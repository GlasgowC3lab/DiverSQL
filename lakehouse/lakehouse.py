import json
import threading
import http.client
import yaml
import time
import requests
import random
import math

from concurrent.futures import ThreadPoolExecutor, as_completed
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional, Literal
from dataclasses import dataclass, field
from pathlib import Path

from kubernetes import dynamic
from kubernetes.client.rest import ApiException

from lakehouse.config import RELEASE_DEPLOY_TIMEOUT, WORKLOADS_DIR, RESULTS_ROOT

from lakehouse.render import RenderResult
from lakehouse.kubernetes_helpers import *
from lakehouse import hive as hive_mod

from lakehouse.workload import (
    QueryWorkload,
    utc_now_stamp,
    ensure_dir,
    annotate_metrics_csv_inplace,
    write_to_index,
    _trino_ui_query_url,
    _json_safe,
    execute_sql,
)

from utils.load import load_sql_workload
from utils.parser import build_trino_dag

from utils.workload_analysis import (
    queries_from_plan_bundle,
    dags_from_plan_bundle,
    workload_diversity_report,
    diversity_report_tables,
    query_level_diversity_df,
    STANDARD_COMPARISON_COLUMNS,
)

from lakehouse.profile import NodeProfiler
from lakehouse.resource_logger import NodeLogger
from lakehouse.resource_profile import LakehouseResourceProfiler


from diversql.src.main import (
    load_schema,
    make_openai_client,
    warm_up_model,
    generate_query as generate_query_pipeline,
    generate_query_batch,
    write_workload_directory,
    fetch_table_columns,
    fetch_schema_table_columns,
    DiversityTracker as DiversityTrackerV92,
)

