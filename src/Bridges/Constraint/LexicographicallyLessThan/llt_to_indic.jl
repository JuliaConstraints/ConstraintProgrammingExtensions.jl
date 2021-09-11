# Loosely based on MiniZinc's fzn_lex_lesseq_float for MIP: 
# https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/linear/fzn_lex_lesseq_float.mzn
# Major difference: that reformulation is only for two vectors, 
# this implementation is for an arbitrary number of vectors (there is no 
# dedicated set for just two vectors).

"""
Bridges `CP.LexicographicallyLessThan` to indicators.
"""
struct LexicographicallyLessThan2IndicatorBridge{T} <: MOIBC.AbstractBridge
    vars_eq::Matrix{MOI.VariableIndex}
    vars_lt::Matrix{MOI.VariableIndex}
    vars_eq_bin::Matrix{MOI.ConstraintIndex{MOI.VariableIndex, MOI.ZeroOne}}
    vars_lt_bin::Matrix{MOI.ConstraintIndex{MOI.VariableIndex, MOI.ZeroOne}}
    cons_one_lt::Vector{MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.LessThan{T}}}
    cons_move::Matrix{MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}}}
    cons_indic_eq::Matrix{MOI.ConstraintIndex{MOI.VectorAffineFunction{T}, MOI.Indicator{MOI.ACTIVATE_ON_ONE, MOI.EqualTo{T}}}}
    cons_indic_lt::Matrix{MOI.ConstraintIndex{MOI.VectorAffineFunction{T}, MOI.Indicator{MOI.ACTIVATE_ON_ONE, MOI.LessThan{T}}}}
end

function MOIBC.bridge_constraint(
    ::Type{LexicographicallyLessThan2IndicatorBridge{T}},
    model,
    f::MOI.VectorOfVariables,
    s::CP.LexicographicallyLessThan,
) where {T}
    return MOIBC.bridge_constraint(
        LexicographicallyLessThan2IndicatorBridge{T},
        model,
        MOI.VectorAffineFunction{T}(f),
        s,
    )
end

function MOIBC.bridge_constraint(
    ::Type{LexicographicallyLessThan2IndicatorBridge{T}},
    model,
    f::MOI.VectorAffineFunction{T},
    s::CP.LexicographicallyLessThan,
) where {T}
    @assert s.row_dim >= 1
    @assert s.column_dim >= 2

    vars_eq = Matrix{MOI.VariableIndex}(undef, s.column_dim - 1, s.row_dim)
    vars_lt = Matrix{MOI.VariableIndex}(undef, s.column_dim - 1, s.row_dim)
    vars_eq_bin = Matrix{MOI.ConstraintIndex{MOI.VariableIndex, MOI.ZeroOne}}(undef, s.column_dim - 1, s.row_dim)
    vars_lt_bin = Matrix{MOI.ConstraintIndex{MOI.VariableIndex, MOI.ZeroOne}}(undef, s.column_dim - 1, s.row_dim)
    cons_one_lt = Vector{MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.LessThan{T}}}(undef, s.column_dim - 1)
    cons_move = Matrix{MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}}}(undef, s.column_dim - 1, s.row_dim - 1)
    cons_indic_eq = Matrix{MOI.ConstraintIndex{MOI.VectorAffineFunction{T}, MOI.Indicator{MOI.ACTIVATE_ON_ONE, MOI.EqualTo{T}}}}(undef, s.column_dim - 1, s.row_dim)
    cons_indic_lt = Matrix{MOI.ConstraintIndex{MOI.VectorAffineFunction{T}, MOI.Indicator{MOI.ACTIVATE_ON_ONE, MOI.LessThan{T}}}}(undef, s.column_dim - 1, s.row_dim)

    f_scalars = MOIU.scalarize(f)
    f_matrix = reshape(f_scalars, s.column_dim, s.row_dim) 
    # First index: column; second index: row. Rationale: columns are sorted 
    # lexicographically, not rows.

    # Add the constraint between the columns i and i+1.
    for i in 1:(s.column_dim - 1)
        vars_eq[i, :], vars_eq_bin[i, :] = MOI.add_constrained_variables(model, [MOI.ZeroOne() for _ in 1:s.row_dim])
        vars_lt[i, :], vars_lt_bin[i, :] = MOI.add_constrained_variables(model, [MOI.ZeroOne() for _ in 1:s.row_dim])

        cons_one_lt[i] = MOI.add_constraint(
            model,
            sum(one(T) .* MOI.VariableIndex.(vars_lt[i, :])),
            MOI.LessThan(one(T)),
        )

        cons_move[i, :] = MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}}[
            MOI.add_constraint(
                model,
                one(T) * vars_eq[i, j - 1] - one(T) * vars_eq[i, j] - one(T) * vars_lt[i, j],
                MOI.EqualTo(zero(T)),
            )            
            for j in 2:s.row_dim
        ]

        cons_indic_eq[i, :] = MOI.ConstraintIndex{MOI.VectorAffineFunction{T}, MOI.Indicator{MOI.ACTIVATE_ON_ONE, MOI.EqualTo{T}}}[
            MOI.add_constraint(
                model,
                MOIU.vectorize(
                    [
                        one(T) * vars_eq[i, j],
                        f_matrix[i, j] - f_matrix[i + 1, j],
                    ]
                ),
                MOI.Indicator{MOI.ACTIVATE_ON_ONE}(MOI.EqualTo(zero(T))),
            )            
            for j in 1:s.row_dim
        ]

        cons_indic_lt[i, :] = MOI.ConstraintIndex{MOI.VectorAffineFunction{T}, MOI.Indicator{MOI.ACTIVATE_ON_ONE, MOI.LessThan{T}}}[
            MOI.add_constraint(
                model,
                MOIU.vectorize(
                    [
                        one(T) * vars_lt[i, j],
                        f_matrix[i, j] - f_matrix[i + 1, j],
                    ]
                ),
                MOI.Indicator{MOI.ACTIVATE_ON_ONE}(MOI.LessThan(zero(T))),
            )            
            for j in 1:s.row_dim
        ]
    end

    return LexicographicallyLessThan2IndicatorBridge(vars_eq, vars_lt, vars_eq_bin, vars_lt_bin, cons_one_lt, cons_move, cons_indic_eq, cons_indic_lt)
