# Run from repo root in Vivado Tcl Console.
set root [file normalize [file join [file dirname [info script]] ..]]
if {[llength [get_projects -quiet]] == 0} {
 create_project microwave_sim [file join $root vivado_sim] -part xc7a35tcpg236-1 -force
}
set srcs [glob [file join $root src *.v]]
foreach f $srcs {if {[llength [get_files -quiet $f]]==0} {add_files -norecurse $f}}
set tb [file join $root sim tb_microwave.v]
if {[llength [get_files -quiet $tb]]==0} {add_files -fileset sim_1 -norecurse $tb}
set_property top tb_microwave [get_filesets sim_1]
set_property xsim.simulate.runtime 100ms [get_filesets sim_1]
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1
launch_simulation
