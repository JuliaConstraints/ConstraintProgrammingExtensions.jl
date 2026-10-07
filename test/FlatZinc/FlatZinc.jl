@testset "FlatZinc" begin
    include("model.jl")
    include("export.jl")
    include("import.jl")
    include("optimizer.jl")
end
