"""QPP experiment settings; the parsed-results path comes from the repo-root config."""
from config import PARSED_RESULTS_DIR

PARSED_RESULTS_ROOT = str(PARSED_RESULTS_DIR)

# Workload metric
METRIC = "cpu_cores"
XCOL = "t_rel_s"
YCOL = "value"

SEED = 42
TEST_FRAC = 0.2

# Workload folder (under WORKLOADS_DIR) whose generation_report.json defines the TPC-DS held-out templates
REFERENCE_WORKLOAD = "tpcds_ref"

# Executed workload runs, parsed under PARSED_RESULTS_ROOT/<collection>/<SCHEMA_NAME>/<LAKEHOUSE_INSTANCE_NAME>/<run_id>
SCHEMA_NAME = "tpcds"
LAKEHOUSE_INSTANCE_NAME = "lakehouse-h"
WORKLOAD_RUNS = {
    "tpcds":             dict(collection="tpcds_ref", run_ids=["20260816-120034Z"]),
    "gpt_generated":     dict(collection="tpcds_diversql", run_ids=["20260813-214605Z"]),
    "sqlbarber":         dict(collection="tpcds_sqlbarber", run_ids=["20260818-033107Z"]),
    "bootstrapping_lcm": dict(collection="tpcds_bootstrapping_lcm", run_ids=["20260816-171633Z"]),
    "sql_factory":       dict(collection="tpcds_sql_factory", run_ids=["20260817-133213Z"]),
    "e2etune":           dict(collection="tpcds_e2etune", run_ids=["20260817-044319Z"]),
    "sqlstorm":          dict(collection="tpcds_sqlstorm_new", run_ids=["20260819-161625Z"]),
}
