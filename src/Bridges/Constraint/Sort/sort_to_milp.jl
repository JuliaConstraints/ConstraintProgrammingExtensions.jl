"""
Bridges `CP.Sort` to MILP constraints by adding O(n²) binary variables, with a 
transportation-like model.
"""
struct Sort2MILPBridge{T} <: MOIBC.AbstractBridge
    vars_flow::Matrix{MOI.VariableIndex}
    vars_unicity::Matrix{MOI.VariableIndex}
    vars_unicity_bin::Matrix{MOI.ConstraintIndex{MOI.SingleVariable, MOI.ZeroOne}}
    cons_transportation_x::Vector{MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}}}
    cons_transportation_y::Vector{MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}}}
    cons_unicity_x::Vector{MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}}}
    cons_unicity_y::Vector{MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}}}
    cons_flow_gt::Matrix{MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.GreaterThan{T}}}
    cons_flow_lt::Matrix{MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.LessThan{T}}}
    cons_sort::Vector{MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.GreaterThan{T}}}
end

function MOIBC.bridge_constraint(
    ::Type{Sort2MILPBridge{T}},
    model,
    f::MOI.VectorOfVariables,
    s::CP.Sort,
) where {T}
    return MOIBC.bridge_constraint(
        Sort2MILPBridge{T},
        model,
        MOI.VectorAffineFunction{T}(f),
        s,
    )
end

function MOIBC.bridge_constraint(
    ::Type{Sort2MILPBridge{T}},
    model,
    f::MOI.VectorAffineFunction{T},
    s::CP.Sort,
) where {T}
    f_scalars = MOIU.scalarize(f)
    dim = s.dimension
    
    f_sorted = f_scalars[1:dim]
    f_to_sort = f_scalars[(dim + 1):(2 * dim)]

    # For this formulation work, both lower and upper bounds are required on
    # the values of the array to sort.
    for i in 1:dim
        @assert CP.has_lower_bound(model, f_to_sort[i])
        @assert CP.has_upper_bound(model, f_to_sort[i])
    end

    # Create the new variables.
    vars_flow = Matrix{MOI.VariableIndex}(undef, dim, dim)
    vars_unicity = Matrix{MOI.VariableIndex}(undef, dim, dim)
    vars_unicity_bin = Matrix{MOI.ConstraintIndex{MOI.SingleVariable, MOI.ZeroOne}}(undef, dim, dim)
    for i in 1:dim
        vars_flow[i, :] = MOI.add_variables(model, dim)
        vars_unicity[i, :], vars_unicity_bin[i, :] = MOI.add_constrained_variables(model, [MOI.ZeroOne() for _ in 1:dim])
    end

    # Write the transportation equations.
    cons_transportation_x = MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}}[
        MOI.add_constraint(
            model, 
            f_sorted[i] - sum(one(T) .* MOI.SingleVariable.(vars_flow[i, :])),
            MOI.EqualTo(zero(T))
        )
        for i in 1:dim
    ]
    cons_transportation_y = MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}}[
        MOI.add_constraint(
            model, 
            f_to_sort[j] - sum(one(T) .* MOI.SingleVariable.(vars_flow[:, j])),
            MOI.EqualTo(zero(T))
        )
        for j in 1:dim
    ]

    # Unicity constraints, so that only one input and one output contribute to each flow.
    cons_unicity_x = MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}}[
        MOI.add_constraint(
            model, 
            sum(one(T) .* MOI.SingleVariable.(vars_unicity[i, :])),
            MOI.EqualTo(one(T))
        )
        for i in 1:dim
    ]
    cons_unicity_y = MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}}[
        MOI.add_constraint(
            model, 
            sum(one(T) .* MOI.SingleVariable.(vars_unicity[:, j])),
            MOI.EqualTo(one(T))
        )
        for j in 1:dim
    ]

    # Relate flows and unicity.
    cons_flow_gt = Matrix{MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.GreaterThan{T}}}(undef, dim, dim)
    cons_flow_lt = Matrix{MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.LessThan{T}}}(undef, dim, dim)
    for i in 1:dim
        L = T(CP.get_lower_bound(model, f_to_sort[i]))
        U = T(CP.get_upper_bound(model, f_to_sort[i]))

        for j in 1:dim
            cons_flow_gt[i, j] = MOI.add_constraint(
                model, 
                MOI.SingleVariable(vars_flow[i, j]) - U * MOI.SingleVariable(vars_unicity[i, j]),
                MOI.GreaterThan(zero(T))
            )
            cons_flow_lt[i, j] = MOI.add_constraint(
                model, 
                MOI.SingleVariable(vars_flow[i, j]) - L * MOI.SingleVariable(vars_unicity[i, j]),
                MOI.LessThan(zero(T))
            )
        end
    end

    # Ensure that the end array is sorted.
    cons_sort = MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.GreaterThan{T}}[
        MOI.add_constraint(
            model, 
            f_sorted[i] - f_sorted[i + 1],
            MOI.GreaterThan(zero(T))
        )
        for i in 1:(dim - 1)
    ]

    return Sort2MILPBridge(
        vars_flow, 
        vars_unicity, 
        vars_unicity_bin, 
        cons_transportation_x, 
        cons_transportation_y, 
        cons_unicity_x, 
        cons_unicity_y, 
        cons_flow_gt, 
        cons_flow_lt, 
        cons_sort,
    )
