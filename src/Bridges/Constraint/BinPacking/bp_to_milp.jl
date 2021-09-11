"""
Bridges `CP.BinPacking` to a MILP by creating binary variables for the bin 
assignment and MILP constraints.
"""
struct BinPacking2MILPBridge{BPCT, T} <: MOIBC.AbstractBridge
    assign_var::Matrix{MOI.VariableIndex}
    assign_con::Matrix{MOI.ConstraintIndex{MOI.VariableIndex, MOI.ZeroOne}}
    assign_unique::Vector{MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}}}
    assign_number::Vector{MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}}}
    assign_load::Vector{MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}}}
    load_capacity::Vector{MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.LessThan{T}}}
end

function MOIBC.bridge_constraint(
    ::Type{BinPacking2MILPBridge{BPCT, T}},
    model,
    f::MOI.VectorOfVariables,
    s::CP.BinPacking{BPCT, T},
) where {BPCT, T}
    return MOIBC.bridge_constraint(
        BinPacking2MILPBridge{BPCT, T},
        model,
        MOI.VectorAffineFunction{T}(f),
        s,
    )
end

function MOIBC.bridge_constraint(
    ::Type{BinPacking2MILPBridge{BPCT, T}},
    model,
    f::MOI.VectorAffineFunction{T},
    s::CP.BinPacking{BPCT, T},
) where {BPCT, T}
    # Variables in f: 
    # - load (n_bins variables), integer or float
    # - assigned bin (n_items variables), integer
    f_scalars = MOIU.scalarize(f)
    f_load = f_scalars[1:s.n_bins]
    f_capacity = (BPCT == CP.VARIABLE_CAPACITY_BINPACKING) ? f_scalars[(s.n_bins + 1):(2 * s.n_bins)] : MOI.AbstractScalarFunction[]
    f_assigned = (BPCT == CP.VARIABLE_CAPACITY_BINPACKING) ? f_scalars[(2 * s.n_bins + 1):(2 * s.n_bins + s.n_items)] : f_scalars[(s.n_bins + 1):(s.n_bins + s.n_items)]

    # Add the assignment variables. Indexed first by item, then by bin: 
    # first item, all bins; second item, all bins; etc.
    assign_var = Matrix{MOI.VariableIndex}(undef, s.n_items, s.n_bins)
    assign_con = Matrix{MOI.ConstraintIndex{MOI.VariableIndex, MOI.ZeroOne}}(undef, s.n_items, s.n_bins)
    for item in 1:s.n_items
        assign_var[item, :], assign_con[item, :] = MOI.add_constrained_variables(model, [MOI.ZeroOne() for _ in 1:s.n_bins])
    end

    # Each item is assigned to exactly one bin.
    assign_unique = Vector{MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}}}(undef, s.n_items)
    for item in 1:s.n_items
        assign_unique_f = dot(assign_var[item, :], ones(T, s.n_bins))
        assign_unique[item] = MOI.add_constraint(model, assign_unique_f, MOI.EqualTo(one(T)))
    end

    # Relate the assignment to the number of the bin to which the item is assigned.
    assign_number = Vector{MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}}}(undef, s.n_items)
    for item in 1:s.n_items
        assign_number_f = dot(T.(collect(1:s.n_bins)), assign_var[item, :]) - f_assigned[item]
        assign_number[item] = MOI.add_constraint(model, assign_number_f, MOI.EqualTo(zero(T)))
    end

    # Relate the assignment to the load.
    assign_load = Vector{MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}}}(undef, s.n_bins)
    for bin in 1:s.n_bins
        assign_load_f = dot(s.weights, assign_var[:, bin]) - f_load[bin]
        assign_load[bin] = MOI.add_constraint(model, assign_load_f, MOI.EqualTo(zero(T)))
    end

    # Limit the load to the capacity: load <= capacity, implemented as 
    # (load - capacity) <= 0 for a variable capacity.
    load_capacity = if BPCT == CP.FIXED_CAPACITY_BINPACKING
        MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.LessThan{T}}[
            MOI.add_constraint(
                model, 
                f_load[bin], 
                MOI.LessThan(s.capacities[bin])
            )
            for bin in 1:s.n_bins
        ]
    elseif BPCT == CP.VARIABLE_CAPACITY_BINPACKING
        MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.LessThan{T}}[
            MOI.add_constraint(
                model, 
                f_load[bin] - f_capacity[bin], 
                MOI.LessThan(zero(T))
            )
            for bin in 1:s.n_bins
        ]
    else
        MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.LessThan{T}}[]
    end

    return BinPacking2MILPBridge{BPCT, T}(assign_var, assign_con, assign_unique, assign_number, assign_load, load_capacity)
