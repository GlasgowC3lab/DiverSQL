import os
import time
import re
from typing import List, Optional, Iterable, Dict, Tuple

from trino.exceptions import TrinoQueryError, TrinoConnectionError
from trino.dbapi import connect

from lakehouse import config as cfg


def ident(name: str) -> str:
    # Quote identifiers for Trino (handles hyphens, case, etc.)
    return '"' + str(name).replace('"', '""') + '"'


class IcebergTable:
    def __init__(self, schema: str, name: str, location: str, metadata_file: str = "v1.metadata.json"):
        self.schema = schema
        self.name = name
        self.location = location
        self.metadata_file = metadata_file

    def __repr__(self) -> str:
        return f"IcebergTable(schema={self.schema!r}, name={self.name!r}, location={self.location!r})"


class LakehouseSchema:
    def __init__(
        self,
        name: str,
        warehouse_path: str,
        use_dot_db: bool = False,
        trino_warehouse_path: str | None = None,
    ):
        self.name = name
        self.warehouse_path = warehouse_path              # local path
        self.trino_warehouse_path = trino_warehouse_path or warehouse_path # what the lakehouse sees as the warehouse
        self.use_dot_db = use_dot_db
        self.tables: List[IcebergTable] = []

    @property
    def schema_dirname(self) -> str:
        return f"{self.name}.db" if self.use_dot_db else self.name

    @property
    def schema_path(self) -> str:
        return os.path.join(self.warehouse_path, self.schema_dirname)

    def discover(self, metadata_file: str = "auto") -> List[IcebergTable]:
        path = self.schema_path
        if not os.path.isdir(path):
            raise FileNotFoundError(f"Schema path not found or not a directory: {path}")
    
        tables: List[IcebergTable] = []
    
        for name in sorted(os.listdir(path)):
            tpath = os.path.join(path, name)
            if not os.path.isdir(tpath):
                continue
    
            table_metadata_file = metadata_file
    
            if metadata_file == "auto":
                metadata_dir = os.path.join(tpath, "metadata")
                if not os.path.isdir(metadata_dir):
                    raise FileNotFoundError(f"Metadata directory not found for table {name}: {metadata_dir}")
    
                candidates = [
                    f for f in os.listdir(metadata_dir)
                    if f.endswith(".metadata.json")
                ]
    
                if not candidates:
                    raise FileNotFoundError(f"No Iceberg metadata JSON files found for table {name}: {metadata_dir}")
    
                candidates = sorted(
                    candidates,
                    key=lambda f: os.path.getmtime(os.path.join(metadata_dir, f)),
                )
    
                table_metadata_file = candidates[-1]
    
            local_schema_path = self.schema_path
            trino_schema_path = os.path.join(
                self.trino_warehouse_path,
                self.schema_dirname,
            )
            
            tables.append(
                IcebergTable(
                    schema=self.name,
                    name=name,
                    location=os.path.join(trino_schema_path, name),
                    metadata_file=table_metadata_file,
                )
            )
    
        self.tables = tables
        return tables

    def __repr__(self) -> str:
        return f"LakehouseSchema(name={self.name!r}, warehouse_path={self.warehouse_path!r}, tables={len(self.tables)})"


def connect_trino(host: str, schema: str):
    return connect(
        host=host,
        port=cfg.TRINO_PORT,
        user=cfg.TRINO_USER,
        catalog=cfg.TRINO_CATALOG,
        schema=schema,
        http_scheme=cfg.TRINO_HTTP_SCHEME,
        session_properties={"query_max_run_time": cfg.TRINO_TIMEOUT},
    )


def create_schema_if_missing(cursor, schema: str) -> None:
    cursor.execute(f"CREATE SCHEMA IF NOT EXISTS {cfg.TRINO_CATALOG}.{ident(schema)}")


