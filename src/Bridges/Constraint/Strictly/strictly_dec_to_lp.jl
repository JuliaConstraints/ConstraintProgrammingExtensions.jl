"""
Bridges `CP.Strictly{CP.Decreasing}` to linear constraints.
"""
struct StrictlyDecreasing2LPBridge{T} <: MOIBC.AbstractBridge
    cons::Vector{MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, CP.Strictly{MOI.GreaterThan{T}, T}}}
end

function MOIBC.bridge_constraint(
    ::Type{StrictlyDecreasing2LPBridge{T}},
    model,
    f::MOI.VectorOfVariables,
    s::Union{
        CP.Strictly{CP.Decreasing, T}, 
        CP.Strictly{CP.Decreasing, S}, 
        CP.Strictly{CP.Decreasing}
    },
) where {T, S}
    return MOIBC.bridge_constraint(
        StrictlyDecreasing2LPBridge{T},
        model,
        MOI.VectorAffineFunction{T}(f),
        s,
    )
end

function MOIBC.bridge_constraint(
    ::Type{StrictlyDecreasing2LPBridge{T}},
    model,
    f::MOI.VectorAffineFunction{T},
    s::Union{
        CP.Strictly{CP.Decreasing, T}, 
        CP.Strictly{CP.Decreasing, S}, 
        CP.Strictly{CP.Decreasing}
    },
) where {T, S}
    f_scalars = MOIU.scalarize(f)
    dim = MOI.output_dimension(f)

    cons = MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, CP.Strictly{MOI.GreaterThan{T}, T}}[
        MOI.add_constraint(
            model,
            f_scalars[i] - f_scalars[i + 1],
            CP.Strictly(MOI.GreaterThan(zero(T)))
        )
        for i in 1:(dim - 1)
    ]

    return StrictlyDecreasing2LPBridge(cons)
end

function MOI.supports_constraint(
    ::Type{StrictlyDecreasing2LPBridge{T}},
    ::Union{Type{MOI.VectorOfVariables}, Type{MOI.VectorAffineFunction{T}}},
    ::Union{
        Type{CP.Strictly{CP.Decreasing, T}},
        Type{CP.Strictly{CP.Decreasing, S}},
        Type{CP.Strictly{CP.Decreasing}},
    }
) where {T, S}
    return true
end

function MOIB.added_constrained_variable_types(::Type{StrictlyDecreasing2LPBridge{T}}) where {T}
    return Tuple{DataType}[]
end

function MOIB.added_constraint_types(::Type{StrictlyDecreasing2LPBridge{T}}) where {T}
    return [
        (MOI.ScalarAffineFunction{T}, CP.Strictly{MOI.GreaterThan{T}, T}),
    ]
end

function MOIBC.concrete_bridge_type(
    ::Type{StrictlyDecreasing2LPBridge{T}},
    ::Union{Type{MOI.VectorOfVariables}, Type{MOI.VectorAffineFunction{T}}},
    ::Union{
        Type{CP.Strictly{CP.Decreasing, T}},
        Type{CP.Strictly{CP.Decreasing, S}},
        Type{CP.Strictly{CP.Decreasing}},
    }
) where {T, S}
    return StrictlyDecreasing2LPBridge{T}
end

function MOI.get(::StrictlyDecreasing2LPBridge, ::MOI.NumberOfVariables)
    return 0
end

function MOI.get(
    b::StrictlyDecreasing2LPBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.ScalarAffineFunction{T}, CP.Strictly{MOI.GreaterThan{T}, T},
    },
) where {T}
    return length(b.cons)
end

function MOI.get(
    b::StrictlyDecreasing2LPBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.ScalarAffineFunction{T}, CP.Strictly{MOI.GreaterThan{T}, T},
    },
) where {T}
    return copy(b.cons)
end
