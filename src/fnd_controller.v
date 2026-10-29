`timescale 1ns/1ps
module fnd_controller(
    input clk,
    input reset,
    input [12:0] seconds,
    input running,
    inout finish,
    input blank,
    output [3:0] an,
    output [7:0] seg
    );

    localparam integer SCAN=100000; // FND 표시 자리를 바꾸는 간격을 정하는 상수
    reg [31:0] scan_count,display_count;
    reg circle;
    wire tick=(scan_count==SCAN-1);
    
    wire [6:0] minutes=seconds/60;
    wire [5:0] secs=seconds%60;
    wire [13:0] packed_time=finish?14'b0:{1'b1,minutes,secs};
    wire [3:0] raw_an;
    wire [7:0] raw_seg;
    
    always @(posedge clk or posedge reset) begin
        if(reset) begin 
            scan_count<=0;
            display_count<=0;
            circle<=0;
        end else begin
            if(tick) 
                scan_count<=0;
            else 
                scan_count<=scan_count+1'b1;
            if(!running) begin 
                display_count<=0;
                circle<=0;
            end else if(display_count==99999999) begin 
                display_count<=0;
                circle<=~circle;
            end else display_count<=display_count+1'b1;
        end
    end
    fnd_core display(
        .clk(clk),
        .reset(reset),
        .tick(tick),
        .anim_on(running&&circle&&!finish),
        .sw_mode(1'b0),
        .in_data(packed_time),
        .an(raw_an),
        .seg(raw_seg)
    );
    assign an=blank?4'b1111:raw_an;
    assign seg=blank?8'hFF:raw_seg;
endmodule

module fnd_core(
    input clk,
    input reset,
    input tick,
    input anim_on,
    input sw_mode,
    input [13:0] in_data,
    output [3:0] an,
    output [7:0] seg
    );

    wire [1:0] w_sel;
    wire [3:0] w_d1, w_d10, w_d100, w_d1000;
    wire w_dot;

    reg [7:0] r_anim_counter = 0;
    reg [3:0] r_anim_step = 0;

    fnd_digit_select u_fnd_digit_select(
        .clk(clk),
        .reset(reset),
        .tick(tick),
        .sel(w_sel) 
    );
    bin2bcd_4digit u_bin2bcd_4digit(
        .in_data(in_data),
        .sw_mode(sw_mode),
        .dot(w_dot),
        .d1(w_d1),
        .d10(w_d10),
        .d100(w_d100),
        .d1000(w_d1000)
    );   
    
    fnd_digit_display u_fnd_digit_display(
        .sel(w_sel),
        .anim_on(anim_on),
        .anim_step(r_anim_step),
        .d1(w_d1),
        .d10(w_d10),
        .d100(w_d100),
        .d1000(w_d1000),
        .dot(w_dot),
        .an(an),
        .seg(seg)
    );

    //animation counter
    always @(posedge clk, posedge reset) begin
        if(reset) begin 
            r_anim_counter <=0;
            r_anim_step <=0;
        end else if(anim_on) begin
            if(tick) begin
                if(r_anim_counter == 49) begin
                    r_anim_counter <= 0 ;
                    if(r_anim_step == 11)
                        r_anim_step <= 0;
                    else 
                        r_anim_step <= r_anim_step +1;
                end else r_anim_counter <= r_anim_counter + 1;
            end
        end else begin
            r_anim_counter <=0;
            r_anim_step <=0;
        end
    end
endmodule

module fnd_digit_select(
    input clk,
    input reset,
    input tick,
    output reg [1:0] sel // 00 01 10 11 : 1ms마다 바뀜
);
    always @(posedge clk or posedge reset) begin
        if(reset) begin
            sel <= 0;
        end else begin
            if(tick) begin // 1ms
                sel <= sel + 1;
            end
        end
    end
endmodule

module bin2bcd_4digit(
    input [13:0] in_data,
    input sw_mode,
    output dot,
    output [3:0] d1,
    output [3:0] d10,
    output [3:0] d100,
    output [3:0] d1000
);
    wire [6:0] left_data;
    wire [5:0] right_data;

    assign dot = in_data[13];
    assign left_data = sw_mode ? {1'b0, in_data[5:0]} : in_data[12:6];
    assign right_data = sw_mode ? in_data[12:6] : {1'b0, in_data[5:0]};

    assign d1 = right_data % 10;
    assign d10 = right_data / 10;
    assign d100 = left_data % 10;
    assign d1000 = left_data / 10;

endmodule

module fnd_digit_display(
    input [1:0] sel,
    input anim_on,
    input [3:0] anim_step,
    input [3:0] d1,
    input [3:0] d10,
    input [3:0] d100,
    input [3:0] d1000,
    input dot,
    output reg [3:0] an,
    output reg [7:0] seg
);

    reg [3:0] bcd_data;
    reg [1:0] anim_digit;
    reg [7:0] anim_seg;

    always @(*) begin
        case (sel) 
            2'b00: begin
                bcd_data = d1;
                an = 4'b1110;
            end
            2'b01: begin
                bcd_data=d10;
                an = 4'b1101;
            end
            2'b10: begin
                bcd_data=d100;
                an=4'b1011;
            end
            2'b11: begin
                bcd_data=d1000;
                an=4'b0111;
            end
            default: begin 
                bcd_data = 4'b0000;
                an = 4'b1111;
            end
        endcase
    end

     // Circle Animation 위치 결정
    always @(*) begin
        anim_digit = 0;
        anim_seg = 8'b11111111;
        case(anim_step)
            // 위쪽
            4'd0: begin
                anim_digit = 3;
                anim_seg = 8'b11111110;
            end
            4'd1: begin
                anim_digit = 2;
                anim_seg = 8'b11111110;
            end
            4'd2: begin
                anim_digit = 1;
                anim_seg = 8'b11111110;
            end
            4'd3: begin
                anim_digit = 0;
                anim_seg = 8'b11111110;
            end

            // 오른쪽
            4'd4: begin
                anim_digit = 0;
                anim_seg = 8'b11111101;
            end
            4'd5: begin
                anim_digit = 0;
                anim_seg = 8'b11111011;
            end

            // 아래쪽
            4'd6: begin
                anim_digit = 0;
                anim_seg = 8'b11110111;
            end
            4'd7: begin
                anim_digit = 1;
                anim_seg = 8'b11110111;
            end
            4'd8: begin
                anim_digit = 2;
                anim_seg = 8'b11110111;
            end
            4'd9: begin
                anim_digit = 3;
                anim_seg = 8'b11110111;
            end

            // 왼쪽
            4'd10: begin
                anim_digit = 3;
                anim_seg = 8'b11101111;
            end
            4'd11: begin
                anim_digit = 3;
                anim_seg = 8'b11011111;
            end

            default: begin
                anim_digit = 0;
                anim_seg = 8'b11111111;
            end
        endcase
    end

    always @(*) begin
        if(anim_on) begin
        // Circle Animation만 표시
        if(sel == anim_digit)
            seg = anim_seg;
        else
            seg = 8'b11111111;
    end else begin
        // 평소에는 숫자 표시
        case(bcd_data)
            4'd0: seg = 8'b11000000;   // 0
            4'd1: seg = 8'b11111001;   // 1
            4'd2: seg = 8'b10100100;   // 2
            4'd3: seg = 8'b10110000;   // 3
            4'd4: seg = 8'b10011001;   // 4
            4'd5: seg = 8'b10010010;   // 5
            4'd6: seg = 8'b10000010;   // 6
            4'd7: seg = 8'b11111000;   // 7
            4'd8: seg = 8'b10000000;   // 8
            4'd9: seg = 8'b10010000;   // 9
            default: seg = 8'b11111111;  // all off  
        endcase 

        if(sel == 2'b10 && dot) seg[7] = 1'b0;
        else  seg[7] = 1'b1;
    end
end

endmodule
