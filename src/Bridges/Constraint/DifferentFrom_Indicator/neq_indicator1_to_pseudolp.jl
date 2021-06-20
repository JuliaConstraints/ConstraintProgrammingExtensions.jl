"""
Bridges `MOI.IndicatorSet{MOI.ACTIVATE_ON_ONE, CP.DifferentFrom}` to linear 
constraints (including, possibly, strict inequalities). This constraint adds 
one variable to store the absolute value of the difference, and uses it for 
the indicator.

For `AbstractFloat` arguments (like `Float64`): equivalent to abs(x) > 0.0, i.e.
a `Strictly(GreaterThan(0.0))`.
"""
struct Indicator1DifferentFrom2PseudoMILPBridge{T <: Real} <: MOIBC.AbstractBridge
    var_abs::Union{Nothing, MOI.VariableIndex}
    con_abs::Union{Nothing, MOI.ConstraintIndex{MOI.VectorAffineFunction{T}, CP.AbsoluteValue}, MOI.ConstraintIndex{MOI.SingleVariable, CP.AbsoluteValue}}
    con_indic::Union{
        MOI.ConstraintIndex{MOI.VectorAffineFunction{T}, MOI.IndicatorSet{MOI.ACTIVATE_ON_ONE, CP.Strictly{MOI.GreaterThan{T}, T}}},
        MOI.ConstraintIndex{MOI.VectorAffineFunction{T}, MOI.IndicatorSet{MOI.ACTIVATE_ON_ONE, MOI.GreaterThan{T}}},
        MOI.ConstraintIndex{MOI.VectorAffineFunction{T}, MOI.IndicatorSet{MOI.ACTIVATE_ON_ONE, MOI.EqualTo{T}}},
    }
end

function MOIBC.bridge_constraint(
    ::Type{Indicator1DifferentFrom2PseudoMILPBridge{T}},
    model,
    f::MOI.VectorOfVariables,
    s::MOI.IndicatorSet{MOI.ACTIVATE_ON_ONE, CP.DifferentFrom{T}},
) where {T <: Real}
    return MOIBC.bridge_constraint(
        Indicator1DifferentFrom2PseudoMILPBridge{T},
        model,
        MOI.VectorAffineFunction{T}(f),
        s,
    )
end

function MOIBC.bridge_constraint(
    ::Type{Indicator1DifferentFrom2PseudoMILPBridge{T}},
    model,
    f::MOI.VectorAffineFunction{T},
    s::MOI.IndicatorSet{MOI.ACTIVATE_ON_ONE, CP.DifferentFrom{T}},
) where {T <: Real}
    f_scalars = MOIU.scalarize(f)

    # Add the absolute value.
    var_abs = MOI.add_variable(model)
    con_abs = MOI.add_constraint(
        model, 
        MOIU.vectorize([
            MOI.ScalarAffineFunction(
                [MOI.ScalarAffineTerm(one(T), var_abs)], 
                zero(T),
            ), 
            f_scalars[2] - s.set.value,
        ]),
        CP.AbsoluteValue(),
    )

    # New indicator. For floats, the difference may take any real value: 
    # > 0 must be encoded as-is.
    con_indic = MOI.add_constraint(
        model, 
        MOIU.vectorize(
            [
                f_scalars[1],
                one(T) * MOI.SingleVariable(var_abs)
            ]
        ), 
        MOI.IndicatorSet{MOI.ACTIVATE_ON_ONE}(CP.Strictly(MOI.GreaterThan(zero(T))))
    )

    return Indicator1DifferentFrom2PseudoMILPBridge{T}(var_abs, con_abs, con_indic)
end

