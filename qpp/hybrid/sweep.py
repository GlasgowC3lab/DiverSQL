import json
import re
import sys
from pathlib import Path
from typing import Any, Dict, FrozenSet, List, Optional, Tuple

ROOT = Path(__file__).resolve().parents[2]  # repo root
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

import numpy as np  # noqa: E402
import pandas as pd  # noqa: E402

from qpp.models import TrinoGraphGINPlanEncoder  # noqa: E402
from qpp.qpp_harness import (  # noqa: E402
    QPPDataBundle,
    subset_bundle,
    training_subset_stats,
    fit_leg_plan_embeddings,
    filter_embeddings_by_qids,
    build_point_dataset,
    fit_standard_regressors,
    run_mean_baseline,
    run_mscn,
    gin_encoder_default_kwargs,
    evaluate_runtime_metrics,
    METRIC_KEYS,
)

from qpp.hybrid import pools as v7_pools  # noqa: E402
from qpp.hybrid import legs as v7_legs  # noqa: E402

# Unchanged from v4 -- the paper's headline six (02_paper_qpp_table_and_plot.ipynb's GROWTH_MODELS).
STANDARD_MODELS = ["random_forest", "xgboost", "lightgbm", "mlp", "gp_rbf"]
DEEP_MODELS = ["mscn"]
ALL_MODELS = STANDARD_MODELS + DEEP_MODELS

_DEEP_RUNNERS = {"mscn": run_mscn}

DEFAULT_CHECKPOINTS = [5, 10, 20, 50, 100, 200, 400, 700, 10**9]
DEFAULT_N_SEEDS = 5
DEFAULT_NUM_EPOCHS = 30

ARMS = [
    "D0_real_only",
    "D1_hybrid_diversql",
    "D1s_hybrid_diversql_size_matched",
    "D2_hybrid_sqlbarber",
    "D3_hybrid_bootstrapping_lcm",
    "D4_hybrid_sql_factory",
    "D5_hybrid_e2etune",
    "D6_hybrid_sqlstorm",
    "D8_generated_only",
]

_ARM_TO_LEG = {
    "D1_hybrid_diversql": v7_legs.OURS,
    "D1s_hybrid_diversql_size_matched": v7_legs.OURS,
    "D2_hybrid_sqlbarber": "sqlbarber",
    "D3_hybrid_bootstrapping_lcm": "bootstrapping_lcm",
    "D4_hybrid_sql_factory": "sql_factory",
    "D5_hybrid_e2etune": "e2etune",
    "D6_hybrid_sqlstorm": "sqlstorm",
    "D8_generated_only": v7_legs.OURS,
}


def _train_legs_for_arm(arm: str) -> FrozenSet[str]:
    if arm == "D0_real_only":
        return frozenset({v7_legs.REAL_LEG})
    if arm == "D8_generated_only":
        return frozenset({_ARM_TO_LEG[arm]})
    return frozenset({v7_legs.REAL_LEG, _ARM_TO_LEG[arm]})


_ARM_TRAIN_LEGS: Dict[str, FrozenSet[str]] = {arm: _train_legs_for_arm(arm) for arm in ARMS}

# Sentinel `test_leg` value for the one row per (arm, n, seed, model) that pools
# ALL of T_eval with no exclusion -- exactly v4's old metric, kept alongside the
# per-leg breakdown so the two protocols can be compared directly without a
# second rerun. `in_train_composition` is left `None` (neither true nor false --
# it mixes legs on both sides of that line) for this row so a `== False` filter
# (the correct way to select off-diagonal rows) never accidentally includes it.
ALL_BLENDED_SENTINEL = "__all_blended__"


