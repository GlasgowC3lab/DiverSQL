"""Stage raw lakehouse run outputs into per-query runtimes, metric traces and node profiles under PARSED_RESULTS_DIR."""
import json
import logging
from pathlib import Path
from typing import Dict, List, Tuple, Optional

import numpy as np
import pandas as pd

from config import PARSED_RESULTS_DIR

# Raw-results roots to search, in priority order. A run's data lives entirely under one root;
# roots are tried in order until the run's instance dir is found and are never merged.
RESULTS_ROOTS = [
    Path("/mnt/lakehouse-raw-results-2"),
    Path("/mnt/lakehouse-raw-results"),
]

# Aggregating traces from workers
DEFAULT_CORES_PER_WORKER = 48
WORKER_CORE_MAP = {}
NODE_GLOB = "trino-worker-*_metrics.csv"
GRID_POINTS = 400

# Metrics CSV schema
TIME_COL = "epoch_ms"             # milliseconds since epoch
CPU_COUNTER = "process_cpu_s"     # counter (seconds)
IDLE_COUNTER = "node_cpu_idle_s"  # counter (seconds) [not required for util%]
MEM_GAUGE = "trino_mem_bytes"     # gauge (bytes)
READ_COUNTER = "trino_read_bytes" # counter (bytes)
TX_COUNTER = "http_sent_bytes"    # counter (bytes)
RX_COUNTER = "http_recv_bytes"    # counter (bytes)

QID_COL = "trino_query_id"
ATTEMPT_COL = "attempt"
QNAME_COL = "query_name"

REQUIRED_COLS = [
    TIME_COL, CPU_COUNTER, MEM_GAUGE, READ_COUNTER, TX_COUNTER, RX_COUNTER,
    QID_COL, ATTEMPT_COL, QNAME_COL
]

ALSO_STAGE_COORD = True
COORD_METRICS_GLOB = "trino-coord-pod-*_metrics.csv"

# Parsing toggles
PARSE_METRICS = True
PARSE_PROFILES = True
ALLOW_PROFILE_ONLY_RUNS = True

# Node profiler snapshots
PROFILE_DIR_NAME = "profiles"
PROFILE_GLOB = "*_node_profiles.csv"
PROFILE_OUTPUT_NAME = "node_profiles.csv"

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")


def _existing_instance_roots(schema: str, instance: str) -> List[Path]:
    """
    Return <root>/<schema>/<instance> for every configured raw-results root
    that actually exists, in RESULTS_ROOTS priority order.
    """
    candidates = [Path(root) / schema / instance for root in RESULTS_ROOTS]
    return [p for p in candidates if p.exists()]


def _resolve_run_dir(instance_roots: List[Path], run_id: str) -> Optional[Path]:
    """
    Find <instance_root>/<run_id> across instance_roots, in order. A run's
    data lives entirely under one root, so the first match wins.
    """
    for instance_root in instance_roots:
        run_dir = instance_root / run_id
        if run_dir.exists():
            return run_dir
    return None


def find_run_dir(schema: str, instance: str, run_id: str) -> Optional[Path]:
    """
    Locate <root>/<schema>/<instance>/<run_id> by searching every configured
    raw-results root (RESULTS_ROOTS) in order. Returns None if the run
    isn't present under any of them.
    """
    return _resolve_run_dir(_existing_instance_roots(schema, instance), run_id)


