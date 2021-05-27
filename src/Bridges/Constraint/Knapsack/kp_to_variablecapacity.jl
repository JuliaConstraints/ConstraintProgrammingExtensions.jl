"""
Bridges `CP.Knapsack` to `CP.VariableCapacityKnapsack` by creating 
capacity variables.
"""
struct Knapsack2VariableCapacityKnapsackBridge{T} <: MOIBC.AbstractBridge
    capa_var::Vector{MOI.VariableIndex}
    capa_con::Vector{MOI.ConstraintIndex{MOI.SingleVariable, MOI.Integer}}
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
    capa_var, capa_con = MOI.add_constrained_variables(model, [MOI.Integer() for _ in 1:length(s.weights)])

    # Add the capacity constraints.
    f_scalars = MOIU.scalarize(f)
    new_f = [f_scalars..., capa_var...]
    kp_set = CP.VariableCapacityKnapsack(s.weights)
    kp = MOI.add_constraint(model, MOI.VectorAffineFunction(new_f), kp_set)

    return Knapsack2VariableCapacityKnapsackBridge(capa_var, capa_con, kp)
end

function MOIBC.bridge_constraint(
    ::Type{Knapsack2VariableCapacityKnapsackBridge{T}},
    model,
    f::MOI.VectorAffineFunction{T},
    s::CP.Knapsack{T},
) where {T <: Real}
    # Add the capacity variables.
    capa_var = MOI.add_variables(model, length(s.weights))
    capa_con = MOI.ConstraintIndex{MOI.SingleVariable, MOI.Integer}[]

    # Add the capacity constraints.
    f_scalars = MOIU.scalarize(f)
    new_f = [f_scalars..., capa_var...]
    kp_set = CP.VariableCapacityKnapsack(s.weights)
    kp = MOI.add_constraint(model, MOI.VectorAffineFunction(new_f), kp_set)

    return Knapsack2VariableCapacityKnapsackBridge(capa_var, capa_con, kp)
end

function MOIB.added_constrained_variable_types(::Type{<:Knapsack2VariableCapacityKnapsackBridge{<:Integer}})
    return [(MOI.Integer,)]
end

function MOIB.added_constrained_variable_types(::Type{<:Knapsack2VariableCapacityKnapsackBridge{<:Real}})
    return Tuple{DataType}[]
end

function MOIB.added_constraint_types(::Type{Knapsack2VariableCapacityKnapsackBridge{T}}) where {T}
    return [
        (MOI.VectorAffineFunction{T}, CP.VariableCapacityKnapsack{T}),
    ]
end

MOI.get(b::Knapsack2VariableCapacityKnapsackBridge, ::MOI.NumberOfVariables) = 0

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
    ::MOI.NumberOfConstraints{
        MOI.SingleVariable,
        MOI.Integer,
    },
) where {T}
    return length(b.capa_con)
end

function MOI.get(
    b::Knapsack2VariableCapacityKnapsackBridge{T},
    ::MOI.ListOfVariableIndices,
) where {T}
    return b.capa_var
end

function MOI.get(
    b::Knapsack2VariableCapacityKnapsackBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.VectorAffineFunction{T},
        CP.VariableCapacityBinPacking{T},
    },
) where {T}
    return [b.bp]
end

function MOI.get(
    b::Knapsack2VariableCapacityKnapsackBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.SingleVariable,
        MOI.Integer,
    },
) where {T}
    return b.capa_con
end
