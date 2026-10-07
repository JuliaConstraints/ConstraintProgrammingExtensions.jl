"""
Bridges `MOI.Indicator{A, CP.DifferentFrom}` to linear constraints 
(including, possibly, strict inequalities). This constraint adds one variable
to store the absolute value of the difference, and uses it for the indicator.

For `AbstractFloat` arguments (like `Float64`): equivalent to abs(x) > 0.0, i.e.
a `Strictly(GreaterThan(0.0))`.
"""
struct IndicatorDifferentFrom2PseudoMILPBridge{T <: Real, A} <: MOIBC.AbstractBridge
    var_abs::Union{Nothing, MOI.VariableIndex}
    con_abs::Union{Nothing, MOI.ConstraintIndex{MOI.VectorAffineFunction{T}, CP.AbsoluteValue}, MOI.ConstraintIndex{MOI.VariableIndex, CP.AbsoluteValue}}
    con_indic::Union{
        MOI.ConstraintIndex{MOI.VectorAffineFunction{T}, MOI.Indicator{A, CP.Strictly{MOI.GreaterThan{T}, T}}},
        MOI.ConstraintIndex{MOI.VectorAffineFunction{T}, MOI.Indicator{A, MOI.GreaterThan{T}}},
        MOI.ConstraintIndex{MOI.VectorAffineFunction{T}, MOI.Indicator{A, MOI.EqualTo{T}}},
    }
end

function MOIBC.bridge_constraint(
    ::Type{IndicatorDifferentFrom2PseudoMILPBridge{T, A}},
    model,
    f::MOI.VectorOfVariables,
    s::MOI.Indicator{A, CP.DifferentFrom{T}},
) where {T <: Real, A}
    return MOIBC.bridge_constraint(
        IndicatorDifferentFrom2PseudoMILPBridge{T, A},
        model,
        MOI.VectorAffineFunction{T}(f),
        s,
    )
end

function MOIBC.bridge_constraint(
    ::Type{IndicatorDifferentFrom2PseudoMILPBridge{T, A}},
    model,
    f::MOI.VectorAffineFunction{T},
    s::MOI.Indicator{A, CP.DifferentFrom{T}},
) where {T <: Real, A}
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
                one(T) * var_abs
            ]
        ), 
        MOI.Indicator{A}(CP.Strictly(MOI.GreaterThan(zero(T))))
    )

    return IndicatorDifferentFrom2PseudoMILPBridge{T, A}(var_abs, con_abs, con_indic)
end

function MOIBC.bridge_constraint(
    ::Type{IndicatorDifferentFrom2PseudoMILPBridge{T, A}},
    model,
    f::MOI.VectorAffineFunction{T},
    s::MOI.Indicator{A, CP.DifferentFrom{T}},
) where {T <: Integer, A}
    f_scalars = MOIU.scalarize(f)

    # Add the absolute value.
    var_abs = MOI.add_variable(model)
    con_abs = MOI.add_constraint(
        model, 
        MOIU.vectorize([one(T) * var_abs, f_scalars[2] - s.set.value]),
        CP.AbsoluteValue(),
    )

    # New indicator. For integers, the difference takes an integer value: 
    # > 0 is equivalent to >= 1.
    con_indic = MOI.add_constraint(
        model, 
        MOIU.vectorize(
            [
                f_scalars[1],
                one(T) * var_abs
            ]
        ), 
        MOI.Indicator{A}(MOI.GreaterThan(one(T)))
    )

    return IndicatorDifferentFrom2PseudoMILPBridge{T, A}(var_abs, con_abs, con_indic)
end

function MOIBC.bridge_constraint(
    ::Type{IndicatorDifferentFrom2PseudoMILPBridge{Bool, A}},
    model,
    f::MOI.VectorAffineFunction{Bool},
    s::MOI.Indicator{A, CP.DifferentFrom{Bool}},
) where {A}
    # New indicator. For Booleans, no need to have an absolute value: 
    # != 0 is equivalent to == 1, and vice-versa.
    con_indic = MOI.add_constraint(
        model, 
        f,
        MOI.Indicator{A}(MOI.EqualTo{Bool}(1 - s.set.value))
    )

    return IndicatorDifferentFrom2PseudoMILPBridge{Bool, A}(nothing, nothing, con_indic)
end

function MOI.supports_constraint(
    ::Type{IndicatorDifferentFrom2PseudoMILPBridge{T, A}},
    ::Union{Type{MOI.VectorOfVariables}, Type{MOI.VectorAffineFunction{T}}},
    ::Type{MOI.Indicator{A, CP.DifferentFrom{T}}},
) where {T <: Real, A}
    return true
end

function MOIB.added_constrained_variable_types(::Type{IndicatorDifferentFrom2PseudoMILPBridge{T, A}}) where {T <: Real, A}
    return Tuple{Type}[]
end

function MOIB.added_constraint_types(::Type{IndicatorDifferentFrom2PseudoMILPBridge{T, A}}) where {T <: AbstractFloat, A}
    return [
        (MOI.VectorAffineFunction{T}, CP.AbsoluteValue),
        (MOI.VectorAffineFunction{T}, MOI.Indicator{A, CP.Strictly{MOI.GreaterThan{T}}}),
    ]
end

