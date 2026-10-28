set root [file normalize [file dirname [info script]]]
create_project microwave [file join $root vivado_project] -part xc7a35tcpg236-1 -force
add_files -norecurse [glob [file join $root src *.v]]
add_files -fileset constrs_1 -norecurse [file join $root constraints basys3_microwave.xdc]
set_property top microwave_top [get_filesets sources_1]
update_compile_order -fileset sources_1
puts "Open microwave_top, then run synthesis / implementation / Generate Bitstream."
