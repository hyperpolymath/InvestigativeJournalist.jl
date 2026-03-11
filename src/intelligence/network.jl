# SPDX-License-Identifier: PMPL-1.0-or-later
module NetworkIntelligence

using Graphs
using MetaGraphsNext
using ..Types

export InvestigativeGraph, add_connection!, find_shortest_path

"""
    InvestigativeGraph
A specialized graph for tracking connections between people, companies, and assets.
"""
function InvestigativeGraph()
    # Define the graph with Symbol metadata for nodes and Dict for edges
    return MetaGraph(
        SimpleGraph(),
        label_type=Symbol,
        vertex_data_type=Entity,
        edge_data_type=Dict{Symbol, Any},
        graph_data="Investigative Network"
    )
end

"""
    add_connection!(graph, entity1, entity2, relationship)
Links two entities with a specific relationship (e.g. :director_of, :shareholder_in).
"""
function add_connection!(g, e1::Entity, e2::Entity, rel::Symbol)
    # Ensure entities are in the graph
    g[e1.id] = e1
    g[e2.id] = e2
    
    # Add edge with relationship metadata
    g[e1.id, e2.id] = Dict(:relationship => rel)
    return "Connected $(e1.canonical_name) to $(e2.canonical_name) via $rel"
end

"""
    find_shortest_path(graph, start_id, end_id)
Finds the investigative path between two entities (e.g. 'Person A' -> 'Company B' -> 'Oligarch C').
"""
function find_shortest_path(g, start_id::Symbol, end_id::Symbol)
    p = enumerate_paths(dijkstra_shortest_paths(g.graph, code_for(g, start_id)), code_for(g, end_id))
    return [label_for(g, node) for node in p]
end

end # module
