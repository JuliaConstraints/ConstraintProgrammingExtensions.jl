"""
    BinPacking(n_bins::Int, n_items::Int, weights::Vector{T})

Implements an uncapacitated version of the bin-packing problem.

The first `n_bins` variables give the load in each bin, the last `n_items` give
the number of the bin to which the item is assigned to. 

The load of a bin is defined as the sum of the sizes of the items put in that 
bin.

Also called [`pack`](https://sofdem.github.io/gccat/gccat/Cbin_packing.html).

## Example

    [a, b, c] in BinPacking{Int}(1, 2, [2, 3])
    # As there is only one bin, the only solution is to put all the items in 
    # that bin.
    # Enforces that:
    # - the bin load is the sum of the weights of the objects in that bin: 
    #   a = 2 + 3
    # - the bin number of the two items is 1: b = c = 1
"""
struct BinPacking{T <: Real} <: MOI.AbstractVectorSet
    n_bins::Int
    n_items::Int
    weights::Vector{T}

    function BinPacking(
        n_bins::Int,
        n_items::Int,
        weights::Vector{T},
    ) where {T <: Real}
        @assert n_items == length(weights)
        return new{T}(n_bins, n_items, weights)
    end
end

MOI.dimension(set::BinPacking) = set.n_bins + set.n_items
function Base.copy(set::BinPacking{T}) where {T}
    return BinPacking(set.n_bins, set.n_items, copy(set.weights))
end
function Base.:(==)(x::BinPacking{T}, y::BinPacking{T}) where {T}
    return x.n_bins == y.n_bins &&
           x.n_items == y.n_items &&
           x.weights == y.weights
end

"""
    FixedCapacityBinPacking(n_bins::Int, n_items::Int, weights::Vector{T}, capacities::Vector{<:Real})

Implements a capacitated version of the bin-packing problem where capacities
are constant.

The first `n_bins` variables give the load in each bin, the last `n_items` 
give the number of the bin to which the item is assigned to. 

The load of a bin is defined as the sum of the sizes of the items put in that 
bin.

This constraint is equivalent to `BinPacking` with inequality constraints on 
the loads of the bins where the upper bound is a constant. However, there are 
more efficient propagators for the combined constraint (bin packing with 
maximum load); if such propagators are not available, bridges are available to
make the conversion seamless.

Also called [`bin_packing_capa`](https://sofdem.github.io/gccat/gccat/Cbin_packing_capa.html).

## Example
    [a, b, c] in FixedCapacityBinPacking{Int}(1, 2, [2, 3], [4])
    # As there is only one bin, the only solution is to put all the items in
    # that bin if its capacity is large enough.
    # Enforces that:
    # - the bin load is the sum of the weights of the objects in that bin: 
    #   a = 2 + 3
    # - the bin load is at most its capacity: a <= 4 (given in the set)
    # - the bin number of the two items is 1: b = c = 1
"""
struct FixedCapacityBinPacking{T <: Real} <: MOI.AbstractVectorSet
    n_bins::Int
    n_items::Int
    weights::Vector{T}
    capacities::Vector{T}

    function FixedCapacityBinPacking(
        n_bins::Int,
        n_items::Int,
        weights::Vector{T},
        capacities::Vector{T},
    ) where {T <: Real}
        @assert n_items == length(weights)
        @assert n_bins == length(capacities)
        return new{T}(n_bins, n_items, weights, capacities)
    end
end

MOI.dimension(set::FixedCapacityBinPacking) = set.n_bins + set.n_items
function Base.copy(set::FixedCapacityBinPacking{T}) where {T}
    return FixedCapacityBinPacking(
        set.n_bins,
        set.n_items,
        copy(set.weights),
        copy(set.capacities),
    )
end
function Base.:(==)(
    x::FixedCapacityBinPacking{T},
    y::FixedCapacityBinPacking{T},
) where {T}
    return x.n_bins == y.n_bins &&
           x.n_items == y.n_items &&
           x.weights == y.weights &&
           x.capacities == y.capacities
end

