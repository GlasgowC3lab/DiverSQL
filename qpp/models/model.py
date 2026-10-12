# prediction/conditional/model.py
from __future__ import annotations

import numpy as np
import pandas as pd
from dataclasses import dataclass, field
from typing import Any, Dict, Optional, Type, List

from .basis import RBFTauBasis
from .targets import build_run_targets
from .heads_v1 import *


def durations_from_runs(
    runs: List[pd.DataFrame],
    *,
    xcol: str = "t_rel_s",
    runtime_attr: str = "runtime_s",
    runtime_col: str = "runtime_s",
    fallback_to_trace_duration: bool = False,
) -> np.ndarray:
    """
    Extract authoritative runtime per run.

    Preferred source:
        df.attrs["runtime_s"]

    Secondary source:
        df["runtime_s"]

    Optional fallback:
        max(df[xcol]) - min(df[xcol])

    This avoids treating metric trace length as query runtime unless explicitly allowed.
    """
    T = []

    for df in runs:
        if df is None or len(df) == 0:
            continue

        # 1. Preferred: runtime attached by loader from runtimes.csv
        t = None

        if runtime_attr in getattr(df, "attrs", {}):
            t = df.attrs.get(runtime_attr)

        # 2. Secondary: runtime column, if present
        if t is None and runtime_col in df.columns:
            vals = pd.to_numeric(df[runtime_col], errors="coerce").dropna()
            if len(vals) > 0:
                t = float(vals.iloc[0])

        # 3. Optional fallback: trace-derived duration
        if t is None and fallback_to_trace_duration:
            if xcol in df.columns:
                x = pd.to_numeric(df[xcol], errors="coerce").dropna()
                if len(x) >= 2:
                    t = float(x.max() - x.min())

        if t is None:
            continue

        t = float(t)

        if np.isfinite(t) and t > 0:
            T.append(t)

    return np.asarray(T, dtype=float)

