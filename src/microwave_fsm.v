`timescale 1ns/1ps
module microwave_fsm(input wire clk,reset,input wire [6:0] btn_pulse,
 input wire inc,dec,running,done,
 output reg [1:0] mode,output wire [15:0] led,
 output reg door_open,door_event,
 output wire start,pause,motor_enable,
 output reg finish,output wire blank,button_event,cancel_event);
 reg [25:0] blink_count;reg [2:0] blink_phase;
 assign led={13'b0,(mode==2),(mode==1),(mode==0)};
 assign start=btn_pulse[0] && !door_open && !btn_pulse[5] && !btn_pulse[3];
 // Open button pauses cooking once; a held-open door does not block time setting.
 assign pause=btn_pulse[3] || btn_pulse[5] || (running && door_open);
 assign motor_enable=running && !door_open && !btn_pulse[3] && !btn_pulse[5];
 assign blank=finish && blink_phase[0];
 assign button_event=|btn_pulse;
 assign cancel_event=btn_pulse[3]||btn_pulse[5]||btn_pulse[6]||(!running&&(inc||dec));
 always @(posedge clk or posedge reset) begin
  if(reset) begin mode<=0;door_open<=0;door_event<=0;finish<=0;blink_count<=0;blink_phase<=0;end
  else begin
   door_event<=0;
   if(btn_pulse[1] && !btn_pulse[2]) mode<=(mode==2)?0:mode+1'b1;
   else if(btn_pulse[2] && !btn_pulse[1]) mode<=(mode==0)?2:mode-1'b1;
   if(btn_pulse[6]) begin
    if(door_open) door_event<=1;
    door_open<=0;
   end else if(btn_pulse[5]) begin
    if(!door_open) door_event<=1;
    door_open<=1;
   end
   if(btn_pulse[3]||btn_pulse[5]||btn_pulse[6]||start||(!running&&(inc||dec))) begin
    finish<=0;blink_count<=0;blink_phase<=0;
   end else if(done) begin finish<=1;blink_count<=0;blink_phase<=0;end
   else if(finish) begin
    if(blink_count==49999999) begin
     blink_count<=0;
     if(blink_phase==5) begin finish<=0;blink_phase<=0;end
     else blink_phase<=blink_phase+1'b1;
    end else blink_count<=blink_count+1'b1;
   end
  end
 end
endmodule
