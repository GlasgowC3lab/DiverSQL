import json
import os
import time
import threading
import requests
import yaml

from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, Iterable, List, Optional, Tuple, Union

import pandas as pd

from lakehouse.config import *
from lakehouse import hive as hive_mod
from lakehouse.profile import NodeProfiler

RESULTS_ROOT = Path(RESULTS_ROOT).resolve()
OVERVIEW_NAME = "overview.ndjson"

_WRITE_LOCK = threading.Lock()


# ----------------------------
# Helpers
# ----------------------------

@staticmethod
def _json_safe(value):
    """
    Recursively convert objects into JSON-safe values.
    """
    if value is None or isinstance(value, (str, int, float, bool)):
        return value

    if isinstance(value, dict):
        return {str(k): _json_safe(v) for k, v in value.items()}

    if isinstance(value, (list, tuple)):
        return [_json_safe(v) for v in value]

    if isinstance(value, Path):
        return str(value)

    if isinstance(value, datetime):
        if value.tzinfo is None:
            value = value.replace(tzinfo=timezone.utc)
        return value.isoformat()

    return str(value)

def _trino_ui_query_url(host: str, trino_query_id: str) -> str:
    return f"{TRINO_HTTP_SCHEME}://{host}:{TRINO_PORT}/ui/api/query/{trino_query_id}"

def utc_now_stamp() -> str:
    return datetime.now(timezone.utc).strftime("%Y%m%d-%H%M%SZ")


def ensure_dir(p: Path) -> Path:
    p.mkdir(parents=True, exist_ok=True)
    return p


def safe_dump_yaml(obj: Any) -> str:
    return yaml.safe_dump(obj, sort_keys=False)


def write_ndjson(rows: Iterable[Dict[str, Any]], out_path: Path) -> None:
    with out_path.open("w", encoding="utf-8") as f:
        for r in rows:
            f.write(json.dumps(r) + "\n")

