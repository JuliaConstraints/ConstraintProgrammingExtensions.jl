"""
Bridges `CP.Strictly{CP.DoublyLexicographicallyLessThan}` to 
`CP.Strictly{CP.LexicographicallyLessThan}`.
"""
struct StrictlyDoublyLexicographicallyLessThan2LexicographicallyLessThanBridge{T} <: MOIBC.AbstractBridge
    con::MOI.ConstraintIndex{MOI.VectorAffineFunction{T}, CP.Strictly{CP.LexicographicallyLessThan, T}} # Columns are lexicographically sorted.
    con_transposed::MOI.ConstraintIndex{MOI.VectorAffineFunction{T}, CP.Strictly{CP.LexicographicallyLessThan, T}} # Rows are lexicographically sorted.
end

function MOIBC.bridge_constraint(
    ::Type{StrictlyDoublyLexicographicallyLessThan2LexicographicallyLessThanBridge{T}},
    model,
    f::MOI.VectorOfVariables,
    s::CP.Strictly{CP.DoublyLexicographicallyLessThan, T},
) where {T}
    return MOIBC.bridge_constraint(
        StrictlyDoublyLexicographicallyLessThan2LexicographicallyLessThanBridge{T},
        model,
        MOI.VectorAffineFunction{T}(f),
        s,
    )
end

function MOIBC.bridge_constraint(
    ::Type{StrictlyDoublyLexicographicallyLessThan2LexicographicallyLessThanBridge{T}},
    model,
    f::MOI.VectorAffineFunction{T},
    s::CP.Strictly{CP.DoublyLexicographicallyLessThan, T},
) where {T}
    # Constraint on columns.
    con = MOI.add_constraint(
        model,
        f,
        CP.Strictly{CP.LexicographicallyLessThan, T}(CP.LexicographicallyLessThan(s.set.row_dim, s.set.column_dim))
    )

    # Constraint on rows.
    f_scalars = MOIU.scalarize(f)
    f_matrix = reshape(f_scalars, s.set.row_dim, s.set.column_dim)
    f_transposed = MOIU.vectorize(vec(f_matrix)) # vec() does the transposition.

    con_transposed = MOI.add_constraint(
        model, 
        f_transposed,
        CP.Strictly{CP.LexicographicallyLessThan, T}(CP.LexicographicallyLessThan(s.set.column_dim, s.set.row_dim))
    )

    return StrictlyDoublyLexicographicallyLessThan2LexicographicallyLessThanBridge(con, con_transposed)
end

function MOI.supports_constraint(
    ::Type{StrictlyDoublyLexicographicallyLessThan2LexicographicallyLessThanBridge{T}},
    ::Union{Type{MOI.VectorOfVariables}, Type{MOI.VectorAffineFunction{T}}},
    ::Type{CP.Strictly{CP.DoublyLexicographicallyLessThan, T}},
) where {T}
    return true
end

function MOIB.added_constrained_variable_types(::Type{StrictlyDoublyLexicographicallyLessThan2LexicographicallyLessThanBridge{T}}) where {T}
    return Tuple{DataType}[]
end

function MOIB.added_constraint_types(::Type{StrictlyDoublyLexicographicallyLessThan2LexicographicallyLessThanBridge{T}}) where {T}
    return [
        (MOI.VectorAffineFunction{T}, CP.Strictly{CP.LexicographicallyLessThan, T}),
    ]
end

function MOIBC.concrete_bridge_type(
    ::Type{StrictlyDoublyLexicographicallyLessThan2LexicographicallyLessThanBridge{T}},
    ::Union{Type{MOI.VectorOfVariables}, Type{MOI.VectorAffineFunction{T}}},
    ::Type{CP.Strictly{CP.DoublyLexicographicallyLessThan, T}},
) where {T}
    return StrictlyDoublyLexicographicallyLessThan2LexicographicallyLessThanBridge{T}
end

function MOI.get(::StrictlyDoublyLexicographicallyLessThan2LexicographicallyLessThanBridge{T}, ::MOI.NumberOfVariables) where {T}
    return 0
end

function MOI.get(
    ::StrictlyDoublyLexicographicallyLessThan2LexicographicallyLessThanBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.VectorAffineFunction{T}, CP.Strictly{CP.LexicographicallyLessThan, T},
    },
) where {T}
    return 2
end

function MOI.get(
    b::StrictlyDoublyLexicographicallyLessThan2LexicographicallyLessThanBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.VectorAffineFunction{T}, CP.Strictly{CP.LexicographicallyLessThan, T},
    },
) where {T}
    return [b.con, b.con_transposed]
end
