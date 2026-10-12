import json
from pathlib import Path
from typing import Any, Dict, Iterable, List, Optional

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd

OURS = "gpt_generated"

LEG_DISPLAY_NAMES = {
    "gpt_generated": "DiverSQL",
    "tpcds": "TPC-DS",
    "sqlbarber": "SQLBarber",
    "bootstrapping_lcm": "Bootstrapping LCM",
    "sql_factory": "SQL-Factory",
    "e2etune": "E2ETune",
    "sqlstorm": "SQLStorm",
}
LEG_COLORS = {
    "tpcds": "#9ca3af",
    "sqlbarber": "#a855f7",
    "bootstrapping_lcm": "#6366f1",
    "sql_factory": "#0891b2",
    "e2etune": "#059669",
    "sqlstorm": "#db2777",
    "gpt_generated": "#ea580c",
}
MODEL_DISPLAY_NAMES = {
    "mean": "Mean",
    "random_forest": "Random Forest",
    "gp_rbf": "GP-RBF",
    "xgboost": "XGBoost",
    "lightgbm": "LightGBM",
    "mlp": "MLP",
    "tlstm": "TLSTM",
    "tnn": "TNN",
    "tpool": "TPool",
    "mscn": "MSCN",
}
METRIC_DISPLAY_NAMES = {
    "mae": "MAE", "rmse": "RMSE", "r2": "R2",
    "log_mae": "Log MAE", "log_rmse": "Log RMSE", "log_r2": "Log R2",
    "mean_q_error": "Mean Q-Error", "median_q_error": "Median Q-Error",
    "p90_q_error": "P90 Q-Error", "p95_q_error": "P95 Q-Error",
    "max_q_error": "Max Q-Error", "gmean_q_error": "GMean Q-Error",
    "spearman": "Spearman",
}
METRIC_DIRECTIONS = {  # True == lower is better
    "mae": True, "rmse": True, "r2": False,
    "log_mae": True, "log_rmse": True, "log_r2": False,
    "mean_q_error": True, "median_q_error": True, "p90_q_error": True,
    "p95_q_error": True, "max_q_error": True, "gmean_q_error": True,
    "spearman": False,
}
METRIC_COLS = list(METRIC_DIRECTIONS)

CORE_METRICS = ["log_mae", "log_rmse", "median_q_error", "gmean_q_error", "p90_q_error", "spearman"]


def display_name(leg: str) -> str:
    name = LEG_DISPLAY_NAMES.get(leg, leg)
    return f"{name} (Ours)" if leg == OURS else name


def model_display_name(model: str) -> str:
    return MODEL_DISPLAY_NAMES.get(model, model)


def metric_display_name(metric: str) -> str:
    return METRIC_DISPLAY_NAMES.get(metric, metric)


# ---------------------------------------------------------------------------
# Loading
# ---------------------------------------------------------------------------

def load_latest(results_dir: Path, regime: str) -> Dict[str, Any]:
    def _latest(pattern: str) -> Optional[Path]:
        matches = sorted(results_dir.glob(pattern))
        return matches[-1] if matches else None

    results_path = _latest(f"cold_start_dose_response_{regime}_qpp_results_*.csv")
    stats_path = _latest(f"cold_start_dose_response_{regime}_subset_stats_*.csv")
    legs_path = _latest(f"cold_start_dose_response_{regime}_legs_*.json")
    train_diag_path = _latest(f"cold_start_dose_response_{regime}_train_diagnostics_*.csv")
    history_path = _latest(f"cold_start_dose_response_{regime}_training_history_*.csv")

    if results_path is None or stats_path is None or legs_path is None:
        raise FileNotFoundError(
            f"No {regime!r} results found in {results_dir} -- run "
            f"qpp_cold_start_{regime}_training.ipynb first."
        )

    return dict(
        results=pd.read_csv(results_path, dtype={"seed": str}),
        stats=pd.read_csv(stats_path, dtype={"seed": str}),
        train_diagnostics=pd.read_csv(train_diag_path, dtype={"seed": str}) if train_diag_path else None,
        training_history=pd.read_csv(history_path, dtype={"seed": str}) if history_path else None,
        legs_meta=json.loads(legs_path.read_text()),
        file_names=dict(
            results=results_path.name, stats=stats_path.name, legs=legs_path.name,
            train_diagnostics=train_diag_path.name if train_diag_path else None,
            training_history=history_path.name if history_path else None,
        ),
    )


