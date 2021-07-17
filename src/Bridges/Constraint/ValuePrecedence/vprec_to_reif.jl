"""
Bridges `CP.ValuePrecedence` to reification.
"""
struct ValuePrecedence2ReificationBridge{T} <: MOIBC.AbstractBridge
    vars_reif_value::Vector{MOI.VariableIndex}
    vars_reif_precv::Vector{MOI.VariableIndex}
    vars_reif_value_bin::Vector{MOI.ConstraintIndex{MOI.SingleVariable, MOI.ZeroOne}}
    vars_reif_precv_bin::Vector{MOI.ConstraintIndex{MOI.SingleVariable, MOI.ZeroOne}}
    cons_reif_value::Vector{MOI.ConstraintIndex{MOI.VectorAffineFunction{T}, CP.Reified{MOI.EqualTo{T}}}} # Compare values from 2 to end.
    cons_reif_precv::Vector{MOI.ConstraintIndex{MOI.VectorAffineFunction{T}, CP.Reified{MOI.EqualTo{T}}}} # Compare values from 1 to end-1.
    cons_imply::Vector{MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.LessThan{T}}}
end

function MOIBC.bridge_constraint(
    ::Type{ValuePrecedence2ReificationBridge{T}},
    model,
    f::MOI.VectorOfVariables,
    s::CP.ValuePrecedence{T},
) where {T}
    return MOIBC.bridge_constraint(
        ValuePrecedence2ReificationBridge{T},
        model,
        MOI.VectorAffineFunction{T}(f),
        s,
    )
end

function MOIBC.bridge_constraint(
    ::Type{ValuePrecedence2ReificationBridge{T}},
    model,
    f::MOI.VectorAffineFunction{T},
    s::CP.ValuePrecedence{T},
) where {T}
    f_scalars = MOIU.scalarize(f)

    vars_reif_value, vars_reif_value_bin = MOI.add_constrained_variables(model, [MOI.ZeroOne() for _ in 1:(s.dimension - 1)])
    vars_reif_precv, vars_reif_precv_bin = MOI.add_constrained_variables(model, [MOI.ZeroOne() for _ in 1:(s.dimension - 1)])

    cons_reif_value = MOI.ConstraintIndex{MOI.VectorAffineFunction{T}, CP.Reified{MOI.EqualTo{T}}}[
        MOI.add_constraint(
            model, 
            MOIU.vectorize(
                MOI.ScalarAffineFunction{T}[
                    one(T) * MOI.SingleVariable(vars_reif_value[i - 1]),
                    f_scalars[i] - T(s.value),
                ]
            ),
            CP.Reified(MOI.EqualTo(zero(T)))
        )
        for i in 2:s.dimension
    ]

    cons_reif_precv = MOI.ConstraintIndex{MOI.VectorAffineFunction{T}, CP.Reified{MOI.EqualTo{T}}}[
        MOI.add_constraint(
            model, 
            MOIU.vectorize(
                MOI.ScalarAffineFunction{T}[
                    one(T) * MOI.SingleVariable(vars_reif_precv[i]),
                    f_scalars[i] - T(s.before)
                ]
            ),
            CP.Reified(MOI.EqualTo(zero(T)))
        )
        for i in 1:(s.dimension - 1)
    ]

    # If there is one `value`, then there must be at least one `before` before.
    cons_imply = MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.LessThan{T}}[
        MOI.add_constraint(
            model,
            MOI.SingleVariable(vars_reif_value[i - 1]) - sum(one(T) .* MOI.SingleVariable.(vars_reif_precv[1:(i - 1)])),
            MOI.LessThan(zero(T))
        )
        for i in 2:s.dimension
    ]

    return ValuePrecedence2ReificationBridge(vars_reif_value, vars_reif_precv, vars_reif_value_bin, vars_reif_precv_bin, cons_reif_value, cons_reif_precv, cons_imply)
end

function MOI.supports_constraint(
    ::Type{ValuePrecedence2ReificationBridge{T}},
    ::Union{Type{MOI.VectorOfVariables}, Type{MOI.VectorAffineFunction{T}}},
    ::Type{CP.ValuePrecedence{T}},
) where {T}
    return true
end

function MOIB.added_constrained_variable_types(::Type{ValuePrecedence2ReificationBridge{T}}) where {T}
    return [(MOI.ZeroOne,)]
end

function MOIB.added_constraint_types(::Type{ValuePrecedence2ReificationBridge{T}}) where {T}
    return [
        (MOI.SingleVariable, MOI.ZeroOne),
        (MOI.VectorAffineFunction{T}, CP.Reified{MOI.EqualTo{T}}),
        (MOI.ScalarAffineFunction{T}, MOI.LessThan{T}),
    ]
end

function MOIBC.concrete_bridge_type(
    ::Type{ValuePrecedence2ReificationBridge{T}},
    ::Union{Type{MOI.VectorOfVariables}, Type{MOI.VectorAffineFunction{T}}},
    ::Type{CP.ValuePrecedence{T}},
) where {T}
    return ValuePrecedence2ReificationBridge{T}
end

function MOI.get(b::ValuePrecedence2ReificationBridge, ::MOI.NumberOfVariables)
    return length(b.vars_reif_precv) + length(b.vars_reif_value)
end

function MOI.get(
    b::ValuePrecedence2ReificationBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.SingleVariable, MOI.ZeroOne,
    },
) where {T}
    return length(b.vars_reif_precv_bin) + length(b.vars_reif_value_bin)
end

function MOI.get(
    b::ValuePrecedence2ReificationBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.VectorAffineFunction{T}, CP.Reified{MOI.EqualTo{T}},
    },
) where {T}
    return length(b.cons_reif_value) + length(b.cons_reif_precv)
end

function MOI.get(
    b::ValuePrecedence2ReificationBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.ScalarAffineFunction{T}, MOI.LessThan{T}
    },
) where {T}
    return length(b.cons_imply)
end

function MOI.get(
    b::ValuePrecedence2ReificationBridge{T},
    ::MOI.ListOfVariableIndices,
) where {T}
    return vcat(b.vars_reif_precv, b.vars_reif_value)
end

function MOI.get(
    b::ValuePrecedence2ReificationBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.SingleVariable, MOI.ZeroOne,
    },
) where {T}
    return vcat(b.vars_reif_precv_bin, b.vars_reif_value_bin)
end

function MOI.get(
    b::ValuePrecedence2ReificationBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.VectorAffineFunction{T}, CP.Reified{MOI.EqualTo{T}},
    },
) where {T}
    return vcat(b.cons_reif_value, b.cons_reif_precv)
end

function MOI.get(
    b::ValuePrecedence2ReificationBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.ScalarAffineFunction{T}, MOI.LessThan{T}
    },
) where {T}
    return b.cons_imply
end
