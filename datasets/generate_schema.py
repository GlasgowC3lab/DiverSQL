"""
Database-agnostic schema relationship inference using Trino.

Output format:

{
  "name": "imdb",
  "csv_kwargs": {"sep": "|"},
  "tables": [...],
  "relationships": [
    ["child_table", ["child_col"], "parent_table", ["parent_col"]]
  ],
  "ambiguous_relationships": [...]
}
"""

import argparse
import json
import re
from dataclasses import dataclass
from difflib import SequenceMatcher
from pathlib import Path
from typing import Any

import trino


# ---------------------------------------------------------------------
# Data structures
# ---------------------------------------------------------------------

@dataclass(frozen=True)
class ColumnInfo:
    table: str
    name: str
    type: str


@dataclass(frozen=True)
class ParentKeyProfile:
    table: str
    column: str
    non_null_rows: int | None
    approx_distinct: int | None
    uniqueness_ratio: float | None


@dataclass(frozen=True)
class RelationshipCandidate:
    child_table: str
    child_col: str
    parent_table: str
    parent_col: str
    name_score: float
    reason: str


@dataclass(frozen=True)
class RelationshipResult:
    child_table: str
    child_col: str
    parent_table: str
    parent_col: str
    name_score: float
    sampled_rows: int
    matched_rows: int
    match_ratio: float | None
    parent_uniqueness_ratio: float | None
    confidence_score: float
    reason: str


# ---------------------------------------------------------------------
# SQL helpers
# ---------------------------------------------------------------------

def quote_ident(identifier: str) -> str:
    return '"' + identifier.replace('"', '""') + '"'


def fq_table(catalog: str, schema: str, table: str) -> str:
    return f"{quote_ident(catalog)}.{quote_ident(schema)}.{quote_ident(table)}"


def run_query(conn, sql: str) -> list[tuple[Any, ...]]:
    cur = conn.cursor()
    cur.execute(sql)
    return cur.fetchall()


# ---------------------------------------------------------------------
# Trino metadata
# ---------------------------------------------------------------------

def list_tables(conn, catalog: str, schema: str) -> list[str]:
    sql = f"SHOW TABLES FROM {quote_ident(catalog)}.{quote_ident(schema)}"
    rows = run_query(conn, sql)
    return sorted(str(row[0]) for row in rows)


def describe_table(conn, catalog: str, schema: str, table: str) -> list[ColumnInfo]:
    sql = f"DESCRIBE {fq_table(catalog, schema, table)}"
    rows = run_query(conn, sql)

    cols: list[ColumnInfo] = []

    for row in rows:
        col_name = row[0]
        col_type = row[1]

        if not col_name:
            continue

        if str(col_name).startswith("$"):
            continue

        cols.append(
            ColumnInfo(
                table=table,
                name=str(col_name),
                type=str(col_type),
            )
        )

    return cols


def load_schema_metadata(conn, catalog: str, schema: str) -> dict[str, list[ColumnInfo]]:
    tables = list_tables(conn, catalog, schema)
    metadata: dict[str, list[ColumnInfo]] = {}

    for table in tables:
        metadata[table] = describe_table(conn, catalog, schema, table)

    return metadata


# ---------------------------------------------------------------------
# Generic normalisation
# ---------------------------------------------------------------------

def split_tokens(name: str) -> list[str]:
    name = name.lower()
    name = re.sub(r"[^a-z0-9]+", "_", name)
    return [t for t in name.split("_") if t]


def singularise_token(token: str) -> str:
    if token.endswith("ies") and len(token) > 3:
        return token[:-3] + "y"
    if token.endswith("ses") and len(token) > 3:
        return token[:-2]
    if token.endswith("s") and len(token) > 3:
        return token[:-1]
    return token


def normalise_name(name: str) -> str:
    tokens = [singularise_token(t) for t in split_tokens(name)]
    return "_".join(tokens)


def strip_key_suffix(col: str) -> str:
    c = normalise_name(col)

    for suffix in ["_id", "_key", "_sk"]:
        if c.endswith(suffix):
            return c[: -len(suffix)]

    if c != "id" and c.endswith("id") and len(c) > 3:
        return c[:-2]

    if c == "id":
        return ""

    return c