end

function MOI.supports_constraint(
    ::Type{BinPacking2MILPBridge{BPCT, T}},
    ::Union{Type{MOI.VectorOfVariables}, Type{MOI.VectorAffineFunction{T}}},
    ::Type{CP.BinPacking{BPCT, T}},
) where {BPCT, T}
    return true
end

function MOIB.added_constrained_variable_types(::Type{BinPacking2MILPBridge{BPCT, T}}) where {BPCT, T}
    return [(MOI.ZeroOne,)]
end

function MOIB.added_constraint_types(::Type{BinPacking2MILPBridge{BPCT, T}}) where {BPCT, T}
    return [
        (MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}),
        (MOI.ScalarAffineFunction{T}, MOI.LessThan{T}),
    ]
end

function MOIB.added_constraint_types(::Type{BinPacking2MILPBridge{CP.NO_CAPACITY_BINPACKING, T}}) where {T}
    return [
        (MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}),
    ]
end

function MOI.get(b::BinPacking2MILPBridge, ::MOI.NumberOfVariables)
    return length(b.assign_var)
end

function MOI.get(
    b::BinPacking2MILPBridge{BPCT, T},
    ::MOI.NumberOfConstraints{
        MOI.ScalarAffineFunction{T},
        MOI.EqualTo{T},
    },
) where {BPCT, T}
    return length(b.assign_unique) + length(b.assign_number) + length(b.assign_load)
end

function MOI.get(
    b::BinPacking2MILPBridge{BPCT, T},
    ::MOI.NumberOfConstraints{
        MOI.ScalarAffineFunction{T},
        MOI.LessThan{T},
    },
) where {BPCT, T}
    return length(b.load_capacity)
end

function MOI.get(
    b::BinPacking2MILPBridge{BPCT, T},
    ::MOI.NumberOfConstraints{
        MOI.VariableIndex,
        MOI.ZeroOne,
    },
) where {BPCT, T}
    return length(b.assign_con)
end

function MOI.get(
    b::BinPacking2MILPBridge{BPCT, T},
    ::MOI.ListOfVariableIndices,
)::Vector{MOI.VariableIndex} where {BPCT, T}
    return vec(b.assign_var)
end

function MOI.get(
    b::BinPacking2MILPBridge{BPCT, T},
    ::MOI.ListOfConstraintIndices{
        MOI.ScalarAffineFunction{T},
        MOI.EqualTo{T},
    },
) where {BPCT, T}
    return [b.assign_unique..., b.assign_number..., b.assign_load...]
end

function MOI.get(
    b::BinPacking2MILPBridge{BPCT, T},
    ::MOI.ListOfConstraintIndices{
        MOI.ScalarAffineFunction{T},
        MOI.LessThan{T},
    },
) where {BPCT, T}
    return copy(b.load_capacity)
end

function MOI.get(
    b::BinPacking2MILPBridge{BPCT, T},
    ::MOI.ListOfConstraintIndices{
        MOI.VariableIndex,
        MOI.ZeroOne,
    },
)::Vector{MOI.ConstraintIndex{MOI.VariableIndex, MOI.ZeroOne}} where {BPCT, T}
    return vec(b.assign_con)
end
