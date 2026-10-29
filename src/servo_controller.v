`timescale 1ns/1ps
module servo_controller(
    input clk,
    input reset,
    input open,
    output servo
    );
    
    reg [20:0] count;
    reg frame_open;
    
    always @(posedge clk or posedge reset)
        if(reset) begin 
            count<=0;
            frame_open<=0;
        end else if(count==1999999) begin 
            count<=0;
            frame_open<=open;
        end else count<=count+1'b1;
    assign servo=(count<(frame_open?150000:100000));
endmodule