def write_query_runtimes_csv(run_dir: Path, out_dir: Path) -> Optional[Path]:
    """
    Read workload_log.ndjson for a run and write
    <run_dir>/queries/runtimes.csv

    CSV columns:
      - query_id (trino_query_id)
      - runtime_s

    Returns the path written, or None if workload_log.ndjson is missing.
    """
    wl_path = run_dir / "workload_log.ndjson"
    if not wl_path.exists():
        return None

    rows = []
    with wl_path.open("r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue

            rec = json.loads(line)

            qid = rec.get("query_name")
            runtime = rec.get("runtime_s")

            if qid is None or runtime is None:
                continue

            rows.append({
                "query_id": str(qid),
                "runtime_s": float(runtime),
            })

    if not rows:
        return None

    out_dir.mkdir(parents=True, exist_ok=True)

    out_path = out_dir / "runtimes.csv"
    pd.DataFrame(rows).to_csv(out_path, index=False)

    return out_path


def _add_sanitised_time_cols(df: pd.DataFrame) -> pd.DataFrame:
    """
    Add t_rel_s and tau based on the trace's own t_s range.
    Keeps original t_s for debugging.
    """
    df = df.copy()
    t0 = float(df["t_s"].iloc[0])
    t1 = float(df["t_s"].iloc[-1])
    df["t_rel_s"] = df["t_s"] - t0
    dur = max(t1 - t0, 1e-12)
    df["tau"] = (df["t_s"] - t0) / dur
    return df


def cores_for_worker(csv_path: Path) -> int:
    name = csv_path.stem.replace("_metrics", "")
    for key, cores in WORKER_CORE_MAP.items():
        if key in name:
            return int(cores)
    return int(DEFAULT_CORES_PER_WORKER)


def _ms_to_s(x: np.ndarray) -> np.ndarray:
    return x.astype(float) / 1000.0


def _safe_rate(t_s: np.ndarray, v: np.ndarray) -> np.ndarray:
    if t_s.size < 2:
        return np.zeros_like(t_s, dtype=float)
    dt = np.diff(t_s)
    dv = np.diff(v)
    rate = np.divide(dv, dt, out=np.zeros_like(dv, dtype=float), where=dt > 0)
    return np.concatenate(([rate[0]], rate))


def _load_and_clean_node_csv(p: Path) -> pd.DataFrame:
    df = pd.read_csv(p)

    missing = [c for c in REQUIRED_COLS if c not in df.columns]
    if missing:
        raise ValueError(f"{p.name} missing columns: {missing}")

    # time -> seconds
    t_s = _ms_to_s(pd.to_numeric(df[TIME_COL], errors="coerce").to_numpy())
    df = df.copy()
    df["t_s"] = t_s

    # numeric conversions
    for c in [CPU_COUNTER, IDLE_COUNTER, MEM_GAUGE, READ_COUNTER, TX_COUNTER, RX_COUNTER]:
        if c in df.columns:
            df[c] = pd.to_numeric(df[c], errors="coerce")

    # attempt might be float with NaNs; keep as numeric for now
    df[ATTEMPT_COL] = pd.to_numeric(df[ATTEMPT_COL], errors="coerce")

    # clean time
    df = df.dropna(subset=["t_s"]).sort_values("t_s")
    df = df.loc[~df["t_s"].duplicated(keep="first")]

    # keep ids/names as strings (allow NA)
    df[QID_COL] = df[QID_COL].astype("string")
    df[QNAME_COL] = df[QNAME_COL].astype("string")

    return df


def _node_traces_for_query(df_q: pd.DataFrame) -> Dict[str, pd.DataFrame]:
    """
    df_q is already filtered to a single (trino_query_id, attempt) within one worker.
    """
    t_s = df_q["t_s"].to_numpy(dtype=float)

    cpu_cores = _safe_rate(t_s, df_q[CPU_COUNTER].to_numpy(dtype=float))
    disk_read_bps = _safe_rate(t_s, df_q[READ_COUNTER].to_numpy(dtype=float))
    net_tx_bps = _safe_rate(t_s, df_q[TX_COUNTER].to_numpy(dtype=float))
    net_rx_bps = _safe_rate(t_s, df_q[RX_COUNTER].to_numpy(dtype=float))
    mem_bytes = df_q[MEM_GAUGE].to_numpy(dtype=float)

    return {
        "cpu_cores": pd.DataFrame({"t_s": t_s, "value": cpu_cores}),
        "disk_read_Bps": pd.DataFrame({"t_s": t_s, "value": disk_read_bps}),
        "net_tx_Bps": pd.DataFrame({"t_s": t_s, "value": net_tx_bps}),
        "net_rx_Bps": pd.DataFrame({"t_s": t_s, "value": net_rx_bps}),
        "memory_bytes": pd.DataFrame({"t_s": t_s, "value": mem_bytes}),
    }


def _resample(df: pd.DataFrame, t_grid: np.ndarray) -> np.ndarray:
    t = df["t_s"].to_numpy(dtype=float)
    y = df["value"].to_numpy(dtype=float)
    if t.size < 2:
        return np.zeros_like(t_grid, dtype=float)
    return np.interp(t_grid, t, y)


def _aggregate_cluster(
    node_trace_dicts: List[Dict[str, pd.DataFrame]],
    *,
    total_cluster_cores: int,
    grid_points: int,
) -> Dict[str, pd.DataFrame]:
    metric_names = sorted(set().union(*[set(d.keys()) for d in node_trace_dicts]))
    cluster: Dict[str, pd.DataFrame] = {}

    for m in metric_names:
        dfs = [d[m] for d in node_trace_dicts if m in d and not d[m].empty]
        if not dfs:
            continue

        t0 = max(float(df["t_s"].iloc[0]) for df in dfs)
        t1 = min(float(df["t_s"].iloc[-1]) for df in dfs)
        if not np.isfinite(t0) or not np.isfinite(t1) or t1 <= t0:
            continue

        t_grid = np.linspace(t0, t1, grid_points)
        ys = np.vstack([_resample(df, t_grid) for df in dfs])

        y_cluster = ys.sum(axis=0)
        cluster[m] = pd.DataFrame({"t_s": t_grid, "value": y_cluster})

    if "cpu_cores" in cluster and total_cluster_cores > 0:
        cpu = cluster["cpu_cores"]
        util = 100.0 * cpu["value"].to_numpy(dtype=float) / float(total_cluster_cores)
        cluster["cpu_util_percent"] = pd.DataFrame({"t_s": cpu["t_s"], "value": util})

    return cluster


def _safe_dirname(s: str) -> str:
    return "".join(c if c.isalnum() or c in ("-", "_", ".") else "_" for c in s)


def _load_profiles_for_run(profiles_dir: Path) -> pd.DataFrame:
    """
    Load all *_node_profiles.csv files from a raw run's profiles/ directory.

    Expected raw layout:
      <run_dir>/profiles/<node>_node_profiles.csv

    Expected columns include:
      - query_id
      - profile_type
      - node_name
      - node_ip
      - hardware / benchmark columns
    """
    if not profiles_dir.exists():
        return pd.DataFrame()

    profile_csvs = sorted(
        profiles_dir.glob(PROFILE_GLOB)
    )
    if not profile_csvs:
        return pd.DataFrame()

    frames = []

    for p in profile_csvs:
        try:
            df = pd.read_csv(p)
        except Exception as e:
            logging.warning("Failed to read profile file %s: %s", p.name, e)
            continue

        if df.empty:
            continue

        if "query_id" not in df.columns:
            logging.warning("Skipping profile file %s because it has no query_id column", p.name)
            continue

        if "profile_type" not in df.columns:
            logging.warning("Skipping profile file %s because it has no profile_type column", p.name)
            continue

        df = df.copy()
        df["source_profile_file"] = p.name

        # Normalise identifiers.
        df["query_id"] = df["query_id"].astype("string").str.strip()
        df["profile_type"] = df["profile_type"].astype("string").str.strip().str.lower()

        # Drop rows that cannot be mapped to a query directory.
        df = df.dropna(subset=["query_id"])

        frames.append(df)

    if not frames:
        return pd.DataFrame()

    profiles = pd.concat(frames, ignore_index=True)

    # Keep a stable ordering.
    sort_cols = [
        c for c in [
            "query_id",
            "profile_type",
            "node_name",
            "pod_name",
            "profile_launched_at",
            "source_profile_file",
        ]
        if c in profiles.columns
    ]

    if sort_cols:
        profiles = profiles.sort_values(sort_cols).reset_index(drop=True)

    return profiles

def _write_profiles_to_query_dirs(
    profiles: pd.DataFrame,
    run_out: Path,
    *,
    filename: str = "node_profiles.csv",
    only_existing_query_dirs: bool = True,
) -> int:
    if profiles.empty:
        return 0

    if "query_id" not in profiles.columns:
        raise KeyError("profiles DataFrame missing query_id")

    wrote = 0

    for query_id, df_q in profiles.groupby("query_id", dropna=True):
        query_id = str(query_id).strip()
        if not query_id:
            continue

        qdir = run_out / _safe_dirname(query_id)

        if only_existing_query_dirs and not qdir.exists():
            continue

        qdir.mkdir(parents=True, exist_ok=True)

        out_path = qdir / filename
        df_q.to_csv(out_path, index=False)
        wrote += 1

    return wrote
    
def _extract_query_keys(df: pd.DataFrame) -> List[Tuple[str, int]]:
    """
    Return list of (trino_query_id, attempt_int) present in df, ignoring gap rows.
    """
    mask = df[QID_COL].notna() & df[ATTEMPT_COL].notna()
    if not mask.any():
        return []

    qid = df.loc[mask, QID_COL].astype("string")
    att = df.loc[mask, ATTEMPT_COL].astype("Int64")  # nullable int

    # Drop any remaining NA after coercion
    good = qid.notna() & att.notna()
    if not good.any():
        return []

    pairs = pd.DataFrame({"qid": qid[good].astype(str), "att": att[good].astype(int)})
    pairs = pairs.drop_duplicates()
    return list(map(tuple, pairs.to_records(index=False)))


def parse_results(
    *,
    schema,
    instance,
    run_ids,
    collection,
    parse_metrics=PARSE_METRICS,
    parse_profiles=PARSE_PROFILES,
) -> None:
    
    node_glob = NODE_GLOB
    
    coord_glob = COORD_METRICS_GLOB
    also_stage_coord = bool(ALSO_STAGE_COORD)
    
    allow_profile_only_runs = bool(ALLOW_PROFILE_ONLY_RUNS)

    profile_dir_name = PROFILE_DIR_NAME
    profile_output_name = PROFILE_OUTPUT_NAME

    grid_points = int(GRID_POINTS)

    results_instance_roots = _existing_instance_roots(schema, instance)
    out_root = PARSED_RESULTS_DIR / collection / schema / instance

    if not results_instance_roots:
        searched = [Path(root) / schema / instance for root in RESULTS_ROOTS]
        raise SystemExit(f"Missing Results instance dir in any root: {searched}")

    out_root.mkdir(parents=True, exist_ok=True)

    logging.info("Results roots: %s", results_instance_roots)
    logging.info("Output : %s", out_root)
    logging.info("Node glob: %s", node_glob)
    logging.info("Coord glob: %s", coord_glob)
    logging.info("Also stage coord: %s", also_stage_coord)
    logging.info("Parse metrics: %s", parse_metrics)
    logging.info("Parse profiles: %s", parse_profiles)
    logging.info("Allow profile-only runs: %s", allow_profile_only_runs)
    logging.info("Grid points per query: %d", grid_points)

    for run_id in run_ids:
        run_dir = _resolve_run_dir(results_instance_roots, run_id)

        if run_dir is None:
            logging.warning(
                "Skipping missing run dir %r in any root: %s",
                run_id,
                results_instance_roots,
            )
            continue

        run_out = out_root / run_id / "queries"
        run_out.mkdir(parents=True, exist_ok=True)

        # ------------------------------------------------------------
        # Optional node profiling snapshots
        # ------------------------------------------------------------
        profiles_df = pd.DataFrame()

        if parse_profiles:
            profiles_dir = run_dir / profile_dir_name
            profiles_df = _load_profiles_for_run(profiles_dir)

            if profiles_df.empty:
                logging.info("Run %s -> no profiles/ data found", run_id)
            else:
                logging.info(
                    "Run %s -> loaded %d profile rows",
                    run_id,
                    len(profiles_df),
                )
        else:
            logging.info("Run %s -> profile parsing disabled", run_id)

        # ------------------------------------------------------------
        # Optional continuous metrics parsing
        # ------------------------------------------------------------
        worker_csvs: List[Path] = []
        coord_csvs: List[Path] = []
        node_csvs: List[Path] = []

        if parse_metrics:
            worker_csvs = sorted(run_dir.glob(node_glob))
            coord_csvs = sorted(run_dir.glob(coord_glob)) if also_stage_coord else []

            # If ALSO_STAGE_COORD is enabled, coordinator metrics are aggregated
            # into the same cluster-level traces as the workers.
            node_csvs = worker_csvs + coord_csvs

            logging.info(
                "Run %s -> found %d worker CSVs and %d coordinator CSVs",
                run_id,
                len(worker_csvs),
                len(coord_csvs),
            )
        else:
            logging.info("Run %s -> metrics parsing disabled", run_id)

        has_metrics = bool(node_csvs)
        has_profiles = not profiles_df.empty

        if not has_metrics and not has_profiles:
            # No continuous metrics/profiles for this run (e.g. profiler was
            # disabled) -- still stage the one thing workload_log.ndjson can
            # always give us: total per-query wall-clock runtime.
            rt_csv = write_query_runtimes_csv(run_dir, run_out)
            if rt_csv:
                logging.info("Wrote query runtimes -> %s", rt_csv)

            logging.warning(
                "Run %s -> no metrics/profiles data found (metrics=%s, profiles=%s); "
                "wrote runtimes.csv only",
                run_id,
                parse_metrics,
                parse_profiles,
            )
            continue

        if not has_metrics and has_profiles:
            if not allow_profile_only_runs:
                logging.warning(
                    "Skipping run %s because metric CSVs are missing and "
                    "profile-only parsing is disabled",
                    run_id,
                )
                continue

            wrote_profiles = _write_profiles_to_query_dirs(
                profiles_df,
                run_out,
                filename=profile_output_name,
                only_existing_query_dirs=False,
            )

            rt_csv = write_query_runtimes_csv(run_dir, run_out)
            if rt_csv:
                logging.info("Wrote query runtimes -> %s", rt_csv)

            logging.info(
                "Run %s -> profile-only parse wrote %s for %d query directories",
                run_id,
                profile_output_name,
                wrote_profiles,
            )
            continue

        # From here onwards, metrics exist and are enabled.
        logging.info(
            "Run %s -> staging %d worker CSVs and %d coordinator CSVs",
            run_id,
            len(worker_csvs),
            len(coord_csvs),
        )

        core_map = {p.name: cores_for_worker(p) for p in node_csvs}
        total_cluster_cores = int(sum(core_map.values()))

        node_dfs: Dict[str, pd.DataFrame] = {}

        for p in node_csvs:
            try:
                node_dfs[p.name] = _load_and_clean_node_csv(p)
            except Exception as e:
                logging.warning("Failed node file %s: %s", p.name, e)

        if not node_dfs:
            if has_profiles and allow_profile_only_runs:
                wrote_profiles = _write_profiles_to_query_dirs(
                    profiles_df,
                    run_out,
                    filename=profile_output_name,
                    only_existing_query_dirs=False,
                )

                rt_csv = write_query_runtimes_csv(run_dir, run_out)
                if rt_csv:
                    logging.info("Wrote query runtimes -> %s", rt_csv)

                logging.warning(
                    "Run %s -> no readable node CSVs; fell back to profile-only "
                    "parse and wrote %s for %d query directories",
                    run_id,
                    profile_output_name,
                    wrote_profiles,
                )
                continue

            logging.warning("Skipping run %s (no readable node CSVs)", run_id)
            continue

        qkeys = set()

        for df in node_dfs.values():
            qkeys.update(_extract_query_keys(df))

        if not qkeys:
            if has_profiles and allow_profile_only_runs:
                wrote_profiles = _write_profiles_to_query_dirs(
                    profiles_df,
                    run_out,
                    filename=profile_output_name,
                    only_existing_query_dirs=False,
                )

                rt_csv = write_query_runtimes_csv(run_dir, run_out)
                if rt_csv:
                    logging.info("Wrote query runtimes -> %s", rt_csv)

                logging.warning(
                    "Run %s -> no query keys found in metrics; fell back to "
                    "profile-only parse and wrote %s for %d query directories",
                    run_id,
                    profile_output_name,
                    wrote_profiles,
                )
                continue

            logging.warning("Run %s: no query keys found (all gaps?)", run_id)
            continue

        rt_csv = write_query_runtimes_csv(run_dir, run_out)
        if rt_csv:
            logging.info("Wrote query runtimes -> %s", rt_csv)

        wrote = 0

        for qid, attempt in sorted(qkeys):
            node_traces: List[Dict[str, pd.DataFrame]] = []
            qname_seen: Optional[str] = None
            nodes_used: List[str] = []

            for node_name, df in node_dfs.items():
                # Filter to query rows only, ignoring gap rows.
                m = (
                    df[QID_COL].notna()
                    & df[ATTEMPT_COL].notna()
                    & (df[QID_COL].astype("string") == str(qid))
                    & (df[ATTEMPT_COL].astype("Int64") == int(attempt))
                )

                df_q = df.loc[m]

                if df_q.empty:
                    continue

                if qname_seen is None and QNAME_COL in df_q.columns:
                    qname_seen = str(df_q[QNAME_COL].iloc[0])

                traces = _node_traces_for_query(df_q)

                if traces:
                    node_traces.append(traces)
                    nodes_used.append(node_name)

            if not node_traces:
                continue

            cluster = _aggregate_cluster(
                node_traces,
                total_cluster_cores=total_cluster_cores,
                grid_points=grid_points,
            )

            if not cluster:
                continue

            qname_dir = _safe_dirname(qname_seen or "unknown_query")
            out_q = run_out / qname_dir
            out_q.mkdir(parents=True, exist_ok=True)

            for name, df_out in cluster.items():
                df_out = _add_sanitised_time_cols(df_out)
                df_out.to_parquet(out_q / f"{name}.parquet", index=False)

            meta = {
                "collection": collection,
                "schema": schema,
                "instance": instance,
                "run_id": run_id,
                "query_name": qname_seen,
                "trino_query_id": str(qid),
                "attempt": int(attempt),

                "parse_metrics": parse_metrics,
                "parse_profiles": parse_profiles,

                "node_glob": node_glob,
                "coord_glob": coord_glob,
                "includes_coordinator": also_stage_coord,

                "worker_csv_count": len(worker_csvs),
                "coord_csv_count": len(coord_csvs),

                "nodes_used": nodes_used,
                "node_cores": {n: core_map.get(n) for n in nodes_used},
                "total_cluster_cores": total_cluster_cores,

                "grid_points": grid_points,
                "outputs": sorted([f"{k}.parquet" for k in cluster.keys()]),

                # These are deliberately nullable because profile parsing can be
                # disabled, absent, or written after metric parsing.
                "has_node_profiles": None,
                "node_profiles_file": None,
            }

            (out_q / "_meta.json").write_text(
                json.dumps(meta, indent=2),
                encoding="utf-8",
            )

            wrote += 1

        # Write optional node profiling snapshots after all parsed query dirs exist.
        # This avoids creating profile-only directories during a normal metrics parse.
        if has_profiles:
            wrote_profiles = _write_profiles_to_query_dirs(
                profiles_df,
                run_out,
                filename=profile_output_name,
                only_existing_query_dirs=True,
            )

            logging.info(
                "Run %s -> wrote %s for %d existing query directories",
                run_id,
                profile_output_name,
                wrote_profiles,
            )
        elif parse_profiles:
            logging.info("Run %s -> no profiles/ data found", run_id)

        logging.info("Run %s -> wrote %d metric query directories", run_id, wrote)

    logging.info("Done.")