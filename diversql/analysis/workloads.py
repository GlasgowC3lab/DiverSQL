"""The eight workloads evaluated in Section 6, their paper labels, and loaders for their SQL, reports and runtimes."""
import json

import numpy as np
import pandas as pd

from config import WORKLOADS_DIR, RESULTS_DIR, PARSED_RESULTS_DIR

ANALYSIS_RESULTS_DIR = RESULTS_DIR / "analysis"
WORKLOAD_METRICS_CSV = ANALYSIS_RESULTS_DIR / "workload_metrics.csv"   # written by analyse_diversity.ipynb
GIN_VENDI_CSV = ANALYSIS_RESULTS_DIR / "gin_vendi" / "plan_vendi_gin_cosine.csv"   # written by check_cosine_vendi.ipynb
GIN_VENDI_COL = "GIN cosine, pooled vocab, std."

REF = "tpcds_ref"
BASELINES = [
    "tpcds_bootstrapping_lcm",
    "tpcds_e2etune",
    "tpcds_sql_factory",
    "tpcds_sqlbarber",
    "tpcds_sqlstorm",
]
OURS = ["tpcds_diversql_no_feedback", "tpcds_diversql"]
ROWS = [REF] + BASELINES + OURS
GENERATORS = BASELINES + OURS

PRETTY = {
    "tpcds_ref": "TPC-DS (1000)",
    "tpcds_bootstrapping_lcm": "Bootstrapping-LCM",
    "tpcds_e2etune": "E2ETune",
    "tpcds_sql_factory": "SQL-Factory",
    "tpcds_sqlbarber": "SQLBarber",
    "tpcds_sqlstorm": "SQLStorm",
    "tpcds_diversql_no_feedback": "DiverSQL (W/O FB)",
    "tpcds_diversql": "DiverSQL (W/ FB)",
}

PLAN_METRICS_KEY = {"tpcds_ref": "tpcds_ref"}

# workload -> (collection, run_id) of its single execution run on lakehouse-h.
RUNTIME_RUNS = {
    "tpcds_ref": ("tpcds_ref", "20260816-120034Z"),
    "tpcds_bootstrapping_lcm": ("tpcds_bootstrapping_lcm", "20260816-171633Z"),
    "tpcds_e2etune": ("tpcds_e2etune", "20260817-044319Z"),
    "tpcds_sql_factory": ("tpcds_sql_factory", "20260817-133213Z"),
    "tpcds_sqlbarber": ("tpcds_sqlbarber", "20260818-033107Z"),
    "tpcds_sqlstorm": ("tpcds_sqlstorm_new", "20260819-161625Z"),
    "tpcds_diversql_no_feedback": ("tpcds_diversql_no_feedback", "20260921-111847Z"),
    "tpcds_diversql": ("tpcds_diversql", "20260813-214605Z"),
}
SCHEMA, INSTANCE = "tpcds", "lakehouse-h"


def load_sql(workload: str) -> dict:
    """{query name -> SQL text} for every q*.sql in a workload directory."""
    files = sorted((WORKLOADS_DIR / workload).glob("q*.sql"), key=lambda p: int(p.stem[1:]))
    return {f.stem: f.read_text(encoding="utf-8").strip() for f in files}


def load_generation_report(workload: str) -> dict:
    return json.loads((WORKLOADS_DIR / workload / "generation_report.json").read_text(encoding="utf-8"))


def load_runtimes(workload: str, *, max_qid: int | None = None) -> np.ndarray:
    """Per-query runtimes (s) of a workload's execution run; failed and timed-out queries are absent."""
    collection, run_id = RUNTIME_RUNS[workload]
    path = PARSED_RESULTS_DIR / collection / SCHEMA / INSTANCE / run_id / "queries" / "runtimes.csv"
    df = pd.read_csv(path)
    if max_qid is not None:
        df = df[df["query_id"].str.lstrip("q").astype(int) <= max_qid]
    return df["runtime_s"].dropna().to_numpy(dtype=float)


def load_workload_metrics() -> pd.DataFrame:
    """Plan and schema diversity metrics per workload, indexed by the ROWS keys."""
    df = pd.read_csv(WORKLOAD_METRICS_CSV).set_index("workload")
    return df.loc[[PLAN_METRICS_KEY.get(w, w) for w in ROWS]].set_axis(ROWS)
