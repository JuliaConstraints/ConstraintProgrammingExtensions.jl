"""
AllEqual(dimension::Int)

The set corresponding to an all-equal constraint.

All expressions of a vector-valued function are enforced to take the same value
in the solution.

## Example

    [x, y, z] in AllEqual(3)
    # enforces `x == y` AND `x == z`.
"""
struct AllEqual <: MOI.AbstractVectorSet
    dimension::Int
end

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

# https://sofdem.github.io/gccat/gccat/Calldifferent_cst.html should be modelled
# with AllDifferent, because it is just shifting all expressions by constants, 
# i.e. scalar affine expressions.

"""
    AllDifferentExceptConstants{T <: Number}(dimension::Int, k::Set{T})

All expressions of a vector-valued function are enforced to take distinct
values in the solution, but values equal to any value in `k` are not 
considered: for all pairs of expressions, either their values must differ or
at least one of the two variables has a value in `k`.

This constraint is sometimes called `distinct`.

## Example

    [x, y] in AllDifferentExceptConstant(2, 0)
    # enforces `x != y` OR `x == 0` OR `y == 0`.

    [x, y] in AllDifferentExceptConstant(2, Set([0, 1]))
    # enforces `x != y` OR `x == 0` OR `y == 0` OR `x == 1` OR `y == 1`.
"""
struct AllDifferentExceptConstants{T <: Number} <: MOI.AbstractVectorSet
    dimension::Int
    k::Set{T}
end

function copy(set::AllDifferentExceptConstants{T}) where {T}
    return AllDifferentExceptConstants(set.dimension, copy(set.k))
end
function Base.:(==)(
    x::AllDifferentExceptConstants{T},
    y::AllDifferentExceptConstants{T},
) where {T}
    return x.dimension == y.dimension && x.k == y.k
end

"""
Special case of [`AllDifferentExceptConstants`](@ref) where only one value is 
ignored.
"""
function AllDifferentExceptConstant(dimension::Int, value::T) where {T <: Number}
    return AllDifferentExceptConstants(dimension, Set(value))
end

"""
    SymmetricAllDifferent(dimension::Int)

The set corresponding to an all-different constraint, with the additional 
requirement that the array must be symmetric.

All expressions of a vector-valued function are enforced to take distinct
values in the solution: for all pairs of expressions, their values must
differ. Symmetry means that, if ``x[i]=j``, then ``x[j]=i``.

This constraint is sometimes called [`symmetric_alldifferent`](https://sofdem.github.io/gccat/gccat/Csymmetric_alldifferent.html).

## Example

    [x, y, z] in SymmetricAllDifferent(3)
    # enforces `x != y` AND `x != z` AND `y != z` AND `(x == 2 => y == 1)` AND 
    # `(x == 3 => z = 1)` AND `(y == 1 => x == 2)` AND `(y == 3 => z == 2)` AND 
    # `(z == 1 => x == 3)` AND `(z == 2 => y == 3)`.
"""
struct SymmetricAllDifferent <: MOI.AbstractVectorSet
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

copy(set::Domain{T}) where {T} = Domain(copy(set.values))
Base.:(==)(x::Domain{T}, y::Domain{T}) where {T} = x.values == y.values

"""
    VectorDomain{T <: Number}(dimension::Int, values::Set{Vector{T}})

The set corresponding to an enumeration of constant values.

The value of a vector function is enforced to take a value from this set of
vector values.

This constraint is sometimes called `in`, `member` or `allowed_assignments`.
https://sofdem.github.io/gccat/gccat/Cdomain.html

## Example

    [x, y] in Domain(2, Set([[1, 2], [2, 3]]))
    # enforces (`x == 1` AND `y == 2`) OR (`x == 2` AND `y == 3`).
"""
struct VectorDomain{T <: Number} <: MOI.AbstractVectorSet
    dimension::Int
    values::Set{Vector{T}}
end

copy(set::VectorDomain{T}) where {T} = VectorDomain(set.dimension, copy(set.values))
Base.:(==)(x::VectorDomain{T}, y::VectorDomain{T}) where {T} = x.dimension == y.dimension && x.values == y.values

