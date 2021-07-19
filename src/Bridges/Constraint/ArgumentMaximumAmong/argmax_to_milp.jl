"""
Bridges `CP.ArgumentMaximumAmong` to MILP formulations, by the means of big-M 
constraints.
"""
struct ArgumentMaximumAmong2MILPBridge{T} <: MOIBC.AbstractBridge
    vars::Vector{MOI.VariableIndex}
    vars_bin::Vector{MOI.ConstraintIndex{MOI.SingleVariable, MOI.ZeroOne}}
    var_max::MOI.VariableIndex
    var_max_con::Union{
        MOI.ConstraintIndex{MOI.SingleVariable, MOI.ZeroOne}, 
        MOI.ConstraintIndex{MOI.SingleVariable, MOI.Integer},
        Nothing
    }
    cons_lt::Vector{MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.LessThan{T}}}
    cons_gt::Vector{MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.GreaterThan{T}}}
    con_choose_one::MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}}
    con_index::MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}}
end

function MOIBC.bridge_constraint(
    ::Type{ArgumentMaximumAmong2MILPBridge{T}},
    model,
    f::MOI.VectorOfVariables,
    s::CP.ArgumentMaximumAmong,
) where {T}
    return MOIBC.bridge_constraint(
        ArgumentMaximumAmong2MILPBridge{T},
        model,
        MOI.VectorAffineFunction{T}(f),
        s,
    )
end

function MOIBC.bridge_constraint(
    ::Type{ArgumentMaximumAmong2MILPBridge{T}},
    model,
    f::MOI.VectorAffineFunction{T},
    s::CP.ArgumentMaximumAmong,
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

    #= if T <: Bool
        var_max, var_max_con = MOI.add_constrained_variable(model, MOI.ZeroOne())
    else =#if T <: Integer
        var_max, var_max_con = MOI.add_constrained_variable(model, MOI.Integer())
    elseif T <: Real
        var_max = MOI.add_variable(model)
        var_max_con = nothing
    end

    # The maximum is at least every other value.
    cons_gt = MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.GreaterThan{T}}[
        MOI.add_constraint(
            model, 
            MOI.SingleVariable(var_max) - f_scalars[i + 1], 
            MOI.GreaterThan(zero(T))
        )
        for i in 1:n_array
    ]

    # The maximum is less than only one value (i.e. equal to that one).
    big_m = T[
        abs(
            CP.get_upper_bound(model, f_scalars[i + 1]) -
            CP.get_lower_bound(model, f_scalars[i + 1])
        )
        for i in 1:n_array
    ]
    cons_lt = MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.LessThan{T}}[
        MOI.add_constraint(
            model, 
            MOI.SingleVariable(var_max) - f_scalars[i + 1] - big_m[i] * (one(T) - MOI.SingleVariable(vars[i])), 
            MOI.LessThan(zero(T))
        )
        for i in 1:n_array
    ]

    # At most one such inequality holds.
    con_choose_one = MOI.add_constraint(
        model, 
        sum(one(T) * MOI.SingleVariable.(vars)), 
        MOI.EqualTo(one(T))
    )

    # Relate the index to the chosen value.
    con_index = MOI.add_constraint(
        model, 
        f_scalars[1] - sum(T.(collect(1:n_array)) .* MOI.SingleVariable.(vars)), 
        MOI.EqualTo(zero(T))
    )

    return ArgumentMaximumAmong2MILPBridge(vars, vars_bin, var_max, var_max_con, cons_lt, cons_gt, con_choose_one, con_index)
end

function MOI.supports_constraint(
    ::Type{ArgumentMaximumAmong2MILPBridge{T}},
    ::Union{Type{MOI.VectorOfVariables}, Type{MOI.VectorAffineFunction{T}}},
    ::Type{CP.ArgumentMaximumAmong},
) where {T}
    return true
end

function MOIB.added_constrained_variable_types(::Type{ArgumentMaximumAmong2MILPBridge{T}}) where {T} # Bool and Real
    return [(MOI.ZeroOne,)]
end

function MOIB.added_constrained_variable_types(::Type{ArgumentMaximumAmong2MILPBridge{T}}) where {T <: Integer}
    return [(MOI.ZeroOne,), (MOI.Integer,)]
end

function MOIB.added_constraint_types(::Type{ArgumentMaximumAmong2MILPBridge{T}}) where {T} # Bool and Real
    return [
        (MOI.SingleVariable, MOI.ZeroOne),
        (MOI.ScalarAffineFunction{T}, MOI.LessThan{T}),
        (MOI.ScalarAffineFunction{T}, MOI.GreaterThan{T}),
        (MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}),
    ]
end

function MOIB.added_constraint_types(::Type{ArgumentMaximumAmong2MILPBridge{T}}) where {T <: Integer}
    return [
        (MOI.SingleVariable, MOI.ZeroOne),
        (MOI.SingleVariable, MOI.Integer),
        (MOI.ScalarAffineFunction{T}, MOI.LessThan{T}),
        (MOI.ScalarAffineFunction{T}, MOI.GreaterThan{T}),
        (MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}),
    ]
end

function MOI.get(b::ArgumentMaximumAmong2MILPBridge, ::MOI.NumberOfVariables)
    return length(b.vars)
end

function MOI.get(
    b::ArgumentMaximumAmong2MILPBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.SingleVariable, MOI.ZeroOne,
    },
) where {T}
    return length(b.vars_bin)
end

function MOI.get(
    ::ArgumentMaximumAmong2MILPBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.ScalarAffineFunction{T}, MOI.EqualTo{T},
    },
) where {T}
    return 1
end

function MOI.get(
    b::ArgumentMaximumAmong2MILPBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.ScalarAffineFunction{T}, MOI.LessThan{T},
    },
) where {T}
    return length(b.cons_lt)
end

function MOI.get(
    b::ArgumentMaximumAmong2MILPBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.ScalarAffineFunction{T}, MOI.GreaterThan{T},
    },
) where {T}
    return length(b.cons_gt)
end

function MOI.get(
    b::ArgumentMaximumAmong2MILPBridge{T},
    ::MOI.ListOfVariableIndices,
) where {T}
    return copy(b.vars)
end

function MOI.get(
    b::ArgumentMaximumAmong2MILPBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.SingleVariable, MOI.ZeroOne,
    },
) where {T}
    return copy(b.vars_bin)
end

function MOI.get(
    b::ArgumentMaximumAmong2MILPBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.ScalarAffineFunction{T}, MOI.EqualTo{T},
    },
) where {T}
    return [b.con_choose_one]
end

function MOI.get(
    b::ArgumentMaximumAmong2MILPBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.ScalarAffineFunction{T}, MOI.LessThan{T},
    },
) where {T}
    return copy(b.cons_lt)
end

function MOI.get(
    b::ArgumentMaximumAmong2MILPBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.ScalarAffineFunction{T}, MOI.GreaterThan{T},
    },
) where {T}
    return copy(b.cons_gt)
end
