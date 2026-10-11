"""
Shared infrastructure for the related-work baselines.

The design goal is *fairness*: every baseline should differ from DiverSQL
only in its generation pipeline, so all the surrounding machinery
(schema loading, live DDL introspection, LLM client + retry/back-off,
EXPLAIN validation, cost profiling, and the on-disk workload layout) is
shared here.

Two entry points build a :class:`BaselineContext`:

  * :func:`context_from_lakehouse` -- pass a live ``Lakehouse`` instance
    (exactly like ``lh.generate_workload(...)`` in the notebook).  Uses the
    Lakehouse's Trino host for validation / profiling / value sampling.

  * :func:`context_from_factories` -- pass raw ``conn_factory`` /
    ``client_factory`` callables for standalone use / testing.
"""

import json
import random
import threading
from concurrent.futures import ThreadPoolExecutor, as_completed
from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Callable, Dict, List, Optional, Tuple

from diversql.baselines.query_generator import (  # re-use helpers
    load_schema,
    make_openai_client,
    warm_up_model,
    build_table_ddl_context,
    fetch_table_columns_cached,
    build_relationship_graph,
    get_relevant_relationships,
    relationship_to_text,
    sanitize_sql,
    extract_schema_tables,
    call_with_retry,
    ensure_dir,
)
from config import (
    MODEL_NAME,
    BASE_MODEL_URL,
    API_KEY_ENV,
    WORKLOADS_DIR,
    TRINO_PORT,
    TRINO_USER,
    TRINO_QUERY_MAX_RUN_TIME,
)
from diversql.shared.sql_features import query_features, workload_metaheuristics


# ---------------------------------------------------------------------------
# Context
# ---------------------------------------------------------------------------

