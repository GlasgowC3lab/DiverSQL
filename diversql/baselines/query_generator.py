"""Schema loading, live DDL introspection, LLM client/retry and workload-writing helpers shared by every baseline."""
import json
import os
import random
import re
import time
import threading

from collections import defaultdict, deque
from datetime import datetime, timezone
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor, as_completed
from _thread import LockType

from openai import (
    OpenAI,
    InternalServerError,
    APIConnectionError,
    RateLimitError,
    APITimeoutError,
)

from config import WORKLOADS_DIR, SCHEMA_DIR, MODEL_NAME, BASE_MODEL_URL, API_KEY_ENV


def ensure_dir(p: Path) -> Path:
    p.mkdir(parents=True, exist_ok=True)
    return p


# ------------------------------------------------------------
# Schema loading / graph
# ------------------------------------------------------------

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


# ------------------------------------------------------------
# Trino metadata / DDL context
# ------------------------------------------------------------

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


# ------------------------------------------------------------
# Prompt context
# ------------------------------------------------------------

PROMPT_TEMPLATE = """
Schema context:
{schema_context}

Task:
Generate one unique analytical SQL query.
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

def build_schema_context(
    schema: dict,
    selected_tables: list[str],
    ddl_context: str | None = None,
) -> str:
    relationships = get_relevant_relationships(schema, selected_tables)

    relationship_lines = [
        f"- {relationship_to_text(rel)}"
        for rel in relationships
    ]

    ddl_block = ddl_context.strip() if ddl_context else "No DDL provided."

    return f"""
Dataset:
- {schema.get("name", "unknown")}
- Tables are Iceberg tables queried through Trino.

Selected tables:
{chr(10).join(f"- {table}" for table in selected_tables)}

DDL context:
{ddl_block}

Valid join rules:
{chr(10).join(relationship_lines) if relationship_lines else "- No direct joins available."}