def name_similarity(a: str, b: str) -> float:
    a_norm = normalise_name(a)
    b_norm = normalise_name(b)

    if not a_norm or not b_norm:
        return 0.0

    if a_norm == b_norm:
        return 1.0

    if a_norm in b_norm or b_norm in a_norm:
        return 0.85

    return SequenceMatcher(None, a_norm, b_norm).ratio()


# ---------------------------------------------------------------------
# Type and key heuristics
# ---------------------------------------------------------------------

def is_numeric_or_date_like_type(type_name: str) -> bool:
    t = type_name.lower()

    return any(
        x in t
        for x in [
            "tinyint",
            "smallint",
            "integer",
            "bigint",
            "decimal",
            "double",
            "real",
            "date",
        ]
    )


def is_string_like_type(type_name: str) -> bool:
    t = type_name.lower()

    return any(x in t for x in ["varchar", "char", "string"])


def types_are_compatible(a: ColumnInfo, b: ColumnInfo) -> bool:
    a_type = a.type.lower()
    b_type = b.type.lower()

    a_numeric = is_numeric_or_date_like_type(a_type)
    b_numeric = is_numeric_or_date_like_type(b_type)

    a_string = is_string_like_type(a_type)
    b_string = is_string_like_type(b_type)

    if a_numeric and b_numeric:
        return True

    if a_string and b_string:
        return True

    # Allow numeric/string mismatch for identifier-like columns.
    if is_identifier_like_column(a.name) and is_identifier_like_column(b.name):
        return True

    return False


def is_identifier_like_column(col: str) -> bool:
    c = normalise_name(col)

    if c == "id":
        return True

    return (
        c.endswith("_id")
        or c.endswith("_key")
        or c.endswith("_sk")
        or c.endswith("key")
        or (c.endswith("id") and len(c) > 3)
    )

def is_parent_key_candidate(col: ColumnInfo) -> bool:
    c = normalise_name(col.name)

    if c == "id":
        return True

    if c.endswith("_id") or c.endswith("_key") or c.endswith("_sk"):
        return True

    if c.endswith("key"):
        return True

    return False


def is_child_fk_candidate(col: ColumnInfo) -> bool:
    c = normalise_name(col.name)

    # Bare id is usually the primary key of its own table.
    if c == "id":
        return False

    if c.endswith("_id") or c.endswith("_key") or c.endswith("_sk"):
        return True

    if c.endswith("key"):
        return True

    # Handles compact names:
    # userid, postid, relatedpostid, owneruserid, lasteditoruserid
    if c.endswith("id") and len(c) > 3:
        return True

    # Keep date-like keys, e.g. lo_orderdate -> d_datekey.
    if "date" in c and is_numeric_or_date_like_type(col.type):
        return True

    return False


# ---------------------------------------------------------------------
# Parent key profiling
# ---------------------------------------------------------------------

def profile_parent_key(
    conn,
    *,
    catalog: str,
    schema: str,
    col: ColumnInfo,
) -> ParentKeyProfile:
    table_fq = fq_table(catalog, schema, col.table)
    col_q = quote_ident(col.name)

    sql = f"""
    SELECT
        COUNT({col_q}) AS non_null_rows,
        approx_distinct({col_q}) AS approx_distinct_values
    FROM {table_fq}
    WHERE {col_q} IS NOT NULL
    """

    try:
        rows = run_query(conn, sql)
        non_null_rows = int(rows[0][0])
        approx_distinct = int(rows[0][1])

        uniqueness_ratio = (
            approx_distinct / non_null_rows
            if non_null_rows > 0
            else None
        )

        return ParentKeyProfile(
            table=col.table,
            column=col.name,
            non_null_rows=non_null_rows,
            approx_distinct=approx_distinct,
            uniqueness_ratio=uniqueness_ratio,
        )

    except Exception as e:
        print(f"[warn] Could not profile parent key {col.table}.{col.name}: {e}")

        return ParentKeyProfile(
            table=col.table,
            column=col.name,
            non_null_rows=None,
            approx_distinct=None,
            uniqueness_ratio=None,
        )


