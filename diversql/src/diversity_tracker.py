"""
diversity_tracker -- memory of everything generated so far.

  SCHEMA usage    table_usage / edge_usage / column_usage
                  -> read by sampling.py to bias draws toward under-used elements.

  STRUCTURAL      seen_plan / plan_families    (plan-graph dedup + family cap)
                  operator_usage               (op document-frequency; the deficit
                                                signal feedback.py steers on)
                  ngram_usage / discovery      (Vendi-aligned child-path 3-grams)
                  hint_fires / hint_hits       (per-lever realised efficacy)
                  _hint_aggression             (plateau pressure level)

"""

import math
import re
import threading
from collections import Counter

from . import config
from .operator_space import structural_operators, lever_index


# ---- acceptance-key helpers (used by sampling.py and pipeline.py) ----
def _edge_key(a: str, b: str) -> tuple[str, str]:
    return (a, b) if a <= b else (b, a)


def _dedup_key(sql: str) -> str:
    return re.sub(r"\s+", " ", sql.strip().lower())


def _skeleton_key(sql: str):
    """Coarse structural skeleton via the evaluation's own feature extractor, so
    the "shape" the generator diversifies matches what the metrics measure."""
    from diversql.shared.sql_features import query_features
    f = query_features(sql)

    def n(key):
        return int(f.get(key, 0) or 0)

    return (
        min(n("num_tables"), 6), min(n("num_joins"), 6),
        n("num_group_by") > 0, n("num_order_by") > 0,
        min(n("num_subqueries"), 3), min(n("num_ctes"), 3),
        n("num_window_functions") > 0, n("num_set_operations") > 0,
        n("num_having") > 0, n("num_distinct") > 0, n("num_case_when") > 0,
    )


def _bare_column_name(name: str) -> str:
    return name.rsplit(".", 1)[-1].strip().lower()


def _shannon(counts) -> float:
    total = float(sum(counts))
    if total <= 0:
        return 0.0
    h = 0.0
    for c in counts:
        if c > 0:
            p = c / total
            h -= p * math.log(p)
    return h


