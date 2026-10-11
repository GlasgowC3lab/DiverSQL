"""
A query's prompt has three parts, with a single unified construct-selection step:

  1. FAMILY     (PROMPT_VARIANTS) -- what KIND of query. Base task text, table-count
                                     band.
  2. CONSTRUCTS (CONSTRUCTS)      -- ONE operator-grounded catalog (clause constructs
                                     + operator levers). The feedback policy draws a
                                     small, coverage-weighted subset per query 
                                     (feedback.choose_constructs), appended as
                                     "Additionally: - ...". FINISHERS (order_by,
                                     limit) are cheap and rolled independently.
  3. PLAN-SHAPE (PLAN_SHAPES)     -- a pure join TOPOLOGY hint for join_all families.

"""
import random

from .schema import get_relevant_relationships, relationship_to_text
from .operator_space import LEVERS

# ============================================================
# Templates
# ============================================================

PROMPT_TEMPLATE = """
Schema context:
{schema_context}

Task:
{task}
""".strip()

INSTRUCTIONS_TEMPLATE = """
You are an expert SQL generation system.

Generate one valid Trino SQL query using only the provided schema context.
Do not invent tables, columns, or join keys.
Use explicit JOIN syntax.
Avoid SELECT *.
Also provide:
- goal: a short description of the analytical purpose of the query
Return a structured JSON response.
""".strip()

_SQL_RULES = """
Important SQL rules:
- Use Trino SQL syntax.
- Use only the selected tables.
- Use only columns that appear in the DDL context.
- Use only the listed join rules.
- Do not invent tables, columns, or join keys.
- Avoid SELECT *.
- Unless the task explicitly asks for a simple query, produce a non-trivial analytical query (joins, filtering, grouping, aggregation and/or ordering) and vary the query shape from previous queries.
- Columns ending in *_date_sk are integer surrogate keys, not DATE values.
- Only filter on DATE literals via a DATE-typed column shown in the DDL context.
- Do not use SELECT aliases in GROUP BY, WHERE, or HAVING.
- If a derived expression is selected and also grouped, repeat the full expression in GROUP BY or use a CTE/subquery.
- After defining a CTE or subquery alias, only reference columns explicitly projected by that CTE/subquery.
- Preserve original column names carefully when moving columns through CTEs.
- After joining tables, CTEs, or subqueries, qualify column names when the same column name may exist on both sides of the join.
- Do not reference unqualified columns if they are available from multiple joined sources.
""".strip()

# ============================================================
# 1. Prompt families -- weights are final.
# ============================================================

