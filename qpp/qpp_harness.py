
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Callable, Dict, Iterable, List, Optional

import numpy as np
import pandas as pd
import torch
import torch.nn.functional as F
from scipy.stats import spearmanr
from sklearn.metrics import mean_absolute_error, mean_squared_error, r2_score
from torch.utils.data import DataLoader

ROOT = Path(__file__).resolve().parent.parent  # repo root
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from utils.load import load_aligned_plans_and_runs, make_query_run_id, split_query_run_id
from diversql.src.operator_space import expected_operator_types
from lakehouse.config import RESULTS_ROOT
from qpp.models import (
    set_seed,
    canon_qid,
    split_query_ids,
    make_train_test_run_split,
    make_plan_embeddings_by_run,
    TrinoGraphGINPlanEncoder,
    evaluate_global_mean_runtime_baseline,
    RegressorConfig,
    RandomForestRuntimeRegressor,
    XGBoostRuntimeRegressor,
    LightGBMRuntimeRegressor,
    MLPRuntimeRegressor,
    GPRBFRuntimeRegressor,
)
from qpp.models.mscn import (
    get_train_test_datasets_from_trino as mscn_get_datasets,
    aggregate_query_runtime as mscn_aggregate_runtime,
    SetConv,
    unnormalize_labels as mscn_unnormalize,
    destandardize_labels as mscn_destandardize,
)


# ---------------------------------------------------------------------------
# Canonical metrics (one function, used for every model family)
# ---------------------------------------------------------------------------

def evaluate_runtime_metrics(preds: np.ndarray, targets: np.ndarray, eps: float = 1e-12) -> Dict[str, float]:
    preds = np.asarray(preds, dtype=float).reshape(-1)
    targets = np.asarray(targets, dtype=float).reshape(-1)
    if preds.shape[0] != targets.shape[0]:
        raise ValueError("preds and targets must have the same length")

    q_errors = np.maximum((preds + eps) / (targets + eps), (targets + eps) / (preds + eps))

    spearman = spearmanr(targets, preds).statistic
    if spearman is None or np.isnan(spearman):
        spearman = 0.0
    log_preds = np.log1p(np.clip(preds, 0, None))
    log_targets = np.log1p(np.clip(targets, 0, None))

    return {
        "mae": float(mean_absolute_error(targets, preds)),
        "rmse": float(np.sqrt(mean_squared_error(targets, preds))),
        "r2": float(r2_score(targets, preds)),
        "log_mae": float(mean_absolute_error(log_targets, log_preds)),
        "log_rmse": float(np.sqrt(mean_squared_error(log_targets, log_preds))),
        "log_r2": float(r2_score(log_targets, log_preds)),
        "spearman": float(spearman),
        "mean_q_error": float(np.mean(q_errors)),
        "median_q_error": float(np.median(q_errors)),
        "p90_q_error": float(np.percentile(q_errors, 90)),
        "p95_q_error": float(np.percentile(q_errors, 95)),
        "max_q_error": float(np.max(q_errors)),
        "gmean_q_error": float(np.exp(np.mean(np.log(q_errors + eps)))),
    }


METRIC_KEYS = [
    "mae", "rmse", "r2", "log_mae", "log_rmse", "log_r2", "spearman",
    "mean_q_error", "median_q_error", "p90_q_error", "p95_q_error",
    "max_q_error", "gmean_q_error",
]


def print_metrics_for_excel(metrics: Dict[str, float], keys: List[str] = METRIC_KEYS, decimals: int = 4) -> None:
    print("\t".join(keys))
    print("\t".join(f"{metrics[k]:.{decimals}f}" for k in keys))


# ---------------------------------------------------------------------------
# Shared data loading
# ---------------------------------------------------------------------------

@dataclass
class QPPDataBundle:
    plans_by_query: Dict[str, Any]
    runs_by_query: Dict[str, List[pd.DataFrame]]
    common: List[str]
    train_qids: List[str]
    test_qids: List[str]
    runs_train: Dict[str, List[pd.DataFrame]]
    runs_test: Dict[str, List[pd.DataFrame]]
    xcol: str
    ycol: str
    seed: int


def load_deterministic_qpp_data(
    *,
    queries_dir: str,
    run_ids,
    collection: str,
    schema: str,
    instance: str,
    metric: str,
    xcol: str,
    ycol: str,
    parsed_results_root: str,
    seed: int,
    test_frac: float,
    min_runs: int = 1,
    min_points_per_run: int = 2,
    fixed_test_qids: Optional[Iterable[str]] = None,
    use_scalar_runtime: bool = False,
) -> QPPDataBundle:
    plans_by_query, runs_by_query, common = load_aligned_plans_and_runs(
        queries_dir=queries_dir,
        run_ids=run_ids,
        collection=collection,
        schema=schema,
        instance=instance,
        metric=metric,
        xcol=xcol,
        ycol=ycol,
        parsed_results_root=parsed_results_root,
        canon_fn=canon_qid,
        min_runs=min_runs,
        min_points_per_run=min_points_per_run,
        require_cols=(xcol, ycol),
        use_scalar_runtime=use_scalar_runtime,
    )

    if fixed_test_qids is not None:
        fixed_test_set = {canon_qid(q) for q in fixed_test_qids}
        test_qids = sorted(q for q in common if q in fixed_test_set)
        train_qids = sorted(q for q in common if q not in fixed_test_set)
    else:
        train_qids, test_qids = split_query_ids(common, seed=seed, test_frac=test_frac)

    runs_train, runs_test = make_train_test_run_split(
        runs_by_query,
        train_qids=train_qids,
        test_qids=test_qids,
    )

    return QPPDataBundle(
        plans_by_query=plans_by_query,
        runs_by_query=runs_by_query,
        common=common,
        train_qids=train_qids,
        test_qids=test_qids,
        runs_train=runs_train,
        runs_test=runs_test,
        xcol=xcol,
        ycol=ycol,
        seed=seed,
    )


