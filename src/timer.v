`timescale 1ns/1ps
module timer(input wire clk,reset,inc,dec,start,pause,
 output reg [12:0] remaining,output reg running,done);
 reg [26:0] count;
 always @(posedge clk or posedge reset) begin
  if(reset) begin remaining<=0;running<=0;done<=0;count<=0;end
  else begin
   done<=0;
   if(pause) begin running<=0;count<=0;end
   else if(running) begin
    if(count==99999999) begin
     count<=0;
     if(remaining<=1) begin remaining<=0;running<=0;done<=1;end
     else remaining<=remaining-1'b1;
    end else count<=count+1'b1;
   end else begin
    count<=0;
    if(inc && !dec && remaining<5999) remaining<=remaining+1'b1;
    else if(dec && !inc && remaining!=0) remaining<=remaining-1'b1;
    if(start && remaining!=0) running<=1;
   end
  end
 end
endmodule
