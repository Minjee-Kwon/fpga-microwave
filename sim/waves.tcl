# Source after launch_simulation, before running the test again.
restart
set w [current_wave_config]
if {$w eq ""} {create_wave_config}
add_wave /tb_microwave/clk /tb_microwave/reset /tb_microwave/btn
add_wave /tb_microwave/s1 /tb_microwave/s2
add_wave /tb_microwave/dut/inc /tb_microwave/dut/dec
add_wave /tb_microwave/dut/remaining /tb_microwave/dut/running
add_wave /tb_microwave/dut/start /tb_microwave/dut/pause /tb_microwave/dut/done
add_wave /tb_microwave/dut/door_open /tb_microwave/dut/mode
add_wave /tb_microwave/dut/finish /tb_microwave/dut/blank
add_wave /tb_microwave/led /tb_microwave/pwm_out /tb_microwave/in1_in2
add_wave /tb_microwave/servo /tb_microwave/buzzer
add_wave /tb_microwave/an /tb_microwave/seg
log_wave -r /tb_microwave/dut/*
run all
