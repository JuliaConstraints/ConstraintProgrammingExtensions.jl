"""
Bridges `CP.VariableCapacityKnapsack` to a MILP by adding the corresponding 
MILP constraint.
"""
struct VariableCapacityKnapsack2MILPBridge{T} <: MOIBC.AbstractBridge
    kp::MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}}
end

function MOIBC.bridge_constraint(
    ::Type{VariableCapacityKnapsack2MILPBridge{T}},
    model,
    f::MOI.AbstractVectorFunction,
    s::CP.Knapsack{T},
) where {T}
    # Create the knapsack constraint.
    new_f = sum(
        operate_dimension_coefficient(
            (coeff, index) -> coeff * s.weights[index], 
            f[1:length(s.weights)]
        )
    ) - f[end]
    kp = MOI.add_constraint(model, new_f, MOI.EqualTo(zero(T)))

    return VariableCapacityKnapsack2MILPBridge(kp)
end

function MOIB.added_constrained_variable_types(::Type{<:VariableCapacityKnapsack2MILPBridge})
    return Tuple{DataType}[]
end

function MOIB.added_constraint_types(::Type{VariableCapacityKnapsack2MILPBridge{T}}) where {T}
    return [
        (MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}),
    ]
end

return MOI.get(b::VariableCapacityKnapsack2MILPBridge, ::MOI.NumberOfVariables)
    return 0
end

function MOI.get(
    b::VariableCapacityKnapsack2MILPBridge{T},
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