"""
    AntiDomain{T <: Number}(values::Set{T})

The set corresponding to an enumeration of constant values that are excluded.

The value of a scalar function is enforced to take a value that is not from 
this set of values.

This constraint is sometimes called (`not_in`)[https://sofdem.github.io/gccat/gccat/Cnot_in.html],
`not_member`, `rel`, `forbidden_assignments`, or `no_good`.

## Example

    x in AntiDomain(1:3)
    # enforces `x != 1` AND `x != 2` AND `x != 3`.
"""
struct AntiDomain{T <: Number} <: MOI.AbstractScalarSet
    values::Set{T}
end

copy(set::AntiDomain{T}) where {T} = AntiDomain(copy(set.values))
Base.:(==)(x::AntiDomain{T}, y::AntiDomain{T}) where {T} = x.values == y.values

"""
    VectorAntiDomain{T <: Number}(values::Set{T})

The set corresponding to an enumeration of constant values that are excluded.

The value of a vector function is enforced to take a value that is not from 
this set of vector values.

This constraint is sometimes called (`not_in`)[https://sofdem.github.io/gccat/gccat/Cnot_in.html],
`not_member`, `rel`, `forbidden_assignments`, or `no_good`.

## Example

    [x, y] in VectorAntiDomain(2, Set([[1, 2], [2, 3]]))
    # enforces (`x != 1` AND `y != 2`) OR (`x != 2` AND `y != 3`).
"""
struct VectorAntiDomain{T <: Number} <: MOI.AbstractScalarSet
    dimension::Int
    values::Set{Vector{T}}
end

copy(set::VectorAntiDomain{T}) where {T} = VectorAntiDomain(set.dimension, copy(set.values))
Base.:(==)(x::VectorAntiDomain{T}, y::VectorAntiDomain{T}) where {T} = x.values == y.values
MOI.dimension(set::VectorAntiDomain{T}) where {T} = set.dimension # TODO: why is this needed?

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

The set excluding the single point ``x \\in \\mathbb{R}`` where ``x`` is given
by `value`.
"""
struct DifferentFrom{T <: Number} <: MOI.AbstractScalarSet
    value::T
end

MOI.constant(set::DifferentFrom{T}) where {T} = set.value
copy(set::DifferentFrom{T}) where {T} = DifferentFrom(copy(set.value))
function MOIU.shift_constant(set::DifferentFrom{T}, offset::T) where {T}
    return typeof(set)(MOI.constant(set) + offset)
end

"""
    Element{T <: Real}(values::Vector{T})

``\\{(x, i) \\in \\mathbb{R} \\times \\mathbb{N} | x = values[i]\\}``

Less formally, the first element constrained in this set will take the value of
`values` at the index given by the second element.

