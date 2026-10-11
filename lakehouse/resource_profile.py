import math
import time
import http.client
from dataclasses import dataclass
from concurrent.futures import ThreadPoolExecutor
from typing import Any, Dict, Iterable, Optional, List

import pandas as pd

from lakehouse.kubernetes_helpers import get_trino_pods

# Reuse your metric/port declarations from scrape.py
from lakehouse.scrape import (
    PROCESS_CPU,
    NODE_CPU,
    TRINO_MEM,
    TRINO_READ,
    HTTP_SENT,
    HTTP_RECV,
)


def _nan() -> float:
    return float("nan")


def _safe_float(value: str | bytes | None) -> float:
    if value is None:
        return _nan()

    if isinstance(value, bytes):
        value = value.decode("ascii", errors="ignore")

    try:
        return float(str(value).strip())
    except Exception:
        return _nan()


def _value_token_b(line: bytes) -> bytes | None:
    """
    Extract the Prometheus sample value from a metric line.

    Supports:
        metric_name 123
        metric_name{label="x"} 123
    """
    if not line or line.startswith(b"#"):
        return None

    # Ignore optional Prometheus timestamp; keep first value token after labels/name.
    parts = line.strip().split()
    if len(parts) < 2:
        return None

    return parts[1]


def _is_metric_line_b(line: bytes, metric_name: str) -> bool:
    name_b = metric_name.encode("ascii", errors="ignore")
    return line.startswith(name_b + b"{") or line.startswith(name_b + b" ")


def parse_single_metric(body: bytes, metric_name: str) -> float:
    """
    Return the first sample value for a metric.
    """
    for line in body.split(b"\n"):
        if _is_metric_line_b(line, metric_name):
            return _safe_float(_value_token_b(line))
    return _nan()


def parse_node_idle_sum(body: bytes, metric_name: str) -> float:
    """
    Sum node_cpu_seconds_total{mode="idle"} across all CPUs.
    """
    prefix = (metric_name + "{").encode("ascii", errors="ignore")
    needle = b'mode="idle"'

    total = 0.0
    found = False

    for line in body.split(b"\n"):
        if not line or line.startswith(b"#"):
            continue
        if not line.startswith(prefix):
            continue
        if needle not in line:
            continue

        value = _safe_float(_value_token_b(line))
        if not math.isnan(value):
            total += value
            found = True

    return total if found else _nan()


def parse_node_cpu_count(body: bytes, metric_name: str) -> float:
    """
    Count logical CPUs from node_cpu_seconds_total{cpu="...", mode="..."}.
    """
    prefix = (metric_name + "{").encode("ascii", errors="ignore")
    cpus = set()

    for line in body.split(b"\n"):
        if not line or line.startswith(b"#"):
            continue
        if not line.startswith(prefix):
            continue

        # Fast-enough label extraction for cpu="..."
        marker = b'cpu="'
        i = line.find(marker)
        if i == -1:
            continue

        j = i + len(marker)
        k = line.find(b'"', j)
        if k == -1:
            continue

        cpus.add(line[j:k].decode("ascii", errors="ignore"))

    return float(len(cpus)) if cpus else _nan()


def parse_node_memory(body: bytes) -> dict[str, float]:
    return {
        "node_mem_available_bytes": parse_single_metric(body, "node_memory_MemAvailable_bytes"),
        "node_mem_total_bytes": parse_single_metric(body, "node_memory_MemTotal_bytes"),
    }


def http_get_metrics(
    host: str,
    port: int,
    *,
    path: str = "/metrics",
    timeout_s: float = 2.0,
) -> bytes | None:
    """
    Pull one Prometheus text endpoint.
    """
    conn = None
    try:
        conn = http.client.HTTPConnection(host, port, timeout=timeout_s)
        conn.request(
            "GET",
            path,
            headers={
                "Host": f"{host}:{port}",
                "Accept": "text/plain",
                "Connection": "close",
            },
        )
        resp = conn.getresponse()
        raw = resp.read()

        if resp.status != 200:
            return None

        return raw

    except Exception:
        return None

    finally:
        if conn is not None:
            try:
                conn.close()
            except Exception:
                pass


@dataclass
class ResourceSnapshot:
    pod_name: str
    pod_ip: str
    pod_type: str | None
    node: str | None
    epoch_ms: int

    ok_fast: bool
    ok_mem: bool
    ok_node: bool
    error: str | None = None

    process_cpu_s: float = math.nan
    node_cpu_idle_s: float = math.nan
    node_cpu_count: float = math.nan
    trino_mem_bytes: float = math.nan
    trino_read_bytes: float = math.nan
    http_sent_bytes: float = math.nan
    http_recv_bytes: float = math.nan
    node_mem_available_bytes: float = math.nan
    node_mem_total_bytes: float = math.nan

    def as_row(self) -> dict[str, Any]:
        row = self.__dict__.copy()

        if (
            not math.isnan(row["node_mem_available_bytes"])
            and not math.isnan(row["node_mem_total_bytes"])
            and row["node_mem_total_bytes"] > 0
        ):
            row["node_mem_used_pct"] = 100.0 * (
                1.0 - row["node_mem_available_bytes"] / row["node_mem_total_bytes"]
            )
        else:
            row["node_mem_used_pct"] = math.nan

        return row