def register_table(cursor, table: IcebergTable) -> None:
    q = f"""
    CALL {cfg.TRINO_CATALOG}.system.register_table(
        schema_name => '{table.schema}',
        table_name => '{table.name}',
        table_location => '{table.location}',
        metadata_file_name => '{table.metadata_file}'
    )
    """
    cursor.execute(q)


def register_schema(
    host: str,
    schema: LakehouseSchema,
    verbose: bool = True,
    only_tables: Optional[Iterable[str]] = None,
) -> int:
    if not schema.tables:
        schema.discover()

    allowed = None if only_tables is None else set(only_tables)

    conn = connect_trino(host, schema=schema.name)
    cur = conn.cursor()
    ok = 0

    try:
        create_schema_if_missing(cur, schema.name)

        if verbose:
            print(f"Trino host: {host}")
            print(f"Schema:     {schema.name}")
            print(f"Warehouse:  {schema.warehouse_path}")
            print(f"Tables:     {len(schema.tables)}")

        for t in schema.tables:
            if allowed is not None and t.name not in allowed:
                continue
            try:
                register_table(cur, t)
                ok += 1
            except Exception as e:
                if verbose:
                    print(f"  FAILED {t.name}: {e}")
        if ok == len(schema.tables):
            print(f"Registered all tables")
        return ok
    finally:
        try:
            cur.close()
        finally:
            conn.close()

def list_schemas(host: str, catalog: str) -> List[str]:
    conn = connect_trino(host, schema="information_schema")
    cur = conn.cursor()
    try:
        cur.execute(f"SHOW SCHEMAS FROM {catalog}")
        return [r[0] for r in cur.fetchall()]
    finally:
        try: cur.close()
        finally: conn.close()

def list_tables(host: str, catalog: str, schema: str) -> List[str]:
    conn = connect_trino(host, schema=schema)
    cur = conn.cursor()
    try:
        cur.execute(f"SHOW TABLES FROM {catalog}.{schema}")
        return [r[0] for r in cur.fetchall()]
    finally:
        try: cur.close()
        finally: conn.close()

_LOCATION_RE = re.compile(
    r"(?is)\bWITH\s*\(\s*.*?\blocation\s*=\s*'([^']+)'\s*.*?\)"
)

def get_table_location(
    host: str,
    *,
    catalog: str,
    schema: str,
    table: str,
) -> Optional[str]:
    """
    Best-effort: parse location from SHOW CREATE TABLE.
    Returns location string if found, else None.
    """
    conn = connect_trino(host, schema=schema)
    cur = conn.cursor()
    try:
        # SHOW CREATE TABLE returns rows; join to a single DDL string
        cur.execute(f"SHOW CREATE TABLE {catalog}.{ident(schema)}.{ident(table)}")
        rows = cur.fetchall()

        ddl = "\n".join(r[0] for r in rows if r and isinstance(r[0], str))
        m = _LOCATION_RE.search(ddl)
        if not m:
            return None
        return m.group(1).strip()
    finally:
        try:
            cur.close()
        finally:
            conn.close()


def infer_schema_and_warehouse_from_any_table(
    host: str,
    *,
    catalog: str,
    schema: str,
    verbose: bool = False,
) -> Tuple[Optional[str], Optional[str], Optional[bool]]:
    """
    Returns (schema_path, warehouse_path, use_dot_db).
    """
    tables = list_tables(host, catalog=catalog, schema=schema)
    if not tables:
        return None, None, None

    # Pick first table and fetch its location once
    first = tables[0]
    loc = get_table_location(host, catalog=catalog, schema=schema, table=first)  # your existing function
    if not loc:
        if verbose:
            print(f"WARN: cannot infer schema/warehouse for {schema}; no location for {first}")
        return None, None, None

    schema_path = os.path.dirname(loc.rstrip("/"))
    warehouse_path = os.path.dirname(schema_path.rstrip("/"))
    use_dot_db = schema_path.rstrip("/").endswith(f"{schema}.db")

    return schema_path, warehouse_path, use_dot_db


