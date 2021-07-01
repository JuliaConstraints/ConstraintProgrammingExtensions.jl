"""
    Count{S <: MOI.AbstractScalarSet}(dimension::Int, set::MOI.AbstractScalarSet)

``\\{(y, x) \\in \\mathbb{N} \\times \\mathbb{T}^\\mathtt{dimension} : y = |\\{i | x_i \\in S \\}|\\}``

`dimension` is the number of variables that are checked against the `set`.

Also called `among`.

## Example

    [w, x, y, z] in Count(2.0, MOI.EqualTo(3))
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
