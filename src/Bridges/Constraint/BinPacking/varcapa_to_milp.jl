"""
Bridges `CP.BinPacking` to a MILP by creating binary variables for the bin 
assignment and MILP constraints.
"""
struct VariableCapacityBinPacking2MILPBridge{T} <: MOIBC.AbstractBridge
    assign_var::Matrix{MOI.VariableIndex}
    assign_con::Matrix{MOI.ConstraintIndex{MOI.SingleVariable, MOI.ZeroOne}}
    assign_unique::Vector{MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}}}
    assign_number::Vector{MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}}}
    assign_load::Vector{MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}}}
    load_capacity::Vector{MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.LessThan{T}}}
end

function MOIBC.bridge_constraint(
    ::Type{VariableCapacityBinPacking2MILPBridge{T}},
    model,
    f::MOI.VectorOfVariables,
    s::CP.VariableCapacityBinPacking{T},
) where {T}
    return MOIBC.bridge_constraint(
        VariableCapacityBinPacking2MILPBridge{T},
        model,
        MOI.VectorAffineFunction{T}(f),
        s,
    )
end

function MOIBC.bridge_constraint(
    ::Type{VariableCapacityBinPacking2MILPBridge{T}},
    model,
    f::MOI.VectorAffineFunction{T},
    s::CP.VariableCapacityBinPacking{T},
) where {T}
    # Variables in f: 
    # - load (n_bins variables), integer or float
    # - bin capacity (n_bins variables), integer or float
    # - assigned bin (n_items variables), integer
    f_scalars = MOIU.scalarize(f)

    # Add the assignment variables. Indexed first by item, then by bin: 
    # first item, all bins; second item, all bins; etc.
    assign_var = Matrix{MOI.VariableIndex}(undef, s.n_items, s.n_bins)
    assign_con = Matrix{MOI.ConstraintIndex{MOI.SingleVariable, MOI.ZeroOne}}(undef, s.n_items, s.n_bins)
    for item in 1:s.n_items
        assign_var[item, :], assign_con[item, :] = MOI.add_constrained_variables(model, [MOI.ZeroOne() for _ in 1:s.n_bins])
    end

    # Each item is assigned to exactly one bin.
    assign_unique = Vector{MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}}}(undef, s.n_items)
    for item in 1:s.n_items
        assign_unique_f = cpdot(assign_var[item, :], ones(T, s.n_bins))
        assign_unique[item] = MOI.add_constraint(model, assign_unique_f, MOI.EqualTo(one(T)))
    end

    # Relate the assignment to the number of the bin to which the item is assigned.
    assign_number = Vector{MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}}}(undef, s.n_items)
    for item in 1:s.n_items
        assign_number_f = cpdot(T.(collect(1:s.n_bins)), assign_var[item, :]) - f_scalars[2 * s.n_bins + item]
        assign_number[item] = MOI.add_constraint(model, assign_number_f, MOI.EqualTo(zero(T)))
    end

    # Relate the assignment to the load.
    assign_load = Vector{MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}}}(undef, s.n_bins)
    for bin in 1:s.n_bins
        assign_load_f = cpdot(s.weights, assign_var[:, bin]) - f_scalars[bin]
        assign_load[bin] = MOI.add_constraint(model, assign_load_f, MOI.EqualTo(zero(T)))
    end

    # Limit the load to the capacity: load <= capacity, implemented as 
    # (load - capacity) <= 0.
    load_capacity = Vector{MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.LessThan{T}}}(undef, s.n_bins)
    for bin in 1:s.n_bins
        load_capacity_f = f_scalars[bin] - f_scalars[s.n_bins + bin]
        load_capacity[bin] = MOI.add_constraint(model, load_capacity_f, MOI.LessThan(zero(T)))
    end

    return VariableCapacityBinPacking2MILPBridge(assign_var, assign_con, assign_unique, assign_number, assign_load, load_capacity)
end

function MOI.supports_constraint(
    ::Type{VariableCapacityBinPacking2MILPBridge{T}},
    ::Union{Type{MOI.VectorOfVariables}, Type{MOI.VectorAffineFunction{T}}},
    ::Type{CP.VariableCapacityBinPacking{T}},
) where {T}
    return true
end

function MOIB.added_constrained_variable_types(::Type{<:VariableCapacityBinPacking2MILPBridge})
    return [(MOI.ZeroOne,)]
end

function MOIB.added_constraint_types(::Type{VariableCapacityBinPacking2MILPBridge{T}}) where {T}
    return [
        (MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}),
        (MOI.ScalarAffineFunction{T}, MOI.LessThan{T}),
    ]
end

function MOIBC.concrete_bridge_type(
    ::Type{VariableCapacityBinPacking2MILPBridge{T}},
    ::Union{Type{MOI.VectorOfVariables}, Type{MOI.VectorAffineFunction{T}}},
    ::Type{CP.BinPacking{T}},
) where {T}
    return VariableCapacityBinPacking2MILPBridge{T}
end

function MOI.get(b::VariableCapacityBinPacking2MILPBridge, ::MOI.NumberOfVariables)
    return length(b.assign_var)
end

function MOI.get(
    b::VariableCapacityBinPacking2MILPBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.ScalarAffineFunction{T},
        MOI.EqualTo{T},
    },
) where {T}
    return length(b.assign_unique) + length(b.assign_number) + length(b.assign_load)
end

function MOI.get(
    b::VariableCapacityBinPacking2MILPBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.ScalarAffineFunction{T},
        MOI.LessThan{T},
    },
) where {T}
    return length(b.load_capacity)
end

function MOI.get(
    b::VariableCapacityBinPacking2MILPBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.SingleVariable,
        MOI.ZeroOne,
    },
) where {T}
    return length(b.assign_con)
end

function MOI.get(
    b::VariableCapacityBinPacking2MILPBridge{T},
    ::MOI.ListOfVariableIndices,
)::Vector{MOI.VariableIndex} where {T}
    return vec(b.assign_var)
end

function MOI.get(
    b::VariableCapacityBinPacking2MILPBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.ScalarAffineFunction{T},
        MOI.EqualTo{T},
    },
) where {T}
    return [b.assign_unique..., b.assign_number..., b.assign_load...]
end

function MOI.get(
    b::VariableCapacityBinPacking2MILPBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.ScalarAffineFunction{T},
        MOI.LessThan{T},
    },
) where {T}
    return copy(b.load_capacity)
end

function MOI.get(
    b::VariableCapacityBinPacking2MILPBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.SingleVariable,
        MOI.ZeroOne,
    },
) where {T}
    return copy(b.assign_con)
end
