"""MSCN runtime model over Trino plans (featurisation, SetConv model and datasets). Kipf et al., *Learned Cardinalities: Estimating Correlated Joins with Deep Learning*, CIDR 2019."""
import numpy as np
import torch
import torch.nn as nn
import torch.nn.functional as F
from torch.utils.data import dataset


# --------------------
# Featurisation utilities
# --------------------

def chunks(l, n):
    for i in range(0, len(l), n):
        yield l[i:i + n]


def idx_to_onehot(idx, num_elements):
    onehot = np.zeros(num_elements, dtype=np.float32)
    onehot[idx] = 1.0
    return onehot


def get_set_encoding(source_set, onehot=True, add_unknown=True):
    source_list = sorted(list(source_set))

    if add_unknown and "UNKNOWN" not in source_list:
        source_list.append("UNKNOWN")

    thing2idx = {s: i for i, s in enumerate(source_list)}
    idx2thing = [s for s in source_list]

    if onehot:
        thing2vec = {s: idx_to_onehot(i, len(source_list)) for i, s in enumerate(source_list)}
        return thing2vec, idx2thing

    return thing2idx, idx2thing


def safe_float(x, default=0.0):
    try:
        return float(x)
    except Exception:
        return default


def safe_len(x):
    if x is None:
        return 0.0
    try:
        return float(len(x))
    except Exception:
        return 0.0


def get_all_operator_names(plans):
    ops = set()
    for dag in plans:
        for node in dag["nodes"].values():
            ops.add(node.get("name", "UNKNOWN"))
    ops.add("UNKNOWN")
    return ops


def get_all_edge_types(plans):
    etypes = set()
    for dag in plans:
        for _, _, etype in dag["edges"]:
            etypes.add(str(etype))
    etypes.add("UNKNOWN")
    return etypes


def estimate_list_to_feature_vector(estimates):
    if not estimates:
        return np.zeros(6, dtype=np.float32)

    row_counts = []
    output_sizes = []
    cpu_costs = []
    mem_costs = []
    net_costs = []

    for est in estimates:
        if not isinstance(est, dict):
            continue
        row_counts.append(np.log1p(max(safe_float(est.get("outputRowCount", 0.0), 0.0), 0.0)))
        output_sizes.append(np.log1p(max(safe_float(est.get("outputSizeInBytes", 0.0), 0.0), 0.0)))
        cpu_costs.append(np.log1p(max(safe_float(est.get("cpuCost", 0.0), 0.0), 0.0)))
        mem_costs.append(np.log1p(max(safe_float(est.get("memoryCost", 0.0), 0.0), 0.0)))
        net_costs.append(np.log1p(max(safe_float(est.get("networkCost", 0.0), 0.0), 0.0)))

    def mean_or_zero(vals):
        vals = [v for v in vals if np.isfinite(v)]
        return float(np.mean(vals)) if vals else 0.0

    return np.array([
        float(len(estimates)),
        mean_or_zero(row_counts),
        mean_or_zero(output_sizes),
        mean_or_zero(cpu_costs),
        mean_or_zero(mem_costs),
        mean_or_zero(net_costs),
    ], dtype=np.float32)


def encode_plan_nodes_as_samples(dag, op2vec):
    out = []
    unk_vec = op2vec.get("UNKNOWN")
    if unk_vec is None:
        raise KeyError("op2vec must contain 'UNKNOWN'")

    for node_id, node in dag["nodes"].items():
        op_name = node.get("name", "UNKNOWN")
        op_vec = op2vec.get(op_name, unk_vec)
        frag_val = np.array([safe_float(node.get("fragment", 0.0), 0.0)], dtype=np.float32)
        outputs_len = np.array([safe_len(node.get("outputs", []))], dtype=np.float32)
        has_est = np.array([1.0 if node.get("estimates") else 0.0], dtype=np.float32)
        vec = np.hstack([op_vec, frag_val, outputs_len, has_est]).astype(np.float32)
        out.append(vec)
    return out