function MOIB.added_constraint_types(::Type{IndicatorDifferentFrom2PseudoMILPBridge{T, A}}) where {T <: Integer, A}
    return [
        (MOI.VectorAffineFunction{T}, CP.AbsoluteValue),
        (MOI.VectorAffineFunction{T}, MOI.Indicator{A, MOI.GreaterThan{T}}),
    ]
end

function MOIB.added_constraint_types(::Type{IndicatorDifferentFrom2PseudoMILPBridge{Bool, A}}) where {A}
    return [
        (MOI.VectorAffineFunction{Bool}, MOI.Indicator{A, MOI.EqualTo{Bool}}),
    ]
end

function MOI.get(::IndicatorDifferentFrom2PseudoMILPBridge{T, A}, ::MOI.NumberOfVariables) where {T <: Real, A}
    return 1
end

function MOI.get(::IndicatorDifferentFrom2PseudoMILPBridge{Bool, A}, ::MOI.NumberOfVariables) where {A}
    return 0
end

function MOI.get(
    ::IndicatorDifferentFrom2PseudoMILPBridge{T, A},
    ::MOI.NumberOfConstraints{
        MOI.VectorAffineFunction{T}, CP.AbsoluteValue,
    },
) where {T <: Real, A}
    return 1
end

function MOI.get(
    ::IndicatorDifferentFrom2PseudoMILPBridge{Bool, A},
    ::MOI.NumberOfConstraints{
        MOI.VectorAffineFunction{Bool}, CP.AbsoluteValue,
    },
) where {A}
    return 0
end

function MOI.get(
    ::IndicatorDifferentFrom2PseudoMILPBridge{T, A},
    ::MOI.NumberOfConstraints{
        MOI.VectorAffineFunction{T}, MOI.Indicator{A, CP.Strictly{MOI.GreaterThan{T}}},
    },
) where {T <: AbstractFloat, A}
    return 1
end

function MOI.get(
    ::IndicatorDifferentFrom2PseudoMILPBridge{T, A},
    ::MOI.NumberOfConstraints{
        MOI.VectorAffineFunction{T}, MOI.Indicator{A, CP.Strictly{MOI.GreaterThan{T}}},
    },
) where {T <: Real, A}
    return 0
end

function MOI.get(
    ::IndicatorDifferentFrom2PseudoMILPBridge{T, A},
    ::MOI.NumberOfConstraints{
        MOI.VectorAffineFunction{T}, MOI.Indicator{A, MOI.GreaterThan{T}},
    },
) where {T <: AbstractFloat, A}
    return 0
end

function MOI.get(
    ::IndicatorDifferentFrom2PseudoMILPBridge{T, A},
    ::MOI.NumberOfConstraints{
        MOI.VectorAffineFunction{T}, MOI.Indicator{A, MOI.GreaterThan{T}},
    },
) where {T <: Real, A}
    return 1
end

function MOI.get(
    ::IndicatorDifferentFrom2PseudoMILPBridge{Bool, A},
    ::MOI.NumberOfConstraints{
        MOI.VectorAffineFunction{Bool}, MOI.Indicator{A, MOI.GreaterThan{Bool}},
    },
) where {A}
    return 0
end

function MOI.get(
    ::IndicatorDifferentFrom2PseudoMILPBridge{T, A},
    ::MOI.NumberOfConstraints{
        MOI.VectorAffineFunction{T}, MOI.Indicator{A, MOI.EqualTo{T}},
    },
) where {T <: Real, A}
    return 0
end

function MOI.get(
    ::IndicatorDifferentFrom2PseudoMILPBridge{Bool, A},
    ::MOI.NumberOfConstraints{
        MOI.VectorAffineFunction{Bool}, MOI.Indicator{A, MOI.EqualTo{Bool}},
    },
) where {A}
    return 1
end

function MOI.get(
    b::IndicatorDifferentFrom2PseudoMILPBridge{T, A},
    ::MOI.ListOfVariableIndices,
) where {T <: Real, A}
    return [b.var_abs]
end

function MOI.get(
    b::IndicatorDifferentFrom2PseudoMILPBridge{T, A},
    ::MOI.ListOfConstraintIndices{
        MOI.VectorAffineFunction{T}, CP.AbsoluteValue,
    },
) where {T <: Real, A}
    return [b.con_abs]
end

function MOI.get(
    b::IndicatorDifferentFrom2PseudoMILPBridge{T, A},
    ::MOI.ListOfConstraintIndices{
        MOI.VectorAffineFunction{T}, MOI.Indicator{A, CP.Strictly{MOI.GreaterThan{T}}},
    },
) where {T <: Real, A}
    return [b.con_indic]
end

function MOI.get(
    b::IndicatorDifferentFrom2PseudoMILPBridge{T, A},
    ::MOI.ListOfConstraintIndices{
        MOI.VectorAffineFunction{T}, MOI.Indicator{A, MOI.GreaterThan{T}},
    },
) where {T <: Real, A}
    return [b.con_indic]
end

function MOI.get(
    b::IndicatorDifferentFrom2PseudoMILPBridge{T, A},
    ::MOI.ListOfConstraintIndices{
        MOI.VectorAffineFunction{T}, MOI.Indicator{A, MOI.EqualTo{T}},
    },
) where {T <: Real, A}
    return [b.con_indic]
end
