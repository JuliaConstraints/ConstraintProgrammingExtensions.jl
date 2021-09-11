"""
Bridges `CP.BinPacking{CP.FIXED_CAPACITY_BINPACKING}` to `CP.BinPacking{CP.NO_CAPACITY_BINPACKING}` by adding constraints 
on the capacity variables.
"""
struct FixedCapacityBinPacking2BinPackingBridge{T} <: MOIBC.AbstractBridge
    bp::MOI.ConstraintIndex{MOI.VectorAffineFunction{T}, CP.BinPacking{CP.NO_CAPACITY_BINPACKING, T}}
    capa::Vector{MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.LessThan{T}}}
end

function MOIBC.bridge_constraint(
    ::Type{FixedCapacityBinPacking2BinPackingBridge{T}},
    model,
    f::MOI.VectorOfVariables,
    s::CP.BinPacking{CP.FIXED_CAPACITY_BINPACKING, T},
) where {T}
    return MOIBC.bridge_constraint(
        FixedCapacityBinPacking2BinPackingBridge{T},
        model,
        MOI.VectorAffineFunction{T}(f),
        s,
    )
end

function MOIBC.bridge_constraint(
    ::Type{FixedCapacityBinPacking2BinPackingBridge{T}},
    model,
    f::MOI.VectorAffineFunction{T},
    s::CP.BinPacking{CP.FIXED_CAPACITY_BINPACKING, T},
) where {T}
    # Create the simpler BinPacking set.
    bp_set = CP.BinPacking{CP.NO_CAPACITY_BINPACKING}(s.n_bins, s.n_items, s.weights)
    bp = MOI.add_constraint(model, f, bp_set)

    # Add the capacity constraints.
    f_scalars = MOIU.scalarize(f)
    capa = [
        MOI.add_constraint(model, f_scalars[i], MOI.LessThan(s.capacities[i]))
        for i in 1:s.n_bins
    ]

    return FixedCapacityBinPacking2BinPackingBridge(bp, capa)
end

function MOI.supports_constraint(
    ::Type{FixedCapacityBinPacking2BinPackingBridge{T}},
    ::Union{Type{MOI.VectorOfVariables}, Type{MOI.VectorAffineFunction{T}}},
    ::Type{CP.BinPacking{CP.FIXED_CAPACITY_BINPACKING, T}},
) where {T}
    return true
end

function MOIB.added_constrained_variable_types(::Type{<:FixedCapacityBinPacking2BinPackingBridge})
    return Tuple{Type}[]
end

function MOIB.added_constraint_types(::Type{FixedCapacityBinPacking2BinPackingBridge{T}}) where {T}
    return [
        (MOI.VectorAffineFunction{T}, CP.BinPacking{CP.NO_CAPACITY_BINPACKING, T}),
        (MOI.ScalarAffineFunction{T}, MOI.LessThan{T}),
    ]
end

function MOI.get(
    ::FixedCapacityBinPacking2BinPackingBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.VectorAffineFunction{T},
        CP.BinPacking{CP.NO_CAPACITY_BINPACKING, T},
    },
) where {T}
    return 1
end

function MOI.get(
    b::FixedCapacityBinPacking2BinPackingBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.ScalarAffineFunction{T},
        MOI.LessThan{T},
    },
) where {T}
    return length(b.capa)
end

function MOI.get(
    b::FixedCapacityBinPacking2BinPackingBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.VectorAffineFunction{T},
        CP.BinPacking{CP.NO_CAPACITY_BINPACKING, T},
    },
) where {T}
    return [b.bp]
end

function MOI.get(
    b::FixedCapacityBinPacking2BinPackingBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.ScalarAffineFunction{T},
        MOI.LessThan{T},
    },
) where {T}
    return copy(b.capa)
end
