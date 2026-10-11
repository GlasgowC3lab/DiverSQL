# Utils: plans, workloads and run results

Shared helpers for parsing query plans, loading workloads and runtimes, and computing plan diversity metrics. They are used by `diversql/`, the analysis notebooks and `notebooks/parse_raw_results.ipynb`. Paths come from the repo-root `config.py`.

| File | Purpose |
|---|---|
| `parser.py` | Parses Trino `EXPLAIN (FORMAT JSON)` output into an operator DAG (`build_trino_dag`, `iter_edges`). |
| `workload_analysis.py` | Plan- and schema-level diversity metrics over a workload's compiled plans: plan signatures, operator n-grams, coverage and Vendi scores. |
| `load.py` | Loads SQL workloads (`load_sql_workload`), plan bundles, execution logs and per-query runtime traces (`load_aligned_plans_and_runs`). |
| `clean_stage.py` | Stages a raw lakehouse run into `PARSED_RESULTS_DIR/<collection>/<schema>/<instance>/<run_id>/`, including the per-query `runtimes.csv`. Run it through `notebooks/parse_raw_results.ipynb`. |

`clean_stage.py` keeps its own settings at the top of the file: the raw-results roots to search (`RESULTS_ROOTS`), the metrics CSV columns and the parsing toggles.
