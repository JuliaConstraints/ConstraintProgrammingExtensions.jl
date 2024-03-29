@testset "Reification" begin
    mock = MOIU.MockOptimizer(MOIU.UniversalFallback(MOIU.Model{Int}()))
    config = MOIT.Config()

    MOIU.set_mock_optimize!(
        mock,
        (mock::MOIU.MockOptimizer) -> (MOIU.mock_optimize!(mock, [0, 1])),
        (mock::MOIU.MockOptimizer) -> (MOIU.mock_optimize!(mock, [0, 1])),
    )
    COIDT.reificationtest(mock, config)
end
