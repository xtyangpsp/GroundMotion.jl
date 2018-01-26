using Base.Test, GroundMotion

# constants
TEST_GRID_SIZE = 17
WITH_MINPGA = 8
SIMULATION_ARRAY_SIZE = 1000
# load vs30 grid
grid = read_vs30_file("testvs30.txt")
# set earthquake location
eq_6 = Earthquake(143.04,51.92,13,6)
eq_7 = Earthquake(143.04,51.92,13,7.0)
eq_4 = Earthquake(143.04,51.92,13,4)

@testset "GRID'S read/convert" begin
  @test typeof(grid) == Array{GroundMotion.Point_vs30,1}
  @test length(grid) == TEST_GRID_SIZE
  # get PGA data grid and test it
  include("../examples/as2008.conf")
  pga_grid = pga_as2008(eq_6,grid,config_as2008)
  @test typeof(pga_grid) == Array{GroundMotion.Point_pga_out,1}
  # convert to float array
  A = convert_to_float_array(grid)
  @test typeof(A) == Array{Float64,2}
  @test length(A) == 51
  @test round(sum(A[:,3]),2) == 12400.0
  A = convert_to_float_array(pga_grid)
  @test typeof(A) == Array{Float64,2}
  @test length(A) == 51
  @test round(sum(A[:,3]),2) == 4.39
end

@testset "AS2008 GMPE" begin
  # init model parameters
  include("../examples/as2008.conf")
  # test at epicenter with M7.0, VS=350 
  grid_1 = [Point_vs30(143.04,51.92,350)]
  @test pga_as2008(eq_7,grid_1,config_as2008)[1].g == 22.45
  # run PGA modeling on grid without minpga M6.0
  A = pga_as2008(eq_6,grid,config_as2008)
  @test length(A) == TEST_GRID_SIZE
  @test round(sum([A[i].g for i=1:length(A)]),2) == 4.39
  # run PGA modeling on grid with minpga M6.0
  A = pga_as2008(eq_6,grid,config_as2008,0.22)
  @test length(A) == WITH_MINPGA
  @test round(sum([A[i].g for i=1:length(A)]),2) == 2.86
  # run PGA modeling with M4.0
  A = pga_as2008(eq_4,grid,config_as2008)
  @test length(A) == TEST_GRID_SIZE
  @test round(sum([A[i].g for i=1:length(A)]),2) == 0.21
  # run PGA modeling for plotting M6.0
  A = pga_as2008(eq_6,config_as2008)
  @test length(A) == SIMULATION_ARRAY_SIZE
  @test round(sum(A),2) == 573.5
  # run PGA Modeling M=7
  pga_as2008(eq_7,config_as2008)[1] == 22.4
end 

@testset "Si-Midorikawa 1999 GMPE" begin
  # init model parameters
  include("../examples/si-midorikawa-1999.conf")
  ## test at epicenter on grid M7.0
  grid_1 = [Point_vs30(143.04,51.92,350)]
  @test pga_simidorikawa1999(eq_7,grid_1,config_simidorikawa1999_crustal)[1].g == 59.04
  ## run PGA modeling on grid withoit minpga Depth <= 30 M6.0
  S_c = pga_simidorikawa1999(eq_6,grid,config_simidorikawa1999_crustal)
  @test length(S_c) == TEST_GRID_SIZE
  @test round(sum([S_c[i].g for i=1:length(S_c)]),2) == 6.98
  S_intp = pga_simidorikawa1999(eq_6,grid,config_simidorikawa1999_interplate)
  @test length(S_intp) == TEST_GRID_SIZE 
  @test round(sum([S_intp[i].g for i=1:length(S_intp)]),2) == 8.38
  S_intra = pga_simidorikawa1999(eq_6,grid,config_simidorikawa1999_intraplate)
  @test length(S_intra) == TEST_GRID_SIZE
  @test round(sum([S_intra[i].g for i=1:length(S_intra)]),2) == 13.9
  ## run PGA modeling on grid with minpga Depth <= 30 M6.0
  S_c = pga_simidorikawa1999(eq_6,grid,config_simidorikawa1999_crustal,0.34)
  @test length(S_c) == WITH_MINPGA
  @test round(sum([S_c[i].g for i=1:length(S_c)]),2) == 4.61
  ## run PGA modeling on grid with minpga Depth > 30 M6.0
  eq_30 = Earthquake(143.04,51.92,35,6.0)
  S_c = pga_simidorikawa1999(eq_30,grid,config_simidorikawa1999_crustal,0.15)
  @test length(S_c) == WITH_MINPGA
  @test round(sum([S_c[i].g for i=1:length(S_c)]),2) == 2.04
  ## run PGA modeling for plotting Depth <= 30 M6.0
  S_c = pga_simidorikawa1999(eq_6,config_simidorikawa1999_crustal)
  @test length(S_c) == SIMULATION_ARRAY_SIZE
  @test round(sum(S_c),2) == 1096.79
  S_intp = pga_simidorikawa1999(eq_6,config_simidorikawa1999_interplate)
  @test round(sum(S_intp),2) == 1318.74
  S_intra = pga_simidorikawa1999(eq_6,config_simidorikawa1999_intraplate)
  @test round(sum(S_intra),2) == 2188.89
  ## run PGA modeling for plotting Depth > 30 M6.0
  S_c = pga_simidorikawa1999(eq_30,config_simidorikawa1999_crustal)
  @test round(sum(S_c),2) == 722.93
end
