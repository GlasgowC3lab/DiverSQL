"""Related-work SQL workload generators, adapted to the Trino/Iceberg lakehouse; see README.md."""

from diversql.baselines import (
    sqlstorm,
    sqlbarber,
    e2etune,
    bootstrapping_lcm,
    sql_factory,
)

BASELINES = {
    "sqlstorm": sqlstorm.generate_workload,
    "sqlbarber": sqlbarber.generate_workload,
    "e2etune": e2etune.generate_workload,
    "bootstrapping_lcm": bootstrapping_lcm.generate_workload,
    "sql_factory": sql_factory.generate_workload,
}

__all__ = [
    "BASELINES",
    "sqlstorm",
    "sqlbarber",
    "e2etune",
    "bootstrapping_lcm",
    "sql_factory",
]
