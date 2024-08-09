"""
Bridges `CP.AllDifferent` to a series of `CP.DifferentFrom`.
"""
struct AllDifferent2DifferentFromBridge{T} <: MOIBC.AbstractBridge
    # An upper-triangular matrix (i.e. nothing if i < j, constraint if i >= j).
    # Standard sparse matrices cannot store anything that is not a Number 
    # (more specifically, anything that does not implement `zero(T)`).
    # https://github.com/JuliaLang/julia/issues/30573
    cons::Dict{
        Tuple{Int, Int},
        MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, CP.DifferentFrom{T}}, 
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
    dim = MOI.output_dimension(f)

    # Upper-triangular matrix of constraints: i >= j, i.e. d(d-1)/2 elements:
    #     \sum_{i=2}^{d} (n - i + 1) = d (d - 1) / 2
    cons = Dict{
        Tuple{Int, Int},
        MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, CP.DifferentFrom{T}}, 
    }()
    sizehint!(cons, div(dim * (dim - 1), 2))

    for i in 1:dim
        for j in (i+1):dim
            cons[i, j] = MOI.add_constraint(
                model,
                f_scalars[i] - f_scalars[j],
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
    return Tuple{Type}[]
end

function MOIB.added_constraint_types(::Type{AllDifferent2DifferentFromBridge{T}}) where {T}
    return [
        (MOI.ScalarAffineFunction{T}, CP.DifferentFrom{T}),
    ]
end

function MOI.get(
    b::AllDifferent2DifferentFromBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.ScalarAffineFunction{T}, CP.DifferentFrom{T},
    },
) where {T}
    return length(b.cons)
end

function MOI.get(
    b::AllDifferent2DifferentFromBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.ScalarAffineFunction{T}, CP.DifferentFrom{T},
    },
) where {T}
    return collect(values(b.cons))
end
