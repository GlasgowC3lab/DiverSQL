# prediction/conditional/basis.py
from __future__ import annotations
import numpy as np
from dataclasses import dataclass
from typing import Optional


@dataclass
class RBFTauBasis:
    """
    Fixed RBF basis on tau in [0,1].
    Phi(tau) = [1, exp(-(tau-c1)^2/(2l^2)), ...]
    """
    n_centers: int = 25
    length_scale: float = 0.10
    include_bias: bool = True

    def centers(self) -> np.ndarray:
        return np.linspace(0.0, 1.0, int(self.n_centers))

    def design_matrix(self, tau: np.ndarray) -> np.ndarray:
        tau = np.asarray(tau, dtype=float).reshape(-1)
        C = self.centers().reshape(1, -1)     # (1, M)
        T = tau.reshape(-1, 1)                # (N, 1)

        l2 = float(self.length_scale) ** 2
        if l2 <= 0:
            raise ValueError("length_scale must be > 0")

        rbf = np.exp(-0.5 * ((T - C) ** 2) / l2)  # (N, M)

        if self.include_bias:
            bias = np.ones((tau.shape[0], 1), dtype=float)
            return np.concatenate([bias, rbf], axis=1)
        return rbf