PROMPT_VARIANTS: list[dict] = [
    {
        "name": "simple", "weight": 0.10, "temp_delta": -0.2,
        "n_tables_range": (1, 2), "join_all": False,
        "task": (
            "Generate one simple SQL query: scan one table (or two tables with a "
            "single join), apply one or two selective filter predicates using "
            "realistic literals, and project a small set of columns, optionally "
            "with one aggregate. Do not use subqueries, window functions, or set "
            "operations."
        ),
    },
    {
        "name": "core_analytical", "weight": 0.20, "temp_delta": 0.0,
        "n_tables_range": None, "join_all": True,
        "task": (
            "Generate one analytical SQL query that joins all {n_tables} selected "
            "tables using only the listed join rules, applies at least "
            "{k_predicates} selective filter predicates with realistic literals, "
            "and groups and aggregates measures (SUM / AVG / COUNT / MIN / MAX)."
        ),
    },
    {
        "name": "windows_ranking", "weight": 0.16, "temp_delta": +0.2,
        "n_tables_range": None, "join_all": True,
        "task": (
            "Generate one analytical SQL query that joins all {n_tables} selected "
            "tables using only the listed join rules, applies at least "
            "{k_predicates} filter predicates, and ranks or compares rows with "
            "window functions (RANK, DENSE_RANK, ROW_NUMBER, or moving aggregates "
            "over a window frame), optionally combined with CASE WHEN logic."
        ),
    },
    {
        "name": "nested_aggregation", "weight": 0.14, "temp_delta": +0.1,
        "n_tables_range": None, "join_all": True,
        "task": (
            "Generate one analytical SQL query that joins all {n_tables} selected "
            "tables using only the listed join rules, aggregates in a CTE or "
            "derived subquery, and then aggregates or filters over that result "
            "again (e.g. an average of per-group sums, or HAVING against a derived "
            "aggregate). Apply at least {k_predicates} filter predicates."
        ),
    },
    {
        "name": "set_operations", "weight": 0.16, "temp_delta": +0.2,
        "n_tables_range": None, "join_all": False,
        "task": (
            "Generate one analytical SQL query built around a set operation "
            "(UNION, UNION ALL, INTERSECT, or EXCEPT) that combines two or more "
            "sub-selects over the selected tables, each with joins and filter "
            "predicates where the join rules allow."
        ),
    },
    {
        "name": "multi_role_joins", "weight": 0.12, "temp_delta": +0.2,
        "n_tables_range": "high", "join_all": True,
        "task": (
            "Generate one deep-join analytical SQL query: join all {n_tables} "
            "selected tables using the listed join rules, and additionally reuse "
            "at least two of the tables under different aliases in different roles "
            "(for example, the same dimension joined twice through the same join "
            "rule for two different purposes), so that the query contains at least "
            "9 join clauses in total. Aggregate and group the result. If 9 joins "
            "are not achievable with the listed rules, use as many as they allow."
        ),
    },
    {
        "name": "string_regex", "weight": 0.12, "temp_delta": +0.2,
        "n_tables_range": None, "join_all": False,
        "task": (
            "Generate one analytical SQL query that exercises string processing on "
            "the selected tables: use regexp_like or regexp_extract on a text "
            "column, plus LIKE pattern matching, concatenation, or substring "
            "manipulation in predicates and projections, combined with joins and "
            "aggregation where the join rules allow."
        ),
    },
]
if abs(sum(v["weight"] for v in PROMPT_VARIANTS) - 1.0) > 1e-6:
    raise ValueError("family weights must sum to 1.0")

# ============================================================
# 2. Constructs
#
#    Each construct: name, prompt line, the plan operator it targets (None for
#    pure-clause shaping), reliability, and whether it may fire for "simple".
#    The operator-grounded entries come straight from the lever map so there is a
#    single source of truth for construct->operator.
# ============================================================

# Pure-clause constructs (shape the query; no single distinct structural operator).
_CLAUSE_CONSTRUCTS: list[dict] = [
    {"name": "cte", "target_operator": None, "reliability": "guaranteed", "simple_ok": False,
     "line": "Structure part of the query as a CTE (WITH clause)."},
    {"name": "subquery", "target_operator": None, "reliability": "guaranteed", "simple_ok": False,
     "line": "Include at least one subquery (scalar, IN, or EXISTS)."},
    {"name": "case_when", "target_operator": None, "reliability": "guaranteed", "simple_ok": False,
     "line": "Use a CASE WHEN expression in the projection or aggregation."},
    {"name": "having", "target_operator": "Aggregate", "reliability": "guaranteed", "simple_ok": False,
     "line": "Filter groups with a HAVING clause."},
    {"name": "distinct", "target_operator": "MarkDistinct", "reliability": "conditional", "simple_ok": True,
     "line": "Use DISTINCT somewhere meaningful."},
]

FINISHERS: list[dict] = [
    {"name": "order_by", "p": 0.75, "line": "Order the final result."},
    {"name": "limit", "p": 0.85, "line": "End the query with LIMIT 100."},
]


