@testset "Test" begin
    CP.Test.runtests(
        MOI.Utilities.MockOptimizer(
            MOI.Utilities.UniversalFallback(MOI.Utilities.Model{Int}()),
        ),
        MOI.Test.Config(),
        warn_unsupported = true,
    )
end