# Shared: static SQL features

Code shared by the DiverSQL generator (`src/`), the baselines (`baselines/`) and the analysis notebooks.
| File | Purpose |
|---|---|
| `sql_features.py` | Computes static, execution-free features for each query and aggregates them into the workload-level `metaheuristics` stored in every `generation_report.json`. |

## `sql_features.py`

- **`query_features(sql)`**: per-query counts (tables, columns, joins, aggregations, predicates, subqueries, CTEs, window functions, set operations, ...), query length, and a `complexity` label.

