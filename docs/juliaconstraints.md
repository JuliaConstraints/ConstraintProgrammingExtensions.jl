All the constraints of the [JuliaConstraints ecosystem](https://github.com/JuliaConstraints) are supported, with the exception of `always_true`: 

* `all_different`: `AllDifferent` set
* `all_equal`: either a set of equalities or `MaximumDistance`
* `all_equal_param`: a set of equalities to the constant
* `always_true`: this constraint is always true, i.e. it does not fit into the usual variable-in-set paradigm of MathOptInterface, as there is no variable in this set
* `dist_different`: `DifferentFrom` set
* `eq`: standard `MOI.EqualTo`
* `ordered`: `Sort` set

(Order from [Constraints.jl](https://github.com/JuliaConstraints/Constraints.jl/blob/main/src/Constraints.jl).)
