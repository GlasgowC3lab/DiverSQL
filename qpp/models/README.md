# QPP models

The six query performance prediction (QPP) model families evaluated in Section 7, plus the plan encoder, data splits and helpers they share. Five of the models are regressors over a 256-dimensional GIN plan embedding; MSCN instead reads the plan directly as sets of operators, per-node features and parent–child edges.

## Models

| File | Model | Source |
|---|---|---|
| `random_forest_regressor.py` | Random Forest | Breiman, *Random Forests*, Machine Learning 45(1), 2001. |
| `xgboost_regressor.py` | XGBoost | Chen & Guestrin, *XGBoost: A Scalable Tree Boosting System*, KDD 2016. |
| `lightgbm_regressor.py` | LightGBM | Ke et al., *LightGBM: A Highly Efficient Gradient Boosting Decision Tree*, NeurIPS 2017. |
| `mlp_regressor.py` | MLP | Dutt et al., *Selectivity Estimation for Range Predicates using Lightweight Models*, PVLDB 12(9), 2019. |
| `gp_rbf_regressor.py` | GP-RBF | Zhao et al., *Lightweight and Accurate Cardinality Estimation by Neural Network Gaussian Process*, SIGMOD 2022. |
| `mscn.py` | MSCN | Kipf et al., *Learned Cardinalities: Estimating Correlated Joins with Deep Learning*, CIDR 2019. |

## Supporting files

| File | Purpose |
|---|---|
| `trinoGraphQueryEncoder.py` | The self-supervised GIN plan encoder (Xu et al., ICLR 2019; Hu et al., ICLR 2020), along with plan-to-graph conversion and `canon_qid` for normalising query IDs. |
| `embedding.py` | Fits the plan encoder on the training plans only and returns scaled embeddings for each run. |
| `base_regressor.py` | `BaseRuntimeRegressor` and `RegressorConfig`, the shared fit, predict, hyperparameter-search and save interface for the five embedding regressors. |
| `optimise.py` | Train/test splits by query and by run, plus Q-error metrics and grid-search helpers. |
| `evaluate.py` | Evaluation metrics and the global mean-runtime baseline. |
| `model.py` | `durations_from_runs`, which extracts per-run runtimes, and the conditional runtime model it belongs to. |
| `targets.py` | Converts runtime traces into runtime and trace targets. |
| `heads_v1.py` | Prediction heads (runtime and trace) used by `model.py`. |
| `basis.py` | The fixed RBF time basis used to represent traces. |
| `shared_utils.py` | `set_seed` for reproducible runs. |
| `__init__.py` | Re-exports the encoder, splits, mean baseline and the five regressors. MSCN is imported from `qpp.models.mscn`. |
