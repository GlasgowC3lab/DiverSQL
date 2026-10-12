# QPP evaluation

The query performance prediction (QPP) experiments of Section 7: six model families trained on each workload and scored on held-out queries from workloads they have not seen, in a cold-start setting (generated queries only) and a hybrid setting (a TPC-DS log plus one generator's workload). Labels are the per-query runtimes in `results/parsed_results/`, produced by `notebooks/parse_raw_results.ipynb`.

## Directories

| Directory | Contents |
|---|---|
| [`models/`](models/) | The six model families (Random Forest, XGBoost, LightGBM, MLP, GP-RBF and MSCN), the GIN plan encoder, and the data splits and helpers they share. |
| [`cold/`](cold/) | Cold-start setting (Section 7.2). `01_offline_training_and_testing.ipynb` trains every model on nested subsets of each workload; `02_paper_qpp_table_and_plot.ipynb` builds Table 6 and Figure 5 from `results/`. |
| [`hybrid/`](hybrid/) | Hybrid setting (Section 7.3). `legs.py` defines the workloads and the blended held-out set, `pools.py` builds each arm's training pool, and `sweep.py` runs the sweep and loads its results. `01_hybrid_training_and_testing.ipynb` runs the sweep; `02_paper_hybrid_table_and_plots.ipynb` builds Table 7 and Figures 6 and 7 from `results/`. |

Each experiment keeps its results next to its notebooks: `cold/results/cold_start_dose_response_offline_qpp_results.csv` and `hybrid/results/hybrid_results_<stamp>.csv` (with its `hybrid_config_<stamp>.json`).

## Files

| File | Purpose |
|---|---|
| `config.py` | QPP settings shared by both settings: the runtime metric and columns, seed, test fraction, and the schema, lakehouse instance and executed run of each workload. |
| `qpp_harness.py` | Loads plans and runtimes into train/test bundles, fits the plan encoder, and trains and scores every model family with one shared set of metrics. |
| `results_lib.py` | Display names, colours, metric directions and the seed/test-workload aggregation used by the cold-start results notebook. |

## Running

Run the notebooks from inside `cold/` or `hybrid/`; each finds the repo root and imports from `qpp`. The `01_*` notebooks need the parsed runs listed in `config.WORKLOAD_RUNS` under `results/parsed_results/`. They also need `workloads/tpcds_1200/`, whose `generation_report.json` defines the TPC-DS held-out templates; `hybrid/02_*` needs it too, as it imports `legs.py` through `sweep.py`. The `02_*` notebooks only read saved results, so the paper's tables and figures can be rebuilt without retraining.