def build_parent_key_profiles(
    conn,
    *,
    catalog: str,
    schema: str,
    parent_cols: list[ColumnInfo],
) -> dict[tuple[str, str], ParentKeyProfile]:
    profiles: dict[tuple[str, str], ParentKeyProfile] = {}

    for col in parent_cols:
        print(f"Profiling parent key candidate {col.table}.{col.name}")
        profiles[(col.table, col.name)] = profile_parent_key(
            conn,
            catalog=catalog,
            schema=schema,
            col=col,
        )

    return profiles


# ---------------------------------------------------------------------
# Candidate generation
# ---------------------------------------------------------------------

def generic_name_score(child: ColumnInfo, parent: ColumnInfo) -> tuple[float, str]:
    child_base = strip_key_suffix(child.name)
    parent_table = normalise_name(parent.table)
    parent_col_base = strip_key_suffix(parent.name)

    child_tokens = set(split_tokens(child_base))
    parent_table_tokens = set(split_tokens(parent_table))
    parent_col_tokens = set(split_tokens(parent_col_base))

    if child_base and child_base == parent_table:
        return 1.0, "child_key_prefix_matches_parent_table"

    if child_base and child_base == parent_col_base:
        return 0.95, "child_key_prefix_matches_parent_key"

    if child_tokens and parent_table_tokens and child_tokens & parent_table_tokens:
        return 0.80, "child_key_tokens_overlap_parent_table"

    if child_tokens and parent_col_tokens and child_tokens & parent_col_tokens:
        return 0.75, "child_key_tokens_overlap_parent_key"

    sim_table = name_similarity(child_base, parent_table)
    sim_col = name_similarity(child_base, parent_col_base)
    sim = max(sim_table, sim_col)

    if sim >= 0.70:
        return sim, "fuzzy_name_similarity"

    # Allow data-driven candidates even with weak names.
    # These are later accepted only if data evidence is strong and unambiguous.
    return 0.0, "data_only"


def generate_candidates(
    metadata: dict[str, list[ColumnInfo]],
    *,
    min_name_score: float,
    include_data_only_candidates: bool,
) -> list[RelationshipCandidate]:
    all_columns = [c for cols in metadata.values() for c in cols]

    child_cols = [c for c in all_columns if is_child_fk_candidate(c)]
    parent_cols = [c for c in all_columns if is_parent_key_candidate(c)]

    candidates: list[RelationshipCandidate] = []

    for child in child_cols:
        for parent in parent_cols:
            if child.table == parent.table:
                continue

            if not types_are_compatible(child, parent):
                continue

            score, reason = generic_name_score(child, parent)

            if score >= min_name_score or include_data_only_candidates:
                candidates.append(
                    RelationshipCandidate(
                        child_table=child.table,
                        child_col=child.name,
                        parent_table=parent.table,
                        parent_col=parent.name,
                        name_score=score,
                        reason=reason,
                    )
                )

    # Deduplicate
    seen = set()
    deduped: list[RelationshipCandidate] = []

    for c in candidates:
        key = (c.child_table, c.child_col, c.parent_table, c.parent_col)

        if key in seen:
            continue

        seen.add(key)
        deduped.append(c)

    return sorted(
        deduped,
        key=lambda x: (
            -x.name_score,
            x.child_table,
            x.child_col,
            x.parent_table,
            x.parent_col,
        ),
    )


# ---------------------------------------------------------------------
# Candidate validation
# ---------------------------------------------------------------------

