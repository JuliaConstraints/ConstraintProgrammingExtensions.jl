# Based on code written by Ole Kröger (@Wikunia).
# https://github.com/Wikunia/ConstraintSolver.jl/blob/0f63f1601f007852d6cc5939ab3768dd4c4b237c/src/MOI_wrapper/Bridges/strictly_greater_than.jl

struct StrictlyGreaterThan2StrictlyLessThanBridge{T <: Real} <: MOIBC.AbstractBridge
    con::MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, CP.Strictly{MOI.LessThan{T}, T}}
end

function MOIBC.bridge_constraint(
    ::Type{StrictlyGreaterThan2StrictlyLessThanBridge{T}},
    model,
    f::MOI.VariableIndex,
    s::CP.Strictly{MOI.GreaterThan{T}, T},
) where {T}
    return MOIBC.bridge_constraint(
        StrictlyGreaterThan2StrictlyLessThanBridge{T},
        model,
        MOI.ScalarAffineFunction{T}(f),
        s,
    )
end

function MOIBC.bridge_constraint(
    ::Type{StrictlyGreaterThan2StrictlyLessThanBridge{T}},
    model,
    f::MOI.ScalarAffineFunction{T},
    s::CP.Strictly{MOI.GreaterThan{T}, T},
) where {T}
    con = MOI.add_constraint(
        model, 
        -f,
        CP.Strictly(MOI.LessThan(- s.set.lower))
    )

    return StrictlyGreaterThan2StrictlyLessThanBridge(con)
end

function MOI.supports_constraint(
    ::Type{StrictlyGreaterThan2StrictlyLessThanBridge{T}},
    ::Union{Type{MOI.VariableIndex}, Type{MOI.ScalarAffineFunction{T}}},
    ::Type{CP.Strictly{MOI.GreaterThan{T}, T}},
) where {T}
    return true
end

function MOIB.added_constrained_variable_types(::Type{StrictlyGreaterThan2StrictlyLessThanBridge{T}}) where {T}
    return Tuple{Type}[]
end

function MOIB.added_constraint_types(::Type{StrictlyGreaterThan2StrictlyLessThanBridge{T}}) where {T}
    return [
        (MOI.ScalarAffineFunction{T}, CP.Strictly{MOI.LessThan{T}, T}),
    ]
end

function MOI.get(
    ::StrictlyGreaterThan2StrictlyLessThanBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.ScalarAffineFunction{T}, CP.Strictly{MOI.LessThan{T}, T},
    },
) where {T}
    return 1
end

function MOI.get(
    b::StrictlyGreaterThan2StrictlyLessThanBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.ScalarAffineFunction{T}, CP.Strictly{MOI.LessThan{T}, T},
    },
) where {T}
    return [b.con]
end
