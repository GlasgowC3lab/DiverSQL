"""Lakehouse deployment settings; paths and shared Trino settings come from the repo-root config."""
from config import (  # noqa: F401 -- re-exported to the lakehouse modules
    WORKLOADS_DIR,
    TRINO_USER,
    TRINO_CATALOG,
    TRINO_QUERY_MAX_RUN_TIME as TRINO_TIMEOUT,
)

RELEASE_DEPLOY_TIMEOUT = 240  # s, wait for a Helm-style release to become ready

# In-cluster Trino service
TRINO_PORT = 8080
TRINO_HTTP_SCHEME = "http"

# Raw run outputs (PVC mount on this host)
RESULTS_ROOT = "/mnt/lakehouse-raw-results"

# Node logging sidecar
LOGGING_PORT = 8099
