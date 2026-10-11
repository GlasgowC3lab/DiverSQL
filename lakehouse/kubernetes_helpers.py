import json
from datetime import datetime
from typing import Any, Dict, List, Optional, Tuple

import time
import yaml
from kubernetes import client, config, dynamic
from kubernetes.client import api_client
from kubernetes.client.rest import ApiException


# ----------------------------
# Release record
# ----------------------------

def make_release_configmap(
    instance_name: str,
    namespace: str,
    labels: Dict[str, str],
    values: dict,
    inventory: List[Dict[str, str]],
    rendered_sha256: str,
    name_prefix: str = "release",
) -> dict:
    cm_name = f"{name_prefix}-{instance_name}"
    return {
        "apiVersion": "v1",
        "kind": "ConfigMap",
        "metadata": {"name": cm_name, "namespace": namespace, "labels": dict(labels)},
        "data": {
            "createdAt": datetime.utcnow().isoformat(timespec="seconds") + "Z",
            "instanceName": instance_name,
            "renderedSha256": rendered_sha256,
            "values.yaml": yaml.safe_dump(values, sort_keys=False),
            "inventory.json": json.dumps(inventory, indent=2),
        },
    }


# ----------------------------
# Kubernetes client
# ----------------------------

def k8s_dynamic_client() -> dynamic.DynamicClient:
    """Auth: in-cluster first, fallback to kubeconfig."""
    try:
        config.load_incluster_config()
    except Exception:
        config.load_kube_config()
    return dynamic.DynamicClient(api_client.ApiClient())


def sanitize_manifest_for_openshift(manifest: dict) -> dict:
    """
    OpenShift: many SAs cannot set Route spec.host (422 FieldValueForbidden).
    If spec.host is present, strip it so OpenShift can allocate one.
    """
    if manifest.get("kind") == "Route" and str(manifest.get("apiVersion", "")).startswith("route.openshift.io/"):
        spec = manifest.get("spec")
        if isinstance(spec, dict) and "host" in spec:
            spec.pop("host", None)
    return manifest

# ----------------------------
# Dependency ordering
# ----------------------------

_KIND_ORDER: Dict[str, int] = {
    "Namespace": 0,
    "CustomResourceDefinition": 1,

    "ServiceAccount": 10,
    "Role": 11,
    "RoleBinding": 12,
    "ClusterRole": 13,
    "ClusterRoleBinding": 14,
    "Secret": 20,
    "ConfigMap": 21,
    "PersistentVolumeClaim": 22,

    "Service": 30,
    "Route": 31,
    "Ingress": 32,

    "StatefulSet": 40,
    "Deployment": 41,
    "DaemonSet": 42,
    "Job": 43,
    "CronJob": 44,
    "Pod": 45,
}


def sort_manifests_for_apply(manifests: List[dict]) -> List[dict]:
    def key(m: dict) -> Tuple[int, str, str]:
        kind = str(m.get("kind", ""))
        meta = m.get("metadata", {}) or {}
        name = str(meta.get("name", ""))
        api_version = str(m.get("apiVersion", ""))
        return (_KIND_ORDER.get(kind, 999), kind, name + "|" + api_version)

    return sorted(manifests, key=key)


def sort_manifests_for_delete(manifests: List[dict]) -> List[dict]:
    # reverse dependency order: workloads first, then services/config, etc.
    return list(reversed(sort_manifests_for_apply(manifests)))


# ----------------------------
# Apply functions
# ----------------------------

