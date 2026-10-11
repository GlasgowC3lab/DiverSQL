"""
SQLBarber baseline.

    Lao & Trummer.
    "SQLBarber: A System Leveraging Large Language Models to Generate
     Customized and Realistic SQL Workloads."  SIGMOD 2026.  arXiv:2507.06192.
    https://github.com/SolidLao/SQLBarber

Adaptation of SQLBarber's workflow (``src/run_sqlbarber.py`` and
``src/sqlbarber/`` in the reference implementation) to Trino / Iceberg.
"""

import itertools
import json
import math
import random
import re
import threading
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from dataclasses import dataclass, field
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional, Tuple

import numpy as np

from diversql.baselines.common import (
    BaselineContext,
    random_connected_subset,
    trino_literal,
    type_kind,
    write_baseline_workload,
)
from diversql.baselines.query_generator import sanitize_sql


BASELINE = "sqlbarber"

# (num_tables_accessed, num_joins, num_aggregations) of the 24 templates in
# SQLBarber's Redset specification (a 28-table database).
_REDSET_NUM_TABLES = 28
REDSET_TEMPLATE_SPECS: List[Tuple[int, int, int]] = [
    (1, 0, 0), (1, 0, 0), (1, 0, 0), (1, 0, 0), (1, 0, 0), (1, 0, 2),
    (1, 0, 0), (1, 0, 0), (1, 0, 0), (1, 0, 0), (1, 0, 3), (1, 0, 0),
    (1, 0, 2), (2, 1, 0), (1, 2, 7), (1, 2, 8), (8, 7, 6), (8, 7, 6),
    (9, 8, 6), (8, 8, 6), (9, 8, 6), (9, 9, 6), (9, 9, 6), (13, 27, 21),
]

# Semantic requirements and weights from the reference ``run_sqlbarber.py``.
DEFAULT_SEMANTIC_REQUIREMENTS: List[Tuple[int, str]] = [
    (3, "The query should have a nested query with aggregation, at least two predicate values to fill."),
    (3, "The query should use aggregation, and have at least three predicate values to fill."),
    (3, "The query should use group-by, and have at least two predicate values to fill."),
]

_VALUE_LIMIT = 500
_MAX_CONSTRAINT_RETRIES = 5
_MAX_GRAMMAR_RETRIES = 5

_PLACEHOLDER = re.compile(r"'?\{\{\s*([A-Za-z_]\w*)\.([A-Za-z_]\w*)\s*\}\}'?")

_SYSTEM = (
    "You are an expert in SQL and database systems writing SQL templates for "
    "Trino (Presto SQL) over Iceberg tables. Respond with valid JSON only."
)

_FORMAT_REQUIREMENT = """
Format Requirement:
- Predicate values (the dynamic values that will be inserted for filtering) should be wrapped in double curly braces with single quotes like `'{{}}'`.
- Ensure that all predicate values wrapped in double curly braces are enclosed in single quotes, e.g., `'{{real_table_name.real_column_name}}'`.
- Table names, column names, and JOIN conditions should be written directly without any curly braces or quotes. Double curly braces with single quotes are only for placeholders where predicate values will be inserted.
- For predicates with both lower and upper bounds, use `'{{real_table_name.real_column_name_start}}'` and `'{{real_table_name.real_column_name_end}}'` to represent the placeholder values, but do not wrap the actual column names in curly braces.
- The table names and column names should exactly match those in the database. Include both real table name and column name like `'{{real_table_name.real_column_name}}'`.
- Placeholders are replaced by typed Trino literals (e.g. 42, DATE '2001-01-01', 'text'), so write them where a literal of the column's type is valid.
"""


def _obj(props: Dict[str, Any]) -> Dict[str, Any]:
    return {"type": "object", "properties": props,
            "required": list(props), "additionalProperties": False}


_S = {"type": "string"}
_GEN_SCHEMA = {"name": "sql_template", "strict": True,
               "schema": _obj({"sql_template": _S, "think_process": _S})}
_CHECK_SCHEMA = {"name": "constraint_check", "strict": True,
                 "schema": _obj({"result": {"type": "string", "enum": ["Satisfied", "Not Satisfied"]},
                                 "reason": _S, "modification": _S, "sql_template": _S})}
_REPAIR_SCHEMA = {"name": "grammar_repair", "strict": True,
                  "schema": _obj({"think_process": _S, "sql_template": _S})}
_REFINE_SCHEMA = {"name": "refined_template", "strict": True,
                  "schema": _obj({"sql_template": _S,
                                  "metadata": _obj({"operation": _S, "old_join_path": _S,
                                                    "new_join_path": _S, "table_size_changes": _S,
                                                    "structural_changes": _S, "think_process": _S})})}


# ---------------------------------------------------------------------------
# Specifications
# ---------------------------------------------------------------------------

def _scaled_specs(
    n_target_tables: int, requirements: List[Tuple[int, str]], rng: random.Random,
) -> List[Dict[str, Any]]:
    """Rescale the Redset template profiles to the target schema and assign
    semantic requirements proportionally (reference ``generate_prompts``)."""
    n = len(REDSET_TEMPLATE_SPECS)
    assigned: List[Optional[str]] = [None] * n
    if requirements:
        total = sum(w for w, _ in requirements)
        counts = [int(w * n / total) for w, _ in requirements]
        i = 0
        while sum(counts) < n:
            counts[i % len(counts)] += 1
            i += 1
        assigned = [req for c, (_, req) in zip(counts, requirements) for _ in range(c)]
        rng.shuffle(assigned)

    specs = []
    for k, ((tables, joins, aggs), req) in enumerate(zip(REDSET_TEMPLATE_SPECS, assigned), start=1):
        self_join = tables != joins + 1
        scale = n_target_tables / _REDSET_NUM_TABLES
        j = math.ceil(joins * scale)
        a = math.ceil(aggs * scale)
        t = math.ceil(tables * scale)
        if not self_join:
            t = max(t, j + 1)
            j = t - 1
        specs.append({"spec_id": f"redset_{k}", "num_tables_accessed": t,
                      "num_joins": j, "num_aggregations": a,
                      "semantic_requirement": req})
    return specs


