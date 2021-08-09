"""
    Count{S <: MOI.AbstractScalarSet}(dimension::Int, set::MOI.AbstractScalarSet)

``\\{(y, x) \\in \\mathbb{N} \\times \\mathbb{T}^\\mathtt{dimension} : y = |\\{i | x_i \\in S \\}|\\}``

`dimension` is the number of variables that are checked against the `set`.

Also called `among`.

## Example

    [w, x, y, z] in Count(3, MOI.EqualTo(2.0))
    # w == sum([x, y, z] .== 2.0)
"""
struct Count{S <: MOI.AbstractScalarSet} <: MOI.AbstractVectorSet
    dimension::Int
    set::S
end

function Count(dimension::Int, value::Real)
    return Count(dimension, MOI.EqualTo(value))
end

MOI.dimension(set::Count{S}) where {S} = set.dimension + 1
copy(set::Count{S}) where {S} = Count(set.dimension, copy(set.set))
function Base.:(==)(x::Count{S}, y::Count{S}) where {S}
    return x.dimension == y.dimension && x.set == y.set
end

"""
    CountedValuesType

Kind of values to be counted for a `GlobalCardinality` constraint:

* either the values to count are fixed when creating the set:
  `FIXED_COUNTED_VALUES`
* or the values are themselves variables (typically constrained elsewhere): 
  `VARIABLE_COUNTED_VALUES`
"""
@enum CountedValuesType begin
    FIXED_COUNTED_VALUES
    VARIABLE_COUNTED_VALUES
end

"""
    CountedValuesClosureType

Whether values that are not counted in `GlobalCardinality` constraint are 
allowed in the array whose values are counted:

* either uncounted values are allowed: `OPEN_COUNTED_VALUES`
* or they are not allowed: `CLOSED_COUNTED_VALUES`
"""
@enum CountedValuesClosureType begin
    OPEN_COUNTED_VALUES
    CLOSED_COUNTED_VALUES
end

"""
    GlobalCardinality{CVT, CVCT, T}(dimension::Int, values::Vector{T})

This set represents the large majority of the variants of the 
global-cardinality constraint, with the parameters set in `CountedValuesType` 
(`CVT` parameter) and `CountedValuesClosureType` (`CVCT` parameter).

``\\{(x, y) \\in \\mathbb{T}^\\mathtt{dimension} \\times \\mathbb{N}^d : y_i = |\\{ j | x_j = \\mathtt{values}_i, \\forall j \\}| \\}``

The first `dimension` variables are an array, the last variables are the 
number of times that each item of `values` is present in the first array.
Values that are not in `values` are ignored. 

Also called [`gcc`](https://sofdem.github.io/gccat/gccat/Cglobal_cardinality.html)
or `count`.

## Example

    [x, y, z, v, w] in GlobalCardinality(3, [2.0, 4.0])
    # v == sum([x, y, z] .== 2.0)
    # w == sum([x, y, z] .== 4.0)
"""
struct GlobalCardinality{CVT, CVCT, T <: Real} <: MOI.AbstractVectorSet
    dimension::Int
    values::Vector{T}
    n_values::Int
end

function GlobalCardinality(dimension::Int, values::Vector{T}) where {T <: Real}
    return GlobalCardinality{FIXED_COUNTED_VALUES, OPEN_COUNTED_VALUES, T}(dimension, values, -1)
end

function GlobalCardinality{CVT, CVCT}(dimension::Int, values::Vector{T}) where {CVT, CVCT, T <: Real}
    return GlobalCardinality{CVT, CVCT, T}(dimension, values, -1)
end

function GlobalCardinality{CVT, CVCT, T}(dimension::Int, values::Vector{T}) where {CVT, CVCT, T <: Real}
    return GlobalCardinality{CVT, CVCT, T}(dimension, values, -1)
end

function GlobalCardinality{CVT, CVCT, T}(dimension::Int, n_values::Int) where {CVT, CVCT, T <: Real}
    return GlobalCardinality{CVT, CVCT, T}(dimension, T[], n_values)
end

function n_values(set::GlobalCardinality)
    if length(set.values) > 0
        return length(set.values)
    else
        return set.n_values
    end
end

