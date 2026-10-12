"""XGBoost runtime regressor over GIN plan embeddings. Chen & Guestrin, *XGBoost: A Scalable Tree Boosting System*, KDD 2016."""
from __future__ import annotations

from typing import Any, Optional

from .base_regressor import BaseRuntimeRegressor, RegressorConfig

try:
    from xgboost import XGBRegressor
except ImportError as exc:  # pragma: no cover
    raise ImportError(
        "xgboost is required for XGBoostRuntimeRegressor. Install it with `pip install xgboost`."
    ) from exc


class XGBoostRuntimeRegressor(BaseRuntimeRegressor):
    def __init__(
        self,
        config: Optional[RegressorConfig] = None,
        *,
        n_estimators: int = 256,
        max_depth: int = 6,
        learning_rate: float = 0.05,
        subsample: float = 0.8,
        colsample_bytree: float = 0.8,
        reg_alpha: float = 0.0,
        reg_lambda: float = 1.0,
        min_child_weight: float = 1.0,
        objective: str = "reg:squarederror",
        n_jobs: int = -1,
        random_state=42,
    ) -> None:
        super().__init__(config=config)
        self.n_estimators = n_estimators
        self.max_depth = max_depth
        self.learning_rate = learning_rate
        self.subsample = subsample
        self.colsample_bytree = colsample_bytree
        self.reg_alpha = reg_alpha
        self.reg_lambda = reg_lambda
        self.min_child_weight = min_child_weight
        self.objective = objective
        self.n_jobs = n_jobs

    @property
    def model_name(self) -> str:
        return "xgboost"

    def get_search_space(self) -> Dict[str, Any]:
        return {
            "n_estimators": [64, 128, 256],
            "max_depth": [3, 4, 5, 6, 8],
            "learning_rate": [0.03, 0.05, 0.1],
            "subsample": [0.8, 1.0],
            "colsample_bytree": [0.8, 1.0],
        }

    def _build_model(self) -> Any:
        return XGBRegressor(
            n_estimators=self.n_estimators,
            max_depth=self.max_depth,
            learning_rate=self.learning_rate,
            subsample=self.subsample,
            colsample_bytree=self.colsample_bytree,
            reg_alpha=self.reg_alpha,
            reg_lambda=self.reg_lambda,
            min_child_weight=self.min_child_weight,
            objective=self.objective,
            random_state=self.config.random_state,
            n_jobs=self.n_jobs,
        )
