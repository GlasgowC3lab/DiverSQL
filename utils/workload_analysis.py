"""Plan- and schema-level diversity metrics over workloads of compiled query plans."""

import hashlib
import json
import math
import re
from collections import Counter, defaultdict
from typing import Any, Dict, Iterable, List, Optional, Tuple

import numpy as np
import pandas as pd

from utils.parser import iter_edges

STANDARD_COMPARISON_COLUMNS = [
    "workload",
    "sql_queries",
    "planned_queries",

    # Schema coverage
    "table_coverage_pct",
    "column_coverage_pct",
    "join_edge_coverage_pct",

    # Schema balance
    "table_usage_entropy",
    "column_usage_entropy",
    "join_edge_usage_entropy",
    "unique_table_set_ratio",

    # Plan diversity
    "unique_plan_graphs",
    "plan_uniqueness_ratio",
    "operator_types_observed",
    "operator_type_entropy",
    "unique_operator_instances",
    "operator_ngram_entropy",

    # Redundancy / similarity
    "mean_nn_plan_distance",
    "min_nn_plan_distance",
    "plan_graph_vendi_score",
]

# =============================================================================
# Generic helpers
# =============================================================================

_QID_RE = re.compile(r"^q(\d+)$", re.IGNORECASE)


def _qid_sort_key(qid: Any) -> tuple[int, int | str]:
    """Sort q1, q2, ..., q10 numerically; sort other ids after q ids."""
    text = str(qid)
    m = _QID_RE.match(text)
    if m:
        return (0, int(m.group(1)))
    return (1, text)


def _normalise_identifier(x: Any) -> str:
    """Normalise SQL/schema identifiers for comparison."""
    return str(x).strip().strip('"').strip("`").lower()


def _as_clean_table_name(x: Any) -> str:
    """
    Normalise a table identifier to its final component.

    Examples
    --------
    iceberg.tpcds.store_sales -> store_sales
    store_sales               -> store_sales
    """
    return _normalise_identifier(x).split(".")[-1]


def _as_clean_column_name(x: Any) -> str:
    """
    Normalise a column identifier to table.column where possible.

    Examples
    --------
    iceberg.tpcds.store_sales.ss_item_sk -> store_sales.ss_item_sk
    store_sales.ss_item_sk               -> store_sales.ss_item_sk
    """
    text = _normalise_identifier(x)
    parts = text.split(".")
    if len(parts) >= 2:
        return f"{parts[-2]}.{parts[-1]}"
    return text


def stable_hash(obj: Any, *, n_chars: int = 16) -> str:
    """Return a stable short hash for a nested JSON-serialisable object."""
    payload = json.dumps(obj, sort_keys=True, default=str)
    return hashlib.sha256(payload.encode("utf-8")).hexdigest()[:n_chars]


def shannon_entropy(counter: Counter, *, normalise: bool = True) -> float:
    """
    Shannon entropy over a frequency distribution.

    If normalise=True, entropy is divided by log(k), where k is the number of
    observed categories. The result is therefore in [0, 1].
    """
    total = sum(counter.values())
    if total <= 0:
        return 0.0

    vals = np.array([v for v in counter.values() if v > 0], dtype=float)
    if len(vals) == 0:
        return 0.0

    probs = vals / vals.sum()
    h = float(-(probs * np.log(probs)).sum())

    if normalise:
        if len(probs) <= 1:
            return 0.0
        h /= math.log(len(probs))

    return h


def coverage_ratio(observed: Iterable[Any], universe: Iterable[Any]) -> float:
    """Compute |observed ∩ universe| / |universe|."""
    observed_set = set(observed)
    universe_set = set(universe)
    if not universe_set:
        return np.nan
    return len(observed_set & universe_set) / len(universe_set)


def weighted_coverage_ratio(observed: Iterable[Any], weights: Dict[Any, float]) -> float:
    """Compute weighted coverage over a universe represented by item weights."""
    observed_set = set(observed)
    total_weight = 0.0
    observed_weight = 0.0

    for item, weight in weights.items():
        try:
            w = float(weight)
        except Exception:
            continue

        if not np.isfinite(w) or w <= 0:
            continue

        total_weight += w
        if item in observed_set:
            observed_weight += w

    if total_weight <= 0:
        return np.nan

    return observed_weight / total_weight


def weighted_jaccard_similarity(a: Counter, b: Counter) -> float:
    """Weighted Jaccard similarity between two Counters."""
    keys = set(a) | set(b)
    if not keys:
        return 1.0

    numerator = 0.0
    denominator = 0.0

    for k in keys:
        av = float(a.get(k, 0.0))
        bv = float(b.get(k, 0.0))
        numerator += min(av, bv)
        denominator += max(av, bv)

    if denominator <= 0:
        return 0.0

    return numerator / denominator


def counter_to_df(
    counter: Counter,
    *,
    key_name: str = "item",
    count_name: str = "count",
    top_k: Optional[int] = None,
) -> pd.DataFrame:
    """Convert a Counter into a sorted DataFrame."""
    rows = [
        {key_name: key, count_name: int(count)}
        for key, count in counter.most_common(top_k)
    ]
    return pd.DataFrame(rows)


# =============================================================================
# Convenience extraction from Lakehouse.load_query_plans output
# =============================================================================


def queries_from_plan_bundle(plan_bundle: Dict[str, Any]) -> Dict[str, Dict[str, Any]]:
    """Extract `queries_by_name` from `Lakehouse.load_query_plans(...)` output."""
    out: Dict[str, Dict[str, Any]] = {}

    for qname, row in plan_bundle.get("plans", {}).items():
        out[str(qname)] = {
            "query_name": str(qname),
            "sql": row.get("sql", ""),
            "path": row.get("sql_path"),
            "status": row.get("status"),
        }

    return dict(sorted(out.items(), key=lambda kv: _qid_sort_key(kv[0])))


def dags_from_plan_bundle(
    plan_bundle: Dict[str, Any],
    *,
    require_ok: bool = True,
) -> Dict[str, Dict[str, Any]]:
    """Extract `dags_by_query` from `Lakehouse.load_query_plans(...)` output."""
    out: Dict[str, Dict[str, Any]] = {}

    for qname, row in plan_bundle.get("plans", {}).items():
        if require_ok and row.get("status") != "ok":
            continue

        dag = row.get("dag")
        if isinstance(dag, dict) and {"nodes", "edges"}.issubset(dag.keys()):
            out[str(qname)] = dag

    return dict(sorted(out.items(), key=lambda kv: _qid_sort_key(kv[0])))


# =============================================================================
# Query-generator schema integration
# =============================================================================


def _extract_schema_tables_from_schema_json(schema_json: Dict[str, Any]) -> List[str]:
    """
    Extract table names from the schema JSON used by query_generator.py.

    Supports:
    - {"tables": ["store_sales", "date_dim", ...]}
    - {"tables": {"store_sales": {...}, ...}}
    - {"tables": [{"name": "store_sales"}, ...]}
    """
    raw_tables = schema_json.get("tables", [])
    tables: List[str] = []

    if isinstance(raw_tables, dict):
        tables = list(raw_tables.keys())
    elif isinstance(raw_tables, list):
        for item in raw_tables:
            if isinstance(item, dict):
                name = item.get("name") or item.get("table_name") or item.get("table")
                if name:
                    tables.append(str(name))
            else:
                tables.append(str(item))

    return sorted({_as_clean_table_name(t) for t in tables if str(t).strip()})