def _rekey_plans_and_runs(
    plans_by_query: Dict[str, Any],
    runs_by_query: Dict[str, List[pd.DataFrame]],
    qids: Iterable[str],
    prefix: str,
) -> tuple:
    new_plans: Dict[str, Any] = {}
    new_runs: Dict[str, List[pd.DataFrame]] = {}
    for q in qids:
        if q not in plans_by_query or q not in runs_by_query:
            continue
        new_q = f"{prefix}{q}"
        new_plans[new_q] = plans_by_query[q]
        new_dfs = []
        for df in runs_by_query[q]:
            df2 = df.copy()
            run_id = str(df2.attrs.get("run_id", ""))
            new_query_run_id = make_query_run_id(new_q, run_id)
            df2["query_name"] = new_q
            df2["query_run_id"] = new_query_run_id
            df2.attrs["query_name"] = new_q
            df2.attrs["query_run_id"] = new_query_run_id
            new_dfs.append(df2)
        new_runs[new_q] = new_dfs
    return new_plans, new_runs


def load_cross_collection_qpp_data(
    *,
    train_queries_dir: str,
    train_run_ids,
    train_collection: str,
    test_queries_dir: str,
    test_run_ids,
    test_collection: str,
    test_qids: Iterable[str],
    schema: str,
    instance: str,
    metric: str,
    xcol: str,
    ycol: str,
    parsed_results_root: str,
    seed: int,
    min_runs: int = 1,
    min_points_per_run: int = 2,
    use_scalar_runtime: bool = False,
    train_prefix: Optional[str] = None,
    test_prefix: Optional[str] = None,
    exclude_from_train: Optional[Iterable[str]] = None,
) -> QPPDataBundle:
    train_prefix = train_prefix or f"{train_collection}::"
    test_prefix = test_prefix or f"{test_collection}::"

    if exclude_from_train is None and train_collection == test_collection:
        exclude_from_train = test_qids

    train_plans_raw, train_runs_raw, train_common = load_aligned_plans_and_runs(
        queries_dir=train_queries_dir,
        run_ids=train_run_ids,
        collection=train_collection,
        schema=schema,
        instance=instance,
        metric=metric,
        xcol=xcol,
        ycol=ycol,
        parsed_results_root=parsed_results_root,
        canon_fn=canon_qid,
        min_runs=min_runs,
        min_points_per_run=min_points_per_run,
        require_cols=(xcol, ycol),
        use_scalar_runtime=use_scalar_runtime,
    )

    test_plans_raw, test_runs_raw, test_common = load_aligned_plans_and_runs(
        queries_dir=test_queries_dir,
        run_ids=test_run_ids,
        collection=test_collection,
        schema=schema,
        instance=instance,
        metric=metric,
        xcol=xcol,
        ycol=ycol,
        parsed_results_root=parsed_results_root,
        canon_fn=canon_qid,
        min_runs=min_runs,
        min_points_per_run=min_points_per_run,
        require_cols=(xcol, ycol),
        use_scalar_runtime=use_scalar_runtime,
    )

    fixed_test_set = {canon_qid(q) for q in test_qids}
    test_common_restricted = [q for q in test_common if q in fixed_test_set]

    if exclude_from_train:
        exclude_set = {canon_qid(q) for q in exclude_from_train}
        train_common = [q for q in train_common if q not in exclude_set]

    train_plans, train_runs = _rekey_plans_and_runs(train_plans_raw, train_runs_raw, train_common, train_prefix)
    test_plans, test_runs = _rekey_plans_and_runs(test_plans_raw, test_runs_raw, test_common_restricted, test_prefix)

    plans_by_query = {**train_plans, **test_plans}
    runs_by_query = {**train_runs, **test_runs}
    train_qids = sorted(train_plans.keys())
    test_qids_final = sorted(test_plans.keys())

    runs_train, runs_test = make_train_test_run_split(
        runs_by_query,
        train_qids=train_qids,
        test_qids=test_qids_final,
    )

    return QPPDataBundle(
        plans_by_query=plans_by_query,
        runs_by_query=runs_by_query,
        common=train_qids + test_qids_final,
        train_qids=train_qids,
        test_qids=test_qids_final,
        runs_train=runs_train,
        runs_test=runs_test,
        xcol=xcol,
        ycol=ycol,
        seed=seed,
    )


