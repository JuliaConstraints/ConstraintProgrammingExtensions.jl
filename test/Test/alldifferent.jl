@testset "AllDifferent" begin
    mock = MOIU.MockOptimizer(MOIU.Model{Float64}())
    config = MOIT.TestConfig()
    
    MOIU.set_mock_optimize!(
        mock,
        (mock::MOIU.MockOptimizer) -> (MOIU.mock_optimize!(mock, [1, 2])),
        (mock::MOIU.MockOptimizer) -> (MOIU.mock_optimize!(mock, [1, 2])),
    )
    COIT.alldifferenttest(mock, config)
end
