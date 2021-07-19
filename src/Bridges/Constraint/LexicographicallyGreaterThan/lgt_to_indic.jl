# Loosely based on MiniZinc's fzn_lex_lesseq_float for MIP: 
# https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/linear/fzn_lex_lesseq_float.mzn
# Major difference: that reformulation is only for two vectors, 
# this implementation is for an arbitrary number of vectors (there is no 
# dedicated set for just two vectors).

"""
Bridges `CP.LexicographicallyGreaterThan` to indicators.
"""
struct LexicographicallyGreaterThan2IndicatorBridge{T} <: MOIBC.AbstractBridge
    vars_eq::Matrix{MOI.VariableIndex}
    vars_gt::Matrix{MOI.VariableIndex}
    vars_eq_bin::Matrix{MOI.ConstraintIndex{MOI.SingleVariable, MOI.ZeroOne}}
    vars_gt_bin::Matrix{MOI.ConstraintIndex{MOI.SingleVariable, MOI.ZeroOne}}
    cons_one_gt::Vector{MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.LessThan{T}}}
    cons_move::Matrix{MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}}}
    cons_indic_eq::Matrix{MOI.ConstraintIndex{MOI.VectorAffineFunction{T}, MOI.IndicatorSet{MOI.ACTIVATE_ON_ONE, MOI.EqualTo{T}}}}
    cons_indic_gt::Matrix{MOI.ConstraintIndex{MOI.VectorAffineFunction{T}, MOI.IndicatorSet{MOI.ACTIVATE_ON_ONE, MOI.GreaterThan{T}}}}
end

function MOIBC.bridge_constraint(
    ::Type{LexicographicallyGreaterThan2IndicatorBridge{T}},
    model,
    f::MOI.VectorOfVariables,
    s::CP.LexicographicallyGreaterThan,
) where {T}
    return MOIBC.bridge_constraint(
        LexicographicallyGreaterThan2IndicatorBridge{T},
        model,
        MOI.VectorAffineFunction{T}(f),
        s,
    )
end

function MOIBC.bridge_constraint(
    ::Type{LexicographicallyGreaterThan2IndicatorBridge{T}},
    model,
    f::MOI.VectorAffineFunction{T},
    s::CP.LexicographicallyGreaterThan,
) where {T}
    @assert s.row_dim >= 1
    @assert s.column_dim >= 2

    vars_eq = Matrix{MOI.VariableIndex}(undef, s.column_dim - 1, s.row_dim)
    vars_gt = Matrix{MOI.VariableIndex}(undef, s.column_dim - 1, s.row_dim)
    vars_eq_bin = Matrix{MOI.ConstraintIndex{MOI.SingleVariable, MOI.ZeroOne}}(undef, s.column_dim - 1, s.row_dim)
    vars_gt_bin = Matrix{MOI.ConstraintIndex{MOI.SingleVariable, MOI.ZeroOne}}(undef, s.column_dim - 1, s.row_dim)
    cons_one_gt = Vector{MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.LessThan{T}}}(undef, s.column_dim - 1)
    cons_move = Matrix{MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}}}(undef, s.column_dim - 1, s.row_dim - 1)
    cons_indic_eq = Matrix{MOI.ConstraintIndex{MOI.VectorAffineFunction{T}, MOI.IndicatorSet{MOI.ACTIVATE_ON_ONE, MOI.EqualTo{T}}}}(undef, s.column_dim - 1, s.row_dim)
    cons_indic_gt = Matrix{MOI.ConstraintIndex{MOI.VectorAffineFunction{T}, MOI.IndicatorSet{MOI.ACTIVATE_ON_ONE, MOI.GreaterThan{T}}}}(undef, s.column_dim - 1, s.row_dim)

    f_scalars = MOIU.scalarize(f)
    f_matrix = reshape(f_scalars, s.column_dim, s.row_dim) 
    # First index: column; second index: row. Rationale: columns are sorted 
    # lexicographically, not rows.

    # Add the constraint between the columns i and i+1.
    for i in 1:(s.column_dim - 1)
        vars_eq[i, :], vars_eq_bin[i, :] = MOI.add_constrained_variables(model, [MOI.ZeroOne() for _ in 1:s.row_dim])
        vars_gt[i, :], vars_gt_bin[i, :] = MOI.add_constrained_variables(model, [MOI.ZeroOne() for _ in 1:s.row_dim])

        cons_one_gt[i] = MOI.add_constraint(
            model,
            sum(one(T) .* MOI.SingleVariable.(vars_gt[i, :])),
            MOI.LessThan(one(T)),
        )

        cons_move[i, :] = MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}}[
            MOI.add_constraint(
                model,
                one(T) * MOI.SingleVariable(vars_eq[i, j - 1]) - one(T) * MOI.SingleVariable(vars_eq[i, j]) - one(T) * MOI.SingleVariable(vars_gt[i, j]),
                MOI.EqualTo(zero(T)),
            )            
            for j in 2:s.row_dim
        ]

        cons_indic_eq[i, :] = MOI.ConstraintIndex{MOI.VectorAffineFunction{T}, MOI.IndicatorSet{MOI.ACTIVATE_ON_ONE, MOI.EqualTo{T}}}[
            MOI.add_constraint(
                model,
                MOIU.vectorize(
                    [
                        one(T) * MOI.SingleVariable(vars_eq[i, j]),
                        f_matrix[i, j] - f_matrix[i + 1, j],
                    ]
                ),
                MOI.IndicatorSet{MOI.ACTIVATE_ON_ONE}(MOI.EqualTo(zero(T))),
            )            
            for j in 1:s.row_dim
        ]

        cons_indic_gt[i, :] = MOI.ConstraintIndex{MOI.VectorAffineFunction{T}, MOI.IndicatorSet{MOI.ACTIVATE_ON_ONE, MOI.GreaterThan{T}}}[
            MOI.add_constraint(
                model,
                MOIU.vectorize(
                    [
                        one(T) * MOI.SingleVariable(vars_gt[i, j]),
                        f_matrix[i, j] - f_matrix[i + 1, j],
                    ]
                ),
                MOI.IndicatorSet{MOI.ACTIVATE_ON_ONE}(MOI.GreaterThan(zero(T))),
            )            
            for j in 1:s.row_dim
        ]
    end

    return LexicographicallyGreaterThan2IndicatorBridge(vars_eq, vars_gt, vars_eq_bin, vars_gt_bin, cons_one_gt, cons_move, cons_indic_eq, cons_indic_gt)
