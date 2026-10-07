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
        DoublyLexicographicallyGreaterThan,
        DoublyLexicographicallyLessThan,
        Increasing,
        Decreasing,
    },
    T <: Number,
} <: MOI.AbstractScalarSet
    set::S
end

copy(set::Strictly{S, T}) where {S, T} = Strictly{S, T}(copy(set.set))
MOI.constant(set::Strictly{S, T}) where {S, T} = MOI.constant(set.set)
MOI.dimension(set::Strictly{S, T}) where {S, T} = MOI.dimension(set.set)
function MOIU.shift_constant(set::Strictly{S, T}, offset::T) where {S, T}
    return typeof(set)(MOIU.shift_constant(set.set, offset))
end

function Strictly(set::LexicographicallyLessThan) # TODO: does this more harm than good, with an automatic value of Int? 
    return Strictly{LexicographicallyLessThan, Int}(set)
end
function Strictly(set::LexicographicallyGreaterThan) # TODO: does this more harm than good, with an automatic value of Int? 
    return Strictly{LexicographicallyGreaterThan, Int}(set)
end
function Strictly(set::DoublyLexicographicallyLessThan) # TODO: does this more harm than good, with an automatic value of Int? 
    return Strictly{DoublyLexicographicallyLessThan, Int}(set)
end
function Strictly(set::DoublyLexicographicallyGreaterThan) # TODO: does this more harm than good, with an automatic value of Int? 
    return Strictly{DoublyLexicographicallyGreaterThan, Int}(set)
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