def _extract_columns_from_schema_json_tables(schema_json: Dict[str, Any]) -> Dict[str, List[dict]]:
    """
    Best-effort extraction of table columns embedded in schema_json["tables"].

    If your schema JSON only contains table names and relationships, pass
    table_columns fetched from query_generator.fetch_table_columns(...).
    """
    raw_tables = schema_json.get("tables", {})
    out: Dict[str, List[dict]] = {}

    if not isinstance(raw_tables, dict):
        return out

    for table, meta in raw_tables.items():
        table_name = _as_clean_table_name(table)
        if not isinstance(meta, dict):
            continue

        cols = meta.get("columns") or meta.get("cols") or meta.get("schema") or []
        parsed_cols: List[dict] = []

        for col in cols:
            if isinstance(col, dict):
                name = col.get("name") or col.get("column_name")
                dtype = col.get("type") or col.get("data_type")
                if name:
                    parsed_cols.append({"name": str(name), "type": dtype})
            else:
                parsed_cols.append({"name": str(col), "type": None})

        if parsed_cols:
            out[table_name] = parsed_cols

    return out


def _normalise_table_columns(table_columns: Optional[Dict[str, Any]]) -> Dict[str, List[dict]]:
    """Normalise table column metadata to table -> [{name, type}, ...]."""
    if table_columns is None:
        return {}

    out: Dict[str, List[dict]] = {}

    for table, cols in table_columns.items():
        table_name = _as_clean_table_name(table)
        parsed_cols: List[dict] = []

        for col in cols or []:
            if isinstance(col, dict):
                name = col.get("name") or col.get("column_name")
                dtype = col.get("type") or col.get("data_type")
                if name:
                    parsed_cols.append({"name": str(name), "type": dtype})
            else:
                parsed_cols.append({"name": str(col), "type": None})

        out[table_name] = parsed_cols

    return out


def schema_columns_from_table_columns(table_columns: Dict[str, List[dict]]) -> List[str]:
    """Convert table -> column metadata into ["table.column", ...]."""
    columns: List[str] = []

    for table, cols in table_columns.items():
        table_name = _as_clean_table_name(table)
        for col in cols:
            name = col.get("name") if isinstance(col, dict) else str(col)
            if name:
                columns.append(f"{table_name}.{_normalise_identifier(name)}")

    return sorted(set(columns))


def schema_join_edges_from_relationships(schema_json: Dict[str, Any]) -> List[tuple[str, str]]:
    """
    Convert query_generator schema relationships into table-level join edges.

    query_generator.py relationships are expected to look like:
        [left_table, left_cols, right_table, right_cols]
    """
    edges = set()

    for rel in schema_json.get("relationships", []) or []:
        if not isinstance(rel, (list, tuple)) or len(rel) < 3:
            continue

        left_table = _as_clean_table_name(rel[0])
        right_table = _as_clean_table_name(rel[2])

        if left_table and right_table and left_table != right_table:
            edges.add(tuple(sorted((left_table, right_table))))

    return sorted(edges)


def table_relationship_degree_from_schema(schema_json: Dict[str, Any]) -> Counter:
    """Count how many relationship edges each table participates in."""
    degree = Counter()

    for left, right in schema_join_edges_from_relationships(schema_json):
        degree[left] += 1
        degree[right] += 1

    return degree


def table_complexity_weights_from_schema(
    schema_json: Dict[str, Any],
    *,
    table_columns: Optional[Dict[str, List[dict]]] = None,
) -> Dict[str, float]:
    """
    Build simple, explainable table complexity weights.

    weight = 1 + log(1 + number_of_columns) + log(1 + relationship_degree)
    """
    tables = _extract_schema_tables_from_schema_json(schema_json)
    degree = table_relationship_degree_from_schema(schema_json)
    table_columns = _normalise_table_columns(table_columns)

    weights: Dict[str, float] = {}
    for table in tables:
        n_cols = len(table_columns.get(table, []))
        deg = degree.get(table, 0)
        weights[table] = 1.0 + math.log1p(n_cols) + math.log1p(deg)

    return weights


def schema_universe_from_query_generator_schema(
    schema_json: Dict[str, Any],
    *,
    table_columns: Optional[Dict[str, Any]] = None,
    include_table_weights: bool = True,
) -> Dict[str, Any]:
    """
    Build the schema universe expected by workload_diversity_report(...).

    Parameters
    ----------
    schema_json:
        Schema object loaded using query_generator.load_schema(...).

    table_columns:
        Optional table -> columns metadata fetched using
        query_generator.fetch_table_columns(...).
    """
    schema_tables = _extract_schema_tables_from_schema_json(schema_json)

    embedded_table_columns = _extract_columns_from_schema_json_tables(schema_json)
    provided_table_columns = _normalise_table_columns(table_columns)

    merged_table_columns = dict(embedded_table_columns)
    merged_table_columns.update(provided_table_columns)

    schema_columns = schema_columns_from_table_columns(merged_table_columns)
    schema_join_edges = schema_join_edges_from_relationships(schema_json)

    table_weights = None
    if include_table_weights:
        table_weights = table_complexity_weights_from_schema(
            schema_json,
            table_columns=merged_table_columns,
        )

    return {
        "schema_tables": schema_tables,
        "schema_columns": schema_columns,
        "schema_join_edges": schema_join_edges,
        "table_weights": table_weights,
        "table_columns": merged_table_columns,
    }


def build_schema_universe(
    *,
    schema_tables: Optional[Iterable[Any]] = None,
    schema_columns: Optional[Iterable[Any]] = None,
) -> tuple[Optional[set[str]], Optional[set[str]], Dict[str, set[str]]]:
    """Build normalised schema table/column universes."""
    table_universe = None
    column_universe = None
    columns_by_table: Dict[str, set[str]] = {}

    if schema_tables is not None:
        table_universe = {_as_clean_table_name(t) for t in schema_tables if str(t).strip()}

    if schema_columns is not None:
        column_universe = {_as_clean_column_name(c) for c in schema_columns if str(c).strip()}

        for col in column_universe:
            if "." not in col:
                continue
            table, _ = col.split(".", 1)
            columns_by_table.setdefault(table, set()).add(col)

        if table_universe is None:
            table_universe = set(columns_by_table)

    return table_universe, column_universe, columns_by_table


def normalise_join_edges(join_edges: Iterable[Any]) -> set[tuple[str, str]]:
    """Normalise join edges to undirected sorted table-name tuples."""
    out = set()

    for edge in join_edges:
        if isinstance(edge, (tuple, list)) and len(edge) == 2:
            a, b = edge
        else:
            text = str(edge)
            if "--" in text:
                a, b = text.split("--", 1)
            elif "-" in text:
                a, b = text.split("-", 1)
            elif "." in text:
                a, b = text.split(".", 1)
            else:
                continue

        a = _as_clean_table_name(a)
        b = _as_clean_table_name(b)
        if a and b and a != b:
            out.add(tuple(sorted((a, b))))

    return out


# =============================================================================
# SQL schema feature extraction
# =============================================================================

_SQL_KEYWORDS = {
    "select", "from", "where", "join", "inner", "left", "right", "full", "outer",
    "cross", "on", "group", "by", "order", "limit", "with", "as", "and", "or",
    "case", "when", "then", "else", "end", "sum", "avg", "count", "min", "max",
    "round", "coalesce", "nullif", "distinct", "union", "all", "having", "date",
    "cast", "over", "partition", "rows", "range", "between", "is", "not", "null",
    "true", "false", "desc", "asc", "using", "interval", "extract",
}


def _strip_sql_comments(sql: str) -> str:
    """Remove line and block comments from SQL text."""
    sql = re.sub(r"--.*?$", "", sql, flags=re.MULTILINE)
    sql = re.sub(r"/\*.*?\*/", "", sql, flags=re.DOTALL)
    return sql


def _strip_string_literals(sql: str) -> str:
    """Replace string literals so regex extraction does not pick up fake identifiers."""
    return re.sub(r"'(?:''|[^'])*'", "''", sql)


def extract_cte_names_simple(sql: str) -> set[str]:
    """Extract CTE names from common WITH clauses."""
    sql = _strip_sql_comments(sql)
    ctes = set()

    for match in re.finditer(
        r"(?:with|,)\s+([a-zA-Z_][\w]*)\s+as\s*\(",
        sql,
        flags=re.IGNORECASE,
    ):
        ctes.add(_normalise_identifier(match.group(1)))

    return ctes

