import http.client
import json
from concurrent.futures import ThreadPoolExecutor
from dataclasses import dataclass
from typing import List

from lakehouse.kubernetes_helpers import get_trino_pods
from lakehouse.config import LOGGING_PORT


@dataclass
class NodeLogger:
    namespace: str
    selector: str
    timeout_s: int = 2

    def _post_json(self, pod: dict, path: str, payload: dict) -> dict:
        conn = None
        try:
            conn = http.client.HTTPConnection(pod["pod_ip"], LOGGING_PORT, self.timeout_s)
            body = json.dumps(payload)
            headers = {"Content-Type": "application/json"}
            conn.request("POST", path, body=body, headers=headers)
            resp = conn.getresponse()
            raw = resp.read().decode("utf-8", errors="replace")

            try:
                data = json.loads(raw)
            except Exception:
                data = {"ok": False, "raw": raw}

            return {
                "pod_name": pod.get("name"),
                "pod_ip": pod.get("pod_ip"),
                "type": pod.get("type"),
                "http_status": resp.status,
                "ok": bool(data.get("ok", False)),
                "data": data,
            }

        except Exception as e:
            return {
                "pod_name": pod.get("name"),
                "pod_ip": pod.get("pod_ip"),
                "type": pod.get("type"),
                "ok": False,
                "error": str(e),
                "data": None,
            }

        finally:
            if conn is not None:
                try:
                    conn.close()
                except Exception:
                    pass

    def _for_all_pods(self, fn) -> List[dict]:
        pods = get_trino_pods(self.namespace, self.selector)
        if not pods:
            return []

        with ThreadPoolExecutor(max_workers=len(pods)) as executor:
            return list(executor.map(fn, pods))

    def _get_json(self, pod: dict, path: str) -> dict:
        conn = None
        try:
            conn = http.client.HTTPConnection(pod["pod_ip"], LOGGING_PORT, self.timeout_s)
            conn.request("GET", path)
            resp = conn.getresponse()
            raw = resp.read().decode("utf-8", errors="replace")
    
            try:
                data = json.loads(raw)
            except Exception:
                data = {"ok": False, "raw": raw}
    
            return {
                "pod_name": pod.get("name"),
                "pod_ip": pod.get("pod_ip"),
                "type": pod.get("type"),
                "http_status": resp.status,
                "ok": bool(data.get("ok", False)),
                "data": data,
            }
    
        except Exception as e:
            return {
                "pod_name": pod.get("name"),
                "pod_ip": pod.get("pod_ip"),
                "type": pod.get("type"),
                "ok": False,
                "error": str(e),
                "data": None,
            }
    
        finally:
            if conn is not None:
                try:
                    conn.close()
                except Exception:
                    pass

    def start_logging(self, out_dir: str) -> List[dict]:
        def _start_for_pod(pod: dict) -> dict:
            out_path = f"{out_dir}/{pod['name']}_metrics.csv"
            return self._post_json(pod, "/start", {"out_path": out_path})

        return self._for_all_pods(_start_for_pod)

    def stop_logging(self) -> List[dict]:
        return self._for_all_pods(lambda pod: self._post_json(pod, "/stop", {}))

    def get_status(self) -> List[dict]:
        status = self._for_all_pods(lambda pod: self._get_json(pod, "/status"))
        return status

    def reset_logging(self, out_dir: str) -> dict:
        stop_results = self.stop_logging()
        start_results = self.start_logging(out_dir)
        return {
            "stop_results": stop_results,
            "start_results": start_results,
        }

    def get_logging_state(self) -> List[dict]:
        results = self.get_status()
    
        normalized = []
        for r in results:
            data = r.get("data") or {}
            status = data.get("status") or {}
            normalized.append({
                "pod_name": r.get("pod_name"),
                "pod_ip": r.get("pod_ip"),
                "type": r.get("type"),
                "ok": r.get("ok", False),
                "running": bool(status.get("running", False)),
                "out_path": status.get("out_path"),
                "last_epoch_ms": status.get("last_epoch_ms"),
                "raw": data,
            })
        return normalized

    def is_logging(self) -> bool:
        states = self.get_logging_state()
        return any(s.get("running", False) for s in states)

    def prepare_run(self, out_dir: str, verbose: bool = False) -> None:
        states = self.get_logging_state()
        if any(s.get("running", False) for s in states):
            if verbose:
                print("Detected existing resource logging session; stopping it first.")
            stop_results = self.stop_logging()
            stop_failures = self.any_failures(stop_results)
            if stop_failures:
                raise RuntimeError(f"Failed to stop existing resource logging session: {stop_failures}")

        start_results = self.start_logging(out_dir)
        start_failures = self.any_failures(start_results)
        if start_failures:
            raise RuntimeError(f"Failed to start resource logging: {start_failures}")

        if verbose:
            print("Started resource logging.")

    def cleanup_run(self, verbose: bool = False) -> None:
        states = self.get_logging_state()
        if not any(s.get("running", False) for s in states):
            return

        stop_results = self.stop_logging()
        stop_failures = self.any_failures(stop_results)
        if stop_failures:
            print(f"Warning: failed to stop resource logging cleanly: {stop_failures}")
        elif verbose:
            print("Stopped resource logging.")

    @staticmethod
    def any_failures(results: List[dict]) -> List[dict]:
        return [r for r in results if not r.get("ok", False)]

    @staticmethod
    def all_ok(results: List[dict]) -> bool:
        return all(r.get("ok", False) for r in results)