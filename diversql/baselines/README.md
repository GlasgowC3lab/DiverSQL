# Baselines

Related-work SQL workload generators, re-implemented for the Trino / Iceberg lakehouse. Every baseline reuses the same schema loading, LLM client and `EXPLAIN` validation as DiverSQL, so only the generation pipeline differs. Each one writes the same output: one `q<i>.sql` per query plus a `generation_report.json`.

| File | Baseline |
|---|---|
| `sqlstorm.py` | **SQLStorm**: a fixed suite of seven prompts over the full schema, followed by clean-up, LLM rewriting to Trino SQL and selection by `EXPLAIN`. Schmidt et al., *SQLStorm: Taking Database Benchmarking into the LLM Era*, PVLDB 18(11), 2025. |
| `sqlbarber.py` | **SQLBarber**: LLM-generated SQL templates with self-correction, then Bayesian optimisation of predicate values to match a target cost distribution. Lao & Trummer, *SQLBarber: A System Leveraging Large Language Models to Generate Customized and Realistic SQL Workloads*, SIGMOD 2026 (arXiv:2507.06192). |
| `e2etune.py` | **E2ETune**: the OLAP workload-generation component, using a structured prompt with sampled live predicate values and an `EXPLAIN` repair loop. Yao et al., *E2ETune: End-to-End Knob Tuning via Fine-tuned Generative Language Model*, PVLDB 18(5), 2025. |
| `bootstrapping_lcm.py` | **Bootstrapping-LCM (DiGiT)**: enumerates connected foreign-key subschemas and steers prompts towards under-covered SQL operations using a running coverage report. Nidd et al., *Bootstrapping Learned Cost Models with Synthetic SQL Queries*, VLDB 2025 AIDB Workshop (arXiv:2508.19807). |
| `sql_factory.py` | **SQL-Factory**: multi-agent generation, expansion and management teams that filter queries by `EXPLAIN` and a similarity gate. Li et al., *SQL-Factory: A Multi-Agent Framework for High-Quality and Large-Scale SQL Generation*, arXiv:2504.14837. |

## Shared code

| File | Purpose |
|---|---|
| `common.py` | `BaselineContext`, the context builders (`context_from_lakehouse`, `context_from_factories`), `EXPLAIN` validation, cost profiling and `write_baseline_workload`. |
| `query_generator.py` | Schema loading, live DDL introspection, the LLM client with retry and back-off, and SQL sanitising. |
| `__init__.py` | `BASELINES`, a registry mapping each baseline name to its `generate_workload` function. |

Shared settings (`WORKLOADS_DIR`, `SCHEMA_DIR`, the LLM endpoint and the Trino connection) come from the repo-root `config.py`. Baseline-specific settings stay at the top of each file.

## Usage

```python
from diversql.baselines import BASELINES
from diversql.baselines.common import context_from_lakehouse

ctx = context_from_lakehouse(lakehouse, schema="tpcds")
BASELINES["sqlstorm"](ctx, workload_name="sqlstorm_tpcds", num_queries=1000)
```
