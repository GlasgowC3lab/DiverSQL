
import os, time, json, threading, re
from openai import (OpenAI, InternalServerError, APIConnectionError, RateLimitError, APITimeoutError)
from .config import (MODEL_NAME, BASE_MODEL_URL, API_KEY_ENV,
                     USE_RESPONSES_STREAMING, RETRY_VERBOSE)
from .prompt import PROMPT_TEMPLATE, INSTRUCTIONS_TEMPLATE

def make_openai_client(
    *,
    base_url: str = BASE_MODEL_URL,
    api_key_env: str = API_KEY_ENV,
    timeout_s: float = 600.0,
) -> OpenAI:
    return OpenAI(
        base_url=base_url,
        api_key=os.environ[api_key_env],
        timeout=timeout_s,
        max_retries=0,
    )

_RETRY_TLS = threading.local()

# --- LLM token accounting ---------------------------------------------------
# Module-level accumulator (mirrors report._RUN_STATS): generate_sql records
# usage from every completion; report.py drains it once per run. Warm-up is
# excluded -- it does not call generate_sql.
_TOKEN_LOCK = threading.Lock()

def _fresh_token_usage() -> dict:
    return dict(input_tokens=0, output_tokens=0, reasoning_tokens=0,
                total_tokens=0, calls=0, calls_without_usage=0)

_TOKEN_USAGE: dict = _fresh_token_usage()

def _usage_get(u, *names):
    """Read a field from an OpenAI usage object OR a plain dict."""
    for n in names:
        v = u.get(n) if isinstance(u, dict) else getattr(u, n, None)
        if v is not None:
            return v
    return None

def _record_token_usage(result) -> None:
    """Accumulate token usage from one completion. Robust to providers that omit
    usage (tallied under ``calls_without_usage``) and to Responses (input/output)
    vs Chat (prompt/completion) field names."""
    u = getattr(result, "usage", None)
    if u is None and isinstance(result, dict):
        u = result.get("usage")
    inp = _usage_get(u, "input_tokens", "prompt_tokens") if u is not None else None
    out = _usage_get(u, "output_tokens", "completion_tokens") if u is not None else None
    tot = _usage_get(u, "total_tokens") if u is not None else None
    details = _usage_get(u, "output_tokens_details", "completion_tokens_details") if u is not None else None
    reasoning = _usage_get(details, "reasoning_tokens") if details is not None else None

    with _TOKEN_LOCK:
        tu = _TOKEN_USAGE
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

def drain_token_usage() -> dict:
    """Return accumulated token usage and reset, so the next run starts fresh."""
    with _TOKEN_LOCK:
        s = dict(_TOKEN_USAGE)
        _TOKEN_USAGE.clear()
        _TOKEN_USAGE.update(_fresh_token_usage())
    return s

_RETRY_OBSERVERS: list = []

_RETRY_OBSERVERS_LOCK = threading.Lock()

_RETRY_MAX_DEFAULT = 2000

def set_retry_max_default(n: int) -> int:
    """Set the default retry budget; returns the previous value (for restore)."""
    global _RETRY_MAX_DEFAULT
    prev = _RETRY_MAX_DEFAULT
    _RETRY_MAX_DEFAULT = int(n)
    return prev

def get_retry_max_default() -> int:
    return _RETRY_MAX_DEFAULT

def register_retry_observer(cb) -> None:
    """Register ``cb(exc)`` to be called once per transient-error retry."""
    with _RETRY_OBSERVERS_LOCK:
        _RETRY_OBSERVERS.append(cb)

def unregister_retry_observer(cb) -> None:
    with _RETRY_OBSERVERS_LOCK:
        try:
            _RETRY_OBSERVERS.remove(cb)
        except ValueError:
            pass

def last_retry_count() -> int:
    """Retries incurred by the most recent ``call_with_retry`` on THIS thread."""
    return int(getattr(_RETRY_TLS, "count", 0))

def _notify_retry(exc) -> None:
    with _RETRY_OBSERVERS_LOCK:
        observers = list(_RETRY_OBSERVERS)
    for cb in observers:
        try:
            cb(exc)
        except Exception:
            pass

