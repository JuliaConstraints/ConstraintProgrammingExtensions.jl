module FlatZinc

import MathOptInterface
import ConstraintProgrammingExtensions

const MOI = MathOptInterface
const MOIU = MOI.Utilities
const CleverDicts = MOIU.CleverDicts
const CP = ConstraintProgrammingExtensions

# Formal grammar: https://www.minizinc.org/doc-2.5.5/en/fzn-spec.html#grammar
include("model.jl")
include("export.jl")
include("import.jl")
include("optimizer.jl")

end