def encode_plan_nodes_as_predicates(dag, op2vec):
    out = []
    unk_vec = op2vec.get("UNKNOWN")
    if unk_vec is None:
        raise KeyError("op2vec must contain 'UNKNOWN'")

    child_counts = {}
    for node_id in dag["nodes"]:
        child_counts[node_id] = 0.0
    for src, dst, etype in dag["edges"]:
        if etype == "child":
            child_counts[src] += 1.0

    for node_id, node in dag["nodes"].items():
        op_name = node.get("name", "UNKNOWN")
        op_vec = op2vec.get(op_name, unk_vec)
        est_vec = estimate_list_to_feature_vector(node.get("estimates", []))
        descriptor_size = np.array([safe_len(node.get("descriptor", {}))], dtype=np.float32)
        child_count = np.array([child_counts[node_id]], dtype=np.float32)
        vec = np.hstack([op_vec, est_vec, descriptor_size, child_count]).astype(np.float32)
        out.append(vec)
    return out


def encode_plan_edges_as_joins(dag, edge2vec, op2vec):
    out = []

    unk_edge_vec = edge2vec.get("UNKNOWN")
    if unk_edge_vec is None:
        raise KeyError("edge2vec must contain 'UNKNOWN'")

    unk_op_vec = op2vec.get("UNKNOWN")
    if unk_op_vec is None:
        raise KeyError("op2vec must contain 'UNKNOWN'")

    nodes = dag["nodes"]
    for src, dst, etype in dag["edges"]:
        edge_vec = edge2vec.get(str(etype), unk_edge_vec)
        src_vec = op2vec.get(nodes[src].get("name", "UNKNOWN"), unk_op_vec)
        dst_vec = op2vec.get(nodes[dst].get("name", "UNKNOWN"), unk_op_vec)

        same_fragment = np.array([
            float(str(nodes[src].get("fragment", "")) == str(nodes[dst].get("fragment", "")))
        ], dtype=np.float32)

        vec = np.hstack([edge_vec, src_vec, dst_vec, same_fragment]).astype(np.float32)
        out.append(vec)
    return out


def normalize_labels(labels, min_val=None, max_val=None):
    labels = np.array([np.log(float(l)) for l in labels], dtype=np.float32)
    if min_val is None:
        min_val = float(labels.min())
    if max_val is None:
        max_val = float(labels.max())
    denom = max(max_val - min_val, 1e-12)
    labels_norm = (labels - min_val) / denom
    labels_norm = np.clip(labels_norm, 0.0, 1.0)
    return labels_norm.astype(np.float32), float(min_val), float(max_val)


def unnormalize_labels(labels_norm, min_val, max_val):
    labels_norm = np.asarray(labels_norm, dtype=np.float32)
    labels_norm = np.clip(labels_norm, 0.0, 1.0)
    labels_log = labels_norm * (max_val - min_val) + min_val
    labels_log = np.clip(labels_log, -50.0, 50.0)
    return np.exp(labels_log).astype(np.float32)


def standardize_labels(labels, mean=None, std=None):
    """Log-space z-score of the runtime labels: ``(log(y) - mean) / std``.

    Unlike ``normalize_labels`` this does not squash into ``[0, 1]`` and is not
    clipped, so the target range does not depend on the min/max of whatever
    subset it is fitted on. Pair with ``SetConv(bounded_output=False)`` and
    ``destandardize_labels`` for the inverse.
    """
    labels = np.array([np.log(float(l)) for l in labels], dtype=np.float32)
    if mean is None:
        mean = float(labels.mean())
    if std is None:
        std = float(labels.std())
    std = max(std, 1e-6)
    labels_std = (labels - mean) / std
    return labels_std.astype(np.float32), float(mean), float(std)


def destandardize_labels(labels_std, mean, std):
    labels_std = np.asarray(labels_std, dtype=np.float32)
    labels_log = labels_std * std + mean
    labels_log = np.clip(labels_log, -50.0, 50.0)
    return np.exp(labels_log).astype(np.float32)


# --------------------
# Model
# --------------------

# Define model architecture

