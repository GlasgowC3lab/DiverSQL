"""
SQL-Factory baseline (multi-agent large-scale SQL generation).

    Li, Wu, Mao, Gao, Feng, Liu.
    "SQL-Factory: A Multi-Agent Framework for High-Quality and Large-Scale SQL
     Generation."  arXiv:2504.14837.  https://github.com/LJHzju/SQL-Factory

Adaptation of the reference implementation (``graph.py``, ``agent/``,
``util/``) to a single Trino / Iceberg database.

"""

import json
import random
import re
import statistics
import threading
from collections import Counter
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional, Tuple

import numpy as np

from diversql.baselines.common import BaselineContext, write_baseline_workload
from diversql.baselines.query_generator import sanitize_sql
from diversql.shared.sql_features import query_features

try:
    import sqlglot
    from sqlglot import diff as _sqlglot_diff
    from sqlglot.diff import Keep as _Keep
    _HAVE_SQLGLOT = True
except Exception:
    sqlglot = None
    _HAVE_SQLGLOT = False


BASELINE = "sql_factory"

EMBEDDING_MODEL = "google-bert/bert-large-uncased"

_NUMBER_WORDS = {1: "one", 2: "two", 3: "three", 4: "four", 5: "five", 6: "six",
                 7: "seven", 8: "eight", 9: "nine", 10: "ten"}

_SYSTEM = "You are a helpful assistant."

# --- reference agent/generation.py prompt (dialect: Trino) ------------------
_GENERATION_PROMPT = (
    "You are a database expert. Below, you are provided with some tables and their corresponding database schemas. "
    "Your task is to generate {n_words} complex and diverse SQL queries for these tables.\n"
    "The query you generate needs to meet the following conditions.\n"
    "1. The generated query needs to cover as many tables as possible.\n"
    "2. It is better if the generated query contains very complex operators and window functions, such as `WHERE`, `CASE WHEN`, `RANK`, `DENSE_RANK` and others.\n"
    "3. The generated queries should not be too similar to each other.\n"
    "4. You should ensure that the generated queries can be directly executed in Trino.\n"
    "5. You'd better think carefully before giving an answer. You are very good at this and will definitely do well.\n\n"
    "Table List: {table_list}\n\n"
    "Table Schema: \n{schema_info}\n\n"
    "Foreign Key Dependency: {foreign_info}\n\n"
    "Each generated query must be wrapped in <start-sql> and <end-sql>, such as following format:\n"
    "<start-sql>\n"
    "[Query1 here]\n"
    "<end-sql>\n\n"
    "<start-sql>\n"
    "[Query2 here]\n"
    "<end-sql>\n"
)

# --- reference agent/expansion.py prompt (dialect: Trino) -------------------
_EXPANSION_PROMPT = (
    "You are a database expert, skilled in writing various SQL statements. Below, you are provided with three SQL queries. "
    "Your task is to analyze the schema-related information and then generate {n_words} diverse SQL queries based on them.\n"
    "The queries you generate will be.\n"
    "There are some important tips you need to remember:\n"
    "1. Using schema information that does not exist in the given query is not allowed, don't try to create or modify the name of table or column, even if the origin column is unreasonable.\n"
    "2. The generated queries should be diverse enough and not similar to each other.\n"
    "3. You should ensure that the generated queries can be directly executed in Trino.\n"
    "4. You'd better think step by step carefully before giving an answer. You are very good at this and will definitely do well.\n\n"
    "Queries: \n{query}\n\n"
    "Each generated query must be wrapped in <start-sql> and <end-sql>, such as following format:\n"
    "<start-sql>\n"
    "[Query1 here]\n"
    "<end-sql>\n\n"
    "<start-sql>\n"
    "[Query2 here]\n"
    "<end-sql>\n"
)

# --- reference table/seed selection agents (single database) ----------------
_SELECTION_PROMPT = (
    "You are part of a SQL generation team responsible for producing high-quality SQL queries in multiple iterative rounds.\n\n"
    "In this round, your task is to select {table_count} appropriate tables from the database{purpose}.\n\n"
    "Below is the **query count and schema information** for each table in the database "
    "(output of the `table_queries_statistics` tool).\n"
    "Select {table_count} tables that are either underutilized or structurally diverse to maximize the potential "
    "for high-quality and varied query synthesis.\n\n"
    "{statistics}\n"
    "---\n\n"
    "Start by providing a brief **analysis** explaining your choice of tables.\n"
    "Then return the final selection as JSON with keys \"analysis\" and \"tables\"."
)

