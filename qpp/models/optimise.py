from __future__ import annotations

import itertools
from typing import Any, Dict, Iterable, Optional
from scipy.stats import spearmanr
from sklearn.metrics import mean_absolute_error, mean_squared_error

import numpy as np
import pandas as pd

from .evaluate import evaluate_unseen_queries

def split_query_ids(
    qids: Iterable[str],
    *,
    seed: int,
    test_frac: float,
) -> tuple[list[str], list[str]]:
    """
    Randomly split query ids into train and test sets.

    This is still a query-level split: all runs for a held-out query go into
    the test set.
    """
    qids = list(qids)
    rng = np.random.default_rng(seed)
    rng.shuffle(qids)

    n_test = max(1, int(len(qids) * test_frac))
    test_qids = sorted(qids[:n_test])
    train_qids = sorted(qids[n_test:])
    return train_qids, test_qids

def _query_run_id_from_df(df: pd.DataFrame) -> str | None:
    """
    Extract query_run_id from a run DataFrame.
    """
    query_run_id = getattr(df, "attrs", {}).get("query_run_id")

    if query_run_id is None and "query_run_id" in df.columns:
        vals = df["query_run_id"].dropna()
        if len(vals) > 0:
            query_run_id = str(vals.iloc[0])

    return None if query_run_id is None else str(query_run_id)


def make_train_test_run_split(
    runs_by_query: Dict[str, Any],
    *,
    train_qids: Iterable[str],
    test_qids: Iterable[str],
    require_query_run_id: bool = True,
) -> tuple[Dict[str, pd.DataFrame], Dict[str, pd.DataFrame]]:
    """
    Split runs_by_query into train/test sets and return run-level dictionaries.

    Input
    -----
    runs_by_query:
        query_id -> list[pd.DataFrame]

    Output
    ------
    runs_train:
        query_run_id -> pd.DataFrame

    runs_test:
        query_run_id -> pd.DataFrame

    This means everything downstream can operate at run level.
    """

    def build_run_level(qids: Iterable[str]) -> Dict[str, pd.DataFrame]:
        out: Dict[str, pd.DataFrame] = {}

        for q in qids:
            if q not in runs_by_query:
                continue

            for i, df in enumerate(runs_by_query[q]):
                query_run_id = _query_run_id_from_df(df)

                if query_run_id is None:
                    if require_query_run_id:
                        raise ValueError(
                            f"Missing query_run_id for query={q!r}, run index={i}. "
                            "Check that the loader attaches df.attrs['query_run_id']."
                        )

                    run_id = getattr(df, "attrs", {}).get("run_id", f"run{i}")
                    query_run_id = f"{q}@{run_id}"

                out[str(query_run_id)] = df

        return out

    runs_train = build_run_level(train_qids)
    runs_test = build_run_level(test_qids)

    return runs_train, runs_test


from typing import Any, Dict, Iterable
import pandas as pd


def _query_run_id_from_profile_df(df: pd.DataFrame) -> str | None:
    """
    Extract query_run_id from a profile DataFrame.
    """
    qrid = getattr(df, "attrs", {}).get("query_run_id")

    if qrid is None and "query_run_id" in df.columns:
        vals = df["query_run_id"].dropna()
        if len(vals) > 0:
            qrid = str(vals.iloc[0])

    return None if qrid is None else str(qrid)


def make_train_test_profile_split(
    profiles_by_query: Dict[str, list[pd.DataFrame]],
    *,
    train_qids: Iterable[str],
    test_qids: Iterable[str],
    require_query_run_id: bool = True,
) -> tuple[Dict[str, pd.DataFrame], Dict[str, pd.DataFrame]]:
    """
    Split profiles_by_query into train/test sets and return run-level dictionaries.

    Input
    -----
    profiles_by_query:
        query_id -> list[pd.DataFrame]

    Output
    ------
    profiles_train:
        query_run_id -> profile DataFrame

    profiles_test:
        query_run_id -> profile DataFrame

    This matches the expected input for make_context_embeddings_by_run(...).
    """

    def build_run_level(qids: Iterable[str]) -> Dict[str, pd.DataFrame]:
        out: Dict[str, pd.DataFrame] = {}

        for q in qids:
            q = str(q)

            if q not in profiles_by_query:
                continue

            for i, df in enumerate(profiles_by_query[q]):
                if df is None or df.empty:
                    continue

                query_run_id = _query_run_id_from_profile_df(df)

                if query_run_id is None:
                    if require_query_run_id:
                        raise ValueError(
                            f"Missing query_run_id for query={q!r}, profile index={i}. "
                            "Check that the loader attaches df.attrs['query_run_id'] "
                            "or a query_run_id column."
                        )

                    run_id = getattr(df, "attrs", {}).get("run_id", f"run{i}")
                    query_run_id = f"{q}@{run_id}"

                out[str(query_run_id)] = df

        return out

    profiles_train = build_run_level(train_qids)
    profiles_test = build_run_level(test_qids)

    return profiles_train, profiles_test

def qerror_numpy(preds, labels, eps: float = 1e-12):
    preds = np.asarray(preds, dtype=float).reshape(-1)
    labels = np.asarray(labels, dtype=float).reshape(-1)

    preds = np.maximum(preds, eps)
    labels = np.maximum(labels, eps)

    return np.maximum(preds / labels, labels / preds)