class SetConv(nn.Module):
    def __init__(self, sample_feats, predicate_feats, join_feats, hid_units, *, bounded_output=False):
        super(SetConv, self).__init__()
        # bounded_output=False -> (default) linear head, unbounded prediction
        #                         (pair with standardize_labels / destandardize_labels)
        # bounded_output=True  -> sigmoid head, prediction confined to (0, 1)
        #                         (pair with normalize_labels / unnormalize_labels)
        self.bounded_output = bounded_output
        self.sample_mlp1 = nn.Linear(sample_feats, hid_units)
        self.sample_mlp2 = nn.Linear(hid_units, hid_units)
        self.predicate_mlp1 = nn.Linear(predicate_feats, hid_units)
        self.predicate_mlp2 = nn.Linear(hid_units, hid_units)
        self.join_mlp1 = nn.Linear(join_feats, hid_units)
        self.join_mlp2 = nn.Linear(hid_units, hid_units)
        self.out_mlp1 = nn.Linear(hid_units * 3, hid_units)
        self.out_mlp2 = nn.Linear(hid_units, 1)

    def forward(self, samples, predicates, joins, sample_mask, predicate_mask, join_mask):
        # samples has shape [batch_size x num_joins+1 x sample_feats]
        # predicates has shape [batch_size x num_predicates x predicate_feats]
        # joins has shape [batch_size x num_joins x join_feats]

        hid_sample = F.relu(self.sample_mlp1(samples))
        hid_sample = F.relu(self.sample_mlp2(hid_sample))
        hid_sample = hid_sample * sample_mask  # Mask
        hid_sample = torch.sum(hid_sample, dim=1, keepdim=False)
        sample_norm = sample_mask.sum(1, keepdim=False).clamp_min(1.0)
        hid_sample = hid_sample / sample_norm  # Calculate average only over non-masked parts

        hid_predicate = F.relu(self.predicate_mlp1(predicates))
        hid_predicate = F.relu(self.predicate_mlp2(hid_predicate))
        hid_predicate = hid_predicate * predicate_mask
        hid_predicate = torch.sum(hid_predicate, dim=1, keepdim=False)
        predicate_norm = predicate_mask.sum(1, keepdim=False).clamp_min(1.0)
        hid_predicate = hid_predicate / predicate_norm

        hid_join = F.relu(self.join_mlp1(joins))
        hid_join = F.relu(self.join_mlp2(hid_join))
        hid_join = hid_join * join_mask
        hid_join = torch.sum(hid_join, dim=1, keepdim=False)
        join_norm = join_mask.sum(1, keepdim=False).clamp_min(1.0)
        hid_join = hid_join / join_norm

        hid = torch.cat((hid_sample, hid_predicate, hid_join), 1)
        hid = F.relu(self.out_mlp1(hid))
        out = self.out_mlp2(hid)
        if self.bounded_output:
            out = torch.sigmoid(out)
        return out


# --------------------
# Datasets
# --------------------

def runtime_from_run_df(df, xcol="t_rel_s"):
    """
    Infer one run's runtime from the trace dataframe.

    Assumes xcol is relative time and the runtime is the maximum observed xcol.
    """
    return float(df[xcol].max())


def aggregate_query_runtime(run_dfs, xcol="t_rel_s", mode="mean"):
    """
    Aggregate multiple observed runtimes for the same query into one scalar target.
    """
    runtimes = [runtime_from_run_df(df, xcol=xcol) for df in run_dfs]
    if len(runtimes) == 0:
        raise ValueError("No runs available to aggregate runtime.")

    if mode == "mean":
        return float(np.mean(runtimes))
    if mode == "median":
        return float(np.median(runtimes))
    if mode == "min":
        return float(np.min(runtimes))
    if mode == "max":
        return float(np.max(runtimes))

    raise ValueError(f"Unknown runtime aggregation mode: {mode}")


def encode_queries_from_plans(
    plans_by_query,
    runs_by_query,
    qids,
    op2vec,
    edge2vec,
    *,
    xcol="t_rel_s",
    runtime_mode="mean",
):
    """
    Encode a set of query plans into MSCN-style sets:
      - samples     := node-level structural tokens
      - predicates  := node-level detail/statistical vectors
      - joins       := edge-level vectors
      - labels      := aggregated runtime targets
    """
    samples = []
    predicates = []
    joins = []
    labels = []

    kept_qids = []

    for qid in qids:
        if qid not in plans_by_query:
            continue
        if qid not in runs_by_query:
            continue

        dag = plans_by_query[qid]
        run_dfs = runs_by_query[qid]

        sample_enc = encode_plan_nodes_as_samples(dag, op2vec)
        predicate_enc = encode_plan_nodes_as_predicates(dag, op2vec)
        join_enc = encode_plan_edges_as_joins(dag, edge2vec, op2vec)

        # Guard against empty sets
        if len(sample_enc) == 0:
            continue
        if len(predicate_enc) == 0:
            continue
        if len(join_enc) == 0:
            # allow zero-edge plans by inserting one all-zero dummy vector
            join_dim = len(next(iter(edge2vec.values()))) + 2 * len(next(iter(op2vec.values()))) + 1
            join_enc = [np.zeros(join_dim, dtype=np.float32)]

        rt = aggregate_query_runtime(run_dfs, xcol=xcol, mode=runtime_mode)

        samples.append(sample_enc)
        predicates.append(predicate_enc)
        joins.append(join_enc)
        labels.append(rt)
        kept_qids.append(qid)

    return samples, predicates, joins, labels, kept_qids


