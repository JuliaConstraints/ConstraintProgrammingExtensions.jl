"""
    VertexWeightedType

Whether a cycle/path constraint has a weight for vertices:

* the constraint has a fixed weight for each vertex: `FIXED_WEIGHT_VERTEX`
* the constraint has a variable weight for each vertex: 
  `VARIABLE_WEIGHT_VERTEX` (typically, such a constraint has a dimension for
  each vertex to give its weight)
* the constraint does not have a notion of per-vertex weight: 
  `UNWEIGHTED_VERTEX`

Typically, constraints with a type other than `UNWEIGHTED_VERTEX` have a
dimension for the total weight due to vertices.
"""
@enum VertexWeightedType begin
    FIXED_WEIGHT_VERTEX
    VARIABLE_WEIGHT_VERTEX
    UNWEIGHTED_VERTEX
end

"""
    EdgeWeightedType

Whether a cycle/path constraint has a weight for edges:

* the constraint has a fixed weight for each edge: `FIXED_WEIGHT_EDGE`
* the constraint has a variable weight for each edge: 
  `VARIABLE_WEIGHT_EDGE` (typically, such a constraint has a dimension for
  each edge to give its weight)
* the constraint does not have a notion of per-edge weight: 
  `UNWEIGHTED_EDGE`

Typically, constraints with a type other than `UNWEIGHTED_EDGE` have a
dimension for the total weight due to edges.
"""
@enum EdgeWeightedType begin
    FIXED_WEIGHT_EDGE
    VARIABLE_WEIGHT_EDGE
    UNWEIGHTED_EDGE
end

"""
    WalkType

The type of walk implemented by the constraint. In graph theory, a walk is a
sequence of edges that join vertices (also called nodes): a walk starts at some
vertex, then uses an edge to get to a second vertex, etc.

The possible values are:

* a trail (walk whose edges are distinct, but not necessarily the vertices):
  `TRAIL_WALK`
* a cycle (walk whose edges are distinct, starting and ending at the same
  vertex): `CYCLE_WALK`
* a path (walk whose edges and vertices are distinct; sometimes called a 
  "simple path"): `PATH_WALK`

Although each walk is supposed to have a first vertex `s` (often called the
source vertex) and a last vertex `t` (often called the destination vertex),
this distinction does not make sense for cycles.
"""
@enum WalkType begin
    TRAIL_WALK
    CYCLE_WALK
    PATH_WALK
end

"""
    WalkSubType

The specific type of walk (e.g., a path or a cycle) implemented by the
constraint:

* a simple walk: `NO_SPECIFIC_WALK`
* a Eulerian walk (every edge is visited exactly once): `EULERIAN_WALK`
* a Hamiltonian walk (every vertex is visited exactly once): `HAMILTONIAN_WALK`

Subtypes can be thought of as adjectives for the walk types of `WalkType`.
"""
@enum WalkSubType begin
    EULERIAN_WALK
    HAMILTONIAN_WALK
    NO_SPECIFIC_WALK
end

"""
    WalkSourceType

The way the source vertex is given:

* no source node (typically, only for cycles): `NO_SOURCE_VERTEX`
* a fixed source vertex: `FIXED_SOURCE_VERTEX`
* a variable source vertex: `VARIABLE_SOURCE_VERTEX`
"""
@enum WalkSourceType begin
    NO_SOURCE_VERTEX
    FIXED_SOURCE_VERTEX
    VARIABLE_SOURCE_VERTEX
end

"""
    WalkDestinationType

The way the destination vertex is given:

* no destination node (typically, only for cycles): `NO_DESTINATION_VERTEX`
* a fixed destination vertex: `FIXED_DESTINATION_VERTEX`
* a variable destination vertex: `VARIABLE_DESTINATION_VERTEX`
"""
@enum WalkDestinationType begin
    NO_DESTINATION_VERTEX
    FIXED_DESTINATION_VERTEX
    VARIABLE_DESTINATION_VERTEX
end

