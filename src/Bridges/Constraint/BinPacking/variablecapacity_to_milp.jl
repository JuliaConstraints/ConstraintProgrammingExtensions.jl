"""
Bridges `CP.BinPacking` to a MILP by creating binary variables for the bin 
assignment and MILP constraints.
"""
struct VariableCapacityBinPacking2MILPBridge{T} <: MOIBC.AbstractBridge
    assign_var::Vector{MOI.VariableIndex}
    assign_con::Vector{MOI.ConstraintIndex{MOI.SingleVariable, MOI.Integer}}
    assign_unique::Vector{MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}}}
    assign_number::Vector{MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}}}
    assign_load::Vector{MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.EqualTo{T}}}
    load_capacity::Vector{MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.LessThan{T}}}
end

function MOIBC.bridge_constraint(
    ::Type{VariableCapacityBinPacking2MILPBridge{T}},
    model,
    f::MOI.VectorOfVariables,
    s::CP.FixedCapacityBinPacking{T},
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
    s::CP.FixedCapacityBinPacking{T},
) where {T}
    # Variables in f: 
    # - load (n_bins variables), integer or float
    # - bin capacity (n_bins variables), integer or float
    # - assigned bin (n_items variables), integer
    f_scalars = MOIU.scalarize(f)

    # Add the assignment variables. Indexed first by item, then by bin: 
    # first item, all bins; second item, all bins; etc.
    assign_var, assign_con = MOI.add_constrained_variables(model, [MOI.Integer() for _ in 1:s.n_items * s.n_bins])

    # Each item is assigned to exactly one bin.
    assign_unique = Vector(undef, s.n_items)
    i = 1
    for item in 1:s.n_items
        assign_unique_f = MOI.ScalarAffineFunction(
            MOI.ScalarAffineTerm.(
                ones(T, s.n_bins),
                assign_var[i : (i + s.n_bins - 1)]
            ),
            zero(T)
        )
        i += s.n_bins
        assign_unique[item] = MOI.add_constraint(model, assign_unique_f, MOI.EqualTo(one(T)))
    end

    # Relate the assignment to the number of the bin to which the item is assigned.
    assign_number = Vector(undef, s.n_items)
    i = 1
    for item in 1:s.n_items
        assign_number_f = MOI.ScalarAffineFunction(
            MOI.ScalarAffineTerm.(
                [-one(T), T.(collect(1:s.n_bins))...],
                [f_scalars[s.n_bins + item - 1], assign_var[i : (i + s.n_bins - 1)]...]
            ),
            zero(T)
        )
        i += s.n_bins
        assign_number[item] = MOI.add_constraint(model, assign_number_f, MOI.EqualTo(zero(T)))
    end

    # Relate the assignment to the load.
    assign_load = Vector(undef, s.n_items)
    for bin in 1:s.n_bins
        assign_load_f = MOI.ScalarAffineFunction(
            MOI.ScalarAffineTerm.(
                [-one(T), T.(collect(1:s.n_items))...],
                [f_scalars[bin], assign_var[i : s.n_bins : (i + s.n_bins * (s.n_items - 1))]...]
            ),
            zero(T)
        )
        assign_load[bin] = MOI.add_constraint(model, assign_load_f, MOI.EqualTo(zero(T)))
    end

    # Limit the load to the capacity: load <= capacity, implemented as 
    # (load - capacity) <= 0.
    load_capacity = Vector(undef, s.n_bins)
    for bin in 1:s.n_bins
        load_capacity_f = MOI.ScalarAffineFunction(
            MOI.ScalarAffineTerm.(
                [one(T), -one(T)],
                [f_scalars[bin], f_scalars[s.n_items + bin - 1]]
            ),
            zero(T)
        )
        load_capacity[bin] = MOI.add_constraint(model, load_capacity_f, MOI.LessThan(zero(T)))
    end

    return VariableCapacityBinPacking2MILPBridge(assign_var, assign_con, assign_unique, assign_number, assign_load, load_capacity)
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
) where {T}
    return b.assign_var
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
    return b.load_capacity
end

function MOI.get(
    b::VariableCapacityBinPacking2MILPBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.SingleVariable,
        MOI.ZeroOne,
    },
) where {T}
    return b.assign_con
end
