"""
Bridges `CP.Knapsack` to `CP.VariableCapacityKnapsack` by creating 
capacity variables.
"""
struct Knapsack2VariableCapacityKnapsackBridge{T} <: MOIBC.AbstractBridge
    capa_var::MOI.VariableIndex
    capa_con::Union{MOI.ConstraintIndex{MOI.SingleVariable, MOI.Integer}, Nothing}
    kp::MOI.ConstraintIndex{MOI.VectorAffineFunction{T}, CP.VariableCapacityKnapsack{T}}
end

function MOIBC.bridge_constraint(
    ::Type{Knapsack2VariableCapacityKnapsackBridge{T}},
    model,
    f::MOI.VectorOfVariables,
    s::CP.Knapsack{T},
) where {T}
    return MOIBC.bridge_constraint(
        Knapsack2VariableCapacityKnapsackBridge{T},
        model,
        MOI.VectorAffineFunction{T}(f),
        s,
    )
end

function MOIBC.bridge_constraint(
    ::Type{Knapsack2VariableCapacityKnapsackBridge{T}},
    model,
    f::MOI.VectorAffineFunction{T},
    s::CP.Knapsack{T},
) where {T <: Integer}
    # Add the capacity variables.
    capa_var, capa_con = MOI.add_constrained_variable(model, MOI.Integer())

    # Add the capacity constraints.
    f_scalars = MOIU.scalarize(f)
    f_capa = MOI.ScalarAffineFunction([MOI.ScalarAffineTerm(one(T), capa_var)], zero(T))
    new_f = MOIU.vectorize([f_scalars..., f_capa])
    kp_set = CP.VariableCapacityKnapsack(s.weights)
    kp = MOI.add_constraint(model, new_f, kp_set)

    return Knapsack2VariableCapacityKnapsackBridge(capa_var, capa_con, kp)
end

function MOIBC.bridge_constraint(
    ::Type{Knapsack2VariableCapacityKnapsackBridge{T}},
    model,
    f::MOI.VectorAffineFunction{T},
    s::CP.Knapsack{T},
) where {T <: Real}
    # Add the capacity variables.
    capa_var = MOI.add_variable(model)
    capa_con = nothing

    # Add the capacity constraints.
    f_scalars = MOIU.scalarize(f)
    f_capa = MOI.ScalarAffineFunction([MOI.ScalarAffineTerm(one(T), capa_var)], zero(T))
    new_f = MOIU.vectorize([f_scalars..., f_capa])
    kp_set = CP.VariableCapacityKnapsack(s.weights)
    kp = MOI.add_constraint(model, new_f, kp_set)

    return Knapsack2VariableCapacityKnapsackBridge(capa_var, capa_con, kp)
end

function MOI.supports_constraint(
    ::Type{Knapsack2VariableCapacityKnapsackBridge{T}},
    ::Union{Type{MOI.VectorOfVariables}, Type{MOI.VectorAffineFunction{T}}},
    ::Type{CP.Knapsack{T}},
) where {T}
    return true
end

function MOIB.added_constrained_variable_types(::Type{<:Knapsack2VariableCapacityKnapsackBridge{T}}) where {T <: Integer}
    return [(MOI.Integer,)]
end

function MOIB.added_constrained_variable_types(::Type{<:Knapsack2VariableCapacityKnapsackBridge{T}}) where {T <: Real}
    return Tuple{DataType}[]
end

function MOIB.added_constraint_types(::Type{Knapsack2VariableCapacityKnapsackBridge{T}}) where {T <: Integer}
    return [
        (MOI.VectorAffineFunction{T}, CP.VariableCapacityKnapsack{T}),
        (MOI.SingleVariable, MOI.Integer),
    ]
end

function MOIB.added_constraint_types(::Type{Knapsack2VariableCapacityKnapsackBridge{T}}) where {T <: Real}
    return [
        (MOI.VectorAffineFunction{T}, CP.VariableCapacityKnapsack{T}),
    ]
end

function MOIBC.concrete_bridge_type(
    ::Type{Knapsack2VariableCapacityKnapsackBridge{T}},
    ::Union{Type{MOI.VectorOfVariables}, Type{MOI.VectorAffineFunction{T}}},
    ::Type{CP.VariableCapacityKnapsack{T}},
) where {T}
    return Knapsack2VariableCapacityKnapsackBridge{T}
end

MOI.get(b::Knapsack2VariableCapacityKnapsackBridge, ::MOI.NumberOfVariables) = 1

function MOI.get(
    ::Knapsack2VariableCapacityKnapsackBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.SingleVariable,
        MOI.Integer,
    },
) where {T <: Integer}
    return 1
end

function MOI.get(
    ::Knapsack2VariableCapacityKnapsackBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.SingleVariable,
        MOI.Integer,
    },
) where {T <: Real}
    return 0
end

function MOI.get(
    ::Knapsack2VariableCapacityKnapsackBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.VectorAffineFunction{T},
        CP.VariableCapacityKnapsack{T},
    },
) where {T}
    return 1
end

function MOI.get(
    b::Knapsack2VariableCapacityKnapsackBridge{T},
    ::MOI.ListOfVariableIndices,
) where {T}
    return [b.capa_var]
end

function MOI.get(
    b::Knapsack2VariableCapacityKnapsackBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.VectorAffineFunction{T},
        CP.VariableCapacityKnapsack{T},
    },
) where {T}
    return [b.kp]
end

function MOI.get(
    b::Knapsack2VariableCapacityKnapsackBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.SingleVariable,
        MOI.Integer,
    },
) where {T <: Integer}
    return [b.capa_con]
end
# Undefined for <: Real.
