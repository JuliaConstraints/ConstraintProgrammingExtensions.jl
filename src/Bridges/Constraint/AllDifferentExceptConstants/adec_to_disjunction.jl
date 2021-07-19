"""
Bridges `CP.AllDifferentExceptConstants` to a series of `CP.Disjunction`
of `CP.DifferentFrom` and `CP.Domain`.
"""
struct AllDifferentExceptConstants2ConjunctionDisjunctionBridge{T} <: MOIBC.AbstractBridge
    # An upper-triangular matrix (i.e. nothing if i < j, constraint if i >= j).
    # Standard sparse matrices cannot store anything that is not a Number 
    # (more specifically, anything that does not implement `zero(T)`).
    # https://github.com/JuliaLang/julia/issues/30573
    cons::Dict{
        Tuple{Int, Int},
        MOI.ConstraintIndex, # {MOI.VectorAffineFunction{T}, CP.Disjunction{Tuple{CP.Domain{T}, CP.Domain{T}, CP.DifferentFrom{T}}}},
    }
end

function MOIBC.bridge_constraint(
    ::Type{AllDifferentExceptConstants2ConjunctionDisjunctionBridge{T}},
    model,
    f::MOI.VectorOfVariables,
    s::CP.AllDifferentExceptConstants{T},
) where {T}
    return MOIBC.bridge_constraint(
        AllDifferentExceptConstants2ConjunctionDisjunctionBridge{T},
        model,
        MOI.VectorAffineFunction{T}(f),
        s,
    )
end

function MOIBC.bridge_constraint(
    ::Type{AllDifferentExceptConstants2ConjunctionDisjunctionBridge{T}},
    model,
    f::MOI.VectorAffineFunction{T},
    s::CP.AllDifferentExceptConstants{T},
) where {T}
    f_scalars = MOIU.scalarize(f)
    dim = MOI.output_dimension(f)

    # Upper-triangular matrix of constraints: i >= j, i.e. d(d-1)/2 elements:
    #     \sum_{i=2}^{d} (n - i + 1) = d (d - 1) / 2
    cons = Dict{Tuple{Int, Int}, MOI.ConstraintIndex}()
    sizehint!(cons, dim * (dim - 1) / 2)

    for i in 1:dim
        for j in (i+1):dim
            cons[i, j] = MOI.add_constraint(
                model,
                MOIU.vectorize(
                    [
                        f_scalars[i],
                        f_scalars[j],
                        f_scalars[i] - f_scalars[j],
                    ]
                ),
                CP.Disjunction(
                    (
                        CP.Domain(copy(s.k)), # x[i] to ignore
                        CP.Domain(copy(s.k)), # x[j] to ignore
                        CP.DifferentFrom(zero(T)), # x[i] != x[j]
                    )
                ),
            )
        end
    end

    return AllDifferentExceptConstants2ConjunctionDisjunctionBridge{T}(cons)
end

function MOI.supports_constraint(
    ::Type{AllDifferentExceptConstants2ConjunctionDisjunctionBridge{T}},
    ::Union{Type{MOI.VectorOfVariables}, Type{MOI.VectorAffineFunction{T}}},
    ::Type{CP.AllDifferentExceptConstants{T}},
) where {T}
    return true
end

function MOIB.added_constrained_variable_types(::Type{AllDifferentExceptConstants2ConjunctionDisjunctionBridge{T}}) where {T}
    return Tuple{DataType}[]
end

function MOIB.added_constraint_types(::Type{AllDifferentExceptConstants2ConjunctionDisjunctionBridge{T}}) where {T}
    return [
        (MOI.VectorAffineFunction{T}, CP.Disjunction),
    ]
end

function MOI.get(
    b::AllDifferentExceptConstants2ConjunctionDisjunctionBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.VectorAffineFunction{T}, CP.Disjunction,
    },
) where {T}
    return length(b.cons)
end

function MOI.get(
    b::AllDifferentExceptConstants2ConjunctionDisjunctionBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.VectorAffineFunction{T}, CP.Disjunction,
    },
) where {T}
    return collect(values(b.cons))
end