def load_pooled_cross_collection_qpp_data(
    *,
    train_sources: List[Dict[str, Any]],
    test_queries_dir: str,
    test_run_ids,
    test_collection: str,
    test_qids: Iterable[str],
    schema: str,
    instance: str,
    metric: str,
    xcol: str,
    ycol: str,
    parsed_results_root: str,
    seed: int,
    min_runs: int = 1,
    min_points_per_run: int = 2,
    use_scalar_runtime: bool = False,
    test_prefix: Optional[str] = None,
) -> QPPDataBundle:
    test_prefix = test_prefix or f"{test_collection}::"

    test_plans_raw, test_runs_raw, test_common = load_aligned_plans_and_runs(
        queries_dir=test_queries_dir,
        run_ids=test_run_ids,
        collection=test_collection,
        schema=schema,
        instance=instance,
        metric=metric,
        xcol=xcol,
        ycol=ycol,
        parsed_results_root=parsed_results_root,
        canon_fn=canon_qid,
        min_runs=min_runs,
        min_points_per_run=min_points_per_run,
        require_cols=(xcol, ycol),
        use_scalar_runtime=use_scalar_runtime,
    )
    fixed_test_set = {canon_qid(q) for q in test_qids}
    test_common_restricted = [q for q in test_common if q in fixed_test_set]
    test_plans, test_runs = _rekey_plans_and_runs(
        test_plans_raw, test_runs_raw, test_common_restricted, test_prefix,
    )

    plans_by_query: Dict[str, Any] = dict(test_plans)
    runs_by_query: Dict[str, List[pd.DataFrame]] = dict(test_runs)
    train_qids: List[str] = []

    for src in train_sources:
        collection = src["collection"]
        prefix = src.get("prefix") or f"{collection}::"
        exclude_qids = src.get("exclude_qids")
        if exclude_qids is None and collection == test_collection:
            exclude_qids = test_qids

        src_plans_raw, src_runs_raw, src_common = load_aligned_plans_and_runs(
            queries_dir=src["queries_dir"],
            run_ids=src["run_ids"],
            collection=collection,
            schema=schema,
            instance=instance,
            metric=metric,
            xcol=xcol,
            ycol=ycol,
            parsed_results_root=parsed_results_root,
            canon_fn=canon_qid,
            min_runs=min_runs,
            min_points_per_run=min_points_per_run,
            require_cols=(xcol, ycol),
            use_scalar_runtime=use_scalar_runtime,
        )

        if exclude_qids:
            exclude_set = {canon_qid(q) for q in exclude_qids}
            src_common = [q for q in src_common if q not in exclude_set]

        src_plans, src_runs = _rekey_plans_and_runs(src_plans_raw, src_runs_raw, src_common, prefix)

        overlap = set(src_plans) & set(plans_by_query)
        if overlap:
            raise ValueError(
                f"train source {collection!r} (prefix={prefix!r}) collides with "
                f"already-pooled ids, e.g. {sorted(overlap)[:5]} — use a distinct prefix."
            )

        plans_by_query.update(src_plans)
        runs_by_query.update(src_runs)
        train_qids.extend(src_plans.keys())

    train_qids = sorted(train_qids)
    test_qids_final = sorted(test_plans.keys())

    runs_train, runs_test = make_train_test_run_split(
        runs_by_query,
        train_qids=train_qids,
        test_qids=test_qids_final,
    )

    return QPPDataBundle(
        plans_by_query=plans_by_query,
        runs_by_query=runs_by_query,
        common=train_qids + test_qids_final,
        train_qids=train_qids,
        test_qids=test_qids_final,
        runs_train=runs_train,
        runs_test=runs_test,
        xcol=xcol,
        ycol=ycol,
        seed=seed,
    )


def subset_bundle(
    data: QPPDataBundle,
    *,
    train_qids: Iterable[str],
    test_qids: Optional[Iterable[str]] = None,
) -> QPPDataBundle:
    train_qids = sorted(set(train_qids))
    test_qids_final = sorted(set(test_qids)) if test_qids is not None else list(data.test_qids)

    runs_train, runs_test = make_train_test_run_split(
        data.runs_by_query,
        train_qids=train_qids,
        test_qids=test_qids_final,
    )

    return QPPDataBundle(
        plans_by_query=data.plans_by_query,
        runs_by_query=data.runs_by_query,
        common=train_qids + test_qids_final,
        train_qids=train_qids,
        test_qids=test_qids_final,
        runs_train=runs_train,
        runs_test=runs_test,
        xcol=data.xcol,
        ycol=data.ycol,
        seed=data.seed,
    )


def nested_query_subsamples(
    train_qids: Iterable[str],
    checkpoint_ns: Iterable[int],
    seed: int,
) -> Dict[int, List[str]]:
    train_qids = list(train_qids)
    rng = np.random.RandomState(seed)
    shuffled = rng.permutation(np.array(train_qids, dtype=object)).tolist()

    result: Dict[int, List[str]] = {}
    for n in sorted({int(x) for x in checkpoint_ns}):
        n_clipped = min(n, len(shuffled))
        if n_clipped in result:
            continue
        result[n_clipped] = shuffled[:n_clipped]
    return result


def training_subset_stats(
    plans_by_query: Dict[str, Any],
    runs_by_query: Dict[str, List[pd.DataFrame]],
    qids: Iterable[str],
    xcol: str,
) -> Dict[str, Any]:
    from utils.workload_analysis import structural_diversity_summary

    qids = list(qids)
    dags = {q: plans_by_query[q] for q in qids if q in plans_by_query}

    n_operators = [len(dag.get("nodes", {})) for dag in dags.values()]
    runtimes = []
    for q in qids:
        dfs = runs_by_query.get(q) or []
        run_vals = [_runtime_from_run_df(df, xcol=xcol) for df in dfs if df is not None and not df.empty]
        if run_vals:
            runtimes.append(float(np.mean(run_vals)))

    def _stats(values: List[float], prefix: str) -> Dict[str, float]:
        if not values:
            return {f"{prefix}_mean": float("nan"), f"{prefix}_median": float("nan"), f"{prefix}_p90": float("nan")}
        arr = np.asarray(values, dtype=float)
        return {
            f"{prefix}_mean": float(np.mean(arr)),
            f"{prefix}_median": float(np.median(arr)),
            f"{prefix}_p90": float(np.percentile(arr, 90)),
        }

    diversity = structural_diversity_summary(dags, compute_similarity=True)

    return {
        "n_queries": len(qids),
        "n_queries_with_plans": len(dags),
        "n_queries_with_runtime": len(runtimes),
        **_stats(n_operators, "n_operators"),
        **_stats(runtimes, "runtime"),
        "unique_plan_graph_count": diversity["unique_plan_graph_count"],
        "plan_graph_uniqueness_ratio": diversity["plan_graph_uniqueness_ratio"],
        "plan_graph_vendi_score": diversity["plan_graph_vendi_score"],
        "operator_type_entropy": diversity["operator_type_entropy"],
        "mean_nearest_neighbour_distance": diversity["mean_nearest_neighbour_distance"],
    }


def default_queries_dir_for(run_id: str, *, schema: str, instance: str) -> str:
    return f"{RESULTS_ROOT}/{schema}/{instance}/{run_id}/queries"


