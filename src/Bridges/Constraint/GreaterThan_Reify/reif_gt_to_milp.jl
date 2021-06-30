_REIF_LT_FLOAT_EPSILON = 1.0e-5

"""
Bridges `CP.Reified{MOI.GreaterThan}` to MILP constraints.
"""
struct ReifiedGreaterThan2MILPBridge{T <: Real} <: MOIBC.AbstractBridge
    con_bigm::MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.LessThan{T}}
    con_smallm::MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.LessThan{T}}
end

function MOIBC.bridge_constraint(
    ::Type{ReifiedEqualTo2MILPBridge{T}},
    model,
    f::MOI.VectorOfVariables,
    s::CP.Reified{MOI.EqualTo{T}},
) where {T}
    return MOIBC.bridge_constraint(
        ReifiedEqualTo2MILPBridge{T},
        model,
        MOI.VectorAffineFunction{T}(f),
        s,
    )
end

function MOIBC.bridge_constraint(
    ::Type{ReifiedEqualTo2MILPBridge{T}},
    model,
    f::MOI.VectorAffineFunction{T},
    s::CP.Reified{MOI.EqualTo{T}},
) where {T <: Real}
    f_scalars = MOIU.scalarize(f)

    # For this formulation work, both lower and upper bounds are required on
    # the constrained expression (but obviously not on the binary reified 
    # variable).
    @assert CP.is_binary(model, f_scalars[1])
    @assert CP.has_lower_bound(model, f_scalars[2])
    @assert CP.has_upper_bound(model, f_scalars[2])

    # If the reified expression is true/false, then the EqualTo constraint 
    # must/cannot be satisfied. (If the constraint is satisfied, the reified 
    # expression is unconstrained.)
    if T <: Integer
        var_abs, var_abs_int = MOI.add_constrained_variable(model, MOI.Integer())
    else
        var_abs = MOI.add_variable(model)
        var_abs_int = nothing
    end

    con_abs = MOI.add_constraint(
        model, 
        MOIU.vectorize(
            MOI.ScalarAffineFunction{T}[
                one(T) * MOI.SingleVariable(var_abs),
                f_scalars[2] - s.set.value
            ]
        ), 
        CP.AbsoluteValue()
    )

    bigm = T(max(
        abs(CP.get_upper_bound(model, f_scalars[2])), 
        abs(CP.get_lower_bound(model, f_scalars[2]))
    ))
    con_bigm = MOI.add_constraint(
        model, 
        MOI.SingleVariable(var_abs) - bigm * (one(T) - f_scalars[1]), 
        MOI.LessThan(zero(T))
    )

    # If the constraint is satisfied, constrain the reified. 
    smallm = if T <: Int
        one(T)
    else
        T(_REIF_EQTO_FLOAT_EPSILON)
    end

    con_smallm = MOI.add_constraint(
        model, 
        f_scalars[1] - MOI.SingleVariable(var_abs) / smallm,
        MOI.LessThan(zero(T))
    )

    return ReifiedEqualTo2MILPBridge{T}(var_abs, var_abs_int, con_abs, con_bigm, con_smallm)
end

function MOI.supports_constraint(
    ::Type{ReifiedEqualTo2MILPBridge{T}},
    ::Union{Type{MOI.VectorOfVariables}, Type{MOI.VectorAffineFunction{T}}},
    ::Type{CP.Reified{MOI.EqualTo{T}}},
) where {T <: Real}
    return true
end

function MOIB.added_constrained_variable_types(::Type{ReifiedEqualTo2MILPBridge{T}}) where {T <: Real}
    return Tuple{DataType}[]
end

function MOIB.added_constrained_variable_types(::Type{ReifiedEqualTo2MILPBridge{T}}) where {T <: Integer}
    return [(MOI.Integer,)]
end

function MOIB.added_constraint_types(::Type{ReifiedEqualTo2MILPBridge{T}}) where {T <: Real}
    return [
        (MOI.VectorAffineFunction{T}, CP.AbsoluteValue),
        (MOI.VectorAffineFunction{T}, MOI.LessThan{T}),
    ]
end

function MOIB.added_constraint_types(::Type{ReifiedEqualTo2MILPBridge{T}}) where {T <: Integer}
    return [
        (MOI.SingleVariable, MOI.Integer),
        (MOI.VectorAffineFunction{T}, CP.AbsoluteValue),
        (MOI.VectorAffineFunction{T}, MOI.LessThan{T}),
    ]
end

function MOIBC.concrete_bridge_type(
    ::Type{ReifiedEqualTo2MILPBridge{T}},
    ::Union{Type{MOI.VectorOfVariables}, Type{MOI.VectorAffineFunction{T}}},
    ::Type{CP.Reified{MOI.EqualTo{T}}},
) where {T <: Real}
    return ReifiedEqualTo2MILPBridge{T}
end

function MOI.get(::ReifiedEqualTo2MILPBridge{T}, ::MOI.NumberOfVariables) where {T <: Real}
    return 1
end

function MOI.get(
    ::ReifiedEqualTo2MILPBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.SingleVariable, MOI.Integer,
    },
) where {T <: Real}
    return 0
end

function MOI.get(
    ::ReifiedEqualTo2MILPBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.SingleVariable, MOI.Integer,
    },
) where {T <: Integer}
    return 1
end

function MOI.get(
    ::ReifiedEqualTo2MILPBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.VectorAffineFunction{T}, CP.AbsoluteValue,
    },
) where {T <: Real}
    return 1
end

function MOI.get(
    ::ReifiedEqualTo2MILPBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.ScalarAffineFunction{T}, MOI.LessThan{T},
    },
) where {T <: Real}
    return 2
end

function MOI.get(
    b::ReifiedEqualTo2MILPBridge{T},
    ::MOI.ListOfVariableIndices,
) where {T <: Real}
    return [b.var_abs]
end

function MOI.get(
    b::ReifiedEqualTo2MILPBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.SingleVariable, MOI.Integer,
    },
) where {T <: Integer}
    return [b.var_abs_int]
end

function MOI.get(
    b::ReifiedEqualTo2MILPBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.VectorAffineFunction{T}, CP.AbsoluteValue,
    },
) where {T <: Real}
    return [b.con_abs]
end

function MOI.get(
    b::ReifiedEqualTo2MILPBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.ScalarAffineFunction{T}, MOI.LessThan{T},
    },
) where {T <: Real}
    return [b.con_bigm, b.con_smallm]
end
