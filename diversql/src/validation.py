"""validation -- EXPLAIN + plan signatures + Vendi 3-grams."""

import json
from collections import Counter
from utils.parser import build_trino_dag
from utils.workload_analysis import operator_ngram_counts
from . import config

def explain_plan_json(conn_factory, sql: str):
    """Best-effort ``EXPLAIN (FORMAT JSON)``. Returns plan dict, or None if the
    query is invalid / Trino errored (treated as an invalid candidate)."""
    sql = (sql or "").strip().rstrip(";")
    if not sql:
        return None
    conn = conn_factory()
    try:
        cur = conn.cursor()
        try:
            cur.execute(f"EXPLAIN (FORMAT JSON) {sql}")
            rows = cur.fetchall()
            if not rows or not rows[0]:
                return None
            raw = rows[0][0]
            return json.loads(raw) if isinstance(raw, str) else raw
        finally:
            cur.close()
    except Exception:
        return None
    finally:
        try:
            conn.close()
        except Exception:
            pass

def plan_signatures(plan_json) -> tuple:
   
    dag = build_trino_dag(plan_json)
    nodes = dag.get("nodes", {})
    if not nodes:
        return None, None

    op_counts = Counter(n.get("name", "?") for n in nodes.values())
    coarse_family = tuple(sorted(op_counts.items()))

    bigrams = Counter()
    for src, dst, etype in dag.get("edges", []):
        pn = nodes.get(src, {}).get("name", "?")
        cn = nodes.get(dst, {}).get("name", "?")
        bigrams[(pn, cn, etype)] += 1

    fine = (coarse_family, tuple(sorted(bigrams.items())))
    return hash(fine), coarse_family

def plan_ngrams(plan_json) -> Counter:
    """Child-path operator 3-gram COUNTS of a plan -- the exact motif unit the
    plan-graph Vendi score is computed over (count-weighted, not a set)."""
    dag = build_trino_dag(plan_json)
    return operator_ngram_counts(dag, n=config.NGRAM_N, include_edge_types=("child",))