# Unified catalog = clause constructs + operator levers.
# Feedback selects a budgeted subset of this.
CONSTRUCTS: list[dict] = _CLAUSE_CONSTRUCTS + [
    {"name": lv.lever_id, "line": lv.prompt_hint, "target_operator": lv.target_operator,
     "reliability": lv.reliability, "simple_ok": False}
    for lv in LEVERS if lv.lever_id != "order_by_limit"
]

# ============================================================
# 3. Plan shapes -- pure join TOPOLOGY hints (join_all families).
# ============================================================

PLAN_SHAPES: list[dict] = [
    {"name": "default", "weight": 0.40, "line": None},
    {"name": "star", "weight": 0.20,
     "line": ("Join shape: use a star topology -- pick the single largest "
              "(fact) table and join every other selected table directly to it.")},
    {"name": "chain", "weight": 0.20,
     "line": ("Join shape: use a chain/path topology -- each table joins to the "
              "previously joined table, forming a left-deep chain.")},
    {"name": "pre_aggregate", "weight": 0.20,
     "line": ("Join shape: pre-aggregate at least one table inside a CTE "
              "(GROUP BY + aggregate) BEFORE joining it to the others.")},
]
if abs(sum(p["weight"] for p in PLAN_SHAPES) - 1.0) > 1e-6:
    raise ValueError("plan-shape weights must sum to 1.0")


# ============================================================
# Draw + render
# ============================================================

def sample_shape_spec(rng: random.Random) -> dict:
    """Draw a family, roll the cheap finishers, and (for join_all families) draw a
    topology. The BUDGETED, coverage-weighted constructs are added afterwards by
    feedback.FeedbackPolicy.choose_constructs -- one coherent selection instead of
    rolling every construct independently."""
    family = rng.choices(PROMPT_VARIANTS, weights=[v["weight"] for v in PROMPT_VARIANTS], k=1)[0]

    addons = []
    if family["name"] != "simple":
        for f in FINISHERS:
            if rng.random() < f["p"]:
                addons.append({"name": f["name"], "line": f["line"]})

    plan_shape = None
    if family.get("join_all"):
        plan_shape = rng.choices(PLAN_SHAPES, weights=[p["weight"] for p in PLAN_SHAPES], k=1)[0]

    return {"family": family, "addons": addons, "plan_shape": plan_shape}


def build_task_text(spec: dict, *, n_tables: int, rng: random.Random,
                    has_join_rules: bool) -> str:
    """Render the family task + add-on lines + plan-shape line into one task.
    ``spec["addons"]`` already includes any deficit-hint lines the feedback policy
    injected, so they render exactly like the sampled add-ons."""
    family = spec["family"]
    k_predicates = rng.randint(3, 6)
    task = family["task"].format(n_tables=n_tables, k_predicates=k_predicates)

    if not has_join_rules and family["join_all"]:
        task += " If no join rules are listed, use the tables independently."

    lines = [a["line"] for a in spec["addons"] if a.get("line")]
    if lines:
        task += "\nAdditionally:\n" + "\n".join(f"- {l}" for l in lines)

    plan_shape = spec.get("plan_shape")
    if plan_shape and plan_shape.get("line"):
        task += "\n" + plan_shape["line"]
    return task


def build_schema_context(
    schema: dict,
    selected_tables: list[str],
    ddl_context: str | None = None,
    value_aid: str = "",
) -> str:
    relationships = get_relevant_relationships(schema, selected_tables)
    relationship_lines = [f"- {relationship_to_text(rel)}" for rel in relationships]
    ddl_block = ddl_context.strip() if ddl_context else "No DDL provided."
    aid_block = f"\n\n{value_aid}" if value_aid else ""

    return f"""
Dataset:
- {schema.get("name", "unknown")}
- Tables are Iceberg tables queried through Trino.

Selected tables:
{chr(10).join(f"- {table}" for table in selected_tables)}

DDL context:
{ddl_block}

Valid join rules:
{chr(10).join(relationship_lines) if relationship_lines else "- No direct joins available."}{aid_block}

{_SQL_RULES}
""".strip()
