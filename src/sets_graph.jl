"""
    HamiltonianCycleWeightedType

Whether a Hamiltonian cycle has a weight:

* either the constraint also includes a variable for the total weight:
  `FIXED_WEIGHT_HAMILTONIAN_CYCLE`
* or the constraint also includes a variable for the total weight and one 
  variable giving the weight of each vertex: 
  `VARIABLE_WEIGHT_HAMILTONIAN_CYCLE`
* or it only includes the next vertices: `UNWEIGHTED_HAMILTONIAN_CYCLE`
"""
@enum HamiltonianCycleWeightedType begin
    FIXED_WEIGHT_HAMILTONIAN_CYCLE
    VARIABLE_WEIGHT_HAMILTONIAN_CYCLE
    UNWEIGHTED_HAMILTONIAN_CYCLE
end

"""
    HamiltonianCycle{HWCT, T}(n_nodes::Int)

A Hamiltonian cycle (i.e. a cycle in a graph that visits each vertex once).
If the vector `x` is constrained within a `Circuit(n)`, each `x[i]` denotes
the next vertex in the graph, for `i ∈ [1, n]`. 

The considered graph is an undirected complete graph with `n` vertices.
To model a Hamiltonian circuit in a noncomplete graph, you can add constraints
on the variables: if the vertex `i` only has edges towards `j` and `k`, then
`x[i]` should only have the possible values `j` and `k`.

Also called `cycle` or `atour`.

GCC: https://sofdem.github.io/gccat/gccat/Ccircuit.html

## Unweighted cycle

`HamiltonianCycle{UNWEIGHTED_HAMILTONIAN_CYCLE}` considers an unweighted
Hamiltonian cycle.

`x`-in-`HamiltonianCycle{UNWEIGHTED_HAMILTONIAN_CYCLE}(n)`:
a Hamiltonian cycle in the complete graph of `n` vertices.
`x[i]` is the index of the next vertex in the cycle.

## Fixed-weight cycle

`HamiltonianCycle{FIXED_WEIGHT_HAMILTONIAN_CYCLE}` considers an Hamiltonian
cycle whose weights are fixed. Having an edge in the cycle increases the
total weight.

`[x, tw]`-in-`HamiltonianCycle{FIXED_WEIGHT_HAMILTONIAN_CYCLE}(n, weights)`:
`x` is a Hamiltonian cycle in the complete graph of `n` vertices.
`x[i]` is the index of the next vertex in the cycle. 
`tw` is the total weight of the cycle, with `weights` being indexed by the 
vertices: 

``\\mathtt{tw} = \\sum_{i=1}^{n} \\mathtt{weights[i, x[i]]}``

## Variable-weight cycle

`HamiltonianCycle{VARIABLE_WEIGHT_HAMILTONIAN_CYCLE}` considers an Hamiltonian
cycle whose weights are variable. Having an edge in the cycle increases the
total weight.

`[x, w, tw]`-in-`HamiltonianCycle{VARIABLE_WEIGHT_HAMILTONIAN_CYCLE}(n)`:
`x` is a Hamiltonian cycle in the complete graph of `n` vertices.
`x[i]` is the index of the next vertex in the cycle. 
`tw` is the total weight of the cycle, with `w` being indexed by the vertices:

``\\mathtt{tw} = \\sum_{i=1}^{n} \\mathtt{w[i, x[i]]}``
"""
struct HamiltonianCycle{HCWT, T <: Real} <: MOI.AbstractVectorSet
    n_nodes::Int
    weights::AbstractMatrix{T}
end

MOI.dimension(set::HamiltonianCycle{FIXED_WEIGHT_HAMILTONIAN_CYCLE, T}) where {T <: Real} = set.n_nodes + 1
MOI.dimension(set::HamiltonianCycle{VARIABLE_WEIGHT_HAMILTONIAN_CYCLE, T}) where {T <: Real} = 2 * set.n_nodes + 1
MOI.dimension(set::HamiltonianCycle{UNWEIGHTED_HAMILTONIAN_CYCLE, T}) where {T <: Real} = set.n_nodes

