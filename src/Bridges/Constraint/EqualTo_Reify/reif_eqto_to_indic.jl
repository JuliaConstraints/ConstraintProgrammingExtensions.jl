"""
Bridges `CP.Reification{MOI.EqualTo}` to indicator constraints, both with equality
and inequalities (CP.DifferentFrom).
"""
struct ReificationEqualTo2IndicatorBridge{T <: Real} <: MOIBC.AbstractBridge
    indic_true::MOI.ConstraintIndex{MOI.VectorAffineFunction{T}, MOI.Indicator{MOI.ACTIVATE_ON_ONE, MOI.EqualTo{T}}}
    indic_false::MOI.ConstraintIndex{MOI.VectorAffineFunction{T}, MOI.Indicator{MOI.ACTIVATE_ON_ZERO, CP.DifferentFrom{T}}}
end

function MOIBC.bridge_constraint(
    ::Type{ReificationEqualTo2IndicatorBridge{T}},
    model,
    f::MOI.VectorOfVariables,
    s::CP.Reification{MOI.EqualTo{T}},
) where {T}
    return MOIBC.bridge_constraint(
        ReificationEqualTo2IndicatorBridge{T},
        model,
        MOI.VectorAffineFunction{T}(f),
        s,
    )
end

function MOIBC.bridge_constraint(
    ::Type{ReificationEqualTo2IndicatorBridge{T}},
    model,
    f::MOI.VectorAffineFunction{T},
    s::CP.Reification{MOI.EqualTo{T}},
) where {T <: Real}
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

    return ReificationEqualTo2IndicatorBridge{T}(indic_true, indic_false)
end

function MOI.supports_constraint(
    ::Type{ReificationEqualTo2IndicatorBridge{T}},
    ::Union{Type{MOI.VectorOfVariables}, Type{MOI.VectorAffineFunction{T}}},
    ::Type{CP.Reification{MOI.EqualTo{T}}},
) where {T <: Real}
    return true
end

function MOIB.added_constrained_variable_types(::Type{ReificationEqualTo2IndicatorBridge{T}}) where {T <: Real}
    return Tuple{Type}[]
end

function MOIB.added_constraint_types(::Type{ReificationEqualTo2IndicatorBridge{T}}) where {T <: Real}
    return [
        (MOI.VectorAffineFunction{T}, MOI.Indicator{MOI.ACTIVATE_ON_ONE, MOI.EqualTo{T}}),
        (MOI.VectorAffineFunction{T}, MOI.Indicator{MOI.ACTIVATE_ON_ZERO, CP.DifferentFrom{T}}),
    ]
end

function MOI.get(
    ::ReificationEqualTo2IndicatorBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.VectorAffineFunction{T}, MOI.Indicator{MOI.ACTIVATE_ON_ONE, MOI.EqualTo{T}},
    },
) where {T <: Real}
    return 1
end

function MOI.get(
    ::ReificationEqualTo2IndicatorBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.VectorAffineFunction{T}, MOI.Indicator{MOI.ACTIVATE_ON_ZERO, CP.DifferentFrom{T}},
    },
) where {T <: Real}
    return 1
end

function MOI.get(
    b::ReificationEqualTo2IndicatorBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.VectorAffineFunction{T}, MOI.Indicator{MOI.ACTIVATE_ON_ONE, MOI.EqualTo{T}},
    },
) where {T <: Real}
    return [b.indic_true]
end

function MOI.get(
    b::ReificationEqualTo2IndicatorBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.VectorAffineFunction{T}, MOI.Indicator{MOI.ACTIVATE_ON_ZERO, CP.DifferentFrom{T}},
    },
) where {T <: Real}
    return [b.indic_false]
end
