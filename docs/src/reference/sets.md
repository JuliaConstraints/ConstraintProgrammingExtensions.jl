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

```@docs
Contiguity
```

### Bin packing

```@docs
BinPacking
BinPackingCapacityType
```

### Knapsack

```@docs
Knapsack
KnapsackCapacityType
KnapsackValueType
```

## Counting constraints

```@docs
Count
CountCompare
```

### Global cardinality

```@docs
GlobalCardinality
CountedValuesType
CountedValuesClosureType
```

## Graph constraints

```@docs
Walk
```

## Reification constraints

```@docs
Reification
Equivalence
EquivalenceNot
IfThenElse
Implication
Conjunction
Disjunction
Negation
True
False
```

## Scheduling constraints

### Cumulative resource 

```@docs
CumulativeResource
CumulativeResourceDeadlineType
```

### Non-overlapping orthotopes

```@docs
NonOverlappingOrthotopes
NonOverlappingOrthotopesConditionalityType
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
