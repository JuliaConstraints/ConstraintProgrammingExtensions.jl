"""
Bridges `CP.AllDifferent` to a series of `CP.DifferentFrom`.
"""
struct AllDifferent2DifferentFromBridge{T} <: MOIBC.AbstractBridge
    # An upper-triangular matrix (i.e. nothing if i < j, constraint if i >= j).
    cons::SparseMatrixCSC{
        MOI.ConstraintIndex{MOI.VectorAffineFunction{T}, CP.DifferentFrom{T}}, 
        Int,
    }
end

function MOIBC.bridge_constraint(
    ::Type{AllDifferent2DifferentFromBridge{T}},
    model,
    f::MOI.VectorOfVariables,
    s::CP.AllDifferent,
) where {T}
    return MOIBC.bridge_constraint(
        AllDifferent2DifferentFromBridge{T},
        model,
        MOI.VectorAffineFunction{T}(f),
        s,
    )
end

function MOIBC.bridge_constraint(
    ::Type{AllDifferent2DifferentFromBridge{T}},
    model,
    f::MOI.VectorAffineFunction{T},
    s::CP.AllDifferent,
) where {T}
    f_scalars = MOIU.scalarize(f)

    # Upper-triangular matrix of constraints: i >= j.
    cons = spzeros(
        MOI.ConstraintIndex{MOI.VectorAffineFunction{T}, CP.DifferentFrom{T}}, 
        MOI.dimension(f),
        MOI.dimension(f),
    )
    # TODO: use a sizehint!?

    for i in 1:MOI.dimension(f)
        for j in i:MOI.dimension(f)
            cons[i, j] = MOI.add_constraint(
                model,
                MOIU.vectorize([
                    f_scalars[i],
                    f_scalars[j],
                ]),
                CP.DifferentFrom(zero(T))
            )
        end
    end

    return AllDifferent2DifferentFromBridge(cons)
end

function MOI.supports_constraint(
    ::Type{AllDifferent2DifferentFromBridge{T}},
    ::Union{Type{MOI.VectorOfVariables}, Type{MOI.VectorAffineFunction{T}}},
    ::Type{CP.AllDifferent},
) where {T}
    return true
end

function MOIB.added_constrained_variable_types(::Type{AllDifferent2DifferentFromBridge{T}}) where {T}
    return Tuple{DataType}[]
end

function MOIB.added_constraint_types(::Type{AllDifferent2DifferentFromBridge{T}}) where {T}
    return [
        (MOI.VectorAffineFunction{T}, CP.DifferentFrom{T}),
    ]
end

function MOIBC.concrete_bridge_type(
    ::Type{AllDifferent2DifferentFromBridge{T}},
    ::Union{Type{MOI.VectorOfVariables}, Type{MOI.VectorAffineFunction{T}}},
    ::Type{CP.AllDifferent},
) where {T}
    return AllDifferent2DifferentFromBridge{T}
end

function MOI.get(::AllDifferent2DifferentFromBridge, ::MOI.NumberOfVariables)
    return 0
end

function MOI.get(
    b::AllDifferent2DifferentFromBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.VectorAffineFunction{T}, CP.DifferentFrom{T},
    },
) where {T}
    return length(b.cons)
end

function MOI.get(
    b::AllDifferent2DifferentFromBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.VectorAffineFunction{T}, CP.DifferentFrom{T},
    },
) where {T}
    return b.cons
end