@dataclass
class ConditionalTraceRuntimeModel:
    basis: RBFTauBasis
    trace_head_cls: Type[TraceHead]
    runtime_head_cls: Type[RuntimeHead]
    
    n_grid: int = 200

    # optional per-head constructor kwargs
    trace_head_kwargs: Dict[str, Any] = field(default_factory=dict)
    runtime_head_kwargs: Dict[str, Any] = field(default_factory=dict)

    # fitted heads
    trace_head: Optional[TraceHead] = None
    runtime_head: Optional[RuntimeHead] = None

    meta: Dict[str, Any] = field(default_factory=dict)

    def fit(
        self,
        *,
        Z_by_run: dict[str, np.ndarray],
        runs_by_run: dict[str, pd.DataFrame],
        xcol_time: str = "t_rel_s",
        ycol: str = "value",
        ridge_lam_targets: float = 1e-3,
        ridge_lam_heads: float = 1,
        min_runs: int = 3,
    ) -> "ConditionalTraceRuntimeModel":
        """
        Fit trace and runtime heads at query-run level.
    
        Each training example is one query execution:
            query_run_id -> embedding
            query_run_id -> trace/runtime target
    
        This avoids averaging repeated runs into one per-query trace target.
        """
        common = sorted(set(Z_by_run) & set(runs_by_run))
    
        if len(common) < int(min_runs):
            raise ValueError(
                f"Need >= {min_runs} run-level examples with embeddings and runs; got {len(common)}"
            )
    
        targets = build_run_targets(
            {k: runs_by_run[k] for k in common},
            xcol_time=xcol_time,
            ycol=ycol,
            n_grid=int(self.n_grid),
            basis=self.basis,
            ridge_lam=float(ridge_lam_targets),
        )
    
        common = [k for k in common if k in targets]
    
        if len(common) < int(min_runs):
            raise ValueError(
                f"Need >= {min_runs} valid run-level targets after filtering; got {len(common)}"
            )
    
        Z = np.vstack([
            np.asarray(Z_by_run[k], dtype=float).reshape(-1)
            for k in common
        ])
    
        Wt = np.vstack([
            np.asarray(targets[k].w, dtype=float).reshape(1, -1)
            for k in common
        ])
    
        logT = np.asarray([
            float(targets[k].logT)
            for k in common
        ], dtype=float)
    
        tau_grid = np.linspace(0.0, 1.0, int(self.n_grid))
    
        # 1) Trace head
        self.trace_head = self.trace_head_cls(
            **{
                "tau_grid": tau_grid,
                "basis": self.basis,
                **self.trace_head_kwargs,
            }
        )
    
        if hasattr(self.trace_head, "fit"):
            if isinstance(self.trace_head, FPCATraceHead):
                raise NotImplementedError(
                    "FPCATraceHead currently expects grouped query-level runs. "
                    "Use PCABLRTraceHead, BLRTraceHead, GPTraceHead, or MLPHeteroVecHead "
                    "for run-level trace training."
                )
    
            if isinstance(self.trace_head, MLPHeteroVecHead):
                self.trace_head.fit(Z, Wt)
            else:
                self.trace_head.fit(Z, Wt, lam=float(ridge_lam_heads))
    
        # 2) Runtime head
        self.runtime_head = self.runtime_head_cls(**self.runtime_head_kwargs)
        self.runtime_head.fit(Z, logT)
    
        # 3) Metadata
        self.meta.update({
            "level": "run",
            "n_runs": int(len(common)),
            "n_grid": int(self.n_grid),
            "d_embed": int(Z.shape[1]),
            "D_coeffs": int(Wt.shape[1]),
            "ridge_lam_targets": float(ridge_lam_targets),
            "ridge_lam_heads": float(ridge_lam_heads),
            "xcol_time": xcol_time,
            "ycol": ycol,
            "run_keys": list(common),
            "z_train_mean": Z.mean(axis=0),
            "z_train_std": Z.std(axis=0) + 1e-12,
        })
    
        return self

    # -------------------------
    # Minimal API
    # -------------------------

    def predict_trace(self, z: np.ndarray) -> Dict[str, np.ndarray]:
        """
        Returns:
          {"tau_grid": (n_grid,), "mean": (n_grid,), "std": (n_grid,)}
        """
        if self.trace_head is None:
            raise RuntimeError("Model not fit")
    
        z = np.asarray(z, dtype=float).reshape(-1)
    
        expected = self.meta.get("d_embed")
        if expected is not None and z.shape[0] != int(expected):
            raise ValueError(
                f"Embedding dimension mismatch: got {z.shape[0]}, expected {expected}"
            )

        return self.trace_head.predict(z)

    def predict_runtime(self, z: np.ndarray) -> Dict[str, float]:
        """
        Returns:
          {"mu_log": float, "sigma_log": float}
        """
        if self.runtime_head is None:
            raise RuntimeError("Model not fit")
    
        z = np.asarray(z, dtype=float).reshape(-1)
    
        z_train_mean = self.meta["z_train_mean"]
        z_train_std = self.meta["z_train_std"]
    
        if z.shape[0] != z_train_mean.shape[0]:
            raise ValueError(
                f"Embedding dimension mismatch: got {z.shape[0]}, "
                f"expected {z_train_mean.shape[0]}"
            )
    
        z_norm = (z - z_train_mean) / z_train_std
        ood_score = float(np.linalg.norm(z_norm))
    
        runtime = self.runtime_head.predict(z)
    
        if ood_score > 3.0:
            runtime["sigma_log"] *= min(3.0, ood_score / 3.0)
    
        return runtime

    def sample(
        self,
        z: np.ndarray,
        *,
        z_runtime: Optional[np.ndarray] = None,
        n: int = 200,
        seed: int = 0,
        t_ref_q: float = 0.95,
    ) -> Dict[str, np.ndarray]:
        """
        Sample:
          - T samples (seconds)
          - trace samples on a real-time grid t (seconds) by time-warping tau
    
        Returns:
          {"T": (n,), "t_grid": (n_t,), "Y_t": (n, n_t)}
        """
        if self.trace_head is None or self.runtime_head is None:
            raise RuntimeError("Model not fit")
    
        rng = np.random.default_rng(int(seed))
    
        # 1) sample runtimes
        if z_runtime is None:
            z_runtime = z

        T = self.runtime_head.sample(z_runtime, rng=rng, n=int(n))
    
        # 2) sample tau-space traces (support both head APIs)
        tau_grid = self.trace_head.tau_grid  # (n_grid,)
    
        if hasattr(self.trace_head, "sample_traces"):
            # FPCA-style heads: directly sample Y(tau)
            Y_tau = self.trace_head.sample_traces(z, rng=rng, n=int(n))  # (n, n_grid)
            Y_tau = np.asarray(Y_tau, dtype=float)
            if Y_tau.ndim != 2 or Y_tau.shape[0] != int(n) or Y_tau.shape[1] != tau_grid.size:
                raise ValueError(
                    f"trace_head.sample_traces returned {Y_tau.shape}, expected (n, n_grid)=({int(n)},{tau_grid.size})"
                )
        else:
            # basis-coeff heads: sample w then map through Phi(tau)
            W = self.trace_head.sample_coeffs(z, rng=rng, n=int(n))  # (n, D)
            W = np.asarray(W, dtype=float)
            Phi_tau = self.basis.design_matrix(tau_grid)  # (n_grid, D)
            Y_tau = W @ Phi_tau.T  # (n, n_grid)
    
        # 3) real-time grid (shared) using a high quantile so longer traces fit
        # guard against pathological runtime samples
        T = np.asarray(T, dtype=float).reshape(-1)
        T = np.where(np.isfinite(T) & (T > 0), T, 1e-6)
    
        T_ref = float(np.quantile(T, float(t_ref_q)))
        T_ref = max(T_ref, 1e-6)
        t_grid = np.linspace(0.0, T_ref, int(self.n_grid))
    
        # 4) warp each sample back to seconds: tau = t / T_i
        Y_t = np.zeros((int(n), t_grid.size), dtype=float)
        for i in range(int(n)):
            Ti = max(float(T[i]), 1e-12)
            tau = np.clip(t_grid / Ti, 0.0, 1.0)
            Y_t[i] = np.interp(tau, tau_grid, Y_tau[i])
    
        return {"T": T, "t_grid": t_grid, "Y_t": Y_t} 

