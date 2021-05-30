"""
    Circuit(n_nodes::Int)

A Hamiltonian circuit. If the vector `x` is constrained within a `Circuit(n)`,
each `x[i]` denotes the next node in the graph, for `i ∈ [1, n]`. 

The considered graph is an undirected complete graph with `n` nodes.

Also called `cycle` or `atour`.
"""
struct Circuit <: MOI.AbstractVectorSet
    n_nodes::Int
end

MOI.dimension(set::Circuit) = set.n_nodes

"""
    CircuitPath(n_nodes::Int)

A Hamiltonian circuit. If the vectors `x` and `y` are constrained within a 
`CircuitPath(n)`, each `x[i]` denotes the next node in the graph, for 
`i ∈ [1, n]`. The last `n` variables denote the order in which the nodes are
visited, i.e. `y[1]` is the first visited node (1 by convention), `y[2]` is 
the next node in the path, etc.

The considered graph is an undirected complete graph with `n` nodes.
"""
struct CircuitPath <: MOI.AbstractVectorSet
    n_nodes::Int
end

MOI.dimension(set::CircuitPath) = 2 * set.n_nodes

"""
    WeightedCircuit{T <: Real}(n_nodes::Int, cost_matrix::AbstractMatrix{T})

A Hamiltonian circuit. If the vector `x` and the scalar `c` are constrained
within a `WeightedCircuit(n, cost_matrix)`, each `x[i]` denotes the next node 
in the graph, for `i ∈ [1, n]`. `c` is the total cost of the circuit, defined as: 

``c = \\sum_{i=1}^n \\mathtt{cost_matrix}_{i, x[i]}``

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

``c = \\sum_{i=1}^n \\mathtt{cost_matrix}_{i, x[i]}``

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
