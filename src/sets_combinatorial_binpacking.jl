"""
    BinPackingCapacityType

Whether the capacities of a `BinPacking` constraint are fixed:

* either there is no capacity: `NO_CAPACITY_BINPACKING`
* or the capacity values are fixed when creating the set: `FIXED_CAPACITY_BINPACKING`
* or the capacity values are themselves variable: `VARIABLE_CAPACITY_BINPACKING`
"""
@enum BinPackingCapacityType begin
    NO_CAPACITY_BINPACKING
    FIXED_CAPACITY_BINPACKING
    VARIABLE_CAPACITY_BINPACKING
end

"""
    BinPacking(n_bins::Int, n_items::Int, weights::Vector{T})

## Uncapacitated bin packing

Implements an uncapacitated version of the bin-packing problem.

The first `n_bins` variables give the load in each bin, the last `n_items` give
the number of the bin to which the item is assigned to. 

The load of a bin is defined as the sum of the sizes of the items put in that 
bin.

Also called [`pack`](https://sofdem.github.io/gccat/gccat/Cbin_packing.html).

### Example

    [a, b, c] in BinPacking{NO_CAPACITY_BINPACKING}(1, 2, [2, 3])
    # As there is only one bin, the only solution is to put all the items in 
    # that bin.
    # Enforces that:
    # - the bin load is the sum of the weights of the objects in that bin: 
    #   a = 2 + 3
    # - the bin number of the two items is 1: b = c = 1

## Fixed-capacity bin packing

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

### Example
    [a, b, c] in BinPacking{FIXED_CAPACITY_BINPACKING}(1, 2, [2, 3], [4])
    # As there is only one bin, the only solution is to put all the items in
    # that bin if its capacity is large enough.
    # Enforces that:
    # - the bin load is the sum of the weights of the objects in that bin: 
    #   a = 2 + 3
    # - the bin load is at most its capacity: a <= 4 (given in the set)
    # - the bin number of the two items is 1: b = c = 1

## Variable-capacity bin packing

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
    [a, 2, b, c] in BinPacking{VARIABLE_CAPACITY_BINPACKING}(1, 2, [2, 3])
    # As there is only one bin, the only solution is to put all the items in
    # that bin if its capacity is large enough.
    # Enforces that:
    # - the bin load is the sum of the weights of the objects in that bin: 
    #   a = 2 + 3
    # - the bin load is at most its capacity: a <= 2 (given in a variable)
    # - the bin number of the two items is 1: b = c = 1
"""
struct BinPacking{BPCT, T <: Real} <: MOI.AbstractVectorSet
    n_bins::Int
    n_items::Int
    weights::Vector{T}
    capacities::Vector{T}

    function BinPacking{BPCT}(
        n_bins::Int,
        n_items::Int,
        weights::Vector{T},
        capacities::Vector{T},
    ) where {BPCT, T <: Real}
        @assert n_items == length(weights)
        @assert all(weights .>= zero(T))

        if BPCT == FIXED_CAPACITY_BINPACKING
            @assert n_bins == length(capacities)
            @assert all(capacities .>= zero(T))
        end

        @assert n_bins > 0
        @assert n_items > 0

        return new{BPCT, T}(n_bins, n_items, weights, capacities)
    end
end

function BinPacking{NO_CAPACITY_BINPACKING}(n_bins::Int, n_items::Int, weights::Vector{T}) where {T <: Real}
    return BinPacking{NO_CAPACITY_BINPACKING}(n_bins, n_items, weights, T[])
end

function BinPacking(n_bins::Int, n_items::Int, weights::Vector{T}, capacities::Vector{T}) where {T <: Real}
    return BinPacking{FIXED_CAPACITY_BINPACKING}(n_bins, n_items, weights, capacities)
end

function BinPacking{VARIABLE_CAPACITY_BINPACKING}(n_bins::Int, n_items::Int, weights::Vector{T}) where {T <: Real}
    return BinPacking{VARIABLE_CAPACITY_BINPACKING}(n_bins, n_items, weights, T[])
end

MOI.dimension(set::BinPacking{NO_CAPACITY_BINPACKING, T}) where {T} = set.n_bins + set.n_items
MOI.dimension(set::BinPacking{FIXED_CAPACITY_BINPACKING, T}) where {T} = set.n_bins + set.n_items
MOI.dimension(set::BinPacking{VARIABLE_CAPACITY_BINPACKING, T}) where {T} = 2 * set.n_bins + set.n_items

function copy(set::BinPacking{BPCT, T}) where {BPCT, T}
    return BinPacking{BPCT}(
        set.n_bins,
        set.n_items,
        copy(set.weights),
        copy(set.capacities),
    )
end

function Base.:(==)(x::BinPacking{BPCT, T}, y::BinPacking{BPCT, T}) where {BPCT, T}
    return x.n_bins == y.n_bins &&
           x.n_items == y.n_items &&
           x.weights == y.weights &&
           x.capacities == y.capacities
end

# Shortcuts for types.
# const BinPacking{T} = BinPacking{NO_CAPACITY_BINPACKING, T}
const BinPackingNoCapacity{T} = BinPacking{NO_CAPACITY_BINPACKING, T}
const BinPackingFixedCapacity{T} = BinPacking{FIXED_CAPACITY_BINPACKING, T}
const BinPackingVariableCapacity{T} = BinPacking{VARIABLE_CAPACITY_BINPACKING, T}
