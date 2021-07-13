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
    GlobalCardinality{T}(dimension::Int, values::Vector{T})

``\\{(x, y) \\in \\mathbb{R}^\\mathtt{dimension} \\times \\mathbb{N}^d : y_i = |\\{ j | x_j = \\mathtt{values}_i, \\forall j \\}| \\}``

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
struct GlobalCardinality{T} <: MOI.AbstractVectorSet
    dimension::Int
    values::Vector{T}
end

MOI.dimension(set::GlobalCardinality) = set.dimension + length(set.values)
copy(set::GlobalCardinality) = GlobalCardinality(set.dimension, copy(set.values))
function Base.:(==)(x::GlobalCardinality, y::GlobalCardinality)
    return x.dimension == y.dimension && x.values == y.values
end

"""
    GlobalCardinalityVariable(dimension::Int, n_values::Int)

``\\{(x, y, z) \\in \\mathbb{R}^\\mathtt{dimension} \\times \\mathbb{N}^\\mathtt{n\\_values} \\times \\mathbb{R}^\\mathtt{n\\_values} : y_i = |\\{ j | x_j = z_i, \\forall j \\}| \\}``

The first `dimension` variables are an array, the next `n_values` variables 
are the number of times that each item of the last `n_values` variables is 
present in the first array. Values of the first array that are not in the 
`n_values` are ignored. 

Also called `distribute`.

## Example

    [x, y, z, t, u, v, w] in GlobalCardinalityVariable(3, 2)
    # t == sum([x, y, z] .== v)
    # u == sum([x, y, z] .== w)
"""
struct GlobalCardinalityVariable <: MOI.AbstractVectorSet
    dimension::Int
    n_values::Int
end

MOI.dimension(set::GlobalCardinalityVariable) = set.dimension + 2 * set.n_values

"""
    ClosedGlobalCardinality{T}(dimension::Int, values::Vector{T})

``\\{(x, y) \\in \\mathbb{R}^\\mathtt{dimension} \\times \\mathbb{N}^d : y_i = |\\{ j | x_j = \\mathtt{values}_i, \\forall j \\}| \\}``

The first `dimension` variables are an array, the last variables are the 
number of times that each item of `values` is present in the first array.
Each value of the first array must be within `values`.

## Example

    [x, y, z, v, w] in ClosedGlobalCardinality(3, [2.0, 4.0])
    # v == sum([x, y, z] .== 2.0)
    # w == sum([x, y, z] .== 4.0)
    # x ∈ [2.0, 4.0], y ∈ [2.0, 4.0], z ∈ [2.0, 4.0]
"""
struct ClosedGlobalCardinality{T} <: MOI.AbstractVectorSet
    dimension::Int
    values::Vector{T}
end

MOI.dimension(set::ClosedGlobalCardinality) = set.dimension + length(set.values)
copy(set::ClosedGlobalCardinality) = ClosedGlobalCardinality(set.dimension, copy(set.values))
function Base.:(==)(x::ClosedGlobalCardinality, y::ClosedGlobalCardinality)
    return x.dimension == y.dimension && x.values == y.values
end

"""
    ClosedGlobalCardinalityVariable(dimension::Int, n_values::Int)

``\\{(x, y, z) \\in \\mathbb{R}^\\mathtt{dimension} \\times \\mathbb{N}^\\mathtt{n\\_values} \\times \\mathbb{R}^\\mathtt{n\\_values} : y_i = |\\{ j | x_j = z_i, \\forall j \\}| \\}``

The first `dimension` variables are an array, the next `n_values` variables 
are the number of times that each item of the last `n_values` variables is 
present in the first array. Each value of the first array must be within the 
next given `n_values`.

Also called `distribute`.

## Example

    [x, y, z, t, u, v, w] in ClosedGlobalCardinalityVariable(3, 2)
    # t == sum([x, y, z] .== v)
    # u == sum([x, y, z] .== w)
    # x ∈ [v, w], y ∈ [v, w], z ∈ [v, w]
"""
struct ClosedGlobalCardinalityVariable <: MOI.AbstractVectorSet
    dimension::Int
    n_values::Int
end

MOI.dimension(set::ClosedGlobalCardinalityVariable) = set.dimension + 2 * set.n_values

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
    set::Union{CountCompare, CountDistinct, GlobalCardinalityVariable, ClosedGlobalCardinalityVariable},
)
    return set
end
