import numpy as np
import pandas as pd
from typing import Dict, Any, Tuple, List, Optional

from .model import durations_from_runs
from .targets import run_duration

# -----------------------------
# Lognormal utilities
# -----------------------------

def _safe_log(x: np.ndarray, eps: float = 1e-12) -> np.ndarray:
    x = np.asarray(x, dtype=float)
    x = x[np.isfinite(x)]
    x = np.maximum(x, eps)
    return np.log(x)

def fit_global_runtime_lognormal(
    runs_train: Dict[str, List[pd.DataFrame]],
    *,
    xcol: str = "t_rel_s",
) -> Tuple[float, float, np.ndarray]:
    """
    Pool ALL training run durations across ALL training queries.
    Fit lognormal params as mean/std in log-space.

    Returns (mu_log, sigma_log, T_all)
    """
    all_runs = []
    all_runs = list(runs_train.values())
    T_all = durations_from_runs(all_runs, xcol=xcol)
    T_all = T_all[np.isfinite(T_all) & (T_all > 0)]
    if T_all.size == 0:
        return float("nan"), float("nan"), T_all

    logT = _safe_log(T_all)
    mu_log = float(np.mean(logT))
    sigma_log = float(np.std(logT, ddof=0))
    sigma_log = _clip_sigma(sigma_log)
    return mu_log, sigma_log, T_all


def _clip_sigma(sigma: float, eps: float = 1e-6) -> float:
    return float(max(float(sigma), eps))

def lognormal_mean(mu_log: float, sigma_log: float) -> float:
    """E[T] for lognormal."""
    sigma = _clip_sigma(sigma_log)
    return float(np.exp(mu_log + 0.5 * sigma**2))

def lognormal_median(mu_log: float) -> float:
    """median(T) for lognormal."""
    return float(np.exp(mu_log))

def lognormal_quantile(mu_log: float, sigma_log: float, p: float) -> float:
    """
    Quantile for lognormal using Normal quantile approximation.
    Avoid SciPy: use inverse error function approximation via numpy if available.
    """
    # If you have SciPy, replace this with: norm.ppf(p)
    # We'll implement a decent approximation using erfinv if present.
    sigma = _clip_sigma(sigma_log)

    # Φ^{-1}(p) = sqrt(2) * erfinv(2p - 1)
    if hasattr(np, "erfinv"):
        z = np.sqrt(2.0) * np.erfinv(2.0 * float(p) - 1.0)
    else:
        # fallback: crude approximation (rare in modern numpy)
        # You can install scipy to remove this path.
        z = 0.0 if p == 0.5 else np.sign(p - 0.5) * 1.0

    return float(np.exp(mu_log + sigma * float(z)))

def lognormal_std(mu_log: float, sigma_log: float) -> float:
    """
    Std(T) for lognormal.
    Var(T) = (exp(s^2)-1) * exp(2m + s^2)
    """
    sigma = _clip_sigma(sigma_log)
    var = (np.exp(sigma**2) - 1.0) * np.exp(2.0 * mu_log + sigma**2)
    return float(np.sqrt(max(var, 1e-18)))

def lognormal_nll(T: np.ndarray, mu_log: float, sigma_log: float, *, include_const: bool = False) -> float:
    """
    Mean negative log likelihood for lognormal observations T.

    If include_const=False (default), drops the constant 0.5*log(2π) so
    values are comparable across models on the same dataset.
    """
    T = np.asarray(T, dtype=float)
    eps = 1e-12
    T = T[np.isfinite(T)]
    if T.size == 0:
        return float("nan")

    T = np.maximum(T, eps)
    sigma = _clip_sigma(sigma_log)

    z = (np.log(T) - float(mu_log)) / sigma
    nll = np.log(T) + np.log(sigma) + 0.5 * (z**2)
    if include_const:
        nll = nll + 0.5 * np.log(2.0 * np.pi)
    return float(np.mean(nll))


