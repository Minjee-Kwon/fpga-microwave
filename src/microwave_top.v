`timescale 1ns/1ps
module microwave_top(
 input wire clk,reset,
 input wire [6:0] btn,
 input wire s1,s2,
 output wire [15:0] led,
 output wire [3:0] an,
 output wire [7:0] seg,
 output wire buzzer,servo,
 output wire pwm_out,
 output wire [1:0] in1_in2
);
 wire [6:0] clean_pulse;
 wire inc,dec;
 wire [12:0] remaining;
 wire running,done,door_open,door_event,finish,blank;
 wire start,pause,motor_enable,button_event,cancel_event;
 wire [1:0] mode;
 btn_debounce u_btn(.clk(clk),.reset(reset),.noisy_btn(btn),.btn_pulse(clean_pulse));
 rotary u_rotary(.clk(clk),.reset(reset),.s1(s1),.s2(s2),.inc(inc),.dec(dec));
 // Direct rotary -> timer. Only the RUNNING state inhibits adjustment.
 timer u_timer(.clk(clk),.reset(reset),.inc(inc),.dec(dec),.start(start),.pause(pause),
  .remaining(remaining),.running(running),.done(done));
 microwave_fsm u_fsm(.clk(clk),.reset(reset),.btn_pulse(clean_pulse),.inc(inc),.dec(dec),
  .running(running),.done(done),.mode(mode),.led(led),.door_open(door_open),
  .door_event(door_event),.start(start),.pause(pause),.motor_enable(motor_enable),.finish(finish),.blank(blank),
  .button_event(button_event),.cancel_event(cancel_event));
 fnd_controller u_fnd(.clk(clk),.reset(reset),.seconds(remaining),.running(running),
  .finish(finish),.blank(blank),.an(an),.seg(seg));
 buzzer_controller u_buzzer(.clk(clk),.reset(reset),.button_event(button_event),
  .door_event(door_event),.door_open(door_open),.done(done),
  .cancel(cancel_event),.buzzer(buzzer));
 servo_controller u_servo(.clk(clk),.reset(reset),.open(door_open),.servo(servo));
 motor_controller u_motor(.clk(clk),.reset(reset),.enable(motor_enable),.mode(mode),
  .motor_pwm(pwm_out),.in1(in1_in2[0]),.in2(in1_in2[1]));
endmodule
