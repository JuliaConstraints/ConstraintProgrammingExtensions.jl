module ConstraintProgrammingExtensions

import MathOptInterface
const MOI = MathOptInterface
const MOIU = MOI.Utilities

include("moi_traits.jl")

include("sets.jl") # Most sets.
include("sets_combinatorial.jl") # Sets related to typical combinatorial problems.
include("sets_sorting.jl") # Sets related to sorting values.
include("sets_strictly.jl") # Strictly is defined for many of the above sets (sets.jl and sets_sorting.jl).
include("sets_scheduling.jl") # Sets related to scheduling.
include("sets_graph.jl") # Sets that work on graphs.
include("sets_reification.jl") # Sets that rely on the concept of reification (also called logical constraints).

include("Test/Test.jl")
include("Utilities/Utilities.jl")

include("FlatZinc/FlatZinc.jl")
include("XCSP/XCSP.jl")

end