# -----------------------------
# Helpers: trace resampling
# -----------------------------
def resample_run_to_tau(
    df: pd.DataFrame,
    tau_grid: np.ndarray,
    *,
    xcol: str = "t_rel_s",
    ycol: str = "value",
) -> np.ndarray:
    """
    Convert a run with real time xcol into a normalised tau ∈ [0,1] trace,
    then interpolate onto tau_grid.

    Handles non-monotonic or repeated timestamps by sorting and dropping duplicates.
    """
    if xcol not in df.columns or ycol not in df.columns:
        return np.zeros_like(tau_grid, dtype=float)

    x = df[xcol].to_numpy(dtype=float)
    y = df[ycol].to_numpy(dtype=float)

    mask = np.isfinite(x) & np.isfinite(y)
    x = x[mask]
    y = y[mask]

    if x.size < 2:
        return np.zeros_like(tau_grid, dtype=float)

    t0, t1 = float(np.min(x)), float(np.max(x))
    T = max(t1 - t0, 1e-12)

    tau = (x - t0) / T
    order = np.argsort(tau)
    tau = tau[order]
    y = y[order]

    # ensure strictly increasing tau (drop ties)
    keep = np.concatenate([[True], np.diff(tau) > 0])
    tau = tau[keep]
    y = y[keep]

    if tau.size < 2:
        return np.zeros_like(tau_grid, dtype=float)

    return np.interp(tau_grid, tau, y)


def gaussian_nll(Y: np.ndarray, mean: np.ndarray, std: np.ndarray, *, include_const: bool = False) -> float:
    """
    Mean NLL under independent Gaussian per tau:
      y ~ N(mean[t], std[t]^2)

    Y shape: (n_runs, n_grid)
    mean/std shape: (n_grid,)
    """
    Y = np.asarray(Y, dtype=float)
    mean = np.asarray(mean, dtype=float).reshape(1, -1)
    std = np.asarray(std, dtype=float).reshape(1, -1)

    mask = np.isfinite(Y)
    if not np.any(mask):
        return float("nan")

    s = np.maximum(std, 1e-6)
    z2 = ((Y - mean) / s) ** 2
    nll = np.log(s) + 0.5 * z2
    if include_const:
        nll = nll + 0.5 * np.log(2.0 * np.pi)

    # average only over valid entries
    return float(np.mean(nll[mask]))


def quantile_pinball_loss(y: np.ndarray, qhat: float, p: float) -> float:
    """
    Pinball loss for quantile prediction.
    Lower is better; proper scoring rule for quantiles.
    """
    y = np.asarray(y, dtype=float)
    y = y[np.isfinite(y)]
    if y.size == 0:
        return float("nan")
    u = y - float(qhat)
    return float(np.mean(np.maximum(p * u, (p - 1.0) * u)))


# -----------------------------
# CRPS (Continuous Ranked Probability Score)
# -----------------------------

def crps_gaussian(y: float, mu: float, sigma: float) -> float:
    """
    Closed-form CRPS for a Gaussian predictive N(mu, sigma^2) and scalar obs y
    (Gneiting & Raftery 2007). Lower is better; a proper scoring rule.

    We evaluate in the same space as the predictive parameters. For the
    lognormal runtime heads (mu_log, sigma_log), call with y = log(T) to obtain
    the log-space CRPS, which is comparable across all Gaussian-in-log models.
    """
    from scipy.stats import norm
    sigma = _clip_sigma(float(sigma))
    z = (float(y) - float(mu)) / sigma
    return float(sigma * (z * (2.0 * norm.cdf(z) - 1.0) + 2.0 * norm.pdf(z) - 1.0 / np.sqrt(np.pi)))


def crps_ensemble(y: float, samples: np.ndarray) -> float:
    """
    Empirical CRPS from predictive samples (energy form):
        CRPS = E|X - y| - 0.5 E|X - X'|
    Suitable for sample- or quantile-based heads. Uses the O(m log m) sorted
    identity for the second term.
    """
    s = np.asarray(samples, dtype=float)
    s = s[np.isfinite(s)]
    m = s.size
    if m == 0:
        return float("nan")
    y = float(y)
    term1 = float(np.mean(np.abs(s - y)))
    s_sorted = np.sort(s)
    i = np.arange(1, m + 1)
    # sum_{j,k} |s_j - s_k| = 2 * sum_i (2i - m - 1) * s_sorted[i]
    pair_sum = 2.0 * float(np.sum((2.0 * i - m - 1.0) * s_sorted))
    term2 = 0.5 * pair_sum / (m * m)
    return float(term1 - term2)

# -----------------------------
# Baseline evaluation
# -----------------------------