"""
    HamiltonianPathWeightedType

Whether a Hamiltonian path has a weight:

* either the constraint also includes a variable for the total weight:
  `WEIGHTED_HAMILTONIAN_PATH`
* or it only includes the next vertices: `UNWEIGHTED_HAMILTONIAN_PATH`
"""
@enum HamiltonianPathWeightedType begin
    WEIGHTED_HAMILTONIAN_PATH
    UNWEIGHTED_HAMILTONIAN_PATH
end

"""
    HamiltonianPath(n_nodes::Int)

A Hamiltonian path. 


If the vectors `x` and `y` are constrained within a 
`CircuitPath(n)`, each `x[i]` denotes the next node in the graph, for 
`i ∈ [1, n]`. The last `n` variables denote the order in which the nodes are
visited, i.e. `y[1]` is the first visited node (1 by convention), `y[2]` is 
the next node in the path, etc.

The considered graph is an undirected complete graph with `n` nodes.
"""
struct HamiltonianPath <: MOI.AbstractVectorSet
    n_nodes::Int
end

MOI.dimension(set::HamiltonianPath) = set.n_nodes

"""
    WeightedCircuit{T <: Real}(n_nodes::Int, cost_matrix::AbstractMatrix{T})

A Hamiltonian circuit. If the vector `x` and the scalar `c` are constrained
within a `WeightedCircuit(n, cost_matrix)`, each `x[i]` denotes the next node 
in the graph, for `i ∈ [1, n]`. `c` is the total cost of the circuit, defined as: 

``c = \\sum_{i=1}^n \\mathtt{cost\\_matrix}_{i, x[i]}``

The considered graph is an undirected complete graph with `n` nodes.
"""
struct WeightedCircuit{T <: Real} <: MOI.AbstractVectorSet
    n_nodes::Int
    cost_matrix::AbstractMatrix{T}
end

MOI.dimension(set::WeightedCircuit{T}) where {T} = set.n_nodes + 1
function copy(set::WeightedCircuit{T}) where {T}
    return WeightedCircuit(set.n_nodes, copy(set.cost_matrix))
end
function Base.:(==)(x::WeightedCircuit{T}, y::WeightedCircuit{T}) where {T}
    return x.n_nodes == y.n_nodes && x.cost_matrix == y.cost_matrix
end

"""
    WeightedCircuitPath(n_nodes::Int, cost_matrix::AbstractMatrix{T})

A Hamiltonian circuit. If the vectors `x` and `y` and the scalar `c` are 
constrained within a `CircuitPath(n)`, each `x[i]` denotes the next node in the graph, for 
`i ∈ [1, n]`. The next `n` variables denote the order in which the nodes are
visited, i.e. `y[1]` is the first visited node (1 by convention), `y[2]` is 
the next node in the path, etc. `c` is the total cost of the circuit, defined as: 

``c = \\sum_{i=1}^n \\mathtt{cost\\_matrix}_{i, x[i]}``

The considered graph is an undirected complete graph with `n` nodes.
"""
struct WeightedCircuitPath{T <: Real} <: MOI.AbstractVectorSet
    n_nodes::Int
    cost_matrix::AbstractMatrix{T}
end

MOI.dimension(set::WeightedCircuitPath{T}) where {T} = 2 * set.n_nodes + 1
function copy(set::WeightedCircuitPath{T}) where {T}
    return WeightedCircuitPath(set.n_nodes, copy(set.cost_matrix))
end
function Base.:(==)(
    x::WeightedCircuitPath{T},
    y::WeightedCircuitPath{T},
) where {T}
    return x.n_nodes == y.n_nodes && x.cost_matrix == y.cost_matrix
end

# isbits types, nothing to copy
function copy(set::Union{Circuit, CircuitPath})
    return set
end
