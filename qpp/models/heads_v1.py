"""
Prediction heads for ConditionalTraceRuntimeModel.

Conventions
-----------
- z is a query embedding vector (shape (d,)).
- Runtime heads predict lognormal parameters for T:
    log T ~ Normal(mu_log(z), sigma_log(z)^2)
- Trace heads predict a trace distribution on a normalised time grid tau in [0,1].

API (intended)
--------------
RuntimeHead:
    .fit(Z, logT) -> self
    .predict(z) -> {"mu_log": float, "sigma_log": float}
    .sample(z, rng, n) -> (n,) samples of T (seconds)

TraceHead:
    .fit(Z, W_targets, lam=...) -> self
    .predict(z) -> {"tau_grid": (G,), "mean": (G,), "std": (G,)}
    .sample_coeffs(z, rng, n) -> (n, D) coefficient samples (optional; used by model.sample)

Notes
-----
This file is intentionally numpy-only (no torch / sklearn), to keep your
experimental pipeline light and portable.
"""

from dataclasses import dataclass
from typing import Any, Dict, List, Literal, Optional, Protocol, Tuple

import numpy as np
import pandas as pd

from .basis import RBFTauBasis

__all__ = [
    # basis / utilities
    "resample_run_to_tau",

    # lightweight interfaces
    "RuntimeHead",
    "TraceHead",

    # trace heads
    "BLRTraceHead",
    "PCABLRTraceHead",
    "GPTraceHead",
    "PCAGPTraceHead",
    "MLPHeteroVecHead",
    "FPCATraceHead",

    # runtime heads
    "MLPRuntimeHead",
    "MLPHeteroRuntimeHead",
    "BLRRuntimeHead",
]
# -----------------------------------------------------------------------------
# Common utilities
# -----------------------------------------------------------------------------

def _safe_exp(x: np.ndarray, *, max_x: float = 50.0) -> np.ndarray:
    """exp(x) with clipping to avoid overflow."""
    x = np.asarray(x, dtype=float)
    return np.exp(np.clip(x, a_min=-max_x, a_max=max_x))


def _ridge_multi_target(X: np.ndarray, Y: np.ndarray, lam: float) -> Tuple[np.ndarray, np.ndarray]:
    """
    Multi-output ridge regression:

      W = argmin ||XW - Y||^2 + lam||W||^2

    Returns
    -------
    W : (d, k)
    resid_var : (k,)
        Per-target residual variance proxy.
    """
    X = np.asarray(X, dtype=float)
    Y = np.asarray(Y, dtype=float)
    n, d = X.shape
    k = Y.shape[1]

    A = X.T @ X + float(lam) * np.eye(d)
    W = np.linalg.solve(A, X.T @ Y)  # (d, k)

    resid = Y - X @ W
    var = np.var(resid, axis=0, ddof=1) + 1e-12 if n > 1 else np.ones((k,), dtype=float)
    return W, var


def _rbf_kernel(X: np.ndarray, Y: np.ndarray, *, length_scale: float, variance: float) -> np.ndarray:
    """RBF kernel: k(x,y) = variance * exp(-||x-y||^2 / (2*ell^2))."""
    X = np.asarray(X, dtype=float)
    Y = np.asarray(Y, dtype=float)
    d2 = np.sum((X[:, None, :] - Y[None, :, :]) ** 2, axis=2)
    ell2 = float(length_scale) ** 2 + 1e-12
    return float(variance) * np.exp(-0.5 * d2 / ell2)


def _pca_fit_transform(W: np.ndarray, K: int) -> Tuple[np.ndarray, np.ndarray, np.ndarray]:
    """
    PCA via SVD (numpy-only).

    Parameters
    ----------
    W : (n, D)
    K : int
        Number of components.

    Returns
    -------
    W_mean : (D,)
    Vt : (K, D)
        PCA components (rows).
    S : (n, K)
        PCA scores.
    """
    W = np.asarray(W, dtype=float)
    n, D = W.shape
    K = int(min(K, n, D))
    W_mean = W.mean(axis=0)
    X = W - W_mean
    U, s, Vt = np.linalg.svd(X, full_matrices=False)
    VtK = Vt[:K, :]
    S = U[:, :K] * s[:K]
    return W_mean, VtK, S


def resample_run_to_tau(
    df: pd.DataFrame,
    tau_grid: np.ndarray,
    *,
    xcol: str = "t_rel_s",
    ycol: str = "value",
) -> np.ndarray:
    """
    Resample a single run df onto tau_grid in [0,1] via linear interpolation.

    If df[xcol] is time in seconds:
        tau = (t - t0) / (t_end - t0)
    """
    tau_grid = np.asarray(tau_grid, dtype=float).reshape(-1)
    x = df[xcol].to_numpy(dtype=float)
    y = df[ycol].to_numpy(dtype=float)
    if len(x) < 2:
        return np.zeros_like(tau_grid, dtype=float)

    t0 = float(x[0])
    t1 = float(x[-1])
    dur = max(t1 - t0, 1e-12)
    tau = (x - t0) / dur
    return np.interp(tau_grid, tau, y)


# -----------------------------------------------------------------------------
# Lightweight "interfaces" (Protocols)
# -----------------------------------------------------------------------------

class RuntimeHead(Protocol):
    def fit(self, Z: np.ndarray, logT_targets: np.ndarray) -> "RuntimeHead": ...
    def predict(self, z: np.ndarray) -> Dict[str, float]: ...
    def sample(self, z: np.ndarray, *, rng: np.random.Generator, n: int) -> np.ndarray: ...


class TraceHead(Protocol):
    tau_grid: np.ndarray
    def fit(self, Z: np.ndarray, W_targets: np.ndarray, *, lam: float = 1e-3) -> "TraceHead": ...
    def predict(self, z: np.ndarray) -> Dict[str, np.ndarray]: ...
    def sample_coeffs(self, z: np.ndarray, *, rng: np.random.Generator, n: int) -> np.ndarray: ...


# -----------------------------------------------------------------------------
# Trace heads: BLR / PCA+BLR
# -----------------------------------------------------------------------------