def _split_top_level_commas(text: str) -> List[str]:
    """
    Split a SQL fragment on commas that are not inside parentheses.
    """
    parts = []
    current = []
    depth = 0

    for ch in text:
        if ch == "(":
            depth += 1
        elif ch == ")":
            depth = max(0, depth - 1)

        if ch == "," and depth == 0:
            part = "".join(current).strip()
            if part:
                parts.append(part)
            current = []
        else:
            current.append(ch)

    part = "".join(current).strip()
    if part:
        parts.append(part)

    return parts


def _extract_from_table_items(sql: str) -> List[tuple[str, Optional[str]]]:
    """
    Extract table/alias pairs from FROM clauses.

    Handles comma-style TPC-DS syntax:
        FROM store_sales ss, date_dim d, item i

    Also handles unaliased form:
        FROM store_sales, date_dim, item
    """
    sql_clean = _strip_string_literals(_strip_sql_comments(sql))

    items: List[tuple[str, Optional[str]]] = []

    # Capture FROM body until the next major SQL clause.
    from_pattern = (
        r"\bfrom\b\s+"
        r"(.+?)"
        r"(?=\bwhere\b|\bgroup\s+by\b|\border\s+by\b|\bhaving\b|"
        r"\blimit\b|\bunion\b|\bintersect\b|\bexcept\b|$)"
    )

    for match in re.finditer(from_pattern, sql_clean, flags=re.IGNORECASE | re.DOTALL):
        body = match.group(1)

        for part in _split_top_level_commas(body):
            part = part.strip()

            # Ignore subqueries/derived tables here. They are not schema tables.
            if part.startswith("("):
                continue

            # Remove any trailing explicit join segment if mixed syntax appears.
            part = re.split(
                r"\bjoin\b|\bleft\b|\bright\b|\binner\b|\bfull\b|\bcross\b",
                part,
                maxsplit=1,
                flags=re.IGNORECASE,
            )[0].strip()

            tokens = part.split()

            if not tokens:
                continue

            table = tokens[0]
            alias = None

            if len(tokens) >= 2:
                if tokens[1].lower() == "as" and len(tokens) >= 3:
                    alias = tokens[2]
                elif tokens[1].lower() not in _SQL_KEYWORDS:
                    alias = tokens[1]

            items.append((table, alias))

    return items


def _extract_join_table_items(sql: str) -> List[tuple[str, Optional[str]]]:
    """
    Extract table/alias pairs from explicit JOIN clauses.
    """
    sql_clean = _strip_string_literals(_strip_sql_comments(sql))

    items: List[tuple[str, Optional[str]]] = []

    join_pattern = (
        r"\bjoin\s+"
        r"([a-zA-Z_][\w.]*)"
        r"(?:\s+(?:as\s+)?([a-zA-Z_][\w]*))?"
    )

    for match in re.finditer(join_pattern, sql_clean, flags=re.IGNORECASE):
        table = match.group(1)
        alias = match.group(2)
        items.append((table, alias))

    return items


def _extract_table_alias_items(sql: str) -> List[tuple[str, Optional[str]]]:
    """
    Extract table/alias pairs from both comma-style FROM and explicit JOINs.
    """
    return _extract_from_table_items(sql) + _extract_join_table_items(sql)


def _column_table_lookup_from_schema_columns(
    schema_columns: Optional[Iterable[Any]],
) -> Dict[str, set[str]]:
    """
    Build column_name -> {tables} lookup from table.column schema columns.

    Example:
        store_sales.ss_item_sk -> ss_item_sk -> {store_sales}
    """
    lookup: Dict[str, set[str]] = defaultdict(set)

    if schema_columns is None:
        return lookup

    for col in schema_columns:
        clean = _as_clean_column_name(col)

        if "." not in clean:
            continue

        table, column = clean.split(".", 1)
        lookup[column].add(table)

    return dict(lookup)


def extract_table_refs_simple(
    sql: str,
    *,
    schema_tables: Optional[Iterable[Any]] = None,
    filter_to_schema: bool = True,
) -> set[str]:
    """
    Extract table references from FROM/JOIN clauses.

    Supports:
    - explicit JOIN syntax
    - comma-style TPC-DS FROM syntax
    """
    sql_clean = _strip_string_literals(_strip_sql_comments(sql))
    cte_names = extract_cte_names_simple(sql_clean)

    table_universe = None
    if schema_tables is not None:
        table_universe = {_as_clean_table_name(t) for t in schema_tables}

    tables = set()

    for table_raw, _alias in _extract_table_alias_items(sql_clean):
        table = _as_clean_table_name(table_raw)

        if not table or table in _SQL_KEYWORDS or table in cte_names:
            continue

        if filter_to_schema and table_universe is not None and table not in table_universe:
            continue

        tables.add(table)

    return tables


def extract_alias_map_simple(
    sql: str,
    *,
    schema_tables: Optional[Iterable[Any]] = None,
    filter_to_schema: bool = True,
) -> Dict[str, str]:
    """
    Extract alias -> base-table mappings.

    Supports:
    - FROM store_sales ss, date_dim d
    - FROM store_sales, date_dim
    - JOIN date_dim d ON ...
    """
    sql_clean = _strip_string_literals(_strip_sql_comments(sql))
    cte_names = extract_cte_names_simple(sql_clean)

    table_universe = None
    if schema_tables is not None:
        table_universe = {_as_clean_table_name(t) for t in schema_tables}

    alias_map: Dict[str, str] = {}

    for table_raw, alias_raw in _extract_table_alias_items(sql_clean):
        table = _as_clean_table_name(table_raw)

        if not table or table in _SQL_KEYWORDS or table in cte_names:
            continue

        if filter_to_schema and table_universe is not None and table not in table_universe:
            continue

        # Unaliased references can still resolve through the table name.
        alias_map[table] = table

        if alias_raw:
            alias = _normalise_identifier(alias_raw)

            if alias and alias not in _SQL_KEYWORDS:
                alias_map[alias] = table

    return alias_map


def extract_column_refs_simple(
    sql: str,
    *,
    schema_tables: Optional[Iterable[Any]] = None,
    schema_columns: Optional[Iterable[Any]] = None,
    resolve_aliases: bool = True,
    filter_to_schema: bool = True,
) -> set[str]:
    """
    Extract real schema column references from SQL.

    Supports:
    - qualified references: ss.ss_item_sk
    - unqualified TPC-DS references: ss_item_sk

    Unqualified columns are only counted when they map uniquely to one schema
    table. Ambiguous column names are ignored.
    """
    sql_clean = _strip_string_literals(_strip_sql_comments(sql))

    table_universe, column_universe, _ = build_schema_universe(
        schema_tables=schema_tables,
        schema_columns=schema_columns,
    )

    alias_map = {}
    if resolve_aliases:
        alias_map = extract_alias_map_simple(
            sql_clean,
            schema_tables=table_universe,
            filter_to_schema=filter_to_schema,
        )

    column_lookup = _column_table_lookup_from_schema_columns(column_universe)

    columns = set()

    # 1. Qualified references: alias.column or table.column
    for left, right in re.findall(r"\b([a-zA-Z_][\w]*)\.([a-zA-Z_][\w]*)\b", sql_clean):
        left_norm = _normalise_identifier(left)
        right_norm = _normalise_identifier(right)

        if left_norm in _SQL_KEYWORDS or right_norm in _SQL_KEYWORDS:
            continue

        if resolve_aliases and left_norm not in alias_map:
            continue

        table = alias_map.get(left_norm, left_norm)
        col = f"{table}.{right_norm}"

        if filter_to_schema:
            if table_universe is not None and table not in table_universe:
                continue
            if column_universe is not None and col not in column_universe:
                continue

        columns.add(col)

    # 2. Unqualified references, useful for standard TPC-DS SQL.
    # Only keep columns that uniquely identify a schema table.
    if column_universe is not None:
        for token in re.findall(r"\b([a-zA-Z_][\w]*)\b", sql_clean):
            token_norm = _normalise_identifier(token)

            if token_norm in _SQL_KEYWORDS:
                continue

            candidate_tables = column_lookup.get(token_norm, set())

            if len(candidate_tables) != 1:
                continue

            table = next(iter(candidate_tables))
            col = f"{table}.{token_norm}"

            if filter_to_schema and table_universe is not None and table not in table_universe:
                continue

            columns.add(col)

    return columns