# ---------------------------------------------------------------------------
# Off-diagonal aggregation
# ---------------------------------------------------------------------------

def build_curve(df_results: pd.DataFrame, *, exclude_degenerate: bool = True) -> pd.DataFrame:
    if exclude_degenerate and "degenerate_fit" in df_results.columns:
        df_results = df_results[~df_results["degenerate_fit"].astype(bool)]

    off_diag = (
        df_results.groupby(["train_leg", "seed", "n_queries", "model"])[METRIC_COLS]
        .mean()
        .reset_index()
    )
    curve = (
        off_diag.groupby(["train_leg", "n_queries", "model"])[METRIC_COLS]
        .agg(["mean", "std"])
    )
    curve.columns = ["_".join(c) for c in curve.columns]
    return curve.reset_index().sort_values(["train_leg", "model", "n_queries"]).reset_index(drop=True)


def build_cost_curve(df_results: pd.DataFrame) -> pd.DataFrame:
    return (
        df_results.groupby(["train_leg", "n_queries", "model"])["training_cost_this_step"]
        .mean()
        .reset_index()
    )


def leg_curve(curve: pd.DataFrame, leg: str, model: str) -> pd.DataFrame:
    return curve[(curve.train_leg == leg) & (curve.model == model)].sort_values("n_queries")


# ---------------------------------------------------------------------------
# Results table
# ---------------------------------------------------------------------------

def _pick_checkpoint_n(curve: pd.DataFrame, leg: str, model: str, selector):
    sub = leg_curve(curve, leg, model)
    if sub.empty:
        return None
    ns = sub["n_queries"].to_numpy(dtype=float)
    if selector == "min":
        return ns.min()
    if selector == "max":
        return ns.max()
    return ns[np.argmin(np.abs(ns - float(selector)))]


def results_table(
    curve: pd.DataFrame, *, model: str, metrics: Iterable[str], available_legs: List[str], selector="max",
) -> pd.DataFrame:
    metrics = list(metrics)
    rows = []
    for leg in available_legs:
        n = _pick_checkpoint_n(curve, leg, model, selector)
        if n is None:
            continue
        row = leg_curve(curve, leg, model)
        row = row[row.n_queries == n].iloc[0]
        entry = {"leg": leg, "n_queries": int(n)}
        for m in metrics:
            entry[m] = row[f"{m}_mean"]
            entry[f"{m}_std"] = row[f"{m}_std"]
        rows.append(entry)
    return pd.DataFrame(rows).set_index("leg")


def format_results_table(df: pd.DataFrame, metrics: Iterable[str]) -> pd.DataFrame:
    """`results_table`'s numeric output -> a compact 'mean ± std' display table."""
    metrics = list(metrics)
    out = pd.DataFrame(index=[display_name(l) for l in df.index])
    out["n"] = df["n_queries"].astype(int).to_numpy()
    for m in metrics:
        out[metric_display_name(m)] = [
            f"{mean:.3f} ± {std:.3f}" if np.isfinite(mean) else "--"
            for mean, std in zip(df[m].to_numpy(), df[f"{m}_std"].to_numpy())
        ]
    return out


# ---------------------------------------------------------------------------
# Plot: performance vs. training-set size (single regime)
# ---------------------------------------------------------------------------

def learning_curve_grid(
    curve: pd.DataFrame, *, metric: str, available_legs: List[str], models: List[str],
    exclude_models=("mean",), title_extra: str = "", regime_label: str = "",
):
    lower_better = METRIC_DIRECTIONS[metric]
    panel_models = [m for m in models if m not in exclude_models]

    fig, axes = plt.subplots(1, len(panel_models), figsize=(4.6 * len(panel_models), 4.8), sharey=False)
    if len(panel_models) == 1:
        axes = [axes]

    for ax, model in zip(axes, panel_models):
        for leg in available_legs:
            sub = leg_curve(curve, leg, model)
            if not sub.empty:
                ax.plot(
                    sub["n_queries"], sub[f"{metric}_mean"], "-o", markersize=4,
                    color=LEG_COLORS.get(leg, "#333"), label=display_name(leg),
                )
        ax.set_xscale("log")
        if lower_better:
            ax.invert_yaxis()
        ax.set_xlabel("training queries (n)")
        ax.set_title(model_display_name(model))

    axis_note = "axis inverted: up = better" if lower_better else "higher = better"
    axes[0].set_ylabel(f"{metric_display_name(metric)}  ({axis_note})")
    handles, labels = axes[0].get_legend_handles_labels()
    fig.legend(handles, labels, loc="upper center", bbox_to_anchor=(0.5, 1.14),
               ncol=min(len(available_legs), 7), fontsize=8)
    fig.suptitle(
        f"Off-diagonal {metric_display_name(metric)} vs. training-set size{title_extra} ({regime_label})",
        y=1.2,
    )
    plt.tight_layout()
    return fig