function MOIBC.bridge_constraint(
    ::Type{Indicator1DifferentFrom2PseudoMILPBridge{T}},
    model,
    f::MOI.VectorAffineFunction{T},
    s::MOI.IndicatorSet{MOI.ACTIVATE_ON_ONE, CP.DifferentFrom{T}},
) where {T <: Integer}
    f_scalars = MOIU.scalarize(f)

    # Add the absolute value.
    var_abs = MOI.add_variable(model)
    con_abs = MOI.add_constraint(
        model, 
        MOIU.vectorize([one(T) * MOI.SingleVariable(var_abs), f_scalars[2] - s.set.value]),
        CP.AbsoluteValue(),
    )

    # New indicator. For integers, the difference takes an integer value: 
    # > 0 is equivalent to >= 1.
    con_indic = MOI.add_constraint(
        model, 
        MOIU.vectorize(
            [
                f_scalars[1],
                one(T) * MOI.SingleVariable(var_abs)
            ]
        ), 
        MOI.IndicatorSet{MOI.ACTIVATE_ON_ONE}(MOI.GreaterThan(one(T)))
    )

    return Indicator1DifferentFrom2PseudoMILPBridge{T}(var_abs, con_abs, con_indic)
end

function MOIBC.bridge_constraint(
    ::Type{Indicator1DifferentFrom2PseudoMILPBridge{Bool}},
    model,
    f::MOI.VectorAffineFunction{Bool},
    s::MOI.IndicatorSet{MOI.ACTIVATE_ON_ONE, CP.DifferentFrom{Bool}},
)
    # New indicator. For Booleans, no need to have an absolute value: 
    # != 0 is equivalent to == 1, and vice-versa.
    con_indic = MOI.add_constraint(
        model, 
        f,
        MOI.IndicatorSet{MOI.ACTIVATE_ON_ONE}(MOI.EqualTo{Bool}(1 - s.set.value))
    )

    return Indicator1DifferentFrom2PseudoMILPBridge{Bool}(nothing, nothing, con_indic)
end

function MOI.supports_constraint(
    ::Type{Indicator1DifferentFrom2PseudoMILPBridge{T}},
    ::Union{Type{MOI.VectorOfVariables}, Type{MOI.VectorAffineFunction{T}}},
    ::Type{MOI.IndicatorSet{MOI.ACTIVATE_ON_ONE, CP.DifferentFrom{T}}},
) where {T <: Real}
    return true
end

function MOIB.added_constrained_variable_types(::Type{Indicator1DifferentFrom2PseudoMILPBridge{T}}) where {T <: Real}
    return Tuple{DataType}[]
end

function MOIB.added_constraint_types(::Type{Indicator1DifferentFrom2PseudoMILPBridge{T}}) where {T <: AbstractFloat}
    return [
        (MOI.VectorAffineFunction{T}, CP.AbsoluteValue),
        (MOI.VectorAffineFunction{T}, MOI.IndicatorSet{MOI.ACTIVATE_ON_ONE, CP.Strictly{MOI.GreaterThan{T}}}),
    ]
end

function MOIB.added_constraint_types(::Type{Indicator1DifferentFrom2PseudoMILPBridge{T}}) where {T <: Integer}
    return [
        (MOI.VectorAffineFunction{T}, CP.AbsoluteValue),
        (MOI.VectorAffineFunction{T}, MOI.IndicatorSet{MOI.ACTIVATE_ON_ONE, MOI.GreaterThan{T}}),
    ]
end

function MOIB.added_constraint_types(::Type{Indicator1DifferentFrom2PseudoMILPBridge{Bool}})
    return [
        (MOI.VectorAffineFunction{Bool}, MOI.IndicatorSet{MOI.ACTIVATE_ON_ONE, MOI.EqualTo{Bool}}),
    ]
end

function MOIBC.concrete_bridge_type(
    ::Type{Indicator1DifferentFrom2PseudoMILPBridge{T}},
    ::Union{Type{MOI.VectorOfVariables}, Type{MOI.VectorAffineFunction{T}}},
    ::Type{CP.DifferentFrom{T}},
) where {T <: Real}
    return Indicator1DifferentFrom2PseudoMILPBridge{T}
end

function MOI.get(::Indicator1DifferentFrom2PseudoMILPBridge{T}, ::MOI.NumberOfVariables) where {T <: Real}
    return 1
end

function MOI.get(::Indicator1DifferentFrom2PseudoMILPBridge{Bool}, ::MOI.NumberOfVariables)
    return 0
