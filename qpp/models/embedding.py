from __future__ import annotations

from dataclasses import dataclass
from sklearn.preprocessing import StandardScaler
from typing import Any, Dict, Iterable, Protocol, runtime_checkable, Type, Tuple
import numpy as np
import pandas as pd


@runtime_checkable
class PlanEncoder(Protocol):
    @classmethod
    def fit_from_train_plans(cls, train_plans: Iterable[dict], **kwargs) -> "PlanEncoder":
        ...

    def encode_plan(self, dag: dict) -> np.ndarray:
        ...

    def dim(self) -> int:
        ...

@runtime_checkable
class QueryAwareContextEncoder(Protocol):
    @classmethod
    def fit_from_train_profiles(
        cls,
        *,
        profiles_by_run: Dict[str, pd.DataFrame],
        plans_by_query: Dict[str, Any],
        train_query_run_ids: Iterable[str],
        train_qids: Iterable[str],
        **kwargs,
    ) -> "QueryAwareContextEncoder":
        ...

    def encode_profile(
        self,
        profile_df: pd.DataFrame,
        plan: Dict[str, Any],
    ) -> np.ndarray:
        ...

    def dim(self) -> int:
        ...

def fit_plan_encoder(
    *,
    encoder_cls: Type,
    plans_by_query: Dict[str, Any],
    train_qids: Iterable[str],
    encoder_kwargs: Dict[str, Any] | None = None,
):
    """
    Fit a plan encoder on training plans only.
    """
    train_qids = list(train_qids)
    encoder_kwargs = {} if encoder_kwargs is None else dict(encoder_kwargs)

    enc = encoder_cls.fit_from_train_plans(
        train_plans=[plans_by_query[q] for q in train_qids],
        **encoder_kwargs,
    )
    return enc


def fit_context_encoder(
    *,
    encoder_cls: Type,
    profiles_train: Dict[str, pd.DataFrame],
    encoder_kwargs: Dict[str, Any] | None = None,
):
    """
    Fit a context encoder on training profile DataFrames only.

    profiles_train:
        query_run_id -> profile DataFrame
    """
    encoder_kwargs = {} if encoder_kwargs is None else dict(encoder_kwargs)

    enc = encoder_cls.fit_from_train_profiles(
        train_profiles=list(profiles_train.values()),
        **encoder_kwargs,
    )

    return enc
    

def encode_plans_by_query(
    *,
    encoder,
    plans_by_query: Dict[str, Any],
    qids: Iterable[str],
) -> Dict[str, np.ndarray]:
    """
    Encode a subset of plans with an already-fitted encoder.
    """
    return {q: encoder.encode_plan(plans_by_query[q]) for q in qids}

def _query_name_from_run_df(df) -> str | None:
    """
    Extract query_name from a run DataFrame.
    """
    query_name = getattr(df, "attrs", {}).get("query_name")

    if query_name is None and "query_name" in df.columns:
        vals = df["query_name"].dropna()
        if len(vals) > 0:
            query_name = str(vals.iloc[0])

    return None if query_name is None else str(query_name)

def _query_name_from_profile_df(df: pd.DataFrame) -> str | None:
    """
    Extract query_name from a profile DataFrame.
    """
    query_name = getattr(df, "attrs", {}).get("query_name")

    if query_name is None and "query_name" in df.columns:
        vals = df["query_name"].dropna()
        if len(vals) > 0:
            query_name = str(vals.iloc[0])

    return None if query_name is None else str(query_name)

