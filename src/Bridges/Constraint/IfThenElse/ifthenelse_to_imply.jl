"""
Bridges `CP.IfThenElse` to `CP.Imply`.
"""
struct IfThenElse2ImplyBridge{T} <: MOIBC.AbstractBridge
    con_if::MOI.ConstraintIndex # {MOI.VectorAffineFunction{T}, CP.Imply}
    con_else::MOI.ConstraintIndex # {MOI.VectorAffineFunction{T}, CP.Imply}

    # TODO: why is it necessary?
    function IfThenElse2ImplyBridge(
            con_if::MOI.ConstraintIndex{MOI.VectorAffineFunction{T}, CP.Imply{S1, S2}}, 
            con_else::MOI.ConstraintIndex{MOI.VectorAffineFunction{T}, CP.Imply{S1, S3}},
        ) where {T, S1, S2, S3}
        return new{T}(con_if, con_else)
    end
end

function MOIBC.bridge_constraint(
    ::Type{IfThenElse2ImplyBridge{T}},
    model,
    f::MOI.VectorOfVariables,
    s::CP.IfThenElse{S1, S2, S3},
) where {T, S1, S2, S3}
    return MOIBC.bridge_constraint(
        IfThenElse2ImplyBridge{T},
        model,
        MOI.VectorAffineFunction{T}(f),
        s,
    )
end

function MOIBC.bridge_constraint(
    ::Type{IfThenElse2ImplyBridge{T}},
    model,
    f::MOI.VectorAffineFunction{T},
    s::CP.IfThenElse{S1, S2, S3},
) where {T, S1, S2, S3}
    f_scalars = MOIU.scalarize(f)
    f_condition = f_scalars[1 : MOI.dimension(s.condition)]
    f_true = f_scalars[(MOI.dimension(s.condition) + 1) : (MOI.dimension(s.condition) + MOI.dimension(s.true_constraint))]
    f_false = f_scalars[(MOI.dimension(s.condition) + MOI.dimension(s.true_constraint) + 1) : (MOI.dimension(s.condition) + MOI.dimension(s.true_constraint) + MOI.dimension(s.false_constraint))]

    con_if = MOI.add_constraint(
        model,
        MOIU.vectorize(
            [
                f_condition...,
                f_true...,
            ]
        ),
        CP.Imply(s.condition, s.true_constraint)
    )

    con_else = MOI.add_constraint(
        model,
        MOIU.vectorize(
            [
                f_condition...,
                f_false...,
            ]
        ),
        CP.Imply(s.condition, s.false_constraint)
    )

    return IfThenElse2ImplyBridge(con_if, con_else)
end

function MOI.supports_constraint(
    ::Type{IfThenElse2ImplyBridge{T}},
    ::Union{Type{MOI.VectorOfVariables}, Type{MOI.VectorAffineFunction{T}}},
    ::Type{CP.IfThenElse{S1, S2, S3}},
) where {T, S1, S2, S3}
    return true
end

function MOIB.added_constrained_variable_types(::Type{IfThenElse2ImplyBridge{T}}) where {T}
    return Tuple{DataType}[]
end

function MOIB.added_constraint_types(::Type{IfThenElse2ImplyBridge{T}}) where {T}
    return [
        (MOI.VectorAffineFunction{T}, CP.Imply), # TODO: how to be more precise?
    ]
end

function MOI.get(
    ::IfThenElse2ImplyBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.VectorAffineFunction{T}, CP.Imply,
    },
) where {T}
    return 2
end

function MOI.get(
    b::IfThenElse2ImplyBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.VectorAffineFunction{T}, CP.Imply,
    },
) where {T}
    return [b.con_if, b.con_else]
end
