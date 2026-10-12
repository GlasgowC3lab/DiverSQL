"""LightGBM runtime regressor over GIN plan embeddings. Ke et al., *LightGBM: A Highly Efficient Gradient Boosting Decision Tree*, NeurIPS 2017."""
from __future__ import annotations

from typing import Any, Optional

from .base_regressor import BaseRuntimeRegressor, RegressorConfig

try:
    from lightgbm import LGBMRegressor
except ImportError as exc:  # pragma: no cover
    raise ImportError(
        "lightgbm is required for LightGBMRuntimeRegressor. Install it with `pip install lightgbm`."
    ) from exc


class LightGBMRuntimeRegressor(BaseRuntimeRegressor):
    def __init__(
        self,
        config: Optional[RegressorConfig] = None,
        *,
        n_estimators: int = 256,
        learning_rate: float = 0.05,
        num_leaves: int = 31,
        max_depth: int = -1,
        min_child_samples: int = 20,
        subsample: float = 0.8,
        colsample_bytree: float = 0.8,
        reg_alpha: float = 0.0,
        reg_lambda: float = 0.0,
        n_jobs: int = -1,
        verbose: int = -1,
    ) -> None:
        super().__init__(config=config)
        self.n_estimators = n_estimators
        self.learning_rate = learning_rate
        self.num_leaves = num_leaves
        self.max_depth = max_depth
        self.min_child_samples = min_child_samples
        self.subsample = subsample
        self.colsample_bytree = colsample_bytree
        self.reg_alpha = reg_alpha
        self.reg_lambda = reg_lambda
        self.n_jobs = n_jobs
        self.verbose = verbose

    @property
    def model_name(self) -> str:
        return "lightgbm"

    def get_search_space(self) -> Dict[str, Any]:
        return {
            "n_estimators": [64, 128, 256],
            "num_leaves": [15, 31, 63],
            "learning_rate": [0.03, 0.05, 0.1],
            "min_child_samples": [5, 10, 20],
            "max_depth": [-1, 4, 5, 6],
        }

    def _build_model(self) -> Any:
        return LGBMRegressor(
            n_estimators=self.n_estimators,
            learning_rate=self.learning_rate,
            num_leaves=self.num_leaves,
            max_depth=self.max_depth,
            min_child_samples=self.min_child_samples,
            subsample=self.subsample,
            colsample_bytree=self.colsample_bytree,
            reg_alpha=self.reg_alpha,
            reg_lambda=self.reg_lambda,
            random_state=self.config.random_state,
            n_jobs=self.n_jobs,
            verbose=self.verbose,
        )
