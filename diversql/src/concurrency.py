import threading
import time

from . import config


class ConcurrencyController:
    """AIMD in-flight target: +1 every probe_interval_s when healthy; beta on a
    contention signal, then frozen for cooldown_s so a burst = one cut. The
    caller's worker count is the CEILING (c_max), not a fixed level.

    Thread-safe: on_contention is called from worker threads (retry observer);
    limit()/snapshot() from the scheduler thread.
    """

    def __init__(self, *, c_min, c_max, start,
                 beta=config.CONC_BETA,
                 probe_interval_s=config.CONC_PROBE_INTERVAL_S,
                 cooldown_s=config.CONC_COOLDOWN_S):
        self.c_min = max(1, int(c_min))
        self.c_max = max(self.c_min, int(c_max))
        self.beta = beta
        self.probe_interval_s = probe_interval_s
        self.cooldown_s = cooldown_s
        self._limit = float(min(max(int(start), self.c_min), self.c_max))
        self._lock = threading.Lock()
        now = time.monotonic()
        self._last_change = now
        self._frozen_until = 0.0
        self.increases = self.decreases = self.contention_events = 0
        self.min_seen = self.max_seen = self._limit

    def _maybe_increase_locked(self):
        now = time.monotonic()
        if now < self._frozen_until or self._limit >= self.c_max:
            return
        if now - self._last_change >= self.probe_interval_s:
            self._limit = min(self.c_max, self._limit + 1.0)
            self.increases += 1
            self._last_change = now
            self.max_seen = max(self.max_seen, self._limit)

    def limit(self) -> int:
        with self._lock:
            self._maybe_increase_locked()
            return max(self.c_min, int(round(self._limit)))

    def on_contention(self, exc=None):
        with self._lock:
            self.contention_events += 1
            now = time.monotonic()
            if now < self._frozen_until:
                return
            new = max(self.c_min, self._limit * self.beta)
            if new < self._limit:
                self._limit = new
                self.decreases += 1
                self.min_seen = min(self.min_seen, self._limit)
            self._frozen_until = now + self.cooldown_s
            self._last_change = now

    def snapshot(self) -> dict:
        with self._lock:
            return {
                "final_limit": max(self.c_min, int(round(self._limit))),
                "ceiling": self.c_max, "floor": self.c_min,
                "min_limit_seen": max(self.c_min, int(round(self.min_seen))),
                "max_limit_seen": int(round(self.max_seen)),
                "increases": self.increases, "decreases": self.decreases,
                "contention_events": self.contention_events,
            }


def run_pool(*, worker, on_complete, is_done, ceiling, max_attempts, rng,
             progress_cb=None, progress_snapshot=None):
    """Saturating pool driven by ConcurrencyController + the llm retry observer.

    * ``worker(seed) -> result`` runs on a pool thread (one generation).
    * ``on_complete(result)`` runs on the scheduler thread (accept/reject).
    * ``is_done() -> bool`` stop condition (e.g. enough accepted).
    * ``progress_snapshot() -> dict`` optional extra fields merged into progress.
    """
    from concurrent.futures import ThreadPoolExecutor, wait, FIRST_COMPLETED
    from .llm import register_retry_observer, unregister_retry_observer

    ceiling = max(1, int(ceiling))
    controller = ConcurrencyController(
        c_min=config.CONC_MIN, c_max=ceiling,
        start=min(ceiling, config.CONC_START),
    )
    register_retry_observer(controller.on_contention)

    executor = ThreadPoolExecutor(max_workers=ceiling)
    inflight: set = set()
    attempts = 0

    def _submit():
        nonlocal attempts
        if attempts >= max_attempts:
            return False
        inflight.add(executor.submit(worker, rng.randint(0, 10 ** 9)))
        attempts += 1
        return True

    def _refill():
        while len(inflight) < controller.limit() and not is_done() and attempts < max_attempts:
            if not _submit():
                break

    def _emit(event):
        if progress_cb is None:
            return
        st = {
            "event": event, "attempts": attempts, "max_attempts": max_attempts,
            "inflight": len(inflight), "concurrency_limit": controller.limit(),
            "contention_events": controller.contention_events,
        }
        if progress_snapshot is not None:
            try:
                st.update(progress_snapshot())
            except Exception:
                pass
        try:
            progress_cb(st)
        except Exception:
            pass

    try:
        _refill()
        _emit("start")
        while inflight and not is_done():
            done, _pending = wait(inflight, timeout=2.0, return_when=FIRST_COMPLETED)
            for fut in done:
                inflight.discard(fut)
                try:
                    on_complete(fut.result())
                except Exception as e:
                    controller.on_contention()
                    print(f"[generation failed] {type(e).__name__}: {e}")
            _refill()
            _emit("progress" if done else "tick")
    finally:
        unregister_retry_observer(controller.on_contention)
        try:
            executor.shutdown(wait=False, cancel_futures=True)
        except TypeError:
            executor.shutdown(wait=False)

    _emit("done")
    return attempts, controller.snapshot()