def make_plan_embeddings_by_run(
    *,
    encoder_cls: Type,
    plans_by_query: Dict[str, Any],
    runs_train: Dict[str, Any],
    runs_test: Dict[str, Any],
    train_qids: Iterable[str],
    test_qids: Iterable[str],
    encoder_kwargs: Dict[str, Any] | None = None,
    Z_context_train: Dict[str, np.ndarray] | None = None,
    Z_context_test: Dict[str, np.ndarray] | None = None,
):
    """
    Fit a plan encoder on training query plans, then produce run-level embeddings.

    Input
    -----
    runs_train / runs_test:
        query_run_id -> pd.DataFrame

    Output
    ------
    Z_train / Z_test:
        query_run_id -> embedding

    If context embeddings are supplied, the final embedding is:
        concat(query_plan_embedding, context_embedding)

    Otherwise:
        query_plan_embedding only.
    """
    train_qids = list(train_qids)
    test_qids = list(test_qids)
    encoder_kwargs = {} if encoder_kwargs is None else dict(encoder_kwargs)

    enc = fit_plan_encoder(
        encoder_cls=encoder_cls,
        plans_by_query=plans_by_query,
        train_qids=train_qids,
        encoder_kwargs=encoder_kwargs,
    )

    # Encode each query once.
    Z_query: Dict[str, np.ndarray] = {}

    for q in sorted(set(train_qids) | set(test_qids)):
        if q not in plans_by_query:
            continue

        Z_query[q] = np.asarray(enc.encode_plan(plans_by_query[q]), dtype=float).reshape(-1)

    def build_split(
        runs_by_run: Dict[str, Any],
        Z_context: Dict[str, np.ndarray] | None = None,
    ) -> Dict[str, np.ndarray]:
        out: Dict[str, np.ndarray] = {}

        for query_run_id, df in runs_by_run.items():
            query_name = _query_name_from_run_df(df)

            if query_name is None:
                raise ValueError(
                    f"Missing query_name for run {query_run_id!r}. "
                    "Check that the loader attaches df.attrs['query_name']."
                )

            if query_name not in Z_query:
                continue

            z = Z_query[query_name]

            if Z_context is not None and query_run_id in Z_context:
                z_context = np.asarray(Z_context[query_run_id], dtype=float).reshape(-1)
                z = np.concatenate([z, z_context])

            out[str(query_run_id)] = z

        return out

    Z_train = build_split(runs_train, Z_context_train)
    Z_test = build_split(runs_test, Z_context_test)

    return Z_train, Z_test, enc

def make_context_embeddings_by_run(
    *,
    encoder_cls: Type,
    profiles_train: Dict[str, pd.DataFrame],
    profiles_test: Dict[str, pd.DataFrame],
    plans_by_query: Dict[str, Any],
    train_qids: Iterable[str],
    encoder_kwargs: Dict[str, Any] | None = None,
):
    """
    Fit a query-aware context encoder on training profiles and plans,
    then encode train/test profile contexts at query-run level.

    This is intended for context encoders whose features depend on both:
        - profile_df for the query_run_id
        - query plan for the corresponding query_name

    Input
    -----
    profiles_train / profiles_test:
        query_run_id -> profile DataFrame

    plans_by_query:
        query_name -> plan dictionary

    train_qids:
        query ids used to fit query-pressure statistics.

    Output
    ------
    Z_context_train / Z_context_test:
        query_run_id -> context embedding

    enc:
        fitted context encoder
    """
    encoder_kwargs = {} if encoder_kwargs is None else dict(encoder_kwargs)

    train_query_run_ids = list(profiles_train.keys())

    enc = encoder_cls.fit_from_train_profiles(
        profiles_by_run=profiles_train,
        plans_by_query=plans_by_query,
        train_query_run_ids=train_query_run_ids,
        train_qids=train_qids,
        **encoder_kwargs,
    )

    def build_split(
        profiles_by_run: Dict[str, pd.DataFrame],
    ) -> Dict[str, np.ndarray]:
        out: Dict[str, np.ndarray] = {}

        for query_run_id, df in profiles_by_run.items():
            query_run_id = str(query_run_id)

            query_name = _query_name_from_profile_df(df)

            if query_name is None:
                raise ValueError(
                    f"Missing query_name for profile run {query_run_id!r}. "
                    "Check that the loader attaches df.attrs['query_name'] "
                    "or a query_name column."
                )

            if query_name not in plans_by_query:
                continue

            z = enc.encode_profile(
                profile_df=df,
                plan=plans_by_query[query_name],
            )

            out[query_run_id] = np.asarray(z, dtype=float).reshape(-1)

        return out

    Z_context_train = build_split(profiles_train)
    Z_context_test = build_split(profiles_test)

    return Z_context_train, Z_context_test, enc

