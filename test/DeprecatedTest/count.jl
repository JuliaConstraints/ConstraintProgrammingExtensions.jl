@testset "Count" begin
    mock = MOIU.MockOptimizer(MOIU.UniversalFallback(MOIU.Model{Int}()))
    config = MOIT.Config()

    MOIU.set_mock_optimize!(
        mock,
        (mock::MOIU.MockOptimizer) -> (MOIU.mock_optimize!(mock, [1, 1, 2, 2])),
        (mock::MOIU.MockOptimizer) -> (MOIU.mock_optimize!(mock, [1, 1, 2, 2])),
    )
    COIT.counttest(mock, config)
end
