"""
Bridges `CP.DifferentFrom` to linear constraints (including, possibly, strict 
inequalities). This constraint adds one variable to store the absolute value of
the difference, and constrains it to be nonzero.

For `AbstractFloat` arguments (like `Float64`): equivalent to abs(x) > 0.0, i.e.
a `Strictly(GreaterThan(0.0))`.
"""
struct DifferentFrom2PseudoMILPBridge{T <: Real, U <: Real} <: MOIBC.AbstractBridge
    var_abs::Union{Nothing, MOI.VariableIndex}
    con_abs::Union{Nothing, MOI.ConstraintIndex{MOI.VectorAffineFunction{T}, CP.AbsoluteValue}}
    con_abs_strictly::Union{Nothing, MOI.ConstraintIndex{MOI.SingleVariable, CP.Strictly{MOI.GreaterThan{U}, U}}}
    con_abs_gt::Union{Nothing, MOI.ConstraintIndex{MOI.SingleVariable, MOI.GreaterThan{U}}}
    con_eq::Union{Nothing, MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.EqualTo{U}}}
end

function MOIBC.bridge_constraint(
    ::Type{DifferentFrom2PseudoMILPBridge{T, U}},
    model,
    f::MOI.SingleVariable,
    s::CP.DifferentFrom{U},
) where {T <: Real, U <: Real}
    return MOIBC.bridge_constraint(
        DifferentFrom2PseudoMILPBridge{T, U},
        model,
        MOI.ScalarAffineFunction{T}(f),
        s,
    )
end

function MOIBC.bridge_constraint(
    ::Type{DifferentFrom2PseudoMILPBridge{T}},
    model,
    f::MOI.ScalarAffineFunction{T},
    s::CP.DifferentFrom{U},
) where {T <: Real, U <: AbstractFloat}
    var_abs = MOI.add_variable(model)
    con_abs = MOI.add_constraint(
        model, 
        MOIU.vectorize([MOI.SingleVariable(var_abs), f - s.value]),
        CP.AbsoluteValue(),
    )

    # For floats, the difference may take any real value: > 0 must be 
    # encoded as-is.
    con_abs_strictly = MOI.add_constraint(
        model, 
        MOI.SingleVariable(var_abs),
        CP.Strictly(MOI.GreaterThan(zero(U)))
    )

    return DifferentFrom2PseudoMILPBridge{T, U}(var_abs, con_abs, con_abs_strictly, nothing)
end

function MOIBC.bridge_constraint(
    ::Type{DifferentFrom2PseudoMILPBridge{T, U}},
    model,
    f::MOI.ScalarAffineFunction{T},
    s::CP.DifferentFrom{U},
) where {T <: Real, U <: Integer}
    var_abs = MOI.add_variable(model)
    con_abs = MOI.add_constraint(
        model, 
        MOIU.vectorize([MOI.SingleVariable(var_abs), f - s.value]),
        CP.AbsoluteValue(),
    )

    # For integers, the difference takes an integer value: > 0 is equivalent to >= 1.
    con_abs_gt = MOI.add_constraint(
        model, 
        MOI.SingleVariable(var_abs),
        MOI.GreaterThan(one(U))
    )

    return DifferentFrom2PseudoMILPBridge{T, U}(var_abs, con_abs, nothing, con_abs_gt)
end

function MOIBC.bridge_constraint(
    ::Type{DifferentFrom2PseudoMILPBridge{Bool}},
    model,
    f::MOI.ScalarAffineFunction{T},
    s::CP.DifferentFrom{Bool},
) where {T <: Real}
    # For Booleans, no need to have an absolute value: != 0 is equivalent to 
    # == 1, and vice-versa.
    con_eq = MOI.add_constraint(
        model, 
        f,
        MOI.EqualTo(1 - s.value)
    )

    return DifferentFrom2PseudoMILPBridge{T, Bool}(nothing, nothing, nothing, nothing, con_abs_gt)
end

function MOI.supports_constraint(
    ::Type{DifferentFrom2PseudoMILPBridge{T, U}},
    ::Union{Type{MOI.SingleVariable}, Type{MOI.ScalarAffineFunction{T}}},
    ::Type{CP.DifferentFrom{U}},
) where {T <: Real, U <: Real}
    @assert false
    return true
end

function MOIB.added_constrained_variable_types(::Type{DifferentFrom2PseudoMILPBridge{T, U}}) where {T <: Real, U <: Real}
    return Tuple{DataType}[]
end

function MOIB.added_constraint_types(::Type{DifferentFrom2PseudoMILPBridge{T, U}}) where {T <: AbstractFloat, U <: Real}
    return [
        (MOI.VectorAffineFunction{T}, CP.AbsoluteValue),
        (MOI.SingleVariable, CP.Strictly{MOI.GreaterThan{U}, U}),
    ]
end

function MOIB.added_constraint_types(::Type{DifferentFrom2PseudoMILPBridge{T, U}}) where {T <: Integer, U <: Real}
    return [
        (MOI.VectorAffineFunction{T}, CP.AbsoluteValue),
        (MOI.SingleVariable, MOI.GreaterThan{U}),
    ]
end

