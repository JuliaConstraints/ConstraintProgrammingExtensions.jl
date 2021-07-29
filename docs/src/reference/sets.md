```@meta
CurrentModule = ConstraintProgrammingExtensions
```

# [Sets](@id sets_ref)

## Generic CP sets

### Domain of variables

```@docs
Domain
VectorDomain
AntiDomain
VectorAntiDomain
Membership
```

### Array indexing

```@docs
Element
ElementVariableArray
```

### Others

```@docs
AllEqual
AllDifferent
AllDifferentExceptConstants
AllDifferentExceptConstant
SymmetricAllDifferent
DifferentFrom
MinimumDistance
MaximumDistance
Inverse
SlidingSum
ValuePrecedence
```

## Combinatorial constraints

### Bin packing

```@docs
BinPacking
FixedCapacityBinPacking
VariableCapacityBinPacking
```

### Knapsack

```@docs
Knapsack
VariableCapacityKnapsack
ValuedKnapsack
VariableCapacityValuedKnapsack
```

### Others

```@docs
Contiguity
```

## Counting constraints

```@docs
Count
GlobalCardinality
GlobalCardinalityVariable
ClosedGlobalCardinality
ClosedGlobalCardinalityVariable
CountCompare
CountDistinct
```

## Graph constraints

```@docs
Circuit
CircuitPath
WeightedCircuit
WeightedCircuitPath
```

## Reification constraints

```@docs
Reification
Equivalence
EquivalenceNot
IfThenElse
Imply
Conjunction
Disjunction
Negation
True
False
```

## Scheduling constraints

```@docs
CumulativeResource
CumulativeResourceWithDeadline
NonOverlappingOrthotopes
ConditionallyNonOverlappingOrthotopes
```

## Sorting constraints

### Lexicographic order

```@docs
LexicographicallyLessThan
LexicographicallyGreaterThan
DoublyLexicographicallyLessThan
DoublyLexicographicallyGreaterThan
```

### Typical order

```@docs
Sort
SortPermutation
```

### Extrema

```@docs
MaximumAmong
MinimumAmong
ArgumentMaximumAmong
ArgumentMinimumAmong
```

## Strict constraints

```@docs
Strictly
```