def extract_join_edges_simple(
    sql: str,
    *,
    schema_tables: Optional[Iterable[Any]] = None,
    schema_columns: Optional[Iterable[Any]] = None,
    filter_to_schema: bool = True,
) -> set[tuple[str, str]]:
    """
    Extract observed table-to-table join edges.

    Supports:
    - qualified joins: ss.ss_item_sk = i.i_item_sk
    - unqualified TPC-DS joins: ss_item_sk = i_item_sk
    """
    sql_clean = _strip_string_literals(_strip_sql_comments(sql))

    table_universe, column_universe, _ = build_schema_universe(
        schema_tables=schema_tables,
        schema_columns=schema_columns,
    )

    alias_map = extract_alias_map_simple(
        sql_clean,
        schema_tables=table_universe,
        filter_to_schema=filter_to_schema,
    )

    column_lookup = _column_table_lookup_from_schema_columns(column_universe)

    edges = set()

    # 1. Qualified equality joins.
    qualified_eq_pattern = (
        r"\b([a-zA-Z_][\w]*)\.([a-zA-Z_][\w]*)\s*=\s*"
        r"([a-zA-Z_][\w]*)\.([a-zA-Z_][\w]*)\b"
    )

    for a1, _c1, a2, _c2 in re.findall(qualified_eq_pattern, sql_clean):
        t1 = alias_map.get(_normalise_identifier(a1))
        t2 = alias_map.get(_normalise_identifier(a2))

        if not t1 or not t2 or t1 == t2:
            continue

        if filter_to_schema and table_universe is not None:
            if t1 not in table_universe or t2 not in table_universe:
                continue

        edges.add(tuple(sorted((t1, t2))))

    # 2. Unqualified equality joins.
    unqualified_eq_pattern = (
        r"\b([a-zA-Z_][\w]*)\s*=\s*([a-zA-Z_][\w]*)\b"
    )

    for c1, c2 in re.findall(unqualified_eq_pattern, sql_clean):
        c1 = _normalise_identifier(c1)
        c2 = _normalise_identifier(c2)

        if c1 in _SQL_KEYWORDS or c2 in _SQL_KEYWORDS:
            continue

        t1_candidates = column_lookup.get(c1, set())
        t2_candidates = column_lookup.get(c2, set())

        if len(t1_candidates) != 1 or len(t2_candidates) != 1:
            continue

        t1 = next(iter(t1_candidates))
        t2 = next(iter(t2_candidates))

        if t1 == t2:
            continue

        if filter_to_schema and table_universe is not None:
            if t1 not in table_universe or t2 not in table_universe:
                continue

        edges.add(tuple(sorted((t1, t2))))

    return edges


def extract_query_schema_features(
    sql: str,
    *,
    schema_tables: Optional[Iterable[Any]] = None,
    schema_columns: Optional[Iterable[Any]] = None,
    filter_to_schema: bool = True,
) -> Dict[str, set]:
    """Extract schema-level feature sets from one SQL query."""
    table_universe, column_universe, _ = build_schema_universe(
        schema_tables=schema_tables,
        schema_columns=schema_columns,
    )

    return {
        "tables": extract_table_refs_simple(
            sql,
            schema_tables=table_universe,
            filter_to_schema=filter_to_schema,
        ),
        "columns": extract_column_refs_simple(
            sql,
            schema_tables=table_universe,
            schema_columns=column_universe,
            filter_to_schema=filter_to_schema,
        ),
        "join_edges": extract_join_edges_simple(
            sql,
            schema_tables=table_universe,
            schema_columns=column_universe,
            filter_to_schema=filter_to_schema,
        ),
    }

def build_schema_features_by_query(
    queries_by_name: Dict[str, Any],
    *,
    schema_tables: Optional[Iterable[Any]] = None,
    schema_columns: Optional[Iterable[Any]] = None,
    filter_to_schema: bool = True,
) -> Dict[str, Dict[str, set]]:
    """Build schema feature sets for every query in a workload."""
    out: Dict[str, Dict[str, set]] = {}

    for qname, record in queries_by_name.items():
        sql = record.get("sql", "") if isinstance(record, dict) else str(record)
        out[str(qname)] = extract_query_schema_features(
            sql,
            schema_tables=schema_tables,
            schema_columns=schema_columns,
            filter_to_schema=filter_to_schema,
        )

    return dict(sorted(out.items(), key=lambda kv: _qid_sort_key(kv[0])))


# =============================================================================
# Schema diversity summaries
# =============================================================================


def schema_diversity_summary(
    queries_by_name: Dict[str, Any],
    *,
    schema_tables: Optional[Iterable[Any]] = None,
    schema_columns: Optional[Iterable[Any]] = None,
    schema_join_edges: Optional[Iterable[Any]] = None,
    table_weights: Optional[Dict[Any, float]] = None,
    filter_to_schema: bool = True,
) -> Dict[str, Any]:
    """Compute schema-diversity metrics for a SQL workload."""
    table_universe, column_universe, _ = build_schema_universe(
        schema_tables=schema_tables,
        schema_columns=schema_columns,
    )

    join_edge_universe = None
    if schema_join_edges is not None:
        join_edge_universe = normalise_join_edges(schema_join_edges)

    features_by_query = build_schema_features_by_query(
        queries_by_name,
        schema_tables=table_universe,
        schema_columns=column_universe,
        filter_to_schema=filter_to_schema,
    )

    table_counter: Counter = Counter()
    column_counter: Counter = Counter()
    join_edge_counter: Counter = Counter()
    table_sets: List[frozenset] = []

    for features in features_by_query.values():
        tables = set(features.get("tables", set()))
        columns = set(features.get("columns", set()))
        join_edges = set(features.get("join_edges", set()))

        table_counter.update(tables)
        column_counter.update(columns)
        join_edge_counter.update(join_edges)
        table_sets.append(frozenset(tables))

    observed_tables = set(table_counter)
    observed_columns = set(column_counter)
    observed_join_edges = set(join_edge_counter)

    normalised_table_weights = None
    if table_weights is not None:
        normalised_table_weights = {_as_clean_table_name(k): float(v) for k, v in table_weights.items()}

    unique_table_sets = set(table_sets)
    n_queries = len(features_by_query)

    return {
        "n_queries": n_queries,
        "n_tables_schema": len(table_universe) if table_universe is not None else np.nan,
        "n_columns_schema": len(column_universe) if column_universe is not None else np.nan,
        "n_join_edges_schema": len(join_edge_universe) if join_edge_universe is not None else np.nan,
        "n_tables_observed": len(observed_tables),
        "n_columns_observed": len(observed_columns),
        "n_join_edges_observed": len(observed_join_edges),
        "table_coverage": coverage_ratio(observed_tables, table_universe) if table_universe is not None else np.nan,
        "column_coverage": coverage_ratio(observed_columns, column_universe) if column_universe is not None else np.nan,
        "join_edge_coverage": coverage_ratio(observed_join_edges, join_edge_universe) if join_edge_universe is not None else np.nan,
        "complexity_weighted_table_coverage": (
            weighted_coverage_ratio(observed_tables, normalised_table_weights)
            if normalised_table_weights is not None else np.nan
        ),
        "table_usage_entropy": shannon_entropy(table_counter, normalise=True),
        "column_usage_entropy": shannon_entropy(column_counter, normalise=True),
        "join_edge_usage_entropy": shannon_entropy(join_edge_counter, normalise=True),
        "unique_table_set_count": len(unique_table_sets),
        "unique_table_set_ratio": len(unique_table_sets) / n_queries if n_queries else np.nan,
        "table_usage_counts": table_counter,
        "column_usage_counts": column_counter,
        "join_edge_usage_counts": join_edge_counter,
        "schema_features_by_query": features_by_query,
    }


