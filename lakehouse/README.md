# Lakehouse: Trino / Iceberg deployment and workload execution

Deploys the evaluation lakehouse on Kubernetes and runs workloads against it. The setup is a Trino coordinator and workers over Apache Iceberg tables, with a Hive Metastore backed by Postgres. Each run captures `EXPLAIN` plans, per-query runtimes and node resource traces. Deployment settings live in `config.py`; paths and the shared Trino settings come from the repo-root `config.py`.

## Images

| Component | Image |
|---|---|
| Trino coordinator and workers (custom, with a node-metrics sidecar) | [`2570809n/trino-node-exporter`](https://hub.docker.com/r/2570809n/trino-node-exporter) |
| Node profiler (CPU, RAM and storage benchmarks before a run) | [`2570809n/node-profiler`](https://hub.docker.com/r/2570809n/node-profiler) |
| Hive Metastore | [`bde2020/hive`](https://hub.docker.com/r/bde2020/hive) |
| Metastore database | [`postgres:13`](https://hub.docker.com/_/postgres) |

The images are set in `lakehouses/lakehouse-tpcds.yaml` and `manifests/trino-worker.yaml.j2`.

## Files

| File | Purpose |
|---|---|
| `lakehouse.py` | The `Lakehouse` class: deploy or attach to a release, register schemas, run workloads, capture plans and compute workload diversity metrics. |
| `render.py` | Renders the Jinja manifests in `manifests/` from a values file in `lakehouses/`. |
| `kubernetes_helpers.py` | Applies, orders and deletes the rendered manifests through the Kubernetes API. |
| `hive.py` | Trino connections and Iceberg schema and table registration. |
| `workload.py` | `QueryWorkload` and `execute_sql`: runs queries sequentially and writes logs, runtimes and the run index. |
| `profile.py` | Triggers the node profiler on each Trino pod. |
| `resource_logger.py` | Starts and stops the metrics-logging sidecar on each Trino pod. |
| `resource_profile.py` | Snapshots node resource counters before and after a query and computes rates. |
| `scrape.py` | The metrics sidecar itself: a small HTTP server that scrapes local node and Trino metrics to CSV. |
| `config.py` | Deployment timeout, in-cluster Trino port, raw-results mount and logging port. |
| `lakehouses/lakehouse-tpcds.yaml` | Values for the paper's deployment: one coordinator and two workers, each 4 vCPUs and 16 GB. |
| `manifests/*.yaml.j2` | Kubernetes templates for Trino, the Hive Metastore, Postgres and the services. |

Fill in `namespace`, the node names and the PVC names in `lakehouses/lakehouse-tpcds.yaml` for your cluster before deploying.
