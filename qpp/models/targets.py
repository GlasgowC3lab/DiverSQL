import numpy as np
import pandas as pd
from dataclasses import dataclass
from typing import Dict, List, Tuple, Optional

from .basis import RBFTauBasis


def _clean_xy(df: pd.DataFrame, xcol: str, ycol: str) -> Tuple[np.ndarray, np.ndarray]:
    d = df[[xcol, ycol]].dropna().copy()
    if len(d) < 2:
        return np.array([]), np.array([])
    x = d[xcol].to_numpy(dtype=float)
    y = d[ycol].to_numpy(dtype=float)
    order = np.argsort(x)
    x, y = x[order], y[order]
    keep = np.concatenate(([True], np.diff(x) > 0))
    return x[keep], y[keep]


def run_duration(
    df: pd.DataFrame,
    *,
    xcol_time: str,
    runtime_attr: str = "runtime_s",
    runtime_col: str = "runtime_s",
    fallback_to_trace_duration: bool = False,
) -> float:
    if df is None or len(df) == 0:
        return float("nan")

    if runtime_attr in getattr(df, "attrs", {}):
        t = float(df.attrs[runtime_attr])
        if np.isfinite(t) and t > 0:
            return t

    if runtime_col in df.columns:
        vals = pd.to_numeric(df[runtime_col], errors="coerce").dropna()
        if len(vals) > 0:
            t = float(vals.iloc[0])
            if np.isfinite(t) and t > 0:
                return t

    if fallback_to_trace_duration and xcol_time in df.columns:
        x = pd.to_numeric(df[xcol_time], errors="coerce").dropna().to_numpy(dtype=float)
        if x.size >= 2:
            t = float(np.nanmax(x) - np.nanmin(x))
            if np.isfinite(t) and t > 0:
                return t

    return float("nan")


def resample_to_tau_grid(df: pd.DataFrame, *, tau_grid: np.ndarray, xcol_time: str, ycol: str) -> np.ndarray:
    x, y = _clean_xy(df, xcol_time, ycol)
    if x.size < 2:
        return np.zeros_like(tau_grid, dtype=float)

    t0 = float(np.min(x))
    t1 = float(np.max(x))
    T = max(t1 - t0, 1e-12)
    tau = (x - t0) / T
    return np.interp(tau_grid, tau, y)


def ridge_fit(Phi: np.ndarray, y: np.ndarray, lam: float) -> np.ndarray:
    """
    w = argmin ||Phi w - y||^2 + lam ||w||^2
    """
    D = Phi.shape[1]
    A = Phi.T @ Phi + float(lam) * np.eye(D)
    b = Phi.T @ y.reshape(-1)
    return np.linalg.solve(A, b)


@dataclass
class QueryTargets:
    query_name: str
    w_mean: np.ndarray          # (D,)
    w_var: np.ndarray           # (D,) diag variance proxy
    logT_mean: float
    logT_std: float
    meta: Dict[str, float]


def build_query_targets(
    runs_by_query: Dict[str, List[pd.DataFrame]],
    *,
    xcol_time: str = "t_rel_s",
    ycol: str = "value",
    n_grid: int = 200,
    basis: Optional[RBFTauBasis] = None,
    ridge_lam: float = 1e-3,
    eps: float = 1e-9,
) -> Dict[str, QueryTargets]:
    """
    For each query:
      - resample each run to a shared tau grid
      - compute mean trace ybar(tau)
      - fit basis coefficients w_mean for ybar
      - estimate coefficient variance via per-run fitted coefficients dispersion
      - fit lognormal params for runtime via log(T)
    """
    basis = basis or RBFTauBasis()
    tau_grid = np.linspace(0.0, 1.0, int(n_grid))
    Phi = basis.design_matrix(tau_grid)  # (n_grid, D)
    D = Phi.shape[1]

    out: Dict[str, QueryTargets] = {}

    for q, runs in runs_by_query.items():
        if len(runs) < 2:
            continue

        # --- runtime targets ---
        Ts = np.array([run_duration(r, xcol_time=xcol_time) for r in runs], dtype=float)
        Ts = Ts[np.isfinite(Ts) & (Ts > 0)]
        if Ts.size < 2:
            continue
        logT = np.log(Ts + eps)
        logT_mean = float(logT.mean())
        logT_std = float(max(logT.std(ddof=1), 1e-12))

        # --- trace targets on tau ---
        Y = np.vstack([resample_to_tau_grid(r, tau_grid=tau_grid, xcol_time=xcol_time, ycol=ycol) for r in runs])  # (n_runs, n_grid)
        ybar = Y.mean(axis=0)

        # mean coefficients (fit to mean trace)
        w_mean = ridge_fit(Phi, ybar, lam=ridge_lam)

        # per-run coefficients (for variance proxy)
        W = np.vstack([ridge_fit(Phi, Y[i], lam=ridge_lam) for i in range(Y.shape[0])])  # (n_runs, D)
        w_var = np.var(W, axis=0, ddof=1) + 1e-12

        out[q] = QueryTargets(
            query_name=q,
            w_mean=w_mean,
            w_var=w_var,
            logT_mean=logT_mean,
            logT_std=logT_std,
            meta={
                "n_runs": float(len(runs)),
                "n_grid": float(n_grid),
                "ridge_lam": float(ridge_lam),
            },
        )

    return out

@dataclass
class RunTargets:
    run_id: str
    w: np.ndarray              # (D,)
    logT: float
    meta: Dict[str, float]


def build_run_targets(
    runs_by_run: Dict[str, pd.DataFrame],
    *,
    xcol_time: str = "t_rel_s",
    ycol: str = "value",
    n_grid: int = 200,
    basis: Optional[RBFTauBasis] = None,
    ridge_lam: float = 1e-3,
    eps: float = 1e-9,
) -> Dict[str, RunTargets]:
    """
    Build one trace/runtime target per query execution.

    Unlike build_query_targets(...), this does NOT average traces across
    repeated executions of the same query.

    Input
    -----
    runs_by_run:
        query_run_id -> pd.DataFrame

    Returns
    -------
    dict
        query_run_id -> RunTargets
    """
    basis = basis or RBFTauBasis()
    tau_grid = np.linspace(0.0, 1.0, int(n_grid))
    Phi = basis.design_matrix(tau_grid)

    out: Dict[str, RunTargets] = {}

    for run_key, df in runs_by_run.items():
        if df is None or len(df) < 2:
            continue

        T = run_duration(df, xcol_time=xcol_time)
        if not np.isfinite(T) or T <= 0:
            continue

        y_tau = resample_to_tau_grid(
            df,
            tau_grid=tau_grid,
            xcol_time=xcol_time,
            ycol=ycol,
        )

        if y_tau.size != tau_grid.size:
            continue

        w = ridge_fit(Phi, y_tau, lam=ridge_lam)

        out[str(run_key)] = RunTargets(
            run_id=str(run_key),
            w=w,
            logT=float(np.log(T + eps)),
            meta={
                "runtime_s": float(T),
                "n_grid": float(n_grid),
                "ridge_lam": float(ridge_lam),
            },
        )

    return out
