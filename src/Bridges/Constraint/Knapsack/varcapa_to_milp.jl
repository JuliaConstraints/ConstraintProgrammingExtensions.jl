"""
Bridges `CP.VariableCapacityKnapsack` to a MILP by adding the corresponding 
MILP constraint.
"""
struct VariableCapacityKnapsack2MILPBridge{T} <: MOIBC.AbstractBridge
    kp::MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.LessThan{T}}
end

function MOIBC.bridge_constraint(
    ::Type{VariableCapacityKnapsack2MILPBridge{T}},
    model,
    f::MOI.AbstractVectorFunction,
    s::CP.VariableCapacityKnapsack{T},
) where {T}
    # Create the knapsack constraint.
    f_scalars = MOIU.scalarize(f)
    new_f = cpdot(f_scalars[1:end-1], s.weights) - f_scalars[end]
    kp = MOI.add_constraint(model, new_f, MOI.LessThan(zero(T)))

    return VariableCapacityKnapsack2MILPBridge(kp)
end

function MOI.supports_constraint(
    ::Type{VariableCapacityKnapsack2MILPBridge{T}},
    ::Union{Type{MOI.VectorOfVariables}, Type{MOI.VectorAffineFunction{T}}},
    ::Type{CP.VariableCapacityKnapsack{T}},
) where {T}
    return true
end

function MOIB.added_constrained_variable_types(::Type{<:VariableCapacityKnapsack2MILPBridge})
    return Tuple{DataType}[]
end

function MOIB.added_constraint_types(::Type{VariableCapacityKnapsack2MILPBridge{T}}) where {T}
    return [
        (MOI.ScalarAffineFunction{T}, MOI.LessThan{T}),
    ]
end

function MOI.get(
    ::VariableCapacityKnapsack2MILPBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.ScalarAffineFunction{T},
        MOI.LessThan{T},
    },
) where {T}
    return 1
end

function MOI.get(
    b::VariableCapacityKnapsack2MILPBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.ScalarAffineFunction{T},
        MOI.LessThan{T},
    },
) where {T}
    return [b.kp]
end
