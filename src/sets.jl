

"""
    AllDifferent(dimension::Int)

The set corresponding to an all-different constraint.

All expressions of a vector-valued function are enforced to take distinct
values in the solution: for all pairs of expressions, their values must
differ.

This constraint is sometimes called `distinct`.

## Example

    [x, y, z] in AllDifferent(3)
    # enforces `x != y` AND `x != z` AND `y != z`.
"""
struct AllDifferent <: MOI.AbstractVectorSet
    dimension::Int
end

"""
    Domain{T <: Number}(values::Set{T})

The set corresponding to an enumeration of constant values.

The value of a scalar function is enforced to take a value from this set of
values.

This constraint is sometimes called `in`, `member` or `allowed_assignments`.
https://sofdem.github.io/gccat/gccat/Cdomain.html

## Example

    x in Domain(1:3)
    # enforces `x == 1` OR `x == 2` OR `x == 3`.
"""
struct Domain{T <: Number} <: MOI.AbstractScalarSet
    values::Set{T}
end

Base.copy(set::Domain{T}) where T = Domain(copy(set.values))
Base.:(==)(x::Domain{T}, y::Domain{T}) where T = x.values == y.values

"""
    AntiDomain{T <: Number}(values::Set{T})

The set corresponding to an enumeration of constant values that are excluded.

The value of a scalar function is enforced to take a value that is not from 
this set of values.

This constraint is sometimes called (`not_in`)[https://sofdem.github.io/gccat/gccat/Cnot_in.html#uid28032],
`not_member`, `rel`, or `forbidden_assignments`.

## Example

    x in AntiDomain(1:3)
    # enforces `x != 1` AND `x != 2` AND `x != 3`.
"""
struct AntiDomain{T <: Number} <: MOI.AbstractScalarSet
    values::Set{T}
end

Base.copy(set::AntiDomain{T}) where T = AntiDomain(copy(set.values))
Base.:(==)(x::AntiDomain{T}, y::AntiDomain{T}) where T = x.values == y.values

"""
    Membership(dimension)

The first element of a function of dimension `dimension` must equal at least
one of the following `dimension - 1` elements of the function.

This constraint is sometimes called `in_set`.

## Example

    [x, y, z] in Membership(3)
    # enforces `x == y` OR `x == z`.
"""
struct Membership <: MOI.AbstractVectorSet
    dimension::Int
end

"""
    DifferentFrom{T <: Number}(value::T)

The set exclusing the single point ``x \\in \\mathbb{R}`` where ``x`` is given
by `value`.
"""
struct DifferentFrom{T <: Number} <: MOI.AbstractScalarSet
    value::T
end

MOI.constant(set::DifferentFrom{T}) where T = set.value
MOIU.shift_constant(set::DifferentFrom{T}, offset::T) where T =
    typeof(set)(MOI.constant(set) + offset)

"""
    Count{T <: Real}(value::T, dimension::Int)

``\\{(y, x) \\in \\mathbb{N} \\times \\mathbb{T}^\\mathtt{dimension} : y = |\\{i | x_i = value\\}|\\}``

`dimension` is the number of variables that are checked against the `value`, 
i.e. the result variable is not included.

Also called `among`.

## Example

    [w, x, y, z] in Count(2.0, 3)
    # w == sum([x, y, z] .== 2.0)
"""
struct Count{T <: Real} <: MOI.AbstractVectorSet
    value::T
    dimension::Int
end

MOI.dimension(set::Count{T}) where T = set.dimension + 1
Base.copy(set::Count{T}) where T = Count(copy(set.value), value)

"""
    CountDistinct(dimension::Int)

The first variable in the set is forced to be the number of distinct values in
the rest of the expressions.

This is a relaxed version of `AllDifferent`; it encodes an `AllDifferent`
constraint when the first variable is the number of variables in the set.

Also called `nvalues`.

## Example

    [x, y, z] in CountDistinct(3)
    # x = 1 if y == z, x = 2 if y != z
"""
struct CountDistinct <: MOI.AbstractVectorSet
    dimension::Int
end

MOI.dimension(set::CountDistinct) = set.dimension + 1

