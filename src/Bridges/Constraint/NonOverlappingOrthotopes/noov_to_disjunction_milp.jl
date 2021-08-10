"""
Bridges `CP.NonOverlappingOrthotopes` to `CP.Disjunction` of linear 
inequations (`MOI.LessThan{T}`).

Variable number of constraints in the disjunction (two per dimension).
"""
struct NonOverlappingOrthotopes2DisjunctionLPBridge{T} <: MOIBC.AbstractBridge
    cons_disjunction::Dict{NTuple{2, Int}, MOI.ConstraintIndex{MOI.VectorAffineFunction{T}, CP.Disjunction{NTuple{n, MOI.LessThan{T}}}}} where n
    cons_ends::Dict{NTuple{2, Int}, MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}}}
end

function MOIBC.bridge_constraint(
    ::Type{NonOverlappingOrthotopes2DisjunctionLPBridge{T}},
    model,
    f::MOI.VectorOfVariables,
    s::CP.NonOverlappingOrthotopes{CP.UNCONDITIONAL_NONVERLAPPING_ORTHOTOPES}
) where {T}
    return MOIBC.bridge_constraint(
        NonOverlappingOrthotopes2DisjunctionLPBridge{T},
        model,
        MOI.VectorAffineFunction{T}(f),
        s,
    )
end

function MOIBC.bridge_constraint(
    ::Type{NonOverlappingOrthotopes2DisjunctionLPBridge{T}},
    model,
    f::MOI.VectorAffineFunction{T},
    s::CP.NonOverlappingOrthotopes{CP.UNCONDITIONAL_NONVERLAPPING_ORTHOTOPES}
) where {T}
    f_scalars = MOIU.scalarize(f)
    f_pos = Vector{MOI.ScalarAffineFunction{T}}[
        f_scalars[((1 + 3 * (i - 1)) * s.n_dimensions - s.n_dimensions + 1) : ((1 + 3 * (i - 1)) * s.n_dimensions)]
        for i in 1:s.n_orthotopes
    ]
    f_sze = Vector{MOI.ScalarAffineFunction{T}}[
        f_scalars[((2 + 3 * (i - 1)) * s.n_dimensions - s.n_dimensions + 1) : ((2 + 3 * (i - 1)) * s.n_dimensions)]
        for i in 1:s.n_orthotopes
    ]
    f_end = Vector{MOI.ScalarAffineFunction{T}}[
        f_scalars[((3 + 3 * (i - 1)) * s.n_dimensions - s.n_dimensions + 1) : ((3 + 3 * (i - 1)) * s.n_dimensions)]
        for i in 1:s.n_orthotopes
    ]

    cons_disjunction = Dict{NTuple{2, Int}, MOI.ConstraintIndex{MOI.VectorAffineFunction{T}, CP.Disjunction{NTuple{2 * s.n_dimensions, MOI.LessThan{T}}}}}()
    for i in 1:s.n_orthotopes
        for j in 1:s.n_orthotopes
            if i < j
                cons_disjunction[i, j] = MOI.add_constraint(
                    model, 
                    MOIU.vectorize(
                        vcat([
                            [
                                f_pos[i][d] + f_sze[i][d] - f_pos[j][d],
                                f_pos[j][d] + f_sze[j][d] - f_pos[i][d],
                            ]
                            for d in 1:s.n_dimensions
                        ]...)
                    ),
                    CP.Disjunction(
                        tuple(
                            collect(MOI.LessThan(zero(T)) for _ in 1:(2 * s.n_dimensions))...
                        )
                    )
                )
            end
        end
    end

    cons_ends = Dict{NTuple{2, Int}, MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}}}()
    for i in 1:s.n_orthotopes
        for d in 1:s.n_dimensions
            cons_ends[i, d] = MOI.add_constraint(
                model, 
                f_pos[i][d] + f_sze[i][d] - f_end[i][d],
                MOI.EqualTo(zero(T))
            )
        end
    end

    return NonOverlappingOrthotopes2DisjunctionLPBridge(cons_disjunction, cons_ends)
end

function MOI.supports_constraint(
    ::Type{NonOverlappingOrthotopes2DisjunctionLPBridge{T}},
    ::Union{Type{MOI.VectorOfVariables}, Type{MOI.VectorAffineFunction{T}}},
    ::Type{CP.NonOverlappingOrthotopes{CP.UNCONDITIONAL_NONVERLAPPING_ORTHOTOPES}},
) where {T}
    return true
end

function MOIB.added_constrained_variable_types(::Type{NonOverlappingOrthotopes2DisjunctionLPBridge{T}}) where {T}
    return Tuple{DataType}[]
end

function MOIB.added_constraint_types(::Type{NonOverlappingOrthotopes2DisjunctionLPBridge{T}}) where {T}
    return [
        (MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}),
        # Not enough information in the type to qualify fully the disjunction.
        # (No dimension available in the bridge or constraint type.)
        (MOI.VectorAffineFunction{T}, CP.Disjunction{NTuple{n, MOI.LessThan{T}} where n}),
    ]
end

function MOI.get(
    b::NonOverlappingOrthotopes2DisjunctionLPBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.VectorAffineFunction{T}, CP.Disjunction{NTuple{n, MOI.LessThan{T}} where n},
    },
) where {T}
    return length(b.cons_disjunction)
end

function MOI.get(
    b::NonOverlappingOrthotopes2DisjunctionLPBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.ScalarAffineFunction{T}, MOI.EqualTo{T},
    },
) where {T}
    return length(b.cons_ends)
end

function MOI.get(
    b::NonOverlappingOrthotopes2DisjunctionLPBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.VectorAffineFunction{T}, CP.Disjunction{NTuple{n, MOI.LessThan{T}} where n},
    },
) where {T}
    return collect(values(b.cons_disjunction))
end

function MOI.get(
    b::NonOverlappingOrthotopes2DisjunctionLPBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.ScalarAffineFunction{T}, MOI.EqualTo{T},
    },
) where {T}
    return collect(values(b.cons_ends))
end
