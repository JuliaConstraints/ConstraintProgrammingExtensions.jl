"""
Bridges `CP.Strictly{CP.DoublyLexicographicallyGreaterThan}` 
to `CP.Strictly{CP.LexicographicallyGreaterThan}`.
"""
struct DoublyStrictlyLexicographicallyLessThan2StrictlyLexicographicallyGreaterThanBridge{T} <: MOIBC.AbstractBridge
    con::MOI.ConstraintIndex{MOI.VectorAffineFunction{T}, CP.Strictly{CP.LexicographicallyGreaterThan, T}} # Columns are lexicographically sorted.
    con_transposed::MOI.ConstraintIndex{MOI.VectorAffineFunction{T}, CP.Strictly{CP.LexicographicallyGreaterThan, T}} # Rows are lexicographically sorted.
end

function MOIBC.bridge_constraint(
    ::Type{DoublyStrictlyLexicographicallyLessThan2StrictlyLexicographicallyGreaterThanBridge{T}},
    model,
    f::MOI.VectorOfVariables,
    s::CP.Strictly{CP.DoublyLexicographicallyGreaterThan, T},
) where {T}
    return MOIBC.bridge_constraint(
        DoublyStrictlyLexicographicallyLessThan2StrictlyLexicographicallyGreaterThanBridge{T},
        model,
        MOI.VectorAffineFunction{T}(f),
        s,
    )
end

function MOIBC.bridge_constraint(
    ::Type{DoublyStrictlyLexicographicallyLessThan2StrictlyLexicographicallyGreaterThanBridge{T}},
    model,
    f::MOI.VectorAffineFunction{T},
    s::CP.Strictly{CP.DoublyLexicographicallyGreaterThan, T},
) where {T}
    # Constraint on columns.
    con = MOI.add_constraint(
        model,
        f,
        CP.Strictly{CP.LexicographicallyGreaterThan, T}(CP.LexicographicallyGreaterThan(s.set.row_dim, s.set.column_dim))
    )

    # Constraint on rows.
    f_scalars = MOIU.scalarize(f)
    f_matrix = reshape(f_scalars, s.set.row_dim, s.set.column_dim)
    f_transposed = MOIU.vectorize(vec(f_matrix)) # vec() does the transposition.

    con_transposed = MOI.add_constraint(
        model, 
        f_transposed,
        CP.Strictly{CP.LexicographicallyGreaterThan, T}(CP.LexicographicallyGreaterThan(s.set.column_dim, s.set.row_dim))
    )

    return DoublyStrictlyLexicographicallyLessThan2StrictlyLexicographicallyGreaterThanBridge(con, con_transposed)
end

function MOI.supports_constraint(
    ::Type{DoublyStrictlyLexicographicallyLessThan2StrictlyLexicographicallyGreaterThanBridge{T}},
    ::Union{Type{MOI.VectorOfVariables}, Type{MOI.VectorAffineFunction{T}}},
    ::Type{CP.Strictly{CP.DoublyLexicographicallyGreaterThan, T}},
) where {T}
    return true
end

function MOIB.added_constrained_variable_types(::Type{DoublyStrictlyLexicographicallyLessThan2StrictlyLexicographicallyGreaterThanBridge{T}}) where {T}
    return Tuple{Type}[]
end

function MOIB.added_constraint_types(::Type{DoublyStrictlyLexicographicallyLessThan2StrictlyLexicographicallyGreaterThanBridge{T}}) where {T}
    return [
        (MOI.VectorAffineFunction{T}, CP.Strictly{CP.LexicographicallyGreaterThan, T}),
    ]
end

function MOI.get(
    ::DoublyStrictlyLexicographicallyLessThan2StrictlyLexicographicallyGreaterThanBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.VectorAffineFunction{T}, CP.Strictly{CP.LexicographicallyGreaterThan, T},
    },
) where {T}
    return 2
end

function MOI.get(
    b::DoublyStrictlyLexicographicallyLessThan2StrictlyLexicographicallyGreaterThanBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.VectorAffineFunction{T}, CP.Strictly{CP.LexicographicallyGreaterThan, T},
    },
) where {T}
    return [b.con, b.con_transposed]
end
