"""
Bridges `CP.Implication` to reification.
"""
struct Implication2ReificationBridge{T} <: MOIBC.AbstractBridge
    var_antecedent::MOI.VariableIndex
    var_consequent::MOI.VariableIndex
    var_antecedent_bin::MOI.ConstraintIndex{MOI.SingleVariable, MOI.ZeroOne}
    var_consequent_bin::MOI.ConstraintIndex{MOI.SingleVariable, MOI.ZeroOne}
    con_reif_antecedent::MOI.ConstraintIndex
    con_reif_consequent::MOI.ConstraintIndex
    # Ideally, Vector{MOI.ConstraintIndex{MOI.VectorAffineFunction{T}, CP.Reification{<: MOI.AbstractSet}}}, 
    # but Julia has no notion of type erasure.
    con_implication::MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.GreaterThan{T}}
end

function MOIBC.bridge_constraint(
    ::Type{Implication2ReificationBridge{T}},
    model,
    f::MOI.VectorOfVariables,
    s::CP.Implication{S1, S2},
) where {T, S1, S2}
    return MOIBC.bridge_constraint(
        Implication2ReificationBridge{T},
        model,
        MOI.VectorAffineFunction{T}(f),
        s,
    )
end

function MOIBC.bridge_constraint(
    ::Type{Implication2ReificationBridge{T}},
    model,
    f::MOI.VectorAffineFunction{T},
    s::CP.Implication{S1, S2},
) where {T, S1, S2}
    var_antecedent, var_antecedent_bin = MOI.add_constrained_variable(model, MOI.ZeroOne())
    var_consequent, var_consequent_bin = MOI.add_constrained_variable(model, MOI.ZeroOne())

    f_scalars = MOIU.scalarize(f)
    con_reif_antecedent = MOI.add_constraint(
        model,
        MOIU.vectorize(
            [
                one(T) * MOI.SingleVariable(var_antecedent),
                f_scalars[1 : MOI.dimension(s.antecedent)]...,
            ]
        ),
        CP.Reification(s.antecedent)
    )

    con_reif_consequent = MOI.add_constraint(
        model,
        MOIU.vectorize(
            [
                one(T) * MOI.SingleVariable(var_consequent),
                f_scalars[(MOI.dimension(s.antecedent) + 1) : (MOI.dimension(s.antecedent) + MOI.dimension(s.consequent))]...,
            ]
        ),
        CP.Reification(s.consequent)
    )

    # x ⟹ y is equivalent to ¬x ∨ y: 
    #     (1 - var_antecedent) + var_consequent ≥ 1
    #     var_consequent - var_antecedent ≥ 0
    con_implication = MOI.add_constraint(
        model, 
        one(T) * MOI.SingleVariable(var_consequent) - one(T) * MOI.SingleVariable(var_antecedent),
        MOI.GreaterThan(zero(T))
    )

    return Implication2ReificationBridge(var_antecedent, var_consequent, var_antecedent_bin, var_consequent_bin, con_reif_antecedent, con_reif_consequent, con_implication)
end

function MOI.supports_constraint(
    ::Type{Implication2ReificationBridge{T}},
    ::Union{Type{MOI.VectorOfVariables}, Type{MOI.VectorAffineFunction{T}}},
    ::Type{CP.Implication{S1, S2}},
) where {T, S1, S2}
    return true
    # Ideally, ensure that the underlying solver supports all the needed 
    # reified constraints.
end

function MOIB.added_constrained_variable_types(::Type{Implication2ReificationBridge{T}}) where {T}
    return [(MOI.ZeroOne,)]
end

function MOIB.added_constraint_types(::Type{Implication2ReificationBridge{T}}) where {T}
    return [
        (MOI.VectorAffineFunction{T}, CP.Reification), # TODO: how to be more precise?
        (MOI.ScalarAffineFunction{T}, MOI.GreaterThan{T}),
    ]
end

function MOI.get(::Implication2ReificationBridge{T}, ::MOI.NumberOfVariables) where {T}
    return 2
end

function MOI.get(
    ::Implication2ReificationBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.SingleVariable, MOI.ZeroOne,
    },
) where {T}
    return 2
end

function MOI.get(
    ::Implication2ReificationBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.VectorAffineFunction{T}, CP.Reification,
    },
) where {T}
    return 2
end

function MOI.get(
    ::Implication2ReificationBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.ScalarAffineFunction{T}, MOI.GreaterThan{T},
    },
) where {T}
    return 1
end

function MOI.get(
    b::Implication2ReificationBridge{T},
    ::MOI.ListOfVariableIndices,
) where {T}
    return [b.var_antecedent, b.var_consequent]
end

function MOI.get(
    b::Implication2ReificationBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.SingleVariable, MOI.ZeroOne,
    },
) where {T}
    return [b.var_antecedent_bin, b.var_consequent_bin]
end

function MOI.get(
    b::Implication2ReificationBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.VectorAffineFunction{T}, CP.Reification,
    },
) where {T}
    return [b.con_reif_antecedent, b.con_reif_consequent]
end

function MOI.get(
    b::Implication2ReificationBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.ScalarAffineFunction{T}, MOI.GreaterThan{T},
    },
) where {T}
    return [b.con_implication]
end
