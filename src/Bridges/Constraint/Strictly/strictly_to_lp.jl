# TODO: find a way to make this a parameter.
_STRICTLY_FLOAT_EPSILON = 1.0e-9

"""
Bridges `CP.Strictly` to linear constraints.
"""
struct Strictly2LPBridge{T} <: MOIBC.AbstractBridge
    con::Union{
        MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.LessThan{T}},
        MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.GreaterThan{T}},
    }
end

function MOIBC.bridge_constraint(
    ::Type{Strictly2LPBridge{T}},
    model,
    f::MOI.SingleVariable,
    s::Union{CP.Strictly{MOI.LessThan{T}, T}, CP.Strictly{MOI.GreaterThan{T}, T}},
) where {T}
    return MOIBC.bridge_constraint(
        Strictly2LPBridge{T},
        model,
        MOI.ScalarAffineFunction{T}(f),
        s,
    )
end

function MOIBC.bridge_constraint(
    ::Type{Strictly2LPBridge{T}},
    model,
    f::MOI.ScalarAffineFunction{T},
    s::CP.Strictly{MOI.LessThan{T}, T},
) where {T <: Real}
    con = MOI.add_constraint(
        model, 
        f,
        MOI.LessThan(s.set.upper - _STRICTLY_FLOAT_EPSILON)
    )

    return Strictly2LPBridge(con)
end

function MOIBC.bridge_constraint(
    ::Type{Strictly2LPBridge{T}},
    model,
    f::MOI.ScalarAffineFunction{T},
    s::CP.Strictly{MOI.LessThan{T}, T},
) where {T <: Integer}
    con = MOI.add_constraint(
        model, 
        f,
        MOI.LessThan(s.set.upper - one(T))
    )

    return Strictly2LPBridge(con)
end

function MOIBC.bridge_constraint(
    ::Type{Strictly2LPBridge{T}},
    model,
    f::MOI.ScalarAffineFunction{T},
    s::CP.Strictly{MOI.GreaterThan{T}, T},
) where {T <: Real}
    con = MOI.add_constraint(
        model, 
        f,
        MOI.GreaterThan(s.set.lower + _STRICTLY_FLOAT_EPSILON)
    )

    return Strictly2LPBridge(con)
end

function MOIBC.bridge_constraint(
    ::Type{Strictly2LPBridge{T}},
    model,
    f::MOI.ScalarAffineFunction{T},
    s::CP.Strictly{MOI.GreaterThan{T}, T},
) where {T <: Integer}
    con = MOI.add_constraint(
        model, 
        f,
        MOI.GreaterThan(s.set.lower + one(T))
    )

    return Strictly2LPBridge(con)
end

function MOI.supports_constraint(
    ::Type{Strictly2LPBridge{T}},
    ::Union{Type{MOI.SingleVariable}, Type{MOI.ScalarAffineFunction{T}}},
    ::Union{Type{CP.Strictly{MOI.LessThan{T}, T}}, Type{CP.Strictly{MOI.GreaterThan{T}, T}}},
) where {T}
    return true
end

function MOIB.added_constrained_variable_types(::Type{Strictly2LPBridge{T}}) where {T}
    return Tuple{Type}[]
end

function MOIB.added_constraint_types(::Type{Strictly2LPBridge{T}}) where {T}
    return [
        (MOI.ScalarAffineFunction{T}, MOI.LessThan{T}),
        (MOI.ScalarAffineFunction{T}, MOI.GreaterThan{T}),
    ]
end

function MOI.get(
    b::Strictly2LPBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.ScalarAffineFunction{T}, MOI.GreaterThan{T},
    },
) where {T}
    return (b.con isa MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.GreaterThan{T}}) ? 1 : 0
end

function MOI.get(
    b::Strictly2LPBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.ScalarAffineFunction{T}, MOI.LessThan{T},
    },
) where {T}
    return (b.con isa MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.LessThan{T}}) ? 1 : 0
end

function MOI.get(
    b::Strictly2LPBridge{T},
    ::Union{
        MOI.ListOfConstraintIndices{
            MOI.ScalarAffineFunction{T}, MOI.GreaterThan{T},
        },
        MOI.ListOfConstraintIndices{
            MOI.ScalarAffineFunction{T}, MOI.LessThan{T},
        },
    }
) where {T}
    return [b.con]
end
