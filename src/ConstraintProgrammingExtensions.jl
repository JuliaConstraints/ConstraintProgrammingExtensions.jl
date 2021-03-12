module ConstraintProgrammingExtensions

import MathOptInterface
const MOI = MathOptInterface
const MOIU = MOI.Utilities

include("sets.jl") # Most sets.
include("sets_sorting.jl") # Sets related to sorting values.
include("sets_strictly.jl") # Strictly is defined for many of the above sets (sets.jl and sets_sorting.jl).
include("sets_scheduling.jl") # Sets related to scheduling.
include("sets_graph.jl") # Sets that work on graphs.
include("sets_reification.jl") # Sets that rely on the concept of reification.

end
