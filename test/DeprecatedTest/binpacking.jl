@testset "BinPacking" begin
    mock = MOIU.MockOptimizer(MOIU.UniversalFallback(MOIU.Model{Int}()))
    config = MOIT.Config()

    MOIU.set_mock_optimize!(
        mock,
        (mock::MOIU.MockOptimizer) -> (MOIU.mock_optimize!(mock, [4, 0, 0])),
        (mock::MOIU.MockOptimizer) -> (MOIU.mock_optimize!(mock, [4, 0, 0])),
    )
    COIDT.binpackingtest(mock, config)
end
