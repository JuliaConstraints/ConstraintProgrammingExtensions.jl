"""
Bridges 
`CP.Knapsack{CP.FIXED_CAPACITY_KNAPSACK, CP.VALUED_KNAPSACK, T}` to 
`CP.Knapsack{CP.FIXED_CAPACITY_KNAPSACK, CP.UNVALUED_KNAPSACK, T}` 
by creating a value constraint.
"""
struct ValuedKnapsack2KnapsackBridge{T} <: MOIBC.AbstractBridge
    value::MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}}
    kp::MOI.ConstraintIndex{MOI.VectorAffineFunction{T}, CP.Knapsack{CP.FIXED_CAPACITY_KNAPSACK, CP.UNVALUED_KNAPSACK, T}}
end

function MOIBC.bridge_constraint(
    ::Type{ValuedKnapsack2KnapsackBridge{T}},
    model,
    f::MOI.VectorOfVariables,
    s::CP.Knapsack{CP.FIXED_CAPACITY_KNAPSACK, CP.VALUED_KNAPSACK, T},
) where {T}
    return MOIBC.bridge_constraint(
        ValuedKnapsack2KnapsackBridge{T},
        model,
        MOI.VectorAffineFunction{T}(f),
        s,
    )
end

function MOIBC.bridge_constraint(
    ::Type{ValuedKnapsack2KnapsackBridge{T}},
    model,
    f::MOI.VectorAffineFunction{T},
    s::CP.Knapsack{CP.FIXED_CAPACITY_KNAPSACK, CP.VALUED_KNAPSACK, T},
) where {T <: Real}
    f_scalars = MOIU.scalarize(f)

    # Add the value constraint.
    val_f = dot(s.values, f_scalars[1:end-1]) - f_scalars[end]
    val = MOI.add_constraint(model, val_f, MOI.EqualTo(zero(T)))

    # Add the knapsack constraint.
    new_f = MOIU.vectorize(f_scalars[1:end-1])
    kp_set = CP.Knapsack(s.weights, s.capacity)
    kp = MOI.add_constraint(model, new_f, kp_set)

    return ValuedKnapsack2KnapsackBridge(val, kp)
end

function MOI.supports_constraint(
    ::Type{ValuedKnapsack2KnapsackBridge{T}},
    ::Union{Type{MOI.VectorOfVariables}, Type{MOI.VectorAffineFunction{T}}},
    ::Type{CP.Knapsack{CP.FIXED_CAPACITY_KNAPSACK, CP.VALUED_KNAPSACK, T}},
) where {T}
    return true
end

function MOIB.added_constrained_variable_types(::Type{<:ValuedKnapsack2KnapsackBridge{T}}) where {T <: Real}
    return Tuple{DataType}[]
end

function MOIB.added_constraint_types(::Type{ValuedKnapsack2KnapsackBridge{T}}) where {T <: Real}
    return [
        (MOI.VectorAffineFunction{T}, CP.Knapsack{CP.FIXED_CAPACITY_KNAPSACK, CP.UNVALUED_KNAPSACK, T}),
        (MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}),
    ]
end

function MOI.get(
    ::ValuedKnapsack2KnapsackBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.VectorAffineFunction{T},
        CP.Knapsack{CP.FIXED_CAPACITY_KNAPSACK, CP.UNVALUED_KNAPSACK, T},
    },
) where {T}
    return 1
end

function MOI.get(
    ::ValuedKnapsack2KnapsackBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.ScalarAffineFunction{T},
        MOI.EqualTo{T},
    },
) where {T}
    return 1
end

function MOI.get(
    b::ValuedKnapsack2KnapsackBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.VectorAffineFunction{T},
        CP.Knapsack{CP.FIXED_CAPACITY_KNAPSACK, CP.UNVALUED_KNAPSACK, T},
    },
) where {T}
    return [b.kp]
end

function MOI.get(
    b::ValuedKnapsack2KnapsackBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.ScalarAffineFunction{T},
        MOI.EqualTo{T},
    },
) where {T}
    return [b.value]
end