def read_ndjson(path: Path) -> List[Dict[str, Any]]:
    out = []
    with path.open("r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if line:
                out.append(json.loads(line))
    return out

def _to_utc_ms(x: Any) -> Optional[int]:
    if x is None or (isinstance(x, float) and pd.isna(x)):
        return None
    ts = pd.to_datetime(x, utc=True, errors="coerce")
    if pd.isna(ts):
        return None
    return int(ts.value // 10**6)

def _json_default(o: Any):
    """Make common non-JSON types safe (Path, datetime, etc.)."""
    if isinstance(o, Path):
        return str(o)
    if isinstance(o, datetime):
        if o.tzinfo is None:
            o = o.replace(tzinfo=timezone.utc)
        return o.isoformat()
    raise TypeError(f"Object of type {type(o).__name__} is not JSON serializable")

# ----------------------------
# Workload functions
# ----------------------------

def load_queries_from_directory(directory_path: str, pattern: str = "q*.sql") -> List[Tuple[str, str]]:
    directory = Path(directory_path)
    if not directory.exists():
        raise FileNotFoundError(f"Workload directory not found: {directory}")

    out: List[Tuple[str, str]] = []
    for file_path in sorted(directory.glob(pattern)):
        if not file_path.is_file():
            continue
        out.append((file_path.stem, file_path.read_text(encoding="utf-8").strip()))
    if not out:
        raise RuntimeError(f"No queries found in {directory} (pattern={pattern})")
    return out


def annotate_metrics_csv_inplace_old(
    metrics_csv: str | Path,
    workload_log_ndjson: str | Path,
    *,
    pad_ms: int = 0,
    query_id_field: str = "trino_query_id",
    extra_fields: Optional[List[str]] = None,
    require_ok: bool = False,
    backup: bool = False,
) -> Path:
    metrics_csv = Path(metrics_csv)
    workload_log_ndjson = Path(workload_log_ndjson)

    if extra_fields is None:
        extra_fields = ["query_name", "attempt"]

    # ----------------------------
    # Queries
    # ----------------------------
    q = pd.DataFrame(read_ndjson(workload_log_ndjson))
    if q.empty:
        raise ValueError(f"No query rows found in {workload_log_ndjson}")

    q["raw_start_ms"] = q["start_time"].map(_to_utc_ms)
    q["raw_end_ms"] = q["end_time"].map(_to_utc_ms)

    if require_ok and "status" in q.columns:
        q = q[q["status"].eq("ok")].copy()

    # Drop incomplete windows => failed queries become NULL resources
    q = q.dropna(subset=["raw_start_ms", "raw_end_ms"]).copy()

    if q.empty:
        m = pd.read_csv(metrics_csv)
        if query_id_field not in m.columns:
            m[query_id_field] = pd.NA
        for f in extra_fields:
            if f not in m.columns:
                m[f] = pd.NA

        if backup:
            bak = metrics_csv.with_suffix(metrics_csv.suffix + ".bak")
            if not bak.exists():
                metrics_csv.replace(bak)

        m.to_csv(metrics_csv, index=False)
        return metrics_csv

    if query_id_field not in q.columns:
        raise KeyError(f"workload log missing '{query_id_field}'")

    q["raw_start_ms"] = q["raw_start_ms"].astype("int64")
    q["raw_end_ms"] = q["raw_end_ms"].astype("int64")

    # Sort by true start time, not padded time
    q = q.sort_values(["raw_start_ms", "raw_end_ms"]).reset_index(drop=True)

    # Initial padded windows
    q["start_ms"] = q["raw_start_ms"] - int(pad_ms)
    q["end_ms"] = q["raw_end_ms"] + int(pad_ms)

    # ----------------------------
    # Midpoint clipping to avoid overlap
    # ----------------------------
    n = len(q)

    for i in range(n):
        # Clip start against previous query
        if i > 0:
            prev_end = int(q.loc[i - 1, "raw_end_ms"])
            cur_start = int(q.loc[i, "raw_start_ms"])
            midpoint = (prev_end + cur_start) // 2
            q.loc[i, "start_ms"] = max(int(q.loc[i, "start_ms"]), midpoint)

        # Clip end against next query
        if i < n - 1:
            cur_end = int(q.loc[i, "raw_end_ms"])
            next_start = int(q.loc[i + 1, "raw_start_ms"])
            midpoint = (cur_end + next_start) // 2
            q.loc[i, "end_ms"] = min(int(q.loc[i, "end_ms"]), midpoint)

    # Safety: never let a window invert
    q["start_ms"] = q[["start_ms", "end_ms"]].min(axis=1)
    q["end_ms"] = q[["start_ms", "end_ms"]].max(axis=1)

    # ----------------------------
    # Metrics
    # ----------------------------
    m = pd.read_csv(metrics_csv)
    if "epoch_ms" not in m.columns:
        raise ValueError(f"{metrics_csv} missing required column 'epoch_ms'")

    m["epoch_ms"] = pd.to_numeric(m["epoch_ms"], errors="coerce")
    m = m.dropna(subset=["epoch_ms"]).sort_values("epoch_ms").reset_index(drop=True)
    m["epoch_ms"] = m["epoch_ms"].astype("int64")

    # Ensure columns exist
    if query_id_field not in m.columns:
        m[query_id_field] = pd.NA
    for f in extra_fields:
        if f not in m.columns:
            m[f] = pd.NA

    use_cols = ["start_ms", "end_ms", query_id_field] + [f for f in extra_fields if f in q.columns]

    merged = pd.merge_asof(
        m[["epoch_ms"]].copy(),
        q[use_cols].copy(),
        left_on="epoch_ms",
        right_on="start_ms",
        direction="backward",
        allow_exact_matches=True,
    )

    in_window = merged["end_ms"].notna() & (merged["epoch_ms"] <= merged["end_ms"])

    # Clear labels first, then write only valid assignments
    m.loc[:, query_id_field] = pd.NA
    m.loc[in_window, query_id_field] = merged.loc[in_window, query_id_field].to_numpy()

    for f in extra_fields:
        m.loc[:, f] = pd.NA
        if f in merged.columns:
            m.loc[in_window, f] = merged.loc[in_window, f].to_numpy()

    # ----------------------------
    # Write back
    # ----------------------------
    if backup:
        bak = metrics_csv.with_suffix(metrics_csv.suffix + ".bak")
        if not bak.exists():
            metrics_csv.replace(bak)

    m.to_csv(metrics_csv, index=False)
    return metrics_csv

def annotate_metrics_csv_inplace(
    metrics_csv: str | Path,
    workload_log_ndjson: str | Path,
    *,
    pad_ms: int = 0,
    query_id_field: str = "trino_query_id",
    extra_fields: Optional[List[str]] = None,
    require_ok: bool = False,
    backup: bool = False,
) -> Path:
    metrics_csv = Path(metrics_csv)
    workload_log_ndjson = Path(workload_log_ndjson)

    if extra_fields is None:
        extra_fields = ["query_name", "attempt"]

    # ----------------------------
    # Queries
    # ----------------------------
    q = pd.DataFrame(read_ndjson(workload_log_ndjson))
    if q.empty:
        raise ValueError(f"No query rows found in {workload_log_ndjson}")

    q["raw_start_ms"] = q["start_time"].map(_to_utc_ms)
    q["raw_end_ms"] = q["end_time"].map(_to_utc_ms)

    if require_ok and "status" in q.columns:
        q = q[q["status"].eq("ok")].copy()

    q = q.dropna(subset=["raw_start_ms", "raw_end_ms"]).copy()

    if q.empty:
        m = pd.read_csv(metrics_csv)
        if query_id_field not in m.columns:
            m[query_id_field] = pd.NA
        for f in extra_fields:
            if f not in m.columns:
                m[f] = pd.NA

        if backup:
            bak = metrics_csv.with_suffix(metrics_csv.suffix + ".bak")
            if not bak.exists():
                metrics_csv.replace(bak)

        m.to_csv(metrics_csv, index=False)
        return metrics_csv

    if query_id_field not in q.columns:
        raise KeyError(f"workload log missing '{query_id_field}'")

    q["raw_start_ms"] = q["raw_start_ms"].astype("int64")
    q["raw_end_ms"] = q["raw_end_ms"].astype("int64")

    # Sort by true start time, not padded time
    q = q.sort_values(["raw_start_ms", "raw_end_ms"]).reset_index(drop=True)

    # Initial padded windows
    q["start_ms"] = q["raw_start_ms"] - int(pad_ms)
    q["end_ms"] = q["raw_end_ms"] + int(pad_ms)

    # ----------------------------
    # Midpoint clipping to avoid overlap
    # ----------------------------
    n = len(q)

    for i in range(n):
        # Clip start against previous query
        if i > 0:
            prev_end = int(q.loc[i - 1, "raw_end_ms"])
            cur_start = int(q.loc[i, "raw_start_ms"])
            midpoint = (prev_end + cur_start) // 2
            q.loc[i, "start_ms"] = max(int(q.loc[i, "start_ms"]), midpoint)

        # Clip end against next query
        if i < n - 1:
            cur_end = int(q.loc[i, "raw_end_ms"])
            next_start = int(q.loc[i + 1, "raw_start_ms"])
            midpoint = (cur_end + next_start) // 2
            q.loc[i, "end_ms"] = min(int(q.loc[i, "end_ms"]), midpoint)

    # Safety: never let a window invert
    q["start_ms"] = q[["start_ms", "end_ms"]].min(axis=1)
    q["end_ms"] = q[["start_ms", "end_ms"]].max(axis=1)

    # ----------------------------
    # Metrics
    # ----------------------------
    m = pd.read_csv(metrics_csv)
    if "epoch_ms" not in m.columns:
        raise ValueError(f"{metrics_csv} missing required column 'epoch_ms'")

    m["epoch_ms"] = pd.to_numeric(m["epoch_ms"], errors="coerce")
    m = m.dropna(subset=["epoch_ms"]).sort_values("epoch_ms").reset_index(drop=True)
    m["epoch_ms"] = m["epoch_ms"].astype("int64")

    if query_id_field not in m.columns:
        m[query_id_field] = pd.NA
    for f in extra_fields:
        if f not in m.columns:
            m[f] = pd.NA

    use_cols = ["start_ms", "end_ms", query_id_field] + [f for f in extra_fields if f in q.columns]

    merged = pd.merge_asof(
        m[["epoch_ms"]].copy(),
        q[use_cols].copy(),
        left_on="epoch_ms",
        right_on="start_ms",
        direction="backward",
        allow_exact_matches=True,
    )

    in_window = merged["end_ms"].notna() & (merged["epoch_ms"] <= merged["end_ms"])

    m.loc[:, query_id_field] = pd.NA
    m.loc[in_window, query_id_field] = merged.loc[in_window, query_id_field].to_numpy()

    for f in extra_fields:
        m.loc[:, f] = pd.NA if f not in m.columns else m[f]
        if f in merged.columns:
            m.loc[in_window, f] = merged.loc[in_window, f].to_numpy()

    # ----------------------------
    # Write back
    # ----------------------------
    if backup:
        bak = metrics_csv.with_suffix(metrics_csv.suffix + ".bak")
        if not bak.exists():
            metrics_csv.replace(bak)

    m.to_csv(metrics_csv, index=False)
    return metrics_csv


# ----------------------------
# Workload
# ----------------------------

@dataclass
class QueryWorkload:
    """
    Represents a workload and knows how to execute it + log results.

    queries: list of (query_name, sql_text)
    attempts: number of repeats per query (attempts=1 => run once; attempts=3 => run 3 times)
    """
    name: str
    schema: str
    queries: List[Tuple[str, str]]

    catalog: str = TRINO_CATALOG
    user: str = TRINO_USER
    port: int = TRINO_PORT
    http_scheme: str = TRINO_HTTP_SCHEME

    attempts: int = 1

    @classmethod
    def from_directory(
        cls,
        *,
        workload_dir: Path,
        schema: str,
        name: Optional[str] = None,
        pattern: str = "q*.sql",
        **kwargs,
    ) -> "QueryWorkload":
        queries = load_queries_from_directory(workload_dir, pattern=pattern)
        wl_name = name or Path(workload_dir).name
        return cls(name=wl_name, schema=schema, queries=queries, **kwargs)

    def _trino_ui_query_url(self, host: str, trino_query_id: str) -> str:
        return f"{self.http_scheme}://{host}:{self.port}/ui/api/query/{trino_query_id}"

    def run(
        self,
        *,
        host: str,
        profiler: Optional[NodeProfiler] = None,
        results_dir: str | Path,
        values_snapshot: Optional[dict] = None,
        ctx: Optional[Dict[str, Any]] = None,
        wait_ready: bool = True,
        ready_timeout_s: int = 300,
        ready_poll_s: float = 2.0,
        query_plan: bool = True,
        io_plan: bool = False,
        query: bool = True,
        fetch_ui_doc: bool = True,
    ) -> Dict[str, Any]:
        """
        Executes the workload and writes artifacts into results_dir:
          - workload_log.ndjson
          - per-query JSON docs in queries/
          - optional values.yaml snapshot

        Returns a small summary dict with paths + counts.
        """
        results_dir = Path(results_dir)
        ensure_dir(results_dir)
        ensure_dir(results_dir / "queries")

        if values_snapshot is not None:
            (results_dir / "values.yaml").write_text(
                safe_dump_yaml(values_snapshot),
                encoding="utf-8",
            )

        if wait_ready:
            hive_mod.wait_for_trino(
                host,
                timeout_s=ready_timeout_s,
                poll_s=ready_poll_s,
                verbose=False,
            )

        session_headers = {"X-Trino-User": self.user}

        conn = hive_mod.connect_trino(host, self.schema)
        cur = conn.cursor()

        log_path = ""
        ndjson_rows: List[Dict[str, Any]] = []
        ok = 0
        fail = 0
        qdir = ensure_dir(results_dir / "queries")

        profile_dir = None
        if profiler:
            profile_dir = str(ensure_dir(results_dir / "profiles"))

        try:
            for qname, sql in self.queries:
                print(f"Executing query {qname}")
                for attempt in range(1, int(self.attempts) + 1):
                    
                    if profiler:
                        profiler.trigger_profile("before", qname, out_dir=profile_dir)
                        
                    exec_result = execute_sql(
                        cur=cur,
                        host=host,
                        sql=sql,
                        qname=qname,
                        attempt=attempt,
                        qdir=qdir,
                        session_headers=session_headers,
                        query_plan=query_plan,
                        io_plan=io_plan,
                        query=query,
                        fetch_ui_doc=fetch_ui_doc,
                        receive_result=False,
                    )

                    if profiler:
                        profiler.trigger_profile("after", qname, out_dir=profile_dir)

                    row = exec_result["row"]

                    if query:
                        ndjson_rows.append(row)

                    if row["status"] == "ok":
                        ok += 1
                    else:
                        fail += 1
                        if query:
                            print(f"ERROR: {row['error']}")

        finally:
            try:
                cur.close()
            finally:
                conn.close()

        if query:
            log_path = results_dir / "workload_log.ndjson"
            write_ndjson(ndjson_rows, log_path)

        return {
            "results_dir": str(results_dir),
            "log_path": str(log_path),
            "ok": ok,
            "failed": fail,
            "total_runs": ok + fail,
        }

def execute_sql(
    *,
    cur,
    host: str,
    sql: str,
    qname: str,
    attempt: int,
    qdir: Path,
    session_headers: Optional[Dict[str, str]] = None,
    query_plan: bool = True,
    io_plan: bool = False,
    query: bool = True,
    fetch_ui_doc: bool = True,
    receive_result: bool = False,
) -> Dict[str, Any]:
    """
    Execute one SQL statement and optionally persist artifacts.

    This keeps the batch workload row format unchanged:
      - query_name
      - attempt
      - start_time
      - end_time
      - runtime_s
      - trino_query_id
      - status
      - error
      - results_doc_path

    Additional returned keys (e.g. rows/columns/explain_output/io_output) are
    for ad-hoc callers like Lakehouse.issue_query and are not written by run().
    """
    
    user: str = TRINO_USER
    
    if not sql or not sql.strip():
        raise ValueError("sql must be a non-empty string")

    qdir = ensure_dir(qdir)
    session_headers = session_headers or {"X-Trino-User": user}

    row: Dict[str, Any] = {
        "query_name": qname,
        "sql": sql,
        "attempt": attempt,
        "start_time": None,
        "end_time": None,
        "runtime_s": None,
        "trino_query_id": None,
        "status": "unknown",
        "error": None,
        "results_doc_path": None,
    }

    result: Dict[str, Any] = {
        "row": row,
        "columns": None,
        "rows": None,
        "row_count": None,
        "explain_output": None,
        "io_output": None,
        "ui_doc": None,
        "paths": {
            "explain": None,
            "io": None,
            "ui": None,
        },
    }

    try:
        # ----------------------------
        # EXPLAIN (FORMAT JSON)
        # ----------------------------
        if query_plan:
            explain_stmt = f"EXPLAIN (FORMAT JSON) {sql}"
            cur.execute(explain_stmt)
            explain_rows = cur.fetchall()

            explain_json = None
            if explain_rows and explain_rows[0]:
                raw = explain_rows[0][0]
                explain_path = qdir / f"{qname}_{attempt:03d}_explain.json"
                explain_path.write_text(raw, encoding="utf-8")
                result["paths"]["explain"] = str(explain_path)

                try:
                    explain_json = json.loads(raw)
                except Exception:
                    explain_json = raw

            result["explain_output"] = _json_safe(explain_json)

        # ----------------------------
        # EXPLAIN (TYPE IO, FORMAT JSON)
        # ----------------------------
        if io_plan:
            io_stmt = f"EXPLAIN (TYPE IO, FORMAT JSON) {sql}"
            cur.execute(io_stmt)
            io_rows = cur.fetchall()

            io_json = None
            if io_rows and io_rows[0]:
                raw = io_rows[0][0]
                io_path = qdir / f"{qname}_{attempt:03d}_io.json"
                io_path.write_text(raw, encoding="utf-8")
                result["paths"]["io"] = str(io_path)

                try:
                    io_json = json.loads(raw)
                except Exception:
                    io_json = raw

            result["io_output"] = _json_safe(io_json)

        # ----------------------------
        # Real query execution
        # ----------------------------
        if query:
            start_dt = datetime.now(timezone.utc)
            start_iso = start_dt.strftime("%Y-%m-%dT%H:%M:%SZ")
            t0 = time.perf_counter()
            cur.execute(sql)

            trino_query_id = cur.stats.get("queryId") if hasattr(cur, "stats") else None
            row["trino_query_id"] = trino_query_id

            if receive_result:
                rows = cur.fetchall()
                columns = [d[0] for d in cur.description] if cur.description else []
                result["columns"] = columns
                result["rows"] = _json_safe(rows)
                result["row_count"] = len(rows)
            else:
                for _ in cur:
                    pass   
            t1 = time.perf_counter()
            end_iso = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
            row["start_time"] = start_iso
            row["end_time"] = end_iso
            row["runtime_s"] = t1 - t0
        
            if fetch_ui_doc and trino_query_id:
                ui_url = _trino_ui_query_url(host, trino_query_id)
                resp = requests.get(ui_url, headers=session_headers, timeout=30)

                if resp.ok:
                    doc = resp.json()
                    out_path = qdir / f"{qname}_{attempt:03d}.json"
                    out_path.write_text(json.dumps(doc, indent=2), encoding="utf-8")
                    row["results_doc_path"] = str(out_path)
                    result["ui_doc"] = _json_safe(doc)
                    result["paths"]["ui"] = str(out_path)
                else:
                    result["ui_doc"] = {
                        "ok": False,
                        "status_code": resp.status_code,
                        "reason": resp.reason,
                    }

            row["status"] = "ok"
        else:
            # explain/io-only execution counts as successful if we reached here
            row["status"] = "ok"

    except Exception as e:
        row["status"] = "failed"
        row["error"] = {
            "type": type(e).__name__,
            "message": str(e),
        }

    return _json_safe(result)

# ----------------------------
# Index
# ----------------------------

def write_to_index(
    record: Dict[str, Any],
    *,
    results_root: Union[str, Path] = RESULTS_ROOT,
    overview_name: str = OVERVIEW_NAME,
    fsync: bool = True,
) -> Path:
    """
    Append a single record to ./Results/overview.ndjson (create if missing).

    - Writes one JSON object per line (NDJSON).
    - Adds a small amount of index metadata to the stored row:
        _indexed_at_utc
    - Creates ./Results if missing.

    Returns the path to the overview.ndjson file.
    """
    results_root = Path(results_root)
    results_root.mkdir(parents=True, exist_ok=True)

    overview_path = results_root / overview_name

    # Make a shallow copy + add metadata
    row = dict(record)

    # Ensure paths are strings (nice-to-have)
    for k in ("results_dir", "log_path", "workload_path"):
        if k in row and isinstance(row[k], Path):
            row[k] = str(row[k])

    line = json.dumps(row, ensure_ascii=False, default=_json_default) + "\n"

    # Cross-platform append. Use a lock for intra-process safety.
    with _WRITE_LOCK:
        # Create file if missing + append
        with open(overview_path, "a", encoding="utf-8") as f:
            f.write(line)
            if fsync:
                f.flush()
                os.fsync(f.fileno())

    return overview_path