def server_side_apply(
    dyn: dynamic.DynamicClient,
    manifest: dict,
    default_namespace: str,
    field_manager: str = "python-deployer",
    force: bool = True,
) -> Any:
    """
    Server-side apply for any kind via dynamic client.
    Note: requires RBAC verb 'patch' for the resource.
    """
    manifest = sanitize_manifest_for_openshift(manifest)

    api_version = manifest["apiVersion"]
    kind = manifest["kind"]
    meta = manifest.setdefault("metadata", {})

    resource = dyn.resources.get(api_version=api_version, kind=kind)

    if resource.namespaced:
        meta.setdefault("namespace", default_namespace)

    name = meta["name"]

    kwargs = dict(
        name=name,
        body=manifest,
        content_type="application/apply-patch+yaml",
        field_manager=field_manager,
        force=force,
    )
    if resource.namespaced:
        kwargs["namespace"] = meta["namespace"]

    return resource.patch(**kwargs)


def apply_manifests(
    manifests: List[dict],
    namespace: str,
    dyn: Optional[dynamic.DynamicClient] = None,
    field_manager: str = "python-deployer",
) -> int:
    dyn = dyn or k8s_dynamic_client()
    applied = 0
    for m in manifests:
        server_side_apply(dyn, m, default_namespace=namespace, field_manager=field_manager)
        applied += 1
    return applied


# ----------------------------
# Delete functions
# ----------------------------

def _dyn_resource(dyn: dynamic.DynamicClient, api_version: str, kind: str):
    return dyn.resources.get(api_version=api_version, kind=kind)


def delete_object(
    dyn: dynamic.DynamicClient,
    api_version: str,
    kind: str,
    name: str,
    namespace: Optional[str] = None,
    grace_period_seconds: int = 0,
    propagation_policy: str = "Background",
) -> bool:
    """
    Delete a single named object. Returns True if delete was issued, False if not found.
    """
    r = _dyn_resource(dyn, api_version, kind)
    try:
        kwargs = dict(
            name=name,
            body=client.V1DeleteOptions(
                grace_period_seconds=grace_period_seconds,
                propagation_policy=propagation_policy,
            ),
        )
        if r.namespaced:
            kwargs["namespace"] = namespace
        r.delete(**kwargs)
        return True
    except ApiException as e:
        if e.status == 404:
            return False
        raise


def delete_by_selector(
    dyn: dynamic.DynamicClient,
    api_version: str,
    kind: str,
    namespace: str,
    label_selector: str,
    grace_period_seconds: int = 0,
    propagation_policy: str = "Background",
) -> int:
    """
    Delete all objects of a kind matching a label selector in a namespace.
    """
    r = _dyn_resource(dyn, api_version, kind)
    if not r.namespaced:
        raise ValueError(f"{kind} is not namespaced; selector delete not supported here")

    objs = r.get(namespace=namespace, label_selector=label_selector)
    count = 0
    for item in getattr(objs, "items", []) or []:
        name = item.metadata.name
        delete_object(
            dyn, api_version, kind, name, namespace=namespace,
            grace_period_seconds=grace_period_seconds,
            propagation_policy=propagation_policy,
        )
        count += 1
    return count


# ----------------------------
# Health checks
# ----------------------------

def label_selector_from_labels(labels: Dict[str, str]) -> str:
    # keep it simple: key=value,key=value ...
    parts = []
    for k, v in labels.items():
        if not k or v is None or v == "":
            continue
        parts.append(f"{k}={v}")
    return ",".join(parts)


def pods_ready(core: client.CoreV1Api, namespace: str, selector: str) -> Tuple[int, int, List[str]]:
    pods = core.list_namespaced_pod(namespace=namespace, label_selector=selector).items
    total = len(pods)
    ready = 0
    not_ready_names = []
    for p in pods:
        cs = p.status.container_statuses or []
        if cs and all(c.ready for c in cs) and p.status.phase == "Running":
            ready += 1
        else:
            not_ready_names.append(p.metadata.name)
    return ready, total, not_ready_names


def statefulsets_ready(apps: client.AppsV1Api, namespace: str, selector: str) -> Tuple[int, int, List[str]]:
    ssets = apps.list_namespaced_stateful_set(namespace=namespace, label_selector=selector).items
    total = len(ssets)
    ready = 0
    not_ready = []
    for s in ssets:
        spec_repl = s.spec.replicas or 0
        ready_repl = s.status.ready_replicas or 0
        if spec_repl == ready_repl:
            ready += 1
        else:
            not_ready.append(f"{s.metadata.name} ({ready_repl}/{spec_repl})")
    return ready, total, not_ready


