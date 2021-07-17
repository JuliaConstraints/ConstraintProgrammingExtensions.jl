"""
Bridges `CP.Element` to MILP constraints by using a unary encoding of the 
index in the array.
"""
struct Element2MILPBridge{T} <: MOIBC.AbstractBridge
    vars::Vector{MOI.VariableIndex}
    vars_bin::Vector{MOI.ConstraintIndex{MOI.SingleVariable, MOI.ZeroOne}}
    con_unary::MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}}
    con_choose_one::MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}}
    con_value::MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}}
end

function MOIBC.bridge_constraint(
    ::Type{Element2MILPBridge{T}},
    model,
    f::MOI.VectorOfVariables,
    s::CP.Element{T},
) where {T}
    return MOIBC.bridge_constraint(
        Element2MILPBridge{T},
        model,
        MOI.VectorAffineFunction{T}(f),
        s,
    )
end

function MOIBC.bridge_constraint(
    ::Type{Element2MILPBridge{T}},
    model,
    f::MOI.VectorAffineFunction{T},
    s::CP.Element{T},
) where {T}
    vars, vars_bin = MOI.add_constrained_variables(model, [MOI.ZeroOne() for _ in 1:length(s.values)])

    f_scalars = MOIU.scalarize(f)
    f_value = f_scalars[1]
    f_index = f_scalars[2]

    con_unary = MOI.add_constraint(
        model, 
        sum(T(i) * MOI.SingleVariable(vars[i]) for i in 1:length(s.values)) - f_index,
        MOI.EqualTo(zero(T))
    )

    con_choose_one = MOI.add_constraint(
        model, 
        sum(one(T) .* MOI.SingleVariable.(vars)),
        MOI.EqualTo(one(T))
    )

    con_value = MOI.add_constraint(
        model, 
        sum(s.values[i] * MOI.SingleVariable(vars[i]) for i in 1:length(s.values)) - f_value,
        MOI.EqualTo(zero(T))
    )

    return Element2MILPBridge(vars, vars_bin, con_unary, con_choose_one, con_value)
end

function MOI.supports_constraint(
    ::Type{Element2MILPBridge{T}},
    ::Union{Type{MOI.VectorOfVariables}, Type{MOI.VectorAffineFunction{T}}},
    ::Type{CP.Element{T}},
) where {T}
    return true
end

function MOIB.added_constrained_variable_types(::Type{Element2MILPBridge{T}}) where {T}
    return [(MOI.ZeroOne,)]
end

function MOIB.added_constraint_types(::Type{Element2MILPBridge{T}}) where {T}
    return [
        (MOI.SingleVariable, MOI.ZeroOne),
        (MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}),
    ]
end

function MOIBC.concrete_bridge_type(
    ::Type{Element2MILPBridge{T}},
    ::Union{Type{MOI.VectorOfVariables}, Type{MOI.VectorAffineFunction{T}}},
    ::Type{CP.Element{T}},
) where {T}
    return Element2MILPBridge{T}
end

function MOI.get(b::Element2MILPBridge{T}, ::MOI.NumberOfVariables) where {T}
    return length(b.vars)
end

function MOI.get(
    b::Element2MILPBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.SingleVariable, MOI.ZeroOne,
    },
) where {T}
    return length(b.vars_bin)
end

function MOI.get(
    ::Element2MILPBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.ScalarAffineFunction{T}, MOI.EqualTo{T},
    },
) where {T}
    return 3
end

function MOI.get(
    b::Element2MILPBridge{T},
    ::MOI.ListOfVariableIndices,
) where {T}
    return copy(b.vars)
end

function MOI.get(
    b::Element2MILPBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.SingleVariable, MOI.ZeroOne,
    },
) where {T}
    return copy(b.vars_bin)
end

function MOI.get(
    b::Element2MILPBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.ScalarAffineFunction{T}, MOI.EqualTo{T},
    },
) where {T}
    return [b.con_unary, b.con_choose_one, b.con_value]
end
