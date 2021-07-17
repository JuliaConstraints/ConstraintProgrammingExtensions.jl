"""
Bridges `CP.Reification{MOI.LessThan}` to indicator constraints with (strict) 
inequalities.
"""
struct ReificationLessThan2IndicatorBridge{T <: Real} <: MOIBC.AbstractBridge
    indic_true::MOI.ConstraintIndex{MOI.VectorAffineFunction{T}, MOI.IndicatorSet{MOI.ACTIVATE_ON_ONE, MOI.LessThan{T}}}
    indic_false::MOI.ConstraintIndex{MOI.VectorAffineFunction{T}, MOI.IndicatorSet{MOI.ACTIVATE_ON_ZERO, CP.Strictly{MOI.GreaterThan{T}, T}}}
end

function MOIBC.bridge_constraint(
    ::Type{ReificationLessThan2IndicatorBridge{T}},
    model,
    f::MOI.VectorOfVariables,
    s::CP.Reification{MOI.LessThan{T}},
) where {T}
    return MOIBC.bridge_constraint(
        ReificationLessThan2IndicatorBridge{T},
        model,
        MOI.VectorAffineFunction{T}(f),
        s,
    )
end

function MOIBC.bridge_constraint(
    ::Type{ReificationLessThan2IndicatorBridge{T}},
    model,
    f::MOI.VectorAffineFunction{T},
    s::CP.Reification{MOI.LessThan{T}},
) where {T <: Real}
    indic_true = MOI.add_constraint(
        model, 
        f,
        MOI.IndicatorSet{MOI.ACTIVATE_ON_ONE}(s.set)
    )
    indic_false = MOI.add_constraint(
        model, 
        f,
        MOI.IndicatorSet{MOI.ACTIVATE_ON_ZERO}(CP.Strictly(MOI.GreaterThan(s.set.upper)))
        # TODO: helper to build CP.\neq from MOI.EqTo, CP.Strictly from inequalities, like `!()`? 
    )

    return ReificationLessThan2IndicatorBridge{T}(indic_true, indic_false)
end

function MOI.supports_constraint(
    ::Type{ReificationLessThan2IndicatorBridge{T}},
    ::Union{Type{MOI.VectorOfVariables}, Type{MOI.VectorAffineFunction{T}}},
    ::Type{CP.Reification{MOI.LessThan{T}}},
) where {T <: Real}
    return true
end

function MOIB.added_constrained_variable_types(::Type{ReificationLessThan2IndicatorBridge{T}}) where {T <: Real}
    return Tuple{DataType}[]
end

function MOIB.added_constraint_types(::Type{ReificationLessThan2IndicatorBridge{T}}) where {T <: Real}
    return [
        (MOI.VectorAffineFunction{T}, MOI.IndicatorSet{MOI.ACTIVATE_ON_ONE, MOI.LessThan{T}}),
        (MOI.VectorAffineFunction{T}, MOI.IndicatorSet{MOI.ACTIVATE_ON_ZERO, CP.Strictly{MOI.GreaterThan{T}, T}}),
    ]
end

function MOIBC.concrete_bridge_type(
    ::Type{ReificationLessThan2IndicatorBridge{T}},
    ::Union{Type{MOI.VectorOfVariables}, Type{MOI.VectorAffineFunction{T}}},
    ::Type{CP.Reification{MOI.LessThan{T}}},
) where {T <: Real}
    return ReificationLessThan2IndicatorBridge{T}
end

function MOI.get(::ReificationLessThan2IndicatorBridge{T}, ::MOI.NumberOfVariables) where {T <: Real}
    return 0
end

function MOI.get(
    ::ReificationLessThan2IndicatorBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.VectorAffineFunction{T}, MOI.IndicatorSet{MOI.ACTIVATE_ON_ONE, MOI.LessThan{T}},
    },
) where {T <: Real}
    return 1
end

function MOI.get(
    ::ReificationLessThan2IndicatorBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.VectorAffineFunction{T}, MOI.IndicatorSet{MOI.ACTIVATE_ON_ZERO, CP.Strictly{MOI.GreaterThan{T}, T}},
    },
) where {T <: Real}
    return 1
end

function MOI.get(
    b::ReificationLessThan2IndicatorBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.VectorAffineFunction{T}, MOI.IndicatorSet{MOI.ACTIVATE_ON_ONE, MOI.LessThan{T}},
    },
) where {T <: Real}
    return [b.indic_true]
end

function MOI.get(
    b::ReificationLessThan2IndicatorBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.VectorAffineFunction{T}, MOI.IndicatorSet{MOI.ACTIVATE_ON_ZERO, CP.Strictly{MOI.GreaterThan{T}, T}},
    },
) where {T <: Real}
    return [b.indic_false]
end