def _metadata_header(spec: Dict[str, Any], tables: List[str]) -> str:
    lines = [
        "-- SQL Template Metadata",
        "-- Constraints:",
        f"--   Number of unique Tables Accessed: {spec['num_tables_accessed']}",
        f"--   Number of Joins: {spec['num_joins']}",
        f"--   Number of Aggregations: {spec['num_aggregations']}",
    ]
    if spec.get("semantic_requirement"):
        lines.append(f"--   Semantic Requirement: {spec['semantic_requirement']}")
    lines.append(f"--   Tables Involved: [{', '.join(tables)}]")
    return "\n".join(lines)


def _clean_template(text: str) -> str:
    """Strip fences, metadata comment lines and trailing semicolons."""
    text = sanitize_sql(text or "")
    body = [ln for ln in text.splitlines() if not ln.strip().startswith("--")]
    return sanitize_sql("\n".join(body))


# ---------------------------------------------------------------------------
# Templates and predicate value spaces
# ---------------------------------------------------------------------------

@dataclass(eq=False)
class _Template:
    tid: int
    sql: str
    spec: Dict[str, Any]
    tables: List[str]
    origin: str                                  # "spec" | "refined"
    dims: List[str] = field(default_factory=list)
    values: Dict[str, List[Any]] = field(default_factory=dict)
    types: Dict[str, str] = field(default_factory=dict)
    invalid_placeholders: List[str] = field(default_factory=list)
    evals: Dict[Tuple[int, ...], Optional[float]] = field(default_factory=dict)
    log: Dict[str, Any] = field(default_factory=dict)

    @property
    def space_size(self) -> int:
        size = 1
        for d in self.dims:
            size *= max(1, len(self.values[d]))
        return size

    def costs(self) -> List[float]:
        return [c for c in self.evals.values() if c is not None]


class _Runner:
    """State shared by the SQLBarber stages for one run."""

    def __init__(self, ctx: BaselineContext, *, target: str, min_cost: float,
                 max_cost: float, num_intervals: int, workers: int, rng: random.Random):
        self.ctx = ctx
        self.target = target
        self.min_cost = float(min_cost)
        self.max_cost = float(max_cost)
        self.num_intervals = num_intervals
        self.edges = np.linspace(self.min_cost, self.max_cost, num_intervals + 1)
        self.workers = max(1, workers)
        self.rng = rng
        self.graph = ctx.relationship_graph()
        self.schema_tables = ctx.schema_tables()
        self.columns = {t: {c["name"]: c["type"] for c in ctx.columns_for(t)}
                        for t in self.schema_tables}
        self._values: Dict[Tuple[str, str], List[Any]] = {}
        self._values_lock = threading.Lock()
        self.pool: Dict[str, Dict[str, Any]] = {}    # sql -> {cost, tid, interval}
        self._pool_lock = threading.Lock()
        self.estimates = {"plans": 0, "operator_nodes": 0, "unestimated_nodes": 0, "failed": 0}
        self._est_lock = threading.Lock()
        self.target_counts: List[int] = [0] * num_intervals

    # -- intervals ---------------------------------------------------------
    def interval_of(self, cost: Optional[float]) -> Optional[int]:
        if cost is None or cost < self.min_cost or cost > self.max_cost:
            return None
        if cost == self.max_cost:
            return self.num_intervals - 1
        i = int(np.searchsorted(self.edges, cost, side="right")) - 1
        return min(max(i, 0), self.num_intervals - 1)

    def bounds(self, i: int) -> Tuple[float, float]:
        return float(self.edges[i]), float(self.edges[i + 1])

    def current_counts(self) -> List[int]:
        counts = [0] * self.num_intervals
        with self._pool_lock:
            for rec in self.pool.values():
                if rec["interval"] is not None:
                    counts[rec["interval"]] += 1
        return counts

    def wasserstein(self, counts: Optional[List[int]] = None) -> float:
        from scipy.stats import wasserstein_distance
        counts = counts if counts is not None else self.current_counts()
        mids = [(self.edges[i] + self.edges[i + 1]) / 2 for i in range(self.num_intervals)]
        capped = [min(c, t) for c, t in zip(counts, self.target_counts)]

        def samples(dist):
            s = [m for m, c in zip(mids, dist) for _ in range(c)]
            return s or [0.0]
        return float(wasserstein_distance(samples(self.target_counts), samples(capped)))

    # -- predicate value space --------------------------------------------
    def column_values(self, table: str, column: str) -> List[Any]:
        key = (table, column)
        with self._values_lock:
            if key in self._values:
                return self._values[key]
        vals = self.ctx.sample_column_values(table, column, limit=_VALUE_LIMIT)
        if type_kind(self.columns.get(table, {}).get(column, "")) in ("integer", "numeric"):
            try:
                vals = sorted(vals)
            except TypeError:
                pass
        with self._values_lock:
            self._values[key] = vals
        return vals

    def resolve(self, table: str, col: str) -> Optional[Tuple[str, Optional[str]]]:
        """Reference ``identify_placeholders`` rules: ``_start``/``_end`` range
        suffixes, otherwise strip trailing ``_xxx`` parts until a column matches."""
        valid = self.columns.get(table)
        if not valid:
            return None
        if col.endswith("_start") and col[:-6] in valid:
            return col[:-6], "start"
        if col.endswith("_end") and col[:-4] in valid:
            return col[:-4], "end"
        c = col
        while "_" in c and c not in valid:
            c = c[:c.rfind("_")]
        return (c, None) if c in valid else None

    def build_space(self, t: _Template) -> None:
        t.dims, t.values, t.types, t.invalid_placeholders = [], {}, {}, []
        for table, col in _PLACEHOLDER.findall(t.sql):
            name = f"{table}.{col}"
            if name in t.values or name in t.invalid_placeholders:
                continue
            res = self.resolve(table, col)
            if res is None:
                t.invalid_placeholders.append(name)
                continue
            base, _ = res
            ctype = self.columns[table][base]
            vals = self.column_values(table, base) if type_kind(ctype) != "other" else []
            if not vals:
                t.invalid_placeholders.append(name)
                continue
            t.dims.append(name)
            t.values[name] = vals
            t.types[name] = ctype

    def instantiate(self, t: _Template, cfg: Tuple[int, ...]) -> str:
        chosen = {d: t.values[d][i] for d, i in zip(t.dims, cfg)}
        final: Dict[str, Any] = {}
        for d, v in chosen.items():
            if d.endswith("_start") and d[:-6] + "_end" in chosen:
                other = chosen[d[:-6] + "_end"]
                final[d] = _safe_min(v, other)
            elif d.endswith("_end") and d[:-4] + "_start" in chosen:
                other = chosen[d[:-4] + "_start"]
                final[d] = _safe_max(v, other)
            else:
                final[d] = v

        def repl(m):
            name = f"{m.group(1)}.{m.group(2)}"
            if name in final:
                return trino_literal(final[name], t.types[name])
            return "'test'"
        return _PLACEHOLDER.sub(repl, t.sql)

    def sample_config(self, t: _Template, rng: random.Random) -> Tuple[int, ...]:
        return tuple(rng.randrange(len(t.values[d])) for d in t.dims)

    # -- cost evaluation ---------------------------------------------------
    def estimate(self, sql: str) -> Optional[float]:
        est = self.ctx.explain_cost(sql)
        with self._est_lock:
            if not est:
                self.estimates["failed"] += 1
                return None
            self.estimates["plans"] += 1
            self.estimates["operator_nodes"] += est.get("operator_nodes") or 0
            self.estimates["unestimated_nodes"] += est.get("unestimated_nodes") or 0
        return est.get("sum_rows") if self.target == "card" else est.get("sum_cpu_cost")

    def evaluate(self, t: _Template, configs: List[Tuple[int, ...]],
                 add_to_pool: bool = True) -> List[Tuple[Tuple[int, ...], str, Optional[float]]]:
        """Estimate the cost of each configuration (in parallel); record it on
        the template and, by default, in the query pool."""
        todo = [c for c in dict.fromkeys(configs) if c not in t.evals]
        if not todo:
            return []

        def work(cfg):
            sql = self.instantiate(t, cfg)
            return cfg, sql, self.estimate(sql)

        results = []
        with ThreadPoolExecutor(max_workers=self.workers) as ex:
            for fut in as_completed([ex.submit(work, c) for c in todo]):
                results.append(fut.result())
        results.sort(key=lambda r: todo.index(r[0]))
        for cfg, sql, cost in results:
            t.evals[cfg] = cost
        if add_to_pool:
            self.add_to_pool(t, results)
        return results

    def add_to_pool(self, t: _Template, results) -> None:
        with self._pool_lock:
            for cfg, sql, cost in results:
                if cost is not None and sql not in self.pool:
                    self.pool[sql] = {"cost": cost, "tid": t.tid, "interval": self.interval_of(cost)}


