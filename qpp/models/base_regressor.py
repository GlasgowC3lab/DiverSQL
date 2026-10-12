from abc import ABC, abstractmethod
from dataclasses import dataclass, asdict
from pathlib import Path
from typing import Any, Dict, Optional, Literal

import joblib
import numpy as np
import pandas as pd
from sklearn.metrics import mean_absolute_error, mean_squared_error, r2_score
from sklearn.model_selection import GridSearchCV, RandomizedSearchCV

ArrayLike = np.ndarray


@dataclass
class RegressorConfig:
    log_target: bool = True
    log_base: float = 2.0
    target_epsilon: float = 1e-12
    clip_min_prediction: float = 1e-12
    random_state: int = 42


class BaseRuntimeRegressor(ABC):
    """
    Shared base class for deterministic pointwise runtime regressors.

    Design choices:
    - optionally train on log-transformed targets
    - expose a consistent fit / predict / evaluate / save / load API
    - operate on numpy arrays or pandas DataFrames
    - support generic hyperparameter search in the base class
    """

    def __init__(self, config: Optional[RegressorConfig] = None) -> None:
        self.config = config or RegressorConfig()
        self.model = None
        self.best_model_ = None
        self.best_params_: Optional[Dict[str, Any]] = None
        self.search_results_: Optional[Dict[str, Any]] = None
        self.is_fitted: bool = False

    @property
    @abstractmethod
    def model_name(self) -> str:
        raise NotImplementedError

    @abstractmethod
    def _build_model(self) -> Any:
        raise NotImplementedError

    def get_search_space(self) -> Dict[str, Any]:
        """
        Override in subclasses to provide a default parameter grid/distribution.

        Returned dict is used as:
        - param_grid for GridSearchCV
        - param_distributions for RandomizedSearchCV
        """
        return {}

    def _to_numpy(self, x: Any) -> np.ndarray:
        if hasattr(x, "to_numpy"):
            x = x.to_numpy()
        x = np.asarray(x)
        if x.ndim == 1:
            x = x.reshape(-1, 1)
        return x

    def _transform_target(self, y: Any) -> np.ndarray:
        y = np.asarray(y, dtype=float).reshape(-1)
        if self.config.log_target:
            if self.config.log_base == 2:
                return np.log2(y + self.config.target_epsilon)
            if self.config.log_base == 10:
                return np.log10(y + self.config.target_epsilon)
            return np.log(y + self.config.target_epsilon) / np.log(self.config.log_base)
        return y

    def _inverse_transform_target(self, y_pred: Any) -> np.ndarray:
        y_pred = np.asarray(y_pred, dtype=float).reshape(-1)
        if self.config.log_target:
            y_pred = np.power(self.config.log_base, y_pred)
        return np.maximum(y_pred, self.config.clip_min_prediction)

    def _active_model(self) -> Any:
        if self.best_model_ is not None:
            return self.best_model_
        return self.model

    def fit(self, x: Any, y: Any, **fit_kwargs: Any) -> "BaseRuntimeRegressor":
        x_np = self._to_numpy(x)
        y_np = self._transform_target(y)

        self.model = self._build_model()
        self.model.fit(x_np, y_np, **fit_kwargs)

        self.best_model_ = None
        self.best_params_ = None
        self.search_results_ = None
        self.is_fitted = True
        return self

    def tune(
        self,
        x: Any,
        y: Any,
        *,
        param_grid: Optional[Dict[str, Any]] = None,
        search_type: Literal["grid", "random"] = "random",
        n_iter: int = 20,
        cv: int = 5,
        scoring: str = "neg_mean_absolute_error",
        n_jobs: int = -1,
        verbose: int = 0,
        refit: bool = True,
        return_train_score: bool = True,
        **search_kwargs: Any,
    ) -> "BaseRuntimeRegressor":
        """
        Generic hyperparameter tuning.

        Notes
        -----
        - Always tunes on the transformed target if log_target=True.
        - After tuning, self.model is set to the best estimator if refit=True.
        """
        x_np = self._to_numpy(x)
        y_np = self._transform_target(y)

        estimator = self._build_model()
        search_space = param_grid or self.get_search_space()
        if not search_space:
            raise ValueError(
                f"{self.model_name} did not provide a search space and no param_grid was passed."
            )

        if search_type == "grid":
            search = GridSearchCV(
                estimator=estimator,
                param_grid=search_space,
                scoring=scoring,
                cv=cv,
                n_jobs=n_jobs,
                verbose=verbose,
                refit=refit,
                return_train_score=return_train_score,
                **search_kwargs,
            )
        elif search_type == "random":
            search = RandomizedSearchCV(
                estimator=estimator,
                param_distributions=search_space,
                n_iter=n_iter,
                scoring=scoring,
                cv=cv,
                n_jobs=n_jobs,
                verbose=verbose,
                refit=refit,
                return_train_score=return_train_score,
                random_state=self.config.random_state,
                **search_kwargs,
            )
        else:
            raise ValueError("search_type must be either 'grid' or 'random'")

        search.fit(x_np, y_np)

        self.best_params_ = dict(search.best_params_)
        self.search_results_ = dict(search.cv_results_)
        self.best_model_ = search.best_estimator_ if refit else None
        self.model = self.best_model_ if refit else estimator
        self.is_fitted = refit

        return self

    def predict(self, x: Any) -> np.ndarray:
        model = self._active_model()
        if not self.is_fitted or model is None:
            raise RuntimeError(f"{self.model_name} has not been fitted yet.")
        x_np = self._to_numpy(x)
        raw_pred = model.predict(x_np)
        return self._inverse_transform_target(raw_pred)

    def predict_transformed(self, x: Any) -> np.ndarray:
        model = self._active_model()
        if not self.is_fitted or model is None:
            raise RuntimeError(f"{self.model_name} has not been fitted yet.")
        x_np = self._to_numpy(x)
        raw_pred = model.predict(x_np)
        return np.asarray(raw_pred, dtype=float).reshape(-1)

    def evaluate(self, x: Any, y_true: Any) -> Dict[str, float]:
        from scipy.stats import spearmanr
    
        y_true = np.asarray(y_true, dtype=float).reshape(-1)
        y_pred = self.predict(x)
    
        eps = self.config.target_epsilon
        q_errors = np.maximum((y_pred + eps) / (y_true + eps), (y_true + eps) / (y_pred + eps))
    
        spearman = spearmanr(y_true, y_pred).statistic
        if spearman is None or np.isnan(spearman):
            spearman = 0.0
    
        metrics: Dict[str, float] = {
            "mae": float(mean_absolute_error(y_true, y_pred)),
            "rmse": float(np.sqrt(mean_squared_error(y_true, y_pred))),
            "r2": float(r2_score(y_true, y_pred)),
            "spearman": float(spearman),
            "median_q_error": float(np.median(q_errors)),
            "p95_q_error": float(np.percentile(q_errors, 95)),
            "mean_q_error": float(np.mean(q_errors)),
            "gmean_q_error": float(np.exp(np.mean(np.log(q_errors + eps)))),
            "p90_q_error": float(np.percentile(q_errors, 90)),
            "max_q_error": float(np.max(q_errors)),
        }
    
        return metrics

    def tuning_results_df(self) -> pd.DataFrame:
        if self.search_results_ is None:
            raise RuntimeError(f"{self.model_name} has no stored search results.")
        return pd.DataFrame(self.search_results_)

    def save(self, path: str | Path) -> None:
        model = self._active_model()
        if not self.is_fitted or model is None:
            raise RuntimeError(f"{self.model_name} has not been fitted yet.")

        payload = {
            "model_name": self.model_name,
            "config": asdict(self.config),
            "model": self.model,
            "best_model_": self.best_model_,
            "best_params_": self.best_params_,
            "search_results_": self.search_results_,
            "is_fitted": self.is_fitted,
        }
        joblib.dump(payload, path)

    @classmethod
    def load(cls, path: str | Path) -> "BaseRuntimeRegressor":
        payload = joblib.load(path)
        config = RegressorConfig(**payload["config"])
        instance = cls(config=config)  # type: ignore[misc]
        instance.model = payload.get("model")
        instance.best_model_ = payload.get("best_model_")
        instance.best_params_ = payload.get("best_params_")
        instance.search_results_ = payload.get("search_results_")
        instance.is_fitted = payload["is_fitted"]
        return instance