"""
    VariableCapacityBinPacking(n_bins::Int, n_items::Int, weights::Vector{T})

Implements an capacitated version of the bin-packing problem where capacities 
are optimisation variables.

The first `n_bins` variables give the load in each bin, the next `n_bins` are
the capacity of each bin, the last `n_items` give the number of the bin to
which the item is assigned to.

The load of a bin is defined as the sum of the sizes of the items put in that 
bin.

This constraint is equivalent to `BinPacking` with inequality constraints on 
the loads of the bins where the upper bound is any expression. However, there 
are more efficient propagators for the combined constraint (bin packing with 
maximum load) and for the fixed-capacity version.

Also called [`bin_packing_capa`](https://sofdem.github.io/gccat/gccat/Cbin_packing_capa.html).

## Example
    [a, 2, b, c] in VariableCapacityBinPacking(1, 2, [2, 3])
    # As there is only one bin, the only solution is to put all the items in
    # that bin if its capacity is large enough.
    # Enforces that:
    # - the bin load is the sum of the weights of the objects in that bin: 
    #   a = 2 + 3
    # - the bin load is at most its capacity: a <= 2 (given in a variable)
    # - the bin number of the two items is 1: b = c = 1
"""
struct VariableCapacityBinPacking{T <: Real} <: MOI.AbstractVectorSet
    n_bins::Int
    n_items::Int
    weights::Vector{T}

    function VariableCapacityBinPacking(
        n_bins::Int,
        n_items::Int,
        weights::Vector{T},
    ) where {T <: Real}
        @assert n_items == length(weights)
        return new{T}(n_bins, n_items, weights)
    end
end

MOI.dimension(set::VariableCapacityBinPacking) = 2 * set.n_bins + set.n_items
function Base.copy(set::VariableCapacityBinPacking{T}) where {T}
    return VariableCapacityBinPacking(
        set.n_bins,
        set.n_items,
        copy(set.weights),
    )
end
function Base.:(==)(
    x::VariableCapacityBinPacking{T},
    y::VariableCapacityBinPacking{T},
) where {T}
    return x.n_bins == y.n_bins &&
           x.n_items == y.n_items &&
           x.weights == y.weights
end

"""
    Knapsack{T <: Real}(weights::T, capacity::Vector{T})

Ensures that the `n` variables respect a knapsack constraint with fixed weights
and a fixed capacity: 

``\\{x \\in \\{0, 1\\}^n | \\sum_{i=1}^n \\mathtt{weights[i]} x_i \\leq \\mathtt{capacity} \\}``.
"""
struct Knapsack{T <: Real} <: MOI.AbstractVectorSet
    weights::Vector{T}
    capacity::T
end

MOI.dimension(set::Knapsack{T}) where {T} = length(set.weights)
function Base.copy(set::Knapsack{T}) where {T}
    return Knapsack(copy(set.weights), copy(set.capacity))
end
function Base.:(==)(x::Knapsack{T}, y::Knapsack{T}) where {T}
    return x.weights == y.weights && x.capacity == y.capacity
end

"""
    VariableCapacityKnapsack{T <: Real}(weights::Vector{T})

Ensures that the first `n` variables respect a knapsack constraint with fixed weights
and a capacity given by the last variable: 

``\\{(x, y) \\in \\{0, 1\\}^n \\times \\mathbb{R} | \\sum_{i=1}^n \\mathtt{weights[i]} x_i \\leq y \\}``.
"""
struct VariableCapacityKnapsack{T <: Real} <: MOI.AbstractVectorSet
    weights::Vector{T}
end

function MOI.dimension(set::VariableCapacityKnapsack{T}) where {T}
    return length(set.weights) + 1
end
function Base.copy(set::VariableCapacityKnapsack{T}) where {T}
    return VariableCapacityKnapsack(copy(set.weights))
end
function Base.:(==)(
    x::VariableCapacityKnapsack{T},
    y::VariableCapacityKnapsack{T},
) where {T}
    return x.weights == y.weights
end

"""
    Contiguity(dimension::Int)

Ensures that, in the binary variables `x` constrained to be in this set, 
all the 1s are contiguous. The vector must correspond to the regular expression
`0*1*0*`.
"""
struct Contiguity <: MOI.AbstractVectorSet
    dimension::Int
end

# isbits types, nothing to copy
function Base.copy(set::Contiguity)
    return set
end
