"""
    LexicographicallyLessThan(dimension::Int)

Ensures that each column of the matrix is lexicographically less than 
the next column. 

Formally, for two columns:

``\\{(x, y) \\in \\mathbb{R}^{dimension}} \\times \\mathbb{R}^{column\\_dim}} | \exists j \\in \\{1, 2 \\dots column\\_dim\\}: x_j < y_j, \\forall i < j, x_i = y_i \\}``.

Also called [`lex_less`](https://sofdem.github.io/gccat/gccat/Clex_less.html).

The matrix is encoded by stacking the columns, matching the behaviour of
Julia's `vec` function.
"""
struct LexicographicallyLessThan <: MOI.AbstractVectorSet
    row_dim::Int
    column_dim::Int
end

function LexicographicallyLessThan(column_dim::Int)
    # By default, only two columns.
    return LexicographicallyLessThan(2, column_dim)
end

MOI.dimension(set::LexicographicallyLessThan) = set.row_dim * set.column_dim

"""
    LexicographicallyGreaterThan(dimension::Int)

Ensures that each column of the matrix is lexicographically greater than 
the next column. 

Formally, for two columns:

``\\{(x, y) \\in \\mathbb{R}^{dimension}} \\times \\mathbb{R}^{dimension}} | \exists j \\in \\{1, 2 \\dots dimension\\}: x_j > y_j, \\forall i < j, x_i = y_i \\}``.

Also called [`lex_greater`](https://sofdem.github.io/gccat/gccat/Clex_greater.html).

The matrix is encoded by stacking the columns, matching the behaviour of
Julia's `vec` function.
"""
struct LexicographicallyGreaterThan <: MOI.AbstractVectorSet
    row_dim::Int
    column_dim::Int
end

function LexicographicallyGreaterThan(column_dim::Int)
    # By default, only two columns.
    return LexicographicallyGreaterThan(2, column_dim)
end

MOI.dimension(set::LexicographicallyGreaterThan) = set.row_dim * set.column_dim

# TODO: bridge to LexicographicallyLessThan.

"""
    DoublyLexicographicallyLessThan(dimension::Int)

Ensures that each column of the matrix is lexicographically less than 
the next column, and that each row of the matrix is lexicographically less 
than the next row. 

Also called [`lex2`](https://sofdem.github.io/gccat/gccat/Clex2.html).

The matrix is encoded by stacking the columns, matching the behaviour of
Julia's `vec` function.
"""
struct DoublyLexicographicallyLessThan <: MOI.AbstractVectorSet
    row_dim::Int
    column_dim::Int
end

MOI.dimension(set::DoublyLexicographicallyLessThan) = set.row_dim * set.column_dim

"""
    DoublyLexicographicallyGreaterThan(dimension::Int)

Ensures that each column of the matrix is lexicographically greater than 
the next column, and that each row of the matrix is lexicographically greater 
than the next row. 

The matrix is encoded by stacking the columns, matching the behaviour of
Julia's `vec` function.
"""
struct DoublyLexicographicallyGreaterThan <: MOI.AbstractVectorSet
    row_dim::Int
    column_dim::Int
end

MOI.dimension(set::DoublyLexicographicallyGreaterThan) = set.row_dim * set.column_dim

# TODO: bridge to LexicographicallyLessThan.

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
        DoublyLexicographicallyLessThan,
        DoublyLexicographicallyGreaterThan,
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