@dataclass
class Lakehouse:
    """
    Expected attributes on render_result:
      - namespace: str
      - manifests: List[dict]
      - labels: Dict[str,str]
      - values: dict
      - inventory: List[Dict[str,str]]
      - rendered_sha256: str
    """
    
    render_result: Any
    dyn: Optional[dynamic.DynamicClient] = None
    field_manager: str = "python-deployer"
    release_name_prefix: str = "release"
    pods_healthy: bool = False 
    verbose: bool = False
    
    schemas: Dict[str, Any] = field(default_factory=dict) 

    workload_runs: list[dict] = field(default_factory=list)

    profiler: Optional[NodeProfiler] = None 
    logger: Optional[NodeLogger] = None 

    def __post_init__(self):
        self.dyn = self.dyn or k8s_dynamic_client()
        
        if bool(self.render_result.values.get("trino", {}).get("profiler", {}).get("enabled", False)):
            self.profiler = NodeProfiler(self.namespace, self.selector, self.render_result.values.get("trino", {}).get("profiler", {}).get("when", ['before']))
        if bool(self.render_result.values.get("trino", {}).get("logger", False)):
            self.logger = NodeLogger(self.namespace, self.selector)

    # ----------------------------
    # Kubernetes Properties/Methods
    # ----------------------------

    @property
    def namespace(self) -> str:
        return self.render_result.namespace

    @property
    def labels(self) -> Dict[str, str]:
        return self.render_result.labels

    @property
    def selector(self) -> str:
        # keep selector stable: instance label only
        return label_selector_from_labels({
            "app.kubernetes.io/instance": self.labels.get("app.kubernetes.io/instance", ""),
        })

    @property
    def instance_name(self) -> str:
        return str(self.render_result.values.get("instanceName", "unknown"))


    @property
    def url(self) -> Optional[str]:
        urls = get_route_urls(self.dyn, self.namespace, self.selector)
        if not urls:
            return None
        return urls[0].get("url")

    @property
    def trino_host(self) -> str:
        # You can customize this naming logic if needed
        return f"trino-service-{self.instance_name}.{self.namespace}.svc.cluster.local"

    @property
    def raw_results_root(self) -> Path:
        """
        Host-side directory backing this instance's raw-results PVC
        (results.raw.name in its lakehouse YAML). PVCs are mounted directly
        on this host at /mnt/<pvc-name>, independent of the in-pod mount
        path (results.raw.path), which stays "/mnt/lakehouse-raw-results"
        across every instance -- only the PVC name changes between them.
        Falls back to lakehouse.config.RESULTS_ROOT if the values don't set a name.
        """
        raw = self.render_result.values.get("results", {}).get("raw", {}) or {}
        name = raw.get("name")
        return Path("/mnt") / name if name else Path(RESULTS_ROOT)

    @classmethod
    def from_release(
        cls,
        instance_name: str,
        namespace: str,
        *,
        dyn: Optional[dynamic.DynamicClient] = None,
        release_name_prefix: str = "release",
        field_manager: str = "python-deployer",
        wait: bool = True,
        timeout_s: int = RELEASE_DEPLOY_TIMEOUT,
        sync_schemas=True,
        verbose=True,
    ):
        """
        Reloads Lakehouse into memory
        """
        dyn = dyn or k8s_dynamic_client()
        cm_name = f"{release_name_prefix}-{instance_name}"
    
        r = dyn.resources.get(api_version="v1", kind="ConfigMap")
        try:
            cm = r.get(name=cm_name, namespace=namespace)
        except ApiException as e:
            if e.status == 404:
                raise RuntimeError(f"Release ConfigMap not found: {namespace}/{cm_name}") from e
            raise
    
        data = getattr(cm, "data", {}) or {}
        labels = dict(getattr(cm.metadata, "labels", {}) or {})
        values = yaml.safe_load(data.get("values.yaml", "") or "") or {}
        inventory = json.loads(data.get("inventory.json", "[]") or "[]")
        rendered_sha256 = data.get("renderedSha256", "")
    
        rr = RenderResult(
            namespace=namespace,
            manifests=[],  # not needed for health/selector teardown
            labels=labels,
            values=values,
            inventory=inventory,
            rendered_sha256=rendered_sha256,
            rendered_yaml="",
        )
    
        obj = cls(
            render_result=rr,
            dyn=dyn,
            field_manager=field_manager,
            release_name_prefix=release_name_prefix,
        )

        if sync_schemas:
            obj.check_health(wait=wait, timeout_s=timeout_s)
            if obj.pods_healthy:
                    obj.sync_schemas()

        obj.verbose = verbose
        if obj.verbose:
            obj.status()
    
        return obj


    def deploy(self, record_release: bool = True, wait=True, timeout_s=RELEASE_DEPLOY_TIMEOUT):
        print("Deploying Trino")
        ordered = sort_manifests_for_apply(self.render_result.manifests)
        apply_manifests(
            ordered,
            namespace=self.namespace,
            dyn=self.dyn,
            field_manager=self.field_manager,
        )

        if record_release:
            cm = make_release_configmap(
                instance_name=self.instance_name,
                namespace=self.namespace,
                labels=self.labels,
                values=self.render_result.values,
                inventory=self.render_result.inventory,
                rendered_sha256=self.render_result.rendered_sha256,
                name_prefix=self.release_name_prefix,
            )
            server_side_apply(self.dyn, cm, default_namespace=self.namespace, field_manager=self.field_manager)
        
        self.check_health(wait=wait, timeout_s=timeout_s, verbose=self.verbose)
        
        if self.pods_healthy:
            self.status()

    def check_health(self, wait: bool = True, timeout_s: int = RELEASE_DEPLOY_TIMEOUT, poll_s: int = 5, *, teardown_on_fail: bool = True, verbose: bool = False):
        print("Checking Trino health ...")
        
        status = wait_for_health(
            dyn=self.dyn,
            namespace=self.namespace,
            selector=self.selector,
            wait=wait,
            timeout_s=timeout_s,
            poll_s=poll_s,
            fail_fast=True,
            verbose=verbose,
        )
    
        if wait and teardown_on_fail and not status.get("ok", False):
            self.tear_down()

        self.pods_healthy = status.get("ok", False)
        return status

    def tear_down(
        self,
        *,
        grace_period_seconds: int = 0,
        propagation_policy: str = "Background",
    ) -> Dict[str, Any]:
        
        deleted: Dict[str, Any] = {"by_inventory": 0, "by_selector": {}, "errors": []}
        self.pods_healthy = False
        kinds = [
            ("route.openshift.io/v1", "Route"),
            ("v1", "Pod"),
            ("apps/v1", "StatefulSet"),
            ("apps/v1", "Deployment"),
            ("v1", "Service"),
            ("v1", "ConfigMap"),
        ]
        for api_version, kind in kinds:
            try:
                c = delete_by_selector(
                    self.dyn, api_version, kind, self.namespace, self.selector,
                    grace_period_seconds=grace_period_seconds,
                    propagation_policy=propagation_policy,
                )
                deleted["by_selector"][f"{api_version}:{kind}"] = c
            except Exception as e:
                deleted["errors"].append(str(e))

        # remove release ConfigMap
        try:
            delete_object(
                self.dyn, "v1", "ConfigMap",
                name=f"{self.release_name_prefix}-{self.instance_name}",
                namespace=self.namespace,
                grace_period_seconds=grace_period_seconds,
                propagation_policy=propagation_policy,
            )
        except Exception:
            pass

        if deleted['errors']:
            print("The following objects failed to delete:")
            for error in deleted['errors']:
                print(f"\t {error}")
        else:
            self.schemas = {}
            print(f"Successfully tore down lakehouse {self.instance_name}")

    def status(self, pretty: bool = True, return_dic: bool = False) -> Dict[str, Any]:    
        pods = get_pod_nodes(self.namespace, self.selector)
        
        schemas = getattr(self, "schemas", {}) or {}
    
        status = {
            "instance": self.instance_name,
            "namespace": self.namespace,
            "selector": self.selector,
            "URL": self.url,
            "pods": pods,
            "schemas": schemas,
        }
    
        if pretty:
            self._print_status(status)
    
        if return_dic:
            return status

    # ----------------------------
    # Hive Metastore
    # ----------------------------
    
    def register_schema(
        self,
        name: str,
        warehouse_path: str,
        *,
        trino_warehouse_path: str = "/mnt/iceberg/warehouse",
        use_dot_db: bool = False,
        metadata_file: str = "v1.metadata.json",
        verbose: bool = True,
        overwrite: bool = False,
        wait_trino: bool = True,
        wait_timeout_s: int = 300,
        wait_poll_s: float = 2.0,
        **kwargs,
    ):
        if (not overwrite) and (name in self.schemas):
            return self.schemas[name]
    
        # wait for the engine (not just pod readiness)       
        if self.pods_healthy:
            if wait_trino:
                hive_mod.wait_for_trino(
                    self.trino_host,
                    timeout_s=wait_timeout_s,
                    poll_s=wait_poll_s,
                    verbose=verbose,
                )
                
            # Build schema object (from hive.py)
            sch = hive_mod.LakehouseSchema(
                name=name,
                warehouse_path=warehouse_path,
                trino_warehouse_path=trino_warehouse_path,
                use_dot_db=use_dot_db,
            )
    
            # Discover tables first (populates sch.tables)
            sch.discover(metadata_file=metadata_file)
    
            # Register with Trino metastore (Iceberg catalog)
            hive_mod.register_schema(self.trino_host, sch, verbose=verbose, **kwargs)
    
            # Track it
            self.schemas[name] = sch
        else:
            print("Trino is not healthy, check that Trino and the HMS is up")
        

    def get_schema(self, name: str):
        return self.schemas.get(name)

    def list_schemas(self):
        return sorted(self.schemas.keys())

    def sync_schemas(self, *, verbose: bool = False) -> Dict[str, hive_mod.LakehouseSchema]:
        """
        Populate self.schemas by reading from Trino, then return it.
        """
        self.schemas = hive_mod.discover_registered_schemas(
            host=self.trino_host,
            catalog=hive_mod.cfg.TRINO_CATALOG,
            verbose=verbose,
        )
        return self.schemas

    # ----------------------------
    # Execute Workload
    # ----------------------------

    def run_workload(
        self,
        workload_name: str,
        schema: str,
        *,
        results_path: str | None = None,
        pattern: str = "q*.sql",
        attempts: int = 1,
        wait_ready: bool = True,
        ready_timeout_s: int = 120,
        ready_poll_s: float = 2.0,
        query_plan: bool = True,
        io_plan: bool = False,
        query: bool = True,
        **kwargs,
    ) -> dict:
        workload_dir = WORKLOADS_DIR / workload_name
        start_time = utc_now_stamp()
    
        results_root = self.raw_results_root if results_path is None else Path(results_path)
        results_dir = results_root / schema / self.instance_name / start_time
    
        ensure_dir(workload_dir)
        ensure_dir(results_dir)
    
        wl = QueryWorkload.from_directory(
            workload_dir=workload_dir,
            schema=schema,
            pattern=pattern,
            attempts=attempts,
            **kwargs,
        )
    
        summary = None
    
        try:
            if self.logger is not None:
                self.logger.prepare_run(str(results_dir), verbose=self.verbose)
    
            self.update_render_pod_nodes()
    
            summary = wl.run(
                host=self.trino_host,
                profiler=self.profiler,
                results_dir=results_dir,
                values_snapshot=self.render_result.values,
                ctx={"extension": self.instance_name, "rate_window": "1s"},
                wait_ready=wait_ready,
                ready_timeout_s=ready_timeout_s,
                ready_poll_s=ready_poll_s,
                query_plan=query_plan,
                io_plan=io_plan,
                query=query,
            )
    
        finally:
            if self.logger is not None:
                print("Stopping query")
                self.logger.cleanup_run(verbose=self.verbose)
    
        pods = get_pod_nodes(self.namespace, self.selector)
    
        record = {
            "start_utc": start_time,
            "end_utc": utc_now_stamp(),
            "workload_path": workload_dir,
            "schema": schema,
            "instance": self.instance_name,
            "worker_count": len([p for p in pods if p["type"] == "Worker"]),
            "resource_logs": self.logger is not None,
            "results_dir": summary.get("results_dir", "") if summary else "",
            "log_path": summary.get("log_path", "") if summary else "",
            "ok": summary.get("ok", "") if summary else "",
            "failed": summary.get("failed", "") if summary else "",
            "total_runs": summary.get("total_runs", "") if summary else "",
        }
    
        if self.logger is not None and query and record["results_dir"] and record["log_path"]:
            run_dir = Path(record["results_dir"])
            log_path = Path(record["log_path"])
            for metrics_file in run_dir.glob("*_metrics.csv"):
                annotate_metrics_csv_inplace(
                    metrics_file,
                    log_path,
                    pad_ms=500,
                    query_id_field="trino_query_id",
                    backup=False,
                )
    
        self.workload_runs.append(record)
        write_to_index(record, results_root=results_root)
    
        return summary

    def issue_query(
        self,
        sql: str,
        schema: str,
        *,
        receive_result: bool = False,
        query_plan: bool = False,
        io_plan: bool = False,
        fetch_ui_doc: bool = False,
        save: bool = True,
        ad_hoc_dir: str | Path | None = None,
        wait_ready: bool = True,
        ready_timeout_s: int = 120,
        ready_poll_s: float = 2.0,
    ) -> Dict[str, Any]:
        """
        Issue a single SQL statement to Trino, optionally save artifacts, and
        return JSON-safe output.
    
        Ad-hoc saved structure:
          Results/<schema>/<instance>/ad-hoc/
              workload_log.ndjson
              queries/
                  <UTCSTAMP>_001_explain.json
                  <UTCSTAMP>_001_io.json
                  <UTCSTAMP>_001.json
        """
        if not sql or not sql.strip():
            raise ValueError("sql must be a non-empty string")
    
        if wait_ready:
            hive_mod.wait_for_trino(
                self.trino_host,
                timeout_s=ready_timeout_s,
                poll_s=ready_poll_s,
                verbose=self.verbose,
            )
    
        sql = sql.strip()
        qname = utc_now_stamp()
    
        if ad_hoc_dir is None:
            base_dir = self.raw_results_root / schema / self.instance_name / "ad-hoc"
        else:
            base_dir = Path(ad_hoc_dir)
    
        qdir = ensure_dir(base_dir / "queries" / qname) if save else Path(".")
        
        profile_dir = None
        if save:
            profile_dir = str(ensure_dir(qdir / "profiles"))
    
        conn = hive_mod.connect_trino(self.trino_host, schema)
        cur = conn.cursor()

        if self.profiler:
            self.profiler.trigger_profile("before", qname, out_dir=profile_dir)
        try:
            exec_result = execute_sql(
                cur=cur,
                host=self.trino_host,
                sql=sql,
                qname=qname,
                attempt=1,
                qdir=qdir,
                query_plan=query_plan,
                io_plan=io_plan,
                query=True,
                fetch_ui_doc=fetch_ui_doc,
                receive_result=receive_result,
            )
        finally:
            if self.profiler:
                self.profiler.trigger_profile("after", qname, out_dir=profile_dir)
            try:
                cur.close()
            finally:
                conn.close()
    
        row = exec_result["row"]
    
        if save:
            ensure_dir(base_dir)
            log_path = base_dir / "workload_log.ndjson"
            with log_path.open("a", encoding="utf-8") as f:
                f.write(json.dumps(row) + "\n")
        else:
            log_path = None
    
        response = {
            "sql": sql,
            "schema": schema,
            "instance": self.instance_name,
            "submitted_at": row.get("start_time"),
            "completed_at": row.get("end_time"),
            "runtime_s": row.get("runtime_s"),
            "status": row.get("status"),
            "trino_query_id": row.get("trino_query_id"),
            "columns": exec_result.get("columns"),
            "rows": exec_result.get("rows"),
            "row_count": exec_result.get("row_count"),
            "explain_output": exec_result.get("explain_output"),
            "io_output": exec_result.get("io_output"),
            "ui_doc": exec_result.get("ui_doc"),
            "results_doc_path": row.get("results_doc_path"),
            "paths": exec_result.get("paths"),
            "log_path": str(log_path) if log_path else None,
            "error": row.get("error"),
            "mode": {
                "receive_result": receive_result,
                "query_plan": query_plan,
                "io_plan": io_plan,
                "fetch_ui_doc": fetch_ui_doc,
                "save": save,
            },
        }
    
        return _json_safe(response)

    def validate_query_explain(
        self,
        *,
        sql: str,
        schema: str,
    ) -> tuple[bool, dict | None]:
        result = self.issue_query(
            f"EXPLAIN {sql}",
            schema=schema,
            wait_ready=False,
            receive_result=False,
            fetch_ui_doc=False,
            query_plan=False,
            io_plan=False,
            save=False,
        )
    
        ok = result.get("status") != "failed"
        return ok, None if ok else result.get("error")

    def validate_candidates_parallel(
        self,
        *,
        candidates: list[dict],
        schema: str,
        validation_workers: int = 4,
    ) -> tuple[list[dict], list[dict]]:
    
        def worker(candidate: dict):
            try:
                ok, err = self.validate_query_explain(
                    sql=candidate["sql"],
                    schema=schema,
                )
                return candidate, ok, err
            except Exception as e:
                return candidate, False, {
                    "type": type(e).__name__,
                    "message": str(e),
                }
    
        valid = []
        invalid = []
    
        with ThreadPoolExecutor(max_workers=validation_workers) as executor:
            futures = [executor.submit(worker, candidate) for candidate in candidates]
    
            for future in as_completed(futures):
                candidate, ok, err = future.result()
    
                if ok:
                    valid.append(candidate)
                else:
                    invalid.append({
                        "sql": candidate.get("sql"),
                        "goal": candidate.get("goal"),
                        "error": err,
                    })
    
        return valid, invalid

    # ----------------------------
    # Generate Query/Workload
    # ----------------------------

    def generate_workload(
        self,
        *,
        schema: str,
        workload_name: str | None = None,
        num_queries: int = 10,
        catalog: str = "iceberg",
        min_tables: int = 2,
        max_tables: int = 8,
        model_name: str = "gpt-oss-120b",
        base_url: str = "http://api.llm.apps.os.dcs.gla.ac.uk/v1",
        api_key_env: str = "IDA_LLM_API_KEY",
        temperature: float = 0.6,
        reasoning="medium",
        warmup: bool = True,
        random_seed: int | None = None,
        batch_size: int = 25,
        validate: bool = True,
        generation_workers: int = 4,
        validation_workers: int = 4,
        plan_feedback: bool = True,
        request_timeout_s: float = 600.0,
        policy=None,
    ) -> dict:
        schema_json = load_schema(schema)
    
        if workload_name is None:
            workload_name = f"generated_{schema}_{utc_now_stamp()}"
    
        if batch_size <= 0:
            raise ValueError("batch_size must be > 0")

        ddl_cache: dict[str, list[dict]] = {}
        ddl_cache_lock = threading.Lock()
        
        def conn_factory():
            return hive_mod.connect_trino(self.trino_host, schema)
        
        def client_factory():
            # Patient timeout (default 600s): this endpoint is slow-but-serving,
            # so waiting through contention collects far more than failing fast.
            # Raise request_timeout_s if legitimate high-reasoning calls are being
            # cut; keep concurrency low (generation_workers) to avoid contention.
            return make_openai_client(
                base_url=base_url,
                api_key_env=api_key_env,
                timeout_s=request_timeout_s,
            )
            
        if warmup:
            warm_up_model(client_factory(), model_name=model_name)

        started_at = datetime.now(timezone.utc)
        rng = random.Random(random_seed)

        
        tracker = DiversityTrackerV92()
        tracker.feedback_enabled = plan_feedback


        if not validate:
            if self.verbose:
                print(f"Generating {num_queries} queries")
            queries = generate_query_batch(
                conn_factory=conn_factory,
                schema_json=schema_json,
                num_queries=num_queries,
                catalog=catalog,
                trino_schema=schema,
                client_factory=client_factory,
                model_name=model_name,
                temperature=temperature,
                reasoning=reasoning,
                min_tables=min_tables,
                max_tables=max_tables,
                random_seed=rng.randint(0, 10**9),
                ddl_cache=ddl_cache,
                ddl_cache_lock=ddl_cache_lock,
                generation_workers=generation_workers,
                tracker=tracker,
                policy=policy,
            )

            return write_workload_directory(
                workload_name=workload_name,
                queries=queries,
                schema_json=schema_json,
                catalog=catalog,
                trino_schema=schema,
                model_name=model_name,
                base_url=base_url,
                temperature=temperature,
                min_tables=min_tables,
                max_tables=max_tables,
                random_seed=random_seed,
                started_at=started_at,
                tracker=tracker,
                extra_report_fields={
                    "reasoning":reasoning,
                    "plan_feedback_enabled": plan_feedback,
                    "validation": {
                        "enabled": False,
                    },
                    "parallelism": {
                        "generation_workers": generation_workers,
                        "validation_workers": 0,
                        "batch_size": batch_size,
                    },
                }
            )

        # v9_2 (W1): one continuous saturating pool over the FULL request -- no
        # outer per-batch barrier. generate_query_batch already validates each
        # candidate via EXPLAIN (plan_valid) and returns only valid, deduped
        # queries, so the previous validate_candidates_parallel re-EXPLAIN pass
        # was redundant (it rejected 0) and is dropped. Validation counts now
        # come from the tracker's per-candidate accounting.
        if self.verbose:
            print(f"Generating {num_queries} queries (adaptive continuous pool, "
                  f"ceiling workers={generation_workers})")

        # Jupyter/terminal progress bar over ACCEPTED queries, fed live by
        # generate_query_batch's progress_cb. tqdm.auto renders in notebooks and
        # terminals; if tqdm is unavailable it degrades to a silent no-op.
        try:
            from tqdm.auto import tqdm as _tqdm
            _bar = _tqdm(total=num_queries, desc=f"gen {workload_name}", unit="q")
        except Exception:
            _bar = None

        def _progress_cb(st: dict) -> None:
            if _bar is None:
                return
            _bar.n = min(st.get("accepted", 0), num_queries)
            _bar.set_postfix({
                "conc": st.get("concurrency_limit"),
                "inflight": st.get("inflight"),
                "attempts": st.get("attempts"),
                "invalid": st.get("rejected_invalid"),
                "contention": st.get("contention_events"),
            }, refresh=False)
            _bar.refresh()

        try:
            valid_queries = generate_query_batch(
                conn_factory=conn_factory,
                schema_json=schema_json,
                num_queries=num_queries,
                catalog=catalog,
                trino_schema=schema,
                client_factory=client_factory,
                model_name=model_name,
                temperature=temperature,
                reasoning=reasoning,
                min_tables=min_tables,
                max_tables=max_tables,
                random_seed=rng.randint(0, 10**9),
                ddl_cache=ddl_cache,
                ddl_cache_lock=ddl_cache_lock,
                generation_workers=generation_workers,
                tracker=tracker,
                policy=policy,
                progress_cb=_progress_cb,
            )[:num_queries]
        finally:
            if _bar is not None:
                _bar.close()

        acc = tracker.generation_accounting_snapshot()
        conc = getattr(tracker, "_concurrency_snapshot", None)

        print(f"Finished query generation")

        return write_workload_directory(
            workload_name=workload_name,
            queries=valid_queries,
            schema_json=schema_json,
            catalog=catalog,
            trino_schema=schema,
            model_name=model_name,
            base_url=base_url,
            temperature=temperature,
            min_tables=min_tables,
            max_tables=max_tables,
            random_seed=random_seed,
            started_at=started_at,
            tracker=tracker,
            extra_report_fields=
            {
                "reasoning":reasoning,
                "plan_feedback_enabled": plan_feedback,
                "validation": {
                    "enabled": True,
                    "method": "EXPLAIN inside generate_query_batch (single continuous pass; no redundant re-validation)",
                    "target_num_queries": num_queries,
                    "num_valid_queries_written": len(valid_queries),
                    "num_invalid_queries_rejected": acc.get("invalid"),
                    "total_candidates_generated": acc.get("total_candidates"),
                    "candidate_validity_rate": acc.get("validity_rate"),
                },
                "parallelism": {
                    "generation_workers": generation_workers,
                    "scheduling": "adaptive continuous pool (W1+ AIMD concurrency)",
                    "adaptive_concurrency": conc,
                    "validation_workers": validation_workers,
                    "batch_size": batch_size,
                },
            }
        )
        
    def generate_query(
        self,
        *,
        schema: str,
        catalog: str = "iceberg",
        model_name: str = "gpt-oss-120b",
        base_url: str = "http://api.llm.apps.os.dcs.gla.ac.uk/v1",
        api_key_env: str = "IDA_LLM_API_KEY",
        temperature: float = 0.6,
        reasoning="medium",
        min_tables: int = 2,
        max_tables: int = 8,
        random_seed: int | None = None,
        warmup: bool = False,
        return_metadata: bool = False,
    ) -> dict:
    
        schema_json = load_schema(schema)
        client = make_openai_client(base_url=base_url, api_key_env=api_key_env)
    
        if warmup:
            warm_up_model(client, model_name=model_name)
    
        ddl_cache: dict[str, list[dict]] = {}
        ddl_cache_lock = threading.Lock()
    
        def conn_factory():
            return hive_mod.connect_trino(self.trino_host, schema)
    
        report = generate_query_pipeline(
            conn_factory=conn_factory,
            schema_json=schema_json,
            catalog=catalog,
            trino_schema=schema,
            client=client,
            model_name=model_name,
            temperature=temperature,
            reasoning=reasoning,
            min_tables=min_tables,
            max_tables=max_tables,
            random_seed=random_seed,
            ddl_cache=ddl_cache,
            ddl_cache_lock=ddl_cache_lock,
        )
    
        return report if return_metadata else report["sql"]

    def profile_resources(
        self,
        *,
        as_dataframe: bool = True,
        timeout_s: float = 2.0,
    ):
        """
        Pull one raw resource snapshot from each running Trino pod.

        Returns one row per Coordinator/Worker pod using the pod IPs discovered
        from Kubernetes.
        """
        profiler = LakehouseResourceProfiler(
            namespace=self.namespace,
            selector=self.selector,
            timeout_s=timeout_s,
        )
        return profiler.profile_resources(as_dataframe=as_dataframe)

    def profile_resource_rates(
        self,
        *,
        interval_s: float = 1.0,
        as_dataframe: bool = True,
        timeout_s: float = 2.0,
    ):
        """
        Pull two snapshots and compute near-current per-pod rates.

        Useful for notebook inspection and live plotting.
        """
        profiler = LakehouseResourceProfiler(
            namespace=self.namespace,
            selector=self.selector,
            timeout_s=timeout_s,
        )
        return profiler.profile_resource_rates(
            interval_s=interval_s,
            as_dataframe=as_dataframe,
        )

    # ----------------------------
    # Load Query/Workload Plans
    # ----------------------------
    def load_query_plans(
        self,
        workload_path: str | Path,
        schema: str,
        *,
        pattern: str = "q*.sql",
        parse_dag: bool = True,
        max_queries: int | None = None,
        wait_ready: bool = True,
        ready_timeout_s: int = 120,
        ready_poll_s: float = 2.0,
        raise_on_error: bool = False,
        plan_workers: int = 1,
    ) -> Dict[str, Any]:

        """
        Load a pre-execution SQL workload and obtain Trino query plans in memory.

        With plan_workers=1 (default) queries are EXPLAINed sequentially on a
        single connection, as before. Pass plan_workers > 1 to fetch plans
        concurrently -- each worker thread opens its own Trino connection
        (same pattern as validate_candidates_parallel), keyed back into
        `plans` in original query order so plans.json stays deterministic.
        """
        workload_path = Path(workload_path)

        # Allow either a direct path or a workload name under WORKLOADS_DIR.
        if not workload_path.exists():
            candidate = WORKLOADS_DIR / workload_path

            if candidate.exists():
                workload_path = candidate
            else:
                raise FileNotFoundError(
                    f"Workload path not found: {workload_path}. "
                    f"Also checked: {candidate}"
                )

        workload = load_sql_workload(
            workload_path,
            pattern=pattern,
        )

        query_items = list(workload["queries"].items())

        if max_queries is not None:
            query_items = query_items[: int(max_queries)]

        if wait_ready:
            hive_mod.wait_for_trino(
                self.trino_host,
                timeout_s=ready_timeout_s,
                poll_s=ready_poll_s,
                verbose=self.verbose,
            )

        def fetch_plan(qname: str, record: Dict[str, Any]) -> Dict[str, Any]:
            sql = record["sql"].strip().rstrip(";")

            if self.verbose:
                print(f"Loading query plan for {qname}")

            plan_record: Dict[str, Any] = {
                "query_name": qname,
                "sql": sql,
                "sql_path": record.get("path"),
                "status": "unknown",
                "plan_json": None,
                "dag": None,
                "node_count": None,
                "edge_count": None,
                "error": None,
            }

            conn = hive_mod.connect_trino(self.trino_host, schema)
            cur = conn.cursor()

            try:
                cur.execute(f"EXPLAIN (FORMAT JSON) {sql}")
                rows = cur.fetchall()

                if not rows or not rows[0]:
                    raise RuntimeError(f"No EXPLAIN output returned for {qname}")

                raw_plan = rows[0][0]

                if isinstance(raw_plan, str):
                    plan_json = json.loads(raw_plan)
                else:
                    plan_json = raw_plan

                plan_record["plan_json"] = plan_json

                if parse_dag:
                    dag = build_trino_dag(plan_json)
                    plan_record["dag"] = dag
                    plan_record["node_count"] = len(dag.get("nodes", {}))
                    plan_record["edge_count"] = len(dag.get("edges", []))

                plan_record["status"] = "ok"

            except Exception as e:
                plan_record["status"] = "failed"
                plan_record["error"] = {
                    "type": type(e).__name__,
                    "message": str(e),
                }

                if raise_on_error:
                    raise

            finally:
                try:
                    cur.close()
                finally:
                    conn.close()

            return plan_record

        plans: Dict[str, Any] = {}
        ok = 0
        failed = 0

        if plan_workers <= 1:
            for qname, record in query_items:
                plan_record = fetch_plan(qname, record)
                plans[qname] = plan_record
                ok += plan_record["status"] == "ok"
                failed += plan_record["status"] != "ok"
        else:
            with ThreadPoolExecutor(max_workers=plan_workers) as executor:
                pending = [
                    (qname, executor.submit(fetch_plan, qname, record))
                    for qname, record in query_items
                ]

                for qname, future in pending:
                    plan_record = future.result()
                    plans[qname] = plan_record
                    ok += plan_record["status"] == "ok"
                    failed += plan_record["status"] != "ok"

        return _json_safe(
            {
                "workload_name": workload["workload_name"],
                "workload_dir": workload["workload_dir"],
                "schema": schema,
                "instance": self.instance_name,
                "query_count": len(query_items),
                "ok": ok,
                "failed": failed,
                "plans": plans,
            }
        )

    def workload_diversity_metrics(
        self,
        plan_bundle: Dict[str, Any],
        *,
        catalog: str = "iceberg",
        schema: str | None = None,
        schema_name: str | None = None,
        schema_json: Dict[str, Any] | None = None,
        table_columns: Dict[str, Any] | None = None,
        fetch_columns: bool = True,
        top_k: int = 20,
    ):
        """
        Generate and print the standard workload diversity comparison metrics.

        This is a display wrapper around generate_workload_diversity_report(...).
        It does not duplicate schema loading, column fetching, or diversity logic.
        """
        out = self.generate_workload_diversity_report(
            plan_bundle,
            catalog=catalog,
            schema=schema,
            schema_name=schema_name,
            schema_json=schema_json,
            table_columns=table_columns,
            fetch_columns=fetch_columns,
            top_k=top_k,
            return_query_level=False,
        )

        df = out["tables"]["standard_metrics"].copy()

        df = df[STANDARD_COMPARISON_COLUMNS]

        print(df.to_string(index=False))

        return {"standard_metrics": df, "report": out["report"], "tables": out["tables"],}

    # ---------------------------
    # Workload Analysis
    # ---------------------------
    
    def generate_workload_diversity_report(
        self,
        plan_bundle: Dict[str, Any],
        *,
        catalog: str = "iceberg",
        schema: str | None = None,
        schema_name: str | None = None,
        schema_json: Dict[str, Any] | None = None,
        table_columns: Dict[str, Any] | None = None,
        fetch_columns: bool = True,
        workload_name: str | None = None,
        top_k: int = 20,
        return_query_level: bool = True,
    ) -> Dict[str, Any]:
        """
        Generate a readable workload diversity report from load_query_plans(...).

        Schema loading/fetching is delegated to query_generator.py.
        Diversity analysis is delegated to workload_analysis.py.
        """
        queries_by_name = queries_from_plan_bundle(plan_bundle)
        dags_by_query = dags_from_plan_bundle(plan_bundle)

        if schema is None:
            schema = plan_bundle.get("schema")

        if schema_name is None:
            schema_name = schema

        if schema_json is None and schema_name is not None:
            schema_json = load_schema(schema_name)

        if (
            table_columns is None
            and fetch_columns
            and schema_json is not None
            and schema is not None
        ):
            table_columns = fetch_schema_table_columns(
                conn_factory=lambda: hive_mod.connect_trino(self.trino_host, schema),
                catalog=catalog,
                schema=schema,
                schema_json=schema_json,
            )

        report = workload_diversity_report(
            queries_by_name=queries_by_name,
            dags_by_query=dags_by_query,
            schema_json=schema_json,
            table_columns=table_columns,
        )

        if workload_name is None:
            workload_name = plan_bundle.get("workload_name")

        tables = diversity_report_tables(
            report,
            workload_name=workload_name,
            top_k=top_k,
        )

        out = {
            "report": report,
            "tables": tables,
            "schema_json": schema_json,
            "table_columns": table_columns,
        }

        if return_query_level:
            out["query_level"] = query_level_diversity_df(
                queries_by_name=queries_by_name,
                dags_by_query=dags_by_query,
                schema_json=schema_json,
                table_columns=table_columns,
            )

        return out

    # ----------------------------
    # Helpers
    # ----------------------------

    def update_render_pod_nodes(self) -> dict:
        """
        Fill node placement fields in self.render_result.values from live pods.
        Intended to run right before wl.run(..., values_snapshot=self.render_result.values).
    
        Updates (if present / creates if missing):
          - values['trino']['coord']['nodeName'] = <coordinator node>
          - values['trino']['worker']['nodes']   = [<worker node>, ...]
          - values['metastore']['nodeName']      = <hms node>
        """
        pods = get_pod_nodes(self.namespace, self.selector)
    
        # only trust running+ready pods (matches your helper logic)
        pods = [p for p in pods if p.get("phase") == "Running" and p.get("ready") and p.get("node")]
    
        coord = next((p for p in pods if (p.get("type") or "") == "Coordinator"), None)
        workers = sorted([p for p in pods if (p.get("type") or "") == "Worker"], key=lambda x: x.get("name", ""))
        hms = next((p for p in pods if (p.get("type") or "") in ("Metastore", "HMS")), None)
    
        v = self.render_result.values
        v.setdefault("trino", {}).setdefault("coord", {})
        v.setdefault("trino", {}).setdefault("worker", {})
        v.setdefault("metastore", {})
        
        if coord:
            v["trino"]["coord"]["nodeName"] = coord["node"]
    
        if workers:
            nodes = [p["node"] for p in workers]
            v["trino"]["worker"]["nodes"] = nodes
    
        if hms:
            v["metastore"]["nodeName"] = hms["node"]

        
    def _print_status(self, s: Dict[str, Any]):
        print("STATUS:")
        print(f"\nLakehouse: {s['instance']}")
        print(f"Namespace: {s['namespace']}")
        print(f"Selector:  {s['selector']}")
    
        if s.get("URL"):
            print(f"URL:       {s['URL']}")
        else:
            print("URL:       <none>")
    
        # ----------------------------
        # Pods
        # ----------------------------
        pods = s.get("pods") or []
    
        if not pods:
            print("\nPods:\n  <none>")
        else:
            groups: Dict[str, List[Dict[str, Any]]] = {}
            for p in pods:
                t = (p.get("type") or "unknown")
                if isinstance(t, str):
                    t = t.strip() or "unknown"
                groups.setdefault(str(t), []).append(p)
    
            preferred = ["coordinator", "worker", "metastore", "unknown"]
            ordered_keys = [k for k in preferred if k in groups] + [k for k in sorted(groups) if k not in preferred]
    
            print("\nPods:")
            for t in ordered_keys:
                print(f"\n  {t}:")
                items = sorted(groups[t], key=lambda x: (x.get("node") or "", x.get("name") or ""))
                for p in items:
                    name = p.get("name", "")
                    phase = p.get("phase", "")
                    node = p.get("node", "")
                    ready = "Ready" if p.get("ready") else "NotReady"
                    ip = p.get("pod_ip") or ""
                    print(f"    - {name:<40} {phase:<10} {ready:<9} {node:<18} {ip}")
    
        # ----------------------------
        # Schemas
        # ----------------------------
        schemas = s.get("schemas") or {}
    
        # Exclude defaults you mentioned
        excluded = {"default", "information_schema"}
    
        # Filter + sort
        schema_items = []
        for name, sch in schemas.items():
            if name in excluded:
                continue
            # sch.tables is expected to exist; be defensive
            tables = getattr(sch, "tables", None) or []
            schema_items.append((name, sch, tables))
    
        schema_items.sort(key=lambda x: x[0])
    
        print("\nSchemas:")
        if not schemas:
            print("  <none>")
            return
    
        if not schema_items:
            print("  <none>")
            return
    
        for name, sch, tables in schema_items:
            print(f"\n  Warehouse location: {sch.warehouse_path}")
            print(f"\n  {name}: {len(tables)} tables")
    
            # show tables (sorted), but avoid blowing up output if huge
            table_names = []
            for t in tables:
                # your IcebergTable has .name; fallback to string
                tn = getattr(t, "name", None) or str(t)
                table_names.append(tn)
    
            table_names = sorted(set(table_names))
    
            if not table_names:
                print("    - <none>")
                continue
    
            for tn in table_names[:5]:
                print(f"    - {tn}")
            if len(table_names) > 5:
                print(f" \t ... plus {len(table_names[5:])} more")