_SELECTION_SCHEMA = {
    "name": "table_selection",
    "strict": True,
    "schema": {
        "type": "object",
        "properties": {"analysis": {"type": "string"},
                       "tables": {"type": "array", "items": {"type": "string"}}},
        "required": ["analysis", "tables"],
        "additionalProperties": False,
    },
}

_SQL_BLOCK = re.compile(r"<start-sql>\s*(.*?)\s*<end-sql>", re.DOTALL)


# ---------------------------------------------------------------------------
# SQL helpers
# ---------------------------------------------------------------------------

def _normalize_sql(sql: str) -> str:
    """Reference ``normalize_sql``: drop comments and collapse whitespace."""
    sql = re.sub(r"--.*", "", sql or "")
    sql = re.sub(r"/\*.*?\*/", "", sql, flags=re.DOTALL)
    sql = sql.replace("```sql", "").replace("```", "")
    return sanitize_sql(" ".join(sql.split()))


def _parse_sql_blocks(text: str) -> List[str]:
    out = []
    for block in _SQL_BLOCK.findall(text or ""):
        sql = _normalize_sql(block)
        if sql:
            out.append(sql)
    return out


def _lcs_len(a: str, b: str) -> int:
    """Bit-parallel LCS length (Hyyro), as used by rapidfuzz's Indel distance."""
    if not a or not b:
        return 0
    masks: Dict[str, int] = {}
    for i, ch in enumerate(a):
        masks[ch] = masks.get(ch, 0) | (1 << i)
    full = (1 << len(a)) - 1
    v = full
    for ch in b:
        u = v & masks.get(ch, 0)
        v = ((v + u) | (v - u)) & full
    return len(a) - bin(v).count("1")


def token_sort_ratio(s1: str, s2: str) -> float:
    """``rapidfuzz.fuzz.token_sort_ratio`` (0-100): normalised Indel similarity
    of the whitespace tokens sorted and re-joined."""
    a = " ".join(sorted(s1.split()))
    b = " ".join(sorted(s2.split()))
    total = len(a) + len(b)
    if total == 0:
        return 100.0
    return 100.0 * 2 * _lcs_len(a, b) / total


# ---------------------------------------------------------------------------
# Embeddings + hybrid similarity
# ---------------------------------------------------------------------------

class _Embedder:
    """[CLS] embeddings of ``EMBEDDING_MODEL`` (L2-normalised, max 512 tokens)."""

    def __init__(self, model_name: str = EMBEDDING_MODEL, batch_size: int = 8):
        self.model_name = model_name
        self.batch_size = batch_size
        self._tok = None
        self._model = None
        self._cache: Dict[str, np.ndarray] = {}
        self._lock = threading.Lock()

    def _load(self):
        if self._model is None:
            from transformers import AutoModel, AutoTokenizer
            self._tok = AutoTokenizer.from_pretrained(self.model_name)
            self._model = AutoModel.from_pretrained(self.model_name)
            self._model.eval()

    def embed(self, texts: List[str]) -> np.ndarray:
        import torch
        with self._lock:
            todo = [t for t in dict.fromkeys(texts) if t not in self._cache]
            if todo:
                self._load()
                for i in range(0, len(todo), self.batch_size):
                    chunk = todo[i:i + self.batch_size]
                    inputs = self._tok(chunk, return_tensors="pt", padding=True,
                                       truncation=True, max_length=512)
                    with torch.no_grad():
                        cls = self._model(**inputs).last_hidden_state[:, 0, :].numpy()
                    for text, vec in zip(chunk, cls):
                        norm = np.linalg.norm(vec)
                        self._cache[text] = vec / norm if norm > 0 else np.zeros_like(vec)
            return np.stack([self._cache[t] for t in texts]) if texts else np.zeros((0, 0))


