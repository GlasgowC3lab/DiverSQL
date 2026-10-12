"""
Self-supervised GINE plan encoder with the SAME API surface as
TrinoGraphWLPlanEncoder / TrinoNumericPlanEncoder.

Why this exists
---------------
The WL encoder is a *fixed* graph kernel: it hashes Weisfeiler-Lehman subtree
patterns into a bag-of-labels vector. It is inductive and cheap, but (a) it is
untrained, so the representation cannot be shaped at all, and (b) it crushes the
numeric estimates to log10 order-of-magnitude buckets, discarding most of the
cardinality signal that drives cost.

This module keeps WL's two-stage, *frozen-embedding* contract (encode once ->
StandardScaler -> frozen Z -> your existing beta-NLL head) but replaces the fixed
hash with a small GINE (Graph Isomorphism Network with Edge features) that is
pre-trained *self-supervised on the training plans only*. No runtime targets are
used, so `fit_from_train_plans(train_plans)` has the identical signature to the
other encoders and drops straight into `fit_plan_encoder`.

GINE is the learnable generalisation of exactly what the WL encoder computes:
    h_v^(k) = MLP( (1 + eps) * h_v^(k-1)
                   + sum_{u in N(v)} ReLU( h_u^(k-1) + e_{type(u,v)} ) )
- sum aggregation is injective over multisets (matches WL's exact neighbour
  counting; mean/max would lose it),
- (1 + eps) keeps a node distinct from its neighbours,
- the edge embedding e_{type} carries child/remote + direction,
- the per-layer MLP is what makes it learnable rather than a fixed hash.

Self-supervised pretext (plans only)
------------------------------------
1. Masked node modelling: mask a fraction of nodes (operator -> [MASK], numerics
   zeroed) and reconstruct the operator (cross-entropy) and the numeric estimates
   (MSE). This is BERT-for-plan-DAGs and forces structure-aware node embeddings.
2. Graph-property regression: from the pooled graph readout, predict a handful of
   standardised structural statistics (node/edge counts, remote-edge ratio,
   longest path, aggregate row-count/size). This shapes the *graph-level* vector
   that we actually export.

The exported embedding is the concatenation of sum-pooled node states across all
layers (the classic GIN readout), optionally projected to `emb_dim`. Downstream
scaling is left to the existing pipeline's StandardScaler, exactly as for WL.
"""

from __future__ import annotations

import re
from dataclasses import dataclass, field
from typing import Any, Dict, Iterable, List, Optional, Tuple

import numpy as np
import networkx as nx
import torch
import torch.nn as nn
import torch.nn.functional as F

__all__ = ["TrinoGraphGINPlanEncoder", "trino_dag_dict_to_nx", "canon_qid", "NUM_KEYS"]


NUM_KEYS = ("outputRowCount", "outputSizeInBytes", "cpuCost", "memoryCost", "networkCost")


def trino_dag_dict_to_nx(dag: dict) -> nx.DiGraph:
    """
    Convert your plan dict DAG into a NetworkX DiGraph.

    Node attributes:
      - op (operator name)
      - fragment
      - numeric estimates if present: outputRowCount, outputSizeInBytes,
        cpuCost, memoryCost, networkCost

    Edge attributes:
      - etype ("child" or "remote")
    """
    G = nx.DiGraph()

    nodes = dag.get("nodes", {}) or {}

    def _num(x: Any) -> float:
        try:
            v = float(x)
            return float(v) if np.isfinite(v) else float("nan")
        except Exception:
            return float("nan")

    for nid, nd in nodes.items():
        op = (nd or {}).get("name", "UNK")
        frag = (nd or {}).get("fragment", None)

        est = (nd or {}).get("estimates") or []
        est0 = est[0] if est else {}

        G.add_node(
            nid,
            op=op,
            fragment=frag,
            outputRowCount=_num(est0.get("outputRowCount", np.nan)),
            outputSizeInBytes=_num(est0.get("outputSizeInBytes", np.nan)),
            cpuCost=_num(est0.get("cpuCost", np.nan)),
            memoryCost=_num(est0.get("memoryCost", np.nan)),
            networkCost=_num(est0.get("networkCost", np.nan)),
        )

    for src, dst, etype in dag.get("edges", []) or []:
        if src in nodes and dst in nodes:
            G.add_edge(src, dst, etype=etype)

    return G