function MOI.dimension(set::GlobalCardinality{CVT, CVCT, T}) where {CVT, CVCT, T <: Real}
    dim = set.dimension + n_values(set) # Array to count in, counts.
    if CVT == VARIABLE_COUNTED_VALUES
        dim += n_values(set) # Values to count.
    end
    return dim
end

function copy(set::GlobalCardinality{CVT, CVCT, T})  where {CVT, CVCT, T <: Real}
    return GlobalCardinality{CVT, CVCT, T}(set.dimension, copy(set.values), set.n_values)
end

function Base.:(==)(x::GlobalCardinality{CVT, CVCT, T}, y::GlobalCardinality{CVT, CVCT, T}) where {CVT, CVCT, T <: Real}
    return x.dimension == y.dimension && x.values == y.values && x.n_values == y.n_values
end

# Shortcuts for types.
# const GlobalCardinality{T} = GlobalCardinality{FIXED_COUNTED_VALUES, OPEN_COUNTED_VALUES, T}
const GlobalCardinalityOpen{T} = GlobalCardinality{FIXED_COUNTED_VALUES, OPEN_COUNTED_VALUES, T}
const GlobalCardinalityClosed{T} = GlobalCardinality{FIXED_COUNTED_VALUES, CLOSED_COUNTED_VALUES, T}
const GlobalCardinalityFixed{T} = GlobalCardinality{FIXED_COUNTED_VALUES, OPEN_COUNTED_VALUES, T}
const GlobalCardinalityFixedOpen{T} = GlobalCardinality{FIXED_COUNTED_VALUES, OPEN_COUNTED_VALUES, T}
const GlobalCardinalityFixedClosed{T} = GlobalCardinality{FIXED_COUNTED_VALUES, CLOSED_COUNTED_VALUES, T}
const GlobalCardinalityVariable{T} = GlobalCardinality{VARIABLE_COUNTED_VALUES, OPEN_COUNTED_VALUES, T}
const GlobalCardinalityVariableOpen{T} = GlobalCardinality{VARIABLE_COUNTED_VALUES, OPEN_COUNTED_VALUES, T}
const GlobalCardinalityVariableClosed{T} = GlobalCardinality{VARIABLE_COUNTED_VALUES, CLOSED_COUNTED_VALUES, T}

# Ease dispatch for implementing solvers.
function MOI.supports_constraint(o::MOI.AbstractOptimizer, f::MOI.AbstractVectorFunction, s::Type{GlobalCardinality{CVT, CVCT, T}}) where {CVT, CVCT, T <: Real}
    return MOI.supports_constraint(o, f, s, Val(CVT), Val(CVCT))
end

function MOI.supports_constraint(o::MOI.AbstractOptimizer, f::MOI.AbstractVectorFunction, s::Type{GlobalCardinality{CVT, OPEN_COUNTED_VALUES, T}}, ::Val{CVT}, ::Val{OPEN_COUNTED_VALUES}) where {CVT, T <: Real}
    return MOI.supports_constraint(o, f, s, Val(CVT))
end

function MOI.supports_constraint(o::MOI.AbstractOptimizer, f::MOI.AbstractVectorFunction, s::Type{GlobalCardinality{FIXED_COUNTED_VALUES, CVCT, T}}, ::Val{FIXED_COUNTED_VALUES}, ::Val{CVCT}) where {CVCT, T <: Real}
    return MOI.supports_constraint(o, f, s, Val(CVCT))
end

"""
    CountCompare(dimension::Int)

``\\{(z, x, y) \\in \\mathbb{N} \\times \\mathbb{R}^\\mathtt{dimension} \\times \\mathbb{R}^\\mathtt{dimension} : Z = |\\{i | x_i = y_i\\}|\\}``

The first `dimension` variables are the first array that is compared to the 
second one, indicated by the next `dimension` variables. The last variable
is the number of values that are identical in both arrays.

## Example

    [v, w, x, y, z] in Count(2)
    # w == sum([w, x] .== [y, z])
"""
struct CountCompare <: MOI.AbstractVectorSet
    dimension::Int
end

MOI.dimension(set::CountCompare) = 2 * set.dimension + 1

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

# isbits types, nothing to copy
function copy(
    set::Union{CountCompare, CountDistinct},
)
    return set
end
