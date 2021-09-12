module ConstraintProgrammingExtensions

import MathOptInterface
const MOI = MathOptInterface
const MOIU = MOI.Utilities

import Base: sign, copy, convert

# Planned MOI contributions.
include("moi_traits.jl")

# Actual content.
include("sets.jl") # Most sets.
include("sets_combinatorial.jl") # Sets related to typical combinatorial problems.
include("sets_combinatorial_binpacking.jl")
include("sets_combinatorial_knapsack.jl")
include("sets_count.jl") # Sets related to counting.
include("sets_functions.jl") # Sets related to functions (first argument: image of the function; other arguments: arguments of the function).
include("sets_sorting.jl") # Sets related to sorting values.
include("sets_strictly.jl") # Strictly is defined for many of the above sets (sets.jl and sets_sorting.jl).
include("sets_scheduling.jl") # Sets related to scheduling.
include("sets_graph.jl") # Sets that work on graphs.
include("sets_reification.jl") # Sets that rely on the concept of reification (also called logical constraints).

include("Bridges/Bridges.jl")
include("DeprecatedTest/DeprecatedTest.jl")
include("Test/Test.jl")

include("FlatZinc/FlatZinc.jl")
include("XCSP/XCSP.jl")

end
