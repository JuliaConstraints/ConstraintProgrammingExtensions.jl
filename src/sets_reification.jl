"""
    Reification{S <: MOI.AbstractSet}(set::S)

``\\{(y, x) \\in \\{0, 1\\} \\times \\mathbb{R}^n | y = 1 \\iff x \\in set, y = 0 otherwise\\}``.

This set serves to find out whether a given constraint is satisfied.

The only possible values are 0 and 1 for the first variable of the set.
"""
struct Reification{S <: MOI.AbstractSet} <: MOI.AbstractVectorSet
    set::S
end

MOI.dimension(set::Reification{S}) where {S} = 1 + MOI.dimension(set.set)
copy(set::Reification{S}) where {S} = Reification(copy(set.set))
Base.:(==)(x::Reification{S}, y::Reification{S}) where {S} = x.set == y.set

"""
    Equivalence{S1 <: MOI.AbstractSet, S2 <: MOI.AbstractSet}(set1::S1, 
                                                              set2::S2)

The logical equivalence operator ≡ or ⇔.

``\\{(x, y) \\in \\mathbb{R}^{a+b} | x \\in S1 \\iff y \\in S2\\}``.

The two constraints must be either satisfied or not satisfied at the same time.
More explicitly, if the first one is satisfied, then the second one is implied
to be satisfied too; if the second one is satisfied, then the first one is 
implied.
"""
struct Equivalence{S1 <: MOI.AbstractSet, S2 <: MOI.AbstractSet} <:
       MOI.AbstractVectorSet
    set1::S1
    set2::S2
end

function MOI.dimension(set::Equivalence{S, T}) where {S, T}
    return MOI.dimension(set.set1) + MOI.dimension(set.set2)
end

function copy(set::Equivalence{S, T}) where {S, T}
    return Equivalence(copy(set.set1), copy(set.set2))
end

function Base.:(==)(x::Equivalence{S, T}, y::Equivalence{S, T}) where {S, T}
    return x.set1 == y.set1 && x.set2 == y.set2
end

"""
EquivalenceNot{S1 <: MOI.AbstractSet, S2 <: MOI.AbstractSet}(set1::S1, 
                                                                set2::S2)

The logical equivalence operator ≡ or ⇔, with the second argument negated.

``\\{(x, y) \\in \\mathbb{R}^{a+b} | x \\in S1 \\iff y \\not\\in S2\\}``.
"""
struct EquivalenceNot{S1 <: MOI.AbstractSet, S2 <: MOI.AbstractSet} <:
       MOI.AbstractVectorSet
    set1::S1
    set2::S2
end

function MOI.dimension(set::EquivalenceNot{S, T}) where {S, T}
    return MOI.dimension(set.set1) + MOI.dimension(set.set2)
end

function copy(set::EquivalenceNot{S, T}) where {S, T}
    return EquivalenceNot(copy(set.set1), copy(set.set2))
end

function Base.:(==)(x::EquivalenceNot{S, T}, y::EquivalenceNot{S, T}) where {S, T}
    return x.set1 == y.set1 && x.set2 == y.set2
end

"""
    IfThenElse{
        Condition <: MOI.AbstractSet, 
        TrueConstraint <: MOI.AbstractSet, 
        FalseConstraint <: MOI.AbstractSet
    }(condition::Condition, true_constraint::TrueConstraint, 
      false_constraint::FalseConstraint)

The ternary operator.

If the `condition` is satisfied, then the first constraint (of type 
`TrueConstraint`) will be implied. Otherwise, the second constraint
(of type `FalseConstraint`) will be implied.

``\\{(x, y, z) \\in \\mathbb{R}^(a+b+c) | y \\in TrueConstraint \\iff x \\in set, z \\in FalseConstraint otherwise\\}``.
"""
struct IfThenElse{
    Condition <: MOI.AbstractSet,
    TrueConstraint <: MOI.AbstractSet,
    FalseConstraint <: MOI.AbstractSet,
} <: MOI.AbstractVectorSet
    condition::Condition
    true_constraint::TrueConstraint
    false_constraint::FalseConstraint
end

function MOI.dimension(set::IfThenElse{S, T, U}) where {S, T, U}
    return MOI.dimension(set.condition) +
           MOI.dimension(set.true_constraint) +
           MOI.dimension(set.false_constraint)
end

function copy(set::IfThenElse{S, T, U}) where {S, T, U}
    return IfThenElse(
        copy(set.condition),
        copy(set.true_constraint),
        copy(set.false_constraint),
    )
end

