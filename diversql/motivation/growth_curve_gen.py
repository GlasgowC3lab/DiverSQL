"""Generate a TPC-DS workload with dsqgen and normalise it to Trino-compatible q*.sql files."""
import re
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Iterator

sys.path.insert(0, str(Path(__file__).resolve().parents[2]))  # repo root

from config import DSQGEN_BIN, TPCDS_TEMPLATES_DIR as TEMPLATES_DIR, GROWTH_CURVE_WORKLOAD_DIR  # noqa: E402

TEMPLATES_LST = TEMPLATES_DIR / "templates.lst"
DISTRIBUTIONS = "tpcds.idx"  # resolved relative to the tools dir (-DIRECTORY doesn't cover it)
TOOLS_DIR = DSQGEN_BIN.parent

MULTI_STMT_TEMPLATES = {"query14.tpl", "query23.tpl", "query24.tpl", "query39.tpl"}

START_RE = re.compile(
    r"^-- start query (\d+) in stream (\d+) using template (\S+)\s*$"
)
END_RE = re.compile(
    r"^-- end query (\d+) in stream (\d+) using template (\S+)\s*$"
)


def run_dsqgen(streams: int, rngseed: int, out_dir: Path) -> None:
    out_dir = out_dir.resolve()
    out_dir.mkdir(parents=True, exist_ok=True)
    # NB: dsqgen (2008-era tpcds-kit C binary) corrupts memory when given long
    # absolute paths for -DIRECTORY/-INPUT (looks like a fixed-size buffer
    # overflow) -- pass paths relative to TOOLS_DIR (its cwd) instead, which
    # is stable. -OUTPUT_DIR tolerates an absolute path fine.
    cmd = [
        "./dsqgen",
        "-QUIET", "Y",
        "-STREAMS", str(streams),
        "-RNGSEED", str(rngseed),
        "-SCALE", "1",
        "-DIRECTORY", "../query_templates",
        "-INPUT", "../query_templates/templates.lst",
        "-DIALECT", "netezza",
        "-OUTPUT_DIR", str(out_dir),
        "-DISTRIBUTIONS", DISTRIBUTIONS,
    ]
    # NB: dsqgen (2008-era tpcds-kit C binary) segfaults with malloc corruption
    # when its stdout/stderr are connected to a pipe (subprocess.PIPE) -- redirect
    # to real files instead, which is stable.
    stdout_log = out_dir / "_dsqgen_stdout.log"
    stderr_log = out_dir / "_dsqgen_stderr.log"
    with stdout_log.open("w") as out, stderr_log.open("w") as err:
        result = subprocess.run(cmd, cwd=TOOLS_DIR, stdout=out, stderr=err)
    stdout_text = stdout_log.read_text()
    stderr_text = stderr_log.read_text()
    if result.returncode != 0 or "Error" in stderr_text or "ERROR" in stdout_text:
        raise RuntimeError(f"dsqgen failed: rc={result.returncode}\nstdout={stdout_text}\nstderr={stderr_text}")


@dataclass
class RawQuery:
    stream: int
    position_in_stream: int
    template: str
    sql: str


def _iter_stream_blocks(text: str) -> Iterator[RawQuery]:
    lines = text.split("\n")
    i = 0
    n = len(lines)
    while i < n:
        m = START_RE.match(lines[i])
        if not m:
            i += 1
            continue
        pos, stream, template = int(m.group(1)), int(m.group(2)), m.group(3)
        body_lines = []
        i += 1
        while i < n and not END_RE.match(lines[i]):
            body_lines.append(lines[i])
            i += 1
        i += 1  # skip the end marker
        body = "\n".join(body_lines).strip("\n")
        yield RawQuery(stream=stream, position_in_stream=pos, template=template, sql=body)


def parse_all_streams(out_dir: Path, n_streams: int) -> list[RawQuery]:
    """Read query_0.sql .. query_{n_streams-1}.sql in stream order."""
    all_queries: list[RawQuery] = []
    for s in range(n_streams):
        f = out_dir / f"query_{s}.sql"
        text = f.read_text()
        all_queries.extend(_iter_stream_blocks(text))
    return all_queries


def split_multi_statement(raw: RawQuery) -> list[str]:
    """Split a block's SQL into one or more individual statements on
    top-level ';' terminators (only query14/23/24/39 templates pack two)."""
    if raw.template not in MULTI_STMT_TEMPLATES:
        stmt = raw.sql.strip()
        if stmt.endswith(";"):
            stmt = stmt[:-1].rstrip()
        return [stmt]

    parts = [p.strip() for p in raw.sql.split(";")]
    parts = [p for p in parts if p]
    return parts


# ---------------------------------------------------------------------
# Trino-dialect normalisation
# ---------------------------------------------------------------------

_INTERVAL_RE = re.compile(
    r"(cast\s*\(\s*'[\d-]+'\s*as\s*date\s*\))\s*([+-])\s*(\d+)\s*days?\b",
    re.IGNORECASE,
)
_DEC_RE = re.compile(r"\bdec\(", re.IGNORECASE)
_NUMERIC_RE = re.compile(r"\bnumeric\(", re.IGNORECASE)
_D_DATE_EQ_RE = re.compile(r"\bd_date\s*=\s*'([\d-]+)'")
_D_DATE_BETWEEN_RE = re.compile(r"\bd_date\s+between\s+'([\d-]+)'\s+and\b", re.IGNORECASE)
_D_DATE_IN_RE = re.compile(r"\bd_date\s+in\s*\(\s*((?:'[\d-]+'\s*,?\s*)+)\)", re.IGNORECASE)
_D_DATE_IN_LIT_RE = re.compile(r"'([\d-]+)'")
_QUERY72_BARE_RE = re.compile(r"d1\.d_date\s*\+\s*5\b")

