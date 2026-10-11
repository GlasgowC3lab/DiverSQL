# Analysis: Section 6 tables and figures

Notebooks that produce the workload-diversity results of Section 6 for the eight TPC-DS workloads: the TPC-DS (1000) reference, five baselines, and DiverSQL with and without operator feedback. Paths come from the repo-root `config.py`. Run every notebook from this directory.

## Notebooks

| Notebook | Produces | Needs |
|---|---|---|
| `analyse_diversity.ipynb` | `results/analysis/workload_metrics.csv`: plan and schema diversity metrics per workload | a deployed lakehouse (runs `EXPLAIN`) |
| `check_cosine_vendi.ipynb` | `gin_vendi/plan_vendi_gin_cosine.csv`: the Vendi (cosine) column of Table 4 | `workloads/<w>/plans.json`; a GPU makes training quicker |
| `tables.ipynb` | Tables 1–5 as `.csv` and `.tex` in `results/tables/` | the two outputs above, `workloads/`, `results/parsed_results/` and `sqlglot` |
| `plan_collision_figure.ipynb` | Figure 1, `results/figures/plan_collision_example.{png,pdf}` | `workloads/tpcds/plans.json` |
| `runtime_distribution_figure.ipynb` | Figure 4, `results/figures/runtimes.{pdf,png}` | `results/parsed_results/` |

Run order: `analyse_diversity`, then `check_cosine_vendi`, then `tables`. The two figure notebooks can run at any point. If the shipped `workload_metrics.csv` and GIN Vendi CSV are present, skip the first two and go straight to `tables`.

## Tables in `tables.ipynb`

| Paper table | Content | Source |
|---|---|---|
| Table 1 | Query text and operator structure | static analysis of `workloads/<w>/q*.sql` |
| Table 2 | Workload runtime distribution | `runtimes.csv` of each execution run |
| Table 3 | Generation overhead | `workloads/<w>/generation_report.json` |
| Table 4 | Structural diversity of compiled plans | `workload_metrics.csv` + GIN Vendi CSV |
| Table 5 | Schema diversity | `workload_metrics.csv` |

## Supporting modules

| File | Purpose |
|---|---|
| `workloads.py` | The eight workloads, their paper labels, the execution run for each, and loaders for SQL, generation reports, runtimes and metrics. |
| `analysis.py` | Plan capture and per-workload metric computation used by `analyse_diversity.ipynb` and `plan_collision_figure.ipynb`. |

## Notes

- **`sqlglot` is required for Table 1.** Without it, `query_features` falls back to a regex tokeniser and Table Scan, Join, Select and Nesting change. `tables.ipynb` checks for it.

- Figure 2 (the TPC-DS growth curve) is produced in `../motivation/`.
