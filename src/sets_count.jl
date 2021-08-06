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

@enum CountedValuesType begin
    FIXED_COUNTED_VALUES
    VARIABLE_COUNTED_VALUES
end

@enum CountedValuesClosureType begin
    OPEN_COUNTED_VALUES
    CLOSED_COUNTED_VALUES
end

"""
    GlobalCardinality{T}(dimension::Int, values::Vector{T})

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

function n_values(set::GlobalCardinality)
    if length(set.values) > 0
        return length(set.values)
    else
        return set.n_values
    end
end

function MOI.dimension(set::GlobalCardinality{CVT, CVCT, T})
    dim = set.dimension + n_values(set) # Array to count in, counts.
    if CVT == VARIABLE_COUNTED_VALUES
        dim += n_values(set) # Values to count.
    end
    return dim
end

function copy(set::GlobalCardinality) 
    return GlobalCardinality(set.dimension, copy(set.values), set.n_values)
end

function Base.:(==)(x::GlobalCardinality{CVT, CVCT, T}, y::GlobalCardinality{CVT, CVCT, T}) where {CVT, CVCT, T <: Real}
    return x.dimension == y.dimension && x.values == y.values && x.n_values == y.n_values
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