# =============================================================================
# Structural diversity: plan DAGs
# =============================================================================


def operator_name(dag: Dict[str, Any], node_id: str) -> str:
    """Return operator name for a node id."""
    node = dag.get("nodes", {}).get(str(node_id))
    if not isinstance(node, dict):
        return "<MISSING_NODE>"
    return str(node.get("name", "<UNKNOWN_OP>"))


def operator_type_counts(dag: Dict[str, Any]) -> Counter:
    """Count operator types in one Trino plan DAG."""
    counts = Counter()
    for attrs in dag.get("nodes", {}).values():
        counts[str(attrs.get("name", "<UNKNOWN_OP>"))] += 1
    return counts


def operator_type_counts_many(dags: Iterable[Dict[str, Any]]) -> Counter:
    """Aggregate operator-type counts across many DAGs."""
    total = Counter()
    for dag in dags:
        total.update(operator_type_counts(dag))
    return total


def operator_pair_counts(
    dag: Dict[str, Any],
    *,
    by_type: bool = False,
    include_types: Optional[List[str]] = None,
) -> Counter:
    """Count operator pairs across DAG edges."""
    counts = Counter()
    allowed = {t.lower() for t in include_types} if include_types else None

    for src, dst, etype in iter_edges(dag):
        etype_norm = str(etype).lower()
        if allowed is not None and etype_norm not in allowed:
            continue

        src_op = operator_name(dag, src)
        dst_op = operator_name(dag, dst)

        if by_type:
            counts[(src_op, dst_op, etype_norm)] += 1
        else:
            counts[(src_op, dst_op)] += 1

    return counts


def operator_pair_counts_many(
    dags: Iterable[Dict[str, Any]],
    *,
    by_type: bool = False,
    include_types: Optional[List[str]] = None,
) -> Counter:
    """Aggregate operator-pair counts across many DAGs."""
    total = Counter()
    for dag in dags:
        total.update(operator_pair_counts(dag, by_type=by_type, include_types=include_types))
    return total


def dag_operator_names(dag: Dict[str, Any]) -> List[str]:
    """Return operator names for all nodes in a plan DAG."""
    return [str(attrs.get("name", "<UNKNOWN_OP>")) for attrs in dag.get("nodes", {}).values()]


def canonical_operator_instance(
    attrs: Dict[str, Any],
    *,
    include_descriptor: bool = True,
    include_outputs_count: bool = True,
    include_estimates: bool = False,
) -> Dict[str, Any]:
    """Canonical representation of a single operator instance."""
    out: Dict[str, Any] = {"name": str(attrs.get("name", "<UNKNOWN_OP>"))}
    if include_descriptor:
        out["descriptor"] = attrs.get("descriptor", {})
    if include_outputs_count:
        out["n_outputs"] = len(attrs.get("outputs", []) or [])
    if include_estimates:
        out["estimates"] = attrs.get("estimates", [])
    return out


def operator_instance_signature(
    attrs: Dict[str, Any],
    *,
    include_descriptor: bool = True,
    include_outputs_count: bool = True,
    include_estimates: bool = False,
) -> str:
    """Stable signature for one operator instance."""
    return stable_hash(
        canonical_operator_instance(
            attrs,
            include_descriptor=include_descriptor,
            include_outputs_count=include_outputs_count,
            include_estimates=include_estimates,
        )
    )


def operator_instance_counts(
    dag: Dict[str, Any],
    *,
    include_descriptor: bool = True,
    include_outputs_count: bool = True,
    include_estimates: bool = False,
) -> Counter:
    """Count operator instances in one DAG."""
    counts = Counter()
    for attrs in dag.get("nodes", {}).values():
        counts[operator_instance_signature(
            attrs,
            include_descriptor=include_descriptor,
            include_outputs_count=include_outputs_count,
            include_estimates=include_estimates,
        )] += 1
    return counts


def operator_instance_counts_many(
    dags: Iterable[Dict[str, Any]],
    *,
    include_descriptor: bool = True,
    include_outputs_count: bool = True,
    include_estimates: bool = False,
) -> Counter:
    """Count operator instances across many DAGs."""
    total = Counter()
    for dag in dags:
        total.update(operator_instance_counts(
            dag,
            include_descriptor=include_descriptor,
            include_outputs_count=include_outputs_count,
            include_estimates=include_estimates,
        ))
    return total


def canonical_plan_graph_signature(
    dag: Dict[str, Any],
    *,
    include_descriptors: bool = False,
    include_edge_types: bool = True,
) -> str:
    """
    Build a stable approximate plan-graph signature for uniqueness counting.
    """
    nodes = dag.get("nodes", {})
    node_labels: Dict[str, str] = {}

    for node_id, attrs in nodes.items():
        if include_descriptors:
            label_obj = canonical_operator_instance(attrs, include_descriptor=True, include_outputs_count=True)
        else:
            label_obj = {"name": str(attrs.get("name", "<UNKNOWN_OP>"))}
        node_labels[str(node_id)] = stable_hash(label_obj)

    edge_records = []
    for src, dst, etype in iter_edges(dag):
        src_label = node_labels.get(str(src), "<MISSING_SRC>")
        dst_label = node_labels.get(str(dst), "<MISSING_DST>")
        if include_edge_types:
            edge_records.append((src_label, dst_label, str(etype)))
        else:
            edge_records.append((src_label, dst_label))

    payload = {
        "node_labels": sorted(node_labels.values()),
        "edges": sorted(edge_records),
        "n_nodes": len(nodes),
        "n_edges": len(edge_records),
    }
    return stable_hash(payload)


def unique_plan_graph_count(
    dags_by_query: Dict[str, Dict[str, Any]],
    *,
    include_descriptors: bool = False,
) -> int:
    """Count unique plan-graph signatures."""
    return len({
        canonical_plan_graph_signature(dag, include_descriptors=include_descriptors)
        for dag in dags_by_query.values()
    })


def plan_graph_uniqueness_ratio(
    dags_by_query: Dict[str, Dict[str, Any]],
    *,
    include_descriptors: bool = False,
) -> float:
    """Compute unique plan graphs / valid plan graphs."""
    n = len(dags_by_query)
    if n == 0:
        return np.nan
    return unique_plan_graph_count(dags_by_query, include_descriptors=include_descriptors) / n


def dag_adjacency(
    dag: Dict[str, Any],
    *,
    include_edge_types: Optional[Iterable[str]] = ("child",),
) -> Dict[str, List[str]]:
    """Build an adjacency list from plan DAG edges."""
    allowed = {str(x).lower() for x in include_edge_types} if include_edge_types is not None else None
    adj = defaultdict(list)

    for src, dst, etype in iter_edges(dag):
        if allowed is not None and str(etype).lower() not in allowed:
            continue
        adj[str(src)].append(str(dst))

    return dict(adj)


def dag_roots(
    dag: Dict[str, Any],
    *,
    include_edge_types: Optional[Iterable[str]] = ("child",),
) -> List[str]:
    """Identify DAG roots based on incoming edge count."""
    nodes = set(str(n) for n in dag.get("nodes", {}))
    children = set()
    allowed = {str(x).lower() for x in include_edge_types} if include_edge_types is not None else None

    for _src, dst, etype in iter_edges(dag):
        if allowed is not None and str(etype).lower() not in allowed:
            continue
        children.add(str(dst))

    return sorted(nodes - children)