@dataclass
class BLRTraceHead:
    """
    Ridge (BLR-style) head in coefficient space:

      z -> w_mean (D,) with diagonal noise in coefficient space.

    Implementation detail:
    - Standardise Z on training set.
    - Fit multi-target ridge from [Zs, 1] to W_targets.
    - Use per-dim residual variance as coefficient noise.
    """
    basis: RBFTauBasis
    tau_grid: np.ndarray

    W: Optional[np.ndarray] = None           # (d, D)
    b: Optional[np.ndarray] = None           # (D,)
    w_noise_var: Optional[np.ndarray] = None # (D,)
    meta: Dict[str, Any] = None

    z_mean: Optional[np.ndarray] = None      # (d,)
    z_std: Optional[np.ndarray] = None       # (d,)

    def fit(self, Z: np.ndarray, W_targets: np.ndarray, *, lam: float = 1e-3) -> "BLRTraceHead":
        Z = np.asarray(Z, dtype=float)
        Wt = np.asarray(W_targets, dtype=float)

        self.z_mean = Z.mean(axis=0)
        self.z_std = Z.std(axis=0) + 1e-12
        Zs = (Z - self.z_mean) / self.z_std

        Z1 = np.concatenate([Zs, np.ones((Zs.shape[0], 1), dtype=float)], axis=1)  # (n, d+1)
        W_full, resid_var = _ridge_multi_target(Z1, Wt, lam=float(lam))            # (d+1, D)

        self.W = W_full[:-1, :]
        self.b = W_full[-1, :]
        self.w_noise_var = resid_var
        self.meta = {"kind": "blr_trace_head", "lam": float(lam), "D": int(Wt.shape[1]), "d": int(Z.shape[1])}
        return self

    def _standardise(self, z: np.ndarray) -> np.ndarray:
        if self.z_mean is None or self.z_std is None:
            raise RuntimeError("BLRTraceHead not fit (standardisation missing)")
        z = np.asarray(z, dtype=float).reshape(-1)
        return (z - self.z_mean) / self.z_std

    def predict(self, z: np.ndarray) -> Dict[str, np.ndarray]:
        if self.W is None or self.b is None or self.w_noise_var is None:
            raise RuntimeError("BLRTraceHead not fit")

        zs = self._standardise(z)
        w_mean = zs @ self.W + self.b  # (D,)

        Phi = self.basis.design_matrix(self.tau_grid)  # (G, D)
        mean = Phi @ w_mean                             # (G,)

        var_tau = np.sum((Phi ** 2) * self.w_noise_var.reshape(1, -1), axis=1)
        std = np.sqrt(np.maximum(var_tau, 1e-18))

        return {"tau_grid": self.tau_grid, "mean": mean, "std": std}

    def sample_coeffs(self, z: np.ndarray, *, rng: np.random.Generator, n: int) -> np.ndarray:
        if self.W is None or self.b is None or self.w_noise_var is None:
            raise RuntimeError("BLRTraceHead not fit")
        zs = self._standardise(z)
        w_mean = zs @ self.W + self.b
        w_std = np.sqrt(np.maximum(self.w_noise_var, 1e-18))
        return rng.normal(loc=w_mean, scale=w_std, size=(int(n), w_mean.size))


@dataclass
class PCABLRTraceHead:
    """
    PCA + ridge in score space:

      W_targets (n, D) -> PCA scores S (n, K)
      [Zs, 1] -> ridge -> scores mean

    Uncertainty:
      score_noise_var (K,) is propagated to coefficient variance (diag approx) and then tau.
    """
    basis: RBFTauBasis
    tau_grid: np.ndarray

    n_components: int = 8
    lam: float = 1e-3
    use_score_resid_var: bool = True

    # ridge params (scores)
    Ws: Optional[np.ndarray] = None            # (d, K)
    bs: Optional[np.ndarray] = None            # (K,)
    score_noise_var: Optional[np.ndarray] = None  # (K,)

    # PCA params
    W_mean: Optional[np.ndarray] = None        # (D,)
    Vt: Optional[np.ndarray] = None            # (K, D)

    # Z standardisation
    z_mean: Optional[np.ndarray] = None
    z_std: Optional[np.ndarray] = None

    meta: Dict[str, Any] = None

    def fit(self, Z: np.ndarray, W_targets: np.ndarray, *, lam: float = 1e-3) -> "PCABLRTraceHead":
        Z = np.asarray(Z, dtype=float)
        Wt = np.asarray(W_targets, dtype=float)
        n, d = Z.shape
        n2, D = Wt.shape
        if n != n2:
            raise ValueError("Z and W_targets must align on first dim")
        if n < 3:
            raise ValueError("Need at least 3 training queries")

        self.z_mean = Z.mean(axis=0)
        self.z_std = Z.std(axis=0) + 1e-12
        Zs = (Z - self.z_mean) / self.z_std

        K = int(min(self.n_components, n, D))
        self.W_mean, self.Vt, S = _pca_fit_transform(Wt, K)  # S: (n,K)

        Z1 = np.concatenate([Zs, np.ones((n, 1), dtype=float)], axis=1)   # (n, d+1)
        W_full, resid_var = _ridge_multi_target(Z1, S, lam=float(lam))    # (d+1, K)

        self.Ws = W_full[:-1, :]
        self.bs = W_full[-1, :]
        self.score_noise_var = resid_var

        self.meta = {
            "kind": "pca_blr_trace_head",
            "n": int(n),
            "d": int(d),
            "D": int(D),
            "K": int(K),
            "lam": float(lam),
            "use_score_resid_var": bool(self.use_score_resid_var),
        }
        return self

    def _standardise(self, z: np.ndarray) -> np.ndarray:
        if self.z_mean is None or self.z_std is None:
            raise RuntimeError("PCABLRTraceHead not fit (standardisation missing)")
        z = np.asarray(z, dtype=float).reshape(-1)
        return (z - self.z_mean) / self.z_std

    def _predict_scores(self, zs: np.ndarray) -> Tuple[np.ndarray, np.ndarray]:
        if self.Ws is None or self.bs is None:
            raise RuntimeError("PCABLRTraceHead not fit")
        s_mean = zs @ self.Ws + self.bs
        if self.score_noise_var is None:
            s_var = np.full_like(s_mean, 1e-6)
        else:
            s_var = np.maximum(self.score_noise_var, 1e-12) if self.use_score_resid_var else np.full_like(s_mean, 1e-6)
        return s_mean, s_var

    def predict(self, z: np.ndarray) -> Dict[str, np.ndarray]:
        if self.W_mean is None or self.Vt is None:
            raise RuntimeError("PCABLRTraceHead PCA not initialised (fit not called)")

        zs = self._standardise(z)
        s_mean, s_var = self._predict_scores(zs)

        w_mean = self.W_mean + (self.Vt.T @ s_mean)                      # (D,)
        w_var = np.sum((self.Vt ** 2) * s_var.reshape(-1, 1), axis=0)    # (D,)

        Phi = self.basis.design_matrix(self.tau_grid)                    # (G, D)
        mean = Phi @ w_mean
        var_tau = np.sum((Phi ** 2) * w_var.reshape(1, -1), axis=1)
        std = np.sqrt(np.maximum(var_tau, 1e-18))

        return {"tau_grid": self.tau_grid, "mean": mean, "std": std}

    def sample_coeffs(self, z: np.ndarray, *, rng: np.random.Generator, n: int) -> np.ndarray:
        if self.W_mean is None or self.Vt is None:
            raise RuntimeError("PCABLRTraceHead not fit")

        zs = self._standardise(z)
        s_mean, s_var = self._predict_scores(zs)
        s_std = np.sqrt(np.maximum(s_var, 1e-18))

        S = rng.normal(loc=s_mean, scale=s_std, size=(int(n), s_mean.size))  # (n, K)
        W = self.W_mean.reshape(1, -1) + (S @ self.Vt)                        # (n, D)
        return W