"""
    LexicographicallyLessThan(dimension::Int)

Ensures that the first array of variables of size `dimension` is 
lexicographically less than the second one. 

``\\{(x, y) \\in \\mathbb{R}^{dimension}} \\times \\mathbb{R}^{dimension}} | \exists j \\in \\{1, 2 \\dots dimension\\}: x_j < y_j, \\forall i < j, x_i = y_i \\}``.

Also called [`lex2`](https://sofdem.github.io/gccat/gccat/Clex2.html) or 
[`lex_less`](https://sofdem.github.io/gccat/gccat/Clex_less.html#uid25647).
"""
struct LexicographicallyLessThan <: MOI.AbstractVectorSet
    dimension::Int
end

# TODO: Implement this like Strictly, based on the existing LessThan/GreaterThan sets? Major difference: LessThan/Greater than are with respect to a constant, not LexicographicallyLessThan.

MOI.dimension(set::LexicographicallyLessThan) = 2 * set.dimension

"""
    LexicographicallyGreaterThan(dimension::Int)

Ensures that the first array of variables of size `dimension` is 
lexicographically greater than the second one. 

``\\{(x, y) \\in \\mathbb{R}^{dimension}} \\times \\mathbb{R}^{dimension}} | \exists j \\in \\{1, 2 \\dots dimension\\}: x_j > y_j, \\forall i < j, x_i = y_i \\}``.

Also called [`lex2`](https://sofdem.github.io/gccat/gccat/Clex2.html) or 
[`lex_less`](https://sofdem.github.io/gccat/gccat/Clex_less.html#uid25647).
"""
struct LexicographicallyGreaterThan <: MOI.AbstractVectorSet
    dimension::Int
end

MOI.dimension(set::LexicographicallyGreaterThan) = 2 * set.dimension

# TODO: bridge to LexicographicallyLessThan.

"""
    Strictly{S <: Union{LessThan{T}, GreaterThan{T}, LexicographicallyGreaterThan}}

Converts an inequality set to a set with the same inequality made strict.
For example, while `LessThan(1)` corresponds to the inequality `x <= 1`,
`Strictly(LessThan(1))` corresponds to the inequality `x < 1`.

## Example

    x in Strictly(LessThan(1))
"""
struct Strictly{S <: Union{MOI.LessThan{T} where T, MOI.GreaterThan{T} where T, LexicographicallyLessThan, LexicographicallyGreaterThan}, T <: Number} <: MOI.AbstractScalarSet
    set::S
end

Base.copy(set::Strictly{S}) where S = Count(copy(set.set))
MOI.constant(set::Strictly{S}) where S = MOI.constant(set.set)
MOI.dimension(set::Strictly{S}) where S = MOI.dimension(set.set)
MOIU.shift_constant(set::Strictly{S}, offset::T) where {S, T} =
    typeof(set)(MOIU.shift_constant(set.set, offset))

Strictly(set::LexicographicallyLessThan) = Strictly{LexicographicallyLessThan, Int}(set)
Strictly(set::MOI.LessThan{T}) where T = Strictly{MOI.LessThan{T}, T}(set)
Strictly(set::MOI.GreaterThan{T}) where T = Strictly{MOI.GreaterThan{T}, T}(set)

"""
    Element{T <: Real}(values::Vector{T})

``\\{(x, i) \\in \\mathbb{R}^d \\times \\mathbb{N}^d | x = values[i]\\}``

Less formally, the first element constrained in this set will take the value of
`values` at the index given by the second element.

## Examples

    [x, 3] in Element([4, 5, 6])
    # Enforces that x = 6, because 6 is the 3rd element from the array.

    [y, j] in Element([4, 5, 6])
    # Enforces that y = array[j], depending on the value of j (an integer
    # between 1 and 3).
"""
struct Element{T <: Real} <: MOI.AbstractVectorSet
    values::Vector{T}
end

MOI.dimension(set::Element{T}) where T = 2
Base.copy(set::Element{T}) where T = Element(copy(set.values))
Base.:(==)(x::Element{T}, y::Element{T}) where T = x.values == y.values

