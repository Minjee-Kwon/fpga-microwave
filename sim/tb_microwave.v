`timescale 1ns/1ps
// Simple functional demonstration. Not a full regression test.
module tb_microwave;
 reg clk=0,reset=1; reg s1=0,s2=0;
 reg [6:0] sim_button=0;
 wire [15:0] led; wire [3:0] an; wire [7:0] seg;
 wire buzzer,servo,pwm_out; wire [1:0] in1_in2;
 microwave_top dut(.clk(clk),.reset(reset),.btn(7'b0),.s1(s1),.s2(s2),
  .led(led),.an(an),.seg(seg),.buzzer(buzzer),.servo(servo),
  .pwm_out(pwm_out),.in1_in2(in1_in2));
 always #5 clk=~clk; // 100 MHz
 // Use already-debounced pulses so the demonstration stays short.
 // Button debounce itself is outside this test's scope.
 initial force dut.clean_pulse=sim_button;
 task press;input integer n;begin
  @(negedge clk);sim_button=7'b1<<n;
  @(negedge clk);sim_button=0;
  repeat(3) @(negedge clk);
 end endtask
 task phase;input [1:0] v;begin
  @(negedge clk);{s1,s2}=v;repeat(10) @(negedge clk);
 end endtask
 task cw;begin phase(2'b10);phase(2'b11);phase(2'b01);phase(2'b00);end endtask
 task ccw;begin phase(2'b01);phase(2'b11);phase(2'b10);phase(2'b00);end endtask
 // Skip the wait to the next second boundary. The production RTL stays unchanged.
 task next_second;begin
  @(negedge clk);dut.u_timer.count=27'd99999999;
  repeat(3) @(negedge clk);
 end endtask
 initial begin
  repeat(5) @(negedge clk);reset=0;repeat(15) @(negedge clk);
  $display("1. Set time: CW three times, CCW once. Expected remaining=2");
  cw;cw;cw;ccw;
  $display("remaining=%0d",dut.remaining);
  $display("2. Start: expected running=1, motor forward after 5ms");
  press(0);#6000000;
  $display("running=%b EN=%b direction=%b",dut.running,pwm_out,in1_in2);
  $display("3. Rotate while running: expected time unchanged");
  cw;ccw;$display("remaining=%0d",dut.remaining);
  $display("4. Cancel and edit, then restart");
  press(3);cw;
  $display("stopped=%b remaining=%0d EN=%b",!dut.running,dut.remaining,pwm_out);
  press(0);
  $display("5. Open door: timer/motor stop, servo opens at next frame");
  press(5);#22000000;
  $display("door_open=%b running=%b EN=%b",dut.door_open,dut.running,pwm_out);
  $display("6. Close door: no auto start");
  press(6);#22000000;
  $display("door_open=%b running=%b",dut.door_open,dut.running);
  $display("7. Mode1 reverse, then mode2 alternating");
  press(1);press(0);#6000000;
  $display("mode=%0d led=%h direction=%b",dut.mode,led,in1_in2);
  press(1);#6000000;
  @(negedge clk);dut.u_motor.reverse_count=29'd299999999;
  #6000000;
  $display("mode=%0d led=%h direction=%b",dut.mode,led,in1_in2);
  $display("8. Complete timer: done pulse, stop motor, finish display and melody");
  next_second;next_second;next_second;
  $display("remaining=%0d running=%b finish=%b EN=%b",dut.remaining,dut.running,dut.finish,pwm_out);
  #2000000;
  $display("9. Set a new time and start after completion");
  cw;press(0);#6000000;
  $display("remaining=%0d running=%b EN=%b",dut.remaining,dut.running,pwm_out);
  $display("DEMO FINISHED. Inspect displayed values and waveform.");
  $finish;
 end
endmodule