def operator_paths(
    dag: Dict[str, Any],
    *,
    include_edge_types: Optional[Iterable[str]] = ("child",),
    max_depth: int = 64,
) -> List[Tuple[str, ...]]:
    """Extract root-to-leaf operator paths from a DAG."""
    nodes = dag.get("nodes", {})
    adj = dag_adjacency(dag, include_edge_types=include_edge_types)
    roots = dag_roots(dag, include_edge_types=include_edge_types)
    paths: List[Tuple[str, ...]] = []

    def label(node_id: str) -> str:
        attrs = nodes.get(str(node_id), {})
        return str(attrs.get("name", "<UNKNOWN_OP>"))

    def dfs(node_id: str, path: List[str], seen: set[str]) -> None:
        if len(path) >= max_depth:
            paths.append(tuple(path))
            return

        children = adj.get(str(node_id), [])
        if not children:
            paths.append(tuple(path))
            return

        for child in children:
            child = str(child)
            if child in seen:
                continue
            dfs(child, path + [label(child)], seen | {child})

    for root in roots:
        dfs(str(root), [label(str(root))], {str(root)})

    return paths


def operator_ngrams_from_path(path: Tuple[str, ...], *, n: int = 3) -> List[Tuple[str, ...]]:
    """Convert one operator path into n-grams."""
    if len(path) < n:
        return []
    return [tuple(path[i:i + n]) for i in range(0, len(path) - n + 1)]


def operator_ngram_counts(
    dag: Dict[str, Any],
    *,
    n: int = 3,
    include_edge_types: Optional[Iterable[str]] = ("child",),
) -> Counter:
    """Count operator n-grams in one DAG."""
    counts = Counter()
    for path in operator_paths(dag, include_edge_types=include_edge_types):
        counts.update(operator_ngrams_from_path(path, n=n))
    return counts


def operator_ngram_counts_many(
    dags_by_query: Dict[str, Dict[str, Any]],
    *,
    n: int = 3,
    include_edge_types: Optional[Iterable[str]] = ("child",),
) -> Counter:
    """Count operator n-grams across a workload."""
    total = Counter()
    for dag in dags_by_query.values():
        total.update(operator_ngram_counts(dag, n=n, include_edge_types=include_edge_types))
    return total


def plan_graph_feature_counter(
    dag: Dict[str, Any],
    *,
    include_operator_types: bool = True,
    include_operator_pairs: bool = True,
    include_operator_ngrams: bool = True,
    ngram_n: int = 3,
) -> Counter:
    """Convert a DAG into a feature Counter for similarity analysis."""
    features = Counter()

    if include_operator_types:
        for op_name in dag_operator_names(dag):
            features[("op", op_name)] += 1

    if include_operator_pairs:
        for src, dst, etype in iter_edges(dag):
            features[("edge", operator_name(dag, src), operator_name(dag, dst), str(etype))] += 1

    if include_operator_ngrams:
        for gram, count in operator_ngram_counts(dag, n=ngram_n, include_edge_types=("child",)).items():
            features[("ngram", gram)] += count

    return features


def plan_similarity_matrix(
    dags_by_query: Dict[str, Dict[str, Any]],
    *,
    ngram_n: int = 3,
) -> Tuple[List[str], np.ndarray]:
    """Build a weighted-Jaccard similarity matrix over plan-graph features."""
    query_names = list(dags_by_query.keys())
    feature_counters = {
        q: plan_graph_feature_counter(dag, ngram_n=ngram_n)
        for q, dag in dags_by_query.items()
    }

    n = len(query_names)
    sim = np.eye(n, dtype=float)

    for i in range(n):
        for j in range(i + 1, n):
            s = weighted_jaccard_similarity(feature_counters[query_names[i]], feature_counters[query_names[j]])
            sim[i, j] = s
            sim[j, i] = s

    return query_names, sim


def nearest_neighbour_plan_distances(
    dags_by_query: Dict[str, Dict[str, Any]],
    *,
    ngram_n: int = 3,
) -> pd.DataFrame:
    """Find nearest-neighbour plan distance for each query."""
    query_names, sim = plan_similarity_matrix(dags_by_query, ngram_n=ngram_n)
    rows = []

    for i, qname in enumerate(query_names):
        if len(query_names) <= 1:
            rows.append({
                "query": qname,
                "nearest_query": None,
                "nearest_similarity": np.nan,
                "nearest_distance": np.nan,
            })
            continue

        sims = sim[i].copy()
        sims[i] = -np.inf
        j = int(np.argmax(sims))
        rows.append({
            "query": qname,
            "nearest_query": query_names[j],
            "nearest_similarity": float(sim[i, j]),
            "nearest_distance": float(1.0 - sim[i, j]),
        })

    return pd.DataFrame(rows)


def vendi_score_from_similarity(sim: np.ndarray, *, eps: float = 1e-12) -> float:
    """Compute a Vendi-style diversity score from a similarity matrix."""
    sim = np.asarray(sim, dtype=float)
    if sim.ndim != 2 or sim.shape[0] != sim.shape[1]:
        return np.nan

    n = sim.shape[0]
    if n == 0:
        return np.nan

    sim = (sim + sim.T) / 2.0
    eigvals = np.linalg.eigvalsh(sim)
    eigvals = np.clip(eigvals, 0.0, None)

    total = eigvals.sum()
    if total <= eps:
        return 0.0

    probs = eigvals / total
    probs = probs[probs > eps]
    return float(np.exp(-(probs * np.log(probs)).sum()))


def plan_graph_vendi_score(
    dags_by_query: Dict[str, Dict[str, Any]],
    *,
    ngram_n: int = 3,
) -> float:
    """Compute a plan-graph Vendi-style diversity score."""
    _, sim = plan_similarity_matrix(dags_by_query, ngram_n=ngram_n)
    return vendi_score_from_similarity(sim)


def structural_diversity_summary(
    dags_by_query: Dict[str, Dict[str, Any]],
    *,
    expected_operator_types: Optional[Iterable[str]] = None,
    ngram_n: int = 3,
    compute_similarity: bool = True,
) -> Dict[str, Any]:
    """Compute structural diversity metrics over plan DAGs."""
    n_queries = len(dags_by_query)
    dags = list(dags_by_query.values())

    op_type_counts = operator_type_counts_many(dags)
    op_instance_counts = operator_instance_counts_many(dags)
    op_ngram_counts = operator_ngram_counts_many(dags_by_query, n=ngram_n)

    observed_operator_types = set(op_type_counts)
    expected_operator_types_set = None
    if expected_operator_types is not None:
        expected_operator_types_set = {str(x) for x in expected_operator_types}

    summary = {
        "n_valid_plan_graphs": n_queries,
        "unique_plan_graph_count": unique_plan_graph_count(dags_by_query),
        "plan_graph_uniqueness_ratio": plan_graph_uniqueness_ratio(dags_by_query),
        "n_operator_types_observed": len(observed_operator_types),
        "operator_type_coverage": (
            coverage_ratio(observed_operator_types, expected_operator_types_set)
            if expected_operator_types_set is not None else np.nan
        ),
        "operator_type_entropy": shannon_entropy(op_type_counts, normalise=True),
        "unique_operator_instance_count": len(op_instance_counts),
        "operator_instance_entropy": shannon_entropy(op_instance_counts, normalise=True),
        "unique_operator_ngram_count": len(op_ngram_counts),
        "operator_ngram_entropy": shannon_entropy(op_ngram_counts, normalise=True),
        "operator_type_counts": op_type_counts,
        "operator_instance_counts": op_instance_counts,
        "operator_ngram_counts": op_ngram_counts,
    }

    if compute_similarity and n_queries > 1:
        nn_df = nearest_neighbour_plan_distances(dags_by_query, ngram_n=ngram_n)
        summary.update({
            "mean_nearest_neighbour_distance": float(nn_df["nearest_distance"].mean()),
            "median_nearest_neighbour_distance": float(nn_df["nearest_distance"].median()),
            "min_nearest_neighbour_distance": float(nn_df["nearest_distance"].min()),
            "plan_graph_vendi_score": plan_graph_vendi_score(dags_by_query, ngram_n=ngram_n),
            "nearest_neighbour_df": nn_df,
        })
    else:
        summary.update({
            "mean_nearest_neighbour_distance": np.nan,
            "median_nearest_neighbour_distance": np.nan,
            "min_nearest_neighbour_distance": np.nan,
            "plan_graph_vendi_score": np.nan,
            "nearest_neighbour_df": pd.DataFrame(),
        })

    return summary


