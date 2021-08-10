"""
Bridges `CP.Knapsack{KCT, CP.UNVALUED_KNAPSACK}` to a MILP by adding the corresponding MILP constraint.
"""
struct Knapsack2MILPBridge{KCT, KVT, T} <: MOIBC.AbstractBridge
    kp::MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.LessThan{T}}
end

function MOIBC.bridge_constraint(
    ::Type{Knapsack2MILPBridge{KCT, KVT, T}},
    model,
    f::MOI.AbstractVectorFunction,
    s::CP.Knapsack{KCT, KVT, T},
) where {KCT, KVT, T}
    f_scalars = MOIU.scalarize(f)
    f_items = (KCT == CP.VARIABLE_CAPACITY_KNAPSACK) ? f_scalars[1:(end - 1)] : f_scalars
    f_capacity = (KCT == CP.VARIABLE_CAPACITY_KNAPSACK) ? f_scalars[end] : T(s.capacity)

    # Create the knapsack constraint.
    kp = MOI.add_constraint(
        model, 
        dot(f_items, s.weights) - f_capacity, 
        MOI.LessThan(zero(T))
    )

    return Knapsack2MILPBridge{KCT, KVT, T}(kp)
end

function MOI.supports_constraint(
    ::Type{Knapsack2MILPBridge{KCT, KVT, T}},
    ::Union{Type{MOI.VectorOfVariables}, Type{MOI.VectorAffineFunction{T}}},
    ::Type{CP.Knapsack{KCT, KVT, T}},
) where {KCT, KVT, T}
    return true
end

function MOIB.added_constrained_variable_types(::Type{<:Knapsack2MILPBridge{KCT, KVT, T}}) where {KCT, KVT, T}
    return Tuple{DataType}[]
end

function MOIB.added_constraint_types(::Type{Knapsack2MILPBridge{KCT, KVT, T}}) where {KCT, KVT, T}
    return [
        (MOI.ScalarAffineFunction{T}, MOI.LessThan{T}),
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
    ::MOI.ListOfConstraintIndices{
        MOI.ScalarAffineFunction{T},
        MOI.LessThan{T},
    },
) where {KCT, KVT, T}
    return [b.kp]
end
