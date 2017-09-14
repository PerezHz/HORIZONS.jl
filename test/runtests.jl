using HORIZONS, Expect
using Base.Test

@testset "Test connection to HORIZONS machine using Expect.jl" begin
    # @show `telnet $(HORIZONS.HORIZONS_MACHINE) 6775`
    proc = ExpectProc(`telnet $(HORIZONS.HORIZONS_MACHINE) 6775`, 15)

    # Get main prompt and proceed, turning off paging, specifying I/O model,
    # and sending object look-up from command-line 
    idx = expect!(proc, ["unknown host", "Horizons> "])
    if idx == 1
        throw("This system cannot find $HORIZONS_MACHINE")
    end
    @test idx == 2
end

@testset "Test output formatting" begin
    apophisvt = vec_tbl("Apophis", CSV_FORMAT=true);
    @test isa(apophisvt, String)
    @test contains(apophisvt, "\$\$SOE")
    @test contains(apophisvt, "\$\$EOE")
    @test ismatch(r"\$\$SOE", apophisvt)
    @test ismatch(r"\$\$EOE", apophisvt)
    mSOE = match(r"\$\$SOE", apophisvt)
    mEOE = match(r"\$\$EOE", apophisvt);
    @test mSOE.offsets == Int64[]
    @test mEOE.offsets == Int64[]
end
