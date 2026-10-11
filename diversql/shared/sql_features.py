"""Static, execution-free SQL features used to compare workloads from different generators on the same axes."""

from __future__ import annotations

import math
import re
from collections import Counter
from typing import Any, Dict, Iterable, List, Optional

try:  # optional, better structural signal when available
    import sqlglot
    from sqlglot import exp as _sqlglot_exp

    _HAVE_SQLGLOT = True
except Exception:  # pragma: no cover - optional dependency
    sqlglot = None
    _sqlglot_exp = None
    _HAVE_SQLGLOT = False


_WORD = re.compile(r"[A-Za-z_][A-Za-z_0-9]*")
_LINE_COMMENT = re.compile(r"--[^\n]*")
_BLOCK_COMMENT = re.compile(r"/\*.*?\*/", re.DOTALL)
_STRING_LIT = re.compile(r"'(?:[^']|'')*'")

# Keyword groups used for the regex fallback + the "complexity" bucketing.
_AGG_FUNCS = {"count", "sum", "avg", "min", "max", "stddev", "variance",
              "approx_distinct", "array_agg", "corr", "covar_pop"}
_WINDOW_HINT = {"over", "row_number", "rank", "dense_rank", "ntile", "lead",
                "lag", "first_value", "last_value", "percent_rank"}
_SET_OPS = {"union", "intersect", "except"}
_JSON_HINT = {"json_extract", "json_parse", "json_format", "json_array",
              "json_object", "json_query", "json_value"}
_REGEX_HINT = {"regexp_like", "regexp_replace", "regexp_extract", "regexp_split"}
_ARRAY_HINT = {"unnest", "array_agg", "array", "element_at", "cardinality",
               "transform", "filter", "reduce", "zip"}
_STRING_HINT = {"substr", "substring", "concat", "lower", "upper", "trim",
                "split", "length", "replace", "position", "like"}


def _strip_noise(sql: str) -> str:
    sql = _BLOCK_COMMENT.sub(" ", sql)
    sql = _LINE_COMMENT.sub(" ", sql)
    return sql


def _tokens(sql: str) -> List[str]:
    # Drop string literals so their contents don't pollute keyword counts.
    sql_wo_str = _STRING_LIT.sub(" 'lit' ", _strip_noise(sql))
    return [w.lower() for w in _WORD.findall(sql_wo_str)]


def _count_ci(sql_no_str: str, pattern: str) -> int:
    return len(re.findall(pattern, sql_no_str, flags=re.IGNORECASE))


# ---------------------------------------------------------------------------
# sqlglot-backed extraction
# ---------------------------------------------------------------------------

def _features_sqlglot(sql: str) -> Optional[Dict[str, Any]]:
    try:
        tree = sqlglot.parse_one(sql, read="trino")
    except Exception:
        try:
            tree = sqlglot.parse_one(sql)
        except Exception:
            return None
    if tree is None:
        return None

    E = _sqlglot_exp
    tables = sorted({
        t.name for t in tree.find_all(E.Table) if t.name
    })
    joins = list(tree.find_all(E.Join))
    join_types = Counter(
        (j.args.get("side") or j.args.get("kind") or "inner").lower()
        for j in joins
    )
    aggs = [
        f for f in tree.find_all(E.AggFunc)
    ]
    windows = list(tree.find_all(E.Window))
    ctes = list(tree.find_all(E.CTE))
    subqueries = list(tree.find_all(E.Subquery))
    set_ops = len(list(tree.find_all(E.Union))) + \
        len(list(tree.find_all(E.Intersect))) + \
        len(list(tree.find_all(E.Except)))
    group_by = len(list(tree.find_all(E.Group)))
    order_by = len(list(tree.find_all(E.Order)))
    having = len(list(tree.find_all(E.Having)))
    where = len(list(tree.find_all(E.Where)))
    distinct = len(list(tree.find_all(E.Distinct)))
    case_when = len(list(tree.find_all(E.Case)))
    limit = len(list(tree.find_all(E.Limit)))
    # predicate count = comparison / logical leaf predicates in WHERE/HAVING/ON
    predicate_nodes = (
        list(tree.find_all(E.EQ)) + list(tree.find_all(E.NEQ)) +
        list(tree.find_all(E.GT)) + list(tree.find_all(E.GTE)) +
        list(tree.find_all(E.LT)) + list(tree.find_all(E.LTE)) +
        list(tree.find_all(E.Like)) + list(tree.find_all(E.In)) +
        list(tree.find_all(E.Between)) + list(tree.find_all(E.Is))
    )
    columns = sorted({
        c.name for c in tree.find_all(E.Column) if c.name
    })
    functions = Counter(
        f.sql_name().lower()
        for f in tree.find_all(E.Func)
        if hasattr(f, "sql_name")
    )
    recursive = 1 if _count_ci(sql, r"\bwith\s+recursive\b") else 0

    return {
        "parsed": True,
        "parser": "sqlglot",
        "num_tables": len(tables),
        "tables": tables,
        "num_columns": len(columns),
        "num_joins": len(joins),
        "join_types": dict(join_types),
        "num_aggregations": len(aggs),
        "num_group_by": group_by,
        "num_order_by": order_by,
        "num_having": having,
        "num_where": where,
        "num_predicates": len(predicate_nodes),
        "num_subqueries": len(subqueries),
        "num_ctes": len(ctes),
        "num_window_functions": len(windows),
        "num_set_operations": set_ops,
        "num_distinct": distinct,
        "num_case_when": case_when,
        "num_limit": limit,
        "num_functions": sum(functions.values()),
        "recursive": recursive,
        "query_length_chars": len(sql),
        "query_length_tokens": len(_tokens(sql)),
    }


