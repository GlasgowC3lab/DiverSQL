"""Gaussian process (RBF kernel) runtime regressor over GIN plan embeddings. Zhao et al., *Lightweight and Accurate Cardinality Estimation by Neural Network Gaussian Process*, SIGMOD 2022."""
from typing import Optional, Any, Dict

import numpy as np
from sklearn.gaussian_process import GaussianProcessRegressor
from sklearn.gaussian_process.kernels import RBF, WhiteKernel, ConstantKernel as C
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import StandardScaler

from .base_regressor import BaseRuntimeRegressor, RegressorConfig


class GPRBFRuntimeRegressor(BaseRuntimeRegressor):
    """
    Gaussian Process regressor with an RBF kernel.

    Intended as a deterministic baseline similar to the GP-RBF baseline
    used in the NNGP paper, but applied to runtime prediction over your
    fixed-vector query features.
    """

    def __init__(
        self,
        config: Optional[RegressorConfig] = None,
        *,
        length_scale: float = 1.0,
        length_scale_bounds: tuple[float, float] = (1e-2, 1e3),
        constant_value: float = 1.0,
        constant_value_bounds: tuple[float, float] = (1e-3, 1e3),
        noise_level: float = 1e-3,
        noise_level_bounds: tuple[float, float] = (1e-8, 1e1),
        alpha: float = 1e-10,
        normalize_y: bool = False,
        n_restarts_optimizer: int = 2,
        use_scaler: bool = True,
    ) -> None:
        super().__init__(config=config)
        self.length_scale = length_scale
        self.length_scale_bounds = length_scale_bounds
        self.constant_value = constant_value
        self.constant_value_bounds = constant_value_bounds
        self.noise_level = noise_level
        self.noise_level_bounds = noise_level_bounds
        self.alpha = alpha
        self.normalize_y = normalize_y
        self.n_restarts_optimizer = n_restarts_optimizer
        self.use_scaler = use_scaler

    @property
    def model_name(self) -> str:
        return "gp_rbf"

    def _build_model(self) -> Any:
        kernel = (
            C(
                self.constant_value,
                self.constant_value_bounds,
            )
            * RBF(
                length_scale=self.length_scale,
                length_scale_bounds=self.length_scale_bounds,
            )
            + WhiteKernel(
                noise_level=self.noise_level,
                noise_level_bounds=self.noise_level_bounds,
            )
        )

        gp = GaussianProcessRegressor(
            kernel=kernel,
            alpha=self.alpha,
            normalize_y=self.normalize_y,
            n_restarts_optimizer=self.n_restarts_optimizer,
            random_state=self.config.random_state,
        )

        if self.use_scaler:
            return Pipeline([
                ("scaler", StandardScaler()),
                ("gp", gp),
            ])
        return gp


    def get_search_space(self) -> Dict[str, Any]:
        kernels = [
            C(1.0, (1e-3, 1e3)) * RBF(length_scale=0.1, length_scale_bounds=(1e-2, 1e3))
            + WhiteKernel(noise_level=1e-4, noise_level_bounds=(1e-8, 1e1)),
    
            C(1.0, (1e-3, 1e3)) * RBF(length_scale=1.0, length_scale_bounds=(1e-2, 1e3))
            + WhiteKernel(noise_level=1e-3, noise_level_bounds=(1e-8, 1e1)),
    
            C(1.0, (1e-3, 1e3)) * RBF(length_scale=10.0, length_scale_bounds=(1e-2, 1e3))
            + WhiteKernel(noise_level=1e-2, noise_level_bounds=(1e-8, 1e1)),
        ]
    
        if self.use_scaler:
            return {
                "gp__kernel": kernels,
                "gp__alpha": [1e-10, 1e-8, 1e-6],
                "gp__normalize_y": [False, True],
                "gp__n_restarts_optimizer": [0, 1, 2],
            }
    
        return {
            "kernel": kernels,
            "alpha": [1e-10, 1e-8, 1e-6],
            "normalize_y": [False, True],
            "n_restarts_optimizer": [0, 1, 2],
        }

    def predict_with_std(self, x: Any) -> tuple[np.ndarray, np.ndarray]:
        """
        Returns mean prediction and predictive std in original target space.

        For Pipeline, predict through the scaler then GP manually.
        """
        if not self.is_fitted or self.model is None:
            raise RuntimeError(f"{self.model_name} has not been fitted yet.")

        x_np = self._to_numpy(x)

        if hasattr(self.model, "named_steps"):
            scaler = self.model.named_steps["scaler"]
            gp = self.model.named_steps["gp"]
            x_scaled = scaler.transform(x_np)
            mean_t, std_t = gp.predict(x_scaled, return_std=True)
        else:
            mean_t, std_t = self.model.predict(x_np, return_std=True)

        mean = self._inverse_transform_target(mean_t)

        # std is on transformed space; leave it there unless you later want
        # delta-method conversion to original runtime space.
        return mean, np.asarray(std_t, dtype=float).reshape(-1)