function Base.:(==)(x::IfThenElse{S, T, U}, y::IfThenElse{S, T, U}) where {S, T, U}
    return x.condition == y.condition && x.true_constraint == y.true_constraint && x.false_constraint == y.false_constraint
end

"""
    Imply{
        Antecedent <: MOI.AbstractSet,
        Consequent <: MOI.AbstractSet
    }(antecedent::Antecedent, consequent::Consequent)

The logical implication operator ⇒.

If the `antecedent` is satisfied, then the `consequent` will be implied to be 
satisfied. Otherwise, nothing is implied on the truth value of `consequent`.

``\\{(x, y) \\in \\mathbb{R}^a \\times \\mathbb{R}^b | y \\in Consequent if x \\in Antecedent\\}``.

Also called `if_then`, material implication, or material conditional.
"""
struct Imply{Antecedent <: MOI.AbstractSet, Consequent <: MOI.AbstractSet} <:
       MOI.AbstractVectorSet
    antecedent::Antecedent
    consequent::Consequent
end

function MOI.dimension(set::Imply{S, T}) where {S, T}
    return MOI.dimension(set.antecedent) + MOI.dimension(set.consequent)
end

function copy(set::Imply{S, T}) where {S, T}
    return Imply(copy(set.antecedent), copy(set.consequent))
end

function Base.:(==)(x::Imply{S, T}, y::Imply{S, T}) where {S, T}
    return x.antecedent == y.antecedent && x.consequent == y.consequent
end

"""
    Conjunction{Ts}(constraints::Ts)

The logical conjunction operator ∧ (AND).

``\\{(x, y\\dots) \\in \\mathbb{R}^a \\times \\mathbb{R}^b\\dots | x \\in \\mathbb{S_1} \\land y \\in \\mathbb{S_2} \\dots \\}``.
"""
struct Conjunction{Ts} <: MOI.AbstractVectorSet where {Ts <: Tuple}
    constraints::Ts
end

# Currently, no varargs for parametric types... For instance, see:
# https://discourse.julialang.org/t/user-defined-variadic-parametric-types/25487/4

function MOI.dimension(set::Conjunction{Ts}) where {Ts}
    return sum(MOI.dimension(s) for s in set.constraints)
end

function copy(set::Conjunction{Ts}) where {Ts}
    return Conjunction(deepcopy(set.constraints))
end

function Base.:(==)(x::Conjunction{Ts}, y::Conjunction{Ts}) where {Ts}
    return x.constraints == y.constraints
end

"""
    Disjunction{Ts}(constraints::Ts)

The logical disjunction operator ∨ (AND).

``\\{(x, y\\dots) \\in \\mathbb{R}^a \\times \\mathbb{R}^b\\dots | x \\in \\mathbb{S_1} \\lor y \\in \\mathbb{S_2} \\dots \\}``.
"""
struct Disjunction{Ts} <: MOI.AbstractVectorSet where {Ts <: Tuple}
    constraints::Ts
end

# Currently, no varargs for parametric types... For instance, see:
# https://discourse.julialang.org/t/user-defined-variadic-parametric-types/25487/4

function MOI.dimension(set::Disjunction{Ts}) where {Ts}
    return sum(MOI.dimension(s) for s in set.constraints)
end

function copy(set::Disjunction{Ts}) where {Ts}
    return Disjunction(deepcopy(set.constraints))
end

function Base.:(==)(x::Disjunction{Ts}, y::Disjunction{Ts}) where {Ts}
    return x.constraints == y.constraints
end

"""
    Negation{S <: MOI.AbstractSet}(set::S)

The logical negation operator ¬ (NOT).

``\\{x \\in \\times \\mathbb{R}^n | x \\not\\in set\\}``.
"""
struct Negation{S <: MOI.AbstractSet} <: MOI.AbstractVectorSet
    set::S
end

MOI.dimension(set::Negation{S}) where {S} = MOI.dimension(set.set)
copy(set::Negation{S}) where {S} = Negation(copy(set.set))
Base.:(==)(x::Negation{S}, y::Negation{S}) where {S} = x.set == y.set

"""
    True()

A constraint that is always true. 

It is only useful with reification-like constraints.
"""
struct True <: MOI.AbstractVectorSet end

MOI.dimension(set::True) = 0
Base.:(==)(::True, ::True) = true

"""
    False()

A constraint that is always false. 

It is only useful with reification-like constraints.
"""
struct False <: MOI.AbstractVectorSet end

MOI.dimension(set::False) = 0
Base.:(==)(::False, ::False) = true

# isbits types, nothing to copy
function copy(set::Union{True, False})
    return set
end