def validate_candidate(
    conn,
    *,
    catalog: str,
    schema: str,
    candidate: RelationshipCandidate,
    parent_profile: ParentKeyProfile | None,
    sample_percent: float,
    sample_limit: int,
    use_cast_to_varchar: bool,
) -> RelationshipResult:
    child_table_fq = fq_table(catalog, schema, candidate.child_table)
    parent_table_fq = fq_table(catalog, schema, candidate.parent_table)

    child_col_q = quote_ident(candidate.child_col)
    parent_col_q = quote_ident(candidate.parent_col)

    if use_cast_to_varchar:
        child_expr = f"CAST({child_col_q} AS VARCHAR)"
        parent_expr = f"CAST({parent_col_q} AS VARCHAR)"
    else:
        child_expr = child_col_q
        parent_expr = parent_col_q

    table_sample_clause = ""

    if sample_percent < 100:
        table_sample_clause = f" TABLESAMPLE BERNOULLI ({sample_percent})"

    sql = f"""
    WITH child_sample AS (
        SELECT {child_expr} AS child_value
        FROM {child_table_fq}{table_sample_clause}
        WHERE {child_col_q} IS NOT NULL
        LIMIT {sample_limit}
    ),
    parent_keys AS (
        SELECT DISTINCT {parent_expr} AS parent_value
        FROM {parent_table_fq}
        WHERE {parent_col_q} IS NOT NULL
    )
    SELECT
        COUNT(*) AS sampled_rows,
        COUNT(p.parent_value) AS matched_rows,
        CAST(COUNT(p.parent_value) AS DOUBLE) / NULLIF(COUNT(*), 0) AS match_ratio
    FROM child_sample c
    LEFT JOIN parent_keys p
        ON c.child_value = p.parent_value
    """

    rows = run_query(conn, sql)
    sampled_rows, matched_rows, match_ratio = rows[0]

    # Retry without sampling if the sample was empty.
    if int(sampled_rows) == 0 and sample_percent < 100:
        retry_sql = f"""
        WITH child_sample AS (
            SELECT {child_expr} AS child_value
            FROM {child_table_fq}
            WHERE {child_col_q} IS NOT NULL
            LIMIT {sample_limit}
        ),
        parent_keys AS (
            SELECT DISTINCT {parent_expr} AS parent_value
            FROM {parent_table_fq}
            WHERE {parent_col_q} IS NOT NULL
        )
        SELECT
            COUNT(*) AS sampled_rows,
            COUNT(p.parent_value) AS matched_rows,
            CAST(COUNT(p.parent_value) AS DOUBLE) / NULLIF(COUNT(*), 0) AS match_ratio
        FROM child_sample c
        LEFT JOIN parent_keys p
            ON c.child_value = p.parent_value
        """

        rows = run_query(conn, retry_sql)
        sampled_rows, matched_rows, match_ratio = rows[0]

    match_ratio_f = float(match_ratio) if match_ratio is not None else None

    parent_uniqueness = (
        parent_profile.uniqueness_ratio
        if parent_profile is not None
        else None
    )

    confidence_score = compute_confidence_score(
        match_ratio=match_ratio_f,
        name_score=candidate.name_score,
        parent_uniqueness_ratio=parent_uniqueness,
    )

    return RelationshipResult(
        child_table=candidate.child_table,
        child_col=candidate.child_col,
        parent_table=candidate.parent_table,
        parent_col=candidate.parent_col,
        name_score=candidate.name_score,
        sampled_rows=int(sampled_rows),
        matched_rows=int(matched_rows),
        match_ratio=match_ratio_f,
        parent_uniqueness_ratio=parent_uniqueness,
        confidence_score=confidence_score,
        reason=candidate.reason,
    )


def compute_confidence_score(
    *,
    match_ratio: float | None,
    name_score: float,
    parent_uniqueness_ratio: float | None,
) -> float:
    if match_ratio is None:
        return 0.0

    uniqueness = parent_uniqueness_ratio if parent_uniqueness_ratio is not None else 0.5

    # Data evidence dominates. Name and uniqueness break ties.
    return (
        0.70 * match_ratio
        + 0.20 * name_score
        + 0.10 * min(uniqueness, 1.0)
    )