"""
    Walk{VWT, EWT, WT, WST, WsT, WtT, T}(n_nodes::Int)

A walk in an undirected graph.

If the vector `x` describes the walk within a `Walk` constraint, each `x[i]`
denotes the next vertex in the `n`-vertex graph, for `i ∈ [1, n]`.

The considered graph is an undirected complete graph with `n` vertices.
To model a walk in a noncomplete graph, you can add constraints on the
variables: if the vertex `i` only has edges towards `j` and `k`, then `x[i]`
should only have the possible values `j` and `k`.

The dimensions of this set are as follows:

* first, the description of the walk, typically denoted by `x`
* second, the source vertex, depending on `WsT`
* third, the destination vertex, depending on `WtT`
* fourth, the individual weights, depending on `VWT` and `EWT` -- vertices
  (`VWT`) come before edges (`EWT`)
* fifth, the total weights, depending on `VWT` and `EWT` -- vertices (`VWT`)
  come before edges (`EWT`)
* sixth, the total weight, depending on `VWT` and `EWT` (sum of the weight over
  the vertices [`VWT`] and the edges [`EWT`])

For cycles, all the variables describing the cycle are implied to have an
integer value between `1` and `n`. For other walks, the walk-description
variables

Some variants are called `circuit` or `atour`.

GCC: https://sofdem.github.io/gccat/gccat/Ccircuit.html

## Unweighted walk

`Walk{UNWEIGHTED_VERTEX, UNWEIGHTED_EDGE, WalkType, WalkSubType,
WalkSourceType, WalkDestinationType, T}` considers an unweighted walk, for all
`WalkType`, `WalkSubType`, `WalkSourceType`, `WalkDestinationType`, and
`T <: Real`.

`x`-in-`Walk{UNWEIGHTED_VERTEX, UNWEIGHTED_EDGE, WT, WST, WsT, WtT, T}(n)`:
a walk in the complete graph of `n` vertices. `x[i]` is the index of the next
vertex after `i` in the walk.

## Fixed-edge-weight cycle

`Walk{UNWEIGHTED_VERTEX, FIXED_WEIGHT_EDGE, CYCLE_WALK, NO_SPECIFIC_WALK,
NO_SOURCE_VERTEX, NO_DESTINATION_VERTEX, T}` considers a cycle whose edge
weights are fixed: having an edge in the cycle increases the total weight.
Vertices are unweighted, because all of them must be included in a cycle.

`[x, tw]`-in-`Walk{UNWEIGHTED_VERTEX, FIXED_WEIGHT_EDGE, CYCLE_WALK, 
NO_SPECIFIC_WALK, NO_SOURCE_VERTEX, NO_DESTINATION_VERTEX, T}(n, 
edge_weights)` where the elements of `edge_weights` have type `T`:

* `x` is a cycle in the complete graph of `n` vertices, 
  `x[i]` is the index of the next vertex in the cycle
* `tw` is the total weight of the cycle, with `edge_weights` being indexed by
  the vertices: 

  ``\\mathtt{tw} = \\sum_{i=1}^{n} \\mathtt{edge_weights[i, x[i]]}``

## Variable-vertex-weight path

`Walk{VARIABLE_WEIGHT_VERTEX, UNWEIGHTED_EDGE, PATH_WALK, NO_SPECIFIC_WALK,
FIXED_SOURCE_VERTEX, FIXED_DESTINATION_VERTEX, T}` considers a path whose
vertex weights are variable. Having a vertex in the cycle increases the total
weight, but edges do not contribute in this case (although there is no reason
why they could not).

`[x, w, tw]`-in-`Walk{VARIABLE_WEIGHT_VERTEX, UNWEIGHTED_EDGE, PATH_WALK, 
NO_SPECIFIC_WALK, FIXED_SOURCE_VERTEX, FIXED_DESTINATION_VERTEX, T}(n)`:

* `x` is a path in the complete graph of `n` vertices, 
  `x[i]` is the index of the next vertex in the path
* `w` is the weight of each vertex (a vector indexed by the vertex indices)
* `tw` is the total vertex weight of the path:

  ``\\mathtt{tw} = \\sum_{i=1}^{n} \\mathtt{w[x[i]]}``
"""
struct Walk{VWT, EWT, WT, WST, WsT, WtT, T <: Real} <: MOI.AbstractVectorSet
    n_nodes::Int
    s::Int
    t::Int
    vertex_weights::AbstractVector{T}
    edge_weights::AbstractMatrix{T}

    # TODO: add a constructor to check if the parameters make sense.
    # - VARIABLE_WEIGHT_* or UNWEIGHTED_*: no vertex_weights, edge_weights
    # - cycle: no s or t
    # - VARIABLE_*_VERTEX: no s or t
end

Walk{VWT, EWT, WT, WST, WsT, WtT, T}(n_nodes::Int) where {VWT, EWT, WT, WST, WsT, WtT, T} = Walk{VWT, EWT, WT, WST, WsT, WtT, T}(n_nodes, 0, 0, zeros(T, 0), zeros(T, 0, 0))
Walk{VWT, EWT, WT, WST, WsT, WtT, T}(n_nodes::Int, s::Int, t::Int) where {VWT, EWT, WT, WST, WsT, WtT, T} = Walk{VWT, EWT, WT, WST, WsT, WtT, T}(n_nodes, s, t, zeros(T, 0), zeros(T, 0, 0))

