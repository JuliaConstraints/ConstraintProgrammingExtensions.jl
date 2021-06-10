"""
Bridges `CP.DifferentFrom` to linear constraints (including, possibly, strict 
inequalities). This constraint adds one variable to store the absolute value of
the difference, and constrains it to be nonzero.

For `AbstractFloat` arguments (like `Float64`): equivalent to abs(x) > 0.0, i.e.
a `Strictly(GreaterThan(0.0))`.
"""
struct DifferentFrom2PseudoMILPBridge{T <: Real} <: MOIBC.AbstractBridge
    var_abs::Union{Nothing, MOI.VariableIndex}
    con_abs::Union{Nothing, MOI.ConstraintIndex{MOI.VectorAffineFunction{T}, CP.AbsoluteValue}, MOI.ConstraintIndex{MOI.SingleVariable, CP.AbsoluteValue}}
    con_abs_strictly::Union{Nothing, MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, CP.Strictly{MOI.GreaterThan{T}, T}}, MOI.ConstraintIndex{MOI.SingleVariable, CP.Strictly{MOI.GreaterThan{T}, T}}}
    con_abs_gt::Union{Nothing, MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.GreaterThan{T}}, MOI.ConstraintIndex{MOI.SingleVariable, MOI.GreaterThan{T}}}
    con_eq::Union{Nothing, MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}}, MOI.ConstraintIndex{MOI.SingleVariable, MOI.EqualTo{T}}}
end

function MOIBC.bridge_constraint(
    ::Type{DifferentFrom2PseudoMILPBridge{T}},
    model,
    f::MOI.SingleVariable,
    s::CP.DifferentFrom{T},
) where {T <: Real}
    return MOIBC.bridge_constraint(
        DifferentFrom2PseudoMILPBridge{T},
        model,
        MOI.ScalarAffineFunction{T}(f),
        s,
    )
end

function MOIBC.bridge_constraint(
    ::Type{DifferentFrom2PseudoMILPBridge{T}},
    model,
    f::MOI.ScalarAffineFunction{T},
    s::CP.DifferentFrom{T},
) where {T <: Real}
    var_abs = MOI.add_variable(model)
    con_abs = MOI.add_constraint(
        model, 
        MOIU.vectorize([
            MOI.ScalarAffineFunction(
                [MOI.ScalarAffineTerm(one(T), var_abs)], 
                zero(T),
            ), 
            f - s.value,
        ]),
        CP.AbsoluteValue(),
    )

    # For floats, the difference may take any real value: > 0 must be 
    # encoded as-is.
    con_abs_strictly = MOI.add_constraint(
        model, 
        one(T) * MOI.SingleVariable(var_abs),
        CP.Strictly(MOI.GreaterThan(zero(T)))
    )

    return DifferentFrom2PseudoMILPBridge{T}(var_abs, con_abs, con_abs_strictly, nothing, nothing)
end

function MOIBC.bridge_constraint(
    ::Type{DifferentFrom2PseudoMILPBridge{T}},
    model,
    f::MOI.ScalarAffineFunction{T},
    s::CP.DifferentFrom{T},
) where {T <: Integer}
    var_abs = MOI.add_variable(model)
    con_abs = MOI.add_constraint(
        model, 
        MOIU.vectorize([one(T) * MOI.SingleVariable(var_abs), f - s.value]),
        CP.AbsoluteValue(),
    )

    # For integers, the difference takes an integer value: > 0 is equivalent to >= 1.
    con_abs_gt = MOI.add_constraint(
        model, 
        MOI.SingleVariable(var_abs),
        MOI.GreaterThan(one(T))
    )

    return DifferentFrom2PseudoMILPBridge{T}(var_abs, con_abs, nothing, con_abs_gt, nothing)
end

function MOIBC.bridge_constraint(
    ::Type{DifferentFrom2PseudoMILPBridge{Bool}},
    model,
    f::MOI.ScalarAffineFunction{Bool},
    s::CP.DifferentFrom{Bool},
)
    # For Booleans, no need to have an absolute value: != 0 is equivalent to 
    # == 1, and vice-versa.
    con_eq = MOI.add_constraint(
        model, 
        f,
        MOI.EqualTo{Bool}(1 - s.value)
    )

    return DifferentFrom2PseudoMILPBridge{Bool}(nothing, nothing, nothing, nothing, con_eq)
end

function MOI.supports_constraint(
    ::Type{DifferentFrom2PseudoMILPBridge{T}},
    ::Union{Type{MOI.SingleVariable}, Type{MOI.ScalarAffineFunction{T}}},
    ::Type{CP.DifferentFrom{T}},
) where {T <: Real}
    return true
end

function MOIB.added_constrained_variable_types(::Type{DifferentFrom2PseudoMILPBridge{T}}) where {T <: Real}
    return Tuple{DataType}[]
end

