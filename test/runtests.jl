using HORIZONS
using Base.Test

@testset "Some basic tests" begin
    apophisvt = vec_tbl("Apophis", CSV_FORMAT=true);
    @test isa(apophisvt, String)
    @test contains(apophisvt, "\$\$SOE")
    @test contains(apophisvt, "\$\$EOE")
    @test ismatch(r"\$\$SOE", apophisvt)
    @test ismatch(r"\$\$EOE", apophisvt)
    @test mSOE.offsets == Int64[]
    @test mEOE.offsets == Int64[]
end