Important SQL rules:
- Use Trino SQL syntax.
- Use only the selected tables.
- Use only columns that appear in the DDL context.
- Use only the listed join rules.
- Do not invent tables, columns, or join keys.
- Avoid SELECT *.
- Columns ending in *_date_sk are integer surrogate keys, not DATE values.
- To filter by date, join to date_dim and filter on date_dim.d_date.
- If date_dim is not one of the selected tables, do not perform DATE literal filtering.
- Prefer analytical queries with joins, filters, grouping, aggregation, or ordering.
- Do not use SELECT aliases in GROUP BY, WHERE, or HAVING.
- If a derived expression is selected and also grouped, repeat the full expression in GROUP BY or use a CTE/subquery.
- After defining a CTE or subquery alias, only reference columns explicitly projected by that CTE/subquery.
- Preserve original column names carefully when moving columns through CTEs.
- After joining tables, CTEs, or subqueries, qualify column names when the same column name may exist on both sides of the join.
- Do not reference unqualified columns if they are available from multiple joined sources.
""".strip()


# ------------------------------------------------------------
# Sanitisation
# ------------------------------------------------------------

def sanitize_sql(query: str) -> str:
    if not query:
        return query

    query = query.strip()
    query = re.sub(r"^```[a-zA-Z]*\n?", "", query)
    query = re.sub(r"\n?```$", "", query)
    query = re.sub(r";+\s*$", "", query)

    return query.strip()


def normalise_sql_result(data: dict) -> dict:
    return {
        "sql": sanitize_sql(data.get("sql", "")),
        "goal": data.get("goal", ""),
        "tables_used": data.get("tables_used", []),
        "columns_used": data.get("columns_used", []),
        "assumptions": data.get("assumptions", []),
    }


# ------------------------------------------------------------
# API helpers
# ------------------------------------------------------------

def make_openai_client(
    *,
    base_url: str = BASE_MODEL_URL,
    api_key_env: str = API_KEY_ENV,
    timeout_s: float = 600.0,
) -> OpenAI:
    return OpenAI(
        base_url=base_url,
        api_key=os.environ[api_key_env],
        timeout=timeout_s,
        max_retries=0,
    )

# ------------------------------------------------------------
# Retry observability (for adaptive concurrency control).
#
# `call_with_retry` swallows transient 5xx / timeout / rate-limit errors with a
# long retry loop. On a congested endpoint that hides contention from the caller
# (a stuck call just looks slow). These hooks surface each retry WITHOUT changing
# retry behaviour: a thread-local count (read post-call) and a set of observers
# notified in real time on every retry. Both are no-ops unless something opts in,
# so all existing callers/baselines are unaffected.
# ------------------------------------------------------------
_RETRY_TLS = threading.local()
_RETRY_OBSERVERS: list = []
_RETRY_OBSERVERS_LOCK = threading.Lock()
# Default retry budget for call_with_retry. Baselines/warmup keep the patient
# default; the generation pool lowers it (via set_retry_max_default) so contended
# calls FAIL FAST -- with an AIMD pool the pool is the backoff, and a worker that
# keeps re-sending under contention just re-adds the load the controller sheds.
_RETRY_MAX_DEFAULT = 2000


def set_retry_max_default(n: int) -> int:
    """Set the default retry budget; returns the previous value (for restore)."""
    global _RETRY_MAX_DEFAULT
    prev = _RETRY_MAX_DEFAULT
    _RETRY_MAX_DEFAULT = int(n)
    return prev


def get_retry_max_default() -> int:
    return _RETRY_MAX_DEFAULT
# Quiet the per-retry prints when observers are watching (the controller reports
# contention instead) unless QUERYDOCK_RETRY_VERBOSE is set.
_RETRY_VERBOSE = os.environ.get("QUERYDOCK_RETRY_VERBOSE", "0").strip().lower() not in (
    "", "0", "false", "no", "off",
)


def register_retry_observer(cb) -> None:
    """Register ``cb(exc)`` to be called once per transient-error retry."""
    with _RETRY_OBSERVERS_LOCK:
        _RETRY_OBSERVERS.append(cb)


def unregister_retry_observer(cb) -> None:
    with _RETRY_OBSERVERS_LOCK:
        try:
            _RETRY_OBSERVERS.remove(cb)
        except ValueError:
            pass


def last_retry_count() -> int:
    """Retries incurred by the most recent ``call_with_retry`` on THIS thread."""
    return int(getattr(_RETRY_TLS, "count", 0))


def _notify_retry(exc) -> None:
    with _RETRY_OBSERVERS_LOCK:
        observers = list(_RETRY_OBSERVERS)
    for cb in observers:
        try:
            cb(exc)
        except Exception:
            pass


def call_with_retry(
    fn,
    *,
    max_retries: int | None = None,
    sleep_s: float = 2.5,
):
    if max_retries is None:
        max_retries = _RETRY_MAX_DEFAULT

    last_error = None
    _RETRY_TLS.count = 0

    for attempt in range(max_retries):
        try:
            return fn()
        except (
            InternalServerError,
            APIConnectionError,
            RateLimitError,
            APITimeoutError,
        ) as e:
            last_error = e
            _RETRY_TLS.count = attempt + 1
            _notify_retry(e)

            if _RETRY_VERBOSE or not _RETRY_OBSERVERS:
                print(f"[API retry {attempt + 1}/{max_retries}] {type(e).__name__}: {e}")
                if attempt < max_retries - 1:
                    print(f"Sleeping {sleep_s:.1f}s before retry...")

            if attempt < max_retries - 1:
                time.sleep(sleep_s)

    raise RuntimeError(f"API call failed after {max_retries} retries") from last_error

def call_with_retry_start_up(
    fn,
    *,
    max_retries: int = 16,
    base_sleep_s: float = 10.0,
    max_sleep_s: float = 240.0,
):
    last_error = None

    for attempt in range(max_retries):
        try:
            return fn()
        except (
            InternalServerError,
            APIConnectionError,
            RateLimitError,
            APITimeoutError,
        ) as e:
            last_error = e
            sleep_s = min(base_sleep_s * (2 ** attempt), max_sleep_s)
            print(f"[API retry {attempt + 1}/{max_retries}] {type(e).__name__}: {e}")
            print(f"Sleeping {sleep_s:.1f}s before retry...")
            time.sleep(sleep_s)

    raise RuntimeError(f"API call failed after {max_retries} retries") from last_error


def warm_up_model(
    client: OpenAI,
    *,
    model_name: str = MODEL_NAME,
) -> None:
    def _call():
        return client.responses.create(
            model=model_name,
            input="Return only the word ready.",
            temperature=0,
            store=False,
        )

    result = call_with_retry_start_up(_call)
    print(f"Model warm-up response: {result.output_text.strip()}")


# ------------------------------------------------------------
# Low-level SQL generation
# ------------------------------------------------------------

def generate_sql(
    client: OpenAI,
    schema_context: str,
    *,
    reasoning: str = "medium",
    model_name: str = MODEL_NAME,
    temperature: float = 0.6,
) -> dict:
    def _call():
        return client.responses.create(
            model=model_name,
            instructions=INSTRUCTIONS_TEMPLATE,
            input=PROMPT_TEMPLATE.format(schema_context=schema_context),
            reasoning={"effort": reasoning},
            text={
                "format": {
                    "type": "json_schema",
                    "name": "sql_generation_result",
                    "strict": True,
                    "schema": {
                        "type": "object",
                        "properties": {
                            "sql": {
                                "type": "string",
                                "description": "The generated Trino SQL query."
                            },
                            "goal": {
                                "type": "string",
                                "description": "A short description of the analytical goal of the query."
                            },
                            "tables_used": {
                                "type": "array",
                                "items": {"type": "string"}
                            },
                            "columns_used": {
                                "type": "array",
                                "items": {"type": "string"}
                            }
                        },
                        "required": [
                            "sql",
                            "goal",
                            "tables_used",
                            "columns_used"
                        ],
                        "additionalProperties": False
                    }
                }
            },
            temperature=temperature,
            store=False,
        )

    result = call_with_retry(_call)
    data = json.loads(result.output_text)
    return normalise_sql_result(data)


# ------------------------------------------------------------
# Higher-level generation pipeline
# ------------------------------------------------------------

def generate_query(
    *,
    conn_factory,
    schema_json: dict,
    catalog: str,
    trino_schema: str,
    client: OpenAI,
    model_name: str = MODEL_NAME,
    temperature: float = 0.6,
    reasoning: str = "medium",
    min_tables: int = 2,
    max_tables: int = 8,
    random_seed: int | None = None,
    ddl_cache: dict[str, list[dict]] | None = None,
    ddl_cache_lock: LockType | None = None,
) -> dict:
    """
    Full single-query pipeline:
      1. sample connected tables
      2. fetch DDL context using shared thread-safe cache
      3. build schema context
      4. call model
      5. return rich metadata
    """
    if ddl_cache is None:
        ddl_cache = {}

    if ddl_cache_lock is None:
        ddl_cache_lock = threading.Lock()

    rng = random.Random(random_seed)
    n_tables = rng.randint(min_tables, max_tables)

    selected_tables = sample_connected_tables(
        schema=schema_json,
        n_tables=n_tables,
        seed=rng.randint(0, 10**9),
    )

    ddl_context = build_table_ddl_context(
        conn_factory=conn_factory,
        catalog=catalog,
        schema=trino_schema,
        tables=selected_tables,
        ddl_cache=ddl_cache,
        ddl_cache_lock=ddl_cache_lock,
    )

    schema_context = build_schema_context(
        schema=schema_json,
        selected_tables=selected_tables,
        ddl_context=ddl_context,
    )

    sql_result = generate_sql(
        client=client,
        schema_context=schema_context,
        model_name=model_name,
        temperature=temperature,
        reasoning=reasoning,
    )

    return {
        "sql": sql_result["sql"],
        "goal": sql_result["goal"],
        "tables_used": sql_result["tables_used"],
        "columns_used": sql_result["columns_used"],
        "assumptions": sql_result["assumptions"],
        "selected_tables": selected_tables,
        "ddl_context": ddl_context,
        "schema_context": schema_context,
        "prompt_template": PROMPT_TEMPLATE,
        "instructions_template": INSTRUCTIONS_TEMPLATE,
        "model_name": model_name,
        "temperature": temperature,
        "catalog": catalog,
        "schema": trino_schema,
    }


def generate_query_batch(
    *,
    conn_factory,
    schema_json: dict,
    num_queries: int,
    catalog: str,
    trino_schema: str,
    client_factory,
    model_name: str,
    temperature: float = 0.6,
    reasoning="medium",
    min_tables: int = 2,
    max_tables: int = 8,
    random_seed: int | None = None,
    ddl_cache: dict[str, list[dict]] | None = None,
    ddl_cache_lock: LockType | None = None,
    generation_workers: int = 4,
) -> list[dict]:
    rng = random.Random(random_seed)

    if ddl_cache is None:
        ddl_cache = {}

    if ddl_cache_lock is None:
        ddl_cache_lock = threading.Lock()

    thread_local = threading.local()

    def get_client():
        if not hasattr(thread_local, "client"):
            thread_local.client = client_factory()
        return thread_local.client

    seeds = [rng.randint(0, 10**9) for _ in range(num_queries)]

    def worker(seed: int) -> dict:
        return generate_query(
            conn_factory=conn_factory,
            schema_json=schema_json,
            catalog=catalog,
            trino_schema=trino_schema,
            client=get_client(),
            model_name=model_name,
            temperature=temperature,
            reasoning=reasoning,
            min_tables=min_tables,
            max_tables=max_tables,
            random_seed=seed,
            ddl_cache=ddl_cache,
            ddl_cache_lock=ddl_cache_lock,
        )

    queries: list[dict] = []

    with ThreadPoolExecutor(max_workers=min(generation_workers, num_queries)) as executor:
        futures = [executor.submit(worker, seed) for seed in seeds]
        time.sleep(0.1)

        for future in as_completed(futures):
            try:
                queries.append(future.result())
            except Exception as e:
                print(f"[generation failed] {type(e).__name__}: {e}")

    return queries




def write_workload_directory(
    *,
    workload_name: str,
    queries: list[dict],
    schema_json: dict,
    catalog: str,
    trino_schema: str,
    model_name: str,
    base_url: str,
    temperature: float,
    min_tables: int,
    max_tables: int,
    random_seed: int | None,
    workload_root: str | Path = WORKLOADS_DIR,
    started_at: datetime | None = None,
    extra_report_fields: dict | None = None,
) -> dict:
    if started_at is None:
        started_at = datetime.now(timezone.utc)

    workload_root = Path(workload_root)
    workload_dir = ensure_dir(workload_root / workload_name)

    prompt_examples = []

    for i, query_meta in enumerate(queries, start=1):
        query_name = f"q{i}"
        sql_path = workload_dir / f"{query_name}.sql"
        sql_path.write_text(query_meta["sql"].strip() + "\n", encoding="utf-8")

        query_meta["query_name"] = query_name
        query_meta["file"] = str(sql_path)

        if i <= 3:
            prompt_examples.append({
                "query_name": query_name,
                "selected_tables": query_meta["selected_tables"],
                "schema_context": query_meta["schema_context"],
                "goal": query_meta["goal"],
            })

    ended_at = datetime.now(timezone.utc)

    report = {
        "workload_name": workload_name,
        "workload_dir": str(workload_dir),
        "created_at_utc": started_at.isoformat(),
        "completed_at_utc": ended_at.isoformat(),
        "duration_s": (ended_at - started_at).total_seconds(),
        "num_queries": len(queries),
        "model": {
            "name": model_name,
            "base_url": base_url,
            "temperature": temperature,
        },
        "schema": {
            "catalog": catalog,
            "schema": trino_schema,
            "dataset_name": schema_json.get("name"),
        },
        "selection": {
            "min_tables": min_tables,
            "max_tables": max_tables,
            "random_seed": random_seed,
        },
        "prompting": {
            "instructions_template": INSTRUCTIONS_TEMPLATE,
            "prompt_template": PROMPT_TEMPLATE,
            "semantic_fields": ["goal"],
        },
        "queries": [
            {
                "query_name": q["query_name"],
                "file": q["file"],
                "sql": q["sql"],
                "goal": q["goal"],
                "selected_tables": q["selected_tables"],
                "tables_used": q["tables_used"],
                "columns_used": q["columns_used"],
                "assumptions": q["assumptions"],
            }
            for q in queries
        ],
        "prompt_examples": prompt_examples,
    }

    if extra_report_fields:
        report.update(extra_report_fields)

    report_path = workload_dir / "generation_report.json"
    report_path.write_text(json.dumps(report, indent=2), encoding="utf-8")

    return report

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