def build_mixed_bundle_lenient(
    leg_specs: Dict[str, Dict[str, Any]],
    *,
    schema: str,
    instance: str,
    metric: str,
    xcol: str,
    ycol: str,
    parsed_results_root: str,
    seed: int,
    test_frac: float,
    use_scalar_runtime: bool = True,
    queries_dir_for: Optional[Callable[[str], str]] = None,
) -> tuple:
    queries_dir_for = queries_dir_for or (lambda run_id: default_queries_dir_for(run_id, schema=schema, instance=instance))

    sources = []
    available, skipped = [], []

    for name, spec in leg_specs.items():
        run_ids = spec.get("run_ids") or []
        if not run_ids:
            print(f"[missing] {name} ({spec['collection']}): no execution run recorded yet "
                  f"-- skipping. Fill in run_ids in LEGS once it has a clean run.")
            skipped.append(name)
            continue

        queries_dir = queries_dir_for(run_ids[0])
        try:
            load_aligned_plans_and_runs(
                queries_dir=queries_dir,
                run_ids=run_ids,
                collection=spec["collection"],
                schema=schema,
                instance=instance,
                metric=metric,
                xcol=xcol,
                ycol=ycol,
                parsed_results_root=parsed_results_root,
                canon_fn=canon_qid,
                use_scalar_runtime=use_scalar_runtime,
            )
        except Exception as e:
            print(f"[missing] {name} ({spec['collection']}): failed to load "
                  f"({type(e).__name__}: {e}) -- skipping.")
            skipped.append(name)
            continue

        src = dict(collection=spec["collection"], queries_dir=queries_dir,
                   run_ids=run_ids, prefix=f"{name}::")
        if spec.get("fixed_test_qids") is not None:
            src["fixed_test_qids"] = spec["fixed_test_qids"]
        else:
            src["test_frac"] = test_frac
        sources.append(src)
        available.append(name)

    if not sources:
        raise RuntimeError("No legs have usable execution data yet -- nothing to train on.")

    bundle = load_multi_source_qpp_data(
        sources=sources,
        schema=schema,
        instance=instance,
        metric=metric,
        xcol=xcol,
        ycol=ycol,
        parsed_results_root=parsed_results_root,
        seed=seed,
        test_frac=test_frac,
        use_scalar_runtime=use_scalar_runtime,
    )
    return bundle, available, skipped


def load_multi_source_qpp_data(
    *,
    sources: List[Dict[str, Any]],
    schema: str,
    instance: str,
    metric: str,
    xcol: str,
    ycol: str,
    parsed_results_root: str,
    seed: int,
    min_runs: int = 1,
    min_points_per_run: int = 2,
    use_scalar_runtime: bool = False,
    test_frac: float = 0.2,
) -> QPPDataBundle:
    plans_by_query: Dict[str, Any] = {}
    runs_by_query: Dict[str, List[pd.DataFrame]] = {}
    all_train_qids: List[str] = []
    all_test_qids: List[str] = []

    for src in sources:
        collection = src["collection"]
        prefix = src.get("prefix") or f"{collection}::"
        src_fixed_test_qids = src.get("fixed_test_qids")
        src_test_frac = src.get("test_frac", test_frac)

        src_plans_raw, src_runs_raw, src_common = load_aligned_plans_and_runs(
            queries_dir=src["queries_dir"],
            run_ids=src["run_ids"],
            collection=collection,
            schema=schema,
            instance=instance,
            metric=metric,
            xcol=xcol,
            ycol=ycol,
            parsed_results_root=parsed_results_root,
            canon_fn=canon_qid,
            min_runs=min_runs,
            min_points_per_run=min_points_per_run,
            require_cols=(xcol, ycol),
            use_scalar_runtime=use_scalar_runtime,
        )

        if src_fixed_test_qids is not None:
            fixed_set = {canon_qid(q) for q in src_fixed_test_qids}
            src_train = sorted(q for q in src_common if q not in fixed_set)
            src_test = sorted(q for q in src_common if q in fixed_set)
        else:
            src_train, src_test = split_query_ids(src_common, seed=seed, test_frac=src_test_frac)

        src_train_plans, src_train_runs = _rekey_plans_and_runs(src_plans_raw, src_runs_raw, src_train, prefix)
        src_test_plans, src_test_runs = _rekey_plans_and_runs(src_plans_raw, src_runs_raw, src_test, prefix)

        overlap = (set(src_train_plans) | set(src_test_plans)) & set(plans_by_query)
        if overlap:
            raise ValueError(
                f"source {collection!r} (prefix={prefix!r}) collides with "
                f"already-loaded ids, e.g. {sorted(overlap)[:5]} — use a distinct prefix."
            )

        plans_by_query.update(src_train_plans)
        plans_by_query.update(src_test_plans)
        runs_by_query.update(src_train_runs)
        runs_by_query.update(src_test_runs)
        all_train_qids.extend(src_train_plans.keys())
        all_test_qids.extend(src_test_plans.keys())

    all_train_qids = sorted(all_train_qids)
    all_test_qids = sorted(all_test_qids)

    runs_train, runs_test = make_train_test_run_split(
        runs_by_query,
        train_qids=all_train_qids,
        test_qids=all_test_qids,
    )

    return QPPDataBundle(
        plans_by_query=plans_by_query,
        runs_by_query=runs_by_query,
        common=all_train_qids + all_test_qids,
        train_qids=all_train_qids,
        test_qids=all_test_qids,
        runs_train=runs_train,
        runs_test=runs_test,
        xcol=xcol,
        ycol=ycol,
        seed=seed,
    )


# ---------------------------------------------------------------------------
# 1. Mean baseline
# ---------------------------------------------------------------------------

def run_mean_baseline(data: QPPDataBundle) -> Dict[str, Any]:
    df_baseline, _legacy_metrics, info = evaluate_global_mean_runtime_baseline(
        data.runs_train,
        data.runs_test,
        xcol=data.xcol,
    )
    preds = df_baseline["runtime_mean_pred"].to_numpy()
    targets = df_baseline["runtime_s"].to_numpy()
    metrics = evaluate_runtime_metrics(preds, targets)
    train_targets = np.asarray(
        [
            _runtime_from_run_df(df, xcol=data.xcol)
            for df in data.runs_train.values()
            if df is not None and not df.empty
        ],
        dtype=float,
    )
    train_preds = np.full_like(train_targets, fill_value=float(np.mean(preds)) if len(preds) else np.nan)
    train_metrics = evaluate_runtime_metrics(train_preds, train_targets) if len(train_targets) else {}

    return {
        "metrics": metrics,
        "train_metrics": train_metrics,
        "predictions": {"preds": preds, "targets": targets},
        "kept_test_qids": df_baseline["q"].tolist(),
        "info": info,
    }


