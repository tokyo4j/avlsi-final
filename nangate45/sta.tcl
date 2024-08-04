#
# Your design
#
set base_name "mips32"
set vnet_file "mips32.final.vnet"
set sdc_file  "mips32.sdc"
set sdf_file  "mips32.sdf"
set spef_file "mips32.spef"

#
# Libraries
#
set target_library "/home/cad/lib/NANGATE45/typical.db"
set synthetic_library "dw_foundation.sldb"
set link_library [concat "*" $target_library $synthetic_library]
set symbol_library "generic.sldb"
define_design_lib WORK -path ./WORK

#
# Read post-layout netlist
#
read_file -format verilog $vnet_file
current_design $base_name
link

#
# Delay and RC information
#
read_sdc $sdc_file
read_sdf $sdf_file
read_parasitics $spef_file

# report_timing
# report_reference -hier
# quit