def _safe_min(a, b):
    try:
        return min(a, b)
    except TypeError:
        return a


def _safe_max(a, b):
    try:
        return max(a, b)
    except TypeError:
        return a


# ---------------------------------------------------------------------------
# Stage 1-2: template generation + self-correction
# ---------------------------------------------------------------------------

def _generation_prompt(spec: Dict[str, Any], ddl: str) -> str:
    prompt = (
        "Generate an SQL template with placeholders for predicate values that satisfies the following constraints:\n"
        f"- Number of unique tables accessed: {spec['num_tables_accessed']}\n"
        f"- Number of joins: {spec['num_joins']}\n"
        f"- Number of aggregations: {spec['num_aggregations']}\n"
    )
    if spec.get("semantic_requirement"):
        prompt += f"- Semantic Requirement: {spec['semantic_requirement']}\n"
    prompt += (
        "Use the following table schemas. Only the exact table and column names provided "
        "in these schemas are allowed. Any other column name is not allowed.\n"
        f"{ddl}\n"
        f"{_FORMAT_REQUIREMENT}"
        "\nHints:\n"
        "- If the number of joins exceeds 1 + the number of unique tables accessed, then the query must use self-joins or repeatedly join the same set of tables.\n"
        "- Do not use predicate values that require aggregation. For example, expressions like real_table_name.real_column_name_min, max, count, sum, or any other aggregation functions are not allowed. Predicate values must be directly accessible from the database and must follow the format real_table_name.real_column_name\n"
        "- When constructing predicate conditions, do not use string matching at all. This type of condition is currently not supported.\n"
        "\nNow let's think step by step and provide the SQL query template. Return the result in JSON format as:\n"
        '{"sql_template": "Your SQL template here", "think_process": "Your step by step thinking here"}'
    )
    return prompt


def _constraint_prompt(template_with_meta: str) -> str:
    return (
        "Given the following SQL query template and the associated constraints:\n\n"
        f"SQL Template and Constraints:\n{template_with_meta}\n\n"
        "Other constraints:\n"
        "- If the number of joins is larger than 1 + the number of unique table accessed, use self joins or join the same set of tables repeatedly\n"
        "- Do not use predicate values that require aggregation. For example, expressions like real_table_name.real_column_name_min, max, count, sum, or any other aggregation functions are not allowed. Predicate values must be directly accessible from the database and must follow the format real_table_name.real_column_name\n\n"
        "Thinks step by step and check if the SQL template satisfies all the constraints.\n"
        'If it satisfies all the constraints, respond with "result": "Satisfied" (and repeat the template in "sql_template").\n'
        "If not, let's think step by step and provide the reasons why it does not satisfy the constraints, how to modify it, and the corrected SQL template.\n"
        f"{_FORMAT_REQUIREMENT}\n"
        "Respond in JSON format:\n"
        '{"result": "Not Satisfied/Satisfied", "reason": "Your step by step thinking and reason here", '
        '"modification": "How to modify it", "sql_template": "Your corrected SQL template here"}'
    )


