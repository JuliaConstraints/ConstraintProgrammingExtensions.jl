"""
Bridges `CP.Strictly{CP.Increasing}` to linear constraints.
"""
struct StrictlyIncreasing2LPBridge{T} <: MOIBC.AbstractBridge
    cons::Vector{MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, CP.Strictly{MOI.LessThan{T}, T}}}
end

function MOIBC.bridge_constraint(
    ::Type{StrictlyIncreasing2LPBridge{T}},
    model,
    f::MOI.VectorOfVariables,
    s::Union{
        CP.Strictly{CP.Increasing, T}, 
        CP.Strictly{CP.Increasing, S}, 
        CP.Strictly{CP.Increasing}
    },
) where {T, S}
    return MOIBC.bridge_constraint(
        StrictlyIncreasing2LPBridge{T},
        model,
        MOI.VectorAffineFunction{T}(f),
        s,
    )
end

function MOIBC.bridge_constraint(
    ::Type{StrictlyIncreasing2LPBridge{T}},
    model,
    f::MOI.VectorAffineFunction{T},
    s::Union{
        CP.Strictly{CP.Increasing, T}, 
        CP.Strictly{CP.Increasing, S}, 
        CP.Strictly{CP.Increasing}
    },
) where {T, S}
    f_scalars = MOIU.scalarize(f)
    dim = MOI.output_dimension(f)

    cons = MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, CP.Strictly{MOI.LessThan{T}, T}}[
        MOI.add_constraint(
            model,
            f_scalars[i] - f_scalars[i + 1],
            CP.Strictly(MOI.LessThan(zero(T)))
        )
        for i in 1:(dim - 1)
    ]

    return StrictlyIncreasing2LPBridge(cons)
end

function MOI.supports_constraint(
    ::Type{StrictlyIncreasing2LPBridge{T}},
    ::Union{Type{MOI.VectorOfVariables}, Type{MOI.VectorAffineFunction{T}}},
    ::Union{
        Type{CP.Strictly{CP.Increasing, T}},
        Type{CP.Strictly{CP.Increasing, S}},
        Type{CP.Strictly{CP.Increasing}},
    }
) where {T, S}
    return true
end

function MOIB.added_constrained_variable_types(::Type{StrictlyIncreasing2LPBridge{T}}) where {T}
    return Tuple{Type}[]
end

function MOIB.added_constraint_types(::Type{StrictlyIncreasing2LPBridge{T}}) where {T}
    return [
        (MOI.ScalarAffineFunction{T}, CP.Strictly{MOI.LessThan{T}, T}),
    ]
end

function MOI.get(
    b::StrictlyIncreasing2LPBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.ScalarAffineFunction{T}, CP.Strictly{MOI.LessThan{T}, T},
    },
) where {T}
    return length(b.cons)
end

function MOI.get(
    b::StrictlyIncreasing2LPBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.ScalarAffineFunction{T}, CP.Strictly{MOI.LessThan{T}, T},
    },
) where {T}
    return copy(b.cons)
end
