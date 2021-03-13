"""
    Circuit(n_nodes::Int)

A Hamiltonian circuit. If the vector `x` is constrained within a `Circuit(n)`,
each `x[i]` denotes the next node in the graph, for `i ∈ [1, n]`. The 
considered graph is an undirected complete graph with `n` nodes.

Also called `cycle` or `atour`.
"""
struct Circuit <: MOI.AbstractVectorSet
    n_nodes::Int
end

MOI.dimension(set::Circuit) = set.n_nodes

"""
    WeightedCircuit{T <: Real}(Circuit::Int)

A Hamiltonian circuit. If the vector `x` and the scalar `c` are constrained
within a `WeightedCircuit(n, cost_matrix)`, each `x[i]` denotes the next node 
in the graph, for `i ∈ [1, n]`. The considered graph is an undirected complete 
graph with `n` nodes. `c` is the total cost of the circuit, defined as: 

``c = \\sum_{i=1}^n \\mathtt{cost_matrix}_{i, x[i]}``
"""
struct WeightedCircuit{T <: Real} <: MOI.AbstractVectorSet
    n_nodes::Int
    cost_matrix::AbstractMatrix{T}
end

MOI.dimension(set::WeightedCircuit{T}) where {T} = set.n_nodes + 1