def fit_global_trace_gaussian(
    runs_train: Dict[str, List[pd.DataFrame]],
    *,
    tau_grid: np.ndarray,
    xcol: str = "t_rel_s",
    ycol: str = "value",
) -> Tuple[np.ndarray, np.ndarray, np.ndarray]:
    """
    Pool ALL training traces across ALL training queries.
    Resample each run to tau_grid, then take per-tau mean and std.

    Returns (mean_tau, std_tau, Y_all) where Y_all is (n_runs, n_grid).
    """
    all_runs = []
    for q, runs in runs_train.items():
        all_runs.extend(runs)

    if len(all_runs) == 0:
        n = len(tau_grid)
        return np.zeros(n), np.ones(n), np.zeros((0, n))

    Y_all = np.vstack([
        resample_run_to_tau(df, tau_grid, xcol=xcol, ycol=ycol)
        for df in all_runs
    ])

    mean_tau = np.nanmean(Y_all, axis=0)
    std_tau = np.nanstd(Y_all, axis=0, ddof=0)
    std_tau = np.maximum(std_tau, 1e-6)  # avoid degenerate bands

    return mean_tau, std_tau, Y_all

def evaluate_global_baseline_on_test(
    *,
    runs_train: Dict[str, List[pd.DataFrame]],
    runs_test: Dict[str, List[pd.DataFrame]],
    xcol: str = "t_rel_s",
    ycol: str = "value",
    n_grid: int = 200,
    runtime_cover_ps: Tuple[float, ...] = (0.50, 0.80, 0.90, 0.95),
    trace_band_sigmas: Tuple[float, ...] = (1.0, 2.0),
    compute_trace_nll: bool = False,
) -> Tuple[pd.DataFrame, Dict[str, Any]]:
    test_q = sorted(set(runs_test.keys()))

    # Choose a fixed tau grid for the baseline trace head
    tau_grid = np.linspace(0.0, 1.0, int(n_grid), dtype=float)

    # -------- fit baselines on ALL training runs --------
    mu_log_g, sigma_log_g, T_all = fit_global_runtime_lognormal(runs_train, xcol=xcol)
    mean_tau_g, std_tau_g, Y_all = fit_global_trace_gaussian(
        runs_train, tau_grid=tau_grid, xcol=xcol, ycol=ycol
    )

    rows = []
    for run_key, df_run in runs_test.items():
        runs = runs_test[q]

        # -----------------
        # Runtime metrics (global lognormal)
        # -----------------
        T = durations_from_runs(runs, xcol=xcol)
        T_valid = T[np.isfinite(T) & (T > 0)]

        mean_pred = lognormal_mean(mu_log_g, sigma_log_g)
        median_pred = lognormal_median(mu_log_g)
        std_pred = lognormal_std(mu_log_g, sigma_log_g)

        # True summaries
        mean_true = float(np.mean(T_valid)) if T_valid.size else np.nan
        median_true = float(np.median(T_valid)) if T_valid.size else np.nan

        mae_mean = float(np.abs(mean_true - mean_pred)) if np.isfinite(mean_true) else np.nan
        mae_median = float(np.abs(median_true - median_pred)) if np.isfinite(median_true) else np.nan

        runtime_cov = {}
        runtime_pinball = {}
        if T_valid.size:
            for c in runtime_cover_ps:
                lo_p = (1.0 - float(c)) / 2.0
                hi_p = 1.0 - lo_p
                lo = lognormal_quantile(mu_log_g, sigma_log_g, lo_p)
                hi = lognormal_quantile(mu_log_g, sigma_log_g, hi_p)
                runtime_cov[c] = float(np.mean((T_valid >= lo) & (T_valid <= hi)))

            for p in (0.5, 0.9, 0.95):
                qhat = lognormal_quantile(mu_log_g, sigma_log_g, p)
                runtime_pinball[p] = quantile_pinball_loss(T_valid, qhat, p)

        nll_rt = lognormal_nll(T_valid, mu_log_g, sigma_log_g) if T_valid.size else np.nan

        # -----------------
        # Trace metrics (global mean/std trace)
        # -----------------
        Y = np.vstack([resample_run_to_tau(df, tau_grid, xcol=xcol, ycol=ycol) for df in runs])

        mae_tau = float(np.mean(np.abs(Y - mean_tau_g[None, :])))
        rmse_tau = float(np.sqrt(np.mean((Y - mean_tau_g[None, :]) ** 2)))

        trace_cov = {}
        for k in trace_band_sigmas:
            lo = mean_tau_g - float(k) * std_tau_g
            hi = mean_tau_g + float(k) * std_tau_g
            trace_cov[k] = float(np.mean((Y >= lo[None, :]) & (Y <= hi[None, :])))

        band_mean_1sigma = float(np.mean(1.0 * std_tau_g))
        band_p90_2sigma = float(np.quantile(2.0 * std_tau_g, 0.90))

        tr_nll = gaussian_nll(Y, mean_tau_g, std_tau_g) if compute_trace_nll else np.nan

        row = {
            "q": q,
            "n_runs": int(len(runs)),

            # runtime preds (global)
            "runtime_mu_log": float(mu_log_g),
            "runtime_sigma_log": float(sigma_log_g),
            "runtime_mean_pred": float(mean_pred),
            "runtime_median_pred": float(median_pred),
            "runtime_std_pred": float(std_pred),

            # runtime truth
            "runtime_mean_true": mean_true,
            "runtime_median_true": median_true,

            # errors
            "runtime_mae_mean": mae_mean,
            "runtime_mae_median": mae_median,
            "runtime_nll": nll_rt,

            # trace errors
            "trace_mae_tau": mae_tau,
            "trace_rmse_tau": rmse_tau,
            "trace_nll": tr_nll,

            # trace band widths
            "trace_band_mean_1sigma": band_mean_1sigma,
            "trace_band_p90_2sigma": band_p90_2sigma,
        }

        for c, v in runtime_cov.items():
            row[f"runtime_cov_{int(100*c)}"] = v
        for p, v in runtime_pinball.items():
            row[f"runtime_pinball_{int(100*p)}"] = v
        for k, v in trace_cov.items():
            tag = f"{k:g}".replace(".", "p")
            row[f"trace_cov_{tag}sigma"] = v

        rows.append(row)

    df_baseline = pd.DataFrame(rows)

    info = {
        "baseline": "global_workload_mean",
        "n_train_runs_runtime": int(np.sum([len(v) for v in runs_train.values()])),
        "n_train_durations": int(T_all.size),
        "runtime_mu_log_global": float(mu_log_g),
        "runtime_sigma_log_global": float(sigma_log_g),
        "tau_grid": tau_grid,
    }
    return df_baseline, info