Also called [`indexing`](https://sofdem.github.io/gccat/gccat/Celement.html) 
or `nth`.

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

MOI.dimension(set::Element{T}) where {T} = 2
copy(set::Element{T}) where {T} = Element(copy(set.values))
Base.:(==)(x::Element{T}, y::Element{T}) where {T} = x.values == y.values

"""
    ElementVariableArray(dimension::Int)

``\\{(x, i, values) \\in \\mathbb{R} \\times \\mathbb{N} \\times \\mathbb{R}^{\\mathtt{dimension}} | x = values[i]\\}``

Less formally, the first element constrained in this set will take the value of
`values` at the index given by the second element in the array given by the 
remaining elements constrained in the set.

## Examples

    [x, 3, a, b, c] in ElementVariableArray(3)
    # Enforces that x = c, because 6 is the 3rd element from the array [a, b, c].

    [y, j, a, b, c] in ElementVariableArray(3)
    # Enforces that y = array[j], depending on the value of j (an integer
    # between 1 and 3), from the array [a, b, c].
"""
struct ElementVariableArray <: MOI.AbstractVectorSet
    dimension::Int
end

MOI.dimension(set::ElementVariableArray) = 2 + set.dimension
copy(set::ElementVariableArray) = ElementVariableArray(set.dimension)
function Base.:(==)(x::ElementVariableArray, y::ElementVariableArray)
    return x.dimension == y.dimension
end

"""
    MinimumDistance{T <: Real}(dimension::Int, k::T)

Ensures that all the `dimension` expressions in this set are at least `k` 
apart, in absolute value:

``\\Big\\{x \\in \\mathbb{S}^{\\mathtt{dimension}} \\Big| |x_i - x_j| \\geq k, \\forall i \\neq j \\in \\{1, 2\\dots \\mathtt{dimension}\\} \\Big\\}``

Also called [`all_min_dist`](https://sofdem.github.io/gccat/gccat/Call_min_dist.html) 
or `inter_distance`.
"""
struct MinimumDistance{T <: Real} <: MOI.AbstractVectorSet
    dimension::Int
    k::T
end

function copy(set::MinimumDistance{T}) where {T}
    return MinimumDistance(set.dimension, copy(set.k))
end
function Base.:(==)(x::MinimumDistance{T}, y::MinimumDistance{T}) where {T}
    return x.dimension == y.dimension && x.k == y.k
end

"""
    MaximumDistance{T <: Real}(dimension::Int, k::T)

Ensures that all the `dimension` expressions in this set are at most `k` 
apart, in absolute value:

``\\Big\\{x \\in \\mathbb{S}^{\\mathtt{dimension}} \\Big| |x_i - x_j| \\leq k, \\forall i \\neq j \\in \\{1, 2\\dots \\mathtt{dimension}\\} \\Big\\}``
"""
struct MaximumDistance{T <: Real} <: MOI.AbstractVectorSet
    dimension::Int
    k::T
end

function copy(set::MaximumDistance{T}) where {T}
    return MaximumDistance(set.dimension, copy(set.k))
end
function Base.:(==)(x::MaximumDistance{T}, y::MaximumDistance{T}) where {T}
    return x.dimension == y.dimension && x.k == y.k
end

"""
    Inverse(dimension::Int)

Ensures that the two arrays of variables of size `dimension` are the inverse 
one of the other. 

``\\Big\\{(x, y) \\in \\mathbb{R}^{\\mathtt{dimension}} \\times \\mathbb{R}^{dimension} \\Big| x_i = j \\iff y_j = i, \\forall i, j \\in \\{1, 2 \\dots \\mathtt{dimension}\\} \\Big\\}``

Indices start at 1, like Julia.

Also called [`channel`](https://sofdem.github.io/gccat/gccat/Cinverse.html), 
`inverse_channeling`, or `assignment`.
"""
struct Inverse <: MOI.AbstractVectorSet
    dimension::Int
end

"""
    SlidingSum{T}(low::T, high::T, length::Int, dimension::Int)

Ensures that the sum of all sequences of size `length` have a value between
`low` and `high`. 

``\\{x \\in \\mathbb{R}^{\\mathtt{dimension}} | \\mathtt{low} \\leq \\sum_{j=i}^{i+\\mathtt{length}-1} x_i \\leq \\mathtt{high}, \\forall i \\in \\{ 0, 1 \\dots \\mathtt{dimension} - \\mathtt{length} \\} \\}``

https://sofdem.github.io/gccat/gccat/Csliding_sum.html
"""
struct SlidingSum{T <: Real} <: MOI.AbstractVectorSet
    low::T
    high::T
    length::Int
    dimension::Int
end

"""
    ValuePrecedence(before::T, value::T, dimension::Int)

Ensures that the value `before` happens before `value` in the array of size 
`dimension`. 

``\\{x \\in \\mathbb{R}^{\\mathtt{dimension}} | \\exists i < j: x_i = \\mathtt{before}, x_j = \\mathtt{value} \\}``

Also called `precede` or `value_precede`.

https://sofdem.github.io/gccat/gccat/Cint_value_precede.html
"""
struct ValuePrecedence{T <: Real} <: MOI.AbstractVectorSet
    before::T
    value::T
    dimension::Int
end

function copy(set::ValuePrecedence{T}) where {T}
    return ValuePrecedence(copy(set.before), copy(set.value), set.dimension)
end
function Base.:(==)(x::ValuePrecedence{T}, y::ValuePrecedence{T}) where {T}
    return x.dimension == y.dimension && x.before == y.before && x.value == y.value
end

# Solvers tend not to agree on the name of this one... "Inverse" is the most common one, though.
#     https://sofdem.github.io/gccat/gccat/Cinverse.html
# - inverse: CPLEX, MiniZinc, GCC, CHIP
# - inverseChanneling: Choco
# - channel: Gecode
# - assignment: SICStus

MOI.dimension(set::Inverse) = 2 * set.dimension

# isbits types, nothing to copy
function copy(
    set::Union{AllEqual, AllDifferent, SymmetricAllDifferent, Membership, Inverse, SlidingSum,},
)
    return set
end