def deployments_ready(apps: client.AppsV1Api, namespace: str, selector: str) -> Tuple[int, int, List[str]]:
    deps = apps.list_namespaced_deployment(namespace=namespace, label_selector=selector).items
    total = len(deps)
    ready = 0
    not_ready = []
    for d in deps:
        spec_repl = d.spec.replicas or 0
        ready_repl = d.status.ready_replicas or 0
        if spec_repl == ready_repl:
            ready += 1
        else:
            not_ready.append(f"{d.metadata.name} ({ready_repl}/{spec_repl})")
    return ready, total, not_ready


def routes_admitted(dyn: dynamic.DynamicClient, namespace: str, selector: str) -> Tuple[int, int, List[str]]:
    """
    Best-effort route check (OpenShift). If Routes API not present, returns 0/0.
    """
    try:
        r = dyn.resources.get(api_version="route.openshift.io/v1", kind="Route")
    except Exception:
        return 0, 0, []

    routes = r.get(namespace=namespace, label_selector=selector).items
    total = len(routes)
    ok = 0
    bad = []
    for rt in routes:
        host = getattr(rt.spec, "host", None)
        if host:
            ok += 1
        else:
            bad.append(rt.metadata.name)
    return ok, total, bad

def wait_for_health(
    *,
    dyn: dynamic.DynamicClient,
    namespace: str,
    selector: str,
    wait: bool = True,
    timeout_s: int = 120,
    poll_s: int = 5,
    fail_fast: bool = True,
    verbose: bool = False,
) -> Dict[str, Any]:
    """
    Shared health loop. Returns a status dict.

    If wait=True and fail_fast=True, returns early when it detects:
      - Unschedulable (e.g. Insufficient cpu)
      - ImagePullBackOff / ErrImagePull
      - CrashLoopBackOff
      - CreateContainerConfigError, etc.
    """
    core = client.CoreV1Api()
    apps = client.AppsV1Api()

    start = time.time()
    last: Optional[Dict[str, Any]] = None

    while True:
        if verbose:
            print("Waiting ... ")
        pod_ready, pod_total, pod_bad = pods_ready(core, namespace, selector)
        ss_ready, ss_total, ss_bad = statefulsets_ready(apps, namespace, selector)
        dep_ready, dep_total, dep_bad = deployments_ready(apps, namespace, selector)
        rt_ok, rt_total, rt_bad = routes_admitted(dyn, namespace, selector)

        status: Dict[str, Any] = {
            "namespace": namespace,
            "selector": selector,
            "pods": {"ready": pod_ready, "total": pod_total, "not_ready": pod_bad},
            "statefulsets": {"ready": ss_ready, "total": ss_total, "not_ready": ss_bad},
            "deployments": {"ready": dep_ready, "total": dep_total, "not_ready": dep_bad},
            "routes": {"ready": rt_ok, "total": rt_total, "not_ready": rt_bad},
            "ok": (
                (pod_total == 0 or pod_ready == pod_total) and
                (ss_total == 0 or ss_ready == ss_total) and
                (dep_total == 0 or dep_ready == dep_total) and
                (rt_total == 0 or rt_ok == rt_total)
            ),
        }
        if verbose:
            print(f"{status}")

        last = status
        if not wait:
            return status

        if status["ok"]:
            return status

        # ---- NEW: fail-fast diagnostics
        if fail_fast:
            ff = _detect_fail_fast(core, namespace, selector)
            if ff is not None:
                status["failed_fast"] = True
                status.update(ff)
                print(f"ERROR: Fail fast condition occured: {ff}")
                return status

        if time.time() - start > timeout_s:
            print("ERROR: Deploy Timeout Occured")
            status["timeout"] = True
            return status

        time.sleep(poll_s)


