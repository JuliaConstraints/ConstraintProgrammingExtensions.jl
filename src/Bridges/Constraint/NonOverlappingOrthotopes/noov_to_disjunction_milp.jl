"""
Bridges `CP.NonOverlappingOrthotopes` to `CP.Disjunction` of linear 
inequations (`MOI.LessThan{T}`).

Variable number of constraints in the disjunction (two per dimension).
"""
struct NonOverlappingOrthotopes2DisjunctionLinearBridge{T} <: MOIBC.AbstractBridge
    cons_disjunction::Vector{MOI.ConstraintIndex{MOI.VectorAffineFunction{T}, CP.Disjunction{<: Tuple}}}
    cons_ends::Vector{MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}}}
end

function MOIBC.bridge_constraint(
    ::Type{NonOverlappingOrthotopes2DisjunctionLinearBridge{T}},
    model,
    f::MOI.VectorOfVariables,
    s::CP.NonOverlappingOrthotopes
) where {T}
    return MOIBC.bridge_constraint(
        NonOverlappingOrthotopes2DisjunctionLinearBridge{T},
        model,
        MOI.VectorAffineFunction{T}(f),
        s,
    )
end

function MOIBC.bridge_constraint(
    ::Type{NonOverlappingOrthotopes2DisjunctionLinearBridge{T}},
    model,
    f::MOI.VectorAffineFunction{T},
    s::CP.NonOverlappingOrthotopes
) where {T}
    f_scalars = MOIU.scalarize(f)
    f_orthotopes = MOI.ScalarAffineFunction{T}[
        f_scalars[((i - 1) * 3 * s.n_dimensions + 1) : (i * 3 * s.n_dimensions)]
        for i in 1:s.n_orthotopes
    ]

    cons_disjunction = MOI.ConstraintIndex{MOI.VectorAffineFunction{T}, CP.Disjunction{<: Tuple}}[
        MOI.add_constraint(
            model, 
            MOIU.vectorize(
                vcat([
                    [
                        f_orthotopes[i][d] + f_orthotopes[i][s.n_dimensions + d] - f_orthotopes[j][d],
                        f_orthotopes[j][d] + f_orthotopes[j][s.n_dimensions + d] - f_orthotopes[i][d],
                    ]
                    for d in 1:s.n_dimensions
                ]...)
            ),
            CP.Disjunction(
                tuple(
                    (MOI.LessThan(zero(T)) for _ in 1:(2 * s.n_dimensions))
                )
            )
        )
        for i in 1:s.n_orthotopes, j in 1:s.n_orthotopes if i < j
    ]

    cons_ends = MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}}[
        MOI.add_constraint(
            model, 
            f_orthotopes[i][d] + f_orthotopes[i][s.n_dimensions + d] - f_orthotopes[i][2 * s.n_dimensions + d],
            MOI.EqualTo(zero(T))
        )
        for i in 1:s.n_orthotopes, d in 1:s.n_dimensions
    ]

    return NonOverlappingOrthotopes2DisjunctionLinearBridge(cons_disjunction, cons_ends)
end

function MOI.supports_constraint(
    ::Type{NonOverlappingOrthotopes2DisjunctionLinearBridge{T}},
    ::Union{Type{MOI.VectorOfVariables}, Type{MOI.VectorAffineFunction{T}}},
    ::Type{CP.NonOverlappingOrthotopes},
) where {T}
    return true
end

function MOIB.added_constrained_variable_types(::Type{NonOverlappingOrthotopes2DisjunctionLinearBridge{T}}) where {T}
    return Tuple{DataType}[]
end

function MOIB.added_constraint_types(::Type{NonOverlappingOrthotopes2DisjunctionLinearBridge{T}}) where {T}
    return [
        (MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}),
        # Not enough information in the type to qualify fully the disjunction.
        (MOI.VectorAffineFunction{T}, CP.Disjunction{<: Tuple}),
    ]
end

function MOIBC.concrete_bridge_type(
    ::Type{NonOverlappingOrthotopes2DisjunctionLinearBridge{T}},
    ::Union{Type{MOI.VectorOfVariables}, Type{MOI.VectorAffineFunction{T}}},
    ::Type{CP.NonOverlappingOrthotopes},
) where {T}
    return NonOverlappingOrthotopes2DisjunctionLinearBridge{T}
end

function MOI.get(::NonOverlappingOrthotopes2DisjunctionLinearBridge, ::MOI.NumberOfVariables)
    return 0
end

function MOI.get(
    b::NonOverlappingOrthotopes2DisjunctionLinearBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.VectorAffineFunction{T}, CP.Disjunction{<: Tuple},
    },
) where {T}
    return length(b.cons_disjunction)
end

function MOI.get(
    b::NonOverlappingOrthotopes2DisjunctionLinearBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.ScalarAffineFunction{T}, MOI.EqualTo{T},
    },
) where {T}
    return length(b.cons_ends)
end

function MOI.get(
    b::NonOverlappingOrthotopes2DisjunctionLinearBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.VectorAffineFunction{T}, CP.Disjunction{<: Tuple},
    },
) where {T}
    return b.cons_disjunction
end

function MOI.get(
    b::NonOverlappingOrthotopes2DisjunctionLinearBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.ScalarAffineFunction{T}, MOI.EqualTo{T},
    },
) where {T}
    return b.cons_ends
end