# -----------------------------------------------------------------------------
# Trace heads: exact GP / PCA+exact GP
# -----------------------------------------------------------------------------

@dataclass
class GPTraceHead:
    """
    Exact GP in coefficient space (shared kernel across coefficient dims):

      z -> w_mean (D,) and w_var (D,) (diag approx)

    Notes:
    - This uses a shared kernel matrix (so one Cholesky).
    - alpha is (K+σ^2I)^-1 W_targets (n, D).
    - Predictive variance is computed once (scalar latent var) + per-dim residual variance.
    """
    basis: RBFTauBasis
    tau_grid: np.ndarray

    length_scale: float = 1.0
    kernel_var: float = 1
    noise_var: float = 1e-2

    # learned
    Z_train: Optional[np.ndarray] = None      # (n,d) standardised
    L: Optional[np.ndarray] = None            # (n,n) cholesky
    alpha: Optional[np.ndarray] = None        # (n,D)
    w_resid_var: Optional[np.ndarray] = None  # (D,)

    z_mean: Optional[np.ndarray] = None
    z_std: Optional[np.ndarray] = None
    meta: Dict[str, Any] = None

    def fit(self, Z: np.ndarray, W_targets: np.ndarray, *, lam: float = 0.0) -> "GPTraceHead":
        _ = lam  # kept for signature compatibility

        Z = np.asarray(Z, dtype=float)
        Wt = np.asarray(W_targets, dtype=float)
        n, d = Z.shape
        n2, D = Wt.shape
        if n != n2:
            raise ValueError("Z and W_targets must align on first dim")
        if n < 3:
            raise ValueError("Need at least 3 training queries")

        self.z_mean = Z.mean(axis=0)
        self.z_std = Z.std(axis=0) + 1e-12
        Zs = (Z - self.z_mean) / self.z_std
        self.Z_train = Zs

        K = _rbf_kernel(Zs, Zs, length_scale=float(self.length_scale), variance=float(self.kernel_var))
        Ky = K + float(self.noise_var) * np.eye(n)
        Ky = Ky + 1e-8 * np.eye(n)

        self.L = np.linalg.cholesky(Ky)

        v = np.linalg.solve(self.L, Wt)
        self.alpha = np.linalg.solve(self.L.T, v)  # (n,D)

        What = K @ self.alpha
        resid = Wt - What
        self.w_resid_var = np.var(resid, axis=0, ddof=1) if n > 1 else np.full((D,), 1e-6)

        self.meta = {
            "kind": "exact_gp_trace_head",
            "n": int(n),
            "d": int(d),
            "D": int(D),
            "length_scale": float(self.length_scale),
            "kernel_var": float(self.kernel_var),
            "noise_var": float(self.noise_var),
        }
        return self

    def _standardise(self, z: np.ndarray) -> np.ndarray:
        if self.z_mean is None or self.z_std is None:
            raise RuntimeError("GPTraceHead not fit (standardisation missing)")
        z = np.asarray(z, dtype=float).reshape(-1)
        return (z - self.z_mean) / self.z_std

    def _predict_w_mean_var(self, zs: np.ndarray) -> Tuple[np.ndarray, np.ndarray]:
        if self.Z_train is None or self.L is None or self.alpha is None:
            raise RuntimeError("GPTraceHead not fit")

        Ztr = self.Z_train
        k_star = _rbf_kernel(zs.reshape(1, -1), Ztr, length_scale=float(self.length_scale), variance=float(self.kernel_var)).reshape(-1)

        w_mean = k_star @ self.alpha  # (D,)

        # scalar latent variance (shared)
        v = np.linalg.solve(self.L, k_star)
        var_f = float(self.kernel_var) - float(v.T @ v)
        var_f = max(var_f, 1e-12)

        if self.w_resid_var is not None:
            w_var = var_f + np.maximum(self.w_resid_var, 1e-12)
        else:
            w_var = np.full_like(w_mean, var_f + float(self.noise_var))

        return w_mean, w_var

    def predict(self, z: np.ndarray) -> Dict[str, np.ndarray]:
        zs = self._standardise(z)
        w_mean, w_var = self._predict_w_mean_var(zs)

        Phi = self.basis.design_matrix(self.tau_grid)  # (G, D)
        mean = Phi @ w_mean

        var_tau = np.sum((Phi ** 2) * w_var.reshape(1, -1), axis=1)
        std = np.sqrt(np.maximum(var_tau, 1e-18))
        return {"tau_grid": self.tau_grid, "mean": mean, "std": std}

    def sample_coeffs(self, z: np.ndarray, *, rng: np.random.Generator, n: int) -> np.ndarray:
        zs = self._standardise(z)
        w_mean, w_var = self._predict_w_mean_var(zs)
        w_std = np.sqrt(np.maximum(w_var, 1e-18))
        return rng.normal(loc=w_mean, scale=w_std, size=(int(n), w_mean.size))


