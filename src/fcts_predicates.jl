# -----------------------------------------------------------------------------
# - Reification
# -----------------------------------------------------------------------------

struct EquivalenceFunction{F <: NL_SV_FCT, G <: NL_SV_FCT} <: AbstractNonlinearPredicate
    f1::F
    f2::G
end

struct IfThenElseFunction{F <: NL_SV_FCT, G <: NL_SV_FCT, H <: NL_SV_FCT} <: AbstractNonlinearPredicate
    condition::F
    true_constraint::G
    false_constraint::H
end

struct ImplyFunction{F <: NL_SV_FCT, G <: NL_SV_FCT} <: AbstractNonlinearPredicate
    antecedent::F
    consequent::G
end

struct ConjunctionFunction{F <: NL_SV_FCT} <: AbstractNonlinearPredicate
    conditions::Vector{<:F}
end

struct DisjunctionFunction{F <: NL_SV_FCT} <: AbstractNonlinearPredicate
    conditions::Vector{<:F}
end

struct NegationFunction{F <: NL_SV_FCT} <: AbstractNonlinearPredicate
    condition::F
end

struct TrueFunction{F <: NL_SV_FCT} <: AbstractNonlinearPredicate
end

struct FalseFunction{F <: NL_SV_FCT} <: AbstractNonlinearPredicate
end

# -----------------------------------------------------------------------------
# - Sorting
# -----------------------------------------------------------------------------

struct IsLexicographicallyLessThanFunction{F <: NL_SV_FCT, G <: NL_SV_FCT} <: AbstractNonlinearPredicate
    f1::Vector{<:F}
    f2::Vector{<:G}
end

struct IsLexicographicallyGreaterThanFunction{F <: NL_SV_FCT, G <: NL_SV_FCT} <: AbstractNonlinearPredicate
    f1::Vector{<:F}
    f2::Vector{<:G}
end

struct IsSortedFunction{F <: NL_SV_FCT} <: AbstractNonlinearPredicate
    f::Vector{<:F}
end

struct IsPermutationSortedFunction{F <: NL_SV_FCT} <: AbstractNonlinearPredicate
    f::Vector{<:F}
end

struct IsMinimumAmongFunction{F <: NL_SV_FCT} <: AbstractNonlinearPredicate
    f::Vector{<:F}
end

struct IsMaximumAmongFunction{F <: NL_SV_FCT} <: AbstractNonlinearPredicate
    f::Vector{<:F}
end

struct IsArgumentMinimumAmongFunction{F <: NL_SV_FCT} <: AbstractNonlinearPredicate
    f::Vector{<:F}
end

struct IsArgumentMaximumAmongFunction{F <: NL_SV_FCT} <: AbstractNonlinearPredicate
    f::Vector{<:F}
end

struct IsIncreasingFunction{F <: NL_SV_FCT} <: AbstractNonlinearPredicate
    f::Vector{<:F}
end

struct IsDecreasingFunction{F <: NL_SV_FCT} <: AbstractNonlinearPredicate
    f::Vector{<:F}
end

# -----------------------------------------------------------------------------
# - Graphs
# -----------------------------------------------------------------------------

struct IsCircuitFunction{F <: NL_SV_FCT} <: AbstractNonlinearPredicate
    f::Vector{<:F}
end

struct IsCircuitPathFunction{F <: NL_SV_FCT} <: AbstractNonlinearPredicate
    f::Vector{<:F}
end

# -----------------------------------------------------------------------------
# - Combinatorial
# -----------------------------------------------------------------------------

struct IsBinPackingFunction{F <: NL_SV_FCT} <: AbstractNonlinearPredicate
    f::Vector{<:F}
    n_bins::Int
    n_items::Int
end

struct IsCapacitatedBinPackingFunction{F <: NL_SV_FCT, G <: Union{NL_SV_FCT, Real}, T <: Real} <: AbstractNonlinearPredicate
    bins::Vector{<:F}
    capacity::Vector{<:G}
    n_bins::Int
    n_items::Int
    weights::Vector{T}
end

struct IsKnapsackFunction{F <: NL_SV_FCT, G <: Union{NL_SV_FCT, Real}, T <: Real} <: AbstractNonlinearPredicate
    in_knapsack::Vector{<:F}
    capacity::G
    weights::Vector{T}
end