def validate_candidates(
    conn,
    *,
    catalog: str,
    schema: str,
    candidates: list[RelationshipCandidate],
    parent_profiles: dict[tuple[str, str], ParentKeyProfile],
    sample_percent: float,
    sample_limit: int,
    use_cast_to_varchar: bool,
) -> list[RelationshipResult]:
    results: list[RelationshipResult] = []

    for i, candidate in enumerate(candidates, start=1):
        print(
            f"[{i}/{len(candidates)}] Testing "
            f"{candidate.child_table}.{candidate.child_col} -> "
            f"{candidate.parent_table}.{candidate.parent_col} "
            f"(name_score={candidate.name_score:.3f}, reason={candidate.reason})"
        )

        try:
            parent_profile = parent_profiles.get(
                (candidate.parent_table, candidate.parent_col)
            )

            result = validate_candidate(
                conn,
                catalog=catalog,
                schema=schema,
                candidate=candidate,
                parent_profile=parent_profile,
                sample_percent=sample_percent,
                sample_limit=sample_limit,
                use_cast_to_varchar=use_cast_to_varchar,
            )

            ratio = (
                f"{result.match_ratio:.4f}"
                if result.match_ratio is not None
                else "None"
            )

            parent_unique = (
                f"{result.parent_uniqueness_ratio:.4f}"
                if result.parent_uniqueness_ratio is not None
                else "None"
            )

            print(
                f"    sampled={result.sampled_rows}, "
                f"matched={result.matched_rows}, "
                f"match_ratio={ratio}, "
                f"parent_unique={parent_unique}, "
                f"confidence={result.confidence_score:.4f}"
            )

            results.append(result)

        except Exception as e:
            print(f"    [skip] Failed candidate: {e}")

    return results


# ---------------------------------------------------------------------
# Acceptance and ambiguity handling
# ---------------------------------------------------------------------

def group_results_by_child(
    results: list[RelationshipResult],
) -> dict[tuple[str, str], list[RelationshipResult]]:
    grouped: dict[tuple[str, str], list[RelationshipResult]] = {}

    for r in results:
        key = (r.child_table, r.child_col)
        grouped.setdefault(key, []).append(r)

    return grouped


def select_relationships(
    results: list[RelationshipResult],
    *,
    min_match_ratio: float,
    min_confidence: float,
    ambiguity_margin: float,
    allow_ambiguous_best: bool,
) -> tuple[list[RelationshipResult], list[dict[str, Any]]]:
    accepted: list[RelationshipResult] = []
    ambiguous: list[dict[str, Any]] = []

    grouped = group_results_by_child(results)

    for (child_table, child_col), group in grouped.items():
        viable = [
            r for r in group
            if r.match_ratio is not None
            and r.sampled_rows > 0
            and r.match_ratio >= min_match_ratio
            and r.confidence_score >= min_confidence
        ]

        if not viable:
            continue

        viable = sorted(
            viable,
            key=lambda r: (
                -r.confidence_score,
                -r.match_ratio,
                -r.name_score,
                r.parent_table,
                r.parent_col,
            ),
        )

        best = viable[0]
        second = viable[1] if len(viable) > 1 else None

        is_ambiguous = (
            second is not None
            and (best.confidence_score - second.confidence_score) < ambiguity_margin
        )

        if is_ambiguous:
            ambiguous.append(
                {
                    "child_table": child_table,
                    "child_column": child_col,
                    "candidates": [
                        relationship_result_to_debug_dict(r)
                        for r in viable[:10]
                    ],
                }
            )

            if allow_ambiguous_best:
                accepted.append(best)

        else:
            accepted.append(best)

    return accepted, ambiguous


def relationship_result_to_debug_dict(r: RelationshipResult) -> dict[str, Any]:
    return {
        "child_table": r.child_table,
        "child_col": r.child_col,
        "parent_table": r.parent_table,
        "parent_col": r.parent_col,
        "name_score": r.name_score,
        "match_ratio": r.match_ratio,
        "parent_uniqueness_ratio": r.parent_uniqueness_ratio,
        "confidence_score": r.confidence_score,
        "sampled_rows": r.sampled_rows,
        "matched_rows": r.matched_rows,
        "reason": r.reason,
    }


# ---------------------------------------------------------------------
# JSON output
# ---------------------------------------------------------------------

