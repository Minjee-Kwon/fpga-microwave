`timescale 1ns/1ps
module buzzer_controller
(input wire clk,reset,button_event,door_event,door_open,done,cancel,output wire buzzer);
 reg door_direction;reg [1:0] kind;reg [31:0] elapsed;reg [6:0] notes;
 reg [31:0] duration;
 localparam integer NOTE=(100000000/4<1)?1:100000000/4;
 localparam integer BEEP_LENGTH=(100000000/15<1)?1:100000000/15;
 wire expired=((kind==1)&&(elapsed>=BEEP_LENGTH-1)) ||
              ((kind==2)&&(elapsed>=2*NOTE-1)) ||
              ((kind==3)&&(elapsed>=6*NOTE-1));
 wire [1:0] unused_led;
 always @* begin
  notes=0;duration=0;
  case(kind)
   1:begin notes=7'b1000000;duration=(100000000/15<1)?1:100000000/15;end
   2:begin notes=door_direction?((elapsed<NOTE)?7'b0000001:7'b0010000):((elapsed<NOTE)?7'b0010000:7'b0000001);duration=2*NOTE;end
   3:begin
    duration=6*NOTE;
    if(elapsed<NOTE) notes=7'b0000001;
    else if(elapsed<2*NOTE) notes=7'b0000100;
    else if(elapsed<3*NOTE) notes=7'b0010000;
    else if(elapsed<4*NOTE) notes=7'b0000001;
    else if(elapsed<5*NOTE) notes=7'b0000100;
    else notes=7'b0010000;
   end
  endcase
 end
 play_melody sound(.clk(clk),.reset(reset),.btn(notes),.led(unused_led),.buzzer(buzzer));
 always @(posedge clk or posedge reset) begin
  if(reset) begin kind<=0;elapsed<=0;door_direction<=0;end
  else if(cancel) begin kind<=1;elapsed<=0;end
  else if(done) begin kind<=3;elapsed<=0;end
  else if(door_event) begin kind<=2;elapsed<=0;door_direction<=door_open;end
  else if(button_event && kind!=3) begin kind<=1;elapsed<=0;end
  else if(kind!=0) begin
   if(expired) begin kind<=0;elapsed<=0;end
   else elapsed<=elapsed+1'b1;
  end
 end
endmodule


`timescale 1ns / 1ps

module play_melody(
    input clk,
    input reset,
    input [6:0] btn,
    output [1:0] led,
    output buzzer
    );

    // input clk : 100MHz
    // output : 원하는 주파수
    // 100MHz / 원하는 주파수 /2 : duty 비가 50%
    localparam DO = 22'd191_112; // 50% duty 261.63Hz
    localparam RE = 22'd170_265; // 레 2933.63Hz
    localparam MI = 22'd151_685; // 미 50% duty 
    localparam PA = 22'd143_172; // 파 50% duty 22'd174_614
    localparam SOL = 22'd127_662; // 솔 50% duty
    localparam RA = 22'd113_636; //라 50% duty
    localparam SI = 22'd101_238; // 시 50% duty 22'd246_941;


    reg [21:0] r_clk_cnt [6:0]; // 2차원 array
    reg [6:0] r_buzzer_frequency;
    integer i; // interger : signed 32bit, / usigned : reg [31:0]

    always @(posedge clk, posedge reset) begin
        if(reset) begin
            for (i=0;i<7;i=i+1) begin
                r_clk_cnt[i] <= 22'd0;
                r_buzzer_frequency[i] <= 1'b0;            
            end
        end else begin // 10ns 상승에지 클럭
            if(!btn[0]) begin // btnU
                r_clk_cnt[0] <= 22'd0;
                r_buzzer_frequency[0] <= 1'b0;
            end else if (r_clk_cnt[0] >= DO-1) begin
                r_clk_cnt[0] <= 22'd0;
                r_buzzer_frequency[0] <= ~r_buzzer_frequency[0];    
            end else r_clk_cnt[0] <= r_clk_cnt[0]  + 1;
            
            if(!btn[1]) begin // btnL
                r_clk_cnt[1] <= 22'd0;
                r_buzzer_frequency[1] <= 1'b0;
            end else if (r_clk_cnt[1] >= RE-1) begin
                r_clk_cnt[1] <= 22'd0;
                r_buzzer_frequency[1] <= ~r_buzzer_frequency[1];    
            end else r_clk_cnt[1] <= r_clk_cnt[1]  + 1;

            if(!btn[2]) begin // btnC
                r_clk_cnt[2] <= 22'd0;
                r_buzzer_frequency[2] <= 1'b0;
            end else if (r_clk_cnt[2] >= MI-1) begin
                r_clk_cnt[2] <= 22'd0;
                r_buzzer_frequency[2] <= ~r_buzzer_frequency[2];    
            end else r_clk_cnt[2] <= r_clk_cnt[2]  + 1;

            if(!btn[3]) begin // btnR
                r_clk_cnt[3] <= 22'd0;
                r_buzzer_frequency[3] <= 1'b0;
            end else if (r_clk_cnt[3] >= PA-1) begin
                r_clk_cnt[3] <= 22'd0;
                r_buzzer_frequency[3] <= ~r_buzzer_frequency[3];    
            end else r_clk_cnt[3] <= r_clk_cnt[3]  + 1;

            if(!btn[4]) begin // btnD
                r_clk_cnt[4] <= 22'd0;
                r_buzzer_frequency[4] <= 1'b0;
            end else if (r_clk_cnt[4] >= SOL-1) begin
                r_clk_cnt[4] <= 22'd0;
                r_buzzer_frequency[4] <= ~r_buzzer_frequency[4];    
            end else r_clk_cnt[4] <= r_clk_cnt[4]  + 1;

            if(!btn[5]) begin // btn[5]
                r_clk_cnt[5] <= 22'd0;
                r_buzzer_frequency[5] <= 1'b0;
            end else if (r_clk_cnt[5] >= RA-1) begin
                r_clk_cnt[5] <= 22'd0;
                r_buzzer_frequency[5] <= ~r_buzzer_frequency[5];    
            end else r_clk_cnt[5] <= r_clk_cnt[5]  + 1;

            if(!btn[6]) begin // btn[6]
                r_clk_cnt[6] <= 22'd0;
                r_buzzer_frequency[6] <= 1'b0;
            end else if (r_clk_cnt[6] >= SI-1) begin
                r_clk_cnt[6] <= 22'd0;
                r_buzzer_frequency[6] <= ~r_buzzer_frequency[6];    
            end else r_clk_cnt[6] <= r_clk_cnt[6]  + 1;
        end
    end

    assign led = {(|btn),1'b0};
    assign buzzer = |r_buzzer_frequency; // verilog 축약 연산자 OR 연산자 (7개 중 1개라도 1이 있다면 부저 울려주는 것)
    //assign buzzer = r_buzzer_frequency[6] | r_buzzer_frequency[5] | r_buzzer_frequency[4] | r_buzzer_frequency[3] | r_buzzer_frequency[2] | r_buzzer_frequency[1] | r_buzzer_frequency[0]; 대신에
endmodule
