"""Parse Trino EXPLAIN (FORMAT JSON) plans into operator DAGs."""
import re
import matplotlib.pyplot as plt
import networkx as nx

from networkx.drawing.nx_pydot import to_pydot
from typing import Dict, Any, Iterable, Tuple


Edge = Tuple[str, str, str]  # (src_id, dst_id, etype)

def iter_edges(dag: Dict[str, Any]) -> Iterable[Edge]:
    """Yield (src, dst, etype) edges from a DAG dict."""
    for e in dag.get("edges", []):
        if not isinstance(e, (list, tuple)) or len(e) != 3:
            continue
        src, dst, etype = e
        yield str(src), str(dst), str(etype)


def build_trino_dag(plan_json):
    nodes = {}
    edges = []

    fragment_roots = {}   # fragment_id -> root_node_id
    remote_links = []     # (remote_node_id, fragment_id)

    REMOTE_CONSUMERS = {"RemoteSource", "RemoteMerge"}  # <- key fix

    def visit(op, fragment_id, parent_id=None):
        node_id = op["id"]

        nodes[node_id] = {
            "name": op["name"],
            "fragment": fragment_id,
            "descriptor": op.get("descriptor", {}),
            "outputs": op.get("outputs", []),
            "estimates": op.get("estimates", []),
        }

        if parent_id is not None:
            edges.append((parent_id, node_id, "child"))

        # Cross-fragment consumers (RemoteSource, RemoteMerge, ...)
        if op["name"] in REMOTE_CONSUMERS:
            src = op.get("descriptor", {}).get("sourceFragmentIds")
            if src:
                for frag_id in re.findall(r"\d+", str(src)):
                    remote_links.append((node_id, frag_id))

        for child in op.get("children", []):
            visit(child, fragment_id, node_id)

    # First pass: traverse trees
    for fragment_id, root in plan_json.items():
        fragment_roots[fragment_id] = root["id"]
        visit(root, fragment_id)

    # Second pass: add cross-fragment edges
    for remote_node_id, target_fragment in remote_links:
        if target_fragment in fragment_roots:
            target_root = fragment_roots[target_fragment]
            edges.append((remote_node_id, target_root, "remote"))

    return {"nodes": nodes, "edges": edges, "fragment_roots": fragment_roots}



def plot_trino_dag_graphviz_spaced(
    dag,
    out_path=None,
    figsize=(28, 12),
    rankdir="LR",     # "LR" or "TB"
    ranksep=1.2,      # vertical spacing between ranks (increase)
    nodesep=0.6,      # horizontal spacing between nodes (increase)
    splines="spline", # nicer edges: "spline" or "ortho" or "line"
    
):
    G = nx.DiGraph()
    edge_types = {}

    for node_id, attrs in dag["nodes"].items():
        G.add_node(node_id, label=f'{attrs["name"]}\n{node_id}')

    for src, dst, etype in dag["edges"]:
        G.add_edge(src, dst)
        edge_types[(src, dst)] = etype

    # Build a pydot graph so we can set DOT attributes
    P = to_pydot(G)
    P.set_rankdir(rankdir)
    P.set_ranksep(str(ranksep))
    P.set_nodesep(str(nodesep))
    P.set_splines(splines)

    # optional: smaller labels reduce perceived squash
    P.set_node_defaults(fontsize="10")
    P.set_edge_defaults(arrowsize="0.7")

    # layout with dot
    P.set_prog("dot")
    dot = P.create_dot().decode("utf-8")

    # Convert back to positions via graphviz_layout using the DOT string
    # (networkx graphviz_layout doesn't accept attrs reliably across versions)
    import pydot
    (pg,) = pydot.graph_from_dot_data(dot)
    pos = {}
    for n in pg.get_nodes():
        name = n.get_name().strip('"')
        if name in G.nodes and n.get_pos():
            x, y = n.get_pos().strip('"').split(',')
            pos[name] = (float(x), float(y))

    # Draw
    labels = nx.get_node_attributes(G, "label")
    child_edges = []
    remote_edges = []
    for u, v in G.edges():
        if edge_types.get((u, v), "child") == "remote":
            remote_edges.append((u, v))
        else:
            child_edges.append((u, v))

    plt.figure(figsize=figsize)
    nx.draw_networkx_nodes(G, pos, node_size=900)
    nx.draw_networkx_labels(G, pos, labels=labels, font_size=8)
    nx.draw_networkx_edges(G, pos, edgelist=child_edges, arrows=True, width=1.0)
    nx.draw_networkx_edges(G, pos, edgelist=remote_edges, arrows=True, width=1.2, edge_color="red")
    plt.axis("off")
    plt.tight_layout()
    if out_path:
        plt.savefig(out_path, dpi=300, bbox_inches="tight")
    plt.show()