@dataclass
class PCAGPTraceHead:
    """
    PCA + exact GP head:

      1) PCA on W_targets: (n, D) -> scores S: (n, K)
      2) Exact GP on z -> scores (shared kernel)
      3) Reconstruct coefficient mean/var (diag approx) and propagate to tau.

    This is usually better-conditioned than "GP per coefficient" when D is large.
    """
    basis: RBFTauBasis
    tau_grid: np.ndarray

    length_scale: float = 1.0
    kernel_var: float = 1.0
    noise_var: float = 1e-2

    n_components: int = 8
    use_resid_var: bool = True

    # learned GP
    Z_train: Optional[np.ndarray] = None
    L: Optional[np.ndarray] = None
    alpha: Optional[np.ndarray] = None  # (n,K)

    # learned PCA
    W_mean: Optional[np.ndarray] = None
    Vt: Optional[np.ndarray] = None     # (K,D)
    score_resid_var: Optional[np.ndarray] = None  # (K,)

    z_mean: Optional[np.ndarray] = None
    z_std: Optional[np.ndarray] = None
    meta: Dict[str, Any] = None

    def fit(self, Z: np.ndarray, W_targets: np.ndarray, *, lam: float = 0.0) -> "PCAGPTraceHead":
        _ = lam  # signature compatibility

        Z = np.asarray(Z, dtype=float)
        Wt = np.asarray(W_targets, dtype=float)
        n, d = Z.shape
        n2, D = Wt.shape
        if n != n2:
            raise ValueError("Z and W_targets must align on first dim")
        if n < 3:
            raise ValueError("Need at least 3 training queries")

        self.z_mean = Z.mean(axis=0)
        self.z_std = Z.std(axis=0) + 1e-12
        Zs = (Z - self.z_mean) / self.z_std
        self.Z_train = Zs

        K = int(min(self.n_components, n, D))
        self.W_mean, self.Vt, S = _pca_fit_transform(Wt, K)  # S: (n,K)

        Kmat = _rbf_kernel(Zs, Zs, length_scale=float(self.length_scale), variance=float(self.kernel_var))
        Ky = Kmat + float(self.noise_var) * np.eye(n)
        Ky = Ky + 1e-8 * np.eye(n)

        self.L = np.linalg.cholesky(Ky)
        v = np.linalg.solve(self.L, S)
        self.alpha = np.linalg.solve(self.L.T, v)

        # score residual var (helps widen where GP underfits)
        S_hat = Kmat @ self.alpha
        resid = S - S_hat
        self.score_resid_var = np.var(resid, axis=0, ddof=1) if n > 1 else np.full((K,), 1e-6)

        self.meta = {
            "kind": "pca_exact_gp_trace_head",
            "n": int(n),
            "d": int(d),
            "D": int(D),
            "K": int(K),
            "length_scale": float(self.length_scale),
            "kernel_var": float(self.kernel_var),
            "noise_var": float(self.noise_var),
            "use_resid_var": bool(self.use_resid_var),
        }
        return self

    def _standardise(self, z: np.ndarray) -> np.ndarray:
        if self.z_mean is None or self.z_std is None:
            raise RuntimeError("PCAGPTraceHead not fit (standardisation missing)")
        z = np.asarray(z, dtype=float).reshape(-1)
        return (z - self.z_mean) / self.z_std

    def _predict_score_mean_var(self, zs: np.ndarray) -> Tuple[np.ndarray, np.ndarray]:
        if self.Z_train is None or self.L is None or self.alpha is None:
            raise RuntimeError("PCAGPTraceHead not fit")

        k_star = _rbf_kernel(zs.reshape(1, -1), self.Z_train, length_scale=float(self.length_scale), variance=float(self.kernel_var)).reshape(-1)
        s_mean = k_star @ self.alpha  # (K,)

        v = np.linalg.solve(self.L, k_star)
        var_f = float(self.kernel_var) - float(v.T @ v)
        var_f = max(var_f, 1e-12)

        if self.use_resid_var and (self.score_resid_var is not None):
            s_var = var_f + np.maximum(self.score_resid_var, 1e-12)
        else:
            s_var = np.full_like(s_mean, var_f + float(self.noise_var))

        return s_mean, s_var

    def predict(self, z: np.ndarray) -> Dict[str, np.ndarray]:
        if self.W_mean is None or self.Vt is None:
            raise RuntimeError("PCAGPTraceHead PCA not initialised (fit not called)")

        zs = self._standardise(z)
        s_mean, s_var = self._predict_score_mean_var(zs)

        w_mean = self.W_mean + (self.Vt.T @ s_mean)                      # (D,)
        w_var = np.sum((self.Vt ** 2) * s_var.reshape(-1, 1), axis=0)    # (D,)

        Phi = self.basis.design_matrix(self.tau_grid)
        mean = Phi @ w_mean
        var_tau = np.sum((Phi ** 2) * w_var.reshape(1, -1), axis=1)
        std = np.sqrt(np.maximum(var_tau, 1e-18))

        return {"tau_grid": self.tau_grid, "mean": mean, "std": std}

    def sample_coeffs(self, z: np.ndarray, *, rng: np.random.Generator, n: int) -> np.ndarray:
        if self.W_mean is None or self.Vt is None:
            raise RuntimeError("PCAGPTraceHead not fit")

        zs = self._standardise(z)
        s_mean, s_var = self._predict_score_mean_var(zs)
        s_std = np.sqrt(np.maximum(s_var, 1e-18))

        S = rng.normal(loc=s_mean, scale=s_std, size=(int(n), s_mean.size))  # (n,K)
        return self.W_mean.reshape(1, -1) + (S @ self.Vt)                     # (n,D)


# -----------------------------------------------------------------------------
# Trace head: FPCA + heteroscedastic score model (tau-space head)
# -----------------------------------------------------------------------------

