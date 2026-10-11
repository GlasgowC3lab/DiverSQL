"""
Sections
  1. Environment / paths / model      
  2. LLM call behaviour               
  3. Concurrency / scheduling         
  4. Table / value sampling           
  5. Prompt shape distribution        
  6. Acceptance / novelty caps        
  7. Operator-feedback (the loop)     
"""

from pathlib import Path

from config import (     # repo-root config: settings shared with the baselines
    WORKLOADS_DIR,      # noqa: F401 -- where generated workloads are written
    SCHEMA_DIR,         # noqa: F401 -- where <schema>.json dataset definitions live
    MODEL_NAME,         # noqa: F401 -- default model id (e.g. "gpt-oss-120b")
    BASE_MODEL_URL,     # noqa: F401 -- default OpenAI-compatible endpoint
    API_KEY_ENV,        # noqa: F401 -- env var name holding the API key
)

RESOURCES_DIR = Path(__file__).resolve().parent.parent / "resources"   # diversql/resources: operators_ground_truth.csv + lever_operator_map.csv

# ============================================================
# 1. Environment / paths / model  
# ============================================================
DEFAULT_REASONING = "high"       # reasoning effort

# ============================================================
# 2. LLM call behaviour  
# ============================================================
REQUEST_TIMEOUT_S = 600.0        # per-call client timeout. This endpoint is
                                 # slow-but-serving; keep > the gateway's ~5min
                                 # timeout so patience collects slow completions.
RETRY_MAX_DEFAULT = 2000         # transient-error (503/504/timeout) retries.
                                 # Patient by design; the pool is NOT the backoff.
RETRY_SLEEP_S = 2.5              # fixed sleep between retries
WARMUP_RETRY_MAX = 16            # warmup uses exponential backoff instead
WARMUP_BASE_SLEEP_S = 10.0
WARMUP_MAX_SLEEP_S = 240.0
USE_RESPONSES_STREAMING = False  # stream Responses API (keeps long calls alive vs router 504s)
RETRY_VERBOSE = False            # print every transient-error retry (else the controller reports)

# ============================================================
# 3. Concurrency / scheduling 
# ============================================================
GENERATION_WORKERS = 128          # DEFAULT in-flight ceiling. 
                                 
CONC_MIN = 8                     # AIMD floor: never throttle below this
CONC_START = 64                   # AIMD initial in-flight target (<= ceiling)
CONC_BETA = 0.5                  # AIMD multiplicative-decrease factor on contention
CONC_PROBE_INTERVAL_S = 12.0     # AIMD additive-increase (+1) cadence when healthy
CONC_COOLDOWN_S = 25.0           # after a cut: debounce further cuts + pause probing
MAX_ATTEMPT_FACTOR = 4.0         # attempt budget = MAX_ATTEMPT_FACTOR * num_queries

# ============================================================
# 4. Table / value sampling 
# ============================================================
MIN_TABLES = 2
MAX_TABLES = 8
CONNECTED_FRACTION = 0.5         # fraction of draws that use the connected FK walk
                                 # vs a connectivity-guaranteed uniform subset

# ============================================================
# 5. Generation temperature
# ============================================================
TEMPERATURE = 0.6                # caller default (raised to the floor below)
TEMPERATURE_FLOOR = 0.9          # force SQLStorm-style hot sampling

# ============================================================
# 6. Acceptance / novelty caps
# ============================================================
SKELETON_CAP = 12                # max queries sharing one SQL skeleton
PLAN_SIGNATURE_CAP = 3           # max queries per plan family

# ============================================================
# 7. Operator-feedback loop 
# ============================================================
NGRAM_N = 3                      # match Vendi n-gram order (reward unit)
HINT_SOFTMAX_TEMP = 0.5          # softmax temp over construct scores (lower = sharper toward the deficit)
CONDITIONAL_WEIGHT = 0.6         # down-weight of reliability=="conditional" constructs
ESC_WINDOW = 100                 # accepted-plan window for the discovery-plateau check
MAX_AGGRESSION = 3               # cap on extra constructs added per query when discovery plateaus

# Per-family construct budget (lo, hi): how many constructs the feedback policy
# draws per query. This is the primary lever on complexity vs invalid-rate --
# Testing showed that ~7 constructs/query and a 62% invalid rate.
# Therefore keep small but non-trivial so operator variety survives.
FAMILY_CONSTRUCT_BUDGET = {
    "simple":             (0, 0),
    "core_analytical":    (1, 3),
    "windows_ranking":    (1, 3),
    "nested_aggregation": (1, 3),
    "set_operations":     (1, 3),
    "multi_role_joins":   (2, 4),
    "string_regex":       (1, 2),
}

# Common operators excluded from STRUCTURAL operator sequences & steering.
# Coverage/entropy denominators use the reachable-structural set from
# operator_space; these are the ones the reward should not chase.
TRIVIAL_OPERATORS = frozenset({
    "Output", "RemoteSource", "LocalExchange", "RemoteExchange", "Exchange",
    "Project", "ScanFilterProject", "ScanFilter", "ScanProject", "TableScan",
    "Filter", "FilterProject", "Limit", "LimitPartial", "TopN", "TopNPartial",
    "TopNRanking", "DistinctLimit", "DistinctLimitPartial", "Sort", "LocalMerge",
    "RemoteMerge", "PartialSort", "AssignUniqueId", "Values",
})
