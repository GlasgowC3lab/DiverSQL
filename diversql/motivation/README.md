# Motivation: structural collapse at scale

Produces the TPC-DS structural-collapse growth-curve figure. All paths and Trino settings come from the repo-root `config.py`.

| File | Purpose |
|---|---|
| `growth_curve_gen.py` | Runs the TPC-DS `dsqgen` tool to generate 10,000+ queries and normalises them into Trino-compatible `q*.sql` files under `GROWTH_CURVE_WORKLOAD_DIR`. |
| `growth_curve_capture_plans.py` | Runs `EXPLAIN` for every query in that workload against the live Trino instance and saves the parsed plan DAGs to `plans.json`. |
| `tpcds_structural_collapse_growth_curve.ipynb` | Reads `plans.json`, tracks distinct plan shapes and the share of collapsed queries as N grows, and saves the figure to `FIGURES_DIR`. |

To reproduce the figure only, run the notebook; it needs just the shipped `plans.json`. To rebuild the workload from scratch:

```bash
python diversql/motivation/growth_curve_gen.py            # needs third_party/tpcds-kit
python diversql/motivation/growth_curve_capture_plans.py  # needs TRINO_HOST set in config.py
```
