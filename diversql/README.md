# DiverSQL

The DiverSQL generator, the five related-work baselines it is compared against, and the analysis behind the paper's motivation and Section 6. Each subdirectory has its own README with details.

| Directory | Contents |
|---|---|
| [`src/`](src/) | The DiverSQL generator: targeted prompt construction, LLM generation, plan analysis with `EXPLAIN`, admission control and the diversity tracker. |
| [`baselines/`](baselines/) | SQLStorm, SQLBarber, E2ETune, Bootstrapping-LCM and SQL-Factory, re-implemented for Trino/Iceberg on the same harness as DiverSQL. |
| [`shared/`](shared/) | Static SQL features used by the generator, the baselines and the analysis. |
| [`resources/`](resources/) | The Trino operator vocabulary and the SQL construct-to-operator map used for targeted generation. |
| [`motivation/`](motivation/) | The TPC-DS structural-collapse growth curve (Figure 2). |
| [`analysis/`](analysis/) | Section 6 tables (1–5) and figures (1 and 4). |

Workloads are generated with `notebooks/generate_baseline_queries.ipynb` or `Lakehouse.generate_workload` in `lakehouse/`. Paths and shared settings come from the repo-root `config.py`.
