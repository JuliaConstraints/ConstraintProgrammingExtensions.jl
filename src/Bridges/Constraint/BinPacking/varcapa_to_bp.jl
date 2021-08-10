"""
Bridges `CP.BinPacking{CP.VARIABLE_CAPACITY_BINPACKING, T}` to 
`CP.BinPacking{CP.NO_CAPACITY_BINPACKING, T}` by adding constraints on the 
capacity variables.
"""
struct VariableCapacityBinPacking2BinPackingBridge{T} <: MOIBC.AbstractBridge
    bp::MOI.ConstraintIndex{MOI.VectorAffineFunction{T}, CP.BinPacking{CP.NO_CAPACITY_BINPACKING, T}}
    capa::Vector{MOI.ConstraintIndex{MOI.ScalarAffineFunction{T}, MOI.LessThan{T}}}
end

function MOIBC.bridge_constraint(
    ::Type{VariableCapacityBinPacking2BinPackingBridge{T}},
    model,
    f::MOI.VectorOfVariables,
    s::CP.BinPacking{CP.VARIABLE_CAPACITY_BINPACKING, T},
) where {T}
    return MOIBC.bridge_constraint(
        VariableCapacityBinPacking2BinPackingBridge{T},
        model,
        MOI.VectorAffineFunction{T}(f),
        s,
    )
end

function MOIBC.bridge_constraint(
    ::Type{VariableCapacityBinPacking2BinPackingBridge{T}},
    model,
    f::MOI.VectorAffineFunction{T},
    s::CP.BinPacking{CP.VARIABLE_CAPACITY_BINPACKING, T},
) where {T}
    f_scalars = MOIU.scalarize(f)

    # Create the simpler BinPacking set.
    bp_set = CP.BinPacking{CP.NO_CAPACITY_BINPACKING}(s.n_bins, s.n_items, s.weights)
    new_f = MOIU.vectorize([f_scalars[1:s.n_bins]..., f_scalars[(2 * s.n_bins + 1):end]...])
    bp = MOI.add_constraint(model, new_f, bp_set)

    # Add the capacity constraints.
    capa = [
        MOI.add_constraint(model, f_scalars[i] - f_scalars[s.n_bins + i], MOI.LessThan(zero(T)))
        for i in 1:s.n_bins
    ]

    return VariableCapacityBinPacking2BinPackingBridge(bp, capa)
end

function MOI.supports_constraint(
    ::Type{VariableCapacityBinPacking2BinPackingBridge{T}},
    ::Union{Type{MOI.VectorOfVariables}, Type{MOI.VectorAffineFunction{T}}},
    ::Type{CP.BinPacking{CP.VARIABLE_CAPACITY_BINPACKING, T}},
) where {T}
    return true
end

function MOIB.added_constrained_variable_types(::Type{<:VariableCapacityBinPacking2BinPackingBridge})
    return Tuple{DataType}[]
end

function MOIB.added_constraint_types(::Type{VariableCapacityBinPacking2BinPackingBridge{T}}) where {T}
    return [
        (MOI.VectorAffineFunction{T}, CP.BinPacking{CP.NO_CAPACITY_BINPACKING, T}),
        (MOI.ScalarAffineFunction{T}, MOI.LessThan{T}),
    ]
end

MOI.get(b::VariableCapacityBinPacking2BinPackingBridge, ::MOI.NumberOfVariables) = 0

function MOI.get(
    ::VariableCapacityBinPacking2BinPackingBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.VectorAffineFunction{T},
        CP.BinPacking{CP.NO_CAPACITY_BINPACKING, T},
    },
) where {T}
    return 1
end

function MOI.get(
    b::VariableCapacityBinPacking2BinPackingBridge{T},
    ::MOI.NumberOfConstraints{
        MOI.ScalarAffineFunction{T},
        MOI.LessThan{T},
    },
) where {T}
    return length(b.capa)
end

function MOI.get(
    b::VariableCapacityBinPacking2BinPackingBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.VectorAffineFunction{T},
        CP.BinPacking{CP.NO_CAPACITY_BINPACKING, T},
    },
) where {T}
    return [b.bp]
end

function MOI.get(
    b::VariableCapacityBinPacking2BinPackingBridge{T},
    ::MOI.ListOfConstraintIndices{
        MOI.ScalarAffineFunction{T},
        MOI.LessThan{T},
    },
) where {T}
    return copy(b.capa)
end
