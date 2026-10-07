# Based on code written by Ole Kröger (@Wikunia).
# https://github.com/Wikunia/ConstraintSolver.jl/blob/0f63f1601f007852d6cc5939ab3768dd4c4b237c/src/MOI_wrapper/Bridges/strictly_greater_than.jl

struct StrictlyLessThan2StrictlyGreaterThanBridge{T <: Real} <: MOIBC.AbstractBridge
    con::MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, CP.Strictly{MOI.GreaterThan{T}, T}}
end

function MOIBC.bridge_constraint(
    ::Type{StrictlyLessThan2StrictlyGreaterThanBridge{T}},
    model,
    f::MOI.VariableIndex,
    s::CP.Strictly{MOI.LessThan{T}, T},
) where {T}
    return MOIBC.bridge_constraint(
        StrictlyLessThan2StrictlyGreaterThanBridge{T},
        model,
        MOI.ScalarAffineFunction{T}(f),
        s,
    )
end

function MOIBC.bridge_constraint(
    ::Type{StrictlyLessThan2StrictlyGreaterThanBridge{T}},
    model,
    f::MOI.ScalarAffineFunction{T},
    s::CP.Strictly{MOI.LessThan{T}, T},
) where {T}
    con = MOI.add_constraint(
        model, 
        -f,
        CP.Strictly(MOI.GreaterThan(- s.set.upper))
    )

    return StrictlyLessThan2StrictlyGreaterThanBridge(con)
end

function MOI.supports_constraint(
    ::Type{StrictlyLessThan2StrictlyGreaterThanBridge{T}},
    ::Union{Type{MOI.VariableIndex}, Type{MOI.ScalarAffineFunction{T}}},
    ::Type{CP.Strictly{MOI.LessThan{T}, T}},
) where {T}
    return true
end

function MOIB.added_constrained_variable_types(::Type{StrictlyLessThan2StrictlyGreaterThanBridge{T}}) where {T}
    return Tuple{Type}[]
end

function MOIB.added_constraint_types(::Type{StrictlyLessThan2StrictlyGreaterThanBridge{T}}) where {T}
    return [
        (MOI.ScalarAffineFunction{T}, CP.Strictly{MOI.GreaterThan{T}, T}),
    ]
end

function MOI.get(
    ::StrictlyLessThan2StrictlyGreaterThanBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.ScalarAffineFunction{T}, CP.Strictly{MOI.GreaterThan{T}, T},
    },
) where {T}
    return 1
end

function MOI.get(
    b::StrictlyLessThan2StrictlyGreaterThanBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.ScalarAffineFunction{T}, CP.Strictly{MOI.GreaterThan{T}, T},
    },
) where {T}
    return [b.con]
end
