"""Load SQL workloads, execution logs, plan bundles and per-query runtime traces."""
import json
import re
from collections import Counter
from pathlib import Path
from typing import Any, Callable, Dict, Iterable, Iterator, List, Optional, Tuple, Union

import numpy as np
import pandas as pd

from utils.parser import build_trino_dag, iter_edges

NODE_PROFILE_FEATURE_COLS = [
    "node_name",
    "profile_type",
    "cpu_speed_st_events_per_second",
    "cpu_speed_mt_events_per_second",
    "ram_speed_gb_s",
    "ceph_io_sequ_read_iops",
    "ceph_io_sequ_read_bw_mb",
    "ceph_io_sequ_read_lat_us",
]


# -----------------------------------------------------------------------------
# General helpers
# -----------------------------------------------------------------------------

_QID_RE = re.compile(r"^q(\d+)$")

def make_query_run_id(query_name: str, run_id: str, sep: str = "@") -> str:
    """
    Build a stable identifier for one execution of one query.

    Example
    -------
    make_query_run_id("q1", "20260424-115247Z")
    -> "q1@20260424-115247Z"
    """
    return f"{str(query_name)}{sep}{str(run_id)}"


def split_query_run_id(query_run_id: str, sep: str = "@") -> tuple[str, str]:
    """
    Split a query-run identifier back into query_name and run_id.
    """
    q, run_id = str(query_run_id).split(sep, 1)
    return q, run_id


def _qid_key(qid: str) -> int:
    """
    Convert 'q12' -> 12 for sorting. Falls back to a large number if unexpected.
    """
    m = _QID_RE.match(str(qid))
    return int(m.group(1)) if m else 10**9


def _is_query_dir_name(name: str) -> bool:
    """
    Return True for parsed query directories such as q1, q10, q500.
    Skips folders such as .ipynb_checkpoints.
    """
    return _QID_RE.match(str(name)) is not None


def canonicalise_dict_keys(
    data: Dict[str, Any],
    canon_fn: Optional[Callable[[str], str]] = None,
) -> Dict[str, Any]:
    """
    Return a new dictionary with canonicalised string keys.

    Parameters
    ----------
    data : dict
        Mapping keyed by query id.
    canon_fn : callable or None
        Canonicalisation function. If None, keys are returned unchanged.
    """
    if canon_fn is None:
        return dict(data)

    out: Dict[str, Any] = {}

    for k, v in data.items():
        try:
            out[canon_fn(k)] = v
        except Exception:
            continue

    return out


# -----------------------------------------------------------------------------
# Trace paths
# -----------------------------------------------------------------------------

def trace_dir(
    run_id: str,
    query_name: str | None,
    collection: str,
    schema: str,
    instance: str,
    parsed_results_root: str | Path,
) -> Path:
    """
    Build the parsed trace directory path.

    If query_name is None:
        <parsed_root>/<collection>/<schema>/<instance>/<run_id>/queries

    Else:
        <parsed_root>/<collection>/<schema>/<instance>/<run_id>/queries/<query_name>
    """
    parsed_results_root = Path(parsed_results_root).resolve()

    base = (
        parsed_results_root
        / collection
        / schema
        / instance
        / run_id
        / "queries"
    )

    return base / query_name if query_name else base


def build_run_dirs(
    run_ids: Iterable[str],
    *,
    collection: str,
    schema: str,
    instance: str,
    parsed_results_root: str | Path,
) -> list[Path]:
    """
    Build parsed run directories for a set of run ids.
    """
    return [
        trace_dir(
            run_id=run_id,
            query_name=None,
            collection=collection,
            schema=schema,
            instance=instance,
            parsed_results_root=parsed_results_root,
        )
        for run_id in run_ids
    ]


# -----------------------------------------------------------------------------
# Plan loading
# -----------------------------------------------------------------------------

def iter_trino_dags(queries_dir: str | Path) -> Iterator[dict]:
    """
    Iterate over Trino DAGs from q*_explain.json files.
    """
    queries_dir = Path(queries_dir)

    for json_path in sorted(queries_dir.glob("q*_explain.json")):
        with json_path.open("r", encoding="utf-8") as f:
            plan = json.load(f)

        yield build_trino_dag(plan)


def iter_trino_dags_with_id(queries_dir: str | Path) -> Iterator[Tuple[str, Any]]:
    """
    Yield (qid, dag) in q1, q2, ... numeric order.

    Expected files:
        q1_001_explain.json
        q2_001_explain.json
        ...
    """
    queries_dir = Path(queries_dir)
    json_paths = list(queries_dir.glob("q*_explain.json"))

    def path_key(p: Path) -> int:
        stem = p.stem
        qid = stem.replace("_001_explain", "")
        return _qid_key(qid)

    for json_path in sorted(json_paths, key=path_key):
        qid = json_path.stem.replace("_001_explain", "")

        try:
            with json_path.open("r", encoding="utf-8") as f:
                plan = json.load(f)
        except Exception:
            continue

        yield qid, build_trino_dag(plan)


