@testset "Domain" begin
    mock = MOIU.MockOptimizer(MOIU.UniversalFallback(MOIU.Model{Int}()))
    config = MOIT.TestConfig()

    MOIU.set_mock_optimize!(
        mock,
        (mock::MOIU.MockOptimizer) -> (MOIU.mock_optimize!(mock, [1, 2])),
        (mock::MOIU.MockOptimizer) -> (MOIU.mock_optimize!(mock, [1, 2])),
    )
    COIT.domaintest(mock, config)
end