def _pool_for_arm(
    arm: str, n: int, observed_subsamples: Dict[int, List[str]],
    generated_qids_by_leg: Dict[str, List[str]], *, size_match_seed: int,
) -> List[str]:
    if arm == "D0_real_only":
        return observed_subsamples[n]
    if arm == "D8_generated_only":
        return v7_pools.cold_start_pool(generated_qids_by_leg[_ARM_TO_LEG[arm]])
    leg_qids = generated_qids_by_leg[_ARM_TO_LEG[arm]]
    if arm == "D1s_hybrid_diversql_size_matched":
        return v7_pools.size_matched_pool(observed_subsamples[n], leg_qids, seed=size_match_seed)
    return v7_pools.hybrid_pool(observed_subsamples[n], leg_qids)


def _eventual_pool_for_arm(
    arm: str, observed_train_full: List[str], generated_qids_by_leg: Dict[str, List[str]],
) -> List[str]:
    if arm == "D0_real_only":
        return observed_train_full
    if arm == "D8_generated_only":
        return v7_pools.cold_start_pool(generated_qids_by_leg[_ARM_TO_LEG[arm]])
    leg_qids = generated_qids_by_leg[_ARM_TO_LEG[arm]]
    return v7_pools.hybrid_pool(observed_train_full, leg_qids)


def run_checkpoint_models(
    pool_qids: List[str], emb: Optional[Dict[str, Any]], bundle: QPPDataBundle, *,
    seed: int, models: List[str], num_epochs: int = DEFAULT_NUM_EPOCHS,
    deep_model_kwargs: Optional[Dict[str, Dict[str, Any]]] = None,
) -> Dict[str, Dict[str, Any]]:
    results: Dict[str, Dict[str, Any]] = {}
    pool_bundle = subset_bundle(bundle, train_qids=pool_qids)

    if "mean" in models:
        try:
            results["mean"] = run_mean_baseline(pool_bundle)
        except Exception as e:
            print(f"    [skip mean] {type(e).__name__}: {e}")

    standard_wanted = [m for m in STANDARD_MODELS if m in models]
    if standard_wanted:
        want_gp = "gp_rbf" in standard_wanted
        fittable = [m for m in standard_wanted if m != "gp_rbf"]
        try:
            Z_ckpt = filter_embeddings_by_qids(emb["Z_train_full"], pool_qids)
            X_train, y_train, _ = build_point_dataset(
                Z_ckpt, emb["leg_data_full"].runs_train, xcol=emb["xcol"],
            )
            standard_results = fit_standard_regressors(
                X_train, y_train, emb["X_test"], emb["y_test"], emb["kept_test_qids"],
                seed=seed, include_gp=want_gp, model_names=fittable,
            )
            results.update(standard_results)
        except Exception as e:
            print(f"    [skip standard regressors {standard_wanted}] {type(e).__name__}: {e}")

    for name in [m for m in DEEP_MODELS if m in models]:
        try:
            results[name] = _DEEP_RUNNERS[name](
                pool_bundle, seed=seed, num_epochs=num_epochs, **(deep_model_kwargs or {}).get(name, {}),
            )
        except Exception as e:
            print(f"    [skip {name}] {type(e).__name__}: {e}")

    return results


