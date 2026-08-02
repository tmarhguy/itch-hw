# Batch build (repo root):
#   vivado -mode batch -source vivado/build.tcl

set script_dir [file dirname [file normalize [info script]]]
set repo_root  [file normalize [file join $script_dir ..]]
set xpr_path   [file join $repo_root itch-hw.xpr]

source [file join $script_dir add_sources.tcl]

open_project $xpr_path

# Default bitstream: live Ethernet ingress (RMII + lab UDP → ITCH core).
set_property generic {USE_ETH=1} [get_filesets sources_1]

reset_run synth_1
launch_runs synth_1 -jobs 8
wait_on_run synth_1

reset_run impl_1
launch_runs impl_1 -to_step write_bitstream -jobs 8
wait_on_run impl_1

set rpt_dir [file join $repo_root itch-hw.runs impl_1]
set timing [glob -nocomplain [file join $rpt_dir *timing_summary_routed.rpt]]
set util   [glob -nocomplain [file join $rpt_dir *utilization_placed.rpt]]

puts "Build complete. Reports:"
puts "  $timing"
puts "  $util"

close_project
