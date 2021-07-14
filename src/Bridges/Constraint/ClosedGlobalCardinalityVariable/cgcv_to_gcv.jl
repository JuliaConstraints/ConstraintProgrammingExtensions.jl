"""
Bridges `CP.ClosedGlobalCardinalityVariable` to `CP.GlobalCardinalityVariable`.
"""
struct ClosedGlobalCardinalityVariable2GlobalCardinalityVariableBridge{T} <: MOIBC.AbstractBridge
    cons_domain::Vector{MOI.ConstraintIndex{MOI.VectorAffineFunction{T}, CP.Membership}}
    con_gcv::MOI.ConstraintIndex{MOI.VectorAffineFunction{T}, CP.GlobalCardinalityVariable}
end

function MOIBC.bridge_constraint(
    ::Type{ClosedGlobalCardinalityVariable2GlobalCardinalityVariableBridge{T}},
    model,
    f::MOI.VectorOfVariables,
    s::CP.ClosedGlobalCardinalityVariable,
) where {T}
    return MOIBC.bridge_constraint(
        ClosedGlobalCardinalityVariable2GlobalCardinalityVariableBridge{T},
        model,
        MOI.VectorAffineFunction{T}(f),
        s,
    )
end

function MOIBC.bridge_constraint(
    ::Type{ClosedGlobalCardinalityVariable2GlobalCardinalityVariableBridge{T}},
    model,
    f::MOI.VectorAffineFunction{T},
    s::CP.ClosedGlobalCardinalityVariable,
) where {T}
    f_scalars = MOIU.scalarize(f)
    f_sought = f_scalars[(s.dimension + s.n_values + 1):(s.dimension + 2 * s.n_values)]

    cons_domain = MOI.ConstraintIndex{MOI.VectorAffineFunction{T}, CP.Membership}[
        MOI.add_constraint(
            model,
            MOIU.vectorize(
                [
                    f_scalars[i],
                    f_sought...
                ]
            ),
            CP.Membership(s.n_values),
        ) 
        for i in 1:s.dimension
    ]

    con_gcv = MOI.add_constraint(
        model,
        f,
        CP.GlobalCardinalityVariable(s.dimension, s.n_values),
    )

    return ClosedGlobalCardinalityVariable2GlobalCardinalityVariableBridge(cons_domain, con_gcv)
end

function MOI.supports_constraint(
    ::Type{ClosedGlobalCardinalityVariable2GlobalCardinalityVariableBridge{T}},
    ::Union{Type{MOI.VectorOfVariables}, Type{MOI.VectorAffineFunction{T}}},
    ::Type{CP.ClosedGlobalCardinalityVariable},
) where {T}
    return true
end

function MOIB.added_constrained_variable_types(::Type{ClosedGlobalCardinalityVariable2GlobalCardinalityVariableBridge{T}}) where {T}
    return Tuple{DataType}[]
end

function MOIB.added_constraint_types(::Type{ClosedGlobalCardinalityVariable2GlobalCardinalityVariableBridge{T}}) where {T}
    return [
        (MOI.VectorAffineFunction{T}, CP.Membership),
        (MOI.VectorAffineFunction{T}, CP.GlobalCardinalityVariable),
    ]
end

function MOIBC.concrete_bridge_type(
    ::Type{ClosedGlobalCardinalityVariable2GlobalCardinalityVariableBridge{T}},
    ::Union{Type{MOI.VectorOfVariables}, Type{MOI.VectorAffineFunction{T}}},
    ::Type{CP.ClosedGlobalCardinalityVariable},
) where {T}
    return ClosedGlobalCardinalityVariable2GlobalCardinalityVariableBridge{T}
end

function MOI.get(::ClosedGlobalCardinalityVariable2GlobalCardinalityVariableBridge{T}, ::MOI.NumberOfVariables) where {T}
    return 0
end

function MOI.get(
    b::ClosedGlobalCardinalityVariable2GlobalCardinalityVariableBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.VectorAffineFunction{T}, CP.Membership,
    },
) where {T}
    return length(b.cons_domain)
end

function MOI.get(
    ::ClosedGlobalCardinalityVariable2GlobalCardinalityVariableBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.VectorAffineFunction{T}, CP.GlobalCardinalityVariable,
    },
) where {T}
    return 1
end

function MOI.get(
    b::ClosedGlobalCardinalityVariable2GlobalCardinalityVariableBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.VectorAffineFunction{T}, CP.Membership,
    },
) where {T}
    return b.cons_domain
end

function MOI.get(
    b::ClosedGlobalCardinalityVariable2GlobalCardinalityVariableBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.VectorAffineFunction{T}, CP.GlobalCardinalityVariable,
    },
) where {T}
    return [b.con_gcv]
end
