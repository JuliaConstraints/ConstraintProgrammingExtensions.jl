"""
    Reified{S <: MOI.AbstractSet}(set::S)

``\\{(y, x) \\in \\{0, 1\\} \\times \\mathbb{R}^n | y = 1 \\iff x \\in set, y = 0 otherwise\\}``.

This set serves to find out whether a given constraint is satisfied.

The only possible values are 0 and 1 for the first variable of the set.
"""
struct Reified{S <: MOI.AbstractSet} <: MOI.AbstractVectorSet
    set::S
end

MOI.dimension(set::Reified{S}) where {S} = 1 + MOI.dimension(set.set)
Base.copy(set::Reified{S}) where {S} = Reified(copy(set.set))

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

function Base.copy(set::Equivalence{S, T}) where {S, T}
    return Equivalence(copy(set.set), copy(set.set2))
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

function Base.copy(set::EquivalenceNot{S, T}) where {S, T}
    return EquivalenceNot(copy(set.set), copy(set.set2))
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

function Base.copy(set::IfThenElse{S, T, U}) where {S, T, U}
    return Reified(
        copy(set.condition),
        copy(set.true_constraint),
        copy(set.false_constraint),
    )
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
"""
struct Imply{
    Antecedent <: MOI.AbstractSet,
    Consequent <: MOI.AbstractSet
} <: MOI.AbstractVectorSet
    antecedent::Antecedent
    consequent::Consequent
end

function MOI.dimension(set::Imply{S, T}) where {S, T}
    return MOI.dimension(set.antecedent) +
           MOI.dimension(set.consequent)
end

function Base.copy(set::Imply{S, T}) where {S, T}
    return Reified(
        copy(set.antecedent),
        copy(set.consequent),
    )
end

"""
    True()

A constraint that is always true. 

It is only useful with reification-like constraints.
"""
struct True <: MOI.AbstractVectorSet
end

MOI.dimension(set::True) = 0
Base.copy(set::True) = set

"""
    False()

A constraint that is always false. 

It is only useful with reification-like constraints.
"""
struct False <: MOI.AbstractVectorSet
end

MOI.dimension(set::False) = 0
Base.copy(set::False) = set
