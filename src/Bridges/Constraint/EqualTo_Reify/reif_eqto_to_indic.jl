"""
Bridges `CP.Reified{MOI.EqualTo}` to indicator constraints, both with equality
and inequalities (CP.DifferentFrom).
"""
struct ReifiedEqualTo2IndicatorBridge{T <: Real} <: MOIBC.AbstractBridge
    indic_true::MOI.ConstraintIndex{MOI.VectorAffineFunction{T}, MOI.IndicatorSet{MOI.ACTIVATE_ON_ONE, MOI.EqualTo{T}}}
    indic_false::MOI.ConstraintIndex{MOI.VectorAffineFunction{T}, MOI.IndicatorSet{MOI.ACTIVATE_ON_ZERO, CP.DifferentFrom{T}}}
end

function MOIBC.bridge_constraint(
    ::Type{ReifiedEqualTo2IndicatorBridge{T}},
    model,
    f::MOI.SingleVariable,
    s::CP.Reified{MOI.EqualTo{T}},
) where {T}
    return MOIBC.bridge_constraint(
        ReifiedEqualTo2IndicatorBridge{T},
        model,
        MOI.ScalarAffineFunction{T}(f),
        s,
    )
end

function MOIBC.bridge_constraint(
    ::Type{ReifiedEqualTo2IndicatorBridge{T}},
    model,
    f::MOI.ScalarAffineFunction{T},
    s::CP.Reified{MOI.EqualTo{T}},
) where {T <: Real}
    indic_true = MOI.add_constraint(
        model, 
        f,
        MOI.IndicatorSet{MOI.ACTIVATE_ON_ONE}(s.set)
    )
    indic_true = MOI.add_constraint(
        model, 
        f,
        MOI.IndicatorSet{MOI.ACTIVATE_ON_ZERO}(CP.DifferentFrom(s.set.value))
        # TODO: helper to build CP.\neq from MOI.EqTo, CP.Strictly from inequalities, like `!()`? 
    )

    return ReifiedEqualTo2IndicatorBridge{T}(indic_true, indic_false)
end

function MOI.supports_constraint(
    ::Type{ReifiedEqualTo2IndicatorBridge{T}},
    ::Union{Type{MOI.SingleVariable}, Type{MOI.ScalarAffineFunction{T}}},
    ::Type{CP.Reified{MOI.EqualTo{T}}},
) where {T <: Real}
    return true
end

function MOIB.added_constrained_variable_types(::Type{ReifiedEqualTo2IndicatorBridge{T}}) where {T <: Real}
    return Tuple{DataType}[]
end

function MOIB.added_constraint_types(::Type{ReifiedEqualTo2IndicatorBridge{T}}) where {T <: Real}
    return [
        (MOI.VectorAffineFunction{T}, MOI.IndicatorSet{MOI.ACTIVATE_ON_ONE, MOI.EqualTo{T}}),
        (MOI.VectorAffineFunction{T}, MOI.IndicatorSet{MOI.ACTIVATE_ON_ZERO, CP.DifferentFrom{T}}),
    ]
end

function MOIBC.concrete_bridge_type(
    ::Type{ReifiedEqualTo2IndicatorBridge{T}},
    ::Union{Type{MOI.VectorOfVariables}, Type{MOI.VectorAffineFunction{T}}},
    ::Type{CP.Reified{MOI.EqualTo{T}}},
) where {T <: Real}
    return ReifiedEqualTo2IndicatorBridge{T}
end

function MOI.get(::ReifiedEqualTo2IndicatorBridge{T}, ::MOI.NumberOfVariables) where {T <: Real}
    return 0
end

function MOI.get(
    ::ReifiedEqualTo2IndicatorBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.VectorAffineFunction{T}, CP.AbsoluteValue,
    },
) where {T <: Real}
    return 1
end

function MOI.get(
    ::ReifiedEqualTo2IndicatorBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.VectorAffineFunction{T}, MOI.IndicatorSet{MOI.ACTIVATE_ON_ONE, MOI.EqualTo{T}},
    },
) where {T <: Real}
    return 1
end

function MOI.get(
    ::ReifiedEqualTo2IndicatorBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.VectorAffineFunction{T}, MOI.IndicatorSet{MOI.ACTIVATE_ON_ZERO, CP.DifferentFrom{T}},
    },
) where {T <: Real}
    return 1
end

function MOI.get(
    b::ReifiedEqualTo2IndicatorBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.VectorAffineFunction{T}, MOI.IndicatorSet{MOI.ACTIVATE_ON_ONE, MOI.EqualTo{T}},
    },
) where {T <: Real}
    return [b.indic_true]
end

function MOI.get(
    b::ReifiedEqualTo2IndicatorBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.VectorAffineFunction{T}, MOI.IndicatorSet{MOI.ACTIVATE_ON_ZERO, CP.DifferentFrom{T}},
    },
) where {T <: Real}
    return [b.indic_false]
end
