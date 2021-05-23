"""
    Strictly{S <: Union{LessThan{T}, GreaterThan{T}, LexicographicallyGreaterThan}}

Converts an inequality set to a set with the same inequality made strict.
For example, while `LessThan(1)` corresponds to the inequality `x <= 1`,
`Strictly(LessThan(1))` corresponds to the inequality `x < 1`.

## Example

    x in Strictly(LessThan(1))
"""
struct Strictly{
    S <: Union{
        MOI.LessThan{T} where T,
        MOI.GreaterThan{T} where T,
        LexicographicallyLessThan,
        LexicographicallyGreaterThan,
        Increasing,
        Decreasing,
    },
    T <: Number,
} <: MOI.AbstractScalarSet
    set::S
end

copy(set::Strictly{S}) where {S} = Strictly(copy(set.set))
MOI.constant(set::Strictly{S}) where {S} = MOI.constant(set.set)
MOI.dimension(set::Strictly{S}) where {S} = MOI.dimension(set.set)
function MOIU.shift_constant(set::Strictly{S}, offset::T) where {S, T}
    return typeof(set)(MOIU.shift_constant(set.set, offset))
end

function Strictly(set::LexicographicallyLessThan)
    return Strictly{LexicographicallyLessThan, Int}(set)
end
function Strictly(set::LexicographicallyGreaterThan)
    return Strictly{LexicographicallyGreaterThan, Int}(set)
end
function Strictly(set::MOI.LessThan{T}) where {T}
    return Strictly{MOI.LessThan{T}, T}(set)
end
function Strictly(set::MOI.GreaterThan{T}) where {T}
    return Strictly{MOI.GreaterThan{T}, T}(set)
end
function Strictly(set::Increasing)
    return Strictly{Increasing, Int}(set)
end
function Strictly(set::Decreasing)
    return Strictly{Decreasing, Int}(set)
end
