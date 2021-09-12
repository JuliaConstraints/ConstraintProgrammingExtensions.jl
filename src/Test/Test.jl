module Test

using Test
using MathOptInterface
using ConstraintProgrammingExtensions
const MOI = MathOptInterface
const MOIT = MOI.Test
const MOIU = MOI.Utilities
const CP = ConstraintProgrammingExtensions

const Config{T <: Real} = MOIT.Config
const setup_test = MOIT.setup_test

"""
[See MOI docs](https://jump.dev/MathOptInterface.jl/stable/submodules/Test/reference/#MathOptInterface.Test.runtests).
"""
function runtests(
    model::MOI.ModelLike,
    config::Config;
    include::Vector{String} = String[],
    exclude::Vector{String} = String[],
    warn_unsupported::Bool = false,
)
    # Copy-paste from MOI.
    for name_sym in names(@__MODULE__; all = true)
        name = string(name_sym)
        if !startswith(name, "test_")
            continue  # All test functions start with test_
        elseif !isempty(include) && !any(s -> occursin(s, name), include)
            continue
        elseif !isempty(exclude) && any(s -> occursin(s, name), exclude)
            continue
        end
        @testset "$(name)" begin
            test_function = getfield(@__MODULE__, name_sym)
            c = copy(config)
            tear_down = setup_test(test_function, model, c)
            # Make sure to empty the model before every test!
            MOI.empty!(model)
            try
                test_function(model, c)
            catch err
                _error_handler(err, name, warn_unsupported)
            end
            if tear_down !== nothing
                tear_down()
            end
        end
    end
    return
end

# Include all test files in CP.

for file in readdir(@__DIR__)
    if startswith(file, "test_")
        include(file)
    end
end

end