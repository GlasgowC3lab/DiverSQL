"""schema -- dataset schema + live Trino introspection."""

import json, random
from collections import defaultdict, deque
from pathlib import Path
from _thread import LockType
from .config import SCHEMA_DIR

def load_schema(schema: str | Path) -> dict:
    path = SCHEMA_DIR / f"{schema}.json"
    with path.open("r", encoding="utf-8") as f:
        return json.load(f)

def build_relationship_graph(schema: dict):
    graph = defaultdict(set)

    for left_table, _, right_table, _ in schema["relationships"]:
        graph[left_table].add(right_table)
        graph[right_table].add(left_table)

    return graph

def relationship_to_text(rel) -> str:
    left_table, left_cols, right_table, right_cols = rel
    return " AND ".join(
        f"{left_table}.{l_col} = {right_table}.{r_col}"
        for l_col, r_col in zip(left_cols, right_cols)
    )

def sample_connected_tables(
    schema: dict,
    n_tables: int,
    seed: int | None = None,
) -> list[str]:
    rng = random.Random(seed)
    graph = build_relationship_graph(schema)

    all_tables = list(schema["tables"])
    start = rng.choice(all_tables)

    selected = {start}
    frontier = deque([start])

    while frontier and len(selected) < n_tables:
        current = frontier.popleft()
        neighbours = list(graph[current])
        rng.shuffle(neighbours)

        for neighbour in neighbours:
            if neighbour not in selected:
                selected.add(neighbour)
                frontier.append(neighbour)
                if len(selected) >= n_tables:
                    break

    return sorted(selected)

def get_relevant_relationships(schema: dict, selected_tables: list[str]) -> list:
    selected = set(selected_tables)
    return [
        rel for rel in schema["relationships"]
        if rel[0] in selected and rel[2] in selected
    ]

def fetch_table_columns_cached(
    *,
    conn_factory,
    catalog: str,
    schema: str,
    table: str,
    ddl_cache: dict[str, list[dict]],
    ddl_cache_lock: LockType,
) -> list[dict]:
    # First check: quick read under lock.
    with ddl_cache_lock:
        cached = ddl_cache.get(table)

    if cached is not None:
        return cached

    # Cache miss: fetch outside the lock so other threads are not blocked
    # while Trino is queried.
    conn = conn_factory()
    try:
        cols = fetch_table_columns(
            conn=conn,
            catalog=catalog,
            schema=schema,
            table=table,
        )
    finally:
        conn.close()

    # Second check: another thread may have fetched the same table while
    # this thread was querying Trino.
    with ddl_cache_lock:
        existing = ddl_cache.get(table)
        if existing is not None:
            return existing

        ddl_cache[table] = cols
        return cols

def fetch_table_columns(conn, catalog: str, schema: str, table: str) -> list[dict]:
    cur = conn.cursor()
    try:
        cur.execute(
            f"""
            SELECT column_name, data_type
            FROM {catalog}.information_schema.columns
            WHERE table_schema = '{schema}'
              AND table_name = '{table}'
            ORDER BY ordinal_position
            """
        )
        return [{"name": row[0], "type": row[1]} for row in cur.fetchall()]
    finally:
        cur.close()

def build_table_ddl_context(
    *,
    conn_factory,
    catalog: str,
    schema: str,
    tables: list[str],
    ddl_cache: dict[str, list[dict]],
    ddl_cache_lock: LockType,
) -> str:
    chunks = []

    for table in tables:
        cols = fetch_table_columns_cached(
            conn_factory=conn_factory,
            catalog=catalog,
            schema=schema,
            table=table,
            ddl_cache=ddl_cache,
            ddl_cache_lock=ddl_cache_lock,
        )

        if not cols:
            chunks.append(f"-- WARNING: no columns found for table {table}")
            continue

        col_lines = ",\n".join(
            f"    {col['name']} {col['type']}"
            for col in cols
        )
        chunks.append(f"CREATE TABLE {table} (\n{col_lines}\n);")

    return "\n\n".join(chunks)

def extract_schema_tables(schema_json: dict) -> list[str]:
    """
    Extract table names from the schema JSON used by the query generator.

    Supports:
      - {"tables": ["store_sales", "date_dim"]}
      - {"tables": {"store_sales": {...}}}
      - {"tables": [{"name": "store_sales"}]}
    """
    raw_tables = schema_json.get("tables", [])

    if isinstance(raw_tables, dict):
        tables = list(raw_tables.keys())
    else:
        tables = [
            t.get("name") if isinstance(t, dict) else t
            for t in raw_tables
        ]

    return sorted({
        str(t)
        for t in tables
        if t is not None and str(t).strip()
    })

def fetch_schema_table_columns(
    *,
    conn_factory,
    catalog: str,
    schema: str,
    schema_json: dict,
) -> dict[str, list[dict]]:
    """
    Fetch all table-column metadata for a schema JSON.

    This is a convenience wrapper around fetch_table_columns(...), so schema
    metadata fetching remains in query_generator.py.
    """
    tables = extract_schema_tables(schema_json)

    table_columns: dict[str, list[dict]] = {}

    for table in tables:
        conn = conn_factory()

        try:
            table_columns[table] = fetch_table_columns(
                conn=conn,
                catalog=catalog,
                schema=schema,
                table=table,
            )
        finally:
            conn.close()

    return table_columns
