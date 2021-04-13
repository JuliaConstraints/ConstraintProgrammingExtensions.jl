@testset "Element" begin
    mock = MOIU.MockOptimizer(MOIU.UniversalFallback(MOIU.Model{Int}()))
    config = MOIT.TestConfig()

    MOIU.set_mock_optimize!(
        mock,
        (mock::MOIU.MockOptimizer) -> (MOIU.mock_optimize!(mock, [1, 5])),
        (mock::MOIU.MockOptimizer) -> (MOIU.mock_optimize!(mock, [1, 5])),
    )
    COIT.elementtest(mock, config)
end
