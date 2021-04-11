Release Notes
=============

Version 0.2.0
-------------

Interface change: `Count` becomes consistent with 
`AllDifferentExceptConstant`, with the dimension before the value.

Improved the internal test suite. 


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
