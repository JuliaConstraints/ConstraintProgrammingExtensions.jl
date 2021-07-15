"""
Bridges `CP.VectorDomain` to MILP by adding one binary variable per 
possible combination.
"""
struct VectorDomain2MILPBridge{T} <: MOIBC.AbstractBridge
    vars::Vector{MOI.VariableIndex}
    vars_bin::Vector{MOI.ConstraintIndex{MOI.SingleVariable, MOI.ZeroOne}}
    con_choose_one::MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}}
    cons_values::Vector{MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}}}
end

function MOIBC.bridge_constraint(
    ::Type{VectorDomain2MILPBridge{T}},
    model,
    f::MOI.VectorOfVariables,
    s::CP.VectorDomain{T},
) where {T}
    return MOIBC.bridge_constraint(
        VectorDomain2MILPBridge{T},
        model,
        MOI.VectorAffineFunction{T}(f),
        s,
    )
end

function MOIBC.bridge_constraint(
    ::Type{VectorDomain2MILPBridge{T}},
    model,
    f::MOI.VectorAffineFunction{T},
    s::CP.VectorDomain{T},
) where {T}
    vars, vars_bin = MOI.add_constrained_variables(model, [MOI.ZeroOne() for _ in 1:length(s.values)])

    con_choose_one = MOI.add_constraint(
        model,
        sum(one(T) .* MOI.SingleVariable.(vars)),
        MOI.EqualTo(one(T))
    )
    
    f_scalars = MOIU.scalarize(f)
    values = collect(s.values)

    cons_values = MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}}[
        MOI.add_constraint(
            model,
            f_scalars[i] - sum(one(T) * MOI.SingleVariable(vars[j]) * values[j][i] for j in 1:length(s.values)),
            MOI.EqualTo(zero(T))
        )
        for i in 1:s.dimension
    ]

    return VectorDomain2MILPBridge(vars, vars_bin, con_choose_one, cons_values)
end

function MOI.supports_constraint(
    ::Type{VectorDomain2MILPBridge{T}},
    ::Union{Type{MOI.VectorOfVariables}, Type{MOI.VectorAffineFunction{T}}},
    ::Type{CP.VectorDomain{T}},
) where {T}
    return true
end

function MOIB.added_constrained_variable_types(::Type{VectorDomain2MILPBridge{T}}) where {T}
    return [(MOI.ZeroOne,)]
end

function MOIB.added_constraint_types(::Type{VectorDomain2MILPBridge{T}}) where {T}
    return [
        (MOI.SingleVariable, MOI.ZeroOne),
        (MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}),
    ]
end

function MOIBC.concrete_bridge_type(
    ::Type{VectorDomain2MILPBridge{T}},
    ::Union{Type{MOI.VectorOfVariables}, Type{MOI.VectorAffineFunction{T}}},
    ::Type{CP.VectorDomain{T}},
) where {T}
    return VectorDomain2MILPBridge{T}
end

function MOI.get(b::VectorDomain2MILPBridge, ::MOI.NumberOfVariables)
    return length(b.vars)
end

function MOI.get(
    b::VectorDomain2MILPBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.SingleVariable, MOI.ZeroOne,
    },
) where {T}
    return length(b.vars_bin)
end

function MOI.get(
    b::VectorDomain2MILPBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.ScalarAffineFunction{T}, MOI.EqualTo{T},
    },
) where {T}
    return 1 + length(b.cons_values)
end

function MOI.get(
    b::VectorDomain2MILPBridge{T},
    ::MOI.ListOfVariableIndices,
) where {T}
    return b.vars
end

function MOI.get(
    b::VectorDomain2MILPBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.SingleVariable, MOI.ZeroOne,
    },
) where {T}
    return b.vars_bin
end

function MOI.get(
    b::VectorDomain2MILPBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.ScalarAffineFunction{T}, MOI.EqualTo{T},
    },
) where {T}
    return [b.con_choose_one, b.cons_values...]
end