def build_table_locations_from_schema_path(
    schema: str,
    tables: List[str],
    schema_path: str,
) -> List[IcebergTable]:
    """
    Construct IcebergTable objects with location = <schema_path>/<table>.
    """
    schema_path = schema_path.rstrip("/")
    return [
        IcebergTable(schema=schema, name=t, location=f"{schema_path}/{t}", metadata_file="")
        for t in tables
    ]


def discover_registered_schemas(
    host: str,
    *,
    catalog: str,
    include_schemas: Optional[List[str]] = None,
    exclude_schemas: Optional[List[str]] = None,
    verbose: bool = False,
    infer_paths: bool = True,
) -> Dict[str, LakehouseSchema]:

    schemas = list_schemas(host, catalog=catalog)

    if include_schemas:
        allow = set(include_schemas)
        schemas = [s for s in schemas if s in allow]
    if exclude_schemas:
        deny = set(exclude_schemas)
        schemas = [s for s in schemas if s not in deny]

    out: Dict[str, LakehouseSchema] = {}

    for s in schemas:
        table_names = list_tables(host, catalog=catalog, schema=s)

        schema_path = None
        warehouse_path = ""
        use_dot_db = False

        if infer_paths and table_names:
            schema_path, warehouse_path_inferred, use_dot_db_inferred = infer_schema_and_warehouse_from_any_table(
                host, catalog=catalog, schema=s, verbose=verbose
            )
            if warehouse_path_inferred:
                warehouse_path = warehouse_path_inferred
            if use_dot_db_inferred is not None:
                use_dot_db = bool(use_dot_db_inferred)

        sch = LakehouseSchema(name=s, warehouse_path=warehouse_path, use_dot_db=use_dot_db)

        if schema_path:
            sch.tables = build_table_locations_from_schema_path(s, table_names, schema_path)
        else:
            # fallback: we at least know registered table names
            sch.tables = [IcebergTable(schema=s, name=t, location="", metadata_file="") for t in table_names]

        out[s] = sch

        if verbose:
            wp = sch.warehouse_path or "<unknown>"
            print(f"{s}: {len(sch.tables)} tables, warehouse={wp}")

    return out


def wait_for_trino(
    host: str,
    *,
    schema: str = "information_schema",
    timeout_s: int = 300,
    poll_s: float = 2.0,
    verbose: bool = False,
) -> bool:
    """
    Block until Trino is query-ready (not just the pod being Ready).

    Returns True if ready, raises TimeoutError otherwise.
    """
    deadline = time.time() + timeout_s
    last_err: Optional[Exception] = None

    if verbose:
        print(f"Waiting for Trino engine to ready.")

    while time.time() < deadline:
        try:
            conn = connect_trino(host, schema=schema)
            cur = conn.cursor()
            try:
                # cheapest possible query
                cur.execute("SELECT 1")
                _ = cur.fetchall()
                if verbose:
                    print("Trino is ready.")
                return True
            finally:
                try:
                    cur.close()
                finally:
                    conn.close()

        except TrinoQueryError as e:
            # This is your exact case
            last_err = e
            msg = str(e)
            if "SERVER_STARTING_UP" in msg or "still initializing" in msg:
                if verbose:
                    print("  Trino still initializing ...")
                time.sleep(poll_s)
                continue

            # other query errors should not be blindly retried
            raise

        except TrinoConnectionError as e:
            # Connection refused / not listening yet
            last_err = e
            if verbose:
                print("  Trino not reachable yet ...")
            time.sleep(poll_s)
            continue

        except Exception as e:
            # transient network / misc
            last_err = e
            if verbose:
                print(f"  Trino not ready ({type(e).__name__}) ...")
            time.sleep(poll_s)
            continue

    raise TimeoutError(f"Timed out waiting for Trino readiness after {timeout_s}s. Last error: {last_err}")