"""
    Sort(dimension::Int)

Ensures that the first `dimension` elements is a sorted copy of the next
`dimension` elements.

## Example

    [a, b, c, d] in Sort(2)
    # Enforces that:
    # - the first part is sorted: a <= b
    # - the first part corresponds to the second one:
    #     - either a = c and b = d
    #     - or a = d and b = c
"""
struct Sort <: MOI.AbstractVectorSet
    dimension::Int
end

MOI.dimension(set::Sort) = 2 * set.dimension

"""
    SortPermutation(dimension::Int)

Ensures that the first `dimension` elements is a sorted copy of the second
`dimension` elements.

The last `dimension` elements give a permutation to get from the original array
to its sorted version.

## Example

    [a, b, c, d, i, j] in SortPermutation(2)
    # Enforces that:
    # - the first part is sorted: a <= b
    # - the first part corresponds to the second one:
    #     - either a = c and b = d: in this case, i = 1 and j = 2
    #     - or a = d and b = c: in this case, i = 2 and j = 1
"""
struct SortPermutation <: MOI.AbstractVectorSet
    dimension::Int
end

MOI.dimension(set::SortPermutation) where T = 3 * set.dimension

"""
    BinPacking(n_bins::Int, n_items::Int, weights::Vector{T})

Implements an uncapacitated version of the bin-packing problem.

The first `n_bins` variables give the load in each bin, the last `n_items` give
the number of the bin to which the item is assigned to. 

The load of a bin is defined as the sum of the sizes of the items put in that 
bin.

Also called [`pack`](https://sofdem.github.io/gccat/gccat/Cbin_packing.html).

## Example

    [a, b, c] in BinPacking{Int}(1, 2, [2, 3])
    # As there is only one bin, the only solution is to put all the items in 
    # that bin.
    # Enforces that:
    # - the bin load is the sum of the weights of the objects in that bin: 
    #   a = 2 + 3
    # - the bin number of the two items is 1: b = c = 1
"""
struct BinPacking{T <: Real} <: MOI.AbstractVectorSet
    n_bins::Int
    n_items::Int
    weights::Vector{T}

    function BinPacking(n_bins::Int, n_items::Int, weights::Vector{T}) where T <: Real
        @assert n_items == length(weights)
        return new{T}(n_bins, n_items, weights)
    end
end

MOI.dimension(set::BinPacking) = set.n_bins + 2 * set.n_items

"""
    FixedCapacityBinPacking(n_bins::Int, n_items::Int, weights::Vector{T}, capacities::Vector{<:Real})

Implements a capacitated version of the bin-packing problem where capacities
are constant.

The first `n_bins` variables give the load in each bin, the last `n_items` 
give the number of the bin to which the item is assigned to. 

The load of a bin is defined as the sum of the sizes of the items put in that 
bin.

This constraint is equivalent to `BinPacking` with inequality constraints on 
the loads of the bins where the upper bound is a constant. However, there are 
more efficient propagators for the combined constraint (bin packing with 
maximum load); if such propagators are not available, bridges are available to
make the conversion seamless.

Also called [`bin_packing_capa`](https://sofdem.github.io/gccat/gccat/Cbin_packing_capa.html).

## Example
    [a, b, c] in FixedCapacityBinPacking{Int}(1, 2, [2, 3], [4])
    # As there is only one bin, the only solution is to put all the items in
    # that bin if its capacity is large enough.
    # Enforces that:
    # - the bin load is the sum of the weights of the objects in that bin: 
    #   a = 2 + 3
    # - the bin load is at most its capacity: a <= 4 (given in the set)
    # - the bin number of the two items is 1: b = c = 1
"""
struct FixedCapacityBinPacking{T <: Real} <: MOI.AbstractVectorSet
    n_bins::Int
    n_items::Int
    weights::Vector{T}
    capacities::Vector{T}

    function FixedCapacityBinPacking(n_bins::Int, n_items::Int, weights::Vector{T}, capacities::Vector{T}) where T <: Real
        @assert n_items == length(weights)
        @assert n_bins == length(capacities)
        return new{T}(n_bins, n_items, weights)
    end
end

MOI.dimension(set::FixedCapacityBinPacking) = set.n_bins + set.n_items