end

function MOI.get(
    ::Indicator1DifferentFrom2PseudoMILPBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.VectorAffineFunction{T}, CP.AbsoluteValue,
    },
) where {T <: Real}
    return 1
end

function MOI.get(
    ::Indicator1DifferentFrom2PseudoMILPBridge{Bool},
    ::MOI.NumberOfConstraints{
        MOI.VectorAffineFunction{Bool}, CP.AbsoluteValue,
    },
)
    return 0
end

function MOI.get(
    ::Indicator1DifferentFrom2PseudoMILPBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.VectorAffineFunction{T}, MOI.IndicatorSet{MOI.ACTIVATE_ON_ONE, CP.Strictly{MOI.GreaterThan{T}}},
    },
) where {T <: AbstractFloat}
    return 1
end

function MOI.get(
    ::Indicator1DifferentFrom2PseudoMILPBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.VectorAffineFunction{T}, MOI.IndicatorSet{MOI.ACTIVATE_ON_ONE, CP.Strictly{MOI.GreaterThan{T}}},
    },
) where {T <: Real}
    return 0
end

function MOI.get(
    ::Indicator1DifferentFrom2PseudoMILPBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.VectorAffineFunction{T}, MOI.IndicatorSet{MOI.ACTIVATE_ON_ONE, MOI.GreaterThan{T}},
    },
) where {T <: AbstractFloat}
    return 0
end

function MOI.get(
    ::Indicator1DifferentFrom2PseudoMILPBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.VectorAffineFunction{T}, MOI.IndicatorSet{MOI.ACTIVATE_ON_ONE, MOI.GreaterThan{T}},
    },
) where {T <: Real}
    return 1
end

function MOI.get(
    ::Indicator1DifferentFrom2PseudoMILPBridge{Bool},
    ::MOI.NumberOfConstraints{
        MOI.VectorAffineFunction{Bool}, MOI.IndicatorSet{MOI.ACTIVATE_ON_ONE, MOI.GreaterThan{Bool}},
    },
)
    return 0
end

function MOI.get(
    ::Indicator1DifferentFrom2PseudoMILPBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.VectorAffineFunction{T}, MOI.IndicatorSet{MOI.ACTIVATE_ON_ONE, MOI.EqualTo{T}},
    },
) where {T <: Real}
    return 0
end

function MOI.get(
    ::Indicator1DifferentFrom2PseudoMILPBridge{Bool},
    ::MOI.NumberOfConstraints{
        MOI.VectorAffineFunction{Bool}, MOI.IndicatorSet{MOI.ACTIVATE_ON_ONE, MOI.EqualTo{Bool}},
    },
)
    return 1
end

function MOI.get(
    b::Indicator1DifferentFrom2PseudoMILPBridge{T},
    ::MOI.ListOfVariableIndices,
) where {T <: Real}
    return [b.var_abs]
end

function MOI.get(
    b::Indicator1DifferentFrom2PseudoMILPBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.VectorAffineFunction{T}, CP.AbsoluteValue,
    },
) where {T <: Real}
    return [b.con_abs]
end

function MOI.get(
    b::Indicator1DifferentFrom2PseudoMILPBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.VectorAffineFunction{T}, MOI.IndicatorSet{MOI.ACTIVATE_ON_ONE, CP.Strictly{MOI.GreaterThan{T}}},
    },
) where {T <: Real}
    return [b.con_indic]
end

function MOI.get(
    b::Indicator1DifferentFrom2PseudoMILPBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.VectorAffineFunction{T}, MOI.IndicatorSet{MOI.ACTIVATE_ON_ONE, MOI.GreaterThan{T}},
    },
) where {T <: Real}
    return [b.con_indic]
end

function MOI.get(
    b::Indicator1DifferentFrom2PseudoMILPBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.VectorAffineFunction{T}, MOI.IndicatorSet{MOI.ACTIVATE_ON_ONE, MOI.EqualTo{T}},
    },
) where {T <: Real}
    return [b.con_indic]
end
