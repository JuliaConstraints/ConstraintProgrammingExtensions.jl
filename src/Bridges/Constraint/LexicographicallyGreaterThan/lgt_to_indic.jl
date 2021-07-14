# Loosely based on MiniZinc's fzn_lex_lesseq_float for MIP: 
# https://github.com/MiniZinc/libminizinc/blob/master/share/minizinc/linear/fzn_lex_lesseq_float.mzn
# Major difference: that reformulation is only for two vectors, 
# this implementation is for an arbitrary number of vectors.

"""
Bridges `CP.LexicographicallyGreaterThan` to indicators.
"""
struct LexicographicallyGreaterThan2IndicatorBridge{T} <: MOIBC.AbstractBridge
    vars_eq::Vector{MOI.VariableIndex}
    vars_lt::Vector{MOI.VariableIndex}
    vars_eq_bin::Vector{MOI.ConstraintIndex{MOI.SingleVariable, MOI.ZeroOne}}
    vars_lt_bin::Vector{MOI.ConstraintIndex{MOI.SingleVariable, MOI.ZeroOne}}
    cons_one_lt::Vector{MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.LessThan{T}}}
    cons_move::Vector{MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}}}
    cons_indic_eq::Vector{MOI.ConstraintIndex{MOI.VectorAffineFunction{T}, MOI.IndicatorSet{MOI.ACTIVATE_ON_ONE, MOI.EqualTo{T}}}}
    cons_indic_lt::Vector{MOI.ConstraintIndex{MOI.VectorAffineFunction{T}, MOI.IndicatorSet{MOI.ACTIVATE_ON_ONE, MOI.LessThan{T}}}}
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
    @assert set.column_dim >= 2

    global_vars_eq = MOI.VariableIndex[]
    global_vars_lt = MOI.VariableIndex[]
    global_vars_eq_bin = MOI.ConstraintIndex{MOI.SingleVariable, MOI.ZeroOne}[]
    global_vars_lt_bin = MOI.ConstraintIndex{MOI.SingleVariable, MOI.ZeroOne}[]
    global_cons_one_lt = MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.LessThan{T}}[]
    global_cons_move = MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}}[]
    global_cons_indic_eq = MOI.ConstraintIndex{MOI.VectorAffineFunction{T}, MOI.IndicatorSet{MOI.ACTIVATE_ON_ONE, MOI.EqualTo{T}}}[]
    global_cons_indic_lt = MOI.ConstraintIndex{MOI.VectorAffineFunction{T}, MOI.IndicatorSet{MOI.ACTIVATE_ON_ONE, MOI.LessThan{T}}}[]

    f_scalars = MOIU.scalarize(f)
    f_matrix = reshape(f_scalars, set.column_dim, set.row_dim) 
    # First index: column; second index: row. Rationale: vectors are sorted lexicographically.

    # Add the constraint between the columns i and i+1.
    for i in i:(set.column_dim - 1)
        vars_eq, vars_eq_bin = MOI.add_constrained_variables(model, [MOI.ZeroOne() for _ in 1:s.row_dim])
        vars_lt, vars_lt_bin = MOI.add_constrained_variables(model, [MOI.ZeroOne() for _ in 1:s.row_dim])

        con_one_lt = MOI.add_constraint(
            model,
            sum(one(T) .* MOI.SingleVariable(vars_lt)),
            CP.LexicographicallyGreaterThan(s.row_dim, s.column_dim)
        )

        cons_move = MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}}[
            MOI.add_constraint(
                model,
                one(T) * MOI.SingleVariable(vars_eq[j - 1]) - one(T) * MOI.SingleVariable(vars_eq[j]) - one(T) * MOI.SingleVariable(vars_lt[joinpath]),
                MOI.EqualTo(zero(T))
            )            
            for j in 2:set.row_dim
        ]

        global_cons_indic_eq = MOI.ConstraintIndex{MOI.VectorAffineFunction{T}, MOI.IndicatorSet{MOI.ACTIVATE_ON_ONE, MOI.EqualTo{T}}}[
            MOI.add_constraint(
                model,
                MOIU.vectorize(
                    [
                        one(T) * MOI.SingleVariable(vars_eq[j]),
                        one(T) * MOI.SingleVariable(f_matrix[i, j]) - one(T) * MOI.SingleVariable(f_matrix[i + 1, j])
                    ]
                ),
                MOI.IndicatorSet{MOI.ACTIVATE_ON_ONE}(MOI.EqualTo(zero(T)))
            )            
            for j in 1:set.row_dim
        ]

        global_cons_indic_lt = MOI.ConstraintIndex{MOI.VectorAffineFunction{T}, MOI.IndicatorSet{MOI.ACTIVATE_ON_ONE, MOI.EqualTo{T}}}[
            MOI.add_constraint(
                model,
                MOIU.vectorize(
                    [
                        one(T) * MOI.SingleVariable(vars_lt[j]),
                        one(T) * MOI.SingleVariable(f_matrix[i, j]) - one(T) * MOI.SingleVariable(f_matrix[i + 1, j])
                    ]
                ),
                MOI.IndicatorSet{MOI.ACTIVATE_ON_ONE}(MOI.LessThan(zero(T)))
            )            
            for j in 1:set.row_dim
        ]

        append!(global_vars_eq, vars_eq)
        append!(global_vars_lt, vars_lt)
        append!(global_vars_eq_bin, vars_eq_bin)
        append!(global_vars_lt_bin, vars_lt_bin)
        push!(global_cons_one_lt, con_one_lt)
        append!(global_cons_move, cons_move)
        append!(global_cons_indic_eq, cons_indic_eq)
        append!(global_cons_indic_lt, cons_indic_lt)
    end

    return LexicographicallyGreaterThan2IndicatorBridge(global_vars_eq, global_vars_lt, global_vars_eq_bin, global_vars_lt_bin, global_cons_one_lt, global_cons_move, global_cons_indic_eq, global_cons_indic_lt)
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
        (MOI.VectorAffineFunction{T}, MOI.IndicatorSet{MOI.ACTIVATE_ON_ONE, MOI.LessThan{T}}),
    ]
