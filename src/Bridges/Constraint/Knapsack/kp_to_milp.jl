"""
Bridges `CP.Knapsack{KCT, KVT}` to a MILP by adding the corresponding MILP 
constraint.
"""
struct Knapsack2MILPBridge{KCT, KVT, T} <: MOIBC.AbstractBridge
    kp::MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.LessThan{T}}
    value::Union{
        MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}},
        Nothing,
    }
end

function MOIBC.bridge_constraint(
    ::Type{Knapsack2MILPBridge{KCT, CP.UNVALUED_KNAPSACK, T}},
    model,
    f::MOI.AbstractVectorFunction,
    s::CP.Knapsack{KCT, CP.UNVALUED_KNAPSACK, T},
) where {KCT, T}
    f_scalars = MOIU.scalarize(f)
    f_items = (KCT == CP.VARIABLE_CAPACITY_KNAPSACK) ? f_scalars[1:(end - 1)] : f_scalars
    f_capacity = (KCT == CP.VARIABLE_CAPACITY_KNAPSACK) ? f_scalars[end] : T(s.capacity)

    # Create the knapsack constraint.
    kp = MOI.add_constraint(
        model, 
        dot(f_items, s.weights) - f_capacity, 
        MOI.LessThan(zero(T))
    )

    return Knapsack2MILPBridge{KCT, CP.UNVALUED_KNAPSACK, T}(kp, nothing)
end

function MOIBC.bridge_constraint(
    ::Type{Knapsack2MILPBridge{KCT, CP.VALUED_KNAPSACK, T}},
    model,
    f::MOI.AbstractVectorFunction,
    s::CP.Knapsack{KCT, CP.VALUED_KNAPSACK, T},
) where {KCT, T}
    f_scalars = MOIU.scalarize(f)
    f_items = (KCT == CP.VARIABLE_CAPACITY_KNAPSACK) ? f_scalars[1:(end - 2)] : f_scalars[1:(end - 1)]
    f_capacity = (KCT == CP.VARIABLE_CAPACITY_KNAPSACK) ? f_scalars[end - 1] : T(s.capacity)
    f_value = f_scalars[end]

    # Create the knapsack constraint.
    kp = MOI.add_constraint(
        model, 
        dot(f_items, s.weights) - f_capacity, 
        MOI.LessThan(zero(T))
    )

    # Create the value constraint.
    value = MOI.add_constraint(
        model, 
        dot(f_items, s.values) - f_value, 
        MOI.EqualTo(zero(T))
    )

    return Knapsack2MILPBridge{KCT, CP.VALUED_KNAPSACK, T}(kp, value)
end

function MOI.supports_constraint(
    ::Type{Knapsack2MILPBridge{KCT, KVT, T}},
    ::Union{Type{MOI.VectorOfVariables}, Type{MOI.VectorAffineFunction{T}}},
    ::Type{CP.Knapsack{KCT, KVT, T}},
) where {KCT, KVT, T}
    return true
end

function MOIB.added_constrained_variable_types(::Type{<:Knapsack2MILPBridge{KCT, KVT, T}}) where {KCT, KVT, T}
    return Tuple{Type}[]
end

function MOIB.added_constraint_types(::Type{Knapsack2MILPBridge{KCT, CP.UNVALUED_KNAPSACK, T}}) where {KCT, T}
    return [
        (MOI.ScalarAffineFunction{T}, MOI.LessThan{T}),
    ]
end

function MOIB.added_constraint_types(::Type{Knapsack2MILPBridge{KCT, CP.VALUED_KNAPSACK, T}}) where {KCT, T}
    return [
        (MOI.ScalarAffineFunction{T}, MOI.LessThan{T}),
        (MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}),
    ]
end

function MOI.get(
    ::Knapsack2MILPBridge{KCT, KVT, T},
    ::MOI.NumberOfConstraints{
        MOI.ScalarAffineFunction{T},
        MOI.LessThan{T},
    },
) where {KCT, KVT, T}
    return 1
end

function MOI.get(
    b::Knapsack2MILPBridge{KCT, KVT, T},
    ::MOI.NumberOfConstraints{
        MOI.ScalarAffineFunction{T},
        MOI.EqualTo{T},
    },
) where {KCT, KVT, T}
    return (b.value !== nothing) ? 1 : 0
end

function MOI.get(
    b::Knapsack2MILPBridge{KCT, KVT, T},
    ::MOI.ListOfConstraintIndices{
        MOI.ScalarAffineFunction{T},
        MOI.LessThan{T},
    },
) where {KCT, KVT, T}
    return [b.kp]
end

function MOI.get(
    b::Knapsack2MILPBridge{KCT, KVT, T},
    ::MOI.ListOfConstraintIndices{
        MOI.ScalarAffineFunction{T},
        MOI.EqualTo{T},
    },
) where {KCT, KVT, T}
    return [b.value]
end
