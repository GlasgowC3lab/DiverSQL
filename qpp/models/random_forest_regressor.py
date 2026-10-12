"""Random Forest runtime regressor over GIN plan embeddings. Breiman, *Random Forests*, Machine Learning 45(1), 2001."""
from __future__ import annotations

from typing import Any, Optional

from sklearn.ensemble import RandomForestRegressor

from .base_regressor import BaseRuntimeRegressor, RegressorConfig


class RandomForestRuntimeRegressor(BaseRuntimeRegressor):
    def __init__(
        self,
        config: Optional[RegressorConfig] = None,
        *,
        n_estimators: int = 300,
        max_depth: int | None = 16,
        min_samples_split: int = 2,
        min_samples_leaf: int = 1,
        max_features: str | float | int | None = "sqrt",
        n_jobs: int = -1,
    ) -> None:
        super().__init__(config=config)
        self.n_estimators = n_estimators
        self.max_depth = max_depth
        self.min_samples_split = min_samples_split
        self.min_samples_leaf = min_samples_leaf
        self.max_features = max_features
        self.n_jobs = n_jobs

    @property
    def model_name(self) -> str:
        return "random_forest"

    def get_search_space(self) -> Dict[str, Any]:
        return {
            "n_estimators": [100, 200, 300, 500],
            "max_depth": [None, 8, 12, 16],
            "min_samples_leaf": [1, 2, 4],
        }

    def _build_model(self) -> Any:
        return RandomForestRegressor(
            n_estimators=self.n_estimators,
            max_depth=self.max_depth,
            min_samples_split=self.min_samples_split,
            min_samples_leaf=self.min_samples_leaf,
            max_features=self.max_features,
            random_state=self.config.random_state,
            n_jobs=self.n_jobs,
        )