def make_dataset(samples, predicates, joins, labels, max_num_samples, max_num_predicates, max_num_joins):
    """
    Add zero-padding and wrap as TensorDataset.

    Shapes:
      samples    : [batch, max_num_samples, sample_feat_dim]
      predicates : [batch, max_num_predicates, predicate_feat_dim]
      joins      : [batch, max_num_joins, join_feat_dim]
    """
    # ---------- samples ----------
    sample_masks = []
    sample_tensors = []
    for sample in samples:
        sample_tensor = np.vstack(sample).astype(np.float32)
        num_pad = max_num_samples - sample_tensor.shape[0]
        if num_pad < 0:
            raise ValueError("sample_tensor exceeds max_num_samples")

        sample_mask = np.ones((sample_tensor.shape[0], 1), dtype=np.float32)
        sample_tensor = np.pad(sample_tensor, ((0, num_pad), (0, 0)), "constant")
        sample_mask = np.pad(sample_mask, ((0, num_pad), (0, 0)), "constant")

        sample_tensors.append(np.expand_dims(sample_tensor, 0))
        sample_masks.append(np.expand_dims(sample_mask, 0))

    sample_tensors = torch.FloatTensor(np.vstack(sample_tensors))
    sample_masks = torch.FloatTensor(np.vstack(sample_masks))

    # ---------- predicates ----------
    predicate_masks = []
    predicate_tensors = []
    for predicate in predicates:
        predicate_tensor = np.vstack(predicate).astype(np.float32)
        num_pad = max_num_predicates - predicate_tensor.shape[0]
        if num_pad < 0:
            raise ValueError("predicate_tensor exceeds max_num_predicates")

        predicate_mask = np.ones((predicate_tensor.shape[0], 1), dtype=np.float32)
        predicate_tensor = np.pad(predicate_tensor, ((0, num_pad), (0, 0)), "constant")
        predicate_mask = np.pad(predicate_mask, ((0, num_pad), (0, 0)), "constant")

        predicate_tensors.append(np.expand_dims(predicate_tensor, 0))
        predicate_masks.append(np.expand_dims(predicate_mask, 0))

    predicate_tensors = torch.FloatTensor(np.vstack(predicate_tensors))
    predicate_masks = torch.FloatTensor(np.vstack(predicate_masks))

    # ---------- joins ----------
    join_masks = []
    join_tensors = []
    for join in joins:
        join_tensor = np.vstack(join).astype(np.float32)
        num_pad = max_num_joins - join_tensor.shape[0]
        if num_pad < 0:
            raise ValueError("join_tensor exceeds max_num_joins")

        join_mask = np.ones((join_tensor.shape[0], 1), dtype=np.float32)
        join_tensor = np.pad(join_tensor, ((0, num_pad), (0, 0)), "constant")
        join_mask = np.pad(join_mask, ((0, num_pad), (0, 0)), "constant")

        join_tensors.append(np.expand_dims(join_tensor, 0))
        join_masks.append(np.expand_dims(join_mask, 0))

    join_tensors = torch.FloatTensor(np.vstack(join_tensors))
    join_masks = torch.FloatTensor(np.vstack(join_masks))

    # ---------- labels ----------
    target_tensor = torch.FloatTensor(labels).reshape(-1, 1)

    return dataset.TensorDataset(
        sample_tensors,
        predicate_tensors,
        join_tensors,
        target_tensor,
        sample_masks,
        predicate_masks,
        join_masks,
    )