def canon_qid(qid: Optional[str]) -> str:
    """Canonicalise a query id to its bare 'qN' form (e.g. 'q2_001' -> 'q2')."""
    if qid is None:
        raise ValueError("qid is None")
    m = re.search(r"q\d+", str(qid))
    if m is None:
        raise ValueError(f"Could not canonicalise qid={qid!r}")
    return m.group(0)


# Edge type vocabulary: base type ("child"/"remote") x direction (fwd/rev).
_EDGE_TYPES = {"child_fwd": 0, "child_rev": 1, "remote_fwd": 2, "remote_rev": 3}
_N_EDGE_TYPES = len(_EDGE_TYPES)

_N_NUM = len(NUM_KEYS)
_N_PROPS = 7  # see _graph_props


# -----------------------
# Feature extraction (numpy / networkx side)
# -----------------------

def _log1p_safe(x: float) -> float:
    if not np.isfinite(x) or x < 0:
        return np.nan
    return float(np.log1p(x))


def _node_numeric_log1p(G: nx.DiGraph, n: Any) -> np.ndarray:
    """log1p of the NUM_KEYS for one node; NaN where missing/invalid."""
    d = G.nodes[n]
    return np.asarray([_log1p_safe(float(d.get(k, np.nan))) for k in NUM_KEYS], dtype=float)


def _graph_props(G: nx.DiGraph) -> np.ndarray:
    """
    Cheap, self-supervised graph-level targets (all derivable from the plan).
    Kept aligned with trino_graph_structural_features for interpretability.
    """
    n_nodes = G.number_of_nodes()
    n_edges = G.number_of_edges()

    remote = sum(1 for _, _, d in G.edges(data=True) if d.get("etype") == "remote")

    try:
        longest = float(len(nx.dag_longest_path(G))) if n_nodes else 0.0
    except Exception:
        longest = 0.0

    rows = np.asarray(
        [_log1p_safe(float(d.get("outputRowCount", np.nan))) for _, d in G.nodes(data=True)],
        dtype=float,
    )
    size = np.asarray(
        [_log1p_safe(float(d.get("outputSizeInBytes", np.nan))) for _, d in G.nodes(data=True)],
        dtype=float,
    )
    rows_f = rows[np.isfinite(rows)]
    size_f = size[np.isfinite(size)]

    return np.asarray(
        [
            float(np.log1p(n_nodes)),
            float(np.log1p(n_edges)),
            float(remote) / float(max(n_edges, 1)),
            longest,
            float(np.sum(rows_f)) if rows_f.size else 0.0,
            float(np.max(rows_f)) if rows_f.size else 0.0,
            float(np.mean(size_f)) if size_f.size else 0.0,
        ],
        dtype=float,
    )


# -----------------------
# GINE network (torch side)
# -----------------------

class _GINEConv(nn.Module):
    """
    One GINE layer:
        out_v = MLP( (1 + eps) * h_v + sum_u ReLU(h_u + e_{type(u,v)}) )
    with a learnable eps (train_eps=True in the GIN paper).
    """

    def __init__(self, hidden: int, dropout: float):
        super().__init__()
        self.eps = nn.Parameter(torch.zeros(1))
        self.mlp = nn.Sequential(
            nn.Linear(hidden, hidden),
            nn.ReLU(),
            nn.Dropout(dropout),
            nn.Linear(hidden, hidden),
        )

    def forward(
        self,
        h: torch.Tensor,           # [N, H]
        edge_index: torch.Tensor,  # [2, E] (src -> dst)
        edge_emb: torch.Tensor,    # [E, H]
    ) -> torch.Tensor:
        n, hdim = h.shape
        if edge_index.numel() > 0:
            src = edge_index[0]
            dst = edge_index[1]
            msg = F.relu(h.index_select(0, src) + edge_emb)      # [E, H]
            agg = h.new_zeros((n, hdim)).index_add_(0, dst, msg)  # [N, H]
        else:
            agg = h.new_zeros((n, hdim))
        return self.mlp((1.0 + self.eps) * h + agg)


