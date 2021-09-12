@testset "AntiDomain" begin
    mock = MOIU.MockOptimizer(MOIU.UniversalFallback(MOIU.Model{Int}()))
    config = MOIT.Config()

    MOIU.set_mock_optimize!(
        mock,
        (mock::MOIU.MockOptimizer) -> (MOIU.mock_optimize!(mock, [1, 2])),
        (mock::MOIU.MockOptimizer) -> (MOIU.mock_optimize!(mock, [1, 2])),
    )
    COIT.antidomaintest(mock, config)
end