def call_with_retry(
    fn,
    *,
    max_retries: int | None = None,
    sleep_s: float = 2.5,
):
    if max_retries is None:
        max_retries = _RETRY_MAX_DEFAULT

    last_error = None
    _RETRY_TLS.count = 0

    for attempt in range(max_retries):
        try:
            return fn()
        except (
            InternalServerError,
            APIConnectionError,
            RateLimitError,
            APITimeoutError,
        ) as e:
            last_error = e
            _RETRY_TLS.count = attempt + 1
            _notify_retry(e)

            if RETRY_VERBOSE or not _RETRY_OBSERVERS:
                print(f"[API retry {attempt + 1}/{max_retries}] {type(e).__name__}: {e}")
                if attempt < max_retries - 1:
                    print(f"Sleeping {sleep_s:.1f}s before retry...")

            if attempt < max_retries - 1:
                time.sleep(sleep_s)

    raise RuntimeError(f"API call failed after {max_retries} retries") from last_error

def call_with_retry_start_up(
    fn,
    *,
    max_retries: int = 16,
    base_sleep_s: float = 10.0,
    max_sleep_s: float = 240.0,
):
    last_error = None

    for attempt in range(max_retries):
        try:
            return fn()
        except (
            InternalServerError,
            APIConnectionError,
            RateLimitError,
            APITimeoutError,
        ) as e:
            last_error = e
            sleep_s = min(base_sleep_s * (2 ** attempt), max_sleep_s)
            print(f"[API retry {attempt + 1}/{max_retries}] {type(e).__name__}: {e}")
            print(f"Sleeping {sleep_s:.1f}s before retry...")
            time.sleep(sleep_s)

    raise RuntimeError(f"API call failed after {max_retries} retries") from last_error

def warm_up_model(
    client: OpenAI,
    *,
    model_name: str = MODEL_NAME,
) -> None:
    def _call():
        return client.responses.create(
            model=model_name,
            input="Return only the word ready.",
            temperature=0,
            store=False,
        )

    result = call_with_retry_start_up(_call)
    print(f"Model warm-up response: {result.output_text.strip()}")

def sanitize_sql(query: str) -> str:
    if not query:
        return query

    query = query.strip()
    query = re.sub(r"^```[a-zA-Z]*\n?", "", query)
    query = re.sub(r"\n?```$", "", query)
    query = re.sub(r";+\s*$", "", query)

    return query.strip()

def normalise_sql_result(data: dict) -> dict:
    return {
        "sql": sanitize_sql(data.get("sql", "")),
        "goal": data.get("goal", ""),
        "tables_used": data.get("tables_used", []),
        "columns_used": data.get("columns_used", []),
        "assumptions": data.get("assumptions", []),
    }

_OUTPUT_SCHEMA = {
    "type": "json_schema",
    "name": "sql_generation_result",
    "strict": True,
    "schema": {
        "type": "object",
        "properties": {
            "sql": {
                "type": "string",
                "description": "The generated Trino SQL query.",
            },
            "goal": {
                "type": "string",
                "description": "A short description of the analytical goal of the query.",
            },
            "tables_used": {"type": "array", "items": {"type": "string"}},
            "columns_used": {"type": "array", "items": {"type": "string"}},
        },
        "required": ["sql", "goal", "tables_used", "columns_used"],
        "additionalProperties": False,
    },
}

def generate_sql(
    client: OpenAI,
    schema_context: str,
    *,
    task: str,
    reasoning: str = "medium",
    model_name: str = MODEL_NAME,
    temperature: float = 0.6,
) -> dict:
    def _call():
        kwargs = dict(
            model=model_name,
            instructions=INSTRUCTIONS_TEMPLATE,
            input=PROMPT_TEMPLATE.format(schema_context=schema_context, task=task),
            text={"format": _OUTPUT_SCHEMA},
            temperature=temperature,
            store=False,
        )
        if USE_RESPONSES_STREAMING:
            with client.responses.stream(**kwargs) as stream:
                return stream.get_final_response()
        return client.responses.create(**kwargs)

    result = call_with_retry(_call)
    _record_token_usage(result)
    data = json.loads(result.output_text)
    return normalise_sql_result(data)