@dataclass
class MLPHeteroVecHead:
    """
    Multi-output heteroscedastic MLP:
      z -> mu (K,) and sigma (K,)  (sigma is per-score std)

    Trains by Gaussian NLL on Y.
    Standardises Z internally.
    """
    basis: Optional[RBFTauBasis] = None
    hidden: int = 64
    lr: float = 1e-2
    steps: int = 2000
    weight_decay: float = 1e-4
    clip_grad: float = 5.0
    seed: int = 0

    W1: Optional[np.ndarray] = None
    b1: Optional[np.ndarray] = None
    W_mu: Optional[np.ndarray] = None
    b_mu: Optional[np.ndarray] = None
    W_ls: Optional[np.ndarray] = None
    b_ls: Optional[np.ndarray] = None

    z_mean: Optional[np.ndarray] = None
    z_std: Optional[np.ndarray] = None
    meta: Dict[str, Any] = None

    def fit(self, Z: np.ndarray, Y: np.ndarray) -> "MLPHeteroVecHead":
        Z = np.asarray(Z, dtype=float)
        Y = np.asarray(Y, dtype=float)
        n, d = Z.shape
        n2, K = Y.shape
        if n != n2:
            raise ValueError("Z and Y must align")
        if n < 2:
            raise ValueError("Need >=2 samples")

        self.z_mean = Z.mean(axis=0)
        self.z_std = Z.std(axis=0) + 1e-12
        Zs = (Z - self.z_mean) / self.z_std

        rng = np.random.default_rng(self.seed)
        h = int(self.hidden)

        self.W1 = 0.01 * rng.normal(size=(d, h))
        self.b1 = np.zeros((h,), dtype=float)
        self.W_mu = 0.01 * rng.normal(size=(h, K))
        self.b_mu = np.zeros((K,), dtype=float)
        self.W_ls = 0.01 * rng.normal(size=(h, K))
        self.b_ls = np.zeros((K,), dtype=float)

        def relu(x): return np.maximum(x, 0.0)

        for _ in range(int(self.steps)):
            Hpre = Zs @ self.W1 + self.b1
            H = relu(Hpre)

            mu = H @ self.W_mu + self.b_mu
            log_sigma = H @ self.W_ls + self.b_ls
            log_sigma = np.clip(log_sigma, -8.0, 8.0)
            sigma2 = np.exp(2.0 * log_sigma) + 1e-12

            resid = (Y - mu)
            g_mu = -(resid / sigma2) / n
            g_ls = (1.0 - (resid ** 2) / sigma2) / n

            g_W_mu = H.T @ g_mu + float(self.weight_decay) * self.W_mu
            g_b_mu = np.sum(g_mu, axis=0)

            g_W_ls = H.T @ g_ls + float(self.weight_decay) * self.W_ls
            g_b_ls = np.sum(g_ls, axis=0)

            g_H = g_mu @ self.W_mu.T + g_ls @ self.W_ls.T
            g_Hpre = g_H * (Hpre > 0.0)

            g_W1 = Zs.T @ g_Hpre + float(self.weight_decay) * self.W1
            g_b1 = np.sum(g_Hpre, axis=0)

            def clip(g, c):
                nrm = float(np.linalg.norm(g))
                return g * (c / (nrm + 1e-12)) if nrm > c else g

            g_W1 = clip(g_W1, self.clip_grad)
            g_b1 = clip(g_b1, self.clip_grad)
            g_W_mu = clip(g_W_mu, self.clip_grad)
            g_b_mu = clip(g_b_mu, self.clip_grad)
            g_W_ls = clip(g_W_ls, self.clip_grad)
            g_b_ls = clip(g_b_ls, self.clip_grad)

            self.W1 -= float(self.lr) * g_W1
            self.b1 -= float(self.lr) * g_b1
            self.W_mu -= float(self.lr) * g_W_mu
            self.b_mu -= float(self.lr) * g_b_mu
            self.W_ls -= float(self.lr) * g_W_ls
            self.b_ls -= float(self.lr) * g_b_ls

        self.meta = {"kind": "mlp_hetero_vec", "d": int(d), "K": int(K), "steps": int(self.steps), "lr": float(self.lr)}
        return self

    def _standardise(self, z: np.ndarray) -> np.ndarray:
        if self.z_mean is None or self.z_std is None:
            raise RuntimeError("MLPHeteroVecHead not fit")
        z = np.asarray(z, dtype=float).reshape(-1)
        return (z - self.z_mean) / self.z_std

    def predict(self, z: np.ndarray) -> Dict[str, np.ndarray]:
        if self.W1 is None or self.W_mu is None or self.W_ls is None:
            raise RuntimeError("MLPHeteroVecHead not fit")
        zs = self._standardise(z)

        hpre = zs @ self.W1 + self.b1
        h = np.maximum(hpre, 0.0)
        mu = h @ self.W_mu + self.b_mu
        log_sigma = h @ self.W_ls + self.b_ls
        log_sigma = np.clip(log_sigma, -8.0, 8.0)
        sigma = np.exp(log_sigma)
        return {"mu": mu.astype(float), "sigma": sigma.astype(float)}


@dataclass
class FPCATraceHead:
    """
    FPCA head that operates in tau-space.

    It exposes:
      - predict(z) -> mean/std on tau_grid
      - sample_traces(z, rng, n) -> (n, G)

    Optionally, for compatibility with `model.sample(...)` that expects
    `sample_coeffs`, pass `basis` so we can project sampled tau-traces to coeffs.
    """
    tau_grid: np.ndarray

    basis: Optional[RBFTauBasis] = None
    coeff_ridge_lam: float = 1e-3

    n_components: int = 8
    sigma_scale: float = 1.3
    resid_scale: float = 2.0
    fpca_mode: str = "query_means"  # "runs" or "query_means"

    score_head: Optional[MLPHeteroVecHead] = None

    mu_tau: Optional[np.ndarray] = None
    Phi_tau: Optional[np.ndarray] = None
    resid_floor_tau: Optional[np.ndarray] = None

    _proj_tau_to_w: Optional[np.ndarray] = None  # (G, D)

    meta: Dict[str, Any] = None

    def fit(
        self,
        *,
        Z_by_query: Dict[str, np.ndarray],
        runs_by_query: Dict[str, List[pd.DataFrame]],
        xcol_time: str = "t_rel_s",
        ycol: str = "value",
        min_runs_per_query: int = 2,
        score_head: Optional[MLPHeteroVecHead] = None,
    ) -> "FPCATraceHead":
        tau = np.asarray(self.tau_grid, dtype=float).reshape(-1)
        G = tau.size

        Z_samples: List[np.ndarray] = []
        Y_samples: List[np.ndarray] = []
        Z_means: List[np.ndarray] = []
        Y_means: List[np.ndarray] = []

        qids = sorted(set(Z_by_query) & set(runs_by_query))
        for q in qids:
            runs = runs_by_query.get(q, [])
            if len(runs) < int(min_runs_per_query):
                continue
            zq = np.asarray(Z_by_query[q], dtype=float).reshape(-1)

            Yr = np.vstack([resample_run_to_tau(df, tau, xcol=xcol_time, ycol=ycol) for df in runs])
            ybar = Yr.mean(axis=0)

            Z_means.append(zq)
            Y_means.append(ybar)

            for r in range(Yr.shape[0]):
                Z_samples.append(zq)
                Y_samples.append(Yr[r])

        if len(Z_means) < 3:
            raise ValueError("Need >=3 queries with enough runs to fit FPCA head")

        Z_means_arr = np.vstack(Z_means)
        Y_means_arr = np.vstack(Y_means)

        if self.fpca_mode == "runs":
            Z_train = np.vstack(Z_samples)
            Y_train = np.vstack(Y_samples)
        elif self.fpca_mode == "query_means":
            Z_train = Z_means_arr
            Y_train = Y_means_arr
        else:
            raise ValueError(f"fpca_mode must be 'runs' or 'query_means', got {self.fpca_mode}")

        self.mu_tau = Y_train.mean(axis=0)
        X = Y_train - self.mu_tau.reshape(1, -1)

        U, s, Vt = np.linalg.svd(X, full_matrices=False)
        K = int(min(self.n_components, Vt.shape[0], G))
        self.Phi_tau = Vt[:K, :]
        scores = U[:, :K] * s[:K]

        Xhat = scores @ self.Phi_tau
        resid = X - Xhat
        self.resid_floor_tau = np.var(resid, axis=0, ddof=1) if X.shape[0] > 1 else np.full((G,), 1e-6)

        if score_head is None:
            score_head = MLPHeteroVecHead(hidden=64, lr=1e-2, steps=2000, weight_decay=1e-4, seed=0)
        self.score_head = score_head.fit(Z_train, scores)

        self._proj_tau_to_w = None
        if self.basis is not None:
            Phi_basis = self.basis.design_matrix(tau)  # (G, D)
            D = Phi_basis.shape[1]
            A = Phi_basis.T @ Phi_basis + float(self.coeff_ridge_lam) * np.eye(D)
            P = np.linalg.solve(A, Phi_basis.T)         # (D, G)
            self._proj_tau_to_w = P.T                   # (G, D)

        self.meta = {
            "kind": "fpca_trace_head",
            "fpca_mode": self.fpca_mode,
            "G": int(G),
            "K": int(K),
            "n_train_samples": int(Z_train.shape[0]),
            "n_train_queries": int(Z_means_arr.shape[0]),
            "resid_floor_mean": float(np.mean(self.resid_floor_tau)),
            "has_basis_projection": bool(self._proj_tau_to_w is not None),
        }
        return self

    def predict(self, z: np.ndarray) -> Dict[str, np.ndarray]:
        if self.mu_tau is None or self.Phi_tau is None or self.score_head is None:
            raise RuntimeError("FPCATraceHead not fit")

        out = self.score_head.predict(z)
        s_mu = out["mu"]
        s_sig = self.sigma_scale * out["sigma"]

        mean = self.mu_tau + (s_mu @ self.Phi_tau)

        var = np.sum((self.Phi_tau ** 2) * (s_sig.reshape(-1, 1) ** 2), axis=0)
        if self.resid_floor_tau is not None:
            var = var + self.resid_scale * np.maximum(self.resid_floor_tau, 1e-12)

        std = np.sqrt(np.maximum(var, 1e-18))
        return {"tau_grid": self.tau_grid, "mean": mean, "std": std}

    def sample_traces(self, z: np.ndarray, *, rng: np.random.Generator, n: int) -> np.ndarray:
        if self.mu_tau is None or self.Phi_tau is None or self.score_head is None:
            raise RuntimeError("FPCATraceHead not fit")

        out = self.score_head.predict(z)
        s_mu = out["mu"]
        s_sig = self.sigma_scale * out["sigma"]

        S = rng.normal(loc=s_mu, scale=s_sig, size=(int(n), s_mu.size))   # (n,K)
        Y = self.mu_tau.reshape(1, -1) + (S @ self.Phi_tau)

        if self.resid_floor_tau is not None:
            eps = rng.normal(scale=np.sqrt(self.resid_scale * np.maximum(self.resid_floor_tau, 1e-12)), size=Y.shape)
            Y = Y + eps
        return Y

    def sample_coeffs(self, z: np.ndarray, *, rng: np.random.Generator, n: int) -> np.ndarray:
        if self._proj_tau_to_w is None:
            raise RuntimeError(
                "FPCATraceHead.sample_coeffs requires `basis` (and a successful .fit to cache projection). "
                "Either pass basis=RBFTauBasis(...) when constructing this head, or call sample_traces() instead."
            )
        Y = self.sample_traces(z, rng=rng, n=int(n))
        return Y @ self._proj_tau_to_w


