"""
Bridges `CP.Domain` to MILP by adding one binary variable per possible 
combination.
"""
struct Domain2MILPBridge{T} <: MOIBC.AbstractBridge
    vars::Vector{MOI.VariableIndex}
    vars_bin::Vector{MOI.ConstraintIndex{MOI.SingleVariable, MOI.ZeroOne}}
    con_choose_one::MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}}
    con_value::MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}}
end

function MOIBC.bridge_constraint(
    ::Type{Domain2MILPBridge{T}},
    model,
    f::MOI.SingleVariable,
    s::CP.Domain{T},
) where {T}
    return MOIBC.bridge_constraint(
        Domain2MILPBridge{T},
        model,
        MOI.ScalarAffineFunction{T}(f),
        s,
    )
end

function MOIBC.bridge_constraint(
    ::Type{Domain2MILPBridge{T}},
    model,
    f::MOI.ScalarAffineFunction{T},
    s::CP.Domain{T},
) where {T}
    vars, vars_bin = MOI.add_constrained_variables(model, [MOI.ZeroOne() for _ in 1:length(s.values)])

    con_choose_one = MOI.add_constraint(
        model,
        sum(one(T) .* MOI.SingleVariable.(vars)),
        MOI.EqualTo(one(T))
    )
    
    values = collect(s.values)

    con_value = MOI.add_constraint(
        model,
        f - sum(one(T) * MOI.SingleVariable(vars[i]) * values[i] for i in 1:length(s.values)),
        MOI.EqualTo(zero(T))
    )

    return Domain2MILPBridge(vars, vars_bin, con_choose_one, con_value)
end

function MOI.supports_constraint(
    ::Type{Domain2MILPBridge{T}},
    ::Union{Type{MOI.SingleVariable}, Type{MOI.ScalarAffineFunction{T}}},
    ::Type{CP.Domain{T}},
) where {T}
    return true
end

function MOIB.added_constrained_variable_types(::Type{Domain2MILPBridge{T}}) where {T}
    return [(MOI.ZeroOne,)]
end

function MOIB.added_constraint_types(::Type{Domain2MILPBridge{T}}) where {T}
    return [
        (MOI.SingleVariable, MOI.ZeroOne),
        (MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}),
    ]
end

function MOIBC.concrete_bridge_type(
    ::Type{Domain2MILPBridge{T}},
    ::Union{Type{MOI.SingleVariable}, Type{MOI.ScalarAffineFunction{T}}},
    ::Type{CP.Domain{T}},
) where {T}
    return Domain2MILPBridge{T}
end

function MOI.get(b::Domain2MILPBridge, ::MOI.NumberOfVariables)
    return length(b.vars)
end

function MOI.get(
    b::Domain2MILPBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.SingleVariable, MOI.ZeroOne,
    },
) where {T}
    return length(b.vars_bin)
end

function MOI.get(
    ::Domain2MILPBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.ScalarAffineFunction{T}, MOI.EqualTo{T},
    },
) where {T}
    return 2
end

function MOI.get(
    b::Domain2MILPBridge{T},
    ::MOI.ListOfVariableIndices,
) where {T}
    return b.vars
end

function MOI.get(
    b::Domain2MILPBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.SingleVariable, MOI.ZeroOne,
    },
) where {T}
    return b.vars_bin
end

function MOI.get(
    b::Domain2MILPBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.ScalarAffineFunction{T}, MOI.EqualTo{T},
    },
) where {T}
    return [b.con_choose_one, b.con_value]
end
