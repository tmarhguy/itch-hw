# Alias — default build already enables Ethernet (USE_ETH=1).
#   vivado -mode batch -source vivado/build_eth.tcl

set script_dir [file dirname [file normalize [info script]]]
source [file join $script_dir build.tcl]