# -----------------------------------------------------------------------------
# Runtime heads: MLP / heteroscedastic MLP / BLR
# -----------------------------------------------------------------------------

@dataclass
class MLPRuntimeHead:
    """
    Homoscedastic MLP runtime head:

      mu_log(z) = MLP(z)
      sigma_log = global scalar from training residuals
    """
    hidden: int = 64
    lr: float = 1e-2
    steps: int = 2000
    weight_decay: float = 1e-4
    clip_grad: float = 5.0
    seed: int = 0

    W1: Optional[np.ndarray] = None
    b1: Optional[np.ndarray] = None
    W2: Optional[np.ndarray] = None
    b2: float = 0.0
    sigma_log: float = 1.0
    meta: Dict[str, Any] = None

    z_mean: Optional[np.ndarray] = None
    z_std: Optional[np.ndarray] = None

    def fit(self, Z: np.ndarray, logT_targets: np.ndarray) -> "MLPRuntimeHead":
        Z = np.asarray(Z, dtype=float)
        y = np.asarray(logT_targets, dtype=float).reshape(-1)
        n, d = Z.shape
        if n < 2:
            raise ValueError("Need at least 2 training samples for MLPRuntimeHead")

        self.z_mean = Z.mean(axis=0)
        self.z_std = Z.std(axis=0) + 1e-12
        Zs = (Z - self.z_mean) / self.z_std

        rng = np.random.default_rng(self.seed)
        h = int(self.hidden)

        self.W1 = 0.01 * rng.normal(size=(d, h))
        self.b1 = np.zeros((h,), dtype=float)
        self.W2 = 0.01 * rng.normal(size=(h, 1))
        self.b2 = 0.0

        def relu(x): return np.maximum(x, 0.0)

        for _ in range(int(self.steps)):
            Hpre = Zs @ self.W1 + self.b1
            H = relu(Hpre)
            yhat = (H @ self.W2).reshape(-1) + self.b2
            resid = (yhat - y)

            g_yhat = (2.0 / n) * resid
            g_W2 = H.T @ g_yhat.reshape(-1, 1)
            g_b2 = float(np.sum(g_yhat))

            g_H = g_yhat.reshape(-1, 1) @ self.W2.T
            g_Hpre = g_H * (Hpre > 0.0)

            g_W1 = Zs.T @ g_Hpre
            g_b1 = np.sum(g_Hpre, axis=0)

            g_W2 += float(self.weight_decay) * self.W2
            g_W1 += float(self.weight_decay) * self.W1

            def clip(g, c):
                nrm = float(np.linalg.norm(g))
                return g * (c / (nrm + 1e-12)) if nrm > c else g

            g_W1 = clip(g_W1, self.clip_grad)
            g_b1 = clip(g_b1, self.clip_grad)
            g_W2 = clip(g_W2, self.clip_grad)

            self.W1 -= float(self.lr) * g_W1
            self.b1 -= float(self.lr) * g_b1
            self.W2 -= float(self.lr) * g_W2
            self.b2 -= float(self.lr) * g_b2

        # sigma from training residuals
        H = np.maximum(Zs @ self.W1 + self.b1, 0.0)
        mu = (H @ self.W2).reshape(-1) + self.b2
        self.sigma_log = float(max(np.std(y - mu, ddof=1), 1e-6))

        self.meta = {"kind": "mlp_runtime_head", "d": int(d), "hidden": int(h), "steps": int(self.steps), "sigma_log": float(self.sigma_log)}
        return self

    def _standardise(self, z: np.ndarray) -> np.ndarray:
        if self.z_mean is None or self.z_std is None:
            raise RuntimeError("MLPRuntimeHead not fit (standardisation missing)")
        z = np.asarray(z, dtype=float).reshape(-1)
        return (z - self.z_mean) / self.z_std

    def predict(self, z: np.ndarray) -> Dict[str, float]:
        if self.W1 is None or self.W2 is None:
            raise RuntimeError("MLPRuntimeHead not fit")
        zs = self._standardise(z)
        h = np.maximum(zs @ self.W1 + self.b1, 0.0)
        mu_log = float(h @ self.W2.reshape(-1) + self.b2)
        mu_log = float(np.clip(mu_log, -20.0, 20.0))
        return {"mu_log": mu_log, "sigma_log": float(self.sigma_log)}

    def sample(self, z: np.ndarray, *, rng: np.random.Generator, n: int) -> np.ndarray:
        p = self.predict(z)
        logT = rng.normal(loc=p["mu_log"], scale=p["sigma_log"], size=int(n))
        return _safe_exp(logT)