# =============================================================================
# Combined workload report
# =============================================================================


def workload_diversity_report(
    *,
    queries_by_name: Dict[str, Any],
    dags_by_query: Dict[str, Dict[str, Any]],
    schema_json: Optional[Dict[str, Any]] = None,
    table_columns: Optional[Dict[str, Any]] = None,
    schema_tables: Optional[Iterable[Any]] = None,
    schema_columns: Optional[Iterable[Any]] = None,
    schema_join_edges: Optional[Iterable[Any]] = None,
    table_weights: Optional[Dict[Any, float]] = None,
    expected_operator_types: Optional[Iterable[str]] = None,
    ngram_n: int = 3,
    compute_similarity: bool = True,
) -> Dict[str, Any]:
    """
    Build a combined schema + structural diversity report for one workload.

    Preferred schema path:
        pass schema_json loaded by query_generator.load_schema(...)

    Optional:
        pass table_columns fetched using query_generator.fetch_table_columns(...)
    """
    if schema_json is not None:
        schema_universe = schema_universe_from_query_generator_schema(
            schema_json,
            table_columns=table_columns,
            include_table_weights=True,
        )
        schema_tables = schema_tables or schema_universe["schema_tables"]
        schema_columns = schema_columns or schema_universe["schema_columns"] or None
        schema_join_edges = schema_join_edges or schema_universe["schema_join_edges"]
        table_weights = table_weights or schema_universe["table_weights"]

    schema_summary = schema_diversity_summary(
        queries_by_name,
        schema_tables=schema_tables,
        schema_columns=schema_columns,
        schema_join_edges=schema_join_edges,
        table_weights=table_weights,
    )

    structural_summary = structural_diversity_summary(
        dags_by_query,
        expected_operator_types=expected_operator_types,
        ngram_n=ngram_n,
        compute_similarity=compute_similarity,
    )

    overview = {
        "n_queries_sql": len(queries_by_name),
        "n_queries_with_plans": len(dags_by_query),
        "table_coverage": schema_summary["table_coverage"],
        "column_coverage": schema_summary["column_coverage"],
        "join_edge_coverage": schema_summary["join_edge_coverage"],
        "complexity_weighted_table_coverage": schema_summary["complexity_weighted_table_coverage"],
        "table_usage_entropy": schema_summary["table_usage_entropy"],
        "column_usage_entropy": schema_summary["column_usage_entropy"],
        "join_edge_usage_entropy": schema_summary["join_edge_usage_entropy"],
        "unique_table_set_count": schema_summary["unique_table_set_count"],
        "unique_table_set_ratio": schema_summary["unique_table_set_ratio"],
        "unique_plan_graph_count": structural_summary["unique_plan_graph_count"],
        "plan_graph_uniqueness_ratio": structural_summary["plan_graph_uniqueness_ratio"],
        "n_operator_types_observed": structural_summary["n_operator_types_observed"],
        "operator_type_coverage": structural_summary["operator_type_coverage"],
        "operator_type_entropy": structural_summary["operator_type_entropy"],
        "unique_operator_instance_count": structural_summary["unique_operator_instance_count"],
        "operator_instance_entropy": structural_summary["operator_instance_entropy"],
        "unique_operator_ngram_count": structural_summary["unique_operator_ngram_count"],
        "operator_ngram_entropy": structural_summary["operator_ngram_entropy"],
        "mean_nearest_neighbour_distance": structural_summary["mean_nearest_neighbour_distance"],
        "median_nearest_neighbour_distance": structural_summary["median_nearest_neighbour_distance"],
        "min_nearest_neighbour_distance": structural_summary["min_nearest_neighbour_distance"],
        "plan_graph_vendi_score": structural_summary["plan_graph_vendi_score"],
    }

    return {
        "overview": overview,
        "schema": schema_summary,
        "structural": structural_summary,
    }


# =============================================================================
# Readable/comparable report views
# =============================================================================


def _metric_value(value: Any, *, percentage: bool = False, decimals: int = 4) -> Any:
    """Format scalar values for readable report tables."""
    try:
        if value is None or pd.isna(value):
            return np.nan
    except Exception:
        pass

    if isinstance(value, (int, np.integer)):
        return int(value)

    if isinstance(value, (float, np.floating)):
        if percentage:
            return round(float(value) * 100.0, 2)
        return round(float(value), decimals)

    return value


def diversity_overview_df(report: Dict[str, Any]) -> pd.DataFrame:
    """Return the raw overview as a one-row DataFrame."""
    return pd.DataFrame([report["overview"]])


def standard_diversity_metrics_df(
    report: Dict[str, Any],
    *,
    workload_name: Optional[str] = None,
) -> pd.DataFrame:
    """Return one row of standard comparable workload metrics."""
    o = report["overview"]
    s = report["schema"]

    row = {
        "workload": workload_name,
        "sql_queries": o["n_queries_sql"],
        "planned_queries": o["n_queries_with_plans"],
        "schema_tables": s.get("n_tables_schema", np.nan),
        "schema_columns": s.get("n_columns_schema", np.nan),
        "schema_join_edges": s.get("n_join_edges_schema", np.nan),
        "tables_observed": s.get("n_tables_observed", np.nan),
        "columns_observed": s.get("n_columns_observed", np.nan),
        "join_edges_observed": s.get("n_join_edges_observed", np.nan),
        "table_coverage_pct": _metric_value(o["table_coverage"], percentage=True),
        "column_coverage_pct": _metric_value(o["column_coverage"], percentage=True),
        "join_edge_coverage_pct": _metric_value(o["join_edge_coverage"], percentage=True),
        "weighted_table_coverage_pct": _metric_value(o["complexity_weighted_table_coverage"], percentage=True),
        "table_usage_entropy": _metric_value(o["table_usage_entropy"]),
        "column_usage_entropy": _metric_value(o["column_usage_entropy"]),
        "join_edge_usage_entropy": _metric_value(o["join_edge_usage_entropy"]),
        "unique_table_sets": o["unique_table_set_count"],
        "unique_table_set_ratio": _metric_value(o["unique_table_set_ratio"]),
        "unique_plan_graphs": o["unique_plan_graph_count"],
        "plan_uniqueness_ratio": _metric_value(o["plan_graph_uniqueness_ratio"]),
        "operator_types_observed": o["n_operator_types_observed"],
        "operator_type_coverage_pct": _metric_value(o["operator_type_coverage"], percentage=True),
        "operator_type_entropy": _metric_value(o["operator_type_entropy"]),
        "unique_operator_instances": o["unique_operator_instance_count"],
        "operator_instance_entropy": _metric_value(o["operator_instance_entropy"]),
        "unique_operator_ngrams": o["unique_operator_ngram_count"],
        "operator_ngram_entropy": _metric_value(o["operator_ngram_entropy"]),
        "mean_nn_plan_distance": _metric_value(o["mean_nearest_neighbour_distance"]),
        "median_nn_plan_distance": _metric_value(o["median_nearest_neighbour_distance"]),
        "min_nn_plan_distance": _metric_value(o["min_nearest_neighbour_distance"]),
        "plan_graph_vendi_score": _metric_value(o["plan_graph_vendi_score"]),
    }

    if workload_name is None:
        row.pop("workload")

    return pd.DataFrame([row])