end

function MOI.supports_constraint(
    ::Type{LexicographicallyLessThan2IndicatorBridge{T}},
    ::Union{Type{MOI.VectorOfVariables}, Type{MOI.VectorAffineFunction{T}}},
    ::Type{CP.LexicographicallyLessThan},
) where {T}
    return true
end

function MOIB.added_constrained_variable_types(::Type{LexicographicallyLessThan2IndicatorBridge{T}}) where {T}
    return [(MOI.ZeroOne,)]
end

function MOIB.added_constraint_types(::Type{LexicographicallyLessThan2IndicatorBridge{T}}) where {T}
    return [
        (MOI.ScalarAffineFunction{T}, MOI.LessThan{T}),
        (MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}),
        (MOI.VectorAffineFunction{T}, MOI.Indicator{MOI.ACTIVATE_ON_ONE, MOI.EqualTo{T}}),
        (MOI.VectorAffineFunction{T}, MOI.Indicator{MOI.ACTIVATE_ON_ONE, MOI.LessThan{T}}),
    ]
end

function MOI.get(b::LexicographicallyLessThan2IndicatorBridge{T}, ::MOI.NumberOfVariables) where {T}
    return length(b.vars_eq) + length(b.vars_lt)
end

function MOI.get(
    b::LexicographicallyLessThan2IndicatorBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.VariableIndex, MOI.ZeroOne,
    },
) where {T}
    return length(b.vars_eq_bin) + length(b.vars_lt_bin)
end

function MOI.get(
    b::LexicographicallyLessThan2IndicatorBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.ScalarAffineFunction{T}, MOI.LessThan{T},
    },
) where {T}
    return length(b.cons_one_lt)
end

function MOI.get(
    b::LexicographicallyLessThan2IndicatorBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.ScalarAffineFunction{T}, MOI.EqualTo{T},
    },
) where {T}
    return length(b.cons_move)
end

function MOI.get(
    b::LexicographicallyLessThan2IndicatorBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.VectorAffineFunction{T}, MOI.Indicator{MOI.ACTIVATE_ON_ONE, MOI.EqualTo{T}},
    },
) where {T}
    return length(b.cons_indic_eq)
end

function MOI.get(
    b::LexicographicallyLessThan2IndicatorBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.VectorAffineFunction{T}, MOI.Indicator{MOI.ACTIVATE_ON_ONE, MOI.LessThan{T}},
    },
) where {T}
    return length(b.cons_indic_lt)
end

function MOI.get(b::LexicographicallyLessThan2IndicatorBridge{T}, ::MOI.ListOfVariableIndices) where {T}
    return vcat(vec(b.vars_eq), vec(b.vars_lt))
end

function MOI.get(
    b::LexicographicallyLessThan2IndicatorBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.VariableIndex, MOI.ZeroOne,
    },
) where {T}
    return vcat(vec(b.vars_eq_bin), vec(b.vars_lt_bin))
end

function MOI.get(
    b::LexicographicallyLessThan2IndicatorBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.ScalarAffineFunction{T}, MOI.LessThan{T},
    },
) where {T}
    return copy(b.cons_one_lt)
end

function MOI.get(
    b::LexicographicallyLessThan2IndicatorBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.ScalarAffineFunction{T}, MOI.EqualTo{T},
    },
) where {T}
    return vec(b.cons_move)
end

function MOI.get(
    b::LexicographicallyLessThan2IndicatorBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.VectorAffineFunction{T}, MOI.Indicator{MOI.ACTIVATE_ON_ONE, MOI.EqualTo{T}},
    },
) where {T}
    return vec(b.cons_indic_eq)
end

function MOI.get(
    b::LexicographicallyLessThan2IndicatorBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.VectorAffineFunction{T}, MOI.Indicator{MOI.ACTIVATE_ON_ONE, MOI.LessThan{T}},
    },
) where {T}
    return vec(b.cons_indic_lt)
end