@dataclass
class MLPHeteroRuntimeHead:
    """
    Heteroscedastic MLP runtime head:

      logT ~ Normal(mu_log(z), sigma_log(z)^2)

    Trains by minimising NLL in log-space (up to additive constant).
    """
    hidden: int = 64
    lr: float = 1e-2 # try 5e-3
    steps: int = 3000
    weight_decay: float = 1e-4 # try  5e-4
    clip_grad: float = 5.0 # try 1
    seed: int = 0 # try 42

    log_sigma_min: float = -3.0
    log_sigma_max: float = 3.0
    eps_sigma: float = 1e-6

    W1: Optional[np.ndarray] = None
    b1: Optional[np.ndarray] = None
    W2_mu: Optional[np.ndarray] = None
    b2_mu: float = 0.0
    W2_ls: Optional[np.ndarray] = None
    b2_ls: float = -0.5

    z_mean: Optional[np.ndarray] = None
    z_std: Optional[np.ndarray] = None
    meta: Dict[str, Any] = None

    def fit(self, Z: np.ndarray, logT_targets: np.ndarray) -> "MLPHeteroRuntimeHead":
        Z = np.asarray(Z, dtype=float)
        y = np.asarray(logT_targets, dtype=float).reshape(-1)
        n, d = Z.shape
        if n < 3:
            raise ValueError("Need at least 3 training samples for MLPHeteroRuntimeHead")

        self.z_mean = Z.mean(axis=0)
        self.z_std = Z.std(axis=0) + 1e-12
        Zs = (Z - self.z_mean) / self.z_std

        rng = np.random.default_rng(self.seed)
        h = int(self.hidden)

        self.W1 = 0.01 * rng.normal(size=(d, h))
        self.b1 = np.zeros((h,), dtype=float)
        self.W2_mu = 0.01 * rng.normal(size=(h, 1))
        self.W2_ls = 0.01 * rng.normal(size=(h, 1))
        self.b2_mu = 0.0
        self.b2_ls = -0.5

        def relu(x): return np.maximum(x, 0.0)

        def clip(g, c):
            nrm = float(np.linalg.norm(g))
            return g * (c / (nrm + 1e-12)) if nrm > c else g

        for _ in range(int(self.steps)):
            Hpre = Zs @ self.W1 + self.b1
            H = relu(Hpre)

            mu = (H @ self.W2_mu).reshape(-1) + self.b2_mu
            ls = (H @ self.W2_ls).reshape(-1) + self.b2_ls
            ls = np.clip(ls, self.log_sigma_min, self.log_sigma_max)

            r = (y - mu)
            inv_var = np.exp(-2.0 * ls)

            g_mu = (mu - y) * inv_var / n
            g_ls = (-(r ** 2) * inv_var + 1.0) / n

            g_W2_mu = H.T @ g_mu.reshape(-1, 1)
            g_b2_mu = float(np.sum(g_mu))
            g_W2_ls = H.T @ g_ls.reshape(-1, 1)
            g_b2_ls = float(np.sum(g_ls))

            g_H = g_mu.reshape(-1, 1) @ self.W2_mu.T + g_ls.reshape(-1, 1) @ self.W2_ls.T
            g_Hpre = g_H * (Hpre > 0.0)

            g_W1 = Zs.T @ g_Hpre
            g_b1 = np.sum(g_Hpre, axis=0)

            g_W2_mu += float(self.weight_decay) * self.W2_mu
            g_W2_ls += float(self.weight_decay) * self.W2_ls
            g_W1 += float(self.weight_decay) * self.W1

            g_W1 = clip(g_W1, self.clip_grad)
            g_b1 = clip(g_b1, self.clip_grad)
            g_W2_mu = clip(g_W2_mu, self.clip_grad)
            g_W2_ls = clip(g_W2_ls, self.clip_grad)

            self.W1 -= float(self.lr) * g_W1
            self.b1 -= float(self.lr) * g_b1
            self.W2_mu -= float(self.lr) * g_W2_mu
            self.b2_mu -= float(self.lr) * g_b2_mu
            self.W2_ls -= float(self.lr) * g_W2_ls
            self.b2_ls -= float(self.lr) * g_b2_ls

        # training metrics
        H = np.maximum(Zs @ self.W1 + self.b1, 0.0)
        mu_hat = (H @ self.W2_mu).reshape(-1) + self.b2_mu
        ls_hat = (H @ self.W2_ls).reshape(-1) + self.b2_ls
        ls_hat = np.clip(ls_hat, self.log_sigma_min, self.log_sigma_max)
        train_nll = float(np.mean(0.5 * np.exp(-2 * ls_hat) * (y - mu_hat) ** 2 + ls_hat))

        self.meta = {
            "kind": "mlp_hetero_runtime_head",
            "d": int(d),
            "hidden": int(h),
            "steps": int(self.steps),
            "train_nll": train_nll,
            "log_sigma_range": [float(self.log_sigma_min), float(self.log_sigma_max)],
        }
        return self

    def _standardise(self, z: np.ndarray) -> np.ndarray:
        if self.z_mean is None or self.z_std is None:
            raise RuntimeError("MLPHeteroRuntimeHead not fit (standardisation missing)")
        z = np.asarray(z, dtype=float).reshape(-1)
        return (z - self.z_mean) / self.z_std

    def predict(self, z: np.ndarray) -> Dict[str, float]:
        if self.W1 is None or self.W2_mu is None or self.W2_ls is None:
            raise RuntimeError("MLPHeteroRuntimeHead not fit")
        zs = self._standardise(z)

        h = np.maximum(zs @ self.W1 + self.b1, 0.0)
        mu_log = float(h @ self.W2_mu.reshape(-1) + self.b2_mu)
        ls = float(h @ self.W2_ls.reshape(-1) + self.b2_ls)
        ls = float(np.clip(ls, self.log_sigma_min, self.log_sigma_max))

        mu_log = float(np.clip(mu_log, -20.0, 20.0))
        sigma_log = float(max(np.exp(ls), self.eps_sigma))
        return {"mu_log": mu_log, "sigma_log": sigma_log}

    def sample(self, z: np.ndarray, *, rng: np.random.Generator, n: int) -> np.ndarray:
        p = self.predict(z)
        logT = rng.normal(loc=p["mu_log"], scale=p["sigma_log"], size=int(n))
        return _safe_exp(logT)

