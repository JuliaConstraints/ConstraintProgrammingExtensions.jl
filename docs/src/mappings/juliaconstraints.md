# JuliaConstraints

All the constraints of the [JuliaConstraints ecosystem](https://github.com/JuliaConstraints) are supported, with the exception of `always_true`: 

* `all_different`: `AllDifferent` set
* `all_equal`: either a set of equalities or `MaximumDistance`
* `all_equal_param`: a set of equalities to the constant
* `always_true`: `True` set
* `dist_different`: `DifferentFrom` set
* `eq`: standard `MOI.EqualTo`
* `ordered`: `Sort` set

(Order from [Constraints.jl](https://github.com/JuliaConstraints/Constraints.jl/blob/main/src/Constraints.jl).)