# -----------------------------
# Main evaluation
# -----------------------------
def evaluate_unseen_queries(
    model_cls,
    basis,
    trace_head_cls,
    trace_head_kwargs,
    runtime_head_cls,
    runtime_head_kwargs,
    *,
    Z_train: Dict[str, np.ndarray],
    runs_train: Dict[str, pd.DataFrame],
    Z_test: Dict[str, np.ndarray],
    runs_test: Dict[str, pd.DataFrame],
    xcol: str = "t_rel_s",
    ycol: str = "value",
    n_grid: int = 200,
    drop_ood: bool = False,
    ood_ratio_thresh: float = 1e4,
    ood_abs_pred_thresh: float = 1e6,
    runtime_cover_ps: Tuple[float, ...] = (0.50, 0.80, 0.90, 0.95),
    trace_band_sigmas: Tuple[float, ...] = (1.0, 2.0),
    compute_trace_nll: bool = False,
) -> Tuple[Any, pd.DataFrame, Dict[str, Any]]:
    """
    Train and evaluate at query-run level.

    Z_train / Z_test:
        query_run_id -> embedding

    runs_train / runs_test:
        query_run_id -> pd.DataFrame

    Each row in the returned DataFrame corresponds to one query execution.
    """
    train_runs = sorted(set(Z_train) & set(runs_train))
    test_runs = sorted(set(Z_test) & set(runs_test))

    model = model_cls(
        basis=basis,
        trace_head_cls=trace_head_cls,
        trace_head_kwargs=trace_head_kwargs,
        runtime_head_cls=runtime_head_cls,
        runtime_head_kwargs=runtime_head_kwargs,
        n_grid=n_grid,
    )

    model.fit(
        Z_by_run={k: Z_train[k] for k in train_runs},
        runs_by_run={k: runs_train[k] for k in train_runs},
        xcol_time=xcol,
        ycol=ycol,
    )

    rows = []

    for run_key in test_runs:
        z = np.asarray(Z_test[run_key], dtype=float).reshape(-1)
        df_run = runs_test[run_key]

        # -----------------
        # Runtime truth
        # -----------------
        T = run_duration(df_run, xcol_time=xcol)
        if not np.isfinite(T) or T <= 0:
            continue

        # -----------------
        # Runtime prediction
        # -----------------
        rt = model.predict_runtime(z)

        mu_log = float(rt["mu_log"])
        sigma_log = _clip_sigma(float(rt["sigma_log"]))

        mean_pred = lognormal_mean(mu_log, sigma_log)
        median_pred = lognormal_median(mu_log)
        std_pred = lognormal_std(mu_log, sigma_log)

        runtime_mae_mean = float(abs(T - mean_pred))
        runtime_mae_median = float(abs(T - median_pred))
        runtime_nll = lognormal_nll(np.asarray([T], dtype=float), mu_log, sigma_log)
        # CRPS in log-space (comparable across all Gaussian-in-log runtime heads)
        runtime_crps = crps_gaussian(float(np.log(max(T, 1e-12))), mu_log, sigma_log)

        runtime_cov = {}
        runtime_pinball = {}

        for c in runtime_cover_ps:
            lo_p = (1.0 - float(c)) / 2.0
            hi_p = 1.0 - lo_p
            lo = lognormal_quantile(mu_log, sigma_log, lo_p)
            hi = lognormal_quantile(mu_log, sigma_log, hi_p)
            runtime_cov[c] = float(lo <= T <= hi)

        for p in (0.5, 0.9, 0.95):
            qhat = lognormal_quantile(mu_log, sigma_log, p)
            runtime_pinball[p] = quantile_pinball_loss(np.asarray([T]), qhat, p)

        # -----------------
        # Trace prediction
        # -----------------
        tr = model.predict_trace(z)

        tau_grid = np.asarray(tr["tau_grid"], dtype=float)
        mean_tau = np.asarray(tr["mean"], dtype=float)
        std_tau = np.asarray(tr["std"], dtype=float)

        y_true = resample_run_to_tau(
            df_run,
            tau_grid,
            xcol=xcol,
            ycol=ycol,
        )

        trace_mae_tau = float(np.mean(np.abs(y_true - mean_tau)))
        trace_rmse_tau = float(np.sqrt(np.mean((y_true - mean_tau) ** 2)))

        trace_cov = {}
        for k in trace_band_sigmas:
            lo = mean_tau - float(k) * std_tau
            hi = mean_tau + float(k) * std_tau
            trace_cov[k] = float(np.mean((y_true >= lo) & (y_true <= hi)))

        trace_band_mean_1sigma = float(np.mean(std_tau))
        trace_band_p90_2sigma = float(np.quantile(2.0 * std_tau, 0.90))

        trace_nll = (
            gaussian_nll(y_true.reshape(1, -1), mean_tau, std_tau)
            if compute_trace_nll
            else np.nan
        )

        query_name = getattr(df_run, "attrs", {}).get("query_name", None)
        raw_run_id = getattr(df_run, "attrs", {}).get("run_id", None)

        row = {
            "query_run_id": run_key,
            "q": query_name,
            "run_id": raw_run_id,

            # Runtime prediction
            "runtime_mu_log": mu_log,
            "runtime_sigma_log": sigma_log,
            "runtime_mean_pred": mean_pred,
            "runtime_median_pred": median_pred,
            "runtime_std_pred": std_pred,

            # Runtime truth
            "runtime_s": float(T),
            "runtime_mean_true": float(T),
            "runtime_median_true": float(T),

            # Runtime errors
            "runtime_mae_mean": runtime_mae_mean,
            "runtime_mae_median": runtime_mae_median,
            "runtime_nll": runtime_nll,
            "runtime_crps": runtime_crps,

            # Trace errors
            "trace_mae_tau": trace_mae_tau,
            "trace_rmse_tau": trace_rmse_tau,
            "trace_nll": trace_nll,

            # Trace band widths
            "trace_band_mean_1sigma": trace_band_mean_1sigma,
            "trace_band_p90_2sigma": trace_band_p90_2sigma,
        }

        for c, v in runtime_cov.items():
            row[f"runtime_cov_{int(100*c)}"] = v

        for p, v in runtime_pinball.items():
            row[f"runtime_pinball_{int(100*p)}"] = v

        for k, v in trace_cov.items():
            tag = f"{k:g}".replace(".", "p")
            row[f"trace_cov_{tag}sigma"] = v

        rows.append(row)

    df = pd.DataFrame(rows)

    # -----------------------------
    # Optional OOD dropping
    # -----------------------------
    dropped = []
    if drop_ood and len(df):
        eps = 1e-12
        ratio = (df["runtime_mean_pred"].abs() + eps) / (df["runtime_s"].abs() + eps)
        ratio_sym = np.maximum(ratio, 1.0 / ratio)

        ood_mask = (
            ~np.isfinite(df["runtime_mean_pred"])
            | ~np.isfinite(df["runtime_s"])
            | (df["runtime_mean_pred"].abs() > float(ood_abs_pred_thresh))
            | (ratio_sym > float(ood_ratio_thresh))
        )

        df["ood_ratio_sym"] = ratio_sym
        df["ood_abs_pred"] = df["runtime_mean_pred"].abs()
        df["ood_mask"] = ood_mask

        dropped = df.loc[ood_mask, "query_run_id"].tolist()
        df = df.loc[~ood_mask].reset_index(drop=True)

    info = {
        "train_runs": train_runs,
        "test_runs": test_runs,
        "dropped_ood": dropped,
        "n_train": len(train_runs),
        "n_test": len(test_runs),
        "level": "run",
    }

    return model, df, info

