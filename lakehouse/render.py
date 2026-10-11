import os
import glob
import hashlib
from dataclasses import dataclass
from typing import Any, Dict, List, Optional, Tuple

import yaml
from jinja2 import Environment, FileSystemLoader, StrictUndefined


# ----------------------------
# Jinja filters
# ----------------------------

def jinja_quote(v: Any) -> str:
    if v is None:
        return '""'
    s = str(v).replace('"', '\\"')
    return f'"{s}"'


def jinja_to_yaml(v: Any) -> str:
    return yaml.safe_dump(v, default_flow_style=False).rstrip()


def jinja_indent(text: Any, spaces: int = 2) -> str:
    pad = " " * int(spaces)
    return "\n".join(pad + line if line.strip() else line for line in str(text).splitlines())


def load_values(values_path: str) -> dict:
    with open(values_path, "r") as f:
        return yaml.safe_load(f) or {}


def build_env(templates_dir: str) -> Environment:
    env = Environment(
        loader=FileSystemLoader(templates_dir),
        undefined=StrictUndefined,   # fail fast if a value is missing
        autoescape=False,
        keep_trailing_newline=True,
        lstrip_blocks=True,
        trim_blocks=True,
    )
    env.filters["quote"] = jinja_quote
    env.filters["toYaml"] = jinja_to_yaml
    env.filters["indent"] = jinja_indent
    return env


# ----------------------------
# Render + parse
# ----------------------------

def render_templates_to_text(
    templates_dir: str,
    values: dict,
    pattern: str = "*.yaml.j2",
) -> str:
    """
    Render all templates matching pattern in templates_dir into a single multi-doc YAML string.
    """
    env = build_env(templates_dir)
    paths = sorted(glob.glob(os.path.join(templates_dir, pattern)))

    rendered_parts: List[str] = []
    for path in paths:
        name = os.path.basename(path)
        tmpl = env.get_template(name)
        out = tmpl.render(Values=values).strip()
        if out:
            rendered_parts.append(out)

    # Join with doc separators (in case templates don't end with ---)
    return "\n---\n".join(rendered_parts) + "\n"

def is_k8s_manifest(doc: dict) -> bool:
    return isinstance(doc, dict) and "apiVersion" in doc and "kind" in doc and isinstance(doc.get("metadata", {}), dict)

def filter_k8s_manifests(manifests: list) -> list:
    good = []
    bad = []
    for i, m in enumerate(manifests):
        if is_k8s_manifest(m):
            good.append(m)
        else:
            bad.append((i, m))
    if bad:
        print("Dropped non-Kubernetes YAML docs:")
        for i, m in bad:
            print(f"- doc #{i}: type={type(m).__name__}, keys={list(m.keys()) if isinstance(m, dict) else None}")
    return good

def parse_rendered_yaml(rendered_yaml: str) -> List[dict]:
    """
    Parse multi-doc YAML string into a list of manifest dicts.
    """
    return [doc for doc in yaml.safe_load_all(rendered_yaml) if doc]


def sha256_text(s: str) -> str:
    return hashlib.sha256(s.encode("utf-8")).hexdigest()


# ----------------------------
# Collective tracking helpers
# ----------------------------

def default_common_labels(values: dict, extra: Optional[Dict[str, str]] = None) -> Dict[str, str]:
    """
    Standard labels you can stamp onto every resource to treat it as a 'collective'.
    """
    instance = values.get("instanceName", "unknown")
    part_of = values.get("partOf", instance)
    labels = {
        "app.kubernetes.io/instance": str(instance),
        "app.kubernetes.io/part-of": str(part_of),
        "app.kubernetes.io/managed-by": "python-deployer",
    }
    if extra:
        labels.update({str(k): str(v) for k, v in extra.items()})
    return labels


def inject_labels(manifest: dict, labels: Dict[str, str]) -> dict:
    """
    Add labels to metadata.labels for a manifest (best-effort).
    Also stamps Pod template labels for workload controllers.
    """
    meta = manifest.setdefault("metadata", {})
    mlabels = meta.setdefault("labels", {})
    mlabels.update(labels)

    # For controllers, also label pod template
    spec = manifest.get("spec")
    if isinstance(spec, dict):
        template = spec.get("template")
        if isinstance(template, dict):
            tmeta = template.setdefault("metadata", {})
            tlabels = tmeta.setdefault("labels", {})
            tlabels.update(labels)

    return manifest


def inject_labels_all(manifests: List[dict], labels: Dict[str, str]) -> List[dict]:
    return [inject_labels(m, labels) for m in manifests]


def build_inventory(manifests: List[dict]) -> List[Dict[str, str]]:
    """
    Return a simple inventory list: apiVersion/kind/namespace/name.
    """
    inv: List[Dict[str, str]] = []
    for m in manifests:
        meta = m.get("metadata", {}) or {}
        inv.append({
            "apiVersion": str(m.get("apiVersion", "")),
            "kind": str(m.get("kind", "")),
            "namespace": str(meta.get("namespace", "")),
            "name": str(meta.get("name", "")),
        })
    return inv


@dataclass
class RenderResult:
    values: dict
    namespace: str
    rendered_yaml: str
    manifests: List[dict]
    labels: Dict[str, str]
    inventory: List[Dict[str, str]]
    rendered_sha256: str


def render_collective(
    templates_dir: str,
    values_path: str,
    namespace_override: Optional[str] = None,
    label_extra: Optional[Dict[str, str]] = None,
) -> RenderResult:
    """
    Full pipeline:
      values.yaml -> render -> parse -> label injection -> inventory + sha256
    """
    values = load_values(values_path)
    namespace = namespace_override or values.get("namespace") or "default"

    rendered_yaml = render_templates_to_text(templates_dir, values)
    manifests = parse_rendered_yaml(rendered_yaml)
    manifests = filter_k8s_manifests(manifests)

    labels = default_common_labels(values, extra=label_extra)
    manifests = inject_labels_all(manifests, labels)

    rendered_sha = sha256_text(rendered_yaml)
    inventory = build_inventory(manifests)

    return RenderResult(
        values=values,
        namespace=namespace,
        rendered_yaml=rendered_yaml,
        manifests=manifests,
        labels=labels,
        inventory=inventory,
        rendered_sha256=rendered_sha,
    )
