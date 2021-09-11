"""
Bridges `CP.Reification{MOI.GreaterThan}` to indicator constraints with (strict) 
inequalities.
"""
struct ReificationGreaterThan2IndicatorBridge{T <: Real} <: MOIBC.AbstractBridge
    indic_true::MOI.ConstraintIndex{MOI.VectorAffineFunction{T}, MOI.IndicatorSet{MOI.ACTIVATE_ON_ONE, MOI.GreaterThan{T}}}
    indic_false::MOI.ConstraintIndex{MOI.VectorAffineFunction{T}, MOI.IndicatorSet{MOI.ACTIVATE_ON_ZERO, CP.Strictly{MOI.LessThan{T}, T}}}
end

function MOIBC.bridge_constraint(
    ::Type{ReificationGreaterThan2IndicatorBridge{T}},
    model,
    f::MOI.VectorOfVariables,
    s::CP.Reification{MOI.GreaterThan{T}},
) where {T}
    return MOIBC.bridge_constraint(
        ReificationGreaterThan2IndicatorBridge{T},
        model,
        MOI.VectorAffineFunction{T}(f),
        s,
    )
end

function MOIBC.bridge_constraint(
    ::Type{ReificationGreaterThan2IndicatorBridge{T}},
    model,
    f::MOI.VectorAffineFunction{T},
    s::CP.Reification{MOI.GreaterThan{T}},
) where {T <: Real}
    indic_true = MOI.add_constraint(
        model, 
        f,
        MOI.IndicatorSet{MOI.ACTIVATE_ON_ONE}(s.set)
    )
    indic_false = MOI.add_constraint(
        model, 
        f,
        MOI.IndicatorSet{MOI.ACTIVATE_ON_ZERO}(CP.Strictly(MOI.LessThan(s.set.lower)))
        # TODO: helper to build CP.\neq from MOI.EqTo, CP.Strictly from inequalities, like `!()`? 
    )

    return ReificationGreaterThan2IndicatorBridge{T}(indic_true, indic_false)
end

function MOI.supports_constraint(
    ::Type{ReificationGreaterThan2IndicatorBridge{T}},
    ::Union{Type{MOI.VectorOfVariables}, Type{MOI.VectorAffineFunction{T}}},
    ::Type{CP.Reification{MOI.GreaterThan{T}}},
) where {T <: Real}
    return true
end

function MOIB.added_constrained_variable_types(::Type{ReificationGreaterThan2IndicatorBridge{T}}) where {T <: Real}
    return Tuple{Type}[]
end

function MOIB.added_constraint_types(::Type{ReificationGreaterThan2IndicatorBridge{T}}) where {T <: Real}
    return [
        (MOI.VectorAffineFunction{T}, MOI.IndicatorSet{MOI.ACTIVATE_ON_ONE, MOI.GreaterThan{T}}),
        (MOI.VectorAffineFunction{T}, MOI.IndicatorSet{MOI.ACTIVATE_ON_ZERO, CP.Strictly{MOI.LessThan{T}, T}}),
    ]
end

function MOI.get(
    ::ReificationGreaterThan2IndicatorBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.VectorAffineFunction{T}, MOI.IndicatorSet{MOI.ACTIVATE_ON_ONE, MOI.GreaterThan{T}},
    },
) where {T <: Real}
    return 1
end

function MOI.get(
    ::ReificationGreaterThan2IndicatorBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.VectorAffineFunction{T}, MOI.IndicatorSet{MOI.ACTIVATE_ON_ZERO, CP.Strictly{MOI.LessThan{T}, T}},
    },
) where {T <: Real}
    return 1
end

function MOI.get(
    b::ReificationGreaterThan2IndicatorBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.VectorAffineFunction{T}, MOI.IndicatorSet{MOI.ACTIVATE_ON_ONE, MOI.GreaterThan{T}},
    },
) where {T <: Real}
    return [b.indic_true]
end

function MOI.get(
    b::ReificationGreaterThan2IndicatorBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.VectorAffineFunction{T}, MOI.IndicatorSet{MOI.ACTIVATE_ON_ZERO, CP.Strictly{MOI.LessThan{T}, T}},
    },
) where {T <: Real}
    return [b.indic_false]
end