def _grammar_prompt(template_with_meta: str, error: str, columns_ddl: str) -> str:
    return (
        "Given the following SQL template and the error message from the DBMS:\n\n"
        f"SQL Template:\n{template_with_meta}\n\n"
        f"Error Message:\n{error}\n\n"
        "Two Common Errors:\n"
        "1. Check whether there are predicates that require aggregation. If so, modify it. Expressions like real_table_name.real_column_name_min, max, count, sum, or any other aggregation functions are not allowed. Predicate values must be directly accessible from the database\n"
        "2. Check whether the predicates really refer to columns in the corresponding table. Every predicate value should come from one column.\n"
        "This is the columns in the table used by the SQL template. You can use this to know whether the predicate/column exists in the table.\n"
        f"{columns_ddl}\n\n"
        "Please fix the SQL template to correct the error, ensuring that it satisfies all the constraints and follows the format requirements.\n"
        f"{_FORMAT_REQUIREMENT}\n"
        "Note:\n"
        "- If you see 'test' in the SQL templates, it means no predicate value can be obtained from database. Possibly the column does not exist in database, you should use the correct column name, or the column really exist in the corresponding table.\n\n"
        "Now let's think step by step and respond in JSON format:\n"
        '{"think_process": "Your step by step thinking here", "sql_template": "Your corrected SQL template here"}'
    )


def _llm_json(ctx: BaselineContext, prompt: str, schema: Dict[str, Any]) -> Optional[Dict[str, Any]]:
    try:
        return json.loads(ctx.responses_text(instructions=_SYSTEM, prompt=prompt, json_schema=schema))
    except Exception:
        return None


def _tables_in(sql: str, schema_tables: List[str]) -> List[str]:
    words = set(re.findall(r"[A-Za-z_]\w*", sql.lower()))
    return [t for t in schema_tables if t.lower() in words]


def _self_correct(run: _Runner, t: _Template) -> None:
    """Constraint-check loop, then (if satisfied) grammar-check loop."""
    ctx = run.ctx
    constraint_attempts = 0
    satisfied = False
    while constraint_attempts < _MAX_CONSTRAINT_RETRIES:
        resp = _llm_json(ctx, _constraint_prompt(_metadata_header(t.spec, t.tables) + "\n" + t.sql), _CHECK_SCHEMA)
        if resp is None:
            constraint_attempts += 1
            continue
        if resp.get("result") == "Satisfied":
            satisfied = True
            break
        constraint_attempts += 1
        fixed = _clean_template(resp.get("sql_template", ""))
        if fixed:
            t.sql = fixed

    grammar_attempts = 0
    grammar_ok = None
    if satisfied:
        grammar_ok = False
        rng = random.Random(t.tid)
        while grammar_attempts < _MAX_GRAMMAR_RETRIES:
            run.build_space(t)
            sql = run.instantiate(t, run.sample_config(t, rng))
            ok, err = ctx.validate_explain(sql)
            if ok:
                grammar_ok = True
                break
            grammar_attempts += 1
            used = _tables_in(t.sql, run.schema_tables) or t.tables
            resp = _llm_json(ctx, _grammar_prompt(_metadata_header(t.spec, t.tables) + "\n" + t.sql,
                                                  err or "", ctx.ddl_with_keys(used)), _REPAIR_SCHEMA)
            fixed = _clean_template((resp or {}).get("sql_template", ""))
            if fixed:
                t.sql = fixed
    run.build_space(t)
    t.log.update({
        "constraint_rewrites": constraint_attempts,
        "constraints_satisfied": satisfied,
        "grammar_rewrites": grammar_attempts,
        "grammar_ok": grammar_ok,
    })


def _generate_template(run: _Runner, tid: int, spec: Dict[str, Any], rng: random.Random) -> Optional[_Template]:
    joins = spec["num_joins"]
    if joins > 0:
        tables = random_connected_subset(run.schema_tables, run.graph, joins + 1, rng)
    else:
        tables = [rng.choice(run.schema_tables)]
    resp = _llm_json(run.ctx, _generation_prompt(spec, run.ctx.ddl_with_keys(tables)), _GEN_SCHEMA)
    sql = _clean_template((resp or {}).get("sql_template", ""))
    if not sql:
        return None
    t = _Template(tid=tid, sql=sql, spec=spec, tables=tables, origin="spec")
    _self_correct(run, t)
    return t


# ---------------------------------------------------------------------------
# Stage 3: profiling (default configuration + Latin hypercube)
# ---------------------------------------------------------------------------

def _lhs(t: _Template, n: int, rng: random.Random) -> List[Tuple[int, ...]]:
    if n <= 0:
        return []
    if not t.dims:
        return [()]
    cols = []
    for d in t.dims:
        m = len(t.values[d])
        perm = list(range(n))
        rng.shuffle(perm)
        cols.append([min(m - 1, int((p + rng.random()) / n * m)) for p in perm])
    return list(dict.fromkeys(zip(*cols)))


def _profile_configs(t: _Template, n: int, rng: random.Random) -> List[Tuple[int, ...]]:
    if t.space_size <= n:
        return list(itertools.product(*[range(len(t.values[d])) for d in t.dims]))
    default = tuple(0 for _ in t.dims)
    return list(dict.fromkeys([default] + _lhs(t, n - 1, rng)))


# ---------------------------------------------------------------------------
# Stage 5: Bayesian optimisation over predicate values
# ---------------------------------------------------------------------------

def _interval_loss(cost: Optional[float], lo: float, hi: float) -> float:
    """Reference ``calculate_performance`` for a range target (0 inside)."""
    if cost is None:
        return 1.0
    if lo <= cost <= hi:
        return 0.0

    def sim(a, b):
        return min(a / b, b / a) if a > 0 and b > 0 else 0.0
    return 1.0 - max(sim(cost, lo), sim(cost, hi))


def _encode(t: _Template, cfgs: List[Tuple[int, ...]]) -> np.ndarray:
    scale = np.array([max(1, len(t.values[d]) - 1) for d in t.dims], dtype=float)
    return np.asarray(cfgs, dtype=float).reshape(len(cfgs), len(t.dims)) / scale