import numpy as np
import pandas as pd
from sklearn.metrics import mean_absolute_error, mean_squared_error
from scipy.stats import spearmanr


def q_error(y_true, y_pred, eps=1e-9):
    y_true = np.asarray(y_true, dtype=float)
    y_pred = np.asarray(y_pred, dtype=float)

    y_true = np.maximum(y_true, eps)
    y_pred = np.maximum(y_pred, eps)

    return np.maximum(y_true / y_pred, y_pred / y_true)


def evaluate_global_mean_runtime_baseline(
    runs_train,
    runs_test,
    *,
    xcol="t_rel_s",
):
    """
    Naive runtime baseline.

    Fits one global mean runtime from all training runs.
    Predicts that same runtime for every test run.

    Expected inputs:
        runs_train: query_run_id -> pd.DataFrame
        runs_test:  query_run_id -> pd.DataFrame
    """

    # Fit baseline on training runs only
    train_runtimes = []
    for run_id, df in runs_train.items():
        T = run_duration(df, xcol_time=xcol)
        if np.isfinite(T) and T > 0:
            train_runtimes.append(float(T))

    if len(train_runtimes) == 0:
        raise ValueError("No valid training runtimes found.")

    global_mean = float(np.mean(train_runtimes))

    # Evaluate on test runs
    rows = []

    for run_id, df in runs_test.items():
        T = run_duration(df, xcol_time=xcol)

        if not np.isfinite(T) or T <= 0:
            continue

        rows.append({
            "query_run_id": run_id,
            "q": getattr(df, "attrs", {}).get("query_name", None),
            "run_id": getattr(df, "attrs", {}).get("run_id", None),
            "runtime_s": float(T),
            "runtime_mean_pred": global_mean,
            "runtime_mae_mean": float(abs(T - global_mean)),
        })

    df_baseline = pd.DataFrame(rows)

    y_true = df_baseline["runtime_s"].to_numpy(dtype=float)
    y_pred = df_baseline["runtime_mean_pred"].to_numpy(dtype=float)

    qerr = q_error(y_true, y_pred)

    spearman = spearmanr(y_true, y_pred).correlation
    if not np.isfinite(spearman):
        spearman = 0.0

    metrics = {
        "mae": float(mean_absolute_error(y_true, y_pred)),
        "rmse": float(np.sqrt(mean_squared_error(y_true, y_pred))),
        "spearman": float(spearman),
        "mean_q_error": float(np.mean(qerr)),
        "median_q_error": float(np.median(qerr)),
        "p90_q_error": float(np.percentile(qerr, 90)),
        "p95_q_error": float(np.percentile(qerr, 95)),
    }

    info = {
        "baseline": "global_mean_runtime",
        "global_mean_runtime": global_mean,
        "n_train": len(train_runtimes),
        "n_test": len(df_baseline),
    }

    return df_baseline, metrics, info