def _score_rows(
    *, arm: str, n: int, reveal_seed: int, pool_qids: List[str], results: Dict[str, Dict[str, Any]],
    n_queries_with_plans: Optional[int], plan_graph_vendi_score_: Optional[float],
) -> List[dict]:
    train_legs = _ARM_TRAIN_LEGS[arm]
    new_rows: List[dict] = []

    for model_name, res in results.items():
        preds = res.get("predictions")
        kept_qids = res.get("kept_test_qids")
        if preds is None or kept_qids is None:
            # This model's fit failed upstream (run_checkpoint_models already printed
            # why) -- no predictions to score, so no row for it, rather than a row of
            # all-NaN metrics.
            continue

        preds_arr = np.asarray(preds["preds"])
        targets_arr = np.asarray(preds["targets"])
        degenerate = res.get("degenerate_fit")

        common = {
            "arm": arm, "n_observed": n, "reveal_seed": reveal_seed, "model": model_name,
            "n_pool": len(pool_qids),
            "n_queries_with_plans": n_queries_with_plans,
            "plan_graph_vendi_score": plan_graph_vendi_score_,
            "degenerate_fit": degenerate,
        }

        m_all = evaluate_runtime_metrics(preds_arr, targets_arr)
        new_rows.append({
            **common, "test_leg": ALL_BLENDED_SENTINEL, "in_train_composition": None,
            "n_test": len(kept_qids), **{k: m_all.get(k) for k in METRIC_KEYS},
        })

        # Per-test-leg breakdown -- the new, finest-grained data.
        by_leg: Dict[str, List[int]] = {}
        for i, q in enumerate(kept_qids):
            by_leg.setdefault(v7_legs.leg_of_qid(q), []).append(i)

        for test_leg, idx in by_leg.items():
            m = evaluate_runtime_metrics(preds_arr[idx], targets_arr[idx])
            new_rows.append({
                **common, "test_leg": test_leg, "in_train_composition": test_leg in train_legs,
                "n_test": len(idx), **{k: m.get(k) for k in METRIC_KEYS},
            })

    return new_rows


def run_sweep(
    *,
    bundle: QPPDataBundle,
    observed_leg_full_qids: List[str],
    generated_qids_by_leg: Dict[str, List[str]],
    checkpoints: List[int] = DEFAULT_CHECKPOINTS,
    n_seeds: int = DEFAULT_N_SEEDS,
    models: List[str] = ALL_MODELS,
    arms: List[str] = ARMS,
    seed_base: int = 0,
    num_epochs: int = DEFAULT_NUM_EPOCHS,
    compute_stats: bool = True,
    checkpoint_csv_path: Optional[Path] = None,
    deep_model_kwargs: Optional[Dict[str, Dict[str, Any]]] = None,
) -> pd.DataFrame:
    rows: List[dict] = []
    xcol = bundle.xcol
    if checkpoint_csv_path is not None:
        checkpoint_csv_path = Path(checkpoint_csv_path)

    for arm in arms:
        for seed_idx in range(n_seeds):
            reveal_seed = seed_base + seed_idx
            model_seed = seed_base + seed_idx
            encoder_seed = seed_base + seed_idx

            observed_subsamples = v7_pools.observed_train_subsamples(
                observed_leg_full_qids, checkpoints, reveal_seed=reveal_seed,
            )
            arm_checkpoints = [0] if arm == "D8_generated_only" else sorted(observed_subsamples.keys())

            needs_embedding = any(m in models for m in STANDARD_MODELS)
            emb: Optional[Dict[str, Any]] = None
            if needs_embedding:
                eventual_qids = _eventual_pool_for_arm(arm, observed_leg_full_qids, generated_qids_by_leg)
                print(f"=== fitting plan encoder: arm={arm} seed={reveal_seed} eventual_pool={len(eventual_qids)} ===")
                emb = fit_leg_plan_embeddings(
                    bundle, eventual_qids,
                    encoder_cls=TrinoGraphGINPlanEncoder,
                    encoder_kwargs=gin_encoder_default_kwargs(encoder_seed),
                    seed=encoder_seed, xcol=xcol,
                )
                emb["xcol"] = xcol

            for n in arm_checkpoints:
                if arm == "D8_generated_only":
                    pool_qids = v7_pools.cold_start_pool(generated_qids_by_leg[_ARM_TO_LEG[arm]])
                else:
                    pool_qids = _pool_for_arm(
                        arm, n, observed_subsamples, generated_qids_by_leg,
                        size_match_seed=reveal_seed,
                    )

                print(f"--- arm={arm} n={n} reveal_seed={reveal_seed} pool_size={len(pool_qids)} ---")
                n_queries_with_plans: Optional[int] = None
                plan_graph_vendi_score_: Optional[float] = None
                if compute_stats:
                    stats = training_subset_stats(bundle.plans_by_query, bundle.runs_by_query, pool_qids, xcol=xcol)
                    n_queries_with_plans = stats.get("n_queries_with_plans")
                    plan_graph_vendi_score_ = stats.get("plan_graph_vendi_score")
                results = run_checkpoint_models(
                    pool_qids, emb, bundle, seed=model_seed, models=models, num_epochs=num_epochs,
                    deep_model_kwargs=deep_model_kwargs,
                )

                new_rows = _score_rows(
                    arm=arm, n=n, reveal_seed=reveal_seed, pool_qids=pool_qids, results=results,
                    n_queries_with_plans=n_queries_with_plans, plan_graph_vendi_score_=plan_graph_vendi_score_,
                )
                rows.extend(new_rows)

                if checkpoint_csv_path is not None and new_rows:
                    pd.DataFrame(new_rows).to_csv(
                        checkpoint_csv_path, mode="a",
                        header=not checkpoint_csv_path.exists(),
                        index=False,
                    )
                    print(f"    [checkpointed] appended {len(new_rows)} row(s) to {checkpoint_csv_path.name}")

    return pd.DataFrame(rows)


