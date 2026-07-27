# Add RTL and constraints to the existing itch-hw Vivado project (repo root).
# Usage (from repo root):
#   vivado -mode batch -source vivado/add_sources.tcl

set script_dir [file dirname [file normalize [info script]]]
set repo_root  [file normalize [file join $script_dir ..]]
set xpr_path   [file join $repo_root itch-hw.xpr]

if {![file exists $xpr_path]} {
  error "Project not found: $xpr_path"
}

open_project $xpr_path

proc add_sv_under {root} {
  foreach path [glob -nocomplain -directory $root *] {
    if {[file isdirectory $path]} {
      add_sv_under $path
    } elseif {[string match *.sv $path]} {
      add_files -norecurse -fileset sources_1 $path
    }
  }
}

set xdc_path [file join $repo_root constraints nexys_a7_100t.xdc]
if {![file exists $xdc_path]} {
  error "Constraints not found: $xdc_path"
}

add_sv_under [file join $repo_root rtl]
add_files -fileset constrs_1 $xdc_path

set_property top nexys_a7_100t_top [get_filesets sources_1]
set_property top_lib xil_defaultlib [get_filesets sources_1]
update_compile_order -fileset sources_1

set_property -name {xsim.simulate.runtime} -value {1000us} -objects [get_filesets sim_1]

save_project
close_project

puts "Added sources and set top to nexys_a7_100t_top."