def load_plans_by_query(
    queries_dir: str | Path,
    *,
    canon_fn: Optional[Callable[[str], str]] = None,
) -> Dict[str, Any]:
    """
    Load Trino DAG plans from a query directory.

    Returns
    -------
    dict
        Mapping: query_id -> DAG
    """
    plans_by_query: Dict[str, Any] = {}

    for qid, dag in iter_trino_dags_with_id(queries_dir):
        try:
            qid2 = canon_fn(qid) if canon_fn is not None else qid
        except Exception:
            continue

        plans_by_query[qid2] = dag

    return plans_by_query


# -----------------------------------------------------------------------------
# Workload log loading
# -----------------------------------------------------------------------------

def iter_workload_log_records(workload_log_path: Union[str, Path]) -> Iterator[Dict[str, Any]]:
    """
    Yield dict records from a workload_log.ndjson.

    Skips blank lines and tolerates non-JSON lines by ignoring them.
    """
    p = Path(workload_log_path)

    with p.open("r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()

            if not line:
                continue

            try:
                yield json.loads(line)
            except json.JSONDecodeError:
                continue


# -----------------------------------------------------------------------------
# Metric trace loading
# -----------------------------------------------------------------------------

def gather_traces_by_query(
    run_dirs: List[Union[str, Path]],
    *,
    metric: str,
    xcol: str = "t_rel_s",
    ycol: str = "value",
    min_points: int = 2,
    sort_by_x: bool = True,
    run_ids: Optional[Iterable[str]] = None,
) -> Dict[str, List[pd.DataFrame]]:
    """
    Gather per-query metric traces across multiple run directories.

    Expected folder layout:
        <run_dir>/<query_name>/<metric>.parquet

    where <run_dir> is usually:
        <parsed_root>/<collection>/<schema>/<instance>/<run_id>/queries

    Returns
    -------
    dict
        runs_by_query[query_name] = [df_run_1, df_run_2, ...]

    Each DataFrame keeps the expected trace columns:
        [xcol, ycol]

    and stores alignment metadata in df.attrs:
        - run_id
        - query_name
        - metric
        - source_path
    """
    runs_by_query: Dict[str, List[pd.DataFrame]] = {}

    run_dirs = [Path(d) for d in run_dirs]

    if run_ids is None:
        resolved_run_ids = [
            d.parent.name if d.name == "queries" else d.name
            for d in run_dirs
        ]
    else:
        resolved_run_ids = list(run_ids)

    if len(resolved_run_ids) != len(run_dirs):
        raise ValueError(
            f"run_ids length ({len(resolved_run_ids)}) must match "
            f"run_dirs length ({len(run_dirs)})"
        )

    for run_id, run_dir in zip(resolved_run_ids, run_dirs):
        if not run_dir.exists():
            print(f"missing run dir: {run_dir}")
            continue

        for qdir in sorted(run_dir.iterdir(), key=lambda p: _qid_key(p.name)):
            if not qdir.is_dir():
                continue

            query_name = qdir.name

            if not _is_query_dir_name(query_name):
                continue

            p = qdir / f"{metric}.parquet"

            if not p.exists():
                continue

            try:
                df = pd.read_parquet(p)
            except Exception as e:
                print(f"failed to read trace file {p}: {e}")
                continue

            if not {xcol, ycol}.issubset(df.columns):
                continue

            df = df[[xcol, ycol]].dropna().copy()

            if sort_by_x:
                df = df.sort_values(xcol).reset_index(drop=True)

            if len(df) < int(min_points):
                continue

            df.attrs["run_id"] = run_id
            df.attrs["query_name"] = query_name
            df.attrs["metric"] = metric
            df.attrs["source_path"] = str(p)

            runs_by_query.setdefault(query_name, []).append(df)

    return runs_by_query


def load_runs_by_query(
    run_ids: Iterable[str],
    *,
    collection: str,
    schema: str,
    instance: str,
    metric: str,
    xcol: str,
    ycol: str,
    parsed_results_root: str | Path,
    canon_fn: Optional[Callable[[str], str]] = None,
    runtime_col: str = "runtime_s",
    query_col: str = "query_id",
    query_run_sep: str = "@",
    require_runtime: bool = True,
) -> Dict[str, List[pd.DataFrame]]:
    """
    Load metric traces and preserve run-level metadata for each trace DataFrame.

    Returns
    -------
    dict
        runs_by_query[query_name] = [df_run_1, df_run_2, ...]

    Each df has columns [xcol, ycol] plus metadata columns:
        - run_id
        - query_name
        - query_run_id
        - runtime_s

    and attrs:
        - run_id
        - query_name
        - query_run_id
        - metric
        - source_path
        - runtime_s
    """
    run_ids = list(run_ids)

    run_dirs = build_run_dirs(
        run_ids,
        collection=collection,
        schema=schema,
        instance=instance,
        parsed_results_root=parsed_results_root,
    )

    runs_by_query = gather_traces_by_query(
        run_dirs,
        metric=metric,
        xcol=xcol,
        ycol=ycol,
        run_ids=run_ids,
    )

    runs_by_query = canonicalise_dict_keys(runs_by_query, canon_fn=canon_fn)

    runtime_map = load_runtime_map(
        run_ids,
        collection=collection,
        schema=schema,
        instance=instance,
        parsed_results_root=parsed_results_root,
        runtime_col=runtime_col,
        query_col=query_col,
        canon_fn=canon_fn,
    )

    out: Dict[str, List[pd.DataFrame]] = {}

    for q, dfs in runs_by_query.items():
        attached: List[pd.DataFrame] = []

        for df in dfs:
            old_attrs = getattr(df, "attrs", {}).copy()

            run_id = str(old_attrs.get("run_id", ""))
            query_name = str(q)
            query_run_id = make_query_run_id(query_name, run_id, sep=query_run_sep)

            runtime_s = runtime_map.get((run_id, query_name), np.nan)

            try:
                runtime_s = float(runtime_s)
            except Exception:
                runtime_s = np.nan

            if require_runtime and (not np.isfinite(runtime_s) or runtime_s <= 0):
                print(f"missing/invalid runtime for ({run_id}, {query_name}); skipping trace")
                continue

            df = df.copy()
            df.attrs.update(old_attrs)

            df["run_id"] = run_id
            df["query_name"] = query_name
            df["query_run_id"] = query_run_id
            df["runtime_s"] = runtime_s

            df.attrs["run_id"] = run_id
            df.attrs["query_name"] = query_name
            df.attrs["query_run_id"] = query_run_id
            df.attrs["metric"] = metric
            df.attrs["runtime_s"] = runtime_s

            attached.append(df)

        if attached:
            out[q] = attached

    return out


def load_runs_by_query_scalar(
    run_ids: Iterable[str],
    *,
    collection: str,
    schema: str,
    instance: str,
    xcol: str,
    ycol: str,
    parsed_results_root: str | Path,
    canon_fn: Optional[Callable[[str], str]] = None,
    runtime_col: str = "runtime_s",
    query_col: str = "query_id",
    query_run_sep: str = "@",
) -> Dict[str, List[pd.DataFrame]]:
    """
    Build synthetic two-point [xcol, ycol] traces directly from a collection's
    runtimes.csv, for collections with no continuous per-query metric trace
    (e.g. the profiler was disabled during execution). Each synthetic trace is
    [(0, 0), (runtime_s, runtime_s)], so any consumer reading df[xcol].max()
    or df.attrs['runtime_s'] resolves to the same true total runtime.
    """
    run_ids = list(run_ids)

    runtime_map = load_runtime_map(
        run_ids,
        collection=collection,
        schema=schema,
        instance=instance,
        parsed_results_root=parsed_results_root,
        runtime_col=runtime_col,
        query_col=query_col,
        canon_fn=canon_fn,
    )

    out: Dict[str, List[pd.DataFrame]] = {}

    for (run_id, query_name), runtime_s in runtime_map.items():
        query_run_id = make_query_run_id(query_name, run_id, sep=query_run_sep)

        df = pd.DataFrame({xcol: [0.0, runtime_s], ycol: [0.0, runtime_s]})
        df["run_id"] = run_id
        df["query_name"] = query_name
        df["query_run_id"] = query_run_id
        df["runtime_s"] = runtime_s

        df.attrs["run_id"] = run_id
        df.attrs["query_name"] = query_name
        df.attrs["query_run_id"] = query_run_id
        df.attrs["metric"] = "runtime_only"
        df.attrs["runtime_s"] = runtime_s

        out.setdefault(query_name, []).append(df)

    return out


# -----------------------------------------------------------------------------
# Node profile loading
# -----------------------------------------------------------------------------

def load_profiles_by_query(
    run_ids: Iterable[str],
    *,
    collection: str,
    schema: str,
    instance: str,
    parsed_results_root: str | Path,
    filename: str = "node_profiles.csv",
    canon_fn: Optional[Callable[[str], str]] = None,
    profile_types: Optional[Iterable[str] | str] = None,
    runtime_col: str = "runtime_s",
    query_col: str = "query_id",
    query_run_sep: str = "@",
    require_runtime: bool = True,
) -> Dict[str, List[pd.DataFrame]]:
    """
    Load per-query node profile CSVs across multiple parsed runs.

    Expected layout:
        <parsed_root>/<collection>/<schema>/<instance>/<run_id>/queries/<query_name>/node_profiles.csv

    Returns
    -------
    dict
        profiles_by_query[query_name] = [profile_df_run_1, profile_df_run_2, ...]

    Each profile DataFrame has columns:
        - run_id
        - query_name
        - query_run_id
        - runtime_s
        - source_path

    and attrs:
        - run_id
        - query_name
        - query_run_id
        - source_path
        - runtime_s
    """
    profiles_by_query: Dict[str, List[pd.DataFrame]] = {}
    run_ids = list(run_ids)

    runtime_map = load_runtime_map(
        run_ids,
        collection=collection,
        schema=schema,
        instance=instance,
        parsed_results_root=parsed_results_root,
        runtime_col=runtime_col,
        query_col=query_col,
        canon_fn=canon_fn,
    )

    if isinstance(profile_types, str):
        wanted_profile_types = {profile_types.strip().lower()}
    elif profile_types is None:
        wanted_profile_types = None
    else:
        wanted_profile_types = {
            str(p).strip().lower()
            for p in profile_types
            if p is not None and str(p).strip()
        }

    for run_id in run_ids:
        run_id = str(run_id)

        run_dir = trace_dir(
            run_id=run_id,
            query_name=None,
            collection=collection,
            schema=schema,
            instance=instance,
            parsed_results_root=parsed_results_root,
        )

        if not run_dir.exists():
            print(f"missing run dir for profiles: {run_dir}")
            continue

        for qdir in sorted(run_dir.iterdir(), key=lambda p: _qid_key(p.name)):
            if not qdir.is_dir():
                continue

            query_name_raw = qdir.name

            if not _is_query_dir_name(query_name_raw):
                continue

            try:
                query_name = canon_fn(query_name_raw) if canon_fn is not None else query_name_raw
            except Exception:
                continue

            profile_path = qdir / filename

            if not profile_path.exists():
                continue

            try:
                df = pd.read_csv(profile_path, usecols=NODE_PROFILE_FEATURE_COLS)
            except Exception as e:
                print(f"failed to read profile file {profile_path}: {e}")
                continue

            if df.empty:
                continue

            df = df.copy()

            if "profile_type" in df.columns:
                df["profile_type"] = (
                    df["profile_type"]
                    .astype("string")
                    .str.strip()
                    .str.lower()
                )

                if wanted_profile_types is not None:
                    df = df[df["profile_type"].isin(wanted_profile_types)].copy()

            if df.empty:
                continue

            query_run_id = make_query_run_id(query_name, run_id, sep=query_run_sep)

            runtime_s = runtime_map.get((run_id, query_name), np.nan)

            try:
                runtime_s = float(runtime_s)
            except Exception:
                runtime_s = np.nan

            if require_runtime and (not np.isfinite(runtime_s) or runtime_s <= 0):
                print(f"missing/invalid runtime for ({run_id}, {query_name}); skipping profile")
                continue

            df["run_id"] = run_id
            df["query_name"] = query_name
            df["query_run_id"] = query_run_id
            df["runtime_s"] = runtime_s
            df["source_path"] = str(profile_path)

            df.attrs["run_id"] = run_id
            df.attrs["query_name"] = query_name
            df.attrs["query_run_id"] = query_run_id
            df.attrs["runtime_s"] = runtime_s
            df.attrs["source_path"] = str(profile_path)

            profiles_by_query.setdefault(query_name, []).append(df)

    return profiles_by_query


# -----------------------------------------------------------------------------
# Alignment helpers
# -----------------------------------------------------------------------------

def align_plans_and_runs(
    plans_by_query: Dict[str, dict],
    runs_by_query: Dict[str, List[pd.DataFrame]],
    *,
    min_runs: int = 2,
    min_points_per_run: int = 2,
    require_cols: Optional[tuple[str, str]] = None,
) -> Tuple[Dict[str, dict], Dict[str, List[pd.DataFrame]], List[str]]:
    """
    Keep only queries present in both dicts AND with at least min_runs valid runs.

    Preserves run-level metadata in both columns and df.attrs.
    """
    common = sorted(set(plans_by_query) & set(runs_by_query), key=_qid_key)

    plans_aligned: Dict[str, dict] = {}
    runs_aligned: Dict[str, List[pd.DataFrame]] = {}
    kept: List[str] = []

    for q in common:
        raw_runs = runs_by_query.get(q, [])
        valid_runs: List[pd.DataFrame] = []

        for df in raw_runs:
            if not isinstance(df, pd.DataFrame):
                continue

            old_attrs = getattr(df, "attrs", {}).copy()

            if require_cols is not None:
                xcol, ycol = require_cols

                if not {xcol, ycol}.issubset(df.columns):
                    continue

                keep_cols = [xcol, ycol]

                for meta_col in ["run_id", "query_name", "query_run_id", "runtime_s"]:
                    if meta_col in df.columns and meta_col not in keep_cols:
                        keep_cols.append(meta_col)

                dff = df[keep_cols].dropna(subset=[xcol, ycol]).copy()
            else:
                dff = df.dropna().copy()

            dff.attrs.update(old_attrs)

            if len(dff) < int(min_points_per_run):
                continue

            valid_runs.append(dff)

        if len(valid_runs) >= int(min_runs):
            plans_aligned[q] = plans_by_query[q]
            runs_aligned[q] = valid_runs
            kept.append(q)

    return plans_aligned, runs_aligned, kept


def align_plans_and_profiles(
    plans_by_query: Dict[str, dict],
    profiles_by_query: Dict[str, List[pd.DataFrame]],
    *,
    min_profiles_per_query: int = 1,
    require_runtime: bool = True,
) -> Tuple[Dict[str, dict], Dict[str, List[pd.DataFrame]], List[str]]:
    """
    Keep only queries present in both plans_by_query and profiles_by_query.

    A valid profile DataFrame must:
      - be a non-empty DataFrame
      - have query_run_id metadata
      - optionally have a valid runtime_s
    """
    common = sorted(set(plans_by_query) & set(profiles_by_query), key=_qid_key)

    plans_aligned: Dict[str, dict] = {}
    profiles_aligned: Dict[str, List[pd.DataFrame]] = {}
    kept: List[str] = []

    for q in common:
        valid_profiles: List[pd.DataFrame] = []

        for df in profiles_by_query.get(q, []):
            if not isinstance(df, pd.DataFrame) or df.empty:
                continue

            attrs = getattr(df, "attrs", {})

            query_run_id = attrs.get("query_run_id", None)
            if query_run_id is None:
                if "query_run_id" in df.columns and len(df["query_run_id"].dropna()) > 0:
                    query_run_id = str(df["query_run_id"].dropna().iloc[0])

            if query_run_id is None:
                continue

            if require_runtime:
                runtime_s = attrs.get("runtime_s", np.nan)

                if not np.isfinite(runtime_s):
                    if "runtime_s" in df.columns:
                        vals = pd.to_numeric(df["runtime_s"], errors="coerce").dropna()
                        runtime_s = float(vals.iloc[0]) if len(vals) else np.nan

                try:
                    runtime_s = float(runtime_s)
                except Exception:
                    runtime_s = np.nan

                if not np.isfinite(runtime_s) or runtime_s <= 0:
                    continue

            valid_profiles.append(df)

        if len(valid_profiles) >= int(min_profiles_per_query):
            plans_aligned[q] = plans_by_query[q]
            profiles_aligned[q] = valid_profiles
            kept.append(q)

    return plans_aligned, profiles_aligned, kept


# -----------------------------------------------------------------------------
# Public aligned loaders
# -----------------------------------------------------------------------------

def load_aligned_plans_and_runs(
    *,
    queries_dir: str | Path,
    run_ids: Iterable[str],
    collection: str,
    schema: str,
    instance: str,
    metric: str,
    xcol: str,
    ycol: str,
    parsed_results_root: str | Path,
    canon_fn: Optional[Callable[[str], str]] = None,
    min_runs: int = 1,
    min_points_per_run: int = 2,
    require_cols: Optional[Tuple[str, ...]] = None,
    include_profiles: bool = True,
    profile_filename: str = "node_profiles.csv",
    require_profiles: bool = False,
    runtime_col: str = "runtime_s",
    query_col: str = "query_id",
    query_run_sep: str = "@",
    require_runtime: bool = True,
    use_scalar_runtime: bool = False,
) -> tuple[Dict[str, Any], Dict[str, List[pd.DataFrame]], list[str]]:
    """
    Load plans and metric traces.

    Each trace DataFrame is one execution of one query and has:
        - run_id
        - query_name
        - query_run_id
        - runtime_s

    Pass use_scalar_runtime=True for collections with no continuous per-query
    metric trace (e.g. profiler was disabled) — builds synthetic two-point
    traces from runtimes.csv instead of reading <query>/<metric>.parquet.
    """
    run_ids = list(run_ids)

    if require_cols is None:
        require_cols = (xcol, ycol)

    plans_by_query = load_plans_by_query(
        queries_dir,
        canon_fn=canon_fn,
    )

    if use_scalar_runtime:
        runs_by_query = load_runs_by_query_scalar(
            run_ids,
            collection=collection,
            schema=schema,
            instance=instance,
            xcol=xcol,
            ycol=ycol,
            canon_fn=canon_fn,
            parsed_results_root=parsed_results_root,
            runtime_col=runtime_col,
            query_col=query_col,
            query_run_sep=query_run_sep,
        )
    else:
        runs_by_query = load_runs_by_query(
            run_ids,
            collection=collection,
            schema=schema,
            instance=instance,
            metric=metric,
            xcol=xcol,
            ycol=ycol,
            canon_fn=canon_fn,
            parsed_results_root=parsed_results_root,
            runtime_col=runtime_col,
            query_col=query_col,
            query_run_sep=query_run_sep,
            require_runtime=require_runtime,
        )

    plans_by_query, runs_by_query, common = align_plans_and_runs(
        plans_by_query,
        runs_by_query,
        min_runs=min_runs,
        min_points_per_run=min_points_per_run,
        require_cols=require_cols,
    )

    common = sorted(set(plans_by_query) & set(runs_by_query), key=_qid_key)

    return plans_by_query, runs_by_query, common


def load_aligned_plans_and_profiles(
    *,
    queries_dir: str | Path,
    run_ids: Iterable[str],
    collection: str,
    schema: str,
    instance: str,
    parsed_results_root: str | Path,
    canon_fn: Optional[Callable[[str], str]] = None,
    profile_filename: str = "node_profiles.csv",
    profile_types: Optional[Iterable[str] | str] = None,
    min_profiles_per_query: int = 1,
    runtime_col: str = "runtime_s",
    query_col: str = "query_id",
    query_run_sep: str = "@",
    require_runtime: bool = True,
) -> tuple[Dict[str, Any], Dict[str, List[pd.DataFrame]], list[str]]:
    """
    Load query plans and profile-only node profiling data.

    Each profile DataFrame corresponds to one execution of one query and has:
        - run_id
        - query_name
        - query_run_id
        - runtime_s
        - source_path
    """
    run_ids = list(run_ids)

    plans_by_query = load_plans_by_query(
        queries_dir,
        canon_fn=canon_fn,
    )

    profiles_by_query = load_profiles_by_query(
        run_ids,
        collection=collection,
        schema=schema,
        instance=instance,
        parsed_results_root=parsed_results_root,
        filename=profile_filename,
        canon_fn=canon_fn,
        profile_types=profile_types,
        runtime_col=runtime_col,
        query_col=query_col,
        query_run_sep=query_run_sep,
        require_runtime=require_runtime,
    )

    plans_by_query, profiles_by_query, common = align_plans_and_profiles(
        plans_by_query,
        profiles_by_query,
        min_profiles_per_query=min_profiles_per_query,
        require_runtime=require_runtime,
    )

    common = sorted(set(plans_by_query) & set(profiles_by_query), key=_qid_key)

    return plans_by_query, profiles_by_query, common

# -----------------------------------------------------------------------------
# Convenience metric/runtime loaders
# -----------------------------------------------------------------------------

def load_metric_runs(
    run_dirs: list[Path],
    metric: str,
    xcol: str = "t_rel_s",
) -> list[pd.DataFrame]:
    """
    Load the same metric from a list of query-specific run directories.

    Expected each directory contains:
        <metric>.parquet
    """
    runs: list[pd.DataFrame] = []

    for d in run_dirs:
        p = Path(d) / f"{metric}.parquet"

        if not p.exists():
            print(f"missing: {p}")
            continue

        df = pd.read_parquet(p)

        if not {xcol, "value"}.issubset(df.columns):
            raise ValueError(f"{p} missing columns {xcol}. Found: {list(df.columns)}")

        df = df[[xcol, "value"]].dropna().sort_values(xcol)

        if len(df) < 2:
            continue

        runs.append(df)

    return runs


def load_metric_run(parquet_path: str | Path, xlabel: str = "tau") -> pd.DataFrame:
    """
    Load a trace parquet, sorted by the selected x-axis.

    Expected columns:
        <xlabel>, value
    """
    parquet_path = Path(parquet_path)
    df = pd.read_parquet(parquet_path)

    if not {xlabel, "value"}.issubset(df.columns):
        raise ValueError(
            f"{parquet_path} missing required columns. Found: {list(df.columns)}"
        )

    df = df[[xlabel, "value"]].dropna().sort_values(xlabel)
    return df


def load_runtime_map(
    run_ids: Iterable[str],
    *,
    collection: str,
    schema: str,
    instance: str,
    parsed_results_root: str | Path,
    runtime_col: str = "runtime_s",
    query_col: str = "query_id",
    canon_fn: Optional[Callable[[str], str]] = None,
) -> Dict[Tuple[str, str], float]:
    """
    Load authoritative runtimes from parsed runtimes.csv files.

    Returns
    -------
    dict
        (run_id, query_name) -> runtime_s
    """
    runtime_map: Dict[Tuple[str, str], float] = {}

    for run_id in list(run_ids):
        run_queries_dir = trace_dir(
            run_id=run_id,
            query_name=None,
            collection=collection,
            schema=schema,
            instance=instance,
            parsed_results_root=parsed_results_root,
        )

        p = run_queries_dir / "runtimes.csv"

        if not p.exists():
            print(f"missing runtime csv: {p}")
            continue

        df = pd.read_csv(p)

        if query_col not in df.columns:
            raise ValueError(f"{p} missing column '{query_col}'")

        if runtime_col not in df.columns:
            raise ValueError(f"{p} missing column '{runtime_col}'")

        df = df[[query_col, runtime_col]].copy()
        df["query_name"] = (
            df[query_col]
            .astype(str)
            .str.extract(r"(q\d+)", expand=False)
        )
        df["runtime_s"] = pd.to_numeric(df[runtime_col], errors="coerce")
        df = df.dropna(subset=["query_name", "runtime_s"])

        for _, row in df.iterrows():
            q = str(row["query_name"])

            try:
                q = canon_fn(q) if canon_fn is not None else q
            except Exception:
                continue

            t = float(row["runtime_s"])

            if np.isfinite(t) and t > 0:
                runtime_map[(str(run_id), q)] = t

    return runtime_map


# ---------------------------------------------------------------------------
# SQL workloads, plan statistics and runtimes (formerly stats.py)
# ---------------------------------------------------------------------------

def extract_query_runtimes_s(
    workload_log_path: Union[str, Path],
    *,
    prefer: Tuple[str, ...] = ("runtime_s", "runtime_sec", "runtimeSeconds", "duration_s"),
    query_key_candidates: Tuple[str, ...] = ("query_name", "query", "qid", "name"),
    keep_last: bool = True,
) -> Dict[str, float]:
    """
    Extract per-query runtime (seconds) from workload_log.ndjson.

    Returns
    -------
    dict[str, float]
        Mapping { "q1": 12.34, "q2": 0.98, ... }.

    Notes
    -----
    - Uses `prefer` to find runtime field names.
    - Uses `query_key_candidates` to find the per-query identifier.
    - If the same query appears multiple times, keeps the last record by default
      (set keep_last=False to keep the first).
    """
    runtimes: Dict[str, float] = {}

    for rec in iter_workload_log_records(workload_log_path):
        # find query name
        qname: Optional[str] = None
        for k in query_key_candidates:
            if k in rec and rec[k] is not None:
                qname = str(rec[k]).strip()
                break
        if not qname:
            continue

        # normalize to prefix-only qX if the log has extra suffixes
        # examples handled: "q1", "q1_001", "q1 (something)", "q1_explain"
        # we keep only the leading "q<digits>"
        import re
        m = re.match(r"^(q\d+)\b", qname)
        if m:
            qname = m.group(1)

        # find runtime
        rt = None
        for k in prefer:
            if k in rec and rec[k] is not None:
                rt = rec[k]
                break
        if rt is None:
            continue

        # coerce to float
        try:
            rt_f = float(rt)
        except (TypeError, ValueError):
            continue

        if (qname not in runtimes) or keep_last:
            runtimes[qname] = rt_f

    return runtimes
        
def count_remote_edges(dag: Dict[str, Any]) -> int:
    """Count cross-fragment edges (etype == 'remote')."""
    n = 0
    for src, dst, etype in iter_edges(dag):
        if str(etype).lower() == "remote":
            n += 1
    return n


def count_remote_sources(dag: Dict[str, Any]) -> int:
    """Alternative proxy: count RemoteSource operators."""
    return sum(
        1 for nid, attrs in dag.get("nodes", {}).items()
        if str(attrs.get("name", "")).lower() == "remotesource".lower()
    )

def build_remote_vs_runtime_df(
    *,
    queries_dir: str | Path,
    workload_log_path: str | Path,
    remote_metric: str = "remote_edges",  # or "remote_sources"
):
    """
    Returns df with columns:
      - query
      - remote_exchanges
      - runtime_s
    """
    runtimes = extract_query_runtimes_s(workload_log_path)

    rows = []
    for qid, dag in iter_trino_dags_with_id(queries_dir):
        if qid not in runtimes:
            continue

        if remote_metric == "remote_sources":
            r = count_remote_sources(dag)
        else:
            r = count_remote_edges(dag)

        rows.append({
            "query": qid,
            "remote_exchanges": r,
            "runtime_s": runtimes[qid],
        })

    return pd.DataFrame(rows)

def count_plan_nodes(dag: Dict[str, Any]) -> int:
    """Return number of operators (nodes) in a Trino plan DAG."""
    return len(dag.get("nodes", {}))

def build_nodes_vs_runtime_df(
    *,
    queries_dir: str | Path,
    workload_log_path: str | Path,
):
    """
    Returns a DataFrame with columns:
      - query
      - n_nodes
      - runtime_s
    """
    # load runtimes
    runtimes = extract_query_runtimes_s(workload_log_path)

    rows = []
    for qid, dag in iter_trino_dags_with_id(queries_dir):
        if qid not in runtimes:
            continue

        rows.append({
            "query": qid,
            "n_nodes": count_plan_nodes(dag),
            "runtime_s": runtimes[qid],
        })

    return pd.DataFrame(rows)

def operator_name(dag: Dict[str, Any], node_id: str) -> str:
    """Return operator name for a node id (safe fallback if missing)."""
    n = dag["nodes"].get(node_id)
    if not isinstance(n, dict):
        return "<MISSING_NODE>"
    return str(n.get("name", "<UNKNOWN_OP>"))


def operator_pair_counts(
    dag: Dict[str, Any],
    *,
    by_type: bool = False,
    include_types: Optional[List[str]] = None,
) -> Counter:
    """
    Count operator pairs (src_op -> dst_op) across edges.

    Parameters
    ----------
    by_type : bool
        If True, keys include edge type:
            (src_op, dst_op, etype)
        If False:
            (src_op, dst_op)

    include_types : list[str] | None
        Restrict to edge types, e.g. ["child"], ["remote"], or ["child", "remote"].

    Returns
    -------
    Counter
        Mapping operator-pair keys to counts.
    """
    c = Counter()
    allow = set(t.lower() for t in include_types) if include_types else None

    for dst, src, etype in iter_edges(dag):
        et = etype.lower()
        if allow is not None and et not in allow:
            continue

        src_op = operator_name(dag, src)
        dst_op = operator_name(dag, dst)

        if by_type:
            c[(src_op, dst_op, et)] += 1
        else:
            c[(src_op, dst_op)] += 1

    return c

def operator_type_counts(dag: Dict[str, Any]) -> Counter:
    """
    Count operator types (by name) in a single Trino plan DAG.

    Returns
    -------
    Counter
        Mapping { operator_name -> count }
    """
    c = Counter()
    for _, attrs in dag.get("nodes", {}).items():
        name = attrs.get("name")
        if name is None:
            name = "<UNKNOWN_OP>"
        c[str(name)] += 1
    return c


def operator_type_counts_many(
    dags: Iterable[Dict[str, Any]]
) -> Counter:
    """
    Aggregate operator-type counts across many DAGs.

    Useful for workload-level operator distributions.
    """
    total = Counter()
    for dag in dags:
        total.update(operator_type_counts(dag))
    return total


def operator_pair_counts_many(
    dags: Iterable[Dict[str, Any]],
    *,
    by_type: bool = False,
    include_types: Optional[List[str]] = None,
) -> Counter:
    """
    Aggregate operator-pair counts across many DAGs.

    Useful when streaming thousands of query plans.
    """
    total = Counter()
    for dag in dags:
        total.update(
            operator_pair_counts(
                dag,
                by_type=by_type,
                include_types=include_types,
            )
        )
    return total


def pretty_print_pairs(counter: Counter, top_k: int = 20) -> None:
    """Pretty-print the most common operator pairs."""
    for (key, cnt) in counter.most_common(top_k):
        if len(key) == 3:
            src, dst, etype = key
            print(f"{cnt:>6}  [{etype}]  {src} -> {dst}")
        else:
            src, dst = key
            print(f"{cnt:>6}           {src} -> {dst}")

# =======================  Workload loading ==================================

_WORKLOAD_SQL_RE = re.compile(r"^q(\d+)\.sql$", re.IGNORECASE)


def _workload_sql_sort_key(path: Path) -> tuple[int, int | str]:
    """
    Sort q1.sql, q2.sql, ..., q10.sql numerically.

    Any non-standard names are sorted after q<number>.sql files.
    """
    m = _WORKLOAD_SQL_RE.match(path.name)

    if m:
        return (0, int(m.group(1)))

    return (1, path.name)


def normalise_sql_query_name(path: Path) -> str:
    """
    Convert q1.sql -> q1.

    This keeps query identifiers consistent with the rest of the framework.
    """
    m = _WORKLOAD_SQL_RE.match(path.name)

    if m:
        return f"q{int(m.group(1))}"

    return path.stem


def iter_sql_workload(
    workload_dir: Union[str, Path],
    *,
    pattern: str = "q*.sql",
    strip_sql: bool = True,
) -> Iterator[Dict[str, Any]]:
    """
    Iterate over a pre-execution SQL workload.

    Expected structure:
        workload_dir/
            q1.sql
            q2.sql
            ...

    Yields
    ------
    dict
        {
            "query_name": "q1",
            "sql": "...",
            "path": "...",
        }
    """
    workload_dir = Path(workload_dir)

    if not workload_dir.exists():
        raise FileNotFoundError(f"Workload directory not found: {workload_dir}")

    if not workload_dir.is_dir():
        raise ValueError(f"Expected workload directory, got file: {workload_dir}")

    sql_paths = [
        p for p in workload_dir.glob(pattern)
        if p.is_file()
    ]

    sql_paths = sorted(sql_paths, key=_workload_sql_sort_key)

    for sql_path in sql_paths:
        sql = sql_path.read_text(encoding="utf-8")

        if strip_sql:
            sql = sql.strip()

        if not sql:
            continue

        yield {
            "query_name": normalise_sql_query_name(sql_path),
            "sql": sql,
            "path": str(sql_path),
        }


def load_sql_workload(
    workload_dir: Union[str, Path],
    *,
    pattern: str = "q*.sql",
    strip_sql: bool = True,
) -> Dict[str, Any]:
    """
    Load a pre-execution SQL workload into memory.

    This is intentionally independent of generation_report.json and execution
    artefacts, so it can be used for generated workloads, TPC-DS workloads,
    hand-written workloads, or any other workload following qx.sql naming.

    Returns
    -------
    dict
        {
            "workload_name": "...",
            "workload_dir": "...",
            "query_count": 100,
            "queries": {
                "q1": {
                    "query_name": "q1",
                    "sql": "...",
                    "path": "...",
                },
                ...
            }
        }
    """
    workload_dir = Path(workload_dir)

    queries: Dict[str, Any] = {}

    for record in iter_sql_workload(
        workload_dir,
        pattern=pattern,
        strip_sql=strip_sql,
    ):
        queries[record["query_name"]] = record

    if not queries:
        raise RuntimeError(
            f"No SQL queries found in {workload_dir} using pattern={pattern}"
        )

    return {
        "workload_name": workload_dir.name,
        "workload_dir": str(workload_dir),
        "query_count": len(queries),
        "queries": queries,
    }
