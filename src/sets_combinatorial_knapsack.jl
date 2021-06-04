"""
    Knapsack{T <: Real}(weights::T, capacity::Vector{T})

Ensures that the `n` variables respect a knapsack constraint with fixed weights
and a fixed capacity: 

``\\{x \\in \\{0, 1\\}^n | \\sum_{i=1}^n \\mathtt{weights[i]} x_i \\leq \\mathtt{capacity} \\}``.
"""
struct Knapsack{T <: Real} <: MOI.AbstractVectorSet
    weights::Vector{T}
    capacity::T

    function Knapsack(weights::Vector{T}, capacity::T) where {T <: Real}
        @assert all(weights .>= zero(T))
        @assert capacity >= zero(T)
        return new{T}(weights, capacity)
    end
end

MOI.dimension(set::Knapsack{T}) where {T} = length(set.weights)
function copy(set::Knapsack{T}) where {T}
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

    function VariableCapacityKnapsack(weights::Vector{T}) where {T <: Real}
        @assert all(weights .>= zero(T))
        return new{T}(weights)
    end
end

function MOI.dimension(set::VariableCapacityKnapsack{T}) where {T}
    return length(set.weights) + 1
end
function copy(set::VariableCapacityKnapsack{T}) where {T}
    return VariableCapacityKnapsack(copy(set.weights))
end
function Base.:(==)(
    x::VariableCapacityKnapsack{T},
    y::VariableCapacityKnapsack{T},
) where {T}
    return x.weights == y.weights
end

"""
    ValuedKnapsack{T <: Real}(weights::T, capacity::Vector{T})

Ensures that the `n` first variables respect a knapsack constraint with fixed 
weights and a fixed capacity, the last variable being the total value of the knapsack: 

``\\{(x, y) \\in \\{0, 1\\}^n \\times \\mathbb{R} | \\sum_{i=1}^n \\mathtt{weights[i]} x_i \\leq \\mathtt{capacity} \\land y = \\sum_{i=1}^n \\mathtt{values[i]} x_i \\}``.
"""
struct ValuedKnapsack{T <: Real} <: MOI.AbstractVectorSet
    weights::Vector{T}
    values::Vector{T}
    capacity::T

    function ValuedKnapsack(weights::Vector{T}, values::Vector{T}, capacity::T) where {T <: Real}
        @assert all(weights .>= zero(T))
        @assert all(values .>= zero(T))
        @assert capacity >= zero(T)
        return new{T}(weights, values, capacity)
    end
end

MOI.dimension(set::ValuedKnapsack{T}) where {T} = length(set.weights) + 1
function copy(set::ValuedKnapsack{T}) where {T}
    return ValuedKnapsack(copy(set.weights), copy(set.values), copy(set.capacity))
end
function Base.:(==)(x::ValuedKnapsack{T}, y::ValuedKnapsack{T}) where {T}
    return x.weights == y.weights && x.values == y.values && x.capacity == y.capacity
end

"""
    VariableCapacityValuedKnapsack{T <: Real}(weights::Vector{T})

Ensures that the first `n` variables respect a knapsack constraint with 
fixed weights and a capacity given by the last-but-one variable; the total 
value is the last variable: 

``\\{(x, y, z) \\in \\{0, 1\\}^n \\times \\mathbb{R} \\times \\mathbb{R} | \\sum_{i=1}^n \\mathtt{weights[i]} x_i \\leq y \\land z = \\sum_{i=1}^n \\mathtt{values[i]} x_i \\}``.
"""
struct VariableCapacityValuedKnapsack{T <: Real} <: MOI.AbstractVectorSet
    weights::Vector{T}
    values::Vector{T}

    function VariableCapacityValuedKnapsack(weights::Vector{T}, values::Vector{T}) where {T <: Real}
        @assert all(weights .>= zero(T))
        @assert all(values .>= zero(T))
        return new{T}(weights, values)
    end
end

function MOI.dimension(set::VariableCapacityValuedKnapsack{T}) where {T}
    return length(set.weights) + 2
end
function copy(set::VariableCapacityValuedKnapsack{T}) where {T}
    return VariableCapacityValuedKnapsack(copy(set.weights), copy(set.values))
end
function Base.:(==)(
    x::VariableCapacityValuedKnapsack{T},
    y::VariableCapacityValuedKnapsack{T},
) where {T}
    return x.weights == y.weights && x.values == y.values
end