@dataclass
class BaselineContext:
    """Everything a baseline needs to talk to the lakehouse + the LLM."""

    schema_json: Dict[str, Any]
    trino_schema: str
    catalog: str
    conn_factory: Callable[[], Any]
    client_factory: Callable[[], Any]
    model_name: str = MODEL_NAME
    base_url: str = BASE_MODEL_URL
    temperature: float = 0.6
    reasoning: str = "medium"

    # shared thread-safe DDL cache (mirrors query_generator)
    ddl_cache: Dict[str, List[dict]] = field(default_factory=dict)
    ddl_cache_lock: "threading.Lock" = field(default_factory=threading.Lock)
    _thread_local: threading.local = field(default_factory=threading.local, repr=False)

    # thread-safe LLM token accounting. ``_token_usage`` is cumulative over the
    # ctx's lifetime; ``_token_reported`` marks what has already been written to a
    # report, so ``token_usage_delta`` scopes tokens per run even when one ctx is
    # shared across several baselines (warm-up is excluded -- it bypasses
    # ``responses_text``).
    _token_lock: "threading.Lock" = field(default_factory=threading.Lock, repr=False)
    _token_usage: Dict[str, int] = field(
        default_factory=lambda: dict(
            input_tokens=0, output_tokens=0, reasoning_tokens=0,
            total_tokens=0, calls=0, calls_without_usage=0,
        ),
        repr=False,
    )
    _token_reported: Dict[str, int] = field(
        default_factory=lambda: dict(
            input_tokens=0, output_tokens=0, reasoning_tokens=0,
            total_tokens=0, calls=0, calls_without_usage=0,
        ),
        repr=False,
    )

    # ------------------------------------------------------------------
    # LLM
    # ------------------------------------------------------------------
    def client(self):
        """Thread-local OpenAI client (safe to call from worker threads)."""
        if not hasattr(self._thread_local, "client"):
            self._thread_local.client = self.client_factory()
        return self._thread_local.client

    def warm_up(self) -> None:
        warm_up_model(self.client_factory(), model_name=self.model_name)

    def responses_text(
        self,
        *,
        instructions: str,
        prompt: str,
        temperature: Optional[float] = None,
        reasoning: Optional[str] = None,
        json_schema: Optional[dict] = None,
    ) -> str:
        """
        Single plain-text (or structured-JSON) LLM call using the same
        ``client.responses.create`` surface + retry/back-off as QueryDock.
        Returns the raw ``output_text``.
        """
        client = self.client()
        text_arg = None
        if json_schema is not None:
            text_arg = {"format": {"type": "json_schema", **json_schema}}

        def _call():
            kwargs = dict(
                model=self.model_name,
                instructions=instructions,
                input=prompt,
                reasoning={"effort": reasoning or self.reasoning},
                temperature=self.temperature if temperature is None else temperature,
                store=False,
            )
            if text_arg is not None:
                kwargs["text"] = text_arg
            return client.responses.create(**kwargs)

        result = call_with_retry(_call)
        self._record_usage(result)
        return result.output_text

    # ------------------------------------------------------------------
    # Token accounting
    # ------------------------------------------------------------------
    @staticmethod
    def _usage_get(u, *names):
        """Read a field from an OpenAI usage object OR a plain dict."""
        for n in names:
            v = u.get(n) if isinstance(u, dict) else getattr(u, n, None)
            if v is not None:
                return v
        return None

    def _record_usage(self, result) -> None:
        """Accumulate token usage from one ``responses.create`` result. Robust to
        providers that omit usage (counted under ``calls_without_usage``) and to
        Responses (input/output) vs Chat (prompt/completion) field names."""
        u = getattr(result, "usage", None)
        if u is None and isinstance(result, dict):
            u = result.get("usage")
        inp = self._usage_get(u, "input_tokens", "prompt_tokens") if u is not None else None
        out = self._usage_get(u, "output_tokens", "completion_tokens") if u is not None else None
        tot = self._usage_get(u, "total_tokens") if u is not None else None
        details = self._usage_get(u, "output_tokens_details", "completion_tokens_details") if u is not None else None
        reasoning = self._usage_get(details, "reasoning_tokens") if details is not None else None

        with self._token_lock:
            tu = self._token_usage
            tu["calls"] += 1
            if inp is not None:
                tu["input_tokens"] += int(inp)
            if out is not None:
                tu["output_tokens"] += int(out)
            if reasoning is not None:
                tu["reasoning_tokens"] += int(reasoning)
            if tot is not None:
                tu["total_tokens"] += int(tot)
            elif inp is not None or out is not None:
                tu["total_tokens"] += int(inp or 0) + int(out or 0)
            if inp is None and out is None and tot is None:
                tu["calls_without_usage"] += 1

    def token_usage_delta(self) -> Dict[str, int]:
        """Tokens consumed since the previous call, then advance the marker. Called
        once per run by the report writer so a shared ctx scopes tokens per run."""
        with self._token_lock:
            delta = {k: v - self._token_reported.get(k, 0) for k, v in self._token_usage.items()}
            self._token_reported = dict(self._token_usage)
            return delta

    # ------------------------------------------------------------------
    # Schema / DDL context (re-uses QueryDock)
    # ------------------------------------------------------------------
    def schema_tables(self) -> List[str]:
        return extract_schema_tables(self.schema_json)

    def relationship_graph(self):
        return build_relationship_graph(self.schema_json)

    def ddl_for(self, tables: List[str]) -> str:
        return build_table_ddl_context(
            conn_factory=self.conn_factory,
            catalog=self.catalog,
            schema=self.trino_schema,
            tables=tables,
            ddl_cache=self.ddl_cache,
            ddl_cache_lock=self.ddl_cache_lock,
        )

    def full_ddl(self) -> str:
        return self.ddl_for(self.schema_tables())

    def columns_for(self, table: str) -> List[dict]:
        """Column metadata for ``table``. Returns a copy, so callers may reorder
        it without affecting the shared DDL cache."""
        return list(fetch_table_columns_cached(
            conn_factory=self.conn_factory,
            catalog=self.catalog,
            schema=self.trino_schema,
            table=table,
            ddl_cache=self.ddl_cache,
            ddl_cache_lock=self.ddl_cache_lock,
        ))

    def join_rules_text(self, tables: List[str]) -> List[str]:
        rels = get_relevant_relationships(self.schema_json, tables)
        return [relationship_to_text(r) for r in rels]

    def foreign_key_text(self, tables: Optional[List[str]] = None) -> str:
        tables = tables or self.schema_tables()
        rels = get_relevant_relationships(self.schema_json, tables)
        if not rels:
            return "-- no declared foreign-key relationships between these tables"
        return "\n".join(f"- {relationship_to_text(r)}" for r in rels)

    def ddl_with_keys(
        self,
        tables: List[str],
        columns: Optional[Dict[str, List[str]]] = None,
    ) -> str:
        """
        ``CREATE TABLE`` statements for ``tables`` with the declared foreign keys
        between them as ``FOREIGN KEY ... REFERENCES`` clauses.  ``columns``
        optionally restricts each table to a subset of its columns (in schema
        order); key columns are always kept.
        """
        rels = get_relevant_relationships(self.schema_json, tables)
        key_cols: Dict[str, set] = {t: set() for t in tables}
        for lt, lcols, rt, rcols in rels:
            key_cols.setdefault(lt, set()).update(lcols)
            key_cols.setdefault(rt, set()).update(rcols)

        chunks = []
        for table in tables:
            cols = self.columns_for(table)
            if not cols:
                chunks.append(f"-- WARNING: no columns found for table {table}")
                continue
            if columns is not None and table in columns:
                keep = set(columns[table]) | key_cols.get(table, set())
                cols = [c for c in cols if c["name"] in keep]
            lines = [f"    {c['name']} {c['type']}" for c in cols]
            for lt, lcols, rt, rcols in rels:
                if lt == table:
                    lines.append(
                        f"    FOREIGN KEY ({', '.join(lcols)}) REFERENCES {rt} ({', '.join(rcols)})"
                    )
            chunks.append(f"CREATE TABLE {table} (\n" + ",\n".join(lines) + "\n);")
        return "\n\n".join(chunks)

    def key_columns(self, table: str) -> set:
        """Columns of ``table`` that take part in any declared foreign key."""
        keys = set()
        for lt, lcols, rt, rcols in self.schema_json.get("relationships", []):
            if lt == table:
                keys.update(lcols)
            if rt == table:
                keys.update(rcols)
        return keys

    # ------------------------------------------------------------------
    # Validation / cost (live Trino)
    # ------------------------------------------------------------------
    def validate_explain(self, sql: str) -> Tuple[bool, Optional[str]]:
        """
        EXPLAIN-based syntactic/semantic validation -- the same signal used by
        ``Lakehouse.validate_query_explain`` (and by E2ETune / SQLBarber /
        SQLStorm in their own pipelines).  Returns ``(ok, error_message)``.
        """
        sql = sanitize_sql(sql)
        if not sql:
            return False, "empty query"
        conn = self.conn_factory()
        try:
            cur = conn.cursor()
            try:
                cur.execute(f"EXPLAIN {sql}")
                cur.fetchall()
                return True, None
            finally:
                cur.close()
        except Exception as e:  # TrinoUserError etc.
            return False, f"{type(e).__name__}: {e}"
        finally:
            try:
                conn.close()
            except Exception:
                pass

    def explain_cost(self, sql: str) -> Optional[Dict[str, float]]:
        """
        Optimizer estimates from ``EXPLAIN (FORMAT JSON)`` -- used by the
        SQLBarber cost-aware generator.  See :func:`_estimates_from_trino_plan`
        for the returned fields.  ``None`` if the plan can't be produced/parsed
        or carries no finite estimate.
        """
        sql = sanitize_sql(sql)
        if not sql:
            return None
        conn = self.conn_factory()
        try:
            cur = conn.cursor()
            try:
                cur.execute(f"EXPLAIN (FORMAT JSON) {sql}")
                rows = cur.fetchall()
            finally:
                cur.close()
        except Exception:
            return None
        finally:
            try:
                conn.close()
            except Exception:
                pass

        if not rows:
            return None
        try:
            doc = json.loads(rows[0][0])
        except Exception:
            return None
        return _estimates_from_trino_plan(doc)

    def sample_column_values(
        self, table: str, column: str, *, limit: int = 20
    ) -> List[Any]:
        """
        Sample distinct values for a column (E2ETune's "Predicate Generation
        Aid").  Best-effort: returns ``[]`` on any error.
        """
        conn = self.conn_factory()
        try:
            cur = conn.cursor()
            try:
                cur.execute(
                    f"SELECT DISTINCT {column} FROM {self.catalog}."
                    f"{self.trino_schema}.{table} "
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

    def table_stats(self, table: str) -> Dict[str, Any]:
        """
        ``SHOW STATS`` summary for ``table`` (cheap: served from Iceberg
        metadata).  Returns ``{"row_count", "size_bytes", "columns": {name:
        distinct_values_count}}``; fields Trino does not know are ``None``.
        Best-effort: returns empty fields on error.
        """
        out: Dict[str, Any] = {"row_count": None, "size_bytes": None, "columns": {}}
        conn = self.conn_factory()
        try:
            cur = conn.cursor()
            try:
                cur.execute(f"SHOW STATS FOR {self.catalog}.{self.trino_schema}.{table}")
                rows = cur.fetchall()
                names = [d[0] for d in (cur.description or [])]
            finally:
                cur.close()
        except Exception:
            return out
        finally:
            try:
                conn.close()
            except Exception:
                pass

        size = 0.0
        have_size = False
        for row in rows:
            rec = dict(zip(names, row))
            col = rec.get("column_name")
            if col is None:
                out["row_count"] = _to_float(rec.get("row_count"))
                continue
            ndv = _to_float(rec.get("distinct_values_count"))
            out["columns"][col] = int(ndv) if ndv is not None else None
            ds = _to_float(rec.get("data_size"))
            if ds is not None:
                size += ds
                have_size = True
        out["size_bytes"] = size if have_size else None
        return out

    def validate_batch(
        self, candidates: List[dict], *, workers: int = 4
    ) -> Tuple[List[dict], List[dict]]:
        """Parallel EXPLAIN validation of a list of ``{"sql": ...}`` dicts."""
        valid: List[dict] = []
        invalid: List[dict] = []

        def worker(cand):
            ok, err = self.validate_explain(cand.get("sql", ""))
            return cand, ok, err

        with ThreadPoolExecutor(max_workers=max(1, workers)) as ex:
            futs = [ex.submit(worker, c) for c in candidates]
            for fut in as_completed(futs):
                cand, ok, err = fut.result()
                if ok:
                    valid.append(cand)
                else:
                    cand = dict(cand)
                    cand["error"] = err
                    invalid.append(cand)
        return valid, invalid


# Plan nodes that only move rows between operators / fragments (the "exchange"
# category of resources/operators_ground_truth.csv) plus the Output sink. They
# are skipped when summing per-operator estimates so rows are not double counted.
_PLUMBING_NODES = frozenset({
    "Output", "RemoteSource", "Exchange", "LocalExchange", "RemoteExchange",
    "SystemExchange", "LocalMerge", "RemoteMerge", "SystemMerge",
})


def _estimates_from_trino_plan(doc: Any) -> Optional[Dict[str, float]]:
    """
    Summarise the optimizer estimates of a Trino ``EXPLAIN (FORMAT JSON)`` plan
    (a ``{fragment_id: root_node}`` map, or a single node tree).

    Each rendered node carries an ``estimates`` list; fused nodes such as
    ``ScanFilterProject`` list one entry per fused operator, the last being the
    node's output.  Estimates Trino cannot derive are ``NaN`` and are skipped.

    Returns ``None`` when no finite estimate exists, otherwise:
      * ``output_rows``  -- estimated result cardinality (root node of fragment 0)
      * ``sum_rows``     -- sum over operator nodes of their estimated output rows
                            (the analogue of summing ``rows=`` over a PostgreSQL plan)
      * ``sum_cpu_cost`` -- sum of the estimated CPU cost of every fused operator
      * ``operator_nodes`` / ``unestimated_nodes`` -- node counts behind the sums
    """
    if isinstance(doc, dict) and "name" in doc and "children" in doc:
        roots = [("0", doc)]
    elif isinstance(doc, dict):
        roots = sorted(doc.items(), key=lambda kv: (not str(kv[0]).isdigit(), str(kv[0]).zfill(8)))
    else:
        return None

    sums = {"rows": 0.0, "cpu": 0.0}
    seen = {"rows": False, "cpu": False, "nodes": 0, "unestimated": 0}

    def visit(node):
        if not isinstance(node, dict):
            return
        ests = [e for e in (node.get("estimates") or []) if isinstance(e, dict)]
        if node.get("name") not in _PLUMBING_NODES:
            seen["nodes"] += 1
            rows = _to_float(ests[-1].get("outputRowCount")) if ests else None
            if rows is None:
                seen["unestimated"] += 1
            else:
                sums["rows"] += rows
                seen["rows"] = True
            for e in ests:
                cpu = _to_float(e.get("cpuCost"))
                if cpu is not None:
                    sums["cpu"] += cpu
                    seen["cpu"] = True
        for child in node.get("children") or []:
            visit(child)

    for _, root in roots:
        visit(root)

    output_rows = None
    if roots and isinstance(roots[0][1], dict):
        root_ests = roots[0][1].get("estimates") or []
        if root_ests and isinstance(root_ests[-1], dict):
            output_rows = _to_float(root_ests[-1].get("outputRowCount"))

    if output_rows is None and not seen["rows"] and not seen["cpu"]:
        return None
    return {
        "output_rows": output_rows,
        "sum_rows": sums["rows"] if seen["rows"] else None,
        "sum_cpu_cost": sums["cpu"] if seen["cpu"] else None,
        "operator_nodes": seen["nodes"],
        "unestimated_nodes": seen["unestimated"],
    }


def _to_float(v):
    try:
        f = float(v)
        return None if f != f or f in (float("inf"), float("-inf")) else f
    except Exception:
        return None


# ---------------------------------------------------------------------------
# Typed Trino literals
# ---------------------------------------------------------------------------

def type_kind(trino_type: str) -> str:
    """Coarse kind of a Trino ``information_schema`` data type."""
    t = (trino_type or "").strip().lower()
    if t in ("tinyint", "smallint", "integer", "int", "bigint"):
        return "integer"
    if t.startswith(("decimal", "double", "real")):
        return "numeric"
    if t.startswith("timestamp"):
        return "timestamp"
    if t == "date":
        return "date"
    if t == "boolean":
        return "boolean"
    if t.startswith(("varchar", "char")):
        return "string"
    return "other"


def trino_literal(value: Any, trino_type: str) -> str:
    """Render ``value`` as a Trino literal matching the column type."""
    if value is None:
        return "NULL"
    kind = type_kind(trino_type)
    if kind == "integer":
        try:
            return str(int(value))
        except (TypeError, ValueError):
            pass
    if kind == "numeric":
        try:
            float(value)
            return str(value)
        except (TypeError, ValueError):
            pass
    if kind == "boolean":
        return "TRUE" if str(value).lower() in ("true", "1", "t") else "FALSE"
    if kind == "date":
        iso = value.isoformat() if hasattr(value, "isoformat") else str(value)
        return f"DATE '{iso}'"
    if kind == "timestamp":
        iso = value.isoformat(sep=" ") if hasattr(value, "isoformat") else str(value)
        return f"TIMESTAMP '{iso}'"
    s = str(value)
    if (trino_type or "").lower().startswith("char"):
        s = s.rstrip()
    return "'" + s.replace("'", "''") + "'"


# ---------------------------------------------------------------------------
# Connected table subsets of the foreign-key graph
# ---------------------------------------------------------------------------

def enumerate_connected_subsets(
    tables: List[str], graph: Dict[str, set], *, min_size: int, max_size: int,
) -> List[Tuple[str, ...]]:
    """
    Every connected subset of the FK graph with ``min_size <= |S| <= max_size``,
    each exactly once (Wernicke's ESU enumeration).  Subsets are sorted tuples.
    """
    order = {t: i for i, t in enumerate(sorted(tables))}
    found: List[Tuple[str, ...]] = []

    def nbrs(t):
        return {u for u in graph.get(t, set()) if u in order}

    def extend(sub: frozenset, extension: set, root: str):
        if len(sub) >= min_size:
            found.append(tuple(sorted(sub)))
        if len(sub) >= max_size:
            return
        sub_nbrs = set().union(*(nbrs(u) for u in sub))
        extension = set(extension)
        while extension:
            w = min(extension, key=order.__getitem__)
            extension.discard(w)
            exclusive = {
                u for u in nbrs(w)
                if order[u] > order[root] and u not in sub and u not in sub_nbrs
            }
            extend(sub | {w}, extension | exclusive, root)

    for root in sorted(tables):
        extend(frozenset([root]), {u for u in nbrs(root) if order[u] > order[root]}, root)
    return found


def random_connected_subset(
    tables: List[str], graph: Dict[str, set], size: int, rng: random.Random,
) -> List[str]:
    """
    A random connected subset of ``size`` tables grown from a random start
    table by repeatedly adding a random frontier neighbour.  Falls back to the
    whole connected component when it is smaller than ``size``.
    """
    if not tables:
        return []
    size = max(1, min(size, len(tables)))
    selected = [rng.choice(sorted(tables))]
    while len(selected) < size:
        frontier = sorted(
            {u for t in selected for u in graph.get(t, set()) if u in tables} - set(selected)
        )
        if not frontier:
            break
        selected.append(rng.choice(frontier))
    return sorted(selected)


# ---------------------------------------------------------------------------
# Context builders
# ---------------------------------------------------------------------------

def context_from_factories(
    *,
    schema: str,
    conn_factory: Callable[[], Any],
    client_factory: Optional[Callable[[], Any]] = None,
    catalog: str = "iceberg",
    model_name: str = MODEL_NAME,
    base_url: str = BASE_MODEL_URL,
    api_key_env: str = API_KEY_ENV,
    temperature: float = 0.6,
    reasoning: str = "medium",
) -> BaselineContext:
    schema_json = load_schema(schema)
    if client_factory is None:
        def client_factory():  # noqa: E306
            return make_openai_client(base_url=base_url, api_key_env=api_key_env)
    return BaselineContext(
        schema_json=schema_json,
        trino_schema=schema,
        catalog=catalog,
        conn_factory=conn_factory,
        client_factory=client_factory,
        model_name=model_name,
        base_url=base_url,
        temperature=temperature,
        reasoning=reasoning,
    )


def context_from_lakehouse(
    lakehouse,
    *,
    schema: str,
    catalog: str = "iceberg",
    model_name: str = MODEL_NAME,
    base_url: str = BASE_MODEL_URL,
    api_key_env: str = API_KEY_ENV,
    temperature: float = 0.6,
    reasoning: str = "medium",
) -> BaselineContext:
    """
    Build a context from a live ``Lakehouse`` (``Lakehouse.from_release(...)``).
    Connections go through the Lakehouse's Trino host, exactly like
    ``lh.generate_workload``.
    """
    from trino.dbapi import connect  # local import (needs runtime deps)

    trino_host = lakehouse.trino_host

    def conn_factory():
        return connect(
            host=trino_host,
            port=TRINO_PORT,
            user=TRINO_USER,
            catalog=catalog,
            schema=schema,
            http_scheme="http",
            session_properties={"query_max_run_time": TRINO_QUERY_MAX_RUN_TIME},
        )

    def client_factory():
        return make_openai_client(base_url=base_url, api_key_env=api_key_env)

    return BaselineContext(
        schema_json=load_schema(schema),
        trino_schema=schema,
        catalog=catalog,
        conn_factory=conn_factory,
        client_factory=client_factory,
        model_name=model_name,
        base_url=base_url,
        temperature=temperature,
        reasoning=reasoning,
    )


# ---------------------------------------------------------------------------
# Workload writer + generation_report (mirrors write_workload_directory)
# ---------------------------------------------------------------------------

def write_baseline_workload(
    *,
    baseline: str,
    workload_name: str,
    queries: List[dict],
    ctx: BaselineContext,
    started_at: datetime,
    pipeline_report: Dict[str, Any],
    workload_root: str | Path | None = None,
    zero_pad: int = 0,
) -> Dict[str, Any]:
    """
    Write ``q<i>.sql`` files + a ``generation_report.json`` for a baseline run.

    ``queries`` is a list of dicts, each with at least ``sql`` and optionally
    ``goal`` / ``selected_tables`` / any baseline-specific metadata (kept under
    each query's ``extra`` key in the report).

    ``pipeline_report`` carries the baseline-specific run summary (prompt suite,
    self-correction attempts, cost-distribution alignment, agent schedule, ...).
    """
    ended_at = datetime.now(timezone.utc)
    workload_root = Path(workload_root or WORKLOADS_DIR)
    workload_dir = ensure_dir(workload_root / workload_name)

    def qname(i: int) -> str:
        return f"q{str(i).zfill(zero_pad)}" if zero_pad else f"q{i}"

    per_query_report: List[Dict[str, Any]] = []
    schema_tables = ctx.schema_tables()

    for i, q in enumerate(queries, start=1):
        name = qname(i)
        sql = sanitize_sql(q.get("sql", ""))
        sql_path = workload_dir / f"{name}.sql"
        sql_path.write_text(sql.strip() + "\n", encoding="utf-8")

        feats = query_features(sql)
        entry = {
            "query_name": name,
            "file": str(sql_path),
            "sql": sql,
            "goal": q.get("goal", ""),
            "selected_tables": q.get("selected_tables", feats.get("tables", [])),
            "metaheuristics": feats,
        }
        if q.get("extra"):
            entry["extra"] = q["extra"]
        per_query_report.append(entry)

    workload_meta = workload_metaheuristics(
        [e["metaheuristics"] for e in per_query_report],
        schema_tables=schema_tables,
    )

    n_written = len(per_query_report)
    token_usage = ctx.token_usage_delta()
    tokens_per_query = (
        token_usage.get("total_tokens", 0) / n_written if n_written else None
    )

    report = {
        "baseline": baseline,
        "workload_name": workload_name,
        "workload_dir": str(workload_dir),
        "created_at_utc": started_at.isoformat(),
        "completed_at_utc": ended_at.isoformat(),
        "duration_s": (ended_at - started_at).total_seconds(),
        "num_queries": n_written,
        "token_usage": token_usage,
        "tokens_per_query": tokens_per_query,
        "model": {
            "name": ctx.model_name,
            "base_url": ctx.base_url,
            "temperature": ctx.temperature,
            "reasoning": ctx.reasoning,
        },
        "schema": {
            "catalog": ctx.catalog,
            "schema": ctx.trino_schema,
            "dataset_name": ctx.schema_json.get("name"),
            "num_tables": len(schema_tables),
        },
        "pipeline": pipeline_report,
        "workload_metaheuristics": workload_meta,
        "queries": per_query_report,
    }

    report_path = workload_dir / "generation_report.json"
    report_path.write_text(json.dumps(report, indent=2, default=str), encoding="utf-8")
    return report
