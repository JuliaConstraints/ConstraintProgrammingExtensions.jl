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

MOI.dimension(set::BinPacking) = set.n_bins + 2 * set.n_items

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
        return new{T}(n_bins, n_items, weights)
    end
end

MOI.dimension(set::FixedCapacityBinPacking) = set.n_bins + set.n_items

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
Base.copy(set::Knapsack{T}) where {T} = Knapsack(copy(set.weights), set.capacity)

"""
    VariableCapacityKnapsack{T <: Real}(weights::Vector{T})

Ensures that the first `n` variables respect a knapsack constraint with fixed weights
and a capacity given by the last variable: 

``\\{(x, y) \\in \\{0, 1\\}^n \\times \\mathbb{R} | \\sum_{i=1}^n \\mathtt{weights[i]} x_i \\leq y \\}``.
"""
struct VariableCapacityKnapsack{T <: Real} <: MOI.AbstractVectorSet
    weights::Vector{T}
end

MOI.dimension(set::VariableCapacityKnapsack{T}) where {T} = length(set.weights) + 1
Base.copy(set::VariableCapacityKnapsack{T}) where {T} = VariableCapacityKnapsack(copy(set.weights))

"""
    WeightedKnapsack{T <: Real}(weights::Vector{T}, capacity::T, values::Vector{U})

Ensures that the `n` first variables, `x`, respect a knapsack constraint with fixed weights
and a fixed capacity: 

``\\{x \\in \\{0, 1\\}^n | \\sum_{i=1}^n \\mathtt{weights[i]} x_i \\leq \\mathtt{capacity} \\}``.

The last variable, `y`, is the total value of the knapsack

``y = \\mathtt{values[i]} x_i``.
"""
struct WeightedKnapsack{T <: Real, U <: Real} <: MOI.AbstractVectorSet
    weights::Vector{T}
    capacity::T
    values::Vector{U}
end

MOI.dimension(set::WeightedKnapsack{T, U}) where {T, U} = length(set.weights) + 1
Base.copy(set::WeightedKnapsack{T, U}) where {T, U} = Knapsack(copy(set.weights), set.capacity, copy(set.values))

"""
    VariableCapacityWeightedKnapsack{T <: Real, U <: Real}(weights::Vector{T}, values::Vector{U})

Ensures that the first `n` variables, `x`, respect a knapsack constraint with fixed weights
and a capacity given by the next variable, `y`: 

``\\{(x, y) \\in \\{0, 1\\}^n \\times \\mathbb{R} | \\sum_{i=1}^n \\mathtt{weights[i]} x_i \\leq y \\}``.

The last variable, `z`, is the total value of the knapsack

``z = \\mathtt{values[i]} x_i``.
"""
struct VariableCapacityWeightedKnapsack{T <: Real, U <: Real} <: MOI.AbstractVectorSet
    weights::Vector{T}
    values::Vector{U}
end

MOI.dimension(set::VariableCapacityWeightedKnapsack{T}) where {T} = length(set.weights) + 2
Base.copy(set::VariableCapacityWeightedKnapsack{T}) where {T} = VariableCapacityWeightedKnapsack(copy(set.weights), copy(set.values))