def get_train_test_datasets_from_trino(
    plans_by_query,
    runs_by_query,
    train_qids,
    test_qids,
    *,
    xcol="t_rel_s",
    runtime_mode="mean",
    vocab_qids=None,
    label_transform="log_zscore",
):
    """
    Build MSCN-style train/test TensorDatasets from Trino plans and run traces.

    `label_transform` selects how runtime labels are mapped to the training
    target: ``"log_zscore"`` (default; log then z-score, matches the default
    ``SetConv`` linear head) or ``"log_minmax"`` (log then min/max into
    ``[0, 1]``, matches ``SetConv(bounded_output=True)``'s sigmoid head).
    ``label_stats`` in the return tuple is ``(mean, std)`` or
    ``(min_val, max_val)`` accordingly.

    `vocab_qids`, if given, fits the operator/edge-type vocabulary (and hence
    the model's input feature dimensions) from this query set instead of
    `train_qids`. This is what makes pretrain-then-fine-tune transfer safe: a
    model pretrained on one training set and a model later fine-tuned on a
    different (e.g. much smaller) training set need identical input dims for
    `model.load_state_dict(...)` to work, which requires both stages to fit
    their vocabulary from the same (e.g. pooled/superset) query set rather
    than each stage's own, possibly narrower, train_qids.

    Returns
    -------
    dicts : list
        [op2vec, edge2vec]
    label_stats : tuple
        (min_val, max_val) used for label normalization
    labels_train_norm : np.ndarray
    labels_test_norm : np.ndarray
    max_num_samples : int
    max_num_predicates : int
    max_num_joins : int
    train_dataset : TensorDataset
    test_dataset : TensorDataset
    kept_train_qids : list[str]
    kept_test_qids : list[str]
    """
    vocab_source_qids = vocab_qids if vocab_qids is not None else train_qids
    vocab_plans = [plans_by_query[q] for q in vocab_source_qids if q in plans_by_query]

    # Fit vocabularies on vocab_plans (defaults to training plans only)
    operator_names = get_all_operator_names(vocab_plans)
    edge_types = get_all_edge_types(vocab_plans)

    op2vec, idx2op = get_set_encoding(operator_names)
    edge2vec, idx2edge = get_set_encoding(edge_types)

    # Encode train/test
    samples_train, predicates_train, joins_train, labels_train, kept_train_qids = encode_queries_from_plans(
        plans_by_query,
        runs_by_query,
        train_qids,
        op2vec,
        edge2vec,
        xcol=xcol,
        runtime_mode=runtime_mode,
    )

    samples_test, predicates_test, joins_test, labels_test, kept_test_qids = encode_queries_from_plans(
        plans_by_query,
        runs_by_query,
        test_qids,
        op2vec,
        edge2vec,
        xcol=xcol,
        runtime_mode=runtime_mode,
    )

    print(f"Number of training samples: {len(labels_train)}")
    print(f"Number of validation samples: {len(labels_test)}")

    if len(labels_train) == 0:
        raise ValueError("No training examples were encoded.")
    if len(labels_test) == 0:
        raise ValueError("No test examples were encoded.")

    # Transform labels using training stats only
    if label_transform == "log_minmax":
        labels_train_norm, stat_a, stat_b = normalize_labels(labels_train)
        labels_test_norm, _, _ = normalize_labels(labels_test, min_val=stat_a, max_val=stat_b)
    elif label_transform == "log_zscore":
        labels_train_norm, stat_a, stat_b = standardize_labels(labels_train)
        labels_test_norm, _, _ = standardize_labels(labels_test, mean=stat_a, std=stat_b)
    else:
        raise ValueError(
            f"Unknown label_transform {label_transform!r} (expected 'log_minmax' or 'log_zscore')"
        )

    # Padding sizes across both splits
    max_num_samples = max(
        max(len(s) for s in samples_train),
        max(len(s) for s in samples_test),
    )
    max_num_predicates = max(
        max(len(p) for p in predicates_train),
        max(len(p) for p in predicates_test),
    )
    max_num_joins = max(
        max(len(j) for j in joins_train),
        max(len(j) for j in joins_test),
    )

    train_dataset = make_dataset(
        samples_train,
        predicates_train,
        joins_train,
        labels_train_norm,
        max_num_samples=max_num_samples,
        max_num_predicates=max_num_predicates,
        max_num_joins=max_num_joins,
    )
    print("Created TensorDataset for training data")

    test_dataset = make_dataset(
        samples_test,
        predicates_test,
        joins_test,
        labels_test_norm,
        max_num_samples=max_num_samples,
        max_num_predicates=max_num_predicates,
        max_num_joins=max_num_joins,
    )
    print("Created TensorDataset for validation data")

    dicts = [op2vec, edge2vec]
    label_stats = (stat_a, stat_b)

    return (
        dicts,
        label_stats,
        labels_train_norm,
        labels_test_norm,
        max_num_samples,
        max_num_predicates,
        max_num_joins,
        train_dataset,
        test_dataset,
        kept_train_qids,
        kept_test_qids,
    )
