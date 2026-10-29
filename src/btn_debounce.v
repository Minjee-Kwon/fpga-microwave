`timescale 1ns/1ps
// Reuse original clean_btn held levels, then make one press pulse per button.
module btn_debounce(input wire clk,reset,input wire [6:0] noisy_btn,output wire [6:0] btn_pulse);
 wire [6:0] clean_btn;reg [6:0] prev_btn;
 btn_debouncer u_btn_debouncer(.clk(clk),.reset(reset),.noisy_btn(noisy_btn),.clean_btn(clean_btn));
 always @(posedge clk or posedge reset)
  if(reset) prev_btn<=0;else prev_btn<=clean_btn;
 assign btn_pulse=clean_btn & ~prev_btn;
endmodule


module btn_debouncer(
    input clk,
    input reset,
    input [6:0] noisy_btn,
    output [6:0] clean_btn
);

    debouncer u_btnC_debouncer(
        .clk(clk),
        .reset(reset),
        .noisy_btn(noisy_btn[0]),
        .clean_btn(clean_btn[0])
    );

    debouncer u_btnU_debouncer(
        .clk(clk),
        .reset(reset),
        .noisy_btn(noisy_btn[1]),
        .clean_btn(clean_btn[1])
    );

    debouncer u_btnD_debouncer(
        .clk(clk),
        .reset(reset),
        .noisy_btn(noisy_btn[2]),
        .clean_btn(clean_btn[2])
    );

    debouncer u_btnL_debouncer(
        .clk(clk),
        .reset(reset),
        .noisy_btn(noisy_btn[3]),
        .clean_btn(clean_btn[3])
    );

    debouncer u_btnR_debouncer(
        .clk(clk),
        .reset(reset),
        .noisy_btn(noisy_btn[4]),
        .clean_btn(clean_btn[4])
    );

    debouncer u_btn5_debouncer(
        .clk(clk),
        .reset(reset),
        .noisy_btn(noisy_btn[5]),
        .clean_btn(clean_btn[5])
    );

    debouncer u_btn6_debouncer(
        .clk(clk),
        .reset(reset),
        .noisy_btn(noisy_btn[6]),
        .clean_btn(clean_btn[6])
    );

endmodule

// 아래에 있는 코드는 버튼 디바운서 이다. 
// 이는 noisy_btn 버튼의 입력에서 발생할 수 있는 
// 노이즈(채터링)을 제거해, 안정적인 버튼 입력(clean_btn)으로 만들어준다.
// 파라미터는 보통 클럭 카운트 제한값으로 사용되어,
// 얼마나 오랫동안 입력이 안정적인지를 판단하기 위한 시간 지연 설정이다.
// 예: 100MHz 클럭이라면, 999,999는 약 10ms의 디바운싱 지연을 의미할 수 있다.
module debouncer #(parameter DEBOUNCE_LIMIT = 20'd999_999) (
    input      clk,
    input      reset,
    input      noisy_btn,  
    output reg clean_btn
);
    reg [19:0] r_count;
    reg r_btn_state=0;

    //--- start 2단 FF 동기화기: 비동기 버튼 입력(noisy_btn)을 클럭 도메인에 맞춘다.
    reg r_sync1, r_sync2;
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            r_sync1 <= 1'b0;
            r_sync2 <= 1'b0;
        end else begin
            r_sync1 <= noisy_btn;   // 메타스터빌리티가 생길 수 있는 FF
            r_sync2 <= r_sync1;     // 안정된 값 -> 아래 디바운스 로직에서 사용
        end                         // 비동기 입력은 2단 FF 동기화 후 FSM에 투입
    end
    //--------------

    always @(posedge clk or posedge reset) begin
        if (reset) begin   // active-high reset
            r_count <= 0;
            r_btn_state <= 0;
            clean_btn <= 0;
        end else if (r_sync2 == r_btn_state) begin  // 버튼 상태가 이전과 동일할 경우 (안정됨)
            r_count <= 0;
        end else begin
            if (r_count < DEBOUNCE_LIMIT)  // 버튼 상태가 바뀌었지만 아직 안정되지 않은 경우
                r_count <= r_count + 1;
            else begin  // 상태가 충분히 오랫동안 유지됨(10ms)
                r_btn_state <= r_sync2;   // 2단 FF 
                clean_btn <= r_sync2;     // 2단 FF 
                r_count <= 0;  // clear하면 다음 변경을 다시 감지할 수 있음
            end
        end
    end
endmodule

// module debouncer #(
//     parameter DEBOUNCE_LIMIT = 20'd999_999
// )(
//     input clk,
//     input reset,
//     input noisy_btn,
//     output reg clean_btn
// );

//     reg [19:0] r_count;
//     reg r_btn_state = 0;

//     reg r_sync1, r_sync2;

//     // 2단 동기화
//     always @(posedge clk or posedge reset) begin
//         if(reset) begin
//             r_sync1 <= 0;
//             r_sync2 <= 0;
//         end
//         else begin
//             r_sync1 <= noisy_btn;
//             r_sync2 <= r_sync1;
//         end
//     end

//     // 디바운싱 + 1클록 펄스
//     always @(posedge clk or posedge reset) begin
//         if(reset) begin
//             r_count <= 0;
//             r_btn_state <= 0;
//             clean_btn <= 0;
//         end
//         else begin
//             clean_btn <= 0; // 기본값: 1클록 후 자동 LOW

//             if(r_sync2 == r_btn_state) begin
//                 r_count <= 0;
//             end
//             else begin
//                 if(r_count < DEBOUNCE_LIMIT) begin
//                     r_count <= r_count + 1'b1;
//                 end
//                 else begin
//                     r_btn_state <= r_sync2;
//                     r_count <= 0;

//                     // 눌림이 확정된 순간에만 펄스 발생
//                     if(r_sync2 == 1'b1)
//                         clean_btn <= 1'b1;
//                 end
//             end
//         end
//     end

// endmodule