class _GINEncoderNet(nn.Module):
    """Featuriser + stacked GINE layers + multi-layer sum-pool readout."""

    def __init__(
        self,
        *,
        vocab_size: int,   # number of real operator classes (incl. UNK), excl. MASK
        hidden: int,
        n_layers: int,
        dropout: float,
        out_dim: Optional[int],
    ):
        super().__init__()
        self.vocab_size = vocab_size
        self.mask_id = vocab_size            # last embedding row is the [MASK] token
        self.hidden = hidden
        self.n_layers = n_layers

        self.op_emb = nn.Embedding(vocab_size + 1, hidden)
        # concat(op_emb[hidden], num[_N_NUM], num_mask[_N_NUM]) -> hidden
        self.input_proj = nn.Sequential(
            nn.Linear(hidden + 2 * _N_NUM, hidden),
            nn.LayerNorm(hidden),
            nn.ReLU(),
            nn.Dropout(dropout),
        )
        self.edge_emb = nn.Embedding(_N_EDGE_TYPES, hidden)

        self.convs = nn.ModuleList([_GINEConv(hidden, dropout) for _ in range(n_layers)])
        self.norms = nn.ModuleList([nn.LayerNorm(hidden) for _ in range(n_layers)])
        self.dropout = nn.Dropout(dropout)

        readout_dim = (n_layers + 1) * hidden
        self.out_dim = int(out_dim) if out_dim is not None else int(readout_dim)
        self.proj = nn.Linear(readout_dim, out_dim) if out_dim is not None else None

    def node_embeddings(
        self,
        op_idx: torch.Tensor,     # [N] long
        num: torch.Tensor,        # [N, _N_NUM]
        num_mask: torch.Tensor,   # [N, _N_NUM]
        edge_index: torch.Tensor, # [2, E]
        edge_type: torch.Tensor,  # [E] long
    ) -> List[torch.Tensor]:
        h = self.input_proj(torch.cat([self.op_emb(op_idx), num, num_mask], dim=-1))
        edge_emb = self.edge_emb(edge_type) if edge_type.numel() > 0 else edge_type.new_zeros((0, self.hidden), dtype=h.dtype)

        hs = [h]
        for conv, norm in zip(self.convs, self.norms):
            h = conv(h, edge_index, edge_emb)
            h = self.dropout(F.relu(norm(h)))
            hs.append(h)
        return hs  # length n_layers + 1

    def readout(self, hs: List[torch.Tensor], batch: torch.Tensor, num_graphs: int) -> torch.Tensor:
        pooled = [_global_sum_pool(h, batch, num_graphs) for h in hs]
        g = torch.cat(pooled, dim=-1)               # [B, (L+1)*H]
        if self.proj is not None:
            g = self.proj(g)                        # [B, out_dim]
        return g


def _global_sum_pool(h: torch.Tensor, batch: torch.Tensor, num_graphs: int) -> torch.Tensor:
    out = h.new_zeros((num_graphs, h.shape[-1]))
    return out.index_add_(0, batch, h)


# -----------------------
# Encoder (public, API-compatible dataclass)
# -----------------------