def build_output_json(
    *,
    dataset_name: str,
    tables: list[str],
    accepted_relationships: list[RelationshipResult],
    ambiguous_relationships: list[dict[str, Any]],
    csv_sep: str,
    include_debug: bool,
) -> dict[str, Any]:
    rel_json = [
        [
            r.child_table,
            [r.child_col],
            r.parent_table,
            [r.parent_col],
        ]
        for r in accepted_relationships
    ]

    seen = set()
    deduped = []

    for rel in rel_json:
        key = json.dumps(rel, sort_keys=True)
        if key not in seen:
            seen.add(key)
            deduped.append(rel)

    output: dict[str, Any] = {
        "name": dataset_name,
        "csv_kwargs": {
            "sep": csv_sep
        },
        "tables": tables,
        "relationships": deduped,
    }

    if include_debug:
        output["ambiguous_relationships"] = ambiguous_relationships
        output["accepted_relationship_debug"] = [
            relationship_result_to_debug_dict(r)
            for r in accepted_relationships
        ]

    return output


def print_columns(metadata: dict[str, list[ColumnInfo]]) -> None:
    print("\nDiscovered columns:")

    for table, cols in metadata.items():
        print(f"\n  {table}")
        for c in cols:
            print(f"    {c.name}: {c.type}")


def print_candidates(candidates: list[RelationshipCandidate]) -> None:
    print("\nGenerated candidates:")

    if not candidates:
        print("  None")
        return

    for c in candidates:
        print(
            f"  {c.child_table}.{c.child_col} -> "
            f"{c.parent_table}.{c.parent_col} "
            f"(name_score={c.name_score:.3f}, reason={c.reason})"
        )


def print_accepted(accepted: list[RelationshipResult]) -> None:
    print("\nAccepted relationships:")

    if not accepted:
        print("  None")
        return

    for r in accepted:
        print(
            f"  {r.child_table}.{r.child_col} -> "
            f"{r.parent_table}.{r.parent_col} "
            f"(match_ratio={r.match_ratio:.4f}, "
            f"name_score={r.name_score:.3f}, "
            f"confidence={r.confidence_score:.4f})"
        )


def print_ambiguous(ambiguous: list[dict[str, Any]]) -> None:
    print("\nAmbiguous relationships:")

    if not ambiguous:
        print("  None")
        return

    for item in ambiguous:
        print(f"  {item['child_table']}.{item['child_column']}")

        for c in item["candidates"][:5]:
            print(
                f"    -> {c['parent_table']}.{c['parent_col']} "
                f"(match_ratio={c['match_ratio']:.4f}, "
                f"name_score={c['name_score']:.3f}, "
                f"confidence={c['confidence_score']:.4f}, "
                f"reason={c['reason']})"
            )


# ---------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------

def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Infer schema relationships from Trino in a database-agnostic way."
    )

    parser.add_argument("--host", default="localhost")
    parser.add_argument("--port", type=int, default=8080)
    parser.add_argument("--user", default="root")
    parser.add_argument("--http-scheme", default="http", choices=["http", "https"])

    parser.add_argument("--catalog", default="iceberg")
    parser.add_argument("--schema", required=True)
    parser.add_argument("--dataset-name", default=None)

    parser.add_argument("--output", default="schema.json")
    parser.add_argument("--csv-sep", default="|")

    parser.add_argument(
        "--sample-percent",
        type=float,
        default=0.01,
        help=(
            "Trino BERNOULLI sampling percentage. "
            "0.01 means 0.01%%. Use 100 to disable TABLESAMPLE."
        ),
    )

    parser.add_argument(
        "--sample-limit",
        type=int,
        default=100_000,
    )

    parser.add_argument(
        "--min-name-score",
        type=float,
        default=0.70,
        help=(
            "Minimum name score for name-supported candidates. "
            "Data-only candidates are controlled separately."
        ),
    )

    parser.add_argument(
        "--include-data-only-candidates",
        action="store_true",
        help=(
            "Also test candidates with no name evidence. "
            "Useful for schemas where FK names do not resemble parent table names, "
            "but can create ambiguous candidates."
        ),
    )

    parser.add_argument(
        "--min-match-ratio",
        type=float,
        default=0.98,
        help="Minimum sampled child-to-parent match ratio.",
    )

    parser.add_argument(
        "--min-confidence",
        type=float,
        default=0.80,
        help="Minimum combined confidence score.",
    )

    parser.add_argument(
        "--ambiguity-margin",
        type=float,
        default=0.03,
        help=(
            "If the best and second-best candidate for a child column are within "
            "this confidence margin, the relationship is marked ambiguous."
        ),
    )

    parser.add_argument(
        "--allow-ambiguous-best",
        action="store_true",
        help=(
            "If set, accept the best candidate even when it is ambiguous. "
            "Otherwise ambiguous candidates are reported but not added to relationships."
        ),
    )

    parser.add_argument(
        "--max-candidates",
        type=int,
        default=500,
        help="Maximum number of candidates to validate. Use 0 for all candidates.",
    )

    parser.add_argument(
        "--no-cast-to-varchar",
        action="store_true",
        help=(
            "By default validation casts both sides to VARCHAR to tolerate "
            "integer/varchar key mismatches."
        ),
    )

    parser.add_argument("--print-columns", action="store_true")
    parser.add_argument("--print-candidates", action="store_true")
    parser.add_argument("--include-debug", action="store_true")

    return parser.parse_args()