_SELECTCONE_FIX = {
    "t_s_secyear.c_preferred_cust_flag": "t_s_secyear.customer_preferred_cust_flag",
    "t_s_secyear.c_birth_country": "t_s_secyear.customer_birth_country",
    "t_s_secyear.c_login": "t_s_secyear.customer_login",
    "t_s_secyear.c_email_address": "t_s_secyear.customer_email_address",
}


def normalise_sql(sql: str) -> str:
    s = sql

    s = _INTERVAL_RE.sub(lambda m: f"{m.group(1)} {m.group(2)} interval '{m.group(3)}' day", s)
    s = _QUERY72_BARE_RE.sub("(cast(d1.d_date AS DATE) + interval '5' DAY)", s)
    s = _DEC_RE.sub("decimal(", s)
    s = _NUMERIC_RE.sub("decimal(", s)
    s = _D_DATE_EQ_RE.sub(lambda m: f"d_date = CAST('{m.group(1)}' AS DATE)", s)
    s = _D_DATE_BETWEEN_RE.sub(lambda m: f"d_date between CAST('{m.group(1)}' AS DATE) and", s)

    def _wrap_in_list(m: re.Match) -> str:
        wrapped = _D_DATE_IN_LIT_RE.sub(lambda lm: f"CAST('{lm.group(1)}' AS DATE)", m.group(1))
        return f"d_date in ({wrapped})"

    s = _D_DATE_IN_RE.sub(_wrap_in_list, s)

    for bad, good in _SELECTCONE_FIX.items():
        s = s.replace(bad, good)

    return s.strip()


# ---------------------------------------------------------------------
# End-to-end: generate + normalise + write a workload directory of q*.sql
# files (in dsqgen generation order) + a generation_report.json, in the
# same shape as Workloads/tpcds / tpcds_1000 / TPCDS_10000.
# ---------------------------------------------------------------------

def write_workload(
    out_workload_dir: Path,
    *,
    streams: int,
    rngseed: int,
    scratch_dir: Path,
) -> dict:
    """Run dsqgen for `streams` streams, normalise every query, and write
    them out as q1.sql, q2.sql, ... in stream-major generation order.
    Returns the generation_report.json dict that was written."""
    import json
    from datetime import datetime, timezone

    run_dsqgen(streams=streams, rngseed=rngseed, out_dir=scratch_dir)
    raws = parse_all_streams(scratch_dir, streams)

    out_workload_dir.mkdir(parents=True, exist_ok=True)
    report_queries = []
    i = 0
    for r in raws:
        for stmt in split_multi_statement(r):
            i += 1
            sql = normalise_sql(stmt)
            fname = f"q{i}.sql"
            (out_workload_dir / fname).write_text(sql + "\n")
            report_queries.append({
                "file": fname,
                "template": r.template.replace(".tpl", ""),
                "stream": r.stream,
                "position_in_stream": r.position_in_stream,
            })

    template_counts: dict[str, int] = {}
    for q in report_queries:
        template_counts[q["template"]] = template_counts.get(q["template"], 0) + 1

    report = {
        "workload_name": out_workload_dir.name,
        "workload_dir": str(out_workload_dir),
        "source": "official TPC-DS query generator (dsqgen, tpcds-kit) via iceberg-spark-tpcds-benchmark",
        "created_at_utc": datetime.now(timezone.utc).isoformat(),
        "num_queries": len(report_queries),
        "num_templates": 99,
        "generator": {"tool": "dsqgen", "scale": 1, "dialect": "netezza",
                       "rngseed": rngseed, "streams_generated": streams},
        "trino_normalization": [
            "'+/- N day(s)' -> ANSI INTERVAL literal",
            "bare 'd_date +/- N' (query72) -> ANSI INTERVAL literal",
            "'dec(p,s)' -> 'decimal(p,s)'",
            "'numeric(p,s)' -> 'decimal(p,s)'",
            "'d_date = <string literal>' / 'd_date between <string literal> and ...' / "
            "'d_date in (<string literals>)' -> explicit DATE literals",
            "query4/query11: patched known tpcds-kit SELECTCONE macro bug (wrong column aliases on t_s_secyear)",
            "query14/23/24/39: split the two packed sub-queries into separate query files",
            "stripped trailing ';' from every emitted query",
        ],
        "template_counts": template_counts,
        "queries": report_queries,
    }
    (out_workload_dir / "generation_report.json").write_text(json.dumps(report, indent=2))
    return report


if __name__ == "__main__":
    import argparse

    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("out_workload_dir", type=Path, nargs="?", default=GROWTH_CURVE_WORKLOAD_DIR)
    ap.add_argument("--streams", type=int, default=105)
    ap.add_argument("--rngseed", type=int, default=20260917)
    ap.add_argument("--scratch-dir", type=Path, default=None)
    args = ap.parse_args()

    scratch = args.scratch_dir or (args.out_workload_dir.parent / f".{args.out_workload_dir.name}_dsqgen_raw")
    report = write_workload(args.out_workload_dir, streams=args.streams, rngseed=args.rngseed, scratch_dir=scratch)
    print(f"wrote {report['num_queries']} queries to {args.out_workload_dir}")