"""
    VariableCapacityBinPacking(n_bins::Int, n_items::Int, weights::Vector{T})

Implements an capacitated version of the bin-packing problem where capacities 
are optimisation variables.

The first `n_bins` variables give the load in each bin, the next `n_bins` are
the capacity of each bin, the last `n_items` give the number of the bin to
which the item is assigned to.

The load of a bin is defined as the sum of the sizes of the items put in that 
bin.

This constraint is equivalent to `BinPacking` with inequality constraints on 
the loads of the bins where the upper bound is any expression. However, there 
are more efficient propagators for the combined constraint (bin packing with 
maximum load) and for the fixed-capacity version.

Also called [`bin_packing_capa`](https://sofdem.github.io/gccat/gccat/Cbin_packing_capa.html).

## Example
    [a, 2, b, c] in VariableCapacityBinPacking(1, 2, [2, 3])
    # As there is only one bin, the only solution is to put all the items in
    # that bin if its capacity is large enough.
    # Enforces that:
    # - the bin load is the sum of the weights of the objects in that bin: 
    #   a = 2 + 3
    # - the bin load is at most its capacity: a <= 2 (given in a variable)
    # - the bin number of the two items is 1: b = c = 1
"""
struct VariableCapacityBinPacking{T <: Real} <: MOI.AbstractVectorSet
    n_bins::Int
    n_items::Int
    weights::Vector{T}

    function VariableCapacityBinPacking(n_bins::Int, n_items::Int, weights::Vector{T}) where T <: Real
        @assert n_items == length(weights)
        return new{T}(n_bins, n_items, weights)
    end
end

MOI.dimension(set::VariableCapacityBinPacking) = 2 * set.n_bins + set.n_items

"""
    MinimumDistance{T <: Real}(k::T, dimension::Int)

Ensures that all the `dimension` expressions in this set are at least `k` 
apart, in absolute value:

``\\{x \\in \\mathbb{S}^{dimension}} | |x_i - x_j| \\geq k, \\forall i \\neq j \\in \\{1, 2\\dots dimension\\} \\}``.

Also called [`all_min_dist`](https://sofdem.github.io/gccat/gccat/Call_min_dist.html) 
or `inter_distance`.
"""
struct MinimumDistance{T <: Real} <: MOI.AbstractVectorSet
    k::T
    dimension::Int
end

"""
    MaximumDistance{T <: Real}(k::T, dimension::Int)

Ensures that all the `dimension` expressions in this set are at most `k` 
apart, in absolute value:

``\\{x \\in \\mathbb{S}^{dimension}} | |x_i - x_j| \\leq k, \\forall i \\neq j \\in \\{1, 2\\dots dimension\\} \\}``.
"""
struct MaximumDistance{T <: Real} <: MOI.AbstractVectorSet
    k::T
    dimension::Int
end

"""
    Inverse(dimension::Int)

Ensures that the two arrays of variables of size `dimension` are the inverse 
one of the other. 

``\\{(x, y) \\in \\mathbb{R}^{dimension}} \\times \\mathbb{R}^{dimension}} | x_i = j \\iff y_j = i, \\forall i, j \\in \\{1, 2 \\dots dimension\\} \\}``.

Indices start at 1, like Julia.

Also called `channel`, `inverse_channeling`, or `assignment`.
"""
struct Inverse <: MOI.AbstractVectorSet
    dimension::Int
end

# Solvers tend not to agree on the name of this one... "Inverse" is the most common one, though.
#     https://sofdem.github.io/gccat/gccat/Cinverse.html
# - inverse: CPLEX, MiniZinc, GCC, CHIP
# - inverseChanneling: Choco
# - channel: Gecode
# - assignment: SICStus

MOI.dimension(set::Inverse) = 2 * set.dimension

# isbits types, nothing to copy
function Base.copy(
    set::Union{
        AllDifferent,
        DifferentFrom,
        CountDistinct,
        Element,
        BinPacking,
        FixedCapacityBinPacking,
        VariableCapacityBinPacking,
        DifferentFrom,
        MinimumDistance
    }
)
    return set
end