# ---------------------------------------------------------------------------
# 2. Standard regressors (RandomForest, XGBoost, LightGBM, MLP, GP-RBF)
#    over TrinoGraphGINPlanEncoder embeddings
# ---------------------------------------------------------------------------

# Hyperparameters as already tuned in test_deterministic_baselines_standard.ipynb.
STANDARD_BEST_PARAMS = {
    "xgboost": {"subsample": 0.8, "n_estimators": 256, "max_depth": 4, "learning_rate": 0.1, "colsample_bytree": 1.0},
    "random_forest": {"n_estimators": 500, "min_samples_leaf": 2, "max_depth": None},
    "mlp": {"max_iter": 500, "learning_rate_init": 0.01, "hidden_layer_sizes": (256, 128, 64), "alpha": 0.001},
    "lightgbm": {"num_leaves": 15, "n_estimators": 256, "min_child_samples": 20, "max_depth": 4, "learning_rate": 0.05},
}

STANDARD_MODEL_CLASSES = {
    "xgboost": XGBoostRuntimeRegressor,
    "random_forest": RandomForestRuntimeRegressor,
    "mlp": MLPRuntimeRegressor,
    "lightgbm": LightGBMRuntimeRegressor,
}

def gin_encoder_default_kwargs(seed: int = 0) -> Dict[str, Any]:
    return {
        "hidden": 128,
        "n_layers": 3,
        "emb_dim": 256,
        "dropout": 0.1,
        "mask_rate": 0.15,
        "epochs": 200,
        "batch_size": 32,
        "lr": 1e-3,
        "weight_decay": 1e-4,
        "fixed_vocab": expected_operator_types(read_only=True, iceberg=True),
        "seed": seed,
        "device": "cuda" if torch.cuda.is_available() else "cpu",
        "verbose": False,
    }


ENCODER_DEFAULT_KWARGS_BY_CLASS: Dict[Any, Callable[[int], Dict[str, Any]]] = {
    TrinoGraphGINPlanEncoder: gin_encoder_default_kwargs,
}


def _runtime_from_run_df(df: pd.DataFrame, xcol: str) -> float:
    return float(df[xcol].max())


def build_point_dataset(Z_by_run: Dict[str, np.ndarray], runs_by_run: Dict[str, pd.DataFrame], xcol: str):
    """query_run_id -> embedding, query_run_id -> run trace  =>  flat (X, y)."""
    X, y, run_ids = [], [], []
    for run_id, z in Z_by_run.items():
        if run_id not in runs_by_run:
            continue
        df = runs_by_run[run_id]
        if df is None or df.empty:
            continue
        X.append(np.asarray(z, dtype=float).reshape(-1))
        y.append(_runtime_from_run_df(df, xcol=xcol))
        run_ids.append(run_id)
    if not X:
        raise ValueError("No matching run-level embeddings and traces were found.")
    return np.vstack(X), np.asarray(y, dtype=float), run_ids


def run_standard_regressors(
    data: QPPDataBundle,
    *,
    seed: int,
    encoder_cls: Any = TrinoGraphGINPlanEncoder,
    encoder_kwargs: Optional[Dict[str, Any]] = None,
    include_gp: bool = True,
    model_names: Optional[Iterable[str]] = None,
) -> Dict[str, Dict[str, Any]]:
    model_names = list(model_names) if model_names is not None else list(STANDARD_MODEL_CLASSES)
    unknown = set(model_names) - set(STANDARD_MODEL_CLASSES)
    if unknown:
        raise ValueError(f"model_names contains unknown standard regressor(s): {sorted(unknown)}")

    if encoder_kwargs is None:
        default_fn = ENCODER_DEFAULT_KWARGS_BY_CLASS.get(encoder_cls)
        if default_fn is None:
            raise ValueError(
                f"No default encoder_kwargs registered for {encoder_cls!r}; pass encoder_kwargs explicitly."
            )
        encoder_kwargs = default_fn(seed)

    Z_train, Z_test, enc = make_plan_embeddings_by_run(
        encoder_cls=encoder_cls,
        plans_by_query=data.plans_by_query,
        runs_train=data.runs_train,
        runs_test=data.runs_test,
        train_qids=data.train_qids,
        test_qids=data.test_qids,
        encoder_kwargs=encoder_kwargs,
    )

    X_train, y_train, _ = build_point_dataset(Z_train, data.runs_train, xcol=data.xcol)
    X_test, y_test, test_run_ids = build_point_dataset(Z_test, data.runs_test, xcol=data.xcol)
    kept_test_qids = [split_query_run_id(r)[0] for r in test_run_ids]

    return fit_standard_regressors(
        X_train, y_train, X_test, y_test, kept_test_qids,
        seed=seed, include_gp=include_gp, model_names=model_names,
    )