def make_plan_embeddings(
    *,
    encoder_cls: Type,
    plans_by_query: Dict[str, Any],
    train_qids: Iterable[str],
    test_qids: Iterable[str],
    encoder_kwargs: Dict[str, Any] | None = None,
):
    """
    Fit on training plans, then encode train/test plans.
    """
    train_qids = list(train_qids)
    test_qids = list(test_qids)

    enc = fit_plan_encoder(
        encoder_cls=encoder_cls,
        plans_by_query=plans_by_query,
        train_qids=train_qids,
        encoder_kwargs=encoder_kwargs,
    )

    Z_train = encode_plans_by_query(
        encoder=enc,
        plans_by_query=plans_by_query,
        qids=train_qids,
    )
    Z_test = encode_plans_by_query(
        encoder=enc,
        plans_by_query=plans_by_query,
        qids=test_qids,
    )

    return Z_train, Z_test, enc



def query_run_id_from_df(df: pd.DataFrame) -> str | None:
    qrid = getattr(df, "attrs", {}).get("query_run_id")

    if qrid is None and "query_run_id" in df.columns:
        vals = df["query_run_id"].dropna()
        if len(vals) > 0:
            qrid = str(vals.iloc[0])

    return None if qrid is None else str(qrid)


def flatten_runs_by_query_to_run_level(
    runs_by_query: Dict[str, list[pd.DataFrame]],
    *,
    require_query_run_id: bool = True,
) -> Dict[str, pd.DataFrame]:
    """
    Convert:
        runs_by_query[q] = [df_run1, df_run2, ...]

    into:
        runs_by_run[query_run_id] = df_run
    """
    out: Dict[str, pd.DataFrame] = {}

    for q, dfs in runs_by_query.items():
        for i, df in enumerate(dfs):
            qrid = query_run_id_from_df(df)

            if qrid is None:
                if require_query_run_id:
                    raise ValueError(
                        f"Missing query_run_id for query={q!r}, run index={i}"
                    )
                qrid = f"{q}@run{i}"

            out[qrid] = df

    return out


def _dict_to_matrix(
    Z: Dict[str, np.ndarray],
    *,
    ids: list[str],
) -> np.ndarray:
    return np.vstack([
        np.asarray(Z[k], dtype=float).reshape(1, -1)
        for k in ids
    ])


def _scale_embedding_dicts(
    Z_train: Dict[str, np.ndarray],
    Z_test: Dict[str, np.ndarray],
) -> tuple[Dict[str, np.ndarray], Dict[str, np.ndarray], StandardScaler]:
    """
    Fit scaler on train embeddings only, then transform train and test.
    """
    train_ids = list(Z_train.keys())
    test_ids = list(Z_test.keys())

    if not train_ids:
        raise ValueError("Z_train is empty.")

    X_train = _dict_to_matrix(Z_train, ids=train_ids)

    scaler = StandardScaler()
    X_train_scaled = scaler.fit_transform(X_train)

    Z_train_scaled = {
        k: X_train_scaled[i]
        for i, k in enumerate(train_ids)
    }

    if test_ids:
        X_test = _dict_to_matrix(Z_test, ids=test_ids)
        X_test_scaled = scaler.transform(X_test)

        Z_test_scaled = {
            k: X_test_scaled[i]
            for i, k in enumerate(test_ids)
        }
    else:
        Z_test_scaled = {}

    return Z_train_scaled, Z_test_scaled, scaler


