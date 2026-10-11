import http.client
import urllib.parse

from concurrent.futures import ThreadPoolExecutor
from lakehouse.kubernetes_helpers import get_trino_pods

from typing import List, Optional
from dataclasses import dataclass


@dataclass
class NodeProfiler:
    namespace: str
    selector: str
    when: set[str] | list[str] | None = None,

    def _trigger_profile_for_pod(
        self,
        pod: dict,
        phase: str,
        query_id: str,
        out_dir: Optional[str] = None,
    ) -> dict:
        conn = None
        try:
            params = {
                "phase": phase,
                "query_id": query_id,
            }
            if out_dir:
                params["out_dir"] = out_dir

            path = "/profile?" + urllib.parse.urlencode(params)

            conn = http.client.HTTPConnection(pod["pod_ip"], 8123, timeout=300)
            conn.request("POST", path)
            resp = conn.getresponse()
            body = resp.read().decode("utf-8", errors="replace")

            return {
                "pod_name": pod["name"],
                "pod_ip": pod["pod_ip"],
                "type": pod["type"],
                "status": resp.status,
                "body": body,
                "ok": 200 <= resp.status < 300,
                "out_dir": out_dir,
            }

        except Exception as e:
            return {
                "pod_name": pod.get("name"),
                "pod_ip": pod.get("pod_ip"),
                "type": pod.get("type"),
                "ok": False,
                "error": str(e),
                "out_dir": out_dir,
            }

        finally:
            if conn is not None:
                try:
                    conn.close()
                except Exception:
                    pass

    def trigger_profile(
        self,
        phase: str,
        query_id: str,
        out_dir: Optional[str] = None,
    ) -> List[dict]:

        if phase not in self.when:
            return []
        
        pods = get_trino_pods(self.namespace, self.selector)

        if not pods:
            return []

        with ThreadPoolExecutor(max_workers=len(pods)) as executor:
            results = list(
                executor.map(
                    lambda pod: self._trigger_profile_for_pod(pod, phase, query_id, out_dir),
                    pods,
                )
            )

        return results