end

function MOI.supports_constraint(
    ::Type{Sort2MILPBridge{T}},
    ::Union{Type{MOI.VectorOfVariables}, Type{MOI.VectorAffineFunction{T}}},
    ::Type{CP.Sort},
) where {T}
    return true
end

function MOIB.added_constrained_variable_types(::Type{Sort2MILPBridge{T}}) where {T}
    return [(MOI.ZeroOne,)]
end

function MOIB.added_constraint_types(::Type{Sort2MILPBridge{T}}) where {T}
    return [
        (MOI.SingleVariable, MOI.ZeroOne),
        (MOI.ScalarAffineFunction{T}, MOI.GreaterThan{T}),
        (MOI.ScalarAffineFunction{T}, MOI.LessThan{T}),
        (MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}),
    ]
end

function MOI.get(b::Sort2MILPBridge, ::MOI.NumberOfVariables)
    return length(b.vars_flow) + length(b.vars_unicity)
end

function MOI.get(
    b::Sort2MILPBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.SingleVariable, MOI.ZeroOne,
    },
) where {T}
    return length(b.vars_unicity)
end

function MOI.get(
    b::Sort2MILPBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.ScalarAffineFunction{T}, MOI.GreaterThan{T},
    },
) where {T}
    return length(b.cons_flow_gt) + length(b.cons_sort)
end

function MOI.get(
    b::Sort2MILPBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.ScalarAffineFunction{T}, MOI.LessThan{T},
    },
) where {T}
    return length(b.cons_flow_lt)
end

function MOI.get(
    b::Sort2MILPBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.ScalarAffineFunction{T}, MOI.EqualTo{T},
    },
) where {T}
    return length(b.cons_transportation_x) + length(b.cons_transportation_y) + length(b.cons_unicity_x) + length(b.cons_unicity_y)
end

function MOI.get(
    b::Sort2MILPBridge{T},
    ::MOI.ListOfVariableIndices,
) where {T}
    return vcat(vec(b.vars_flow), vec(b.vars_unicity))
end

function MOI.get(
    b::Sort2MILPBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.SingleVariable, MOI.ZeroOne,
    },
) where {T}
    return copy(b.vars_unicity_bin)
end

function MOI.get(
    b::Sort2MILPBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.ScalarAffineFunction{T}, MOI.GreaterThan{T},
    },
) where {T}
    return vcat(vec(b.cons_flow_gt), b.cons_sort)
end

function MOI.get(
    b::Sort2MILPBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.ScalarAffineFunction{T}, MOI.LessThan{T},
    },
) where {T}
    return vec(b.cons_flow_lt)
end

function MOI.get(
    b::Sort2MILPBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.ScalarAffineFunction{T}, MOI.EqualTo{T},
    },
) where {T}
    return vcat(b.cons_transportation_x, b.cons_transportation_y, b.cons_unicity_x, b.cons_unicity_y)
end
