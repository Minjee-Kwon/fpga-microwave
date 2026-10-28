`timescale 1ns/1ps
// Based on the supplied 00->10->11->01->00 decoder.
// No debouncer on s1/s2. Only two-stage synchronization.
module rotary(input wire clk,reset,s1,s2,output reg inc,dec);
 (* ASYNC_REG="TRUE" *) reg [1:0] meta,sync;
 reg [1:0] prev;
 reg signed [3:0] steps;
 reg [2:0] settle;
 always @(posedge clk or posedge reset) begin
  if(reset) begin meta<=0;sync<=0;prev<=0;steps<=0;inc<=0;dec<=0;settle<=0;end
  else begin
   meta<={s1,s2};sync<=meta;inc<=0;dec<=0;
   if(settle!=7) begin settle<=settle+1'b1;prev<=sync;steps<=0;end
   else begin
    prev<=sync;
    case({prev,sync})
     4'b0010,4'b1011,4'b1101,4'b0100:
      if(steps==3) begin steps<=0;inc<=1;end else steps<=steps+1'b1;
     4'b0001,4'b0111,4'b1110,4'b1000:
      if(steps==-3) begin steps<=0;dec<=1;end else steps<=steps-1'b1;
     4'b0000,4'b0101,4'b1010,4'b1111: steps<=steps;
     default: steps<=0;
    endcase
   end
  end
 end
endmodule
