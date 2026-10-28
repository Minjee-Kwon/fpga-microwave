`timescale 1ns/1ps
module motor_controller(
    input clk,
    input reset,
    input enable,
    input [1:0] mode,
    output motor_pwm,
    output in1,
    output in2);

    reg alternate_dir,current_dir,ready;
    reg [1:0] prev_mode;
     reg [28:0] reverse_count;
 reg [18:0] dead_count;
 wire desired=(mode==1)?1'b1:(mode==2)?alternate_dir:1'b0;
 wire active=enable && ready && (current_dir==desired);
 assign motor_pwm=active;
 assign in1=active && !current_dir;
 assign in2=active && current_dir;
 always @(posedge clk or posedge reset) begin
  if(reset) begin alternate_dir<=0;current_dir<=0;ready<=0;prev_mode<=0;reverse_count<=0;dead_count<=0;end
  else begin
   prev_mode<=mode;
   if(!enable || mode!=2 || mode!=prev_mode) begin reverse_count<=0;alternate_dir<=0;end
   else if(reverse_count==299999999) begin reverse_count<=0;alternate_dir<=~alternate_dir;end
   else reverse_count<=reverse_count+1'b1;
   if(!enable) begin ready<=0;dead_count<=0;current_dir<=desired;end
   else if(current_dir!=desired) begin current_dir<=desired;ready<=0;dead_count<=0;end
   else if(!ready) begin
    if(dead_count==499999) begin ready<=1;dead_count<=0;end
    else dead_count<=dead_count+1'b1;
   end
  end
 end
endmodule