# ---------------------------------------------------------------------------
# regex fallback
# ---------------------------------------------------------------------------

def _features_regex(sql: str) -> Dict[str, Any]:
    clean = _strip_noise(sql)
    no_str = _STRING_LIT.sub(" 'lit' ", clean)
    toks = [w.lower() for w in _WORD.findall(no_str)]
    tok_counter = Counter(toks)

    num_joins = _count_ci(no_str, r"\bjoin\b")
    # crude table count: entries after FROM/JOIN
    from_join_tables = re.findall(
        r"\b(?:from|join)\s+([A-Za-z_][A-Za-z_0-9]*)", no_str, flags=re.IGNORECASE
    )
    tables = sorted({t.lower() for t in from_join_tables
                     if t.lower() not in {"select", "lateral", "unnest"}})

    num_agg = sum(tok_counter[a] for a in _AGG_FUNCS)
    num_window = _count_ci(no_str, r"\bover\s*\(")
    num_set = sum(tok_counter[s] for s in _SET_OPS)
    num_group = _count_ci(no_str, r"\bgroup\s+by\b")
    num_order = _count_ci(no_str, r"\border\s+by\b")
    num_having = _count_ci(no_str, r"\bhaving\b")
    num_where = _count_ci(no_str, r"\bwhere\b")
    num_cte = _count_ci(no_str, r"\bwith\b") + max(0, _count_ci(no_str, r"\)\s*,\s*[A-Za-z_][A-Za-z_0-9]*\s+as\s*\(") )
    num_distinct = _count_ci(no_str, r"\bdistinct\b")
    num_case = _count_ci(no_str, r"\bcase\b")
    num_limit = _count_ci(no_str, r"\blimit\b")
    num_subq = max(0, no_str.count("(") and _count_ci(no_str, r"\(\s*select\b"))
    # predicate count: comparison operators + IN/LIKE/BETWEEN/IS
    num_pred = (
        len(re.findall(r"[<>]=?|=|!=|<>", no_str))
        + _count_ci(no_str, r"\b(?:in|like|between|is)\b")
    )
    recursive = 1 if _count_ci(no_str, r"\bwith\s+recursive\b") else 0

    return {
        "parsed": False,
        "parser": "regex",
        "num_tables": len(tables),
        "tables": tables,
        "num_columns": 0,
        "num_joins": num_joins,
        "join_types": {},
        "num_aggregations": num_agg,
        "num_group_by": num_group,
        "num_order_by": num_order,
        "num_having": num_having,
        "num_where": num_where,
        "num_predicates": num_pred,
        "num_subqueries": num_subq,
        "num_ctes": num_cte,
        "num_window_functions": num_window,
        "num_set_operations": num_set,
        "num_distinct": num_distinct,
        "num_case_when": num_case,
        "num_limit": num_limit,
        "num_functions": sum(1 for t in toks if t in (
            _AGG_FUNCS | _WINDOW_HINT | _JSON_HINT | _REGEX_HINT
            | _ARRAY_HINT | _STRING_HINT)),
        "recursive": recursive,
        "query_length_chars": len(sql),
        "query_length_tokens": len(toks),
    }


