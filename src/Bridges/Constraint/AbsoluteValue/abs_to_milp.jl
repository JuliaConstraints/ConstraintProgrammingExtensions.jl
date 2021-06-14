"""
Bridges `CP.AbsoluteValue` to linear constraints and integer constraints.

The implemented model is the most generic one, so that the absolute value 
always has a well-defined value. This requires the use of a binary variable.
In many cases, this is not necessary, and simpler models could be used, but 
checking this automatically would require access to the whole model.

Based on Mosek's 
[modelling cookbook](https://docs.mosek.com/modeling-cookbook/mio.html#exact-absolute-value).
"""
struct AbsoluteValue2MILPBridge{T} <: MOIBC.AbstractBridge
    var_bin::MOI.VariableIndex
    var_bin_con::MOI.ConstraintIndex{MOI.SingleVariable, MOI.ZeroOne}
    var_pos::MOI.VariableIndex
    var_pos_con::MOI.ConstraintIndex{MOI.SingleVariable, MOI.GreaterThan{T}}
    var_neg::MOI.VariableIndex
    var_neg_con::MOI.ConstraintIndex{MOI.SingleVariable, MOI.GreaterThan{T}}

    con_original_var::MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}}
    con_abs_var::MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}}
    con_pos_var_big_m::MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.LessThan{T}}
    con_neg_var_big_m::MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.LessThan{T}}
end

function MOIBC.bridge_constraint(
    ::Type{AbsoluteValue2MILPBridge{T}},
    model,
    f::MOI.VectorOfVariables,
    s::CP.AbsoluteValue,
) where {T}
    return MOIBC.bridge_constraint(
        AbsoluteValue2MILPBridge{T},
        model,
        MOI.VectorAffineFunction{T}(f),
        s,
    )
end

function MOIBC.bridge_constraint(
    ::Type{AbsoluteValue2MILPBridge{T}},
    model,
    f::MOI.VectorAffineFunction{T},
    s::CP.AbsoluteValue,
) where {T}
    f_scalars = MOIU.scalarize(f)

    # For this formulation work, both lower and upper bounds are required on
    # the argument of the absolute value.
    @assert CP.has_lower_bound(model, f_scalars[2])
    @assert CP.has_upper_bound(model, f_scalars[2])

    # Create the variables.
    var_bin, var_bin_con = MOI.add_constrained_variable(model, MOI.ZeroOne())
    var_pos, var_pos_con = MOI.add_constrained_variable(model, MOI.GreaterThan(zero(T)))
    var_neg, var_neg_con = MOI.add_constrained_variable(model, MOI.GreaterThan(zero(T)))

    # Relate the positive and negative parts to the set variables.
    con_original_var = MOI.add_constraint(
        model, 
        f_scalars[2] - MOI.SingleVariable(var_pos) + MOI.SingleVariable(var_neg),
        MOI.EqualTo(zero(T))
    )
    con_abs_var = MOI.add_constraint(
        model, 
        f_scalars[1] - MOI.SingleVariable(var_pos) - MOI.SingleVariable(var_neg),
        MOI.EqualTo(zero(T))
    )

    # Compute a bound on M.
    M = max(
        abs(CP.get_lower_bound(model, f_scalars[2])),
        abs(CP.get_upper_bound(model, f_scalars[2])),
    )

    # Big-M constraints.
    con_pos_var_big_m = MOI.add_constraint(
        model, 
        MOI.SingleVariable(var_pos) - M * MOI.SingleVariable(var_bin), 
        MOI.LessThan(zero(T))
    )
    con_neg_var_big_m = MOI.add_constraint(
        model, 
        MOI.SingleVariable(var_neg) - M * (1 - MOI.SingleVariable(var_bin)), 
        MOI.LessThan(zero(T))
    )    

    return AbsoluteValue2MILPBridge(
        var_bin, var_bin_con, var_pos, var_pos_con, var_neg, var_neg_con, 
        con_original_var, con_abs_var, con_pos_var_big_m, con_neg_var_big_m,
    )
end

function MOI.supports_constraint(
    ::Type{AbsoluteValue2MILPBridge{T}},
    ::Union{Type{MOI.VectorOfVariables}, Type{MOI.VectorAffineFunction{T}}},
    ::Type{CP.AbsoluteValue},
) where {T}
    return true
end

function MOIB.added_constrained_variable_types(::Type{AbsoluteValue2MILPBridge{T}}) where {T}
    return [(MOI.ZeroOne), (MOI.GreaterThan{T})]
end

function MOIB.added_constraint_types(::Type{AbsoluteValue2MILPBridge{T}}) where {T}
    return [
        (MOI.SingleVariable, MOI.ZeroOne),
        (MOI.SingleVariable, MOI.GreaterThan{T}),
        (MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}),
        (MOI.ScalarAffineFunction{T}, MOI.LessThan{T}),
    ]
end

function MOIBC.concrete_bridge_type(
    ::Type{AbsoluteValue2MILPBridge{T}},
    ::Union{Type{MOI.VectorOfVariables}, Type{MOI.VectorAffineFunction{T}}},
    ::Type{CP.AbsoluteValue},
) where {T}
    return AbsoluteValue2MILPBridge{T}
end

function MOI.get(::AbsoluteValue2MILPBridge, ::MOI.NumberOfVariables)
    return 3
end

function MOI.get(
    ::AbsoluteValue2MILPBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.SingleVariable, MOI.ZeroOne,
    },
) where {T}
    return 1
end

function MOI.get(
    ::AbsoluteValue2MILPBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.SingleVariable, MOI.GreaterThan{T},
    },
) where {T}
    return 2
end

function MOI.get(
    ::AbsoluteValue2MILPBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.ScalarAffineFunction{T}, MOI.EqualTo{T},
    },
) where {T}
    return 2
end

function MOI.get(
    ::AbsoluteValue2MILPBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.ScalarAffineFunction{T}, MOI.LessThan{T},
    },
) where {T}
    return 2
end

function MOI.get(
    b::AbsoluteValue2MILPBridge{T},
    ::MOI.ListOfVariableIndices,
) where {T}
    return [b.var_bin, b.var_pos, b.var_neg]
end

function MOI.get(
    b::AbsoluteValue2MILPBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.SingleVariable, MOI.ZeroOne,
    },
) where {T}
    return [b.var_bin_con]
end

function MOI.get(
    b::AbsoluteValue2MILPBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.SingleVariable, MOI.GreaterThan{T},
    },
) where {T}
    return [b.var_pos_con, b.var_neg_con]
end

function MOI.get(
    b::AbsoluteValue2MILPBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.ScalarAffineFunction{T}, MOI.EqualTo{T},
    },
) where {T}
    return [b.con_original_var, b.con_abs_var]
end

function MOI.get(
    b::AbsoluteValue2MILPBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.ScalarAffineFunction{T}, MOI.LessThan{T},
    },
) where {T}
    return [b.con_pos_var_big_m, b.con_neg_var_big_m]
end
