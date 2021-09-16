@testset "Lexicographically" begin
    mock = MOIU.MockOptimizer(MOIU.UniversalFallback(MOIU.Model{Int}()))
    config = MOIT.Config()

    MOIU.set_mock_optimize!(
        mock,
        (mock::MOIU.MockOptimizer) -> (MOIU.mock_optimize!(mock, [2, 2, 2, 2])),
        (mock::MOIU.MockOptimizer) -> (MOIU.mock_optimize!(mock, [2, 2, 2, 2])),
    )
    COIDT.lexicographicallytest(mock, config)
end
