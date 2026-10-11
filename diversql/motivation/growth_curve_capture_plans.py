"""EXPLAIN every q*.sql in a workload against Trino and write plans.json."""
import json
import sys
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from datetime import datetime, timezone
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2]))  # repo root

from trino.dbapi import connect  # noqa: E402
from utils.parser import build_trino_dag  # noqa: E402

from config import (  # noqa: E402
    TRINO_HOST, TRINO_PORT, TRINO_CATALOG, TRINO_SCHEMA, GROWTH_CURVE_WORKLOAD_DIR,
)

def _connect():
    return connect(
        host=TRINO_HOST, port=TRINO_PORT, user="admin",
        catalog=TRINO_CATALOG, schema=TRINO_SCHEMA, http_scheme="http",
    )


def fetch_plan(qname: str, sql: str) -> dict:
    sql = sql.strip().rstrip(";")
    plan_record = {
        "query_name": qname, "sql": sql, "sql_path": None,
        "status": "unknown", "plan_json": None, "dag": None,
        "node_count": None, "edge_count": None, "error": None,
    }
    conn = _connect()
    cur = conn.cursor()
    try:
        cur.execute(f"EXPLAIN (FORMAT JSON) {sql}")
        rows = cur.fetchall()
        if not rows or not rows[0]:
            raise RuntimeError(f"No EXPLAIN output returned for {qname}")
        raw_plan = rows[0][0]
        plan_json = json.loads(raw_plan) if isinstance(raw_plan, str) else raw_plan
        plan_record["plan_json"] = plan_json
        dag = build_trino_dag(plan_json)
        plan_record["dag"] = dag
        plan_record["node_count"] = len(dag.get("nodes", {}))
        plan_record["edge_count"] = len(dag.get("edges", []))
        plan_record["status"] = "ok"
    except Exception as e:
        plan_record["status"] = "failed"
        plan_record["error"] = {"type": type(e).__name__, "message": str(e)}
    finally:
        try:
            cur.close()
        finally:
            conn.close()
    return plan_record


def capture(workload_dir: Path, *, workers: int = 24) -> dict:
    q_files = sorted(
        workload_dir.glob("q*.sql"),
        key=lambda p: int(p.stem[1:]),
    )
    query_items = [(f.stem, f.read_text()) for f in q_files]

    plans: dict = {}
    ok = failed = 0
    t0 = time.time()

    with ThreadPoolExecutor(max_workers=workers) as ex:
        futs = {ex.submit(fetch_plan, qname, sql): qname for qname, sql in query_items}
        done = 0
        for fut in as_completed(futs):
            rec = fut.result()
            plans[rec["query_name"]] = rec
            ok += rec["status"] == "ok"
            failed += rec["status"] != "ok"
            done += 1
            if done % 500 == 0:
                elapsed = time.time() - t0
                print(f"{done}/{len(query_items)} done ({ok} ok, {failed} failed) "
                      f"in {elapsed:.0f}s ({done/elapsed:.1f} q/s)", flush=True)

    bundle = {
        "workload_name": workload_dir.name,
        "workload_dir": str(workload_dir),
        "schema": TRINO_SCHEMA,
        "trino_host": TRINO_HOST,
        "query_count": len(query_items),
        "ok": ok,
        "failed": failed,
        "captured_at_utc": datetime.now(timezone.utc).isoformat(),
        "plans": plans,
    }
    return bundle


if __name__ == "__main__":
    import argparse

    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("workload_dir", type=Path, nargs="?", default=GROWTH_CURVE_WORKLOAD_DIR)
    ap.add_argument("--workers", type=int, default=24)
    args = ap.parse_args()

    workload_dir = args.workload_dir
    bundle = capture(workload_dir, workers=args.workers)
    out_path = workload_dir / "plans.json"
    out_path.write_text(json.dumps(bundle, default=str))
    print(f"wrote {out_path} ({bundle['ok']}/{bundle['query_count']} ok, {bundle['failed']} failed)")
