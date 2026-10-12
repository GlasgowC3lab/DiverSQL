import random
import sys
from pathlib import Path
from typing import Dict, Iterable, List

ROOT = Path(__file__).resolve().parents[2]  # repo root
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from qpp.qpp_harness import nested_query_subsamples  # noqa: E402


def observed_train_subsamples(
    train_qids: Iterable[str], checkpoints: Iterable[int], *, reveal_seed: int,
) -> Dict[int, List[str]]:
    return nested_query_subsamples(list(train_qids), list(checkpoints), seed=reveal_seed)


def hybrid_pool(observed_n: List[str], generated_leg_qids: List[str]) -> List[str]:
    """D1/D2..D6/D7: observed_n + the WHOLE generated leg, unmodified. A set
    union, nothing else -- no selection, no weighting."""
    return sorted(set(observed_n) | set(generated_leg_qids))


def size_matched_pool(observed_n: List[str], generated_leg_qids: List[str], *, seed: int) -> List[str]:
    rng = random.Random(seed)
    full = hybrid_pool(observed_n, generated_leg_qids)
    target_size = len(observed_n)
    if len(full) <= target_size:
        return full
    return sorted(rng.sample(full, target_size))


def cold_start_pool(generated_leg_qids: List[str]) -> List[str]:
    """D8: the generated leg alone, N=0 real."""
    return sorted(set(generated_leg_qids))