function MOIB.added_constraint_types(::Type{DifferentFrom2PseudoMILPBridge{T}}) where {T <: AbstractFloat}
    return [
        (MOI.VectorAffineFunction{T}, CP.AbsoluteValue),
        (MOI.SingleVariable, CP.Strictly{MOI.GreaterThan{T}}),
    ]
end

function MOIB.added_constraint_types(::Type{DifferentFrom2PseudoMILPBridge{T}}) where {T <: Integer}
    return [
        (MOI.VectorAffineFunction{T}, CP.AbsoluteValue),
        (MOI.SingleVariable, MOI.GreaterThan{T}),
    ]
end

function MOIB.added_constraint_types(::Type{DifferentFrom2PseudoMILPBridge{Bool}})
    return [
        (MOI.ScalarAffineFunction{Bool}, MOI.EqualTo{Bool}),
    ]
end

function MOIBC.concrete_bridge_type(
    ::Type{DifferentFrom2PseudoMILPBridge{T}},
    ::Union{Type{MOI.VectorOfVariables}, Type{MOI.VectorAffineFunction{T}}},
    ::Type{CP.DifferentFrom{T}},
) where {T <: Real}
    return DifferentFrom2PseudoMILPBridge{T}
end

function MOI.get(::DifferentFrom2PseudoMILPBridge{T}, ::MOI.NumberOfVariables) where {T <: Real}
    return 1
end

function MOI.get(::DifferentFrom2PseudoMILPBridge{Bool}, ::MOI.NumberOfVariables)
    return 0
end

function MOI.get(
    ::DifferentFrom2PseudoMILPBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.VectorAffineFunction{T}, CP.AbsoluteValue,
    },
) where {T <: Real}
    return 1
end

function MOI.get(
    ::DifferentFrom2PseudoMILPBridge{Bool},
    ::MOI.NumberOfConstraints{
        MOI.VectorAffineFunction{Bool}, CP.AbsoluteValue,
    },
)
    return 0
end

function MOI.get(
    ::DifferentFrom2PseudoMILPBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.ScalarAffineFunction{T}, CP.Strictly{MOI.GreaterThan{T}},
    },
) where {T <: AbstractFloat}
    return 1
end

function MOI.get(
    ::DifferentFrom2PseudoMILPBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.ScalarAffineFunction{T}, CP.Strictly{MOI.GreaterThan{T}},
    },
) where {T <: Real}
    return 0
end

function MOI.get(
    ::DifferentFrom2PseudoMILPBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.ScalarAffineFunction{T}, MOI.GreaterThan{T},
    },
) where {T <: AbstractFloat}
    return 0
end

function MOI.get(
    ::DifferentFrom2PseudoMILPBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.ScalarAffineFunction{T}, MOI.GreaterThan{T},
    },
) where {T <: Real}
    return 1
end

function MOI.get(
    ::DifferentFrom2PseudoMILPBridge{Bool},
    ::MOI.NumberOfConstraints{
        MOI.ScalarAffineFunction{Bool}, MOI.GreaterThan{Bool},
    },
)
    return 0
end

function MOI.get(
    ::DifferentFrom2PseudoMILPBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.ScalarAffineFunction{T}, MOI.EqualTo{T},
    },
) where {T <: Real}
    return 0
end

function MOI.get(
    ::DifferentFrom2PseudoMILPBridge{Bool},
    ::MOI.NumberOfConstraints{
        MOI.ScalarAffineFunction{Bool}, MOI.EqualTo{Bool},
    },
)
    return 1
end

function MOI.get(
    b::DifferentFrom2PseudoMILPBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.VectorAffineFunction{T}, CP.AbsoluteValue,
    },
) where {T <: Real}
    return b.con_abs === nothing ? 
        Vector{MOI.ConstraintIndex{MOI.VectorAffineFunction{T}, CP.AbsoluteValue}}[] :
        [b.con_abs]
end

function MOI.get(
    b::DifferentFrom2PseudoMILPBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.ScalarAffineFunction{T}, CP.Strictly{MOI.GreaterThan{T}},
    },
) where {T <: Real}
    return b.con_abs === nothing ? 
        Vector{MOI.ConstraintIndex{MOI.SingleVariable, CP.Strictly{MOI.GreaterThan{T}}}}[] :
        [b.con_abs_strictly]
end

function MOI.get(
    b::DifferentFrom2PseudoMILPBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.ScalarAffineFunction{T}, MOI.GreaterThan{T},
    },
) where {T <: Real}
    return b.con_abs === nothing ? 
        Vector{MOI.ConstraintIndex{MOI.SingleVariable, MOI.GreaterThan{T}}}[] :
        [b.con_abs_gt]
end

function MOI.get(
    b::DifferentFrom2PseudoMILPBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.ScalarAffineFunction{T}, MOI.EqualTo{T},
    },
) where {T <: Real}
    return b.con_eq === nothing ? 
        Vector{MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}}}[] :
        [b.con_eq]
end