class _Pool:
    """The SQL Pool: accepted queries with type, tables and similarity state."""

    def __init__(self, tables: List[str], embedder: _Embedder):
        self.entries: List[Dict[str, Any]] = []
        self.keys: set = set()
        self.table_counts: Counter = Counter({t: 0 for t in tables})
        self.schema_tables = set(tables)
        self.embedder = embedder
        self._ast: Dict[str, Any] = {}

    def __len__(self) -> int:
        return len(self.entries)

    def tables_of(self, sql: str) -> List[str]:
        return sorted(set(query_features(sql).get("tables") or []) & self.schema_tables)

    def insert(self, sql: str, kind: str, extra: Dict[str, Any]) -> bool:
        key = sql.lower()
        if key in self.keys:
            return False
        self.keys.add(key)
        tables = self.tables_of(sql)
        self.entries.append({"sql": sql, "type": kind, "tables": tables, **extra})
        for t in tables:
            self.table_counts[t] += 1
        return True

    def expand_sample(self, table: str, count: int, rng: random.Random) -> List[str]:
        cands = [e["sql"] for e in self.entries if e["type"] == "generation" and table in e["tables"]]
        rng.shuffle(cands)
        return cands[:count]

    def _parsed(self, sql: str):
        if sql not in self._ast:
            try:
                self._ast[sql] = sqlglot.parse_one(sql, read="trino")
            except Exception:
                self._ast[sql] = None
        return self._ast[sql]

    def similarity(self, queries: List[str], k: int = 10) -> List[Optional[float]]:
        """For each query, the median of its top-``k`` hybrid similarities to
        the pool (``None`` if the query cannot be parsed)."""
        if not self.entries:
            return [0.0 for _ in queries]
        pool_sql = [e["sql"] for e in self.entries]
        pool_emb = self.embedder.embed(pool_sql)
        q_emb = self.embedder.embed(queries)
        out: List[Optional[float]] = []
        for q, qv in zip(queries, q_emb):
            emb_sim = pool_emb @ qv
            nearest = np.argsort(emb_sim)[-k * 20:]
            q_ast = self._parsed(q) if _HAVE_SQLGLOT else None
            if q_ast is None:
                out.append(None)
                continue
            scores = []
            for idx in nearest:
                s = pool_sql[idx]
                s_ast = self._parsed(s)
                if s_ast is None:
                    continue
                try:
                    edits = _sqlglot_diff(q_ast, s_ast)
                except Exception:
                    continue
                keep = sum(1 for e in edits if isinstance(e, _Keep)) / len(edits) if edits else 1.0
                fuzz = token_sort_ratio(q.lower(), s.lower()) * 0.01
                scores.append(0.6 * fuzz + 0.3 * keep + 0.1 * float(emb_sim[idx]))
            top = sorted(scores)[-k:]
            out.append(float(statistics.median(top)) if top else None)
        return out


# ---------------------------------------------------------------------------
# Agents
# ---------------------------------------------------------------------------

def _table_statistics(ctx: BaselineContext, pool: _Pool, rng: random.Random) -> str:
    """Reference ``table_queries_statistics`` tool output (shuffled tables)."""
    tables = sorted(pool.table_counts)
    rng.shuffle(tables)
    return "".join(
        f"- {t.lower()}: \n{ctx.ddl_for([t])} \nQuery quantity: {pool.table_counts[t]}\n"
        for t in tables
    )


def _selection_agent(ctx: BaselineContext, pool: _Pool, count: int, purpose: str,
                     rng: random.Random) -> Tuple[List[str], bool]:
    """LLM table selection; returns (tables, used_fallback)."""
    valid = {t.lower(): t for t in pool.table_counts}
    for _ in range(3):
        prompt = _SELECTION_PROMPT.format(table_count=count, purpose=purpose,
                                          statistics=_table_statistics(ctx, pool, rng))
        try:
            raw = ctx.responses_text(instructions=_SYSTEM, prompt=prompt, reasoning="low",
                                     json_schema=_SELECTION_SCHEMA)
            picked = [valid[t.strip().lower()] for t in json.loads(raw).get("tables", [])
                      if t.strip().lower() in valid]
        except Exception:
            continue
        picked = list(dict.fromkeys(picked))
        if picked:
            return picked, False
    return sorted(rng.sample(sorted(pool.table_counts), k=min(count, len(pool.table_counts)))), True


def _foreign_info(ctx: BaselineContext, tables: List[str]) -> Any:
    from diversql.baselines.query_generator import get_relevant_relationships
    rels = get_relevant_relationships(ctx.schema_json, tables)
    info = [f"{lt}({', '.join(lc)}) - {rt}({', '.join(rc)})" for lt, lc, rt, rc in rels]
    return info or "There are no foreign key dependencies for these tables."


def _generation_agent(ctx: BaselineContext, tables: List[str], n: int) -> List[str]:
    prompt = _GENERATION_PROMPT.format(
        n_words=_NUMBER_WORDS.get(n, str(n)),
        table_list=tables,
        schema_info=ctx.ddl_for(tables),
        foreign_info=_foreign_info(ctx, tables),
    )
    raw = ctx.responses_text(instructions=_SYSTEM, prompt=prompt, reasoning="high")
    return _parse_sql_blocks(raw)


