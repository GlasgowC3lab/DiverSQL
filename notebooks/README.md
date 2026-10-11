# Notebooks: deploy, generate, execute and collect

End-to-end notebooks for producing the workloads and their runtimes. Each one finds the repo root and reads paths and shared settings from `config.py`. They need a Kubernetes cluster for the lakehouse and the OpenAI-compatible LLM endpoint set in `config.py`.

| Notebook | Purpose |
|---|---|
| `launch_lakehouse_tpcds.ipynb` | Deploys the Trino/Iceberg lakehouse from `lakehouse/lakehouses/lakehouse-tpcds.yaml` and registers the TPC-DS schema. It then generates a DiverSQL workload, analyses its plans, executes it on the lakehouse and tears the deployment down. |
| `generate_baseline_queries.ipynb` | Generates the 1,000-query workloads for DiverSQL and the five baselines (SQLStorm, SQLBarber, E2ETune, Bootstrapping-LCM, SQL-Factory) against a deployed lakehouse, writing each to `workloads/<name>/`. |
| `parse_raw_results.ipynb` | Stages a run's raw outputs into `results/parsed_results/<collection>/<schema>/<instance>/<run_id>/`, including the per-query `runtimes.csv` read by the analysis and QPP notebooks. |

Typical order: deploy the lakehouse, generate workloads, execute them with `run_workload` in `launch_lakehouse_tpcds.ipynb`, then parse each run with `parse_raw_results.ipynb`. Set the instance name, namespace and run IDs in each notebook's first cells.