function MOI.dimension(set::Walk{VWT, EWT, WT, WST, WsT, WtT, T}) where {VWT, EWT, WT, WST, WsT, WtT, T}
    dim = set.n_nodes

    if VWT == FIXED_WEIGHT_VERTEX
        dim += 1
    elseif VWT == VARIABLE_WEIGHT_VERTEX
        dim += set.n_nodes
    end

    if EWT == FIXED_WEIGHT_EDGE
        dim += 1
    elseif EWT == VARIABLE_WEIGHT_EDGE
        dim += set.n_nodes ^ 2
    end

    if WsT == VARIABLE_SOURCE_VERTEX
        dim += 1
    end
    if WsT == VARIABLE_DESTINATION_VERTEX
        dim += 1
    end

    return dim
end

function copy(set::Walk{VWT, EWT, WT, WST, WsT, WtT, T}) where {VWT, EWT, WT, WST, WsT, WtT, T}
    return Walk{VWT, EWT, WT, WST, WsT, WtT, T}(set.n_nodes, set.s, set.t, copy(set.vertex_weights), copy(set.edge_weights))
end

function Base.:(==)(x::Walk{VWT, EWT, WT, WST, WsT, WtT, T}, y::Walk{VWT, EWT, WT, WST, WsT, WtT, T}) where {VWT, EWT, WT, WST, WsT, WtT, T}
    return x.n_nodes == y.n_nodes && x.s == y.s && x.t == y.t && x.vertex_weights == y.vertex_weights && x.edge_weights == y.edge_weights
end

# Some shortcuts.
const HamiltonianCycle{T} = Walk{UNWEIGHTED_VERTEX, UNWEIGHTED_EDGE, CYCLE_WALK, HAMILTONIAN_WALK, NO_SOURCE_VERTEX, NO_DESTINATION_VERTEX, T}
const HamiltonianPath{T} = Walk{UNWEIGHTED_VERTEX, UNWEIGHTED_EDGE, PATH_WALK, HAMILTONIAN_WALK, FIXED_SOURCE_VERTEX, FIXED_DESTINATION_VERTEX, T}

const FixedWeightHamiltonianCycle{T} = Walk{UNWEIGHTED_VERTEX, FIXED_WEIGHT_EDGE, CYCLE_WALK, HAMILTONIAN_WALK, NO_SOURCE_VERTEX, NO_DESTINATION_VERTEX, T}
const FixedWeightHamiltonianPath{T} = Walk{UNWEIGHTED_VERTEX, FIXED_WEIGHT_EDGE, PATH_WALK, HAMILTONIAN_WALK, FIXED_SOURCE_VERTEX, FIXED_DESTINATION_VERTEX, T}

const VariableWeightHamiltonianCycle{T} = Walk{UNWEIGHTED_VERTEX, VARIABLE_WEIGHT_EDGE, CYCLE_WALK, HAMILTONIAN_WALK, NO_SOURCE_VERTEX, NO_DESTINATION_VERTEX, T}
const VariableWeightHamiltonianPath{T} = Walk{UNWEIGHTED_VERTEX, VARIABLE_WEIGHT_EDGE, PATH_WALK, HAMILTONIAN_WALK, FIXED_SOURCE_VERTEX, FIXED_DESTINATION_VERTEX, T}

const EulerianCycle{T} = Walk{UNWEIGHTED_VERTEX, UNWEIGHTED_EDGE, CYCLE_WALK, EULERIAN_WALK, NO_SOURCE_VERTEX, NO_DESTINATION_VERTEX, T}
const EulerianPath{T} = Walk{UNWEIGHTED_VERTEX, UNWEIGHTED_EDGE, PATH_WALK, EULERIAN_WALK, FIXED_SOURCE_VERTEX, FIXED_DESTINATION_VERTEX, T}

const FixedWeightEulerianCycle{T} = Walk{FIXED_WEIGHT_VERTEX, UNWEIGHTED_EDGE, CYCLE_WALK, EULERIAN_WALK, NO_SOURCE_VERTEX, NO_DESTINATION_VERTEX, T}
const FixedWeightEulerianPath{T} = Walk{FIXED_WEIGHT_VERTEX, UNWEIGHTED_EDGE, PATH_WALK, EULERIAN_WALK, FIXED_SOURCE_VERTEX, FIXED_DESTINATION_VERTEX, T}

const VariableWeightEulerianCycle{T} = Walk{VARIABLE_WEIGHT_VERTEX, UNWEIGHTED_EDGE, CYCLE_WALK, EULERIAN_WALK, NO_SOURCE_VERTEX, NO_DESTINATION_VERTEX, T}
const VariableWeightEulerianPath{T} = Walk{VARIABLE_WEIGHT_VERTEX, UNWEIGHTED_EDGE, PATH_WALK, EULERIAN_WALK, FIXED_SOURCE_VERTEX, FIXED_DESTINATION_VERTEX, T}