def diversity_metric_long_df(report: Dict[str, Any]) -> pd.DataFrame:
    """Return a readable long-form metric table grouped by metric family."""
    o = report["overview"]
    s = report["schema"]

    rows = [
        ("workload_size", "SQL queries", o["n_queries_sql"], "count"),
        ("workload_size", "Queries with valid plans", o["n_queries_with_plans"], "count"),
        ("schema_size", "Schema tables", s.get("n_tables_schema", np.nan), "count"),
        ("schema_size", "Schema columns", s.get("n_columns_schema", np.nan), "count"),
        ("schema_size", "Schema join edges", s.get("n_join_edges_schema", np.nan), "count"),
        ("schema_observed", "Tables observed", s["n_tables_observed"], "count"),
        ("schema_observed", "Columns observed", s["n_columns_observed"], "count"),
        ("schema_observed", "Join edges observed", s["n_join_edges_observed"], "count"),
        ("schema_coverage", "Table coverage", o["table_coverage"], "ratio"),
        ("schema_coverage", "Column coverage", o["column_coverage"], "ratio"),
        ("schema_coverage", "Join-edge coverage", o["join_edge_coverage"], "ratio"),
        ("schema_coverage", "Weighted table coverage", o["complexity_weighted_table_coverage"], "ratio"),
        ("schema_balance", "Table usage entropy", o["table_usage_entropy"], "entropy"),
        ("schema_balance", "Column usage entropy", o["column_usage_entropy"], "entropy"),
        ("schema_balance", "Join-edge usage entropy", o["join_edge_usage_entropy"], "entropy"),
        ("schema_balance", "Unique table-set count", o["unique_table_set_count"], "count"),
        ("schema_balance", "Unique table-set ratio", o["unique_table_set_ratio"], "ratio"),
        ("structural_uniqueness", "Unique plan graphs", o["unique_plan_graph_count"], "count"),
        ("structural_uniqueness", "Plan uniqueness ratio", o["plan_graph_uniqueness_ratio"], "ratio"),
        ("operators", "Operator types observed", o["n_operator_types_observed"], "count"),
        ("operators", "Operator type coverage", o["operator_type_coverage"], "ratio"),
        ("operators", "Operator type entropy", o["operator_type_entropy"], "entropy"),
        ("operators", "Unique operator instances", o["unique_operator_instance_count"], "count"),
        ("operators", "Operator instance entropy", o["operator_instance_entropy"], "entropy"),
        ("operators", "Unique operator n-grams", o["unique_operator_ngram_count"], "count"),
        ("operators", "Operator n-gram entropy", o["operator_ngram_entropy"], "entropy"),
        ("plan_similarity", "Mean nearest-neighbour plan distance", o["mean_nearest_neighbour_distance"], "distance"),
        ("plan_similarity", "Median nearest-neighbour plan distance", o["median_nearest_neighbour_distance"], "distance"),
        ("plan_similarity", "Minimum nearest-neighbour plan distance", o["min_nearest_neighbour_distance"], "distance"),
        ("plan_similarity", "Plan-graph Vendi score", o["plan_graph_vendi_score"], "score"),
    ]

    df = pd.DataFrame(rows, columns=["group", "metric", "value", "unit"])

    def format_value(row: pd.Series) -> str:
        value = row["value"]
        try:
            if pd.isna(value):
                return "n/a"
        except Exception:
            pass

        if row["unit"] == "ratio":
            return f"{float(value) * 100:.2f}%"
        if row["unit"] in {"entropy", "distance", "score"}:
            return f"{float(value):.4f}"
        if row["unit"] == "count":
            return f"{int(value)}"
        return str(value)

    df["formatted"] = df.apply(format_value, axis=1)
    return df


def diversity_counter_df(counter: Counter, *, name: str, top_k: int = 20) -> pd.DataFrame:
    """Convert a Counter into a readable ranked table."""
    total = sum(counter.values())
    rows = []

    for rank, (item, count) in enumerate(counter.most_common(top_k), start=1):
        rows.append({
            "rank": rank,
            name: item,
            "count": int(count),
            "share_pct": round((count / total) * 100.0, 2) if total else np.nan,
        })

    return pd.DataFrame(rows)


def diversity_report_tables(
    report: Dict[str, Any],
    *,
    workload_name: Optional[str] = None,
    top_k: int = 20,
) -> Dict[str, pd.DataFrame]:
    """Return clean report tables instead of the full nested dict."""
    schema = report["schema"]
    structural = report["structural"]

    return {
        "standard_metrics": standard_diversity_metrics_df(report, workload_name=workload_name),
        "metric_long": diversity_metric_long_df(report),
        "top_tables": diversity_counter_df(schema["table_usage_counts"], name="table", top_k=top_k),
        "top_columns": diversity_counter_df(schema["column_usage_counts"], name="column", top_k=top_k),
        "top_join_edges": diversity_counter_df(schema["join_edge_usage_counts"], name="join_edge", top_k=top_k),
        "top_operator_types": diversity_counter_df(structural["operator_type_counts"], name="operator_type", top_k=top_k),
        "top_operator_ngrams": diversity_counter_df(structural["operator_ngram_counts"], name="operator_ngram", top_k=top_k),
        "nearest_neighbours": structural.get("nearest_neighbour_df", pd.DataFrame()),
    }


def query_level_diversity_df(
    *,
    queries_by_name: Dict[str, Any],
    dags_by_query: Optional[Dict[str, Dict[str, Any]]] = None,
    schema_json: Optional[Dict[str, Any]] = None,
    table_columns: Optional[Dict[str, Any]] = None,
    schema_tables: Optional[Iterable[Any]] = None,
    schema_columns: Optional[Iterable[Any]] = None,
) -> pd.DataFrame:
    """Build a per-query feature DataFrame for debugging."""
    if schema_json is not None:
        schema_universe = schema_universe_from_query_generator_schema(
            schema_json,
            table_columns=table_columns,
            include_table_weights=False,
        )
        schema_tables = schema_tables or schema_universe["schema_tables"]
        schema_columns = schema_columns or schema_universe["schema_columns"] or None

    schema_features = build_schema_features_by_query(
        queries_by_name,
        schema_tables=schema_tables,
        schema_columns=schema_columns,
        filter_to_schema=True,
    )

    rows = []

    for qname, features in schema_features.items():
        row = {
            "query": qname,
            "n_tables": len(features.get("tables", set())),
            "n_columns": len(features.get("columns", set())),
            "n_join_edges": len(features.get("join_edges", set())),
            "tables": sorted(features.get("tables", set())),
            "columns": sorted(features.get("columns", set())),
            "join_edges": sorted(features.get("join_edges", set())),
        }

        if dags_by_query is not None and qname in dags_by_query:
            dag = dags_by_query[qname]
            op_counts = operator_type_counts(dag)
            row.update({
                "has_plan": True,
                "n_plan_nodes": len(dag.get("nodes", {})),
                "n_plan_edges": len(dag.get("edges", [])),
                "n_operator_types": len(op_counts),
                "operator_types": sorted(op_counts.keys()),
                "plan_graph_signature": canonical_plan_graph_signature(dag),
            })
        else:
            row.update({
                "has_plan": False,
                "n_plan_nodes": np.nan,
                "n_plan_edges": np.nan,
                "n_operator_types": np.nan,
                "operator_types": [],
                "plan_graph_signature": None,
            })

        rows.append(row)

    df = pd.DataFrame(rows)
    if not df.empty:
        df["_qid_num"] = df["query"].astype(str).str.extract(r"q(\d+)", expand=False).astype(float)
        df = (
            df.sort_values(["_qid_num", "query"], na_position="last")
            .drop(columns=["_qid_num"])
            .reset_index(drop=True)
        )

    return df


def print_readable_diversity_report(
    report: Dict[str, Any],
    *,
    workload_name: Optional[str] = None,
    top_k: int = 10,
) -> None:
    """Print a compact readable report to stdout."""
    tables = diversity_report_tables(report, workload_name=workload_name, top_k=top_k)

    print("=== Standard workload diversity metrics ===")
    print(tables["standard_metrics"].to_string(index=False))
    print()
    print("=== Metric details ===")
    print(tables["metric_long"][["group", "metric", "formatted"]].to_string(index=False))
    print()
    print(f"=== Top {top_k} tables ===")
    print(tables["top_tables"].to_string(index=False))
    print()
    print(f"=== Top {top_k} schema columns ===")
    print(tables["top_columns"].to_string(index=False))
    print()
    print(f"=== Top {top_k} operator types ===")
    print(tables["top_operator_types"].to_string(index=False))