class DiversityTracker:
    """Thread-safe. Shared across the batch so state accumulates over the whole
    workload. ``feedback_enabled=False`` -> feedback.py injects no hints (== v6)."""

    def __init__(self):
        self.lock = threading.Lock()
        self.feedback_enabled = True
        # schema usage (coverage-weighted sampling)
        self.table_usage: Counter = Counter()
        self.edge_usage: Counter = Counter()
        self.column_usage: Counter = Counter()
        # SQL / skeleton novelty
        self.seen_sql: set[str] = set()
        self.skeletons: Counter = Counter()
        self.seen_fine: set = set()
        # plan-space novelty
        self.seen_plan: set = set()
        self.plan_families: Counter = Counter()
        # operator / motif state (the feedback signal)
        self.operator_usage: Counter = Counter()
        self.ngram_usage: Counter = Counter()
        self.discovery: list[int] = []
        self.plans_seen: int = 0
        self.hint_fires: Counter = Counter()
        self.hint_hits: Counter = Counter()
        self._hint_aggression: int = 0
        self._lever_index = lever_index()   # for hint efficacy attribution
        # stashed by the batch loop for the report (candidate accounting + AIMD).
        self._accounting: dict = {}
        self._concurrency_snapshot: dict | None = None

    # ---- read by sampling.py ----
    def usage_snapshot(self) -> dict:
        with self.lock:
            return {"tables": dict(self.table_usage),
                    "edges": dict(self.edge_usage),
                    "columns": dict(self.column_usage)}

    # ---- read by feedback.py (hint selection) ----
    def feedback_state(self) -> tuple[dict, int]:
        with self.lock:
            return dict(self.operator_usage), self._hint_aggression

    # ---- read by Lakehouse.generate_workload for the report ----
    def generation_accounting_snapshot(self) -> dict:
        return dict(self._accounting)

    # ---- the accept gate ----
    def try_accept(
        self, *,
        sql_key: str, skeleton, tables: list[str], skeleton_cap: int,
        edges=(), columns=(), levers=(),
        plan_sig=None, plan_family=None, plan_ngrams=None,
        plan_signature_cap: int | None = None, enforce_caps: bool = True,
    ) -> str:
        fine_key = (skeleton, tuple(sorted(tables)))
        with self.lock:
            if sql_key in self.seen_sql:
                return "duplicate"
            if enforce_caps:
                if plan_sig is not None and plan_sig in self.seen_plan:
                    return "plan_duplicate"
                if (plan_signature_cap is not None and plan_family is not None
                        and self.plan_families[plan_family] >= plan_signature_cap):
                    return "plan_capped"
                if fine_key in self.seen_fine:
                    return "near_duplicate"
                if self.skeletons[skeleton] >= skeleton_cap:
                    return "skeleton_capped"

            # --- accept: record novelty keys + schema usage ---
            self.seen_sql.add(sql_key)
            self.seen_fine.add(fine_key)
            self.skeletons[skeleton] += 1
            if plan_sig is not None:
                self.seen_plan.add(plan_sig)
            if plan_family is not None:
                self.plan_families[plan_family] += 1
            self.table_usage.update(tables)
            self.edge_usage.update(edges)
            self.column_usage.update(columns)

            # --- operator / motif state (feedback signal + instrumentation) ---
            self.plans_seen += 1
            plan_ops = set()
            if plan_family is not None:
                for op, _c in plan_family:
                    self.operator_usage[op] += 1
                    plan_ops.add(op)
            grams = plan_ngrams or Counter()
            self.discovery.append(sum(1 for g in grams if self.ngram_usage.get(g, 0) == 0))
            for g, c in grams.items():
                self.ngram_usage[g] += c
            for L in (levers or ()):
                lv = self._lever_index.get(L)
                if lv is None:
                    continue
                self.hint_fires[L] += 1
                if lv.target_operator in plan_ops:
                    self.hint_hits[L] += 1

            self._maybe_escalate_locked()
            return "accepted"

    # ---- F-4: directed plateau pressure (raises hint aggression) ----
    def _maybe_escalate_locked(self) -> None:
        n = self.plans_seen
        if n < 2 * config.ESC_WINDOW or n % config.ESC_WINDOW != 0:
            return
        if self._hint_aggression >= config.MAX_AGGRESSION:
            return
        base = self.discovery[:config.ESC_WINDOW]
        recent = self.discovery[-config.ESC_WINDOW:]
        base_rate = sum(base) / len(base)
        recent_rate = sum(recent) / len(recent)
        if base_rate > 0 and recent_rate < 0.5 * base_rate:
            self._hint_aggression += 1

    # ---- F-6: gap instrumentation for the report ----
    def plan_feedback_snapshot(self) -> dict:
        structural = structural_operators()
        with self.lock:
            covered = [op for op in structural if self.operator_usage.get(op, 0) > 0]
            marg = [self.operator_usage.get(op, 0) for op in structural]
            denom = math.log(len(structural)) if len(structural) > 1 else 1.0
            hit_rate = {L: round(self.hint_hits[L] / f, 3)
                        for L, f in self.hint_fires.items() if f}
            return {
                "plans_seen": self.plans_seen,
                "hint_aggression": self._hint_aggression,
                "unique_ngrams": len(self.ngram_usage),
                "operator_coverage": round(len(covered) / max(1, len(structural)), 3),
                "operators_covered": len(covered),
                "operators_reachable": len(structural),
                "operators_missing": sorted(set(structural) - set(covered)),
                "operator_entropy_norm": round(_shannon(marg) / denom, 3) if denom else 0.0,
                "discovery_rate_first100": sum(self.discovery[:100]) / max(1, len(self.discovery[:100])),
                "discovery_rate_last100": sum(self.discovery[-100:]) / max(1, len(self.discovery[-100:])),
                "operator_usage": dict(self.operator_usage),
                "hint_fires": dict(self.hint_fires),
                "hint_hit_rate": hit_rate,
            }

    def reset(self):
        with self.lock:
            for c in (self.table_usage, self.edge_usage, self.column_usage,
                      self.skeletons, self.plan_families, self.operator_usage,
                      self.ngram_usage, self.hint_fires, self.hint_hits):
                c.clear()
            self.seen_sql.clear()
            self.seen_fine.clear()
            self.seen_plan.clear()
            self.discovery.clear()
            self.plans_seen = 0
            self._hint_aggression = 0
            self._accounting = {}
            self._concurrency_snapshot = None
