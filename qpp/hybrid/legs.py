import json
import sys
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

ROOT = Path(__file__).resolve().parents[2]  # repo root
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from config import WORKLOADS_DIR  # noqa: E402
from qpp.config import (  # noqa: E402
    PARSED_RESULTS_ROOT, METRIC, XCOL, YCOL, SEED, SCHEMA_NAME, LAKEHOUSE_INSTANCE_NAME, WORKLOAD_RUNS,
    REFERENCE_WORKLOAD,
)
from qpp.qpp_harness import load_multi_source_qpp_data, QPPDataBundle, default_queries_dir_for  # noqa: E402


REAL_LEG = "tpcds"
OURS = "gpt_generated"
BASELINE_LEGS = ["sqlbarber", "bootstrapping_lcm", "sql_factory", "e2etune", "sqlstorm"]
GENERATED_LEGS = [OURS] + BASELINE_LEGS

GENERATED_TEST_FRAC = 0.18


def _queries_dir_for(run_id: str) -> str:
    return default_queries_dir_for(run_id, schema=SCHEMA_NAME, instance=LAKEHOUSE_INSTANCE_NAME)


def _tpcds_fixed_test_qids() -> List[str]:
    report = json.loads((WORKLOADS_DIR / REFERENCE_WORKLOAD / "generation_report.json").read_text())
    return [Path(f).stem for f in report["train_test_split"]["test_query_files"]]


# Collections and run IDs come from qpp/config.py; the real leg is split by its fixed structural holdout.
LEGS: Dict[str, Dict[str, Any]] = {name: dict(spec) for name, spec in WORKLOAD_RUNS.items()}
LEGS[REAL_LEG]["fixed_test_qids"] = _tpcds_fixed_test_qids()


def build_universe_bundle(
    *, seed: int = SEED, legs: Optional[Dict[str, Dict[str, Any]]] = None,
    generated_test_frac: float = GENERATED_TEST_FRAC,
) -> Tuple[QPPDataBundle, List[str], List[str]]:
    legs = legs if legs is not None else LEGS
    sources: List[Dict[str, Any]] = []
    available: List[str] = []
    skipped: List[str] = []

    for name, spec in legs.items():
        run_ids = spec.get("run_ids") or []
        if not run_ids:
            print(f"[missing] {name} ({spec['collection']}): no execution run recorded -- skipping.")
            skipped.append(name)
            continue

        queries_dir = _queries_dir_for(run_ids[0])
        src: Dict[str, Any] = dict(
            collection=spec["collection"],
            queries_dir=queries_dir,
            run_ids=run_ids,
            prefix=f"{name}::",
        )
        if spec.get("fixed_test_qids") is not None:
            src["fixed_test_qids"] = spec["fixed_test_qids"]
        else:
            src["test_frac"] = generated_test_frac
        sources.append(src)
        available.append(name)

    if not sources:
        raise RuntimeError("No legs have usable execution data -- nothing to load.")

    try:
        bundle = load_multi_source_qpp_data(
            sources=sources,
            schema=SCHEMA_NAME, instance=LAKEHOUSE_INSTANCE_NAME,
            metric=METRIC, xcol=XCOL, ycol=YCOL,
            parsed_results_root=PARSED_RESULTS_ROOT,
            seed=seed, use_scalar_runtime=True, test_frac=generated_test_frac,
        )
    except Exception as e:
        raise RuntimeError(
            f"load_multi_source_qpp_data failed for available legs {available}: "
            f"{type(e).__name__}: {e}"
        ) from e

    return bundle, available, skipped


def leg_train_qids(bundle: QPPDataBundle, leg_name: str) -> List[str]:
    """All of `leg_name`'s query ids that ended up in `bundle.train_qids`."""
    prefix = f"{leg_name}::"
    return [q for q in bundle.train_qids if q.startswith(prefix)]


def leg_test_qids(bundle: QPPDataBundle, leg_name: str) -> List[str]:
    """All of `leg_name`'s query ids that ended up in the shared T_eval."""
    prefix = f"{leg_name}::"
    return [q for q in bundle.test_qids if q.startswith(prefix)]


def t_eval_qids(bundle: QPPDataBundle) -> List[str]:
    """Every test qid in the universe bundle -- spans every available leg's
    held-out slice: REAL_LEG's fixed structural holdout plus
    `generated_test_frac` of every generated leg."""
    return list(bundle.test_qids)


def leg_of_qid(qid: str) -> str:
    return qid.split("::", 1)[0]
