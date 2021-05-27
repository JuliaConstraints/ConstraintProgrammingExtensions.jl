"""
Bridges `CP.Knapsack` to a MILP by adding the corresponding MILP constraint.
"""
struct Knapsack2MILPBridge{T} <: MOIBC.AbstractBridge
    kp::MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.LessThan{T}}
end

function MOIBC.bridge_constraint(
    ::Type{Knapsack2MILPBridge{T}},
    model,
    f::MOI.AbstractVectorFunction,
    s::CP.Knapsack{T},
) where {T}
    # Create the knapsack constraint.
    new_f = sum(
        operate_dimension_coefficient(
            (coeff, index) -> coeff * s.weights[index], 
            f
        )
    )
    kp = MOI.add_constraint(model, new_f, MOI.LessThan(s.capacity))

    return Knapsack2MILPBridge(kp)
end

function MOIB.added_constrained_variable_types(::Type{<:Knapsack2MILPBridge})
    return Tuple{DataType}[]
end

function MOIB.added_constraint_types(::Type{Knapsack2MILPBridge{T}}) where {T}
    return [
        (MOI.ScalarAffineFunction{T}, MOI.LessThan{T}),
    ]
end

function MOI.get(b::Knapsack2MILPBridge, ::MOI.NumberOfVariables)
    return 0
end

function MOI.get(
    b::Knapsack2MILPBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.ScalarAffineFunction{T},
        MOI.LessThan{T},
    },
) where {T}
    return 1
end

function MOI.get(
    b::Knapsack2MILPBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.ScalarAffineFunction{T},
        MOI.LessThan{T},
    },
) where {T}
    return [b.kp]
end
