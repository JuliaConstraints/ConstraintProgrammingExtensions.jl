"""
Bridges `CP.Domain` to MILP by adding one binary variable per possible 
combination.
"""
struct Domain2MILPBridge{T} <: MOIBC.AbstractBridge
    vars::Vector{MOI.VariableIndex}
    vars_bin::Vector{MOI.ConstraintIndex{MOI.VariableIndex, MOI.ZeroOne}}
    con_choose_one::MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}}
    con_value::MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}}
end

# Each returned function owns its terms. Repeated affine addition copies the
# growing prefix for every domain value; construct the final terms once instead.
function _domain_value_function(f::MOI.ScalarAffineFunction{T}, vars, values) where {T}
    prefix = length(f.terms)
    terms = Vector{MOI.ScalarAffineTerm{T}}(undef, prefix + length(vars))
    copyto!(terms, 1, f.terms, 1, prefix)
    for (j, value) in enumerate(values)
        terms[prefix + j] = MOI.ScalarAffineTerm(-(one(T) * value), vars[j])
    end
    return MOI.ScalarAffineFunction(terms, f.constant)
end

function MOIBC.bridge_constraint(
    ::Type{Domain2MILPBridge{T}},
    model,
    f::MOI.VariableIndex,
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
    vars, vars_bin = MOI.add_constrained_variables(model, fill(MOI.ZeroOne(), length(s.values)))

    con_choose_one = MOI.add_constraint(
        model,
        MOI.ScalarAffineFunction([MOI.ScalarAffineTerm(one(T), v) for v in vars], zero(T)),
        MOI.EqualTo(one(T))
    )
    
    values = collect(s.values)

    con_value = MOI.add_constraint(
        model,
        _domain_value_function(f, vars, values),
        MOI.EqualTo(zero(T))
    )

    return Domain2MILPBridge(vars, vars_bin, con_choose_one, con_value)
end

function MOI.supports_constraint(
    ::Type{Domain2MILPBridge{T}},
    ::Union{Type{MOI.VariableIndex}, Type{MOI.ScalarAffineFunction{T}}},
    ::Type{CP.Domain{T}},
) where {T}
    return true
end

function MOIB.added_constrained_variable_types(::Type{Domain2MILPBridge{T}}) where {T}
    return [(MOI.ZeroOne,)]
end

function MOIB.added_constraint_types(::Type{Domain2MILPBridge{T}}) where {T}
    return [
        (MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}),
    ]
end

function MOI.get(b::Domain2MILPBridge, ::MOI.NumberOfVariables)
    return length(b.vars)
end

function MOI.get(
    b::Domain2MILPBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.VariableIndex, MOI.ZeroOne,
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
    return copy(b.vars)
end

function MOI.get(
    b::Domain2MILPBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.VariableIndex, MOI.ZeroOne,
    },
) where {T}
    return copy(b.vars_bin)
end

function MOI.get(
    b::Domain2MILPBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.ScalarAffineFunction{T}, MOI.EqualTo{T},
    },
) where {T}
    return [b.con_choose_one, b.con_value]
end
