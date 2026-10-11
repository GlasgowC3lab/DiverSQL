from pathlib import Path

ROOT = Path(__file__).resolve().parent

# Trino
TRINO_HOST = "" # Host service of the Trino instance
TRINO_PORT = 80
TRINO_CATALOG = "iceberg"
TRINO_SCHEMA = "tpcds"
TRINO_USER = "admin"
TRINO_QUERY_MAX_RUN_TIME = "30m"

# LLM endpoint (OpenAI-compatible), shared by the DiverSQL generator and the baselines
MODEL_NAME = "gpt-oss-120b"
BASE_MODEL_URL = "" # e.g. http://<host>/v1
API_KEY_ENV = "IDA_LLM_API_KEY" # name of the env var holding the API key

# Data
WORKLOADS_DIR = ROOT / "workloads"
RESULTS_DIR = ROOT / "results"
FIGURES_DIR = RESULTS_DIR / "figures"
TABLES_DIR = RESULTS_DIR / "tables" # LaTeX + CSV for the paper tables
PARSED_RESULTS_DIR = RESULTS_DIR / "parsed_results" # <collection>/<schema>/<instance>/<run_id>/queries/runtimes.csv
SCHEMA_DIR = ROOT / "datasets" / "schemas" # <schema>.json dataset definitions

# TPC-DS kit (dsqgen + query templates)
TPCDS_KIT_DIR = ROOT / "third_party" / "tpcds-kit"
DSQGEN_BIN = TPCDS_KIT_DIR / "tools" / "dsqgen"
TPCDS_TEMPLATES_DIR = TPCDS_KIT_DIR / "query_templates"

# Motivation
GROWTH_CURVE_WORKLOAD_DIR = WORKLOADS_DIR / "tpcds_growth_curve"