@dataclass
class TrinoGraphGINPlanEncoder:
    """
    Self-supervised GINE plan encoder.

    API parity with TrinoGraphWLPlanEncoder:
      - fit_from_train_plans(train_plans, ...) -> TrinoGraphGINPlanEncoder
      - encode_plan(dag) -> np.ndarray            (frozen, unscaled)
      - dim() -> int

    Hyper-parameters may be passed through `encoder_kwargs` in your existing
    `fit_plan_encoder` / `make_plan_embeddings_by_run` helpers.
    """
    # architecture
    hidden: int = 128
    n_layers: int = 3
    emb_dim: Optional[int] = None      # None -> readout dim = (n_layers+1)*hidden
    dropout: float = 0.1

    # self-supervised training
    mask_rate: float = 0.15
    epochs: int = 200
    batch_size: int = 32
    lr: float = 1e-3
    weight_decay: float = 1e-4
    clip_grad: float = 5.0
    w_num: float = 1.0                 # weight on masked-numeric reconstruction
    w_graph: float = 1.0              # weight on graph-property regression

    # vocab / misc
    min_op_freq: int = 1
    max_vocab: Optional[int] = None
    fixed_vocab: Optional[Tuple[str, ...]] = None
    seed: int = 0
    device: str = "cpu"
    verbose: bool = False

    # ---- fitted state (populated by fit) ----
    _net: Optional[_GINEncoderNet] = field(default=None, repr=False)
    _op2idx: Optional[Dict[str, int]] = field(default=None, repr=False)
    _num_mean: Optional[np.ndarray] = field(default=None, repr=False)
    _num_std: Optional[np.ndarray] = field(default=None, repr=False)
    _prop_mean: Optional[np.ndarray] = field(default=None, repr=False)
    _prop_std: Optional[np.ndarray] = field(default=None, repr=False)
    _out_dim: Optional[int] = field(default=None, repr=False)

    # ------------------------------------------------------------------
    # public API
    # ------------------------------------------------------------------
    @classmethod
    def fit_from_train_plans(
        cls,
        train_plans: Iterable[dict],
        *,
        hidden: int = 128,
        n_layers: int = 3,
        emb_dim: Optional[int] = None,
        dropout: float = 0.1,
        mask_rate: float = 0.15,
        epochs: int = 200,
        batch_size: int = 32,
        lr: float = 1e-3,
        weight_decay: float = 1e-4,
        clip_grad: float = 5.0,
        w_num: float = 1.0,
        w_graph: float = 1.0,
        min_op_freq: int = 1,
        max_vocab: Optional[int] = None,
        fixed_vocab: Optional[Iterable[str]] = None,
        seed: int = 0,
        device: str = "cpu",
        verbose: bool = False,
        # compatibility kwargs (ignored; mirror the other encoders' signatures)
        include_edge_types: Optional[bool] = None,
        direction: Optional[str] = None,
        use_fragment: Optional[bool] = None,
        use_estimates: Optional[bool] = None,
        use_cost_estimates: Optional[bool] = None,
        standardise: Optional[bool] = None,
        include_unk: Optional[bool] = None,
        include_global: Optional[bool] = None,
        include_counts: Optional[bool] = None,
        **_ignored_kwargs,
    ) -> "TrinoGraphGINPlanEncoder":
        self = cls(
            hidden=hidden,
            n_layers=n_layers,
            emb_dim=emb_dim,
            dropout=dropout,
            mask_rate=mask_rate,
            epochs=epochs,
            batch_size=batch_size,
            lr=lr,
            weight_decay=weight_decay,
            clip_grad=clip_grad,
            w_num=w_num,
            w_graph=w_graph,
            min_op_freq=min_op_freq,
            max_vocab=max_vocab,
            fixed_vocab=tuple(fixed_vocab) if fixed_vocab is not None else None,
            seed=seed,
            device=device,
            verbose=verbose,
        )
        self._fit(list(train_plans))
        return self

    def encode_plan(self, dag: dict) -> np.ndarray:
        """Frozen, unscaled (dim,) embedding for one plan."""
        if self._net is None:
            raise RuntimeError(
                "TrinoGraphGINPlanEncoder.encode_plan called before fit_from_train_plans()."
            )
        G = trino_dag_dict_to_nx(dag)
        if G.number_of_nodes() == 0:
            return np.zeros((self.dim(),), dtype=float)

        feat = self._featurise(G)
        batch = self._collate([feat])

        self._net.eval()
        with torch.no_grad():
            hs = self._net.node_embeddings(
                batch["op_idx"], batch["num"], batch["num_mask"],
                batch["edge_index"], batch["edge_type"],
            )
            g = self._net.readout(hs, batch["batch"], num_graphs=1)
        return g.squeeze(0).cpu().numpy().astype(float)

    def encode_plans(self, dags: Iterable[dict]) -> np.ndarray:
        """Batched convenience encoder; returns (n, dim)."""
        return np.vstack([self.encode_plan(d) for d in dags]) if dags else np.zeros((0, self.dim()))

    def dim(self) -> int:
        if self._out_dim is not None:
            return int(self._out_dim)
        return int(self.emb_dim) if self.emb_dim is not None else int((self.n_layers + 1) * self.hidden)

    # ------------------------------------------------------------------
    # persistence (handy for the frozen two-stage pipeline)
    # ------------------------------------------------------------------
    def save(self, path: str) -> None:
        if self._net is None:
            raise RuntimeError("Nothing to save: encoder is not fitted.")
        torch.save(
            {
                "config": {
                    "hidden": self.hidden, "n_layers": self.n_layers,
                    "emb_dim": self.emb_dim, "dropout": self.dropout,
                },
                "state_dict": self._net.state_dict(),
                "op2idx": self._op2idx,
                "num_mean": self._num_mean, "num_std": self._num_std,
                "prop_mean": self._prop_mean, "prop_std": self._prop_std,
                "out_dim": self._out_dim,
            },
            path,
        )

    @classmethod
    def load(cls, path: str, *, device: str = "cpu") -> "TrinoGraphGINPlanEncoder":
        # weights_only=False: checkpoint holds the op vocab dict + numpy stats,
        # not just tensors. Only load encoders you trust.
        blob = torch.load(path, map_location=device, weights_only=False)
        cfg = blob["config"]
        self = cls(hidden=cfg["hidden"], n_layers=cfg["n_layers"],
                   emb_dim=cfg["emb_dim"], dropout=cfg["dropout"], device=device)
        self._op2idx = blob["op2idx"]
        self._num_mean = blob["num_mean"]; self._num_std = blob["num_std"]
        self._prop_mean = blob["prop_mean"]; self._prop_std = blob["prop_std"]
        self._out_dim = blob["out_dim"]
        net = _GINEncoderNet(
            vocab_size=len(self._op2idx), hidden=self.hidden, n_layers=self.n_layers,
            dropout=self.dropout, out_dim=self.emb_dim,
        ).to(device)
        net.load_state_dict(blob["state_dict"])
        net.eval()
        self._net = net
        return self

    # ------------------------------------------------------------------
    # internals
    # ------------------------------------------------------------------
    def _build_vocab(self, graphs: List[nx.DiGraph]) -> Dict[str, int]:
        if self.fixed_vocab is not None:
            # Closed-world vocabulary supplied by the caller (e.g. the schema's
            # full reachable-operator set), used verbatim instead of whatever
            # this particular fit's plans happen to contain. Without this, a
            # leg whose training plans simply never trigger some valid, real
            # operator (a rare join/set-op type, say) would silently fold that
            # operator into the single shared [MASK]/UNK-style embedding row
            # the moment it *is* seen in another leg's held-out queries --
            # collapsing exactly the structural signal this evaluation is
            # trying to measure. min_op_freq/max_vocab are both frequency-based
            # and can't help with "never observed in this fit's plans at all",
            # so this is a separate knob, not a replacement for them.
            vocab = sorted({str(op) for op in self.fixed_vocab})
            if "UNK" not in vocab:
                vocab.append("UNK")
            return {op: i for i, op in enumerate(vocab)}

        from collections import Counter
        c: Counter = Counter()
        for G in graphs:
            for _, d in G.nodes(data=True):
                c[str(d.get("op", "UNK"))] += 1
        items = [(op, n) for op, n in c.items() if n >= int(self.min_op_freq)]
        items.sort(key=lambda x: (-x[1], x[0]))
        if self.max_vocab is not None:
            items = items[: int(self.max_vocab)]
        vocab = [op for op, _ in items]
        if "UNK" not in vocab:
            vocab.append("UNK")
        return {op: i for i, op in enumerate(vocab)}

    def _fit_stats(self, graphs: List[nx.DiGraph]) -> None:
        num_rows: List[np.ndarray] = []
        prop_rows: List[np.ndarray] = []
        for G in graphs:
            for n in G.nodes():
                num_rows.append(_node_numeric_log1p(G, n))
            prop_rows.append(_graph_props(G))

        N = np.asarray(num_rows, dtype=float) if num_rows else np.zeros((1, _N_NUM))
        with np.errstate(invalid="ignore"):
            num_mean = np.nanmean(N, axis=0)
            num_std = np.nanstd(N, axis=0)
        num_mean = np.where(np.isfinite(num_mean), num_mean, 0.0)
        num_std = np.where(np.isfinite(num_std) & (num_std > 1e-8), num_std, 1.0)

        P = np.asarray(prop_rows, dtype=float) if prop_rows else np.zeros((1, _N_PROPS))
        prop_mean = P.mean(axis=0)
        prop_std = P.std(axis=0)
        prop_std = np.where(prop_std > 1e-8, prop_std, 1.0)

        self._num_mean, self._num_std = num_mean, num_std
        self._prop_mean, self._prop_std = prop_mean, prop_std

    def _featurise(self, G: nx.DiGraph) -> Dict[str, np.ndarray]:
        """One graph -> numpy feature arrays (standardised)."""
        node_list = list(G.nodes())
        idx_of = {n: i for i, n in enumerate(node_list)}
        n = len(node_list)

        op_idx = np.empty((n,), dtype=np.int64)
        num = np.zeros((n, _N_NUM), dtype=np.float32)
        num_mask = np.zeros((n, _N_NUM), dtype=np.float32)

        unk = self._op2idx.get("UNK", len(self._op2idx) - 1)
        for i, node in enumerate(node_list):
            op = str(G.nodes[node].get("op", "UNK"))
            op_idx[i] = self._op2idx.get(op, unk)

            raw = _node_numeric_log1p(G, node)
            finite = np.isfinite(raw)
            std = (raw - self._num_mean) / self._num_std
            num[i] = np.where(finite, std, 0.0).astype(np.float32)
            num_mask[i] = finite.astype(np.float32)

        # bidirectional edges with typed/directed embeddings
        src: List[int] = []
        dst: List[int] = []
        etype: List[int] = []
        for u, v, d in G.edges(data=True):
            base = "remote" if d.get("etype") == "remote" else "child"
            iu, iv = idx_of[u], idx_of[v]
            src.append(iu); dst.append(iv); etype.append(_EDGE_TYPES[f"{base}_fwd"])
            src.append(iv); dst.append(iu); etype.append(_EDGE_TYPES[f"{base}_rev"])

        edge_index = np.asarray([src, dst], dtype=np.int64) if src else np.zeros((2, 0), dtype=np.int64)
        edge_type = np.asarray(etype, dtype=np.int64) if etype else np.zeros((0,), dtype=np.int64)

        props = ((_graph_props(G) - self._prop_mean) / self._prop_std).astype(np.float32)

        return {
            "op_idx": op_idx, "num": num, "num_mask": num_mask,
            "edge_index": edge_index, "edge_type": edge_type,
            "props": props, "n_nodes": np.int64(n),
        }

    def _collate(self, feats: List[Dict[str, np.ndarray]]) -> Dict[str, torch.Tensor]:
        dev = torch.device(self.device)
        op_idx, num, num_mask, batch = [], [], [], []
        ei_src, ei_dst, etype = [], [], []
        props = []
        offset = 0
        for gi, f in enumerate(feats):
            n = int(f["n_nodes"])
            op_idx.append(f["op_idx"]); num.append(f["num"]); num_mask.append(f["num_mask"])
            batch.append(np.full((n,), gi, dtype=np.int64))
            if f["edge_index"].shape[1] > 0:
                ei_src.append(f["edge_index"][0] + offset)
                ei_dst.append(f["edge_index"][1] + offset)
                etype.append(f["edge_type"])
            props.append(f["props"])
            offset += n

        def cat(xs, empty_shape, dtype):
            return np.concatenate(xs) if xs else np.zeros(empty_shape, dtype=dtype)

        edge_index = np.vstack([cat(ei_src, (0,), np.int64), cat(ei_dst, (0,), np.int64)])
        return {
            "op_idx": torch.as_tensor(np.concatenate(op_idx), device=dev),
            "num": torch.as_tensor(np.concatenate(num), device=dev),
            "num_mask": torch.as_tensor(np.concatenate(num_mask), device=dev),
            "edge_index": torch.as_tensor(edge_index, device=dev),
            "edge_type": torch.as_tensor(cat(etype, (0,), np.int64), device=dev),
            "batch": torch.as_tensor(np.concatenate(batch), device=dev),
            "props": torch.as_tensor(np.vstack(props), device=dev),
        }

    def _fit(self, train_plans: List[dict]) -> None:
        torch.manual_seed(int(self.seed))
        np.random.seed(int(self.seed))

        graphs = [trino_dag_dict_to_nx(p) for p in train_plans]
        graphs = [G for G in graphs if G.number_of_nodes() > 0]
        if len(graphs) < 2:
            raise ValueError("Need at least 2 non-empty training plans to fit the GIN encoder.")

        self._op2idx = self._build_vocab(graphs)
        self._fit_stats(graphs)

        feats = [self._featurise(G) for G in graphs]

        dev = torch.device(self.device)
        net = _GINEncoderNet(
            vocab_size=len(self._op2idx), hidden=self.hidden, n_layers=self.n_layers,
            dropout=self.dropout, out_dim=self.emb_dim,
        ).to(dev)
        self._net = net
        self._out_dim = net.out_dim

        op_head = nn.Linear(self.hidden, len(self._op2idx)).to(dev)
        num_head = nn.Linear(self.hidden, _N_NUM).to(dev)
        graph_head = nn.Sequential(
            nn.Linear(net.out_dim, self.hidden), nn.ReLU(), nn.Linear(self.hidden, _N_PROPS)
        ).to(dev)

        params = (
            list(net.parameters()) + list(op_head.parameters())
            + list(num_head.parameters()) + list(graph_head.parameters())
        )
        opt = torch.optim.AdamW(params, lr=float(self.lr), weight_decay=float(self.weight_decay))

        n = len(feats)
        idx = np.arange(n)
        gen = torch.Generator(device="cpu").manual_seed(int(self.seed))

        net.train(); op_head.train(); num_head.train(); graph_head.train()
        for ep in range(int(self.epochs)):
            np.random.shuffle(idx)
            ep_loss = 0.0
            for start in range(0, n, int(self.batch_size)):
                sel = idx[start:start + int(self.batch_size)]
                batch = self._collate([feats[i] for i in sel])

                op_idx = batch["op_idx"]; num = batch["num"]; num_mask = batch["num_mask"]
                N = op_idx.shape[0]

                # choose masked nodes (guarantee at least one)
                masked = torch.rand(N, generator=gen).to(dev) < float(self.mask_rate)
                if not bool(masked.any()):
                    masked[torch.randint(0, N, (1,), generator=gen).item()] = True

                op_in = torch.where(masked, torch.full_like(op_idx, net.mask_id), op_idx)
                keep = (~masked).float().unsqueeze(-1)
                num_in = num * keep
                num_mask_in = num_mask * keep

                hs = net.node_embeddings(op_in, num_in, num_mask_in, batch["edge_index"], batch["edge_type"])
                h_last = hs[-1]
                g = net.readout(hs, batch["batch"], num_graphs=len(sel))

                # (1) masked operator classification
                loss_op = F.cross_entropy(op_head(h_last)[masked], op_idx[masked])

                # (2) masked numeric reconstruction (only masked & originally-observed cells)
                num_pred = num_head(h_last)
                valid = (masked.unsqueeze(-1) & (num_mask > 0.5))
                if bool(valid.any()):
                    loss_num = F.mse_loss(num_pred[valid], num[valid])
                else:
                    loss_num = h_last.new_zeros(())

                # (3) graph-property regression
                loss_graph = F.mse_loss(graph_head(g), batch["props"])

                loss = loss_op + float(self.w_num) * loss_num + float(self.w_graph) * loss_graph

                opt.zero_grad()
                loss.backward()
                torch.nn.utils.clip_grad_norm_(params, max_norm=float(self.clip_grad))
                opt.step()
                ep_loss += float(loss.item()) * len(sel)

            if self.verbose and (ep % max(1, self.epochs // 10) == 0 or ep == self.epochs - 1):
                print(f"[GIN pretext] epoch {ep:4d}  loss={ep_loss / n:.4f}")

        net.eval()
