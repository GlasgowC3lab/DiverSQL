"""
choose_constructs(tracker, rng, family):
1. budget k   = FAMILY_CONSTRUCT_BUDGET[family]  (+hint_aggression when feedback
                plateaus). This CAPS stacking -- the direct lever on invalids --
                while keeping enough constructs for sequence variety.
2. candidates = the unified CONSTRUCTS catalog, filtered to the family.
3. score(c)   = need(op) * reliability
                need(op) = 1/(1+operator_usage[op])  (under-used -> higher;
                1.0 for pure-clause constructs and when feedback is off)
                reliability = 1.0 guaranteed else CONDITIONAL_WEIGHT
4. pick k     = softmax SAMPLING, one per distinct operator so a query never 
                double-asks for the same operator.

``feedback_enabled=False`` -> uniform weights (still budgeted, coherent) 
                           -- a coverage-blind baseline.

Tunables in config: FAMILY_CONSTRUCT_BUDGET, HINT_SOFTMAX_TEMP, CONDITIONAL_WEIGHT,
MAX_AGGRESSION. Plateau pressure (hint_aggression) is raised in the tracker.
"""

import math
import random

from . import config
from .prompt import CONSTRUCTS


class FeedbackPolicy:
    """Default = budgeted, coverage-weighted construct selection."""

    def choose_constructs(self, tracker, rng: random.Random, family: dict) -> list[dict]:
        """-> [{'name', 'line'}] to append as add-on lines for this query."""
        fam = family["name"]
        lo, hi = config.FAMILY_CONSTRUCT_BUDGET.get(fam, (1, 2))
        if hi <= 0:
            return []

        fb = bool(getattr(tracker, "feedback_enabled", False))
        usage, aggression = tracker.feedback_state() if fb else ({}, 0)

        k = rng.randint(lo, hi) + (aggression if fb else 0)
        k = min(k, hi + config.MAX_AGGRESSION)

        candidates = [c for c in CONSTRUCTS if fam != "simple" or c.get("simple_ok")]
        scored = []
        for c in candidates:
            op = c.get("target_operator")
            need = (1.0 / (1.0 + usage.get(op, 0))) if (fb and op) else 1.0
            rel = 1.0 if c.get("reliability", "guaranteed") == "guaranteed" else config.CONDITIONAL_WEIGHT
            scored.append((c, need * rel))

        chosen = self._sample_distinct(scored, k, rng)
        return [{"name": c["name"], "line": c["line"]} for c in chosen]

    @staticmethod
    def _sample_distinct(scored, k, rng) -> list:
        """Softmax sampling without replacement; at most one construct per distinct
        target operator (pure-clause constructs de-dupe on their name)."""
        pool = list(scored)
        chosen, used = [], set()
        while pool and len(chosen) < k:
            weights = [math.exp(s / config.HINT_SOFTMAX_TEMP) for _c, s in pool]
            c = rng.choices([c for c, _s in pool], weights=weights, k=1)[0]
            chosen.append(c)
            key = c.get("target_operator") or c["name"]
            used.add(key)
            pool = [(cc, s) for (cc, s) in pool if (cc.get("target_operator") or cc["name"]) not in used]
        return chosen

    def snapshot(self, tracker) -> dict:
        return tracker.plan_feedback_snapshot()


DEFAULT_POLICY = FeedbackPolicy()

__all__ = ["FeedbackPolicy", "DEFAULT_POLICY"]
