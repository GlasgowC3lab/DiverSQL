"""sampling -- coverage-weighted table + value selection."""

import random, threading
from collections import deque
from .schema import (build_relationship_graph, extract_schema_tables)
from .diversity_tracker import _edge_key, _bare_column_name

_VALUE_CACHE: dict[tuple[str, str], list] = {}

_VALUE_CACHE_LOCK = threading.Lock()

def _is_connected(subset: set[str], graph) -> bool:
    if len(subset) <= 1:
        return True
    start = next(iter(subset))
    seen = {start}
    queue = deque([start])
    while queue:
        cur = queue.popleft()
        for nb in graph.get(cur, set()):
            if nb in subset and nb not in seen:
                seen.add(nb)
                queue.append(nb)
    return len(seen) == len(subset)

def _largest_component(subset: set[str], graph) -> set[str]:
    remaining = set(subset)
    best: set[str] = set()
    while remaining:
        start = next(iter(remaining))
        comp = {start}
        queue = deque([start])
        while queue:
            cur = queue.popleft()
            for nb in graph.get(cur, set()):
                if nb in remaining and nb not in comp:
                    comp.add(nb)
                    queue.append(nb)
        if len(comp) > len(best):
            best = comp
        remaining -= comp
    return best

def sample_tables_v2(
    schema: dict,
    n_tables: int,
    *,
    rng: random.Random,
    table_usage: dict[str, int] | None = None,
    edge_usage: dict[tuple[str, str], int] | None = None,
    connected_fraction: float = 0.5,
    max_uniform_tries: int = 40,
) -> tuple[list[str], str]:
    """
    Returns (tables, mode) where mode is "connected" or "uniform".

    "uniform": rejection-sample uniform subsets until the induced FK
    subgraph is connected (largest-component + top-up as fallback). 
    Keeps table entropy without the degenerate sets.

    "connected": Start table and expansion steps are
    drawn with weight 1/(1+table_usage), multiplied by 1/(1+usage of the 
    least-used FK edge that connects the candidate to the current selection)
    so under-covered join edges get exercised.
    """
    all_tables = extract_schema_tables(schema)
    n_tables = min(n_tables, len(all_tables))
    t_usage = table_usage or {}
    e_usage = edge_usage or {}
    graph = build_relationship_graph(schema)

    def table_weight(t: str) -> float:
        return 1.0 / (1.0 + t_usage.get(t, 0))

    if n_tables <= 1:
        start = rng.choices(all_tables, weights=[table_weight(t) for t in all_tables], k=1)[0]
        return [start], "uniform"

    if rng.random() >= connected_fraction:
        subset: set[str] = set()
        for _ in range(max_uniform_tries):
            cand = set(rng.sample(all_tables, k=n_tables))
            if _is_connected(cand, graph):
                return sorted(cand), "uniform"
            subset = cand
        # fallback: largest connected component of the last draw, topped up
        # along FK edges so the result stays joinable
        comp = _largest_component(subset, graph)
        while len(comp) < n_tables:
            frontier = sorted(set().union(*(graph.get(t, set()) for t in comp)) - comp)
            if not frontier:
                break
            comp.add(rng.choices(frontier, weights=[table_weight(t) for t in frontier], k=1)[0])
        return sorted(comp), "uniform"

    def combined_weight(t: str, selected: set[str]) -> float:
        edge_uses = [
            e_usage.get(_edge_key(t, s), 0)
            for s in selected
            if s in graph.get(t, set())
        ]
        least_used_edge = min(edge_uses) if edge_uses else 0
        return table_weight(t) / (1.0 + least_used_edge)

    start = rng.choices(all_tables, weights=[table_weight(t) for t in all_tables], k=1)[0]
    selected = {start}
    frontier = set(graph.get(start, set()))

    while frontier and len(selected) < n_tables:
        candidates = sorted(frontier)  # sort for seed reproducibility
        pick = rng.choices(
            candidates,
            weights=[combined_weight(t, selected) for t in candidates],
            k=1,
        )[0]
        selected.add(pick)
        frontier |= set(graph.get(pick, set()))
        frontier -= selected

    return sorted(selected), "connected"

def _format_value(v) -> str:
    s = str(v)
    return s if len(s) <= 60 else s[:57] + "..."

def _cached_column_values(
    *,
    conn_factory,
    catalog: str,
    schema: str,
    table: str,
    column: str,
    value_cache: dict,
    value_cache_lock,
) -> list:
    key = (table, column)
    with value_cache_lock:
        cached = value_cache.get(key)
    if cached is not None:
        return cached

    vals = sample_column_values(
        conn_factory=conn_factory,
        catalog=catalog,
        schema=schema,
        table=table,
        column=column,
    )
    with value_cache_lock:
        value_cache.setdefault(key, vals)
        return value_cache[key]

def sample_column_values(
    *,
    conn_factory,
    catalog: str,
    schema: str,
    table: str,
    column: str,
    limit: int = 20,
) -> list:
    """Sample distinct non-null values for one column. Best-effort: [] on error."""
    conn = conn_factory()
    try:
        cur = conn.cursor()
        try:
            cur.execute(
                f"SELECT DISTINCT {column} FROM {catalog}.{schema}.{table} "
                f"WHERE {column} IS NOT NULL LIMIT {int(limit)}"
            )
            return [r[0] for r in cur.fetchall()]
        finally:
            cur.close()
    except Exception:
        return []
    finally:
        try:
            conn.close()
        except Exception:
            pass

def build_value_aid(
    *,
    conn_factory,
    catalog: str,
    schema: str,
    tables: list[str],
    columns_by_table: dict[str, list[dict]],
    rng: random.Random,
    value_cache: dict,
    value_cache_lock,
    column_usage: dict[str, int] | None = None,
    max_cols: int = 8,
    max_vals: int = 5,
) -> str:

    usage = column_usage or {}
    lines: list[str] = []
    budget = max_cols
    shuffled_tables = list(tables)
    rng.shuffle(shuffled_tables)

    for table in shuffled_tables:
        if budget <= 0:
            break
        cols = list(columns_by_table.get(table, []))
        if not cols:
            continue
        weights = [1.0 / (1.0 + usage.get(_bare_column_name(c["name"]), 0)) for c in cols]
        picked: list[dict] = []
        pool = list(zip(cols, weights))
        for _ in range(min(3, len(pool))):  # up to 3 columns per table
            total = sum(w for _, w in pool)
            if total <= 0:
                break
            r = rng.random() * total
            acc = 0.0
            for i, (c, w) in enumerate(pool):
                acc += w
                if r <= acc:
                    picked.append(c)
                    pool.pop(i)
                    break
        for col in picked:
            if budget <= 0:
                break
            vals = _cached_column_values(
                conn_factory=conn_factory,
                catalog=catalog,
                schema=schema,
                table=table,
                column=col["name"],
                value_cache=value_cache,
                value_cache_lock=value_cache_lock,
            )
            if not vals:
                continue
            shown = rng.sample(vals, k=min(max_vals, len(vals)))
            lines.append(
                f"- {table}.{col['name']} ({col['type']}): "
                + ", ".join(_format_value(v) for v in shown)
            )
            budget -= 1

    if not lines:
        return ""
    return (
        "Example column values (sampled from the live data; use them to "
        "write realistic, varied predicates):\n" + "\n".join(lines)
    )
