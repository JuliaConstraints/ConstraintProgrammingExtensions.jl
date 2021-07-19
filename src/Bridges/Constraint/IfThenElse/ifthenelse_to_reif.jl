"""
Bridges `CP.IfThenElse` to reification.
"""
struct IfThenElse2ReificationBridge{T} <: MOIBC.AbstractBridge
    var_condition::MOI.VariableIndex
    var_true::MOI.VariableIndex
    var_false::MOI.VariableIndex
    var_condition_bin::MOI.ConstraintIndex{MOI.SingleVariable, MOI.ZeroOne}
    var_true_bin::MOI.ConstraintIndex{MOI.SingleVariable, MOI.ZeroOne}
    var_false_bin::MOI.ConstraintIndex{MOI.SingleVariable, MOI.ZeroOne}
    con_reif_condition::MOI.ConstraintIndex
    con_reif_true::MOI.ConstraintIndex
    con_reif_false::MOI.ConstraintIndex
    # Ideally, Vector{MOI.ConstraintIndex{MOI.VectorAffineFunction{T}, CP.Reification{<: MOI.AbstractSet}}}, 
    # but Julia has no notion of type erasure.
    con_if::MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.GreaterThan{T}}
    con_else::MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.GreaterThan{T}}
end

function MOIBC.bridge_constraint(
    ::Type{IfThenElse2ReificationBridge{T}},
    model,
    f::MOI.VectorOfVariables,
    s::CP.IfThenElse{S1, S2, S3},
) where {T, S1, S2, S3}
    return MOIBC.bridge_constraint(
        IfThenElse2ReificationBridge{T},
        model,
        MOI.VectorAffineFunction{T}(f),
        s,
    )
end

function MOIBC.bridge_constraint(
    ::Type{IfThenElse2ReificationBridge{T}},
    model,
    f::MOI.VectorAffineFunction{T},
    s::CP.IfThenElse{S1, S2, S3},
) where {T, S1, S2, S3}
    var_condition, var_condition_bin = MOI.add_constrained_variable(model, MOI.ZeroOne())
    var_true, var_true_bin = MOI.add_constrained_variable(model, MOI.ZeroOne())
    var_false, var_false_bin = MOI.add_constrained_variable(model, MOI.ZeroOne())

    f_scalars = MOIU.scalarize(f)
    idx_beg = 1
    idx_end = MOI.dimension(s.condition)
    con_reif_condition = MOI.add_constraint(
        model,
        MOIU.vectorize(
            [
                one(T) * MOI.SingleVariable(var_condition),
                f_scalars[idx_beg : idx_end]...,
            ]
        ),
        CP.Reification(s.condition)
    )

    idx_beg = idx_end + 1
    idx_end = idx_end + MOI.dimension(s.true_constraint)
    con_reif_true = MOI.add_constraint(
        model,
        MOIU.vectorize(
            [
                one(T) * MOI.SingleVariable(var_true),
                f_scalars[idx_beg : idx_end]...,
            ]
        ),
        CP.Reification(s.true_constraint)
    )

    idx_beg = idx_end + 1
    idx_end = idx_end + MOI.dimension(s.false_constraint)
    con_reif_false = MOI.add_constraint(
        model,
        MOIU.vectorize(
            [
                one(T) * MOI.SingleVariable(var_false),
                f_scalars[idx_beg : idx_end]...,
            ]
        ),
        CP.Reification(s.false_constraint)
    )

    # (x ⟹ y) ∧ (¬x ⟹ z) is equivalent to (¬x ∨ y) ∧ (x ∨ z): 
    #     [(1 - var_condition) + var_true] × [var_condition + var_false] ≥ 1
    #     [(1 - var_condition) + var_true ≥ 1] ∧ [var_condition + var_false ≥ 1]
    #     [var_true - var_condition ≥ 0] ∧ [var_condition + var_false ≥ 1]
    #     \____________ if ____________/   \____________ else ___________/
    con_if = MOI.add_constraint(
        model, 
        one(T) * MOI.SingleVariable(var_true) - one(T) * MOI.SingleVariable(var_condition),
        MOI.GreaterThan(zero(T))
    )
    con_else = MOI.add_constraint(
        model, 
        one(T) * MOI.SingleVariable(var_false) + one(T) * MOI.SingleVariable(var_condition),
        MOI.GreaterThan(one(T))
    )

    return IfThenElse2ReificationBridge(var_condition, var_true, var_false, var_condition_bin, var_true_bin, var_false_bin, con_reif_condition, con_reif_true, con_reif_false, con_if, con_else)
end

function MOI.supports_constraint(
    ::Type{IfThenElse2ReificationBridge{T}},
    ::Union{Type{MOI.VectorOfVariables}, Type{MOI.VectorAffineFunction{T}}},
    ::Type{CP.IfThenElse{S1, S2, S3}},
) where {T, S1, S2, S3}
    return true
    # Ideally, ensure that the underlying solver supports all the needed 
    # reified constraints.
end

function MOIB.added_constrained_variable_types(::Type{IfThenElse2ReificationBridge{T}}) where {T}
    return [(MOI.ZeroOne,)]
end

function MOIB.added_constraint_types(::Type{IfThenElse2ReificationBridge{T}}) where {T}
    return [
        (MOI.SingleVariable, MOI.ZeroOne),
        (MOI.VectorAffineFunction{T}, CP.Reification), # TODO: how to be more precise?
        (MOI.ScalarAffineFunction{T}, MOI.GreaterThan{T}),
    ]
end

function MOI.get(::IfThenElse2ReificationBridge{T}, ::MOI.NumberOfVariables) where {T}
    return 3
end

function MOI.get(
    ::IfThenElse2ReificationBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.SingleVariable, MOI.ZeroOne,
    },
) where {T}
    return 3
end

function MOI.get(
    ::IfThenElse2ReificationBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.VectorAffineFunction{T}, CP.Reification,
    },
) where {T}
    return 3
end

function MOI.get(
    ::IfThenElse2ReificationBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.ScalarAffineFunction{T}, MOI.GreaterThan{T},
    },
) where {T}
    return 2
end

function MOI.get(
    b::IfThenElse2ReificationBridge{T},
    ::MOI.ListOfVariableIndices,
) where {T}
    return [b.var_condition, b.var_true, b.var_false]
end

function MOI.get(
    b::IfThenElse2ReificationBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.SingleVariable, MOI.ZeroOne,
    },
) where {T}
    return [b.var_condition_bin, b.var_true_bin, b.var_false_bin]
end

function MOI.get(
    b::IfThenElse2ReificationBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.VectorAffineFunction{T}, CP.Reification,
    },
) where {T}
    return [b.con_reif_condition, b.con_reif_true, b.con_reif_false]
end

function MOI.get(
    b::IfThenElse2ReificationBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.ScalarAffineFunction{T}, MOI.GreaterThan{T},
    },
) where {T}
    return [b.con_if, b.con_else]
end