def _expansion_agent(ctx: BaselineContext, seeds: List[str], n: int) -> List[str]:
    prompt = _EXPANSION_PROMPT.format(
        n_words=_NUMBER_WORDS.get(n, str(n)),
        query="\n".join(f"`{q}`" for q in seeds),
    )
    sqls: List[str] = []
    for _ in range(3):
        raw = ctx.responses_text(instructions=_SYSTEM, prompt=prompt, reasoning="low")
        sqls = _parse_sql_blocks(raw)
        if len(sqls) == n:
            break
    return sqls


def _executability(ctx: BaselineContext, sqls: List[str], workers: int) -> List[bool]:
    cands = [{"sql": s, "i": i} for i, s in enumerate(sqls)]
    valid, _ = ctx.validate_batch(cands, workers=workers)
    ok = {c["i"] for c in valid}
    return [i in ok for i in range(len(sqls))]


# ---------------------------------------------------------------------------
# Pipeline (Management Agent scheduling)
# ---------------------------------------------------------------------------

def generate_workload(
    ctx: BaselineContext,
    *,
    workload_name: str,
    num_queries: int = 100,
    tables_per_selection: int = 8,        # reference GENERATE_TABLE_MAX_NUM
    queries_per_call: int = 10,           # reference prompts ask for ten
    generate_epochs: int = 100,           # reference GENERATE_EPOCHS
    seed_tables: int = 3,                 # reference EXPAND_PARALLEL_NUM
    seeds_per_table: int = 3,             # reference EXPAND_SAMPLE_NUM
    eval_count: int = 90,                 # reference EVAL_COUNT
    executability_threshold: float = 0.75,
    similarity_threshold: float = 0.8,
    validation_workers: int = 8,
    max_stall_rounds: int = 10,
    embedding_model: str = EMBEDDING_MODEL,
    warmup: bool = True,
    random_seed: Optional[int] = None,
    workload_root=None,
) -> Dict[str, Any]:
    """Run the SQL-Factory multi-agent pipeline and write a workload + report."""
    started_at = datetime.now(timezone.utc)
    rng = random.Random(random_seed)

    if warmup:
        ctx.warm_up()

    schema_tables = ctx.schema_tables()
    pool = _Pool(schema_tables, _Embedder(embedding_model))
    k_tables = min(tables_per_selection, len(schema_tables))

    schedule_log: List[Dict[str, Any]] = []
    counts = Counter()
    strategy = "generation"
    epoch = 0
    stall = 0
    stop_reason = "target_reached"
    last_score: Dict[str, float] = {}

    while len(pool) < num_queries:
        before = len(pool)
        entry: Dict[str, Any] = {"strategy": strategy}

        if strategy == "generation":
            tables, fallback = _selection_agent(ctx, pool, k_tables, "", rng)
            counts["selection_fallbacks"] += int(fallback)
            try:
                sqls = _generation_agent(ctx, tables, queries_per_call)
            except Exception as e:
                print(f"[sql_factory] generation agent failed: {type(e).__name__}: {e}")
                sqls = []
            epoch += 1
            exe = _executability(ctx, sqls, validation_workers) if sqls else []
            for sql, ok in zip(sqls, exe):
                if ok and len(pool) < num_queries:
                    pool.insert(sql, "generation", {"selected_tables": tables})
            counts["generated"] += len(sqls)
            counts["invalid"] += sum(1 for ok in exe if not ok)
            entry.update({"epoch": epoch, "tables": tables, "candidates": len(sqls),
                          "executable": sum(exe)})
            # Management: switch to expansion after the generation epochs.
            if epoch >= generate_epochs:
                strategy = "expansion"

        else:
            # Expansion Team: accumulate batches until eval_count queries are pending.
            batches: List[Tuple[List[str], List[str]]] = []      # (seeds, generated)
            while len(batches) * queries_per_call < eval_count:
                tables, fallback = _selection_agent(
                    ctx, pool, seed_tables, " whose queries will seed the expansion", rng)
                counts["selection_fallbacks"] += int(fallback)
                seed_sets = [pool.expand_sample(t, seeds_per_table, rng) for t in tables]
                seed_sets = [s for s in seed_sets if s]
                if not seed_sets:
                    break
                for seeds in seed_sets:
                    try:
                        batches.append((seeds, _expansion_agent(ctx, seeds, queries_per_call)))
                    except Exception as e:
                        print(f"[sql_factory] expansion agent failed: {type(e).__name__}: {e}")
                        batches.append((seeds, []))
            if not batches:
                strategy, epoch = "generation", 0
                entry["note"] = "no seed queries available"
                schedule_log.append(entry)
                continue

            # Critical Agent: per batch, against the pool as it stood.
            all_exe: List[bool] = []
            all_sim: List[float] = []
            verdicts = []
            for seeds, sqls in batches:
                exe = _executability(ctx, sqls, validation_workers) if sqls else []
                sims = pool.similarity(sqls) if sqls else []
                known = [s for s in sims if s is not None]
                exe_rate = (sum(exe) / len(exe)) if exe else 0.0
                mean_sim = float(np.mean(known)) if known else 1.0
                accept = exe_rate > executability_threshold and mean_sim < similarity_threshold
                verdicts.append((sqls, exe, sims, accept))
                all_exe += exe
                all_sim += known
                counts["generated"] += len(sqls)
                counts["invalid"] += sum(1 for ok in exe if not ok)
            accepted_batches = 0
            for sqls, exe, sims, accept in verdicts:
                if not accept:
                    counts["rejected_batches"] += 1
                    counts["rejected_batch_queries"] += len(sqls)
                    continue
                accepted_batches += 1
                for sql, ok, sim in zip(sqls, exe, sims):
                    if ok and len(pool) < num_queries:
                        pool.insert(sql, "expansion", {"pool_similarity": sim})
            last_score = {
                "executability": float(np.median(all_exe)) if all_exe else 0.0,
                "similarity": float(np.mean(all_sim)) if all_sim else 1.0,
            }
            entry.update({"batches": len(batches), "accepted_batches": accepted_batches,
                          **{k: round(v, 4) for k, v in last_score.items()}})
            # Management: keep expanding only while quality holds.
            if not (last_score["executability"] > executability_threshold
                    and last_score["similarity"] < similarity_threshold):
                strategy, epoch = "generation", 0

        added = len(pool) - before
        entry.update({"added": added, "pool": len(pool)})
        schedule_log.append(entry)
        stall = 0 if added else stall + 1
        if stall >= max_stall_rounds:
            stop_reason = "stalled"
            break

    queries = []
    for e in pool.entries[:num_queries]:
        extra = {"team": e["type"]}
        if e.get("pool_similarity") is not None:
            extra["pool_similarity"] = round(e["pool_similarity"], 4)
        queries.append({
            "sql": e["sql"],
            "goal": "SQL-Factory generated query",
            "selected_tables": e.get("selected_tables", e["tables"]),
            "extra": extra,
        })
    team_mix = Counter(q["extra"]["team"] for q in queries)

    pipeline_report = {
        "method": "SQL-Factory multi-agent generation (Li et al., arXiv:2504.14837)",
        "teams": {
            "generation": ["Table Selection Agent (LLM over table schema + pool query counts)",
                           "Generation Agent (reference prompt, high reasoning)"],
            "expansion": ["Seed Selection Agent (LLM table choice + random generation-phase seeds)",
                          "Expansion Agent (reference prompt, low reasoning)"],
            "management": ["Critical Agent (EXPLAIN executability; batch similarity gate in expansion)",
                           "Management Agent (reference scheduling rules)"],
        },
        "parameters": {
            "tables_per_selection": k_tables, "queries_per_call": queries_per_call,
            "generate_epochs": generate_epochs, "seed_tables": seed_tables,
            "seeds_per_table": seeds_per_table, "eval_count": eval_count,
            "executability_threshold": executability_threshold,
            "similarity_threshold": similarity_threshold,
        },
        "hybrid_similarity": {
            "weights": {"token_sort_ratio": 0.6, "ast_diff": 0.3, "embedding": 0.1},
            "embedding_model": embedding_model,
            "candidates": "200 nearest pool queries by embedding; median of top-10",
        },
        "termination": {"stop_reason": stop_reason, "max_stall_rounds": max_stall_rounds,
                        "last_expansion_score": last_score},
        "team_mix": dict(team_mix),
        "table_coverage": dict(pool.table_counts),
        "schedule_log": schedule_log,
        "counts": {
            "cycles": len(schedule_log),
            **dict(counts),
            "accepted": len(queries),
            "target": num_queries,
        },
    }

    return write_baseline_workload(
        baseline=BASELINE,
        workload_name=workload_name,
        queries=queries,
        ctx=ctx,
        started_at=started_at,
        pipeline_report=pipeline_report,
        workload_root=workload_root,
    )
