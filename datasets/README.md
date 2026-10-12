# Datasets: TPC-DS

The evaluation uses TPC-DS, stored as unpartitioned Parquet in Apache Iceberg tables. Data is generated with the [`iceberg-spark-tpcds-benchmark`](https://github.com/MOBIN-F/iceberg-spark-tpcds-benchmark) submodule in `third_party/`. That submodule also bundles `tpcds-kit`, whose `dsqgen` produces the TPC-DS reference and growth-curve workloads.

| File | Purpose |
|---|---|
| `tpcds.json` | Schema definition read by the DiverSQL generator and the baselines (`config.SCHEMA_DIR`): tables, columns and foreign-key relationships. |
| `generate_schema.py` | Rebuilds a schema JSON from a live Trino catalog by introspecting its tables and inferring foreign-key relationships. |

## Setup

Run the commands from the repo root.

1. Fetch the submodule, which is pinned at upstream commit `1d2e2c8`. Skip this if you cloned with `--recurse-submodules`.

   ```bash
   git submodule update --init third_party/iceberg-spark-tpcds-benchmark
   ```

2. Install Spark 3.2.1 and point `SPARK_HOME` at it:

   ```bash
   wget https://archive.apache.org/dist/spark/spark-3.2.1/spark-3.2.1-bin-hadoop3.2.tgz
   tar -xzf spark-3.2.1-bin-hadoop3.2.tgz
   export SPARK_HOME=$PWD/spark-3.2.1-bin-hadoop3.2
   ```

3. Generate the SF10 Iceberg tables into the lakehouse warehouse volume:

   ```bash
   (cd third_party/iceberg-spark-tpcds-benchmark && ./bin/dsdgen --output-location <warehouse path> --scale-factor 10 --iceberg)
   ```

   Register the tables with Trino using `lh.register_schema("tpcds", <warehouse path>, use_dot_db=True)` (see `notebooks/launch_lakehouse_tpcds.ipynb`).

4. Build `dsqgen`, which is needed only to regenerate the TPC-DS reference or growth-curve workloads:

   ```bash
   make -C third_party/iceberg-spark-tpcds-benchmark/thirdparty/tpcds-kit/tools OS=LINUX
   ```

   This builds `tools/dsqgen` (`config.DSQGEN_BIN`). The build output stays untracked inside the submodule.

## Regenerating `tpcds.json`

```bash
python datasets/generate_schema.py --host <trino host> --port 8080 --catalog iceberg --schema tpcds \
    --csv-sep $'\t' --output datasets/tpcds.json
```
