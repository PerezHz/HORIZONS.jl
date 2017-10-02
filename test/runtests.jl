using HORIZONS, Expect
using Base.Test

@testset "Test connection to HORIZONS machine using Expect.jl" begin
    port = 6775
    horizons_telnet_cmd = `telnet $(HORIZONS.HORIZONS_MACHINE) $port`
    @show horizons_telnet_cmd
    proc = ExpectProc(horizons_telnet_cmd, 15)
    # Get main prompt and proceed, turning off paging, specifying I/O model,
    # and sending object look-up from command-line 
    idx = expect!(proc, ["unknown host", "Horizons> "])
    if idx == 1
        throw("This system cannot find $HORIZONS_MACHINE")
    end
    @test idx == 2
end

@testset "Test output formatting" begin
    dt0 = Dates.DateTime(2029,4,13)
    dtmax = Dates.Date(2029,4,14)
    apophisvt = vec_tbl("Apophis", dt0, dtmax, "100", CSV_FORMAT=true);
    @test isa(apophisvt, String)
    @test contains(apophisvt, "\$\$SOE")
    @test contains(apophisvt, "\$\$EOE")
    @test ismatch(r"\$\$SOE", apophisvt)
    @test ismatch(r"\$\$EOE", apophisvt)
    mSOE = match(r"\$\$SOE", apophisvt)
    mEOE = match(r"\$\$EOE", apophisvt)
    @test mSOE.offsets == Int64[]
    @test mEOE.offsets == Int64[]
end
