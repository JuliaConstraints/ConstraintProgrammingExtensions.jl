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
If the vector `x` is constrained within a `HamiltonianCycle`, each `x[i]` denotes
the next vertex in the graph, for `i ∈ [1, n]`. 

The considered graph is an undirected complete graph with `n` vertices.
To model a Hamiltonian cycle in a noncomplete graph, you can add constraints
on the variables: if the vertex `i` only has edges towards `j` and `k`, then
`x[i]` should only have the possible values `j` and `k`.

Also called `circuit` or `atour`.

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

HamiltonianCycle(n_nodes::Int, weights::AbstractMatrix{T}) where {T} = HamiltonianCycle{FIXED_WEIGHT_HAMILTONIAN_CYCLE, T}(n_nodes, weights)

MOI.dimension(set::HamiltonianCycle{FIXED_WEIGHT_HAMILTONIAN_CYCLE, T}) where {T <: Real} = set.n_nodes + 1
MOI.dimension(set::HamiltonianCycle{VARIABLE_WEIGHT_HAMILTONIAN_CYCLE, T}) where {T <: Real} = 2 * set.n_nodes + 1
MOI.dimension(set::HamiltonianCycle{UNWEIGHTED_HAMILTONIAN_CYCLE, T}) where {T <: Real} = set.n_nodes

"""
    HamiltonianPathWeightedType

Whether a Hamiltonian path has a weight:

* either the constraint also includes a variable for the total weight:
  `FIXED_WEIGHT_HAMILTONIAN_PATH`
* or the constraint also includes a variable for the total weight and one
  variable giving the weight of each vertex: 
  `VARIABLE_WEIGHT_HAMILTONIAN_PATH`
* or it only includes the next vertices: `UNWEIGHTED_HAMILTONIAN_PATH`
"""
@enum HamiltonianPathWeightedType begin
    FIXED_WEIGHT_HAMILTONIAN_PATH
    VARIABLE_WEIGHT_HAMILTONIAN_PATH
    UNWEIGHTED_HAMILTONIAN_PATH
end

"""
    HamiltonianPath{HPWT, T}(n_nodes::Int, s::Int, t::Int)

A Hamiltonian path (i.e. a path in a graph that visits each vertex once) from
`s` to `t`. If the vector `x` is constrained within a `HamiltonianPath`, each
`x[i]` denotes the next vertex in the graph, for `i ∈ [1, n]`. The successor
of `t`, i.e. the value of `x[t]`, is undefined and might be different from
solver to solver.

The considered graph is an undirected complete graph with `n` vertices.
To model a Hamiltonian path in a noncomplete graph, you can add constraints
on the variables: if the vertex `i` only has edges towards `j` and `k`, then
`x[i]` should only have the possible values `j` and `k`.

No GCC link?

## Unweighted path

`HamiltonianPath{UNWEIGHTED_HAMILTONIAN_PATH}` considers an unweighted
Hamiltonian path.

`x`-in-`HamiltonianPath{UNWEIGHTED_HAMILTONIAN_PATH}(n)`:
a Hamiltonian path in the complete graph of `n` vertices.
`x[i]` is the index of the next vertex in the path.

## Fixed-weight path

`HamiltonianPath{FIXED_WEIGHT_HAMILTONIAN_PATH}` considers an Hamiltonian
path whose weights are fixed. Having an edge in the path increases the
total weight.

`[x, tw]`-in-`HamiltonianPath{FIXED_WEIGHT_HAMILTONIAN_PATH}(n, weights)`:
`x` is a Hamiltonian path in the complete graph of `n` vertices.
`x[i]` is the index of the next vertex in the path. 
`tw` is the total weight of the path, with `weights` being indexed by the 
vertices: 

``\\mathtt{tw} = \\sum_{i=1}^{n} \\mathtt{weights[i, x[i]]} 1_{i \\neq t}``

## Variable-weight path

`HamiltonianPath{VARIABLE_WEIGHT_HAMILTONIAN_PATH}` considers an Hamiltonian
path whose weights are variable. Having an edge in the path increases the
total weight.

`[x, w, tw]`-in-`HamiltonianPath{VARIABLE_WEIGHT_HAMILTONIAN_PATH}(n)`:
`x` is a Hamiltonian path in the complete graph of `n` vertices.
`x[i]` is the index of the next vertex in the path. 
`tw` is the total weight of the path, with `w` being indexed by the vertices:

``\\mathtt{tw} = \\sum_{i=1}^{n} \\mathtt{w[i, x[i]]}``
"""
struct HamiltonianPath{HCWT, T <: Real} <: MOI.AbstractVectorSet
    n_nodes::Int
    s::Int
    t::Int
    weights::AbstractMatrix{T}
end

HamiltonianPath(n_nodes::Int, s::Int, t::Int, weights::AbstractMatrix{T}) where {T} = HamiltonianPath{FIXED_WEIGHT_HAMILTONIAN_PATH, T}(n_nodes, s, t, weights)

MOI.dimension(set::HamiltonianPath{FIXED_WEIGHT_HAMILTONIAN_PATH, T}) where {T <: Real} = set.n_nodes + 1
MOI.dimension(set::HamiltonianPath{VARIABLE_WEIGHT_HAMILTONIAN_PATH, T}) where {T <: Real} = 2 * set.n_nodes + 1
MOI.dimension(set::HamiltonianPath{UNWEIGHTED_HAMILTONIAN_PATH, T}) where {T <: Real} = set.n_nodes
