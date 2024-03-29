@testset "Inverse" begin
    mock = MOIU.MockOptimizer(MOIU.UniversalFallback(MOIU.Model{Int}()))
    config = MOIT.Config()

    MOIU.set_mock_optimize!(
        mock,
        (mock::MOIU.MockOptimizer) -> (MOIU.mock_optimize!(mock, [2, 1, 2, 1])),
        (mock::MOIU.MockOptimizer) -> (MOIU.mock_optimize!(mock, [2, 1, 2, 1])),
    )
    COIDT.inversetest(mock, config)
end
