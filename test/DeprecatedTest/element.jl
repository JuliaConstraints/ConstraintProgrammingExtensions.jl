@testset "Element" begin
    mock = MOIU.MockOptimizer(MOIU.UniversalFallback(MOIU.Model{Int}()))
    config = MOIT.Config()

    MOIU.set_mock_optimize!(
        mock,
        (mock::MOIU.MockOptimizer) -> (MOIU.mock_optimize!(mock, [1, 5])),
        (mock::MOIU.MockOptimizer) -> (MOIU.mock_optimize!(mock, [1, 5])),
    )
    COIDT.elementtest(mock, config)
end
