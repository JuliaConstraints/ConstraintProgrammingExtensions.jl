"""
Bridges `CP.VariableCapacityValuedKnapsack` to `CP.VariableCapacityKnapsack` 
by creating a value constraint.
"""
struct VariableCapacityValuedKnapsack2VariableCapacityKnapsackBrige{T} <: MOIBC.AbstractBridge
    value::MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}}
    kp::MOI.ConstraintIndex{MOI.VectorAffineFunction{T}, CP.VariableCapacityKnapsack{T}}
end

function MOIBC.bridge_constraint(
    ::Type{VariableCapacityValuedKnapsack2VariableCapacityKnapsackBrige{T}},
    model,
    f::MOI.VectorOfVariables,
    s::CP.VariableCapacityValuedKnapsack{T},
) where {T}
    return MOIBC.bridge_constraint(
        VariableCapacityValuedKnapsack2VariableCapacityKnapsackBrige{T},
        model,
        MOI.VectorAffineFunction{T}(f),
        s,
    )
end

function MOIBC.bridge_constraint(
    ::Type{VariableCapacityValuedKnapsack2VariableCapacityKnapsackBrige{T}},
    model,
    f::MOI.VectorAffineFunction{T},
    s::CP.VariableCapacityValuedKnapsack{T},
) where {T <: Real}
    f_scalars = MOIU.scalarize(f)

    # Add the value constraint.
    val_f = cpdot(s.values, f_scalars[1:end-2]) - f_scalars[end]
    val = MOI.add_constraint(model, val_f, MOI.EqualTo(zero(T)))

    # Add the knapsack constraint.
    new_f = MOIU.vectorize(f_scalars[1:end-1])
    kp_set = CP.VariableCapacityKnapsack(s.weights)
    kp = MOI.add_constraint(model, new_f, kp_set)

    return VariableCapacityValuedKnapsack2VariableCapacityKnapsackBrige(val, kp)
end

function MOI.supports_constraint(
    ::Type{VariableCapacityValuedKnapsack2VariableCapacityKnapsackBrige{T}},
    ::Union{Type{MOI.VectorOfVariables}, Type{MOI.VectorAffineFunction{T}}},
    ::Type{CP.VariableCapacityValuedKnapsack{T}},
) where {T}
    return true
end

function MOIB.added_constrained_variable_types(::Type{<:VariableCapacityValuedKnapsack2VariableCapacityKnapsackBrige{T}}) where {T <: Real}
    return Tuple{DataType}[]
end

function MOIB.added_constraint_types(::Type{VariableCapacityValuedKnapsack2VariableCapacityKnapsackBrige{T}}) where {T <: Real}
    return [
        (MOI.VectorAffineFunction{T}, CP.VariableCapacityKnapsack{T}),
        (MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}),
    ]
end

function MOIBC.concrete_bridge_type(
    ::Type{VariableCapacityValuedKnapsack2VariableCapacityKnapsackBrige{T}},
    ::Union{Type{MOI.VectorOfVariables}, Type{MOI.VectorAffineFunction{T}}},
    ::Type{CP.VariableCapacityValuedKnapsack{T}},
) where {T}
    return VariableCapacityValuedKnapsack2VariableCapacityKnapsackBrige{T}
end

MOI.get(b::VariableCapacityValuedKnapsack2VariableCapacityKnapsackBrige, ::MOI.NumberOfVariables) = 0

function MOI.get(
    ::VariableCapacityValuedKnapsack2VariableCapacityKnapsackBrige{T},
    ::MOI.NumberOfConstraints{
        MOI.VectorAffineFunction{T},
        CP.VariableCapacityKnapsack{T},
    },
) where {T}
    return 1
end

function MOI.get(
    ::VariableCapacityValuedKnapsack2VariableCapacityKnapsackBrige{T},
    ::MOI.NumberOfConstraints{
        MOI.ScalarAffineFunction{T},
        MOI.EqualTo{T},
    },
) where {T}
    return 1
end

function MOI.get(
    b::VariableCapacityValuedKnapsack2VariableCapacityKnapsackBrige{T},
    ::MOI.ListOfConstraintIndices{
        MOI.VectorAffineFunction{T},
        CP.VariableCapacityKnapsack{T},
    },
) where {T}
    return [b.kp]
end

function MOI.get(
    b::VariableCapacityValuedKnapsack2VariableCapacityKnapsackBrige{T},
    ::MOI.ListOfConstraintIndices{
        MOI.ScalarAffineFunction{T},
        MOI.EqualTo{T},
    },
) where {T}
    return [b.value]
end
