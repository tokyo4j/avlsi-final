set base_name "mips32"
set lib_path "/home/cad/lib/NANGATE45/"

# Step 1: Setup (File --> Import Design)
redirect Default.view {
echo "create_library_set -name default -timing {${lib_path}/typical.lib}"
echo "create_constraint_mode -name default -sdc_files {${base_name}.sdc}"
echo "create_delay_corner -name default -library_set {default}"
echo "create_analysis_view -name default -constraint_mode {default} -delay_corner {default}"
echo "set_analysis_view -setup {default} -hold {default}"
}
set init_top_cell ${base_name}
set init_verilog ${base_name}.vnet
set init_lef_file "${lib_path}/tech.lef ${lib_path}/cells.lef"
set init_pwr_net VDD
set init_gnd_net VSS
set init_mmmc_file Default.view
init_design

# Step 2: Global nets (Power --> Connect Global Nets)
setDesignMode -process 45
globalNetConnect VDD -type pgpin -pin VDD -inst *
globalNetConnect VSS -type pgpin -pin VSS -inst *
globalNetConnect VDD -type tiehi
globalNetConnect VSS -type tielo

# Step 3: Floorplan (Floorplan --> Specify Floorplan)
floorPlan -s 150 150 25 25 25 25
saveDesign floor.enc

# Step 4: End-cap cell (Place --> Physical Cell --> Add End Cap)
# Step 5: Well-tap cell (Place --> Physical Cell --> Add Well Tap)
# Step 6: Verify End-cap (Verify --> Verify End Cap)

# Step 7: Power ring (Power --> Power Planning --> Add Ring)
addRing -nets {VDD VSS} -type core_rings -center 1 -width 10 -spacing 2 -layer {top metal9 bottom metal9 left metal10 right metal10}

# Step 8: Power stripe (Power --> Power Planning --> Add Striple)
addStripe -nets {VDD VSS} -layer metal8 -width 4 -spacing 2 -set_to_set_distance 30 -start_offset 15

# Step 9: Power route (Route --> Special Route)
sroute -nets {VDD VSS}
saveDesign power.enc

# Step 10: Placement (Place --> Standard Cell)
setPlaceMode -place_global_place_io_pins true
placeDesign

# Step 11: Optimization (preCTS) (ECO --> Optimize Design)
optDesign -preCTS

# Step 12: Clock tree synthesis (CTS) (command line only)
#          Clock tree check (Clock --> CCOpt Clock Tree Debugger)
set_ccopt_property buffer_cells {CLKBUF_X1 CLKBUF_X2 CLKBUF_X3}
ccopt_design
saveDesign cts.enc

# Step 13: Optimization (postCTS) (ECO --> Optimize Design)
optDesign -postCTS -hold -setup

# Step 14: Detailed route (Route --> Nano Route --> Route)
#setNanoRouteMode -drouteEndIteration 3
routeDesign

# Step 15: Optimization (postRoute) (ECO --> Optimize Design)
setDelayCalMode -engine aae -SIAware false
optDesign -postRoute -hold -setup
saveDesign route.enc

# Step 16: Add fillers (Place --> Physical Cells --> Add Filler)
addFiller -prefix FILLER -cell FILLCELL_X1 FILLCELL_X2 FILLCELL_X4 \
  FILLCELL_X8 FILLCELL_X16 FILLCELL_X32
ecoRoute
checkFiller

# Step 17: Verification (LVS) (Verify --> Verify Connectivity)
verifyConnectivity -noOpen

# Step 18: Verification (DRC) (Verify --> Verify Geometry)
verify_drc

# Step 19: Data out (Timing --> Extract RC, Timing --> Write SDF,
saveNetlist ${base_name}.final.vnet
extractRC
rcOut -spef ${base_name}.spef
write_sdf -recompute_parallel_arcs ${base_name}.sdf
saveDesign final.enc