@dataclass
class LakehouseResourceProfiler:
    namespace: str
    selector: str
    timeout_s: float = 2.0
    max_workers: Optional[int] = None

    def profile_resources(self, *, as_dataframe: bool = True) -> pd.DataFrame | list[dict[str, Any]]:
        """
        Return one row per running Trino pod.

        Rows contain raw cumulative counters/gauges. For rates, call
        profile_resource_rates(...), which samples twice and computes deltas.
        """
        pods = get_trino_pods(self.namespace, self.selector)

        if not pods:
            return pd.DataFrame() if as_dataframe else []

        workers = self.max_workers or len(pods)

        with ThreadPoolExecutor(max_workers=workers) as executor:
            rows = list(executor.map(self._profile_one_pod, pods))

        out = [r.as_row() for r in rows]
        return pd.DataFrame(out) if as_dataframe else out

    def profile_resource_rates(
        self,
        *,
        interval_s: float = 1.0,
        as_dataframe: bool = True,
    ) -> pd.DataFrame | list[dict[str, Any]]:
        """
        Sample twice and compute short-interval rates.

        This gives:
            trino_process_cpu_cores
            node_cpu_util_pct
            trino_read_Bps
            http_sent_Bps
            http_recv_Bps
        """
        before = self.profile_resources(as_dataframe=True)
        time.sleep(interval_s)
        after = self.profile_resources(as_dataframe=True)

        rates = compute_resource_rates(before, after)
        return rates if as_dataframe else rates.to_dict("records")

    def _profile_one_pod(self, pod: dict) -> ResourceSnapshot:
        pod_name = pod.get("name")
        pod_ip = pod.get("pod_ip")
        pod_type = pod.get("type")
        node = pod.get("node")

        snap = ResourceSnapshot(
            pod_name=pod_name,
            pod_ip=pod_ip,
            pod_type=pod_type,
            node=node,
            epoch_ms=time.time_ns() // 1_000_000,
            ok_fast=False,
            ok_mem=False,
            ok_node=False,
        )

        if not pod_ip:
            snap.error = "missing pod_ip"
            return snap

        # 7071: Trino/JMX/process metrics
        process_metric, fast_port = PROCESS_CPU
        trino_read_metric, _ = TRINO_READ
        http_sent_metric, _ = HTTP_SENT
        http_recv_metric, _ = HTTP_RECV

        fast_body = http_get_metrics(pod_ip, fast_port, timeout_s=self.timeout_s)
        if fast_body is not None:
            snap.ok_fast = True
            snap.process_cpu_s = parse_single_metric(fast_body, process_metric)
            snap.trino_read_bytes = parse_single_metric(fast_body, trino_read_metric)
            snap.http_sent_bytes = parse_single_metric(fast_body, http_sent_metric)
            snap.http_recv_bytes = parse_single_metric(fast_body, http_recv_metric)

        # 9102: Trino memory
        trino_mem_metric, mem_port = TRINO_MEM
        mem_body = http_get_metrics(pod_ip, mem_port, timeout_s=self.timeout_s)
        if mem_body is not None:
            snap.ok_mem = True
            snap.trino_mem_bytes = parse_single_metric(mem_body, trino_mem_metric)

        # 9100: node-exporter metrics
        node_cpu_metric, node_port = NODE_CPU
        node_body = http_get_metrics(pod_ip, node_port, timeout_s=self.timeout_s)
        if node_body is not None:
            snap.ok_node = True
            snap.node_cpu_idle_s = parse_node_idle_sum(node_body, node_cpu_metric)
            snap.node_cpu_count = parse_node_cpu_count(node_body, node_cpu_metric)

            mem = parse_node_memory(node_body)
            snap.node_mem_available_bytes = mem["node_mem_available_bytes"]
            snap.node_mem_total_bytes = mem["node_mem_total_bytes"]

        return snap


def compute_resource_rates(before: pd.DataFrame, after: pd.DataFrame) -> pd.DataFrame:
    """
    Convert two raw snapshots into a row-per-pod rate dataframe.
    """
    if before.empty or after.empty:
        return pd.DataFrame()

    merged = after.merge(
        before,
        on="pod_name",
        suffixes=("", "_prev"),
        how="left",
    )

    dt_s = (merged["epoch_ms"] - merged["epoch_ms_prev"]) / 1000.0
    dt_s = dt_s.replace(0, float("nan"))

    out = merged[
        [
            "epoch_ms",
            "pod_name",
            "pod_ip",
            "pod_type",
            "node",
            "ok_fast",
            "ok_mem",
            "ok_node",
            "trino_mem_bytes",
            "node_mem_available_bytes",
            "node_mem_total_bytes",
            "node_mem_used_pct",
            "node_cpu_count",
        ]
    ].copy()

    def rate(col: str) -> pd.Series:
        return (merged[col] - merged[f"{col}_prev"]) / dt_s

    out["trino_process_cpu_cores"] = rate("process_cpu_s")
    out["trino_read_Bps"] = rate("trino_read_bytes")
    out["http_sent_Bps"] = rate("http_sent_bytes")
    out["http_recv_Bps"] = rate("http_recv_bytes")
    out["node_cpu_idle_cores"] = rate("node_cpu_idle_s")

    out["node_cpu_util_pct"] = 100.0 * (
        1.0 - (out["node_cpu_idle_cores"] / out["node_cpu_count"])
    )

    # Avoid negative/invalid results caused by missing data or restarts.
    for col in [
        "trino_process_cpu_cores",
        "trino_read_Bps",
        "http_sent_Bps",
        "http_recv_Bps",
        "node_cpu_idle_cores",
        "node_cpu_util_pct",
    ]:
        out.loc[~pd.to_numeric(out[col], errors="coerce").notna(), col] = math.nan

    return out