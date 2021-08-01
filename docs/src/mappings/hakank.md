All the constraints that are currently defined in [hakank's constraints_utils.jl](http://hakank.org/julia/constraints/constraints_utils.jl): 

* `increasing`: `Increasing`
* `decreasing`: `Decreasing`
* `increasing_strict`: `Strictly(Increasing)`
* `decreasing_strict`: `Strictly(Decreasing)`
* `all_different_except_c`: `AllDifferentExceptConstants`
* `count_ctr`: `Count` (except for operators)
* `count_ctr2`: `CountDistinct` (except for operators)
* `global_cardinality_count`: `Count`
* `either_eq`: `Disjunction`
* `is_member_of`: `Domain` and `Membership`
* `cumulative`: `CumulativeResource` and `CumulativeResourceWithDeadline`
* `circuit`: `Circuit` and `WeightedCircuit`
* `circuit_path`: `CircuitPath` and `WeightedCircuitPath`
* `inverse`: `Inverse`
* `assignment`: `Inverse`
* `assignment_ctr`: not yet
* `matrix_element`: `Element`, but to generalise to more than one dimension
* `regular`: not yet (no representation of finite automata in Julia)
* `atmost`: `Count` with `LessThan`
* `atleast`: `Count` with `GreaterThan`
* `exactly`: `Count`
* `latin_square`: `AllDifferent`
* `no_overlap`: not yet (no representation of intervals)
* `global_contiguity_regular`: `Contiguity`
* `lex_less_eq`: `LexicographicallyLessThan`
* `among`: `Count`

Functions: TODO