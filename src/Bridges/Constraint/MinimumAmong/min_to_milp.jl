"""
Bridges `CP.MinimumAmong` to MILP formulations, by the means of big-M 
constraints.
"""
struct MinimumAmong2MILPBridge{T} <: MOIBC.AbstractBridge
    vars::Vector{MOI.VariableIndex}
    vars_bin::Vector{MOI.ConstraintIndex{MOI.SingleVariable, MOI.ZeroOne}}
    cons_lt::Vector{MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.LessThan{T}}}
    cons_gt::Vector{MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.GreaterThan{T}}}
    con_choose_one::MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}}
end

function MOIBC.bridge_constraint(
    ::Type{MinimumAmong2MILPBridge{T}},
    model,
    f::MOI.VectorOfVariables,
    s::CP.MinimumAmong,
) where {T}
    return MOIBC.bridge_constraint(
        MinimumAmong2MILPBridge{T},
        model,
        MOI.VectorAffineFunction{T}(f),
        s,
    )
end

function MOIBC.bridge_constraint(
    ::Type{MinimumAmong2MILPBridge{T}},
    model,
    f::MOI.VectorAffineFunction{T},
    s::CP.MinimumAmong,
) where {T}
    f_scalars = MOIU.scalarize(f)
    dim = MOI.output_dimension(f)
    n_array = dim - 1

    # For this formulation work, both lower and upper bounds are required on
    # the argument of the absolute value.
    for i in 1:n_array
        @assert CP.has_lower_bound(model, f_scalars[i + 1])
        @assert CP.has_upper_bound(model, f_scalars[i + 1])
    end

    # New variables.
    vars, vars_bin = MOI.add_constrained_variables(model, [MOI.ZeroOne() for _ in 1:n_array])

    # The minimum is at most every other value.
    cons_lt = MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.LessThan{T}}[
        MOI.add_constraint(
            model, 
            f_scalars[1] - f_scalars[i + 1], 
            MOI.LessThan(zero(T))
        )
        for i in 1:n_array
    ]

    # The minimum is greater than only one value (i.e. equal to that one).
    big_m = T[
        abs(
            CP.get_upper_bound(model, f_scalars[i + 1]) -
            CP.get_lower_bound(model, f_scalars[i + 1])
        )
        for i in 1:n_array
    ]
    cons_gt = MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.GreaterThan{T}}[
        MOI.add_constraint(
            model, 
            f_scalars[1] - f_scalars[i + 1] - big_m[i] * (one(T) - MOI.SingleVariable(vars[i])), 
            MOI.GreaterThan(zero(T))
        )
        for i in 1:n_array
    ]

    # At most one such inequality holds.
    con_choose_one = MOI.add_constraint(
        model, 
        sum(one(T) * MOI.SingleVariable.(vars)), 
        MOI.EqualTo(one(T))
    )

    return MinimumAmong2MILPBridge(vars, vars_bin, cons_lt, cons_gt, con_choose_one)
end

function MOI.supports_constraint(
    ::Type{MinimumAmong2MILPBridge{T}},
    ::Union{Type{MOI.VectorOfVariables}, Type{MOI.VectorAffineFunction{T}}},
    ::Type{CP.MinimumAmong},
) where {T}
    return true
end

function MOIB.added_constrained_variable_types(::Type{MinimumAmong2MILPBridge{T}}) where {T}
    return [(MOI.ZeroOne,)]
end

function MOIB.added_constraint_types(::Type{MinimumAmong2MILPBridge{T}}) where {T}
    return [
        (MOI.ScalarAffineFunction{T}, MOI.LessThan{T}),
        (MOI.ScalarAffineFunction{T}, MOI.GreaterThan{T}),
        (MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}),
    ]
end

function MOIBC.concrete_bridge_type(
    ::Type{MinimumAmong2MILPBridge{T}},
    ::Union{Type{MOI.VectorOfVariables}, Type{MOI.VectorAffineFunction{T}}},
    ::Type{CP.MinimumAmong},
) where {T}
    return MinimumAmong2MILPBridge{T}
end

function MOI.get(b::MinimumAmong2MILPBridge, ::MOI.NumberOfVariables)
    return length(b.vars)
end

function MOI.get(
    b::MinimumAmong2MILPBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.SingleVariable, MOI.ZeroOne,
    },
) where {T}
    return length(b.vars_bin)
end

function MOI.get(
    ::MinimumAmong2MILPBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.ScalarAffineFunction{T}, MOI.EqualTo{T},
    },
) where {T}
    return 1
end

function MOI.get(
    b::MinimumAmong2MILPBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.ScalarAffineFunction{T}, MOI.LessThan{T},
    },
) where {T}
    return length(b.cons_lt)
end

function MOI.get(
    b::MinimumAmong2MILPBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.ScalarAffineFunction{T}, MOI.GreaterThan{T},
    },
) where {T}
    return length(b.cons_gt)
end

function MOI.get(
    b::MinimumAmong2MILPBridge{T},
    ::MOI.ListOfVariableIndices,
) where {T}
    return b.vars
end

function MOI.get(
    b::MinimumAmong2MILPBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.SingleVariable, MOI.ZeroOne,
    },
) where {T}
    return b.vars_bin
end

function MOI.get(
    b::MinimumAmong2MILPBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.ScalarAffineFunction{T}, MOI.EqualTo{T},
    },
) where {T}
    return [b.con_choose_one]
end

function MOI.get(
    b::MinimumAmong2MILPBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.ScalarAffineFunction{T}, MOI.LessThan{T},
    },
) where {T}
    return b.cons_lt
end

function MOI.get(
    b::MinimumAmong2MILPBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.ScalarAffineFunction{T}, MOI.GreaterThan{T},
    },
) where {T}
    return b.cons_gt
end
