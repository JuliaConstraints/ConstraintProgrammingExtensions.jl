"""
    KnapsackCapacityType

Whether the capacity of a `Knapsack` constraint is fixed:

* either the value is fixed when creating the set: `FIXED_CAPACITY_KNAPSACK`
* or the value is itself variable: `VARIABLE_CAPACITY_KNAPSACK`
"""
@enum KnapsackCapacityType begin
    FIXED_CAPACITY_KNAPSACK
    VARIABLE_CAPACITY_KNAPSACK
end

"""
    KnapsackValueType

Whether the value of a `Knapsack` constraint is needed:

* either the value is not available: `UNVALUED_CAPACITY_KNAPSACK`
* or the value is available as a new variable: `VALUED_CAPACITY_KNAPSACK`
"""
@enum KnapsackValueType begin
    UNVALUED_CAPACITY_KNAPSACK
    VALUED_CAPACITY_KNAPSACK
end

"""
    Knapsack{KCT, KVT, T <: Real}(weights::T, capacity::Vector{T})

## Fixed capacity, unvalued

Ensures that the `n` variables respect a knapsack constraint with fixed weights
and a fixed capacity: 

``\\{x \\in \\{0, 1\\}^n | \\sum_{i=1}^n \\mathtt{weights[i]} x_i \\leq \\mathtt{capacity} \\}``.

## Variable capacity, unvalued

Ensures that the first `n` variables respect a knapsack constraint with fixed weights
and a capacity given by the last variable: 

``\\{(x, y) \\in \\{0, 1\\}^n \\times \\mathbb{R} | \\sum_{i=1}^n \\mathtt{weights[i]} x_i \\leq y \\}``.

## Fixed capacity, valued

Ensures that the `n` first variables respect a knapsack constraint with fixed 
weights and a fixed capacity, the last variable being the total value of the 
knapsack: 

``\\{(x, y) \\in \\{0, 1\\}^n \\times \\mathbb{R} | \\sum_{i=1}^n \\mathtt{weights[i]} x_i \\leq \\mathtt{capacity} \\land y = \\sum_{i=1}^n \\mathtt{values[i]} x_i \\}``.

## Variable capacity, valued

Ensures that the first `n` variables respect a knapsack constraint with 
fixed weights and a capacity given by the last-but-one variable; the total 
value is the last variable: 

``\\{(x, y, z) \\in \\{0, 1\\}^n \\times \\mathbb{R} \\times \\mathbb{R} | \\sum_{i=1}^n \\mathtt{weights[i]} x_i \\leq y \\land z = \\sum_{i=1}^n \\mathtt{values[i]} x_i \\}``.
"""
struct Knapsack{KCT, KVT, T <: Real} <: MOI.AbstractVectorSet
    weights::Vector{T}
    capacity::T
    values::Vector{T}

    function Knapsack{KCT, KVT}(weights::Vector{T}, capacity::T, values::Vector{T}) where {KCT, KVT, T <: Real}
        @assert all(weights .>= zero(T))
        if KVT == VALUED_CAPACITY_KNAPSACK
            @assert all(values .>= zero(T))
        end
        if KCT == FIXED_CAPACITY_KNAPSACK
            @assert capacity > zero(T)
        end
        return new{KCT, KVT, T}(weights, capacity, values)
    end
end

Knapsack(weights::Vector{T}) where {T} = Knapsack{VARIABLE_CAPACITY_KNAPSACK, UNVALUED_CAPACITY_KNAPSACK}(weights, zero(T), T[])
Knapsack(weights::Vector{T}, capacity::T) where {T} = Knapsack{FIXED_CAPACITY_KNAPSACK, UNVALUED_CAPACITY_KNAPSACK}(weights, capacity, T[])
Knapsack(weights::Vector{T}, values::Vector{T}) where {T} = Knapsack{VARIABLE_CAPACITY_KNAPSACK, VALUED_CAPACITY_KNAPSACK}(weights, zero(T), values)
Knapsack(weights::Vector{T}, capacity::T, values::Vector{T}) where {T} = Knapsack{FIXED_CAPACITY_KNAPSACK, VALUED_CAPACITY_KNAPSACK}(weights, capacity, values)

function Knapsack(; weights::Vector{T}, capacity::T=zero(T), values::Vector{T}=T[]) where {T <: Real}
    KCT = iszero(capacity) ? VARIABLE_CAPACITY_KNAPSACK : FIXED_CAPACITY_KNAPSACK
    KVT = length(values) == 0 ? UNVALUED_CAPACITY_KNAPSACK : VALUED_CAPACITY_KNAPSACK
    return Knapsack{KCT, KVT, T}(weights, capacity, values)
end

MOI.dimension(set::Knapsack{FIXED_CAPACITY_KNAPSACK, UNVALUED_CAPACITY_KNAPSACK, T}) where {T} = length(set.weights)
MOI.dimension(set::Knapsack{VARIABLE_CAPACITY_KNAPSACK, UNVALUED_CAPACITY_KNAPSACK, T}) where {T} = length(set.weights) + 1
MOI.dimension(set::Knapsack{FIXED_CAPACITY_KNAPSACK, VALUED_CAPACITY_KNAPSACK, T}) where {T} = length(set.weights) + 1
MOI.dimension(set::Knapsack{VARIABLE_CAPACITY_KNAPSACK, VALUED_CAPACITY_KNAPSACK, T}) where {T} = length(set.weights) + 2

function copy(set::Knapsack{KCT, KVT, T}) where {KCT, KVT, T}
    return Knapsack{KCT, KVT}(copy(set.weights), copy(set.capacity), copy(set.values))
end

function Base.:(==)(x::Knapsack{KCT, KVT, T}, y::Knapsack{KCT, KVT, T}) where {KCT, KVT, T}
    return x.weights == y.weights && x.values == y.values && x.capacity == y.capacity
end

# Shortcuts for types.
# const Knapsack{T} = Knapsack{FIXED_CAPACITY_KNAPSACK, UNVALUED_CAPACITY_KNAPSACK, T}
const KnapsackFixedCapacity{T} = Knapsack{FIXED_CAPACITY_KNAPSACK, UNVALUED_CAPACITY_KNAPSACK, T}
const KnapsackFixedCapacityUnvalued{T} = Knapsack{FIXED_CAPACITY_KNAPSACK, UNVALUED_CAPACITY_KNAPSACK, T}
const KnapsackFixedCapacityValued{T} = Knapsack{FIXED_CAPACITY_KNAPSACK, VALUED_CAPACITY_KNAPSACK, T}
const KnapsackValued{T} = Knapsack{FIXED_CAPACITY_KNAPSACK, VALUED_CAPACITY_KNAPSACK, T}
const KnapsackVariableCapacity{T} = Knapsack{VARIABLE_CAPACITY_KNAPSACK, UNVALUED_CAPACITY_KNAPSACK, T}
const KnapsackVariableCapacityUnvalued{T} = Knapsack{VARIABLE_CAPACITY_KNAPSACK, UNVALUED_CAPACITY_KNAPSACK, T}
const KnapsackVariableCapacityValued{T} = Knapsack{VARIABLE_CAPACITY_KNAPSACK, VALUED_CAPACITY_KNAPSACK, T}
