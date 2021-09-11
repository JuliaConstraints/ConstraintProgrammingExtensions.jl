"""
Bridges `CP.Reification{CP.DifferentFrom}` to indicator constraints, both with equality
and inequalities (CP.DifferentFrom).
"""
struct ReificationDifferentFrom2IndicatorBridge{T <: Real} <: MOIBC.AbstractBridge
    indic_true::MOI.ConstraintIndex{MOI.VectorAffineFunction{T}, MOI.Indicator{MOI.ACTIVATE_ON_ONE, MOI.EqualTo{T}}}
    indic_false::MOI.ConstraintIndex{MOI.VectorAffineFunction{T}, MOI.Indicator{MOI.ACTIVATE_ON_ZERO, CP.DifferentFrom{T}}}
end

function MOIBC.bridge_constraint(
    ::Type{ReificationDifferentFrom2IndicatorBridge{T}},
    model,
    f::MOI.VectorOfVariables,
    s::CP.Reification{CP.DifferentFrom{T}},
) where {T}
    return MOIBC.bridge_constraint(
        ReificationDifferentFrom2IndicatorBridge{T},
        model,
        MOI.VectorAffineFunction{T}(f),
        s,
    )
end

function MOIBC.bridge_constraint(
    ::Type{ReificationDifferentFrom2IndicatorBridge{T}},
    model,
    f::MOI.VectorAffineFunction{T},
    s::CP.Reification{CP.DifferentFrom{T}},
) where {T <: Real}
    # Only change with respect to CP.Reification{MOI.EqualTo}: change the 
    # sign of the first variable.
    f_scalars = MOIU.scalarize(f)
    f = MOIU.vectorize(
        [
            one(T) - f_scalars[1],
            f_scalars[2]
        ]
    )

    indic_true = MOI.add_constraint(
        model, 
        f,
        MOI.Indicator{MOI.ACTIVATE_ON_ONE}(MOI.EqualTo(s.set.value))
    )
    indic_false = MOI.add_constraint(
        model, 
        f,
        MOI.Indicator{MOI.ACTIVATE_ON_ZERO}(CP.DifferentFrom(s.set.value))
        # TODO: helper to build CP.\neq from MOI.EqTo, CP.Strictly from inequalities, like `!()`? 
    )

    return ReificationDifferentFrom2IndicatorBridge{T}(indic_true, indic_false)
end

function MOI.supports_constraint(
    ::Type{ReificationDifferentFrom2IndicatorBridge{T}},
    ::Union{Type{MOI.VectorOfVariables}, Type{MOI.VectorAffineFunction{T}}},
    ::Type{CP.Reification{CP.DifferentFrom{T}}},
) where {T <: Real}
    return true
end

function MOIB.added_constrained_variable_types(::Type{ReificationDifferentFrom2IndicatorBridge{T}}) where {T <: Real}
    return Tuple{Type}[]
end

function MOIB.added_constraint_types(::Type{ReificationDifferentFrom2IndicatorBridge{T}}) where {T <: Real}
    return [
        (MOI.VectorAffineFunction{T}, MOI.Indicator{MOI.ACTIVATE_ON_ONE, MOI.EqualTo{T}}),
        (MOI.VectorAffineFunction{T}, MOI.Indicator{MOI.ACTIVATE_ON_ZERO, CP.DifferentFrom{T}}),
    ]
end

function MOI.get(
    ::ReificationDifferentFrom2IndicatorBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.VectorAffineFunction{T}, MOI.Indicator{MOI.ACTIVATE_ON_ONE, MOI.EqualTo{T}},
    },
) where {T <: Real}
    return 1
end

function MOI.get(
    ::ReificationDifferentFrom2IndicatorBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.VectorAffineFunction{T}, MOI.Indicator{MOI.ACTIVATE_ON_ZERO, CP.DifferentFrom{T}},
    },
) where {T <: Real}
    return 1
end

function MOI.get(
    b::ReificationDifferentFrom2IndicatorBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.VectorAffineFunction{T}, MOI.Indicator{MOI.ACTIVATE_ON_ONE, MOI.EqualTo{T}},
    },
) where {T <: Real}
    return [b.indic_true]
end

function MOI.get(
    b::ReificationDifferentFrom2IndicatorBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.VectorAffineFunction{T}, MOI.Indicator{MOI.ACTIVATE_ON_ZERO, CP.DifferentFrom{T}},
    },
) where {T <: Real}
    return [b.indic_false]
end
