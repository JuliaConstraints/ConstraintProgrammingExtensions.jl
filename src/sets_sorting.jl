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
    ChainedLexicographicallyLessThan(row_dim::Int, column_dim::Int)

Ensures that each column of the matrix is lexicographically less than 
the next column. 

The matrix is encoded by stacking the columns, matching the behaviour of
Julia's `vec` function.
"""
struct ChainedLexicographicallyLessThan <: MOI.AbstractVectorSet
    row_dim::Int
    column_dim::Int
end

MOI.dimension(set::ChainedLexicographicallyLessThan) = set.row_dim * set.column_dim

"""
    ChainedLexicographicallyGreaterThan(row_dim::Int, column_dim::Int)

Ensures that each column of the matrix is lexicographically greater than 
the next column. 

The matrix is encoded by stacking the columns, matching the behaviour of
Julia's `vec` function.
"""
struct ChainedLexicographicallyGreaterThan <: MOI.AbstractVectorSet
    row_dim::Int
    column_dim::Int
end

MOI.dimension(set::ChainedLexicographicallyGreaterThan) = set.row_dim * set.column_dim

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

Ensures that the first `dimension` elements is a sorted copy of the next
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

MOI.dimension(set::SortPermutation) = 3 * set.dimension

"""
    MinimumAmong(dimension::Int)

Ensures that the first element is the minimum value among the next 
`dimension` elements.

## Example

    [a, b, c] in MinimumAmong(2)
    # Enforces that a == min(b, c)
"""
struct MinimumAmong <: MOI.AbstractVectorSet
    dimension::Int
end

MOI.dimension(set::MinimumAmong) = 1 + set.dimension

"""
    ArgumentMinimumAmong(dimension::Int)

Ensures that the first element is the index of the minimum value among the 
next `dimension` elements.

## Example

    [a, b, c] in ArgumentMinimumAmong(2)
    # Enforces that a == argmin(b, c)
    # I.e., if b < c, a = 1, if b > c, a = 2
"""
struct ArgumentMinimumAmong <: MOI.AbstractVectorSet
    dimension::Int
end

MOI.dimension(set::ArgumentMinimumAmong) = 1 + set.dimension

"""
    MaximumAmong(dimension::Int)

Ensures that the first element is the maximum value among the next 
`dimension` elements.

## Example

    [a, b, c] in MaximumAmong(2)
    # Enforces that a == max(b, c)
"""
struct MaximumAmong <: MOI.AbstractVectorSet
    dimension::Int
end

MOI.dimension(set::MaximumAmong) = 1 + set.dimension

"""
    ArgumentMaximumAmong(dimension::Int)

Ensures that the first element is the index of the maximum value among the 
next `dimension` elements.

## Example

    [a, b, c] in ArgumentMaximumAmong(2)
    # Enforces that a == argmax(b, c)
    # I.e., if b > c, a = 1, if b < c, a = 2
"""
struct ArgumentMaximumAmong <: MOI.AbstractVectorSet
    dimension::Int
end

MOI.dimension(set::ArgumentMaximumAmong) = 1 + set.dimension

"""
    Increasing(dimension::Int)

Ensures that the elements of the vector are in increasing order (<= operation).

## Example

    [a, b, c] in Increasing(3)
    # Enforces that a <= b <= c
"""
struct Increasing <: MOI.AbstractVectorSet
    dimension::Int
end

"""
    Decreasing(dimension::Int)

Ensures that the elements of the vector are in decreasing order (>= operation).

## Example

    [a, b, c] in Decreasing(3)
    # Enforces that a >= b >= c
"""
struct Decreasing <: MOI.AbstractVectorSet
    dimension::Int
end

# isbits types, nothing to copy
function copy(
    set::Union{
        LexicographicallyLessThan,
        LexicographicallyGreaterThan,
        Sort,
        SortPermutation,
        MinimumAmong,
        ArgumentMinimumAmong,
        MaximumAmong,
        ArgumentMaximumAmong,
        Increasing,
        Decreasing,
    },
)
    return set
end
