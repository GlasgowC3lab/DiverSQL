# DiverSQL

Code, workloads and results for **DiverSQL: Feedback-Driven Generation of Plan-Diverse SQL Workloads in Data Lakehouses** .

DiverSQL is an LLM-based SQL workload generator that targets diversity in the *compiled query plan* rather than the SQL text. It couples three mechanisms:

- **Targeted generation** steers prompts towards SQL constructs whose engine operators are under-represented.
- **Candidate validation** compiles each candidate with `EXPLAIN` and rejects duplicate plans and over-represented plan families.
- **Plan-aware diversity tracking** keeps a running profile of admitted plans, which feeds back into both.

On TPC-DS, DiverSQL generates 1,000 compilable queries with no repeated plan graphs and improves plan-graph Vendi score by 37% over the strongest baseline. QPP models trained on its workload achieve the lowest log-scale MAE on unseen workloads in all six model families evaluated.

## Repository layout

| Path | Contents |
|---|---|
| [`diversql/`](diversql/) | The generator (`src/`), the five re-implemented baselines (`baselines/`), the motivation study (`motivation/`) and the Section 6 analysis (`analysis/`). |
| [`qpp/`](qpp/) | The Section 7 QPP evaluation: six model families, plus the cold-start and hybrid experiments. |
| [`lakehouse/`](lakehouse/) | Deploys the Trino / Iceberg lakehouse on Kubernetes and executes workloads, capturing plans, runtimes and resource traces. |
| [`notebooks/`](notebooks/) | End-to-end notebooks that deploy the lakehouse, generate workloads, execute them and parse the results. |
| [`utils/`](utils/) | Shared loaders and plan-analysis helpers used across the repo. |
| [`datasets/`](datasets/) | The TPC-DS schema definition and instructions for generating Iceberg tables. |
| [`workloads/`](workloads/) | The eight evaluated workloads, each as `q*.sql` plus a `generation_report.json`. |
| [`results/parsed_results/`](results/parsed_results/) | Per-query runtimes (`runtimes.csv`) from each workload's execution run. |
| `third_party/` | The [`iceberg-spark-tpcds-benchmark`](https://github.com/MOBIN-F/iceberg-spark-tpcds-benchmark) submodule (TPC-DS data generation and `dsqgen`). |
| `config.py` | Settings shared by the whole repo: Trino connection, LLM endpoint and data paths. |

Each directory has its own README with a table of its files.

## Workloads

| `workloads/<name>` | Paper label |
|---|---|
| `tpcds_ref` | TPC-DS (1000) |
| `tpcds_bootstrapping_lcm` | Bootstrapping-LCM |
| `tpcds_e2etune` | E2ETune |
| `tpcds_sql_factory` | SQL-Factory |
| `tpcds_sqlbarber` | SQLBarber |
| `tpcds_sqlstorm` | SQLStorm |
| `tpcds_diversql_no_feedback` | DiverSQL (W/O FB) |
| `tpcds_diversql` | DiverSQL (W/ FB) |

Each workload's runtimes are under `results/parsed_results/<name>/tpcds/lakehouse-h/<run_id>/queries/runtimes.csv`. The run IDs are listed in `diversql/analysis/workloads.py` and `qpp/config.py`. Compiled plans (`plans.json`) and raw execution logs are too large for Git and are not included in this repository.

## Getting started

```bash
git clone --recurse-submodules https://github.com/GlasgowC3lab/DiverSQL.git
cd DiverSQL
pip install -r requirements.txt
```

The code was developed with Python 3.10. Notebooks find the repo root themselves, so run each one from its own directory.

To generate or execute workloads, fill in `config.py`:

- `TRINO_HOST` / `TRINO_PORT`: the Trino coordinator.
- `BASE_MODEL_URL` and `MODEL_NAME`: an OpenAI-compatible endpoint. The paper uses `gpt-oss-120b`.
- `API_KEY_ENV`: the environment variable holding the endpoint's API key.

## Reproducing the paper

These notebooks only read saved workloads and results, so no lakehouse or LLM access is needed.

| Paper output | Notebook |
|---|---|
| Tables 1–5 | `diversql/analysis/tables.ipynb` |
| Figure 1 | `diversql/analysis/plan_collision_figure.ipynb` |
| Figure 2 | `diversql/motivation/tpcds_structural_collapse_growth_curve.ipynb` |
| Figure 4 | `diversql/analysis/runtime_distribution_figure.ipynb` |
| Table 6, Figure 5 | `qpp/cold/02_paper_qpp_table_and_plot.ipynb` |
| Table 7, Figures 6–7 | `qpp/hybrid/02_paper_hybrid_table_and_plots.ipynb` |

Tables 4 and 5 and Figures 1 and 2 are built from compiled plans, so they need either the plan-level metrics in `results/analysis/` or the `plans.json` files. See [`diversql/analysis/README.md`](diversql/analysis/README.md) for the order the notebooks run in.

## Running the full pipeline

Re-running generation, execution or QPP training needs a Kubernetes cluster and an LLM endpoint:

1. **Data.** Generate the TPC-DS SF10 Iceberg tables ([`datasets/README.md`](datasets/README.md)).
2. **Lakehouse.** Deploy Trino with `notebooks/launch_lakehouse_tpcds.ipynb` ([`lakehouse/README.md`](lakehouse/README.md)).
3. **Generate.** Produce DiverSQL and baseline workloads with `notebooks/launch_lakehouse_tpcds.ipynb` and `notebooks/generate_baseline_queries.ipynb`.
4. **Execute and parse.** Run each workload on the lakehouse, then stage its runtimes with `notebooks/parse_raw_results.ipynb`.
5. **QPP.** Train and evaluate with `qpp/cold/01_offline_training_and_testing.ipynb` and `qpp/hybrid/01_hybrid_training_and_testing.ipynb`. These also need each run's `q*_explain.json` plans ([`qpp/README.md`](qpp/README.md)).

## Citation

TBA

## License

Released under the MIT License; see [`LICENSE`](LICENSE).