def _bayesian_optimise(
    run: _Runner, t: _Template, lo: float, hi: float, *, n_trials: int, n_init: int,
    reuse_history: bool, rng: random.Random, retrain_after: int = 20,
    random_prob: float = 0.2, n_random_candidates: int = 500,
) -> List[float]:
    """SMAC-style BO; returns the costs of the newly evaluated queries."""
    from scipy.stats import norm
    from sklearn.ensemble import RandomForestRegressor

    remaining = t.space_size - len(t.evals)
    n_trials = min(n_trials, remaining)
    if n_trials <= 0:
        return []

    history: List[Tuple[Tuple[int, ...], float]] = []
    if reuse_history and t.evals:
        ranked = sorted(t.evals.items(), key=lambda kv: _interval_loss(kv[1], lo, hi))
        history = [(c, _interval_loss(v, lo, hi)) for c, v in ranked[:max(1, len(ranked) // 4)]]
        n_init = 0
    X_cfg = [c for c, _ in history]
    y = [l for _, l in history]
    new_costs: List[float] = []
    done = 0

    def record(results):
        nonlocal done
        for cfg, _, cost in results:
            X_cfg.append(cfg)
            y.append(_interval_loss(cost, lo, hi))
            if cost is not None:
                new_costs.append(cost)
        done += len(results)

    def random_unseen(k: int) -> List[Tuple[int, ...]]:
        out, tries = [], 0
        while len(out) < k and tries < 50 * k:
            c = run.sample_config(t, rng)
            tries += 1
            if c not in t.evals and c not in out:
                out.append(c)
        if len(out) < k and t.space_size <= 200_000:
            rest = [c for c in itertools.product(*[range(len(t.values[d])) for d in t.dims])
                    if c not in t.evals and c not in out]
            rng.shuffle(rest)
            out += rest[:k - len(out)]
        return out

    if n_init > 0:
        init = [c for c in _lhs(t, n_init, rng) if c not in t.evals][:min(n_init, n_trials)]
        record(run.evaluate(t, init))

    while done < n_trials:
        k = min(retrain_after, n_trials - done)
        if len(y) < 2 or len(set(y)) < 2 or not t.dims:
            batch = random_unseen(k)
        else:
            X = _encode(t, X_cfg)
            y_log = np.log(np.asarray(y) + 1e-3)
            rf = RandomForestRegressor(n_estimators=10, min_samples_leaf=1,
                                       random_state=rng.randrange(2**31))
            rf.fit(X, y_log)

            cands = set(random_unseen(n_random_candidates))
            incumbents = [c for c, _ in sorted(zip(X_cfg, y), key=lambda p: p[1])[:10]]
            for inc in incumbents:
                for di, d in enumerate(t.dims):
                    m = len(t.values[d])
                    for step in (-2, -1, 1, 2):
                        j = inc[di] + step
                        if 0 <= j < m:
                            nb = inc[:di] + (j,) + inc[di + 1:]
                            if nb not in t.evals:
                                cands.add(nb)
            cands = list(cands)
            if not cands:
                break
            Xc = _encode(t, cands)
            per_tree = np.stack([est.predict(Xc) for est in rf.estimators_])
            mu, sigma = per_tree.mean(axis=0), np.maximum(per_tree.std(axis=0), 1e-9)
            best = float(np.min(y_log))
            z = (best - mu) / sigma
            ei = (best - mu) * norm.cdf(z) + sigma * norm.pdf(z)
            ranked = [cands[i] for i in np.argsort(-ei)]
            batch, used = [], set()
            fresh = iter(random_unseen(k))
            for c in ranked:
                if len(batch) >= k:
                    break
                if rng.random() < random_prob:
                    r = next(fresh, None)
                    if r is not None and r not in used:
                        batch.append(r)
                        used.add(r)
                        continue
                if c not in used:
                    batch.append(c)
                    used.add(c)
        if not batch:
            break
        record(run.evaluate(t, batch))
    return new_costs


def _closeness(costs: List[float], lo: float, hi: float) -> float:
    """Reference ``cal_closeness_template_for_interval``."""
    if not costs:
        return 0.0
    dist = sum((lo - c) if c < lo else (c - hi) if c > hi else 0.0 for c in costs) / len(costs)
    return (1.0 / (1.0 + dist)) * (len(set(costs)) / len(costs))


# ---------------------------------------------------------------------------
# Stage 4: template refinement + pruning
# ---------------------------------------------------------------------------

def _refine_prompt(run: _Runner, examples: List[_Template], lo: float, hi: float,
                   schema_info: Dict[str, Any]) -> str:
    cost_name = ("sum of all the cardinalities in the execution plan" if run.target == "card"
                 else "execution plan cost")
    blocks = []
    for i, t in enumerate(examples, start=1):
        costs = t.costs()
        joins = t.spec.get("num_joins", len(re.findall(r"\bjoin\b", t.sql, re.IGNORECASE)))
        paths = [random_connected_subset(run.schema_tables, run.graph, joins + 1, run.rng)
                 for _ in range(10)] if joins > 0 else []
        paths = [list(p) for p in dict.fromkeys(tuple(p) for p in paths)]
        blocks.append(
            f"Example Template {i}:\n"
            f"SQL Template: {_metadata_header(t.spec, t.tables)}\n{t.sql}\n"
            f"Historical Cost Range: [{min(costs)}, {max(costs)}]\n"
            f"Average Cost: {sum(costs) / len(costs):.2f}\n"
            f"Distinct Cost Values: {len(set(costs))} from {len(costs)} costs\n"
            f"Number of JOINs: {joins}\n"
            f"Possible JOIN paths for {joins} joins:\n{json.dumps(paths, indent=4)}\n"
        )
    return f"""
We want to generate SQL queries with certain cost type: {cost_name}.

You are given:
1) {len(examples)} existing SQL templates, where by changing the predicate values, they have historically produced costs in different ranges.
2) We want to refine or rewrite these templates so that future queries generated using various predicate values
will run with a cost in the target range of [{lo}, {hi}].

Here are the existing templates and their cost characteristics:
{''.join(blocks)}
Table schema information (size in bytes, row count, distinct values per column; null = unknown):
{json.dumps(schema_info, indent=1)}

Foreign keys:
{run.ctx.foreign_key_text()}

We have three possible refinement operations:
(1) Change the accessed table or JOIN path:
   - If only one table is accessed, we can choose a different table which is larger or smaller
   - If more than one table is accessed
       - Possibly choose different tables or a different order of joins
       - We can adjust the number of joins up or down based on the target cost range
       - Use the provided possible joinable paths based on our database schema
(2) Change the SQL structure:
   - Make the SQL template more or less complex
   - Add or delete predicate conditions
   - Change the columns used for filters or predicate conditions based on columns selectivity (i.e., the unique values in a column, provided above)
(3) If it is hard to modify the existing templates to satisfy the target costs, we really encourage you to:
    - Create brand-new SQL templates

Learn from the examples to understand:
- Which templates produce costs closest to our target range
- What patterns lead to higher or lower costs
- How join complexity impacts the cost

We do NOT want to break the basic placeholders format, but you can add, remove, or rename placeholders
to shift the cost up/down. For instance, applying more selective predicates might decrease cost,
while removing some or joining larger tables might increase cost.

We want you to:
- Decide which operation(s) to use (only join path, only structure, or both, or create brand-new SQL templates).
- Produce a refined SQL template that can push the cost into the target range.
- Provide metadata explaining what was changed:
  * operation: 'join_path', 'structure', 'both', or 'brand-new'
  * old_join_path -> new_join_path (if changed)
  * table sizes relevant to the changes
  * any relevant new/modified predicates or structural changes

Important notes:
- Keep using double curly braces with single quotes for placeholders, e.g. `'{{{{some_table.some_column}}}}'`.
- Make sure don't use constant value as predicate value since you don't know which values are available for that column in database.
- If you do not change the path, set "new_join_path" equal to "same as old".
- If you do not change the structure, set "structural_changes" to "none".
- Make sure the refined SQL is valid Trino SQL.
- The refined SQL template should still satisfy the constraints listed in the old SQL template

Now let's think step by step. Return your answer in valid JSON with keys "sql_template" and "metadata".
"""


def _schema_info(run: _Runner) -> Dict[str, Any]:
    info = {}
    for tname in run.schema_tables:
        st = run.ctx.table_stats(tname)
        info[tname] = {
            "size": st.get("size_bytes"),
            "row_count": st.get("row_count"),
            "columns": {c: st["columns"].get(c) for c in run.columns[tname]},
        }
    return info


def _refine_phase(run: _Runner, templates: List[_Template], next_tid, *, n_profile: int,
                  main_rounds: int, difficult_rounds: int, rng: random.Random) -> Dict[str, Any]:
    """Reference ``template_refinement_parallel``."""
    schema_info = _schema_info(run)
    history: Dict[int, List[_Template]] = {}
    log: Dict[str, Any] = {"rounds": [], "refined_generated": 0, "refined_kept": 0}

    def missing_intervals(threshold: float) -> List[int]:
        cov = run.current_counts()
        return [i for i in range(run.num_intervals)
                if run.target_counts[i] > 0 and (cov[i] == 0 or cov[i] < threshold * run.target_counts[i])]

    def refine_one(i: int, num_templates: int, few_shot: bool) -> List[Tuple[int, _Template, str]]:
        lo, hi = run.bounds(i)
        scored = [(t, _closeness(t.costs(), lo, hi)) for t in templates if t.costs()]
        if len(scored) <= 3:
            return []
        weights = [s for _, s in scored]
        if sum(weights) <= 0:
            weights = [1.0] * len(scored)
        picks = rng.choices([t for t, _ in scored], weights=weights, k=num_templates)
        out = []

        def call(parent: _Template):
            examples = [parent]
            if few_shot and history.get(i):
                pool = history[i] + [parent]
                pool.sort(key=lambda x: _avg_distance(x.costs(), lo, hi))
                examples = pool[:3]
            resp = _llm_json(run.ctx, _refine_prompt(run, examples, lo, hi, schema_info), _REFINE_SCHEMA)
            return parent, _clean_template((resp or {}).get("sql_template", ""))

        with ThreadPoolExecutor(max_workers=min(run.workers, num_templates)) as ex:
            for fut in as_completed([ex.submit(call, p) for p in picks]):
                try:
                    parent, sql = fut.result()
                except Exception:
                    continue
                if sql:
                    out.append((i, parent, sql))
        return out

    def process(new: List[Tuple[int, _Template, str]], phase: str) -> None:
        for i, parent, sql in new:
            lo, hi = run.bounds(i)
            t = _Template(tid=next_tid(), sql=sql, spec=parent.spec,
                          tables=_tables_in(sql, run.schema_tables) or parent.tables,
                          origin="refined", log={"parent": parent.tid, "interval": i, "phase": phase})
            run.build_space(t)
            results = run.evaluate(t, _profile_configs(t, n_profile, rng), add_to_pool=False)
            costs = [c for _, _, c in results if c is not None]
            log["refined_generated"] += 1
            if costs:
                hist = history.setdefault(i, [])
                if len(hist) < 3:
                    hist.append(t)
                else:
                    worst = max(range(3), key=lambda k: _avg_distance(hist[k].costs(), lo, hi))
                    if _avg_distance(costs, lo, hi) < _avg_distance(hist[worst].costs(), lo, hi):
                        hist[worst] = t
            keep = _keeps(run, costs, missing_intervals(0.2))
            run.add_to_pool(t, results)
            if keep:
                templates.append(t)
                log["refined_kept"] += 1

    for r in range(main_rounds):
        todo = missing_intervals(0.2)
        if not todo:
            break
        new = [x for i in todo for x in refine_one(i, 3, False)]
        process(new, f"main_{r + 1}")
        log["rounds"].append({"phase": f"main_{r + 1}", "intervals": todo, "templates": len(new)})

    for r in range(difficult_rounds):
        todo = missing_intervals(0.1)
        if not todo:
            break
        new = [x for i in todo for x in refine_one(i, 5, r > 0)]
        process(new, f"difficult_{r + 1}")
        log["rounds"].append({"phase": f"difficult_{r + 1}", "intervals": todo, "templates": len(new)})
    return log


def _avg_distance(costs: List[float], lo: float, hi: float) -> float:
    costs = [c for c in costs if c is not None]
    if not costs:
        return float("inf")
    avg = sum(costs) / len(costs)
    return lo - avg if avg < lo else avg - hi if avg > hi else 0.0


def _keeps(run: _Runner, costs: List[float], missing: List[int]) -> bool:
    """Reference ``template_pruning`` (inverted): keep a template that reaches a
    missing interval or any interval still below its target."""
    hit = {run.interval_of(c) for c in costs} - {None}
    if hit & set(missing):
        return True
    cur = run.current_counts()
    return any(run.target_counts[i] - cur[i] > 0 for i in hit)


# ---------------------------------------------------------------------------
# Stage 5 driver: interval-by-interval optimisation
# ---------------------------------------------------------------------------

class _Optimiser:
    """Reference ``optimize_for_interval`` bookkeeping."""

    def __init__(self, run: _Runner, templates: List[_Template], rng: random.Random):
        self.run = run
        self.templates = templates
        self.rng = rng
        self.bad: set = set()
        self.missing: set = set()
        self.selected_times = [0] * run.num_intervals
        self.optimised: set = set()     # templates whose remaining space is known
        self.bo_runs = 0

    def largest_deficit(self) -> Tuple[Optional[int], float]:
        cur = self.run.current_counts()
        diffs = [self.run.target_counts[i] - cur[i] if i not in self.missing else -math.inf
                 for i in range(self.run.num_intervals)]
        best = max(diffs)
        if best == -math.inf:
            return None, -math.inf
        return diffs.index(best), best

    def step(self) -> float:
        while True:
            i, deficit = self.largest_deficit()
            if i is None or deficit <= 0:
                return 0
            lo, hi = self.run.bounds(i)
            ranked = sorted(((t, _closeness(t.costs(), lo, hi)) for t in self.templates if t.costs()),
                            key=lambda p: p[1], reverse=True)
            eligible = []
            for t, score in ranked:
                if (i, t.tid) in self.bad:
                    continue
                if t.tid in self.optimised and t.space_size - len(t.evals) < 5 * deficit:
                    continue
                uniq = set(t.costs())
                if len(uniq) <= 3 and not any(lo <= c < hi for c in uniq):
                    continue
                eligible.append((t, score))
            if len(eligible) > 10:
                weights = [s for _, s in eligible]
                pop = [t for t, _ in eligible]
                if sum(weights) <= 0:
                    chosen = self.rng.sample(pop, 10)
                else:
                    chosen = self.rng.choices(pop, weights=weights, k=10)
                eligible = [(t, 0.0) for t in dict.fromkeys(chosen)]
            if not eligible:
                self.missing.add(i)
                continue

            old_diff = deficit
            improved = False
            for t, _ in eligible:
                if (i, t.tid) in self.bad:
                    continue
                before = self.run.current_counts()
                new_costs = _bayesian_optimise(
                    self.run, t, lo, hi, n_trials=int(5 * deficit), n_init=int(0.5 * deficit),
                    reuse_history=True, rng=self.rng,
                )
                self.bo_runs += 1
                self.optimised.add(t.tid)
                after = self.run.current_counts()
                if self.run.target_counts[i] - after[i] < old_diff:
                    improved = True
                useful = _useful(self.run, before, new_costs)
                if (useful / len(new_costs) if new_costs else 0.0) < 0.05:
                    self.bad.add((i, t.tid))
            if not improved:
                self.selected_times[i] += 1
                if self.selected_times[i] >= 5:
                    self.missing.add(i)
            return deficit


def _useful(run: _Runner, before: List[int], costs: List[float]) -> int:
    dist = list(before)
    n = 0
    for c in costs:
        i = run.interval_of(c)
        if i is not None and dist[i] < run.target_counts[i]:
            n += 1
            dist[i] += 1
    return n


# ---------------------------------------------------------------------------
# Target distribution
# ---------------------------------------------------------------------------

def _target_counts(distribution: str, interval_counts: Optional[List[int]], total: int,
                   min_cost: float, max_cost: float, num_intervals: int,
                   seed: Optional[int]) -> List[int]:
    """Reference ``generate_target_sql_distribution``."""
    if interval_counts is not None:
        if len(interval_counts) != num_intervals:
            raise ValueError("interval_counts must have num_intervals entries")
        return [int(c) for c in interval_counts]
    gen = np.random.default_rng(seed)
    if distribution == "normal":
        costs = np.clip(gen.normal((min_cost + max_cost) / 2, (max_cost - min_cost) / 6, total),
                        min_cost, max_cost)
    elif distribution == "uniform":
        costs = gen.uniform(min_cost, max_cost, total)
    elif distribution == "exponential":
        raw = gen.exponential(1.0, total)
        costs = min_cost + raw / raw.max() * (max_cost - min_cost)
    else:
        raise ValueError(f"unknown distribution {distribution!r}")
    counts, _ = np.histogram(costs, bins=np.linspace(min_cost, max_cost, num_intervals + 1))
    return [int(c) for c in counts]


# ---------------------------------------------------------------------------
# Pipeline
# ---------------------------------------------------------------------------

def generate_workload(
    ctx: BaselineContext,
    *,
    workload_name: str,
    num_queries: int = 1000,
    target: str = "card",                 # "card" | "cost"
    distribution: str = "uniform",
    interval_counts: Optional[List[int]] = None,
    min_cost: float = 0,
    max_cost: float = 10000,
    num_intervals: int = 10,
    num_iterations: int = 100,
    semantic_requirements: Optional[List[Tuple[int, str]]] = None,
    profiling_fraction: float = 0.15,
    main_refine_rounds: int = 3,
    difficult_refine_rounds: int = 5,
    time_budget_s: float = 3600,
    workers: int = 8,
    warmup: bool = True,
    random_seed: Optional[int] = None,
    workload_root=None,
) -> Dict[str, Any]:
    """Run the SQLBarber pipeline and write a workload directory + report."""
    if target not in ("card", "cost"):
        raise ValueError("target must be 'card' or 'cost'")
    started_at = datetime.now(timezone.utc)
    t0 = time.time()
    rng = random.Random(random_seed)
    requirements = DEFAULT_SEMANTIC_REQUIREMENTS if semantic_requirements is None else semantic_requirements

    if warmup:
        ctx.warm_up()

    run = _Runner(ctx, target=target, min_cost=min_cost, max_cost=max_cost,
                  num_intervals=num_intervals, workers=workers, rng=rng)
    run.target_counts = _target_counts(distribution, interval_counts, num_queries,
                                       min_cost, max_cost, num_intervals, random_seed)
    distances: List[Dict[str, Any]] = [{"stage": "start", "w1": run.wasserstein(), "t": 0.0}]

    # ---- Stages 1-2: specifications, template generation, self-correction ----
    specs = _scaled_specs(len(run.schema_tables), requirements, rng)
    tid_counter = itertools.count(1)
    tid_lock = threading.Lock()

    def next_tid() -> int:
        with tid_lock:
            return next(tid_counter)

    jobs = [(next_tid(), spec, random.Random(rng.randrange(2**31))) for spec in specs]
    templates: List[_Template] = []
    failed_specs: List[str] = []
    with ThreadPoolExecutor(max_workers=workers) as ex:
        futs = {ex.submit(_generate_template, run, tid, spec, r): spec for tid, spec, r in jobs}
        for fut in as_completed(futs):
            try:
                t = fut.result()
            except Exception as e:
                print(f"[sqlbarber] template generation failed: {type(e).__name__}: {e}")
                t = None
            if t is None:
                failed_specs.append(futs[fut]["spec_id"])
            else:
                templates.append(t)
    templates.sort(key=lambda t: t.tid)

    # ---- Stage 3: profiling ----
    n_profile = max(1, int(profiling_fraction * num_queries))
    for t in templates:
        run.evaluate(t, _profile_configs(t, n_profile, rng))
    distances.append({"stage": "profiling", "w1": run.wasserstein(), "t": time.time() - t0})

    # ---- Stage 4: refinement + pruning ----
    refine_log = _refine_phase(run, templates, next_tid, n_profile=n_profile,
                               main_rounds=main_refine_rounds,
                               difficult_rounds=difficult_refine_rounds, rng=rng)
    distances.append({"stage": "refinement", "w1": run.wasserstein(), "t": time.time() - t0})

    # ---- Stage 5: interval-targeted Bayesian optimisation ----
    opt = _Optimiser(run, templates, rng)
    stop_reason = "num_iterations"
    iter_w1: List[float] = []
    for it in range(num_iterations):
        deficit = opt.step()
        w1 = run.wasserstein()
        iter_w1.append(w1)
        distances.append({"stage": f"iteration_{it + 1}", "w1": w1, "t": time.time() - t0})
        if deficit <= 0:
            stop_reason = "target_matched_or_no_template"
            break
        if time.time() - t0 > time_budget_s:
            stop_reason = "time_budget"
            break
        if len(iter_w1) >= 3 and len(set(iter_w1[-3:])) == 1:
            stop_reason = "distance_stalled"
            break

    # ---- Stage 6: select the workload ----
    by_interval: Dict[int, List[str]] = {i: [] for i in range(num_intervals)}
    for sql, rec in run.pool.items():
        if rec["interval"] is not None:
            by_interval[rec["interval"]].append(sql)
    chosen: List[str] = []
    surplus: List[str] = []
    for i in range(num_intervals):
        qs = sorted(by_interval[i])
        rng.shuffle(qs)
        chosen += qs[:run.target_counts[i]]
        surplus += qs[run.target_counts[i]:]
    rng.shuffle(surplus)
    chosen += surplus[:max(0, num_queries - len(chosen))]
    chosen = chosen[:num_queries]
    chosen.sort(key=lambda s: run.pool[s]["cost"])

    tmpl_by_id = {t.tid: t for t in templates}
    accepted = []
    for sql in chosen:
        rec = run.pool[sql]
        t = tmpl_by_id.get(rec["tid"])
        accepted.append({
            "sql": sql,
            "goal": (t.spec.get("semantic_requirement") if t else None) or "SQLBarber templated query",
            "extra": {
                "template_id": rec["tid"],
                "template_origin": t.origin if t else "pruned_refinement",
                "spec_id": t.spec.get("spec_id") if t else None,
                "cost_target": target,
                "cost": rec["cost"],
                "interval": rec["interval"],
            },
        })

    final_counts = [0] * num_intervals
    for q in accepted:
        final_counts[q["extra"]["interval"]] += 1
    est = run.estimates

    pipeline_report = {
        "method": "SQLBarber (Lao & Trummer, SIGMOD 2026)",
        "stages": [
            "Redset template specifications rescaled to the schema + semantic requirements",
            "LLM template generation with constraint-check and grammar-check self-correction",
            "profiling (default + Latin hypercube predicate assignments)",
            "LLM template refinement for missing/difficult cost intervals + pruning",
            "interval-targeted Bayesian optimisation over predicate values",
            "per-interval selection of in-range queries",
        ],
        "cost_target": target,
        "cost_definition": ("sum of estimated output rows over operator nodes" if target == "card"
                            else "sum of estimated CPU cost over operator nodes"),
        "target_distribution": {
            "distribution": "interval_counts" if interval_counts is not None else distribution,
            "min_cost": min_cost, "max_cost": max_cost, "num_intervals": num_intervals,
            "target_counts": run.target_counts,
            "pool_counts": run.current_counts(),
            "workload_counts": final_counts,
        },
        "wasserstein_distance": run.wasserstein(final_counts),
        "distance_history": distances,
        "specs": specs,
        "templates": [
            {"template_id": t.tid, "origin": t.origin, "spec_id": t.spec.get("spec_id"),
             "tables": t.tables, "placeholders": t.dims,
             "invalid_placeholders": t.invalid_placeholders, "space_size": t.space_size,
             "evaluations": len(t.evals), "in_range": sum(1 for c in t.costs() if run.interval_of(c) is not None),
             "sql_template": t.sql, **t.log}
            for t in templates
        ],
        "failed_specs": failed_specs,
        "refinement": refine_log,
        "optimisation": {
            "iterations": len(iter_w1), "bo_runs": opt.bo_runs, "stop_reason": stop_reason,
            "missing_intervals": sorted(opt.missing), "bad_combinations": len(opt.bad),
            "time_budget_s": time_budget_s, "elapsed_s": time.time() - t0,
        },
        "estimates": {
            **est,
            "unestimated_node_share": (est["unestimated_nodes"] / est["operator_nodes"]
                                       if est["operator_nodes"] else None),
        },
        "counts": {"pool_queries": len(run.pool), "accepted": len(accepted), "target": num_queries},
        "validation": "Trino EXPLAIN (FORMAT JSON) cost estimates",
    }

    return write_baseline_workload(
        baseline=BASELINE,
        workload_name=workload_name,
        queries=accepted,
        ctx=ctx,
        started_at=started_at,
        pipeline_report=pipeline_report,
        workload_root=workload_root,
    )
