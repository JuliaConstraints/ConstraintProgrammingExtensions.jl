"""
Bridges `CP.CountCompare` to `CP.Count`.
"""
struct CountCompare2CountBridge{T} <: MOIBC.AbstractBridge
    con::MOI.ConstraintIndex{MOI.VectorAffineFunction{T}, CP.Count{MOI.EqualTo{T}}}
end

function MOIBC.bridge_constraint(
    ::Type{CountCompare2CountBridge{T}},
    model,
    f::MOI.VectorOfVariables,
    s::CP.CountCompare,
) where {T}
    return MOIBC.bridge_constraint(
        CountCompare2CountBridge{T},
        model,
        MOI.VectorAffineFunction{T}(f),
        s,
    )
end

function MOIBC.bridge_constraint(
    ::Type{CountCompare2CountBridge{T}},
    model,
    f::MOI.VectorAffineFunction{T},
    s::CP.CountCompare,
) where {T}
    f_scalars = MOIU.scalarize(f)
    con = MOI.add_constraint(
        model,
        MOIU.vectorize(
            [
                f_scalars[1],
                [
                    f_scalars[1 + i] - f_scalars[1 + s.dimension + i]
                    for i in 1:s.dimension
                ]...
            ]
        ),
        CP.Count(s.dimension, MOI.EqualTo(zero(T)))
    )

    return CountCompare2CountBridge(con)
end

function MOI.supports_constraint(
    ::Type{CountCompare2CountBridge{T}},
    ::Union{Type{MOI.VectorOfVariables}, Type{MOI.VectorAffineFunction{T}}},
    ::Type{CP.CountCompare},
) where {T}
    return true
end

function MOIB.added_constrained_variable_types(::Type{CountCompare2CountBridge{T}}) where {T}
    return Tuple{DataType}[]
end

function MOIB.added_constraint_types(::Type{CountCompare2CountBridge{T}}) where {T}
    return [
        (MOI.VectorAffineFunction{T}, CP.Count{MOI.EqualTo{T}}),
    ]
end

function MOI.get(
    ::CountCompare2CountBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.VectorAffineFunction{T}, CP.Count{MOI.EqualTo{T}},
    },
) where {T}
    return 1
end

function MOI.get(
    b::CountCompare2CountBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.VectorAffineFunction{T}, CP.Count{MOI.EqualTo{T}},
    },
) where {T}
    return [b.con]
end
