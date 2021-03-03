module ConstraintProgrammingExtensions

import MathOptInterface
const MOI = MathOptInterface
const MOIU = MOI.Utilities

include("sets.jl") # Most sets.
include("sets_reification.jl") # Sets that rely on the concept of reification.

end