def main() -> None:
    args = parse_args()

    dataset_name = args.dataset_name or args.schema

    print("Connecting to Trino...")
    print(f"  host={args.host}")
    print(f"  port={args.port}")
    print(f"  catalog={args.catalog}")
    print(f"  schema={args.schema}")

    conn = trino.dbapi.connect(
        host=args.host,
        port=args.port,
        user=args.user,
        catalog=args.catalog,
        schema=args.schema,
        http_scheme=args.http_scheme,
    )

    print("\nLoading table/column metadata from Trino...")
    metadata = load_schema_metadata(conn, args.catalog, args.schema)

    tables = sorted(metadata.keys())

    print(f"\nDiscovered {len(tables)} tables:")
    for table in tables:
        print(f"  {table}")

    if args.print_columns:
        print_columns(metadata)

    all_columns = [c for cols in metadata.values() for c in cols]
    parent_cols = [c for c in all_columns if is_parent_key_candidate(c)]

    print(f"\nFound {len(parent_cols)} parent key candidates.")

    parent_profiles = build_parent_key_profiles(
        conn,
        catalog=args.catalog,
        schema=args.schema,
        parent_cols=parent_cols,
    )

    print("\nGenerating relationship candidates...")
    candidates = generate_candidates(
        metadata,
        min_name_score=args.min_name_score,
        include_data_only_candidates=args.include_data_only_candidates,
    )

    if args.max_candidates and args.max_candidates > 0:
        candidates = candidates[: args.max_candidates]

    print(f"Generated {len(candidates)} candidates.")

    if args.print_candidates:
        print_candidates(candidates)

    print("\nValidating candidates through Trino sampled joins...")
    results = validate_candidates(
        conn,
        catalog=args.catalog,
        schema=args.schema,
        candidates=candidates,
        parent_profiles=parent_profiles,
        sample_percent=args.sample_percent,
        sample_limit=args.sample_limit,
        use_cast_to_varchar=not args.no_cast_to_varchar,
    )

    accepted, ambiguous = select_relationships(
        results,
        min_match_ratio=args.min_match_ratio,
        min_confidence=args.min_confidence,
        ambiguity_margin=args.ambiguity_margin,
        allow_ambiguous_best=args.allow_ambiguous_best,
    )

    print_accepted(accepted)
    print_ambiguous(ambiguous)

    output = build_output_json(
        dataset_name=dataset_name,
        tables=tables,
        accepted_relationships=accepted,
        ambiguous_relationships=ambiguous,
        csv_sep=args.csv_sep,
        include_debug=args.include_debug,
    )

    output_path = Path(args.output)
    output_path.write_text(json.dumps(output, indent=2))

    print(f"\nWrote schema JSON to: {output_path.resolve()}")


if __name__ == "__main__":
    main()