"""
Bridges `CP.MaximumAmong` to MILP formulations, by the means of big-M 
constraints.
"""
struct MaximumAmong2MILPBridge{T} <: MOIBC.AbstractBridge
    vars::Vector{MOI.VariableIndex}
    vars_bin::Vector{MOI.ConstraintIndex{MOI.SingleVariable, MOI.ZeroOne}}
    cons_lt::Vector{MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.LessThan{T}}}
    cons_gt::Vector{MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.GreaterThan{T}}}
    con_choose_one::MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}}
end

function MOIBC.bridge_constraint(
    ::Type{MaximumAmong2MILPBridge{T}},
    model,
    f::MOI.VectorOfVariables,
    s::CP.MaximumAmong,
) where {T}
    return MOIBC.bridge_constraint(
        MaximumAmong2MILPBridge{T},
        model,
        MOI.VectorAffineFunction{T}(f),
        s,
    )
end

function MOIBC.bridge_constraint(
    ::Type{MaximumAmong2MILPBridge{T}},
    model,
    f::MOI.VectorAffineFunction{T},
    s::CP.MaximumAmong,
) where {T}
    f_scalars = MOIU.scalarize(f)
    dim = MOI.output_dimension(f)
    n_array = dim - 1

    # New variables.
    vars, vars_bin = MOI.add_constrained_variables(model, [MOI.ZeroOne() for _ in 1:n_array])

    # The maximum is at least every other value.
    cons_gt = MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.GreaterThan{T}}[
        MOI.add_constraint(
            model, 
            f_scalars[1] - f_scalars[i + 1], 
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
            f_scalars[1] - f_scalars[i + 1] - big_m[i] * (one(T) - MOI.SingleVariable(vars[i])), 
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

    return MaximumAmong2MILPBridge(vars, vars_bin, cons_lt, cons_gt, con_choose_one)
end

function MOI.supports_constraint(
    ::Type{MaximumAmong2MILPBridge{T}},
    ::Union{Type{MOI.VectorOfVariables}, Type{MOI.VectorAffineFunction{T}}},
    ::Type{CP.MaximumAmong},
) where {T}
    return true
end

function MOIB.added_constrained_variable_types(::Type{MaximumAmong2MILPBridge{T}}) where {T}
    return [(MOI.ZeroOne,)]
end

function MOIB.added_constraint_types(::Type{MaximumAmong2MILPBridge{T}}) where {T}
    return [
        (MOI.ScalarAffineFunction{T}, MOI.LessThan{T}),
        (MOI.ScalarAffineFunction{T}, MOI.GreaterThan{T}),
        (MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}),
    ]
end

function MOIBC.concrete_bridge_type(
    ::Type{MaximumAmong2MILPBridge{T}},
    ::Union{Type{MOI.VectorOfVariables}, Type{MOI.VectorAffineFunction{T}}},
    ::Type{CP.MaximumAmong},
) where {T}
    return MaximumAmong2MILPBridge{T}
end

function MOI.get(b::MaximumAmong2MILPBridge, ::MOI.NumberOfVariables)
    return length(b.vars)
end

function MOI.get(
    b::MaximumAmong2MILPBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.SingleVariable, MOI.ZeroOne,
    },
) where {T}
    return length(b.vars_bin)
end

function MOI.get(
    ::MaximumAmong2MILPBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.ScalarAffineFunction{T}, MOI.EqualTo{T},
    },
) where {T}
    return 1
end

function MOI.get(
    b::MaximumAmong2MILPBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.ScalarAffineFunction{T}, MOI.LessThan{T},
    },
) where {T}
    return length(b.cons_lt)
end

function MOI.get(
    b::MaximumAmong2MILPBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.ScalarAffineFunction{T}, MOI.GreaterThan{T},
    },
) where {T}
    return length(b.cons_gt)
end

function MOI.get(
    b::MaximumAmong2MILPBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.ScalarAffineFunction{T}, CP.DifferentFrom{T},
    },
) where {T}
    return collect(values(b.cons))
end