def fit_standard_regressors(
    X_train: np.ndarray,
    y_train: np.ndarray,
    X_test: np.ndarray,
    y_test: np.ndarray,
    kept_test_qids: List[str],
    *,
    seed: int,
    include_gp: bool = True,
    model_names: Optional[Iterable[str]] = None,
) -> Dict[str, Dict[str, Any]]:
    model_names = list(model_names) if model_names is not None else list(STANDARD_MODEL_CLASSES)
    unknown = set(model_names) - set(STANDARD_MODEL_CLASSES)
    if unknown:
        raise ValueError(f"model_names contains unknown standard regressor(s): {sorted(unknown)}")

    config = RegressorConfig(log_target=True, log_base=2.0, random_state=seed)

    results: Dict[str, Dict[str, Any]] = {}
    for name in model_names:
        try:
            cls = STANDARD_MODEL_CLASSES[name]
            model = cls(config=config, **STANDARD_BEST_PARAMS[name])
            history = None

            if name == "xgboost":
                # Bypass BaseRuntimeRegressor.fit()'s plain call so `eval_set` can be
                # wired in -- xgboost's native per-boosting-round eval history (both
                # train and test, in the same log-transformed target space fit()
                # itself uses) is a genuine training curve this model gets almost
                # for free, unlike random_forest/gp_rbf which have no per-iteration
                # API to hook into.
                X_train_np = model._to_numpy(X_train)
                y_train_t = model._transform_target(y_train)
                X_test_np = model._to_numpy(X_test)
                y_test_t = model._transform_target(y_test)
                model.model = model._build_model()
                model.model.set_params(eval_metric=["rmse", "mae"])
                model.model.fit(
                    X_train_np, y_train_t,
                    eval_set=[(X_train_np, y_train_t), (X_test_np, y_test_t)],
                    verbose=False,
                )
                model.is_fitted = True
                history = _flatten_xgb_eval_history(model.model.evals_result())
            else:
                model.fit(X_train, y_train)

            preds = model.predict(X_test)
            preds_train = model.predict(X_train)
            result = {
                "metrics": evaluate_runtime_metrics(preds, y_test),
                "train_metrics": evaluate_runtime_metrics(preds_train, y_train),
                "predictions": {"preds": preds, "targets": y_test},
                "kept_test_qids": kept_test_qids,
                "model": model,
            }
            if history is not None:
                result["history"] = history
            results[name] = result
        except Exception as e:
            print(f"[skipping {name}] {type(e).__name__}: {e}")

    if include_gp:
        from sklearn.gaussian_process.kernels import RBF, WhiteKernel

        try:
            gp_best_params = {
                "gp__alpha": 1e-06,
                "gp__kernel": (
                    1.0 ** 2 * RBF(length_scale=10, length_scale_bounds=(1e-2, 1e4))
                    + WhiteKernel(noise_level=0.01, noise_level_bounds=(1e-8, 1e1))
                ),
                "gp__n_restarts_optimizer": 10,
                "gp__normalize_y": True,
                "gp__random_state": seed,
            }
            gp = GPRBFRuntimeRegressor(config=config, use_scaler=True)
            gp.model = gp._build_model()
            gp.model.set_params(**gp_best_params)
            gp.model.fit(gp._to_numpy(X_train), gp._transform_target(y_train))
            gp.best_params_ = dict(gp_best_params)
            gp.best_model_ = gp.model
            gp.is_fitted = True
            gp_preds = gp.predict(X_test)
            gp_preds_train = gp.predict(X_train)

            degenerate = np.std(gp_preds) < 1e-9 or np.std(gp_preds_train) < 1e-9
            if degenerate:
                print(
                    "[gp_rbf degenerate fit] predictions collapsed to a near-constant "
                    f"value (kernel={gp.model.named_steps['gp'].kernel_}) -- spearman "
                    "and any rank-based metric for this (leg, seed, checkpoint) are not "
                    "meaningful; treat like the mean baseline's tie artifact, not a real "
                    "result."
                )

            results["gp_rbf"] = {
                "metrics": evaluate_runtime_metrics(gp_preds, y_test),
                "train_metrics": evaluate_runtime_metrics(gp_preds_train, y_train),
                "predictions": {"preds": gp_preds, "targets": y_test},
                "kept_test_qids": kept_test_qids,
                "model": gp,
                "degenerate_fit": degenerate,
            }
        except Exception as e:
            print(f"[skipping gp_rbf] {type(e).__name__}: {e}")

    return results


def fit_leg_plan_embeddings(
    mixed: "QPPDataBundle",
    train_qids_full: Iterable[str],
    *,
    encoder_cls: Any = TrinoGraphGINPlanEncoder,
    encoder_kwargs: Optional[Dict[str, Any]] = None,
    seed: int,
    xcol: str,
) -> Dict[str, Any]:
    train_qids_full = list(train_qids_full)
    leg_data_full = subset_bundle(mixed, train_qids=train_qids_full)

    if encoder_kwargs is None:
        default_fn = ENCODER_DEFAULT_KWARGS_BY_CLASS.get(encoder_cls)
        if default_fn is None:
            raise ValueError(
                f"No default encoder_kwargs registered for {encoder_cls!r}; pass encoder_kwargs explicitly."
            )
        encoder_kwargs = default_fn(seed)

    Z_train_full, Z_test, enc = make_plan_embeddings_by_run(
        encoder_cls=encoder_cls,
        plans_by_query=mixed.plans_by_query,
        runs_train=leg_data_full.runs_train,
        runs_test=leg_data_full.runs_test,
        train_qids=leg_data_full.train_qids,
        test_qids=leg_data_full.test_qids,
        encoder_kwargs=encoder_kwargs,
    )
    X_test, y_test, test_run_ids = build_point_dataset(Z_test, leg_data_full.runs_test, xcol=xcol)
    kept_test_qids = [split_query_run_id(r)[0] for r in test_run_ids]
    return dict(
        leg_data_full=leg_data_full,
        Z_train_full=Z_train_full,
        X_test=X_test,
        y_test=y_test,
        kept_test_qids=kept_test_qids,
        encoder=enc,
    )


def _flatten_xgb_eval_history(raw_history: Dict[str, Dict[str, List[float]]]) -> List[Dict[str, Any]]:
    name_map = {"validation_0": "train", "validation_1": "test"}
    flat: Dict[int, Dict[str, Any]] = {}
    for val_key, metrics in raw_history.items():
        prefix = name_map.get(val_key, val_key)
        for metric_name, values in metrics.items():
            for i, v in enumerate(values):
                flat.setdefault(i, {"round": i})[f"{prefix}_{metric_name}"] = v
    return [flat[i] for i in sorted(flat)]


def filter_embeddings_by_qids(Z_by_run: Dict[str, np.ndarray], qids: Iterable[str]) -> Dict[str, np.ndarray]:
    qid_set = set(qids)
    return {rid: z for rid, z in Z_by_run.items() if split_query_run_id(rid)[0] in qid_set}


