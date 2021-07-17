"""
Bridges `CP.AllDifferentExceptConstants` to reifications.
"""
struct AllDifferentExceptConstants2ReificationBridge{T} <: MOIBC.AbstractBridge
    vars_compare::Matrix{MOI.VariableIndex} # First index: value in the array; second index: excepted variable
    vars_compare_bin::Matrix{MOI.ConstraintIndex{MOI.SingleVariable, MOI.ZeroOne}}
    cons_compare_reif::Matrix{MOI.ConstraintIndex{MOI.VectorAffineFunction{T}, CP.Reification{MOI.EqualTo{T}}}}
    # An upper-triangular matrix (i.e. nothing if i < j, constraint if i >= j).
    # Standard sparse matrices cannot store anything that is not a Number 
    # (more specifically, anything that does not implement `zero(T)`).
    # https://github.com/JuliaLang/julia/issues/30573
    vars_different::Dict{Tuple{Int, Int}, MOI.VariableIndex}
    vars_different_bin::Dict{
        Tuple{Int, Int},
        MOI.ConstraintIndex{MOI.SingleVariable, MOI.ZeroOne},
    }
    cons_different_reif::Dict{
        Tuple{Int, Int},
        MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, CP.Reification{CP.DifferentFrom{T}}},
    }
    cons::Dict{
        Tuple{Int, Int},
        MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.GreaterThan{T}},
    }
end

function MOIBC.bridge_constraint(
    ::Type{AllDifferentExceptConstants2ReificationBridge{T}},
    model,
    f::MOI.VectorOfVariables,
    s::CP.AllDifferentExceptConstants{T},
) where {T}
    return MOIBC.bridge_constraint(
        AllDifferentExceptConstants2ReificationBridge{T},
        model,
        MOI.VectorAffineFunction{T}(f),
        s,
    )
end

function MOIBC.bridge_constraint(
    ::Type{AllDifferentExceptConstants2ReificationBridge{T}},
    model,
    f::MOI.VectorAffineFunction{T},
    s::CP.AllDifferentExceptConstants{T},
) where {T}
    f_scalars = MOIU.scalarize(f)
    # dim = MOI.output_dimension(f) # TODO: remove everywhere

    values = collect(s.k)

    vars_compare = Matrix{MOI.VariableIndex}(undef, s.dimension, length(values))
    vars_compare_bin = Matrix{MOI.ConstraintIndex{MOI.SingleVariable, MOI.ZeroOne}}(undef, s.dimension, length(values))
    for i in 1:s.dimension
        vars_compare[i, :], vars_compare_bin[i, :] = MOI.add_constrained_variables(model, [MOI.ZeroOne() for _ in 1:s.length(values)])
    end

    # Upper-triangular matrix of constraints: i >= j, i.e. d(d-1)/2 elements:
    #     \sum_{i=2}^{d} (n - i + 1) = d (d - 1) / 2
    vars_different = Dict{Tuple{Int, Int}, MOI.VariableIndex}()
    vars_different_bin = Dict{Tuple{Int, Int}, MOI.ConstraintIndex{MOI.SingleVariable, MOI.ZeroOne}}()
    cons_different_reif = Dict{Tuple{Int, Int}, MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, CP.Reification{CP.DifferentFrom{T}}}}()
    cons = Dict{Tuple{Int, Int}, MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.GreaterThan{T}}}()

    sizehint!(vars_different, s.dimension * (s.dimension - 1) / 2)
    sizehint!(vars_different_bin, s.dimension * (s.dimension - 1) / 2)
    sizehint!(cons_different_reif, s.dimension * (s.dimension - 1) / 2)
    sizehint!(cons, s.dimension * (s.dimension - 1) / 2)

    for i in 1:s.dimension
        for j in (i+1):s.dimension
            vars_different[i, j], vars_different_bin[i, j] = MOI.add_constrained_variable(MOI.ZeroOne())
            
            cons_different_reif[i, j] = MOI.add_constraint(
                model,
                f_scalars[i] - f_scalars[j],
                CP.Reification(MOI.DifferentFrom(zero(T))),
            )
            
            cons[i, j] = MOI.add_constraint(
                model,
                sum(vars_compare[i, :]) + sum(vars_compare[j, :]) + vars_different[i, j],
                MOI.GreaterThan(one(T)),
            )
        end
    end

    return AllDifferentExceptConstants2ReificationBridge{T}(vars_compare, vars_compare_bin, cons_compare_reif, vars_different, vars_different_bin, cons_different_reif, cons)
end

function MOI.supports_constraint(
    ::Type{AllDifferentExceptConstants2ReificationBridge{T}},
    ::Union{Type{MOI.VectorOfVariables}, Type{MOI.VectorAffineFunction{T}}},
    ::Type{CP.AllDifferentExceptConstants{T}},
) where {T}
    return true
end

function MOIB.added_constrained_variable_types(::Type{AllDifferentExceptConstants2ReificationBridge{T}}) where {T}
    return Tuple{DataType}[]
end

function MOIB.added_constraint_types(::Type{AllDifferentExceptConstants2ReificationBridge{T}}) where {T}
    return [
        (MOI.VectorAffineFunction{T}, CP.Disjunction),
    ]
end

function MOIBC.concrete_bridge_type(
    ::Type{AllDifferentExceptConstants2ReificationBridge{T}},
    ::Union{Type{MOI.VectorOfVariables}, Type{MOI.VectorAffineFunction{T}}},
    ::Type{CP.AllDifferentExceptConstants{T}},
) where {T}
    return AllDifferentExceptConstants2ReificationBridge{T}
end

function MOI.get(::AllDifferentExceptConstants2ReificationBridge, ::MOI.NumberOfVariables)
    return 0
end

function MOI.get(
    b::AllDifferentExceptConstants2ReificationBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.VectorAffineFunction{T}, CP.Disjunction,
    },
) where {T}
    return length(b.cons)
end

function MOI.get(
    b::AllDifferentExceptConstants2ReificationBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.VectorAffineFunction{T}, CP.Disjunction,
    },
) where {T}
    return collect(values(b.cons))
end
