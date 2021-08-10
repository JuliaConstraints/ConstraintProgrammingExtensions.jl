Release Notes
=============

Version 0.4.0
-------------

Refactor for sets with many variants. Discussion: 

* https://github.com/dourouc05/ConstraintProgrammingExtensions.jl/issues/22 
* https://github.com/dourouc05/ConstraintProgrammingExtensions.jl/pull/23

The following sets have been touched by the refactor: 

* `CumulativeResource` and friend
* `GlobalCardinality` and friends
* `Knapsack` and friends
* `NonOverlappingOrthotopes` and friend

Experiments with functions are removed for now.

For consistency, `Imply` has been renamed `Implication`.


Version 0.3.2
-------------

Added a bridge to change the sign of strict inequalities.


Version 0.3.1
-------------

Added test sets for `MOI.IndicatorSet`. 

Fixed bug in the reported required constraint types for the bridges.

Added an online documentation.


Version 0.3.0
-------------

Generalise `Count` to any kind of comparison for items, not just equality. 
(The user-facing interface is the same.)

Add many new sets: 

* `VectorDomain` 
* `VectorAntiDomain`
* `AllDifferentExceptConstants`; `AllDifferentExceptConstant` becomes a 
  constructor for the former
* `NonOverlappingOrthotopes` 
* `ConditionallyNonOverlappingOrthotopes`
* `GlobalCardinality`
* `GlobalCardinalityVariable`
* `SymmetricAllDifferent`
* `ClosedGlobalCardinality`
* `ClosedGlobalCardinalityVariable`
* `DoublyLexicographicallyGreaterThan`
* `DoublyLexicographicallyLessThan`
* `SlidingSum`
* `ValuePrecedence`

Add many new bridges between high-level constraints, and also to MILP models.

`Reified` has been renamed to `Reification` for consistency.

There are still no compatibility guarantees for nonlinear functions.


Version 0.2.5
-------------

Added the `ValuedKnapsack`, `ValuedVariableCapacityKnapsack`, and `AllEqual` 
sets. Added sets for functions: `AbsoluteValue`.

Added bridges between high-level constraints, and also to MILP models.

Nonlinear functions have been added, but are not yet used anywhere. No 
semantic versioning is guaranteed for now regarding them.


Version 0.2.4
-------------

Added the `ElementVariableArray` set.

Support FlatZinc reading.


Version 0.2.3
-------------

Various fixes for the FlatZinc output, which is now tested more thoroughly.
Reified constraints are also supported.


Version 0.2.2
-------------

Test suite for the `Test` submodule. The test for `Strictly` has been split
into two parts.


Version 0.2.1
-------------

Hotfix: the test sets for solvers were not fully updated to the latest API 
changes.


Version 0.2.0
-------------

Models can be exported as FlatZinc (submodule FlatZinc), a subset of MiniZinc.

Interface change: `Count`, `MaximumDistance`, and `MinimumDistance` become 
consistent with `AllDifferentExceptConstant`, with the dimension before the value.

Revamped the internal test suite. Many bugs have been discovered and fixed: 
typos, missing `copy` functions or equality comparisons, mostly.


Version 0.1.2
-------------

Added a test suite for solvers implementing this interface. It is based on the 
corresponding CPLEXCP tests, and is not yet complete. It can be used exactly 
like MathOptInterface's `Test` module. 

Added a comparison with the Numberjack modelling layer. 


Version 0.1.1
-------------

Added a few more sets: `AllDifferentExceptConstant`, `ArgumentMinimumAmong`, 
`ArgumentMaximumAmong`, `Circuit`, `CircuitPath`, `Conjunction`, `Contiguity`, 
`CountDistinct`, `Cumulative`, `Decreasing`, `Disjunction`, `Increasing`, 
`Knapsack`, `MaximumAmong`, `MinimumAmong`, `Negation`.

Added a comparison with Hakank's supplementary constraints


Version 0.1.0
-------------

Add a few more sets: `Equivalence`, `EquivalenceNot`, `False`, `IfThenElse`, 
`Imply`, `MaximumDistance`, `True`.

Added a comparison with ConstraintSolver.jl's constraints.