function MOIB.added_constraint_types(::Type{DifferentFrom2PseudoMILPBridge{T, Bool}}) where {T <: Real}
    return [
        (MOI.ScalarAffineFunction{T}, CP.EqualTo{Bool}),
    ]
end

function MOIBC.concrete_bridge_type(
    ::Type{DifferentFrom2PseudoMILPBridge{T}},
    ::Union{Type{MOI.VectorOfVariables}, Type{MOI.VectorAffineFunction{T}}},
    ::Type{CP.DifferentFrom{U}},
) where {T <: Real, U <: Real}
    return DifferentFrom2PseudoMILPBridge{T, U}
end

function MOI.get(::DifferentFrom2PseudoMILPBridge{T, U}, ::MOI.NumberOfVariables) where {T <: Real, U <: Real}
    return 1
end

function MOI.get(::DifferentFrom2PseudoMILPBridge{T, Bool}, ::MOI.NumberOfVariables) where {T <: Real}
    return 0
end

function MOI.get(
    ::DifferentFrom2PseudoMILPBridge{T, U},
    ::MOI.NumberOfConstraints{
        MOI.VectorAffineFunction{T}, CP.AbsoluteValue,
    },
) where {T <: Real, U <: Real}
    return 1
end

function MOI.get(
    ::DifferentFrom2PseudoMILPBridge{T, Bool},
    ::MOI.NumberOfConstraints{
        MOI.VectorAffineFunction{T}, CP.AbsoluteValue,
    },
) where {T <: Real}
    return 0
end

function MOI.get(
    ::DifferentFrom2PseudoMILPBridge{T, U},
    ::MOI.NumberOfConstraints{
        MOI.SingleVariable, CP.Strictly{MOI.GreaterThan{U}, U},
    },
) where {T <: Real, U <: AbstractFloat}
    return 1
end

function MOI.get(
    ::DifferentFrom2PseudoMILPBridge{T, U},
    ::MOI.NumberOfConstraints{
        MOI.SingleVariable, CP.Strictly{MOI.GreaterThan{U}, U},
    },
) where {T <: Real, U <: Real}
    return 0
end

function MOI.get(
    ::DifferentFrom2PseudoMILPBridge{T, U},
    ::MOI.NumberOfConstraints{
        MOI.SingleVariable, MOI.GreaterThan{U},
    },
) where {T <: Real, U <: Real}
    return 0
end

function MOI.get(
    ::DifferentFrom2PseudoMILPBridge{T, U},
    ::MOI.NumberOfConstraints{
        MOI.SingleVariable, MOI.GreaterThan{U},
    },
) where {T <: Real, U <: Integer}
    return 1
end

function MOI.get(
    ::DifferentFrom2PseudoMILPBridge{T, Bool},
    ::MOI.NumberOfConstraints{
        MOI.SingleVariable, MOI.GreaterThan{Bool},
    },
) where {T <: Real}
    return 0
end

function MOI.get(
    ::DifferentFrom2PseudoMILPBridge{T, U},
    ::MOI.NumberOfConstraints{
        MOI.ScalarAffineFunction{T}, MOI.EqualTo{U},
    },
) where {T <: Real, U <: Real}
    return 0
end

function MOI.get(
    ::DifferentFrom2PseudoMILPBridge{T, Bool},
    ::MOI.NumberOfConstraints{
        MOI.ScalarAffineFunction{T}, MOI.EqualTo{Bool},
    },
) where {T <: Real}
    return 0
end

function MOI.get(
    b::DifferentFrom2PseudoMILPBridge{T, U},
    ::MOI.ListOfConstraintIndices{
        MOI.VectorAffineFunction{T}, CP.AbsoluteValue,
    },
) where {T <: Real, U <: Real}
    return b.con_abs === nothing ? 
        Vector{MOI.ConstraintIndex{MOI.VectorAffineFunction{T}, CP.AbsoluteValue}}[] :
        [b.con_abs]
end

function MOI.get(
    b::DifferentFrom2PseudoMILPBridge{T, U},
    ::MOI.ListOfConstraintIndices{
        MOI.SingleVariable, CP.Strictly{MOI.GreaterThan{U}, U},
    },
) where {T <: Real, U <: Real}
    return b.con_abs === nothing ? 
        Vector{MOI.ConstraintIndex{MOI.SingleVariable, CP.Strictly{MOI.GreaterThan{U}, U}}}[] :
        [b.con_abs_strictly]
end

function MOI.get(
    b::DifferentFrom2PseudoMILPBridge{T, U},
    ::MOI.ListOfConstraintIndices{
        MOI.SingleVariable, MOI.GreaterThan{U},
    },
) where {T <: Real, U <: Real}
    return b.con_abs === nothing ? 
        Vector{MOI.ConstraintIndex{MOI.SingleVariable, MOI.GreaterThan{U}}}[] :
        [b.con_abs_gt]
end

function MOI.get(
    b::DifferentFrom2PseudoMILPBridge{T, U},
    ::MOI.ListOfConstraintIndices{
        MOI.ScalarAffineFunction{T}, MOI.EqualTo{U},
    },
) where {T <: Real, U <: Real}
    return b.con_abs === nothing ? 
        Vector{MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.EqualTo{U}}}[] :
        [b.con_eq]
end