# ---------------------------------------------------------------------------
# Plot: rate of improvement (gradient) -- single regime
# ---------------------------------------------------------------------------

def rate_of_improvement(
    curve: pd.DataFrame, *, metric: str, model: str, available_legs: List[str], title_suffix: str = "",
):
    fig, ax = plt.subplots(figsize=(7.5, 5.5))
    saturation_rows = []

    for leg in available_legs:
        sub = leg_curve(curve, leg, model)
        if len(sub) < 2:
            continue

        n = sub["n_queries"].to_numpy(dtype=float)
        y = sub[f"{metric}_mean"].to_numpy(dtype=float)
        y_std = sub[f"{metric}_std"].to_numpy(dtype=float)

        log_n = np.log(n)
        grad = np.diff(y) / np.diff(log_n)
        grad_n = n[1:]

        ax.plot(grad_n, grad, marker="o", color=LEG_COLORS.get(leg, "#333"), label=display_name(leg))

        noise_floor = np.nanmean(y_std) if not np.all(np.isnan(y_std)) else np.nan
        sat_n, sat_metric = None, None
        if not np.isnan(noise_floor):
            below = np.where(np.abs(grad) < noise_floor)[0]
            if len(below):
                sat_n = float(grad_n[below[0]])
                sat_metric = float(y[below[0] + 1])

        saturation_rows.append({
            "leg": leg, "noise_floor": noise_floor, "saturation_n": sat_n,
            f"{metric}_at_saturation": sat_metric, f"{metric}_at_full": float(y[-1]), "full_n": float(n[-1]),
        })
        if sat_n is not None:
            ax.axvline(sat_n, color=LEG_COLORS.get(leg, "#333"), linestyle="--", alpha=0.3)

    ax.axhline(0, color="black", linewidth=0.6)
    ax.set_xscale("log")
    ax.set_xlabel("training queries (n)")
    ax.set_ylabel(
        f"delta {metric_display_name(metric)} / delta log(n)\n"
        "(further from 0 = still improving; near 0 = saturated)"
    )
    ax.set_title(f"Rate of improvement vs. training-set size\n({model_display_name(model)}{title_suffix})")
    ax.legend(fontsize=8, ncol=2)
    plt.tight_layout()

    df_sat = pd.DataFrame(saturation_rows).set_index("leg").reindex(available_legs)
    return fig, df_sat


# ---------------------------------------------------------------------------
# Plot: learning rate, offline vs. online (cross-regime)
# ---------------------------------------------------------------------------

def learning_rate_comparison(
    curve_a: pd.DataFrame, curve_b: pd.DataFrame, *, metric: str, model: str, available_legs: List[str],
    label_a: str = "offline", label_b: str = "online",
):
    fig, ax = plt.subplots(figsize=(8, 5.5))

    for leg in available_legs:
        for curve, style, alpha, label in (
            (curve_a, "-o", 1.0, label_a), (curve_b, "--s", 0.8, label_b),
        ):
            sub = leg_curve(curve, leg, model)
            if len(sub) < 2:
                continue
            n = sub["n_queries"].to_numpy(dtype=float)
            y = sub[f"{metric}_mean"].to_numpy(dtype=float)
            log_n = np.log(n)
            grad = np.diff(y) / np.diff(log_n)
            grad_n = n[1:]
            ax.plot(
                grad_n, grad, style, markersize=4, alpha=alpha,
                color=LEG_COLORS.get(leg, "#333"),
                label=display_name(leg) if curve is curve_a else None,
            )

    ax.axhline(0, color="black", linewidth=0.6)
    ax.set_xscale("log")
    ax.set_xlabel("training queries (n)")
    ax.set_ylabel(f"delta {metric_display_name(metric)} / delta log(n)")
    ax.set_title(
        f"Learning rate: {label_a} (solid) vs. {label_b} (dashed) -- {model_display_name(model)}"
    )
    ax.legend(fontsize=8, ncol=2)
    plt.tight_layout()
    return fig