end

function MOI.supports_constraint(
    ::Type{LexicographicallyGreaterThan2IndicatorBridge{T}},
    ::Union{Type{MOI.VectorOfVariables}, Type{MOI.VectorAffineFunction{T}}},
    ::Type{CP.LexicographicallyGreaterThan},
) where {T}
    return true
end

function MOIB.added_constrained_variable_types(::Type{LexicographicallyGreaterThan2IndicatorBridge{T}}) where {T}
    return [(MOI.ZeroOne,)]
end

function MOIB.added_constraint_types(::Type{LexicographicallyGreaterThan2IndicatorBridge{T}}) where {T}
    return [
        (MOI.SingleVariable, MOI.ZeroOne),
        (MOI.ScalarAffineFunction{T}, MOI.LessThan{T}),
        (MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}),
        (MOI.VectorAffineFunction{T}, MOI.IndicatorSet{MOI.ACTIVATE_ON_ONE, MOI.EqualTo{T}}),
        (MOI.VectorAffineFunction{T}, MOI.IndicatorSet{MOI.ACTIVATE_ON_ONE, MOI.GreaterThan{T}}),
    ]
end

function MOI.get(b::LexicographicallyGreaterThan2IndicatorBridge{T}, ::MOI.NumberOfVariables) where {T}
    return length(b.vars_eq) + length(b.vars_gt)
end

function MOI.get(
    b::LexicographicallyGreaterThan2IndicatorBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.SingleVariable, MOI.ZeroOne,
    },
) where {T}
    return length(b.vars_eq_bin) + length(b.vars_gt_bin)
end

function MOI.get(
    b::LexicographicallyGreaterThan2IndicatorBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.ScalarAffineFunction{T}, MOI.LessThan{T},
    },
) where {T}
    return length(b.cons_one_gt)
end

function MOI.get(
    b::LexicographicallyGreaterThan2IndicatorBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.ScalarAffineFunction{T}, MOI.EqualTo{T},
    },
) where {T}
    return length(b.cons_move)
end

function MOI.get(
    b::LexicographicallyGreaterThan2IndicatorBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.VectorAffineFunction{T}, MOI.IndicatorSet{MOI.ACTIVATE_ON_ONE, MOI.EqualTo{T}},
    },
) where {T}
    return length(b.cons_indic_eq)
end

function MOI.get(
    b::LexicographicallyGreaterThan2IndicatorBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.VectorAffineFunction{T}, MOI.IndicatorSet{MOI.ACTIVATE_ON_ONE, MOI.GreaterThan{T}},
    },
) where {T}
    return length(b.cons_indic_gt)
end

function MOI.get(b::LexicographicallyGreaterThan2IndicatorBridge{T}, ::MOI.ListOfVariableIndices) where {T}
    return vcat(vec(b.vars_eq), vec(b.vars_gt))
end

function MOI.get(
    b::LexicographicallyGreaterThan2IndicatorBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.SingleVariable, MOI.ZeroOne,
    },
) where {T}
    return vcat(vec(b.vars_eq_bin), vec(b.vars_gt_bin))
end

function MOI.get(
    b::LexicographicallyGreaterThan2IndicatorBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.ScalarAffineFunction{T}, MOI.LessThan{T},
    },
) where {T}
    return copy(b.cons_one_gt)
end

function MOI.get(
    b::LexicographicallyGreaterThan2IndicatorBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.ScalarAffineFunction{T}, MOI.EqualTo{T},
    },
) where {T}
    return vec(b.cons_move)
end

function MOI.get(
    b::LexicographicallyGreaterThan2IndicatorBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.VectorAffineFunction{T}, MOI.IndicatorSet{MOI.ACTIVATE_ON_ONE, MOI.EqualTo{T}},
    },
) where {T}
    return vec(b.cons_indic_eq)
end

function MOI.get(
    b::LexicographicallyGreaterThan2IndicatorBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.VectorAffineFunction{T}, MOI.IndicatorSet{MOI.ACTIVATE_ON_ONE, MOI.GreaterThan{T}},
    },
) where {T}
    return vec(b.cons_indic_gt)
end
