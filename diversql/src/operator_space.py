"""
operator_space -- typed access to the curated operator ceiling and lever map.

Loads the two static reference tables under ``diversql/resources``:

  * ``operators_ground_truth.csv`` -- every operator name Trino can render in an
    EXPLAIN plan (the C_phys ceiling), with trivial/reachability flags.
  * ``lever_operator_map.csv``     -- prompt levers -> the operator each reliably
    produces, with ready-to-inject prompt hints and non-degenerate exemplars.
    
"""

import csv
import functools

from dataclasses import dataclass

__all__ = [
    "Operator",
    "Lever",
    "RESOURCES_DIR",
    "load_operators",
    "load_levers",
    "OPERATORS",
    "LEVERS",
    "operator_index",
    "lever_index",
    "reachable_operators",
    "structural_operators",
    "trivial_operators",
    "expected_operator_types",
    "levers_for_operators",
    "levers_for_deficit",
]

from .config import RESOURCES_DIR
_OPERATORS_CSV = RESOURCES_DIR / "operators_ground_truth.csv"
_LEVERS_CSV = RESOURCES_DIR / "lever_operator_map.csv"


# ============================================================
# Row types
# ============================================================

@dataclass(frozen=True)
class Operator:
    """One row of ``operators_ground_truth.csv`` (a Trino-rendered operator)."""
    rendered_name: str
    logical_operator: str
    plan_node_class: str
    category: str
    is_trivial: bool
    read_reachable: bool
    iceberg_reachable: bool
    notes: str


@dataclass(frozen=True)
class Lever:
    """One row of ``lever_operator_map.csv`` (a promptable SQL construct)."""
    lever_id: str
    target_operator: str
    secondary_operators: tuple[str, ...]
    tier: int
    reliability: str
    category: str
    sql_construct: str
    prompt_hint: str
    example_snippet: str
    non_degenerate_note: str


def _as_bool(value: str) -> bool:
    return str(value).strip() in {"1", "true", "True", "yes"}


# ============================================================
# Loaders (cached -- the CSVs never change at runtime)
# ============================================================

@functools.lru_cache(maxsize=1)
def load_operators() -> tuple[Operator, ...]:
    """Parse the operator ceiling. Cached; result is immutable."""
    with _OPERATORS_CSV.open(encoding="utf-8", newline="") as fh:
        rows = list(csv.DictReader(fh))
    return tuple(
        Operator(
            rendered_name=r["rendered_name"].strip(),
            logical_operator=r["logical_operator"].strip(),
            plan_node_class=r["plan_node_class"].strip(),
            category=r["category"].strip(),
            is_trivial=_as_bool(r["is_trivial"]),
            read_reachable=_as_bool(r["read_reachable"]),
            iceberg_reachable=_as_bool(r["iceberg_reachable"]),
            notes=r.get("notes", "").strip(),
        )
        for r in rows
    )


@functools.lru_cache(maxsize=1)
def load_levers() -> tuple[Lever, ...]:
    """Parse the lever->operator map. Cached; result is immutable."""
    with _LEVERS_CSV.open(encoding="utf-8", newline="") as fh:
        rows = list(csv.DictReader(fh))
    levers = []
    for r in rows:
        secondary = tuple(
            s.strip() for s in (r.get("secondary_operators") or "").split("|") if s.strip()
        ) if "|" in (r.get("secondary_operators") or "") else tuple(
            s.strip() for s in (r.get("secondary_operators") or "").split(",") if s.strip()
        )
        levers.append(
            Lever(
                lever_id=r["lever_id"].strip(),
                target_operator=r["target_operator"].strip(),
                secondary_operators=secondary,
                tier=int(r["tier"]),
                reliability=r["reliability"].strip(),
                category=r["category"].strip(),
                sql_construct=r["sql_construct"].strip(),
                prompt_hint=r["prompt_hint"].strip(),
                example_snippet=r["example_snippet"].strip(),
                non_degenerate_note=r["non_degenerate_note"].strip(),
            )
        )
    return tuple(levers)


# Eager module-level views for convenience.
OPERATORS: tuple[Operator, ...] = load_operators()
LEVERS: tuple[Lever, ...] = load_levers()


@functools.lru_cache(maxsize=1)
def operator_index() -> dict[str, Operator]:
    """``rendered_name`` -> :class:`Operator`."""
    return {op.rendered_name: op for op in load_operators()}


@functools.lru_cache(maxsize=1)
def lever_index() -> dict[str, Lever]:
    """``lever_id`` -> :class:`Lever`."""
    return {lv.lever_id: lv for lv in load_levers()}


# ============================================================
# Operator-set helpers
# ============================================================

def reachable_operators(
    *, read_only: bool = True, iceberg: bool = True, include_trivial: bool = True
) -> frozenset[str]:
    """Rendered-name set filtered by reachability.

    Defaults give the full read-only-on-Iceberg reachable set (the honest
    coverage denominator). Set ``include_trivial=False`` to restrict to
    structural motifs.
    """
    out = set()
    for op in load_operators():
        if read_only and not op.read_reachable:
            continue
        if iceberg and not op.iceberg_reachable:
            continue
        if not include_trivial and op.is_trivial:
            continue
        out.add(op.rendered_name)
    return frozenset(out)


def structural_operators(*, read_only: bool = True, iceberg: bool = True) -> frozenset[str]:
    """Reachable, non-trivial operators -- the motifs diversity should chase."""
    return reachable_operators(read_only=read_only, iceberg=iceberg, include_trivial=False)


@functools.lru_cache(maxsize=1)
def trivial_operators() -> frozenset[str]:
    """Rendered names flagged trivial (plumbing/surface artifacts)."""
    return frozenset(op.rendered_name for op in load_operators() if op.is_trivial)


def expected_operator_types(*, read_only: bool = True, iceberg: bool = True) -> frozenset[str]:
    """Alias for the reachable set, named to match
    ``workload_analysis.structural_diversity_summary(expected_operator_types=...)``.
    """
    return reachable_operators(read_only=read_only, iceberg=iceberg, include_trivial=True)


# ============================================================
# Lever lookups (the prompt-construction side)
# ============================================================

def levers_for_operators(targets) -> tuple[Lever, ...]:
    """Every lever whose ``target_operator`` is in ``targets`` (a set/iterable of
    rendered names). Order follows the CSV (stable)."""
    want = set(targets)
    return tuple(lv for lv in load_levers() if lv.target_operator in want)


def levers_for_deficit(
    observed_counts: dict[str, int] | None = None,
    *,
    read_only: bool = True,
    iceberg: bool = True,
    reliable_only: bool = True,
) -> tuple[Lever, ...]:
    """Levers that target currently under-used structural operators, most-deficient
    first.

    ``observed_counts`` maps rendered operator name -> times seen so far (e.g.
    ``tracker.operator_usage``). Operators absent from it count as 0. Only
    structural, reachable operators are considered; ties break on the CSV order.

    With ``reliable_only`` (default) conditional levers are still included but
    guaranteed levers of equal deficit rank first.
    """
    counts = dict(observed_counts or {})
    structural = structural_operators(read_only=read_only, iceberg=iceberg)

    def deficit(lv: Lever) -> tuple:
        seen = counts.get(lv.target_operator, 0)
        guaranteed = 0 if lv.reliability == "guaranteed" else 1
        return (seen, guaranteed)

    candidates = [lv for lv in load_levers() if lv.target_operator in structural]
    candidates.sort(key=deficit)
    if reliable_only:
        # keep all, but the sort already floats guaranteed + zero-seen to the top
        pass
    return tuple(candidates)