# ----------------------------
# Fail-fast pod diagnostics
# ----------------------------

_FAIL_WAITING_REASONS = {
    "ErrImagePull",
    "ImagePullBackOff",
    "CrashLoopBackOff",
    "CreateContainerConfigError",
    "CreateContainerError",
    "RunContainerError",
}

def _pod_unschedulable_message(p: client.V1Pod) -> Optional[str]:
    """
    Returns the scheduler's unschedulable message if the pod is unschedulable, else None.
    """
    for c in (p.status.conditions or []):
        if c.type == "PodScheduled" and c.status == "False" and c.reason == "Unschedulable":
            # Message often includes: "0/.. nodes are available: .. Insufficient cpu"
            return c.message or "Unschedulable"
    return None

def _pod_waiting_failure(p: client.V1Pod) -> Optional[str]:
    """
    Returns a container waiting failure reason if present, else None.
    """
    for st in (p.status.container_statuses or []):
        waiting = getattr(getattr(st.state, "waiting", None), "reason", None)
        if waiting in _FAIL_WAITING_REASONS:
            msg = getattr(getattr(st.state, "waiting", None), "message", "") or ""
            return f"{waiting}: {msg}".strip()
    return None

def _detect_fail_fast(core: client.CoreV1Api, namespace: str, selector: str) -> Optional[Dict[str, str]]:
    """
    Returns a dict describing a fail-fast reason, or None if none detected.
    """
    pods = core.list_namespaced_pod(namespace=namespace, label_selector=selector).items

    for p in pods:
        uns = _pod_unschedulable_message(p)
        if uns:
            return {
                "failure_kind": "Unschedulable",
                "failure_pod": p.metadata.name,
                "failure_message": uns,
            }

        wait_fail = _pod_waiting_failure(p)
        if wait_fail:
            return {
                "failure_kind": "ContainerWaiting",
                "failure_pod": p.metadata.name,
                "failure_message": wait_fail,
            }

    return None

# ----------------------------
# Get functions
# ----------------------------

def get_route_urls(
    dyn: dynamic.DynamicClient,
    namespace: str,
    selector: str,
    *,
    prefer_tls: bool = True,
) -> List[Dict[str, str]]:
    """
    Returns a list of {name, url, host} for OpenShift Routes matching selector.
    If Routes API isn't present, returns [].
    """
    try:
        r = dyn.resources.get(api_version="route.openshift.io/v1", kind="Route")
    except Exception:
        return []

    routes = r.get(namespace=namespace, label_selector=selector).items
    out: List[Dict[str, str]] = []

    for rt in routes:
        name = rt.metadata.name
        host = getattr(rt.spec, "host", None)
        if not host:
            continue

        tls = getattr(rt.spec, "tls", None)
        # If tls exists, assume https is valid
        scheme = "https" if (prefer_tls and tls is not None) else "http"
        out.append({"name": name, "host": host, "url": f"{scheme}://{host}"})

    return out

def get_pod_nodes(namespace: str, selector: str):
    core = client.CoreV1Api()
    pods = core.list_namespaced_pod(namespace=namespace, label_selector=selector).items
    info = []
    for p in pods:
        labels = p.metadata.labels or {}
        info.append({
            "name": p.metadata.name,
            "type": labels.get("type"), 
            "phase": p.status.phase,
            "node": p.spec.node_name,
            "pod_ip": p.status.pod_ip,
            "ready": all(c.ready for c in (p.status.container_statuses or [])),
        })
    return info

def get_trino_pods(namespace: str, selector: str) -> list[dict]:
    core = client.CoreV1Api()
    pods = get_pod_nodes(namespace, selector)
    return [
        p for p in pods
        if p["type"] in ["Worker", "Coordinator"]
        and p["phase"] == "Running"
        and p["ready"]
        and p.get("pod_ip")
    ]
