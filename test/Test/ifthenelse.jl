@testset "IfThenElse" begin
    mock = MOIU.MockOptimizer(MOIU.UniversalFallback(MOIU.Model{Int}()))
    config = MOIT.TestConfig()

    MOIU.set_mock_optimize!(
        mock,
        (mock::MOIU.MockOptimizer) -> (MOIU.mock_optimize!(mock, [1, 1, 0])),
        (mock::MOIU.MockOptimizer) -> (MOIU.mock_optimize!(mock, [1, 1, 0])),
    )
    COIT.ifthenelsetest(mock, config)
end