def off_diagonal_metric(df: pd.DataFrame, metric: str = "log_mae") -> pd.DataFrame:
    off_diag = df[(df["test_leg"] != ALL_BLENDED_SENTINEL) & (df["in_train_composition"] == False)] 
    return (
        off_diag.groupby(["arm", "n_observed", "reveal_seed", "model"], as_index=False)[metric]
        .mean()
    )


def blended_all_metric(df: pd.DataFrame, metric: str = "log_mae") -> pd.DataFrame:
    blended = df[df["test_leg"] == ALL_BLENDED_SENTINEL]
    return blended[["arm", "n_observed", "reveal_seed", "model", metric]].reset_index(drop=True)


def common_leg_metric(
    df: pd.DataFrame, arms: List[str], metric: str = "log_mae",
) -> pd.DataFrame:
    excluded = frozenset().union(*(_ARM_TRAIN_LEGS[a] for a in arms))
    keep = (
        df["arm"].isin(arms)
        & (df["test_leg"] != ALL_BLENDED_SENTINEL)
        & ~df["test_leg"].isin(excluded)
    )
    return (
        df[keep].groupby(["arm", "n_observed", "reveal_seed", "model"], as_index=False)[metric].mean()
    )


_MAIN_CONFIG_RE = re.compile(r"^hybrid_config_(\d{8}T\d{6}Z)\.json$")
_RESULT_KEY = ["arm", "n_observed", "reveal_seed", "model", "test_leg"]


def load_results(results_dir: Path, *, drop_degenerate: bool = True) -> Tuple[pd.DataFrame, Dict[str, Any], str]:
    results_dir = Path(results_dir)
    stamps = sorted(m.group(1) for p in results_dir.iterdir() if (m := _MAIN_CONFIG_RE.match(p.name)))
    if not stamps:
        raise FileNotFoundError(f"no hybrid_config_<stamp>.json in {results_dir}")
    stamp = stamps[-1]
    config = json.loads((results_dir / f"hybrid_config_{stamp}.json").read_text())
    df = pd.read_csv(results_dir / f"hybrid_results_{stamp}.csv", low_memory=False)

    n_before = len(df)
    df = df.drop_duplicates(_RESULT_KEY, keep="last")
    if len(df) < n_before:
        print(f"[load_results] dropped {n_before - len(df)} duplicate rows (re-appended checkpoint, kept last write)")
    if drop_degenerate:
        degenerate = df["degenerate_fit"] == True  # noqa: E712
        if degenerate.any():
            print(f"[load_results] dropped {int(degenerate.sum())} rows from degenerate GP fits")
        df = df[~degenerate]
    return df.reset_index(drop=True), config, stamp
