@testset "Reification" begin
    mock = MOIU.MockOptimizer(MOIU.UniversalFallback(MOIU.Model{Int}()))
    config = MOIT.TestConfig()

    MOIU.set_mock_optimize!(
        mock,
        (mock::MOIU.MockOptimizer) -> (MOIU.mock_optimize!(mock, [0, 1])),
        (mock::MOIU.MockOptimizer) -> (MOIU.mock_optimize!(mock, [0, 1])),
    )
    COIT.reificationtest(mock, config)
end