def classify_complexity(feat: Dict[str, Any], sql: str) -> str:
    """
    SQLStorm-style low / medium / high complexity bucketing (Table 5 of the
    SQLStorm paper), reduced to the operators we can see statically.

      low    : only TableScan / Join / GroupBy / Select, <=3 joins
      medium : + Window and/or SetOperation (or more joins)
      high   : recursion, arrays/unnest, json, regex, or very large plans
    """
    toks = set(_tokens(sql))
    high_signal = (
        feat.get("recursive")
        or (toks & _JSON_HINT)
        or (toks & _REGEX_HINT)
        or ("unnest" in toks)
        or feat.get("num_joins", 0) > 8
    )
    if high_signal:
        return "high"
    medium_signal = (
        feat.get("num_window_functions", 0) > 0
        or feat.get("num_set_operations", 0) > 0
        or feat.get("num_joins", 0) > 3
        or feat.get("num_subqueries", 0) > 0
    )
    if medium_signal:
        return "medium"
    return "low"


def query_features(sql: str) -> Dict[str, Any]:
    """Static metaheuristics for a single query."""
    feat = None
    if _HAVE_SQLGLOT and sql and sql.strip():
        feat = _features_sqlglot(sql)
    if feat is None:
        feat = _features_regex(sql or "")
    feat["complexity"] = classify_complexity(feat, sql or "")
    return feat


# ---------------------------------------------------------------------------
# workload aggregation
# ---------------------------------------------------------------------------

_AGG_FIELDS = [
    "num_tables", "num_columns", "num_joins", "num_aggregations",
    "num_group_by", "num_order_by", "num_having", "num_where",
    "num_predicates", "num_subqueries", "num_ctes", "num_window_functions",
    "num_set_operations", "num_distinct", "num_case_when", "num_limit",
    "num_functions", "query_length_chars", "query_length_tokens",
]


def _stats(values: List[float]) -> Dict[str, float]:
    if not values:
        return {"min": 0, "max": 0, "mean": 0.0, "median": 0.0}
    s = sorted(values)
    n = len(s)
    mean = sum(s) / n
    median = s[n // 2] if n % 2 else (s[n // 2 - 1] + s[n // 2]) / 2
    return {
        "min": min(s),
        "max": max(s),
        "mean": round(mean, 3),
        "median": round(float(median), 3),
    }


def _entropy(counter: Counter) -> float:
    total = sum(counter.values())
    if total <= 0:
        return 0.0
    h = 0.0
    for c in counter.values():
        p = c / total
        if p > 0:
            h -= p * math.log2(p)
    return round(h, 4)


def workload_metaheuristics(
    per_query: List[Dict[str, Any]],
    *,
    schema_tables: Optional[Iterable[str]] = None,
) -> Dict[str, Any]:
    """
    Aggregate per-query features into a workload-level summary.

    Includes the distributional stats E2ETune reports, SQLStorm's complexity
    mix, plus schema table/column coverage and structural-diversity proxies
    (distinct table-sets and distinct query "skeletons").
    """
    n = len(per_query)
    dist = {}
    for field in _AGG_FIELDS:
        dist[field] = _stats([q.get(field, 0) or 0 for q in per_query])

    complexity_mix = Counter(q.get("complexity", "low") for q in per_query)

    # table coverage + usage entropy
    used_tables = Counter()
    table_sets = Counter()
    for q in per_query:
        tbls = tuple(sorted(set(q.get("tables", []) or [])))
        table_sets[tbls] += 1
        for t in tbls:
            used_tables[t] += 1

    coverage = None
    if schema_tables:
        universe = {str(t).lower() for t in schema_tables}
        covered = {t.lower() for t in used_tables} & universe
        coverage = {
            "schema_table_count": len(universe),
            "tables_used": len(covered),
            "table_coverage": round(len(covered) / len(universe), 4) if universe else 0.0,
        }

    skeletons = Counter()
    for q in per_query:
        # coarse structural skeleton for a distinctness proxy
        skeletons[(
            q.get("num_joins", 0), q.get("num_group_by", 0),
            q.get("num_window_functions", 0), q.get("num_set_operations", 0),
            q.get("num_subqueries", 0), q.get("complexity"),
        )] += 1

    return {
        "num_queries": n,
        "distributions": dist,
        "complexity_mix": dict(complexity_mix),
        "table_usage_entropy": _entropy(used_tables),
        "unique_table_sets": len(table_sets),
        "unique_table_set_ratio": round(len(table_sets) / n, 4) if n else 0.0,
        "unique_skeletons": len(skeletons),
        "unique_skeleton_ratio": round(len(skeletons) / n, 4) if n else 0.0,
        "schema_coverage": coverage,
        "feature_extractor": "sqlglot" if _HAVE_SQLGLOT else "regex",
    }