@dataclass
class RunEmbeddingBundle:
    """
    Holds train/test run-level embeddings after optional separate scaling
    and optional fusion.

    This gives the existing model a normal Z_by_run dictionary while preserving
    enough metadata for two-branch heads to split the fused vector later.
    """

    Z_train: Dict[str, np.ndarray]
    Z_test: Dict[str, np.ndarray]

    Z_query_train: Dict[str, np.ndarray]
    Z_query_test: Dict[str, np.ndarray]

    Z_context_train: Optional[Dict[str, np.ndarray]] = None
    Z_context_test: Optional[Dict[str, np.ndarray]] = None

    query_scaler: Optional[StandardScaler] = None
    context_scaler: Optional[StandardScaler] = None

    mode: str = "concat"
    scaled: bool = False
    require_context: bool = False

    d_query: int = 0
    d_context: int = 0

    query_weight: float = 1.0
    context_weight: float = 1.0

    @property
    def d_total(self) -> int:
        return int(self.d_query + self.d_context)

    @property
    def has_context(self) -> bool:
        return self.d_context > 0

    @property
    def query_slice(self) -> tuple[int, int]:
        return (0, int(self.d_query))

    @property
    def context_slice(self) -> tuple[int, int]:
        return (int(self.d_query), int(self.d_query + self.d_context))

    @property
    def fusion_meta(self) -> dict:
        return {
            "fusion_mode": self.mode,
            "fusion_scaled": bool(self.scaled),
            "d_query": int(self.d_query),
            "d_context": int(self.d_context),
            "d_embed": int(self.d_total),
            "query_slice": self.query_slice,
            "context_slice": self.context_slice,
            "query_weight": float(self.query_weight),
            "context_weight": float(self.context_weight),
        }

    def split(self, z: np.ndarray) -> tuple[np.ndarray, Optional[np.ndarray]]:
        """
        Split a single fused vector into query/context parts.
        """
        z = np.asarray(z, dtype=float).reshape(-1)

        if z.shape[0] != self.d_total:
            raise ValueError(
                f"Embedding dimension mismatch: got {z.shape[0]}, "
                f"expected {self.d_total}"
            )

        qs = slice(*self.query_slice)
        cs = slice(*self.context_slice)

        z_q = z[qs]
        z_c = z[cs] if self.has_context else None

        return z_q, z_c

    def split_matrix(self, Z: np.ndarray) -> tuple[np.ndarray, Optional[np.ndarray]]:
        """
        Split a fused matrix into query/context matrices.
        """
        Z = np.asarray(Z, dtype=float)

        if Z.ndim != 2:
            raise ValueError(f"Expected a 2D matrix, got shape {Z.shape}")

        if Z.shape[1] != self.d_total:
            raise ValueError(
                f"Embedding dimension mismatch: got {Z.shape[1]}, "
                f"expected {self.d_total}"
            )

        qs = slice(*self.query_slice)
        cs = slice(*self.context_slice)

        Z_q = Z[:, qs]
        Z_c = Z[:, cs] if self.has_context else None

        return Z_q, Z_c

    @classmethod
    def from_train_test(
        cls,
        *,
        Z_query_train: Dict[str, np.ndarray],
        Z_query_test: Dict[str, np.ndarray],
        Z_context_train: Optional[Dict[str, np.ndarray]] = None,
        Z_context_test: Optional[Dict[str, np.ndarray]] = None,
        mode: str = "concat",
        scale: bool = True,
        require_context: bool = False,
        query_weight: float = 1.0,
        context_weight: float = 1.0,
    ) -> "RunEmbeddingBundle":
        """
        Build a train/test embedding bundle.

        Steps:
            1. Optionally scale query embeddings using train-only statistics.
            2. Optionally scale context embeddings using train-only statistics.
            3. Fuse query/context embeddings into Z_train and Z_test.
            4. Store scalers and split metadata.
        """
        if not Z_query_train:
            raise ValueError("Z_query_train is empty.")

        if Z_context_train is None:
            Z_context_train = None
            Z_context_test = None

        if Z_context_train is not None and Z_context_test is None:
            Z_context_test = {}

        query_scaler = None
        context_scaler = None

        # ------------------------------------------------------------
        # 1. Scale query space
        # ------------------------------------------------------------
        if scale:
            Z_query_train_work, Z_query_test_work, query_scaler = _scale_embedding_dicts(
                Z_query_train,
                Z_query_test,
            )
        else:
            Z_query_train_work = {
                str(k): np.asarray(v, dtype=float).reshape(-1)
                for k, v in Z_query_train.items()
            }
            Z_query_test_work = {
                str(k): np.asarray(v, dtype=float).reshape(-1)
                for k, v in Z_query_test.items()
            }

        # ------------------------------------------------------------
        # 2. Scale context space, separately
        # ------------------------------------------------------------
        if Z_context_train is not None:
            if scale:
                Z_context_train_work, Z_context_test_work, context_scaler = _scale_embedding_dicts(
                    Z_context_train,
                    Z_context_test or {},
                )
            else:
                Z_context_train_work = {
                    str(k): np.asarray(v, dtype=float).reshape(-1)
                    for k, v in Z_context_train.items()
                }
                Z_context_test_work = {
                    str(k): np.asarray(v, dtype=float).reshape(-1)
                    for k, v in (Z_context_test or {}).items()
                }
        else:
            Z_context_train_work = None
            Z_context_test_work = None

        # ------------------------------------------------------------
        # 3. Infer dimensions
        # ------------------------------------------------------------
        first_zq = next(iter(Z_query_train_work.values()))
        d_query = int(np.asarray(first_zq, dtype=float).reshape(-1).shape[0])

        if Z_context_train_work:
            first_zc = next(iter(Z_context_train_work.values()))
            d_context = int(np.asarray(first_zc, dtype=float).reshape(-1).shape[0])
        else:
            d_context = 0

        # ------------------------------------------------------------
        # 4. Fuse train/test
        # ------------------------------------------------------------
        Z_train = cls._fuse_dicts(
            Z_query_by_run=Z_query_train_work,
            Z_context_by_run=Z_context_train_work,
            mode=mode,
            require_context=require_context,
            query_weight=query_weight,
            context_weight=context_weight,
            d_query=d_query,
            d_context=d_context,
        )

        Z_test = cls._fuse_dicts(
            Z_query_by_run=Z_query_test_work,
            Z_context_by_run=Z_context_test_work,
            mode=mode,
            require_context=require_context,
            query_weight=query_weight,
            context_weight=context_weight,
            d_query=d_query,
            d_context=d_context,
        )

        return cls(
            Z_train=Z_train,
            Z_test=Z_test,
            Z_query_train=Z_query_train_work,
            Z_query_test=Z_query_test_work,
            Z_context_train=Z_context_train_work,
            Z_context_test=Z_context_test_work,
            query_scaler=query_scaler,
            context_scaler=context_scaler,
            mode=mode if d_context > 0 else "query_only",
            scaled=bool(scale),
            require_context=bool(require_context),
            d_query=d_query,
            d_context=d_context,
            query_weight=float(query_weight),
            context_weight=float(context_weight),
        )

    @staticmethod
    def _fuse_dicts(
        *,
        Z_query_by_run: Dict[str, np.ndarray],
        Z_context_by_run: Optional[Dict[str, np.ndarray]],
        mode: str,
        require_context: bool,
        query_weight: float,
        context_weight: float,
        d_query: int,
        d_context: int,
    ) -> Dict[str, np.ndarray]:
        out: Dict[str, np.ndarray] = {}

        for query_run_id, z_q in Z_query_by_run.items():
            query_run_id = str(query_run_id)
            z_q = np.asarray(z_q, dtype=float).reshape(-1)

            if z_q.shape[0] != d_query:
                raise ValueError(
                    f"Query embedding dimension mismatch for {query_run_id}: "
                    f"got {z_q.shape[0]}, expected {d_query}"
                )

            z_c = None
            if Z_context_by_run is not None:
                z_c = Z_context_by_run.get(query_run_id)

            if z_c is None:
                if require_context:
                    continue

                # Query-only case.
                # This is fine when d_context == 0.
                # For context experiments, prefer require_context=True.
                if d_context > 0:
                    raise ValueError(
                        f"Missing context for {query_run_id!r}. "
                        "Use require_context=True to skip incomplete runs, "
                        "or provide context for all runs."
                    )

                out[query_run_id] = float(query_weight) * z_q
                continue

            z_c = np.asarray(z_c, dtype=float).reshape(-1)

            if z_c.shape[0] != d_context:
                raise ValueError(
                    f"Context embedding dimension mismatch for {query_run_id}: "
                    f"got {z_c.shape[0]}, expected {d_context}"
                )

            if mode == "concat":
                out[query_run_id] = np.concatenate([
                    float(query_weight) * z_q,
                    float(context_weight) * z_c,
                ])
            else:
                raise ValueError(f"Unknown fusion mode: {mode!r}")

        return out

    @staticmethod
    def infer_embedding_dim(Z):
        if not Z:
            raise ValueError("Embedding dictionary is empty.")
    
        first_key = next(iter(Z))
        return np.asarray(Z[first_key], dtype=float).reshape(-1).shape[0]
    
    
    @classmethod
    def get_equal_context_weight(cls, q_embeddings, c_embeddings):
        query_dim = cls.infer_embedding_dim(q_embeddings)
        context_dim = cls.infer_embedding_dim(c_embeddings)
    
        return np.sqrt(query_dim / context_dim)