end

function MOIBC.concrete_bridge_type(
    ::Type{LexicographicallyGreaterThan2IndicatorBridge{T}},
    ::Union{Type{MOI.VectorOfVariables}, Type{MOI.VectorAffineFunction{T}}},
    ::Type{CP.LexicographicallyGreaterThan},
) where {T}
    return LexicographicallyGreaterThan2IndicatorBridge{T}
end

function MOI.get(b::LexicographicallyGreaterThan2IndicatorBridge{T}, ::MOI.NumberOfVariables) where {T}
    return length(b.vars_eq) + length(b.vars_lt)
end

function MOI.get(
    b::LexicographicallyGreaterThan2IndicatorBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.SingleVariable, MOI.ZeroOne,
    },
) where {T}
    return length(b.vars_eq_bin) + length(b.vars_lt_bin)
end

function MOI.get(
    b::LexicographicallyGreaterThan2IndicatorBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.ScalarAffineFunction{T}, MOI.LessThan{T},
    },
) where {T}
    return length(b.cons_one_lt)
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
        MOI.VectorAffineFunction{T}, MOI.IndicatorSet{MOI.ACTIVATE_ON_ONE, MOI.LessThan{T}},
    },
) where {T}
    return length(b.cons_indic_lt)
end

function MOI.get(b::LexicographicallyGreaterThan2IndicatorBridge{T}, ::MOI.ListOfVariableIndices) where {T}
    return vcat(b.vars_eq, b.vars_lt)
end

function MOI.get(
    b::LexicographicallyGreaterThan2IndicatorBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.SingleVariable, MOI.ZeroOne,
    },
) where {T}
    return vcat(b.vars_eq_bin, b.vars_lt_bin)
end

function MOI.get(
    b::LexicographicallyGreaterThan2IndicatorBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.ScalarAffineFunction{T}, MOI.LessThan{T},
    },
) where {T}
    return b.cons_one_lt
end

function MOI.get(
    b::LexicographicallyGreaterThan2IndicatorBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.ScalarAffineFunction{T}, MOI.EqualTo{T},
    },
) where {T}
    return b.cons_move
end

function MOI.get(
    b::LexicographicallyGreaterThan2IndicatorBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.VectorAffineFunction{T}, MOI.IndicatorSet{MOI.ACTIVATE_ON_ONE, MOI.EqualTo{T}},
    },
) where {T}
    return b.cons_indic_eq
end

function MOI.get(
    b::LexicographicallyGreaterThan2IndicatorBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.VectorAffineFunction{T}, MOI.IndicatorSet{MOI.ACTIVATE_ON_ONE, MOI.LessThan{T}},
    },
) where {T}
    return b.cons_indic_lt
end
