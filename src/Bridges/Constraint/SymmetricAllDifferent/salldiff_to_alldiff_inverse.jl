"""
Bridges `CP.SymmetricAllDifferent` to `MOI.AllDifferent` and `CP.Inverse`.
"""
struct SymmetricAllDifferent2AllDifferentInverseBridge{T} <: MOIBC.AbstractBridge
    con_all_diff::MOI.ConstraintIndex{MOI.VectorAffineFunction{T}, MOI.AllDifferent}
    con_inverse::MOI.ConstraintIndex{MOI.VectorAffineFunction{T}, CP.Inverse}
end

function MOIBC.bridge_constraint(
    ::Type{SymmetricAllDifferent2AllDifferentInverseBridge{T}},
    model,
    f::MOI.VectorOfVariables,
    s::CP.SymmetricAllDifferent,
) where {T}
    return MOIBC.bridge_constraint(
        SymmetricAllDifferent2AllDifferentInverseBridge{T},
        model,
        MOI.VectorAffineFunction{T}(f),
        s,
    )
end

function MOIBC.bridge_constraint(
    ::Type{SymmetricAllDifferent2AllDifferentInverseBridge{T}},
    model,
    f::MOI.VectorAffineFunction{T},
    s::CP.SymmetricAllDifferent,
) where {T}
    f_scalars = MOIU.scalarize(f)
    dim = MOI.output_dimension(f)

    con_all_diff = MOI.add_constraint(
        model,
        f,
        MOI.AllDifferent(dim)
    )

    con_inverse = MOI.add_constraint(
        model,
        MOIU.vectorize([f_scalars..., f_scalars...]),
        CP.Inverse(dim)
    )

    return SymmetricAllDifferent2AllDifferentInverseBridge(con_all_diff, con_inverse)
end

function MOI.supports_constraint(
    ::Type{SymmetricAllDifferent2AllDifferentInverseBridge{T}},
    ::Union{Type{MOI.VectorOfVariables}, Type{MOI.VectorAffineFunction{T}}},
    ::Type{CP.SymmetricAllDifferent},
) where {T}
    return true
end

function MOIB.added_constrained_variable_types(::Type{SymmetricAllDifferent2AllDifferentInverseBridge{T}}) where {T}
    return Tuple{Type}[]
end

function MOIB.added_constraint_types(::Type{SymmetricAllDifferent2AllDifferentInverseBridge{T}}) where {T}
    return [
        (MOI.VectorAffineFunction{T}, MOI.AllDifferent),
        (MOI.VectorAffineFunction{T}, CP.Inverse),
    ]
end

function MOI.get(
    ::SymmetricAllDifferent2AllDifferentInverseBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.VectorAffineFunction{T}, MOI.AllDifferent,
    },
) where {T}
    return 1
end

function MOI.get(
    ::SymmetricAllDifferent2AllDifferentInverseBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.VectorAffineFunction{T}, CP.Inverse,
    },
) where {T}
    return 1
end

function MOI.get(
    b::SymmetricAllDifferent2AllDifferentInverseBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.VectorAffineFunction{T}, MOI.AllDifferent,
    },
) where {T}
    return [b.con_all_diff]
end

function MOI.get(
    b::SymmetricAllDifferent2AllDifferentInverseBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.VectorAffineFunction{T}, CP.Inverse,
    },
) where {T}
    return [b.con_inverse]
end