@dataclass
class BLRRuntimeHead:
    """
    Bayesian Linear Regression on features phi(z):
      y = logT ~ N(phi(z)^T w,  beta^{-1})
      w ~ N(0, alpha^{-1} I)

    Posterior:
      S = (alpha I + beta Phi^T Phi)^-1
      m = beta S Phi^T y

    Predictive:
      mean = phi^T m
      var  = beta^{-1} + phi^T S phi
      => sigma_log = sqrt(var)

    Note: Uncertainty grows mainly with feature-space distance
    """
    basis: Literal["linear", "rbf"] = "rbf"
    alpha: float = 1e-8     # prior precision
    beta: float = 60    # noise precision (can be fit from residuals if you want)

    # rbf settings
    n_centers: int = 64
    length_scale: Optional[float] = None  # if None -> set from train stats

    # standardisation
    z_mean: Optional[np.ndarray] = None
    z_std: Optional[np.ndarray] = None

    # learned BLR params
    centers_: Optional[np.ndarray] = None   # (m, d) for rbf
    m_: Optional[np.ndarray] = None         # (p,)
    S_: Optional[np.ndarray] = None         # (p,p)
    meta: Dict[str, Any] = None

    def _standardise(self, Z: np.ndarray) -> np.ndarray:
        if self.z_mean is None or self.z_std is None:
            raise RuntimeError("Standardisation not initialised (fit not called)")
        return (Z - self.z_mean) / self.z_std

    def _phi_linear(self, Zs: np.ndarray) -> np.ndarray:
        # add bias term
        return np.concatenate([np.ones((Zs.shape[0], 1)), Zs], axis=1)

    def _phi_rbf(self, Zs: np.ndarray) -> np.ndarray:
        if self.centers_ is None:
            raise RuntimeError("RBF centers not initialised")
        C = self.centers_  # (m,d)
        # squared distances: (n,m)
        d2 = np.sum((Zs[:, None, :] - C[None, :, :]) ** 2, axis=2)
        ell = float(self.length_scale) if self.length_scale is not None else 1.0
        Phi = np.exp(-0.5 * d2 / (ell ** 2 + 1e-12))
        # include bias term
        return np.concatenate([np.ones((Zs.shape[0], 1)), Phi], axis=1)

    def _phi(self, Zs: np.ndarray) -> np.ndarray:
        if self.basis == "linear":
            return self._phi_linear(Zs)
        return self._phi_rbf(Zs)

    def fit(self, Z: np.ndarray, logT_targets: np.ndarray) -> "BLRRuntimeHead":
        Z = np.asarray(Z, dtype=float)
        y = np.asarray(logT_targets, dtype=float).reshape(-1)
        n, d = Z.shape
        if n < 3:
            raise ValueError("Need at least 3 training queries for BLRRuntimeHead")

        # standardise
        self.z_mean = Z.mean(axis=0)
        self.z_std = Z.std(axis=0) + 1e-12
        Zs = (Z - self.z_mean) / self.z_std

        # set RBF centers + length scale
        if self.basis == "rbf":
            rng = np.random.default_rng(0)
            m = min(int(self.n_centers), n)
            idx = rng.choice(n, size=m, replace=False)
            self.centers_ = Zs[idx].copy()

            if self.length_scale is None:
                # heuristic: median pairwise distance between centers
                # (cheap O(m^2) since m is small)
                CC = self.centers_
                d2 = np.sum((CC[:, None, :] - CC[None, :, :]) ** 2, axis=2)
                vals = np.sqrt(d2[np.triu_indices_from(d2, k=1)])
                self.length_scale = float(np.median(vals)) if vals.size else 1.0
                self.length_scale = max(self.length_scale, 1e-3)

        Phi = self._phi(Zs)        # (n,p)
        p = Phi.shape[1]
        alpha = float(self.alpha)
        beta = float(self.beta)

        # posterior covariance S = (alpha I + beta Phi^T Phi)^-1
        A = alpha * np.eye(p) + beta * (Phi.T @ Phi)
        # jitter for numerical stability
        A += 1e-8 * np.eye(p)
        S = np.linalg.inv(A)
        mvec = beta * (S @ (Phi.T @ y))

        self.S_ = S
        self.m_ = mvec

        # optional: refit beta from residuals (keeps calibration closer)
        yhat = Phi @ self.m_
        resid = y - yhat
        var = float(np.var(resid, ddof=1)) if n > 1 else 1.0
        var = max(var, 1e-6)
        self.beta = 1.0 / var

        self.meta = {
            "kind": "blr_runtime_head",
            "basis": self.basis,
            "n_train": int(n),
            "p": int(p),
            "alpha": float(self.alpha),
            "beta": float(self.beta),
            "length_scale": float(self.length_scale) if self.basis == "rbf" else None,
        }
        return self

    def predict(self, z: np.ndarray) -> Dict[str, float]:
        if self.m_ is None or self.S_ is None:
            raise RuntimeError("BLRRuntimeHead not fit")

        z = np.asarray(z, dtype=float).reshape(1, -1)
        zs = self._standardise(z)
        phi = self._phi(zs).reshape(-1)  # (p,)

        mu_log = float(phi @ self.m_)
        # predictive variance
        var = (1.0 / float(self.beta)) + float(phi @ (self.S_ @ phi))
        var = max(var, 1e-12)
        sigma_log = float(np.sqrt(var))
        sigma_log = float(np.clip(sigma_log, 1e-3, 2.0))

        # optional: prevent truly insane mu
        mu_log = float(np.clip(mu_log, -20.0, 20.0))
        return {"mu_log": mu_log, "sigma_log": sigma_log}

    def sample(self, z: np.ndarray, *, rng: np.random.Generator, n: int) -> np.ndarray:
        p = self.predict(z)
        logT = rng.normal(loc=p["mu_log"], scale=p["sigma_log"], size=int(n))
        return _safe_exp(logT, max_x=50.0)