def incremental_rf_step(
    reg: RandomForestRuntimeRegressor,
    X_increment: Any,
    y_increment: Any,
    *,
    n_new_trees: int,
) -> RandomForestRuntimeRegressor:
    y_t = reg._transform_target(y_increment)
    X_np = reg._to_numpy(X_increment)
    if reg.model is None:
        reg.model = reg._build_model()
        reg.model.set_params(warm_start=True, n_estimators=n_new_trees)
    else:
        reg.model.set_params(n_estimators=reg.model.n_estimators + n_new_trees)
    reg.model.fit(X_np, y_t)
    reg.is_fitted = True
    return reg


def incremental_xgb_step(
    reg: XGBoostRuntimeRegressor,
    X_increment: Any,
    y_increment: Any,
    *,
    n_new_rounds: int,
    eval_set: Optional[List[tuple]] = None,
) -> tuple:
    y_t = reg._transform_target(y_increment)
    X_np = reg._to_numpy(X_increment)
    prev_booster = reg.model.get_booster() if (reg.model is not None and reg.is_fitted) else None
    reg.n_estimators = n_new_rounds
    new_model = reg._build_model()

    history = None
    fit_kwargs: Dict[str, Any] = {"xgb_model": prev_booster}
    if eval_set is not None:
        new_model.set_params(eval_metric=["rmse", "mae"])
        fit_kwargs["eval_set"] = [
            (reg._to_numpy(x), reg._transform_target(y)) for x, y in eval_set
        ]
        fit_kwargs["verbose"] = False

    new_model.fit(X_np, y_t, **fit_kwargs)
    reg.model = new_model
    reg.is_fitted = True

    if eval_set is not None:
        history = _flatten_xgb_eval_history(new_model.evals_result())
    return reg, history


def _flatten_lgbm_eval_history(raw_history: Dict[str, Dict[str, List[float]]]) -> List[Dict[str, Any]]:
    names = list(raw_history)
    metrics = list(raw_history[names[0]]) if names else []
    n_rounds = len(raw_history[names[0]][metrics[0]]) if names and metrics else 0

    rows = []
    for i in range(n_rounds):
        row: Dict[str, Any] = {"round": i}
        for name in names:
            for metric in metrics:
                row[f"{name}_{metric}"] = raw_history[name][metric][i]
        rows.append(row)
    return rows


def incremental_lgbm_step(
    reg: LightGBMRuntimeRegressor,
    X_increment: Any,
    y_increment: Any,
    *,
    n_new_rounds: int,
    eval_set: Optional[List[tuple]] = None,
) -> tuple:
    y_t = reg._transform_target(y_increment)
    X_np = reg._to_numpy(X_increment)
    prev_booster = reg.model if (reg.model is not None and reg.is_fitted) else None
    reg.n_estimators = n_new_rounds
    new_model = reg._build_model()

    history = None
    fit_kwargs: Dict[str, Any] = {}
    if prev_booster is not None:
        fit_kwargs["init_model"] = prev_booster
    if eval_set is not None:
        fit_kwargs["eval_set"] = [(reg._to_numpy(x), reg._transform_target(y)) for x, y in eval_set]
        fit_kwargs["eval_names"] = ["train", "test"][: len(eval_set)]
        fit_kwargs["eval_metric"] = ["rmse", "mae"]

    new_model.fit(X_np, y_t, **fit_kwargs)
    reg.model = new_model
    reg.is_fitted = True

    if eval_set is not None:
        history = _flatten_lgbm_eval_history(new_model.evals_result_)
    return reg, history


def incremental_mlp_step(
    reg: MLPRuntimeRegressor,
    X_increment: Any,
    y_increment: Any,
    *,
    n_epochs: int,
    eval_set: Optional[List[tuple]] = None,
) -> tuple:
    from sklearn.neural_network import MLPRegressor
    from sklearn.pipeline import Pipeline
    from sklearn.preprocessing import StandardScaler

    y_t = reg._transform_target(y_increment)
    X_np = reg._to_numpy(X_increment)

    if reg.model is None:
        scaler = StandardScaler().fit(X_np)
        mlp = MLPRegressor(
            hidden_layer_sizes=reg.hidden_layer_sizes,
            activation=reg.activation,
            solver=reg.solver,
            alpha=reg.alpha,
            batch_size=min(reg.batch_size, len(X_np)),
            learning_rate_init=reg.learning_rate_init,
            early_stopping=False,
            random_state=reg.config.random_state,
            warm_start=True,
        )
        reg.model = Pipeline([("scaler", scaler), ("mlp", mlp)])

    scaler = reg.model.named_steps["scaler"]
    mlp = reg.model.named_steps["mlp"]
    X_scaled = scaler.transform(X_np)

    history = [] if eval_set is not None else None
    eval_names = ["train", "test"][: len(eval_set)] if eval_set is not None else []
    for epoch in range(int(n_epochs)):
        mlp.partial_fit(X_scaled, y_t)
        reg.is_fitted = True
        if eval_set is not None:
            row: Dict[str, Any] = {"epoch": epoch}
            for name, (x, y) in zip(eval_names, eval_set):
                preds = reg.predict(x)
                row.update({f"{name}_{k}": v for k, v in evaluate_runtime_metrics(preds, y).items()})
            history.append(row)

    reg.is_fitted = True
    return reg, history


# ---------------------------------------------------------------------------
# 3. MSCN
# ---------------------------------------------------------------------------

def _mscn_run_epoch(model, loader, optimizer=None, device: str = "cpu") -> Dict[str, Any]:
    training = optimizer is not None
    model.train(training)

    total_loss, n_batches = 0.0, 0
    preds, targets = [], []

    for batch in loader:
        samples, predicates, joins, y, sample_masks, predicate_masks, join_masks = batch
        samples, predicates, joins = samples.to(device), predicates.to(device), joins.to(device)
        y = y.to(device)
        sample_masks, predicate_masks, join_masks = (
            sample_masks.to(device), predicate_masks.to(device), join_masks.to(device),
        )

        if training:
            optimizer.zero_grad()

        out = model(samples, predicates, joins, sample_masks, predicate_masks, join_masks)
        loss = F.mse_loss(out, y)

        if training:
            loss.backward()
            optimizer.step()

        total_loss += loss.item()
        n_batches += 1
        preds.append(out.detach().cpu().numpy())
        targets.append(y.detach().cpu().numpy())

    return {
        "loss": total_loss / max(n_batches, 1),
        "preds_norm": np.vstack(preds).reshape(-1),
        "targets_norm": np.vstack(targets).reshape(-1),
    }


def run_mscn(
    data: QPPDataBundle,
    *,
    seed: int,
    num_epochs: int = 30,
    batch_size: int = 64,
    hid_units: int = 128,
    device: Optional[str] = None,
    vocab_qids: Optional[Iterable[str]] = None,
    init_state_dict: Optional[Dict[str, Any]] = None,
    lr: float = 1e-3,
    label_transform: str = "log_zscore",
) -> Dict[str, Any]:
    set_seed(seed)
    device = device or ("cuda" if torch.cuda.is_available() else "cpu")

    (
        dicts, label_stats, labels_train_norm, labels_test_norm,
        max_num_samples, max_num_predicates, max_num_joins,
        train_dataset, test_dataset, kept_train_qids, kept_test_qids,
    ) = mscn_get_datasets(
        plans_by_query=data.plans_by_query,
        runs_by_query=data.runs_by_query,
        train_qids=data.train_qids,
        test_qids=data.test_qids,
        xcol=data.xcol,
        runtime_mode="mean",
        vocab_qids=vocab_qids,
        label_transform=label_transform,
    )

    train_loader = DataLoader(train_dataset, batch_size=batch_size, shuffle=True)
    test_loader = DataLoader(test_dataset, batch_size=batch_size, shuffle=False)

    batch = next(iter(train_loader))
    sample_feats, predicate_feats, join_feats = batch[0].shape[-1], batch[1].shape[-1], batch[2].shape[-1]

    model = SetConv(
        sample_feats=sample_feats, predicate_feats=predicate_feats,
        join_feats=join_feats, hid_units=hid_units,
        bounded_output=(label_transform == "log_minmax"),
    ).to(device)
    if init_state_dict is not None:
        model.load_state_dict(init_state_dict)
    optimizer = torch.optim.Adam(model.parameters(), lr=lr, weight_decay=1e-5)

    stat_a, stat_b = label_stats
    _inverse_transform = mscn_unnormalize if label_transform == "log_minmax" else mscn_destandardize

    def _unnorm_metrics(epoch_out: Dict[str, Any], raw_targets: Optional[np.ndarray] = None) -> Dict[str, float]:
        p = _inverse_transform(epoch_out["preds_norm"], stat_a, stat_b)
        t = raw_targets if raw_targets is not None else _inverse_transform(epoch_out["targets_norm"], stat_a, stat_b)
        return evaluate_runtime_metrics(p, t)
    raw_test_targets = np.array([
        mscn_aggregate_runtime(data.runs_by_query[q], xcol=data.xcol, mode="mean") for q in kept_test_qids
    ], dtype=float)

    best_state, best_val_loss = None, float("inf")
    history: List[Dict[str, Any]] = []
    for epoch in range(num_epochs):
        train_out = _mscn_run_epoch(model, train_loader, optimizer=optimizer, device=device)
        train_eval_out = _mscn_run_epoch(model, train_loader, optimizer=None, device=device)
        val_out = _mscn_run_epoch(model, test_loader, optimizer=None, device=device)

        if val_out["loss"] < best_val_loss:
            best_val_loss = val_out["loss"]
            best_state = {k: v.detach().cpu().clone() for k, v in model.state_dict().items()}

        history.append({
            "epoch": epoch,
            "train_loss_mse_norm": train_out["loss"],
            "val_loss_mse_norm": val_out["loss"],
            **{f"train_{k}": v for k, v in _unnorm_metrics(train_eval_out).items()},
            **{f"val_{k}": v for k, v in _unnorm_metrics(val_out, raw_test_targets).items()},
        })

    if best_state is not None:
        model.load_state_dict(best_state)

    test_eval = _mscn_run_epoch(model, test_loader, optimizer=None, device=device)
    train_eval_final = _mscn_run_epoch(model, train_loader, optimizer=None, device=device)
    preds = _inverse_transform(test_eval["preds_norm"], stat_a, stat_b)
    targets = raw_test_targets

    return {
        "metrics": evaluate_runtime_metrics(preds, targets),
        "train_metrics": _unnorm_metrics(train_eval_final),
        "history": history,
        "predictions": {"preds": preds, "targets": targets},
        "model": model,
        "kept_test_qids": kept_test_qids,
        "kept_train_qids": kept_train_qids,
    }


# ---------------------------------------------------------------------------
# Top-level driver
# ---------------------------------------------------------------------------

def run_all_deterministic_baselines(
    data: QPPDataBundle,
    *,
    seed: int = 42,
    num_epochs: int = 30,
    include_gp: bool = True,
    families: Optional[List[str]] = None,
) -> Dict[str, Dict[str, Any]]:
    """Train + evaluate every deterministic baseline against the same
    train/test split. Returns {model_name: {"metrics": {...}, ...}}."""
    all_families = ["mean", "standard", "mscn"]
    families = families or all_families

    results: Dict[str, Dict[str, Any]] = {}

    if "mean" in families:
        print("[mean] training...")
        results["mean"] = run_mean_baseline(data)

    if "standard" in families:
        print("[standard] training random_forest / xgboost / lightgbm / mlp / gp_rbf...")
        for name, res in run_standard_regressors(data, seed=seed, include_gp=include_gp).items():
            results[name] = res

    if "mscn" in families:
        print("[mscn] training...")
        results["mscn"] = run_mscn(data, seed=seed, num_epochs=num_epochs)

    return results


def results_to_dataframe(results: Dict[str, Dict[str, Any]]) -> pd.DataFrame:
    rows = []
    for name, res in results.items():
        row = {"model": name}
        row.update(res["metrics"])
        rows.append(row)
    return pd.DataFrame(rows).set_index("model").sort_values("mean_q_error")