def evaluate_runtime_point_metrics(preds, labels):
    preds = np.asarray(preds, dtype=float).reshape(-1)
    labels = np.asarray(labels, dtype=float).reshape(-1)

    mask = (
        np.isfinite(preds)
        & np.isfinite(labels)
        & (preds > 0)
        & (labels > 0)
    )

    preds = preds[mask]
    labels = labels[mask]

    if len(preds) == 0:
        return {
            "MAE": np.nan,
            "RMSE": np.nan,
            "Spearman Rank": np.nan,
            "Mean Qerror": np.nan,
            "P50 Qerror": np.nan,
            "P90 Qerror": np.nan,
            "P95 Qerror": np.nan,
        }

    qerr = qerror_numpy(preds, labels)

    spearman = spearmanr(labels, preds).statistic
    if spearman is None or not np.isfinite(spearman):
        spearman = 0.0

    return {
        "MAE": float(mean_absolute_error(labels, preds)),
        "RMSE": float(np.sqrt(mean_squared_error(labels, preds))),
        "Spearman Rank": float(spearman),
        "Mean Qerror": float(np.mean(qerr)),
        "P50 Qerror": float(np.percentile(qerr, 50)),
        "P90 Qerror": float(np.percentile(qerr, 90)),
        "P95 Qerror": float(np.percentile(qerr, 95)),
    }

def grid_search_unseen_queries(
    *,
    grid: Dict[str, list],
    model_cls,
    basis,
    trace_head_cls,
    trace_head_kwargs: Dict[str, Any],
    runtime_head_cls,
    runtime_head_fixed_kwargs: Dict[str, Any],
    Z_train: Dict[str, np.ndarray],
    runs_train: Dict[str, pd.DataFrame],
    Z_test: Dict[str, np.ndarray],
    runs_test: Dict[str, pd.DataFrame],
    xcol: str,
    ycol: str,
    n_grid: int = 400,
    drop_ood: bool = True,
    ood_ratio_thresh: float = 1e4,
    ood_abs_pred_thresh: float = 1e5,
) -> pd.DataFrame:
    """
    Run a Cartesian grid search over runtime-head hyperparameters.

    This function assumes run-level inputs:

        Z_train[query_run_id] -> embedding
        runs_train[query_run_id] -> run DataFrame

    Both trace and runtime heads are trained at query-run level.
    """
    keys = list(grid.keys())
    rows = []

    for values in itertools.product(*(grid[k] for k in keys)):
        hp = dict(zip(keys, values))

        model, df_test, split = evaluate_unseen_queries(
            model_cls=model_cls,
            basis=basis,
            trace_head_cls=trace_head_cls,
            trace_head_kwargs=trace_head_kwargs,
            runtime_head_cls=runtime_head_cls,
            runtime_head_kwargs={
                **runtime_head_fixed_kwargs,
                **hp,
            },
            Z_train=Z_train,
            runs_train=runs_train,
            Z_test=Z_test,
            runs_test=runs_test,
            xcol=xcol,
            ycol=ycol,
            n_grid=n_grid,
            drop_ood=drop_ood,
            ood_ratio_thresh=ood_ratio_thresh,
            ood_abs_pred_thresh=ood_abs_pred_thresh,
        )

        runtime_metrics = evaluate_runtime_point_metrics(
            preds=df_test["runtime_mean_pred"].to_numpy(dtype=float)
            if len(df_test) else np.asarray([]),
            labels=df_test["runtime_s"].to_numpy(dtype=float)
            if len(df_test) else np.asarray([]),
        )
        
        row = {
            **hp,
        
            # Excel-style point prediction metrics
            **runtime_metrics,
        
            # Existing probabilistic/runtime metrics
            "runtime_nll_mean": float(df_test["runtime_nll"].mean()) if len(df_test) else np.nan,
            "runtime_mae_mean": float(df_test["runtime_mae_mean"].mean()) if len(df_test) else np.nan,
            "runtime_cov_90_mean": float(df_test["runtime_cov_90"].mean()) if len(df_test) else np.nan,
            "runtime_pinball_90_mean": float(df_test["runtime_pinball_90"].mean()) if len(df_test) else np.nan,
        
            # Trace metrics
            "trace_mae_tau_mean": float(df_test["trace_mae_tau"].mean()) if len(df_test) else np.nan,
            "trace_rmse_tau_mean": float(df_test["trace_rmse_tau"].mean()) if len(df_test) else np.nan,
        
            "n_eval": int(len(df_test)),
        }

        print(row)
        rows.append(row)

    return pd.DataFrame(rows)

EXCEL_KEYS = [
    "MAE",
    "RMSE",
    "Spearman Rank",
    "Mean Qerror",
    "P50 Qerror",
    "P90 Qerror",
    "P95 Qerror",
]


def print_results_metrics_for_excel(results_df, keys=EXCEL_KEYS, decimals=4):
    print("\t".join(keys))

    for _, row in results_df.iterrows():
        print("\t".join(
            f"{float(row[k]):.{decimals}f}" if np.isfinite(row[k]) else "nan"
            for k in keys
        ))

def select_best_hparams(
    results_df: pd.DataFrame,
    *,
    metric: str = "runtime_nll_mean",
    ascending: bool = True,
) -> Dict[str, Any]:
    """
    Select the best row from a hyperparameter search DataFrame.
    """
    if results_df.empty:
        raise ValueError("results_df is empty")

    if metric not in results_df.columns:
        raise KeyError(
            f"Metric {metric!r} not found in results_df. "
            f"Available columns: {list(results_df.columns)}"
        )

    best_row = results_df.sort_values(metric, ascending=ascending).iloc[0]
    return best_row.to_dict()