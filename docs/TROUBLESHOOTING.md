# 개발 과정과 트러블슈팅

각 항목은 **문제 → 근거 → 수정 → 확인 결과** 순서로 정리했습니다. 로그는 실제 개발 중 생성한 자료와 제공받은 오류 메시지에서 가져왔습니다. 코드 발췌는 구현 근거이며 실물 전압이나 동작 시뮬레이션 PASS를 대신하지 않습니다.

## 1. IO placement 실패: RTL 포트와 XDC의 이름 불일치

### 문제가 발생한 상황

버튼을 7비트 `btn[6:0]`로 통합하고 모터 출력을 `pwm_out`, `in1_in2[1:0]`로 바꾼 뒤 기존 XDC를 함께 사용했습니다. 구현 단계에서 아래 오류가 발생했습니다.

```text
[Place 30-374] IO placer failed to find a solution
```

[실제 오류 메시지](evidence/io_placer_error.txt)의 부분 배치표에는 LED·FND·서보·로터리는 나타나지만 버튼과 모터 신호의 배치는 보이지 않습니다. 이 표 하나만으로 원인을 단정하지 않고 제공된 XDC와 최상위 RTL을 대조했습니다.

### 확인한 근거

기존 XDC는 `[get_ports btnC]`, `[get_ports {motor_pwm}]`를 사용했습니다. 반면 최상위 모듈에는 `btnC`와 `motor_pwm`이라는 외부 포트가 없고, `btn[0]`과 `pwm_out`이 있습니다. 이름이 다른 포트에는 의도한 핀 제약이 적용되지 않습니다.

[실제 XDC 수정 전후](evidence/xdc_before_after.txt)

```tcl
# 수정 전: 제공받은 제약 파일
set_property -dict { PACKAGE_PIN U18 IOSTANDARD LVCMOS33 } [get_ports btnC]
set_property -dict { PACKAGE_PIN J1 IOSTANDARD LVCMOS33 } [get_ports {motor_pwm}]

# 수정 후: 현재 최상위 포트에 맞춤
set_property -dict { PACKAGE_PIN U18 IOSTANDARD LVCMOS33 } [get_ports {btn[0]}]
set_property -dict { PACKAGE_PIN J1 IOSTANDARD LVCMOS33 } [get_ports {pwm_out}]
```

### 수정한 내용

C/U/D/L/R을 `btn[0]`~`btn[4]`로 맞추고 외부 열기·닫기 버튼은 J3/L3의 `btn[5]`/`btn[6]`로 등록했습니다. 모터는 JA1/J1의 EN과 JA2/L2·JA3/J2 방향 신호로 통일했습니다. 새 XDC와 이전 XDC가 함께 등록되지 않도록 프로젝트의 제약 파일도 정리했습니다.

### 확인 결과와 범위

현재 XDC의 활성 PACKAGE_PIN은 44개이며 중복 핀은 0개입니다. [정적 핀 점검 결과](evidence/pin_audit.txt)와 수정 코드를 근거로 남겼습니다.

개발 중 2026-10-28 14:50의 배치배선 리포트에는 `Fully Routed`, `Violations found: 0`이 기록돼 있습니다. 같은 시점의 타이밍 리포트는 WNS 3.484ns, TNS 0.000ns이며 `All user specified timing constraints are met.`를 표시합니다. 이는 **해당 개발 버전의 구현 이력**이며 현재 최종 RTL 전체를 다시 검증한 결과로 표시하지 않습니다. 출력 지연을 지정하지 않은 포트도 있으므로 모든 외부 장치 인터페이스 타이밍을 보장한다는 뜻은 아닙니다.

- [개발 중 DRC 원문](evidence/development_drc.txt)
- [개발 중 타이밍 리포트](evidence/development_timing.txt)

## 2. 서보 미동작: 제어 신호와 장치 상태를 나눠 점검

### 문제가 발생한 상황

버튼을 누를 때 부저는 울렸지만 서보가 동작하지 않았습니다. 버튼·알림 경로가 반응한다는 점과 서보가 움직인다는 점은 별개의 확인 항목이었습니다.

### 점검과 수정

먼저 서보 신호를 JB10/C16의 `servo` 출력으로 통일했습니다. 서보 구동은 DC 모터의 EN과 구분해 50Hz 펄스를 유지했습니다. 문 닫힘은 1ms, 열림은 1.5ms로 정하고, 명령은 20ms 프레임 경계에서 반영했습니다.

```verilog
else if(count==1999999) begin
 count<=0;
 frame_open<=open;
end
assign servo=(count<(frame_open?150000:100000));
```

이 코드가 전압·전원·서보 내부 상태까지 증명하는 것은 아닙니다. 장치를 교체해 제어 로직과 장치 문제를 분리해서 확인했습니다.

### 확인 결과와 증거

서보 교체 후 사용자가 동작한다고 확인했습니다. 실제 영상의 초반에는 외부 버튼 조작과 서보 암 위치 변화가 담겨 있습니다.

- [실제 동작 영상](media/microwave_demo_landscape.mp4): 초반 문 개폐 버튼과 서보 암 구간
- [실제 배선 사진](images/hardware_setup.jpg)
- [서보 RTL](../src/servo_controller.v), [핀 제약](../constraints/basys3_microwave.xdc)

**확정한 내용은 교체 후 동작했다는 관찰 결과입니다.** 기존 서보의 고장 원인을 전원 부족·전류 부족·기구 걸림 등 하나로 확정할 측정 자료는 없습니다.

## 3. 모터 출력이 약하다는 증상과 EN 100% 요구

### 문제가 발생한 상황

초기 제공 코드는 PWM 듀티 조절 용도였고, 최종 요구는 듀티 조절 없이 모터를 구동하는 것이었습니다. 실물에서 출력이 약하다는 피드백도 있어 제어 로직의 듀티와 실제 모터 전원 문제를 구분할 필요가 있었습니다.

### 수정한 내용

최종 모터 제어에서 PWM 카운터와 듀티 설정 경로를 제거했습니다. `pwm_out`이라는 외부 포트명은 배선을 유지하기 위해 남겼지만 실제 동작은 운전 허용 시 HIGH인 EN입니다. IN1/IN2는 방향만 선택합니다.

```verilog
wire active=enable && ready && (current_dir==desired);
assign motor_pwm=active;
assign in1=active && !current_dir;
assign in2=active && current_dir;
```

방향 변경 시에는 EN을 낮추고 5ms 대기한 뒤 반대 방향을 허용합니다. 이 구간과 정지 상태를 제외하면 EN은 계속 HIGH입니다.

### 확인 결과와 남은 범위

[실제 모터 RTL](../src/motor_controller.v)에서 EN이 별도 PWM 발진기 없이 active에 직접 연결된 것을 확인할 수 있습니다. [동작 영상](media/microwave_demo_landscape.mp4)에는 팬이 도는 모습이 있습니다. 다만 약한 출력의 물리적 원인을 확정할 전압·전류·드라이버 측정 자료는 없으므로 '코드 수정으로 출력 전압 문제가 해결됐다'고 단정하지 않습니다.

## 4. 취소·종료 후에도 시간 수정과 재시작이 가능한 구조

### 해결하려던 문제

운전 중에는 로터리로 시간을 바꾸면 안 되지만, 취소 후와 타임아웃 후에는 다시 조절해야 했습니다. 문을 계속 열어둔 동안에도 시간 설정은 허용하고 시작만 차단해야 했습니다.

### 수정한 내용과 코드 근거

시간은 timer 모듈이 저장하고, running 분기에서는 차감만 수행하도록 했습니다. pause가 오면 running과 초 분주기만 초기화해 남은 시간은 보존합니다. 정지 상태에서는 inc/dec를 다시 반영합니다.

```verilog
if(pause) begin running<=0;count<=0;end
else if(running) begin
 // 카운트다운 처리
end else begin
 // inc/dec와 start 처리
end
```

문 열기 버튼을 누른 순간에는 pause를 만들고, 이후 문이 열린 정지 상태에서는 로터리 설정을 허용합니다. start는 `!door_open` 조건으로 차단합니다. 닫기 동작은 start를 만들지 않아 자동 재시작을 막습니다.

### 확인 결과와 증거

- [타이머 구현](../src/timer.v)과 [FSM 출력 조건](../src/microwave_fsm.v)에서 분기와 우선순위 확인
- [기본 동작 테스트벤치](../sim/tb_microwave.v)에서 취소·문 열림·종료 후 재시작 순서를 자극으로 제공
- 실제 동작 파형은 사용자 실행 결과 대기. 코드 근거와 시뮬레이션 결과를 구분

## 5. FND 통합 과정의 클록·조합회로 정리

### 발견한 구조

제공된 FND 자리 선택 코드는 `always @(posedge reset, posedge tick)`로 별도 tick을 클록처럼 사용했습니다. 조합 출력 중에는 `always @(sel)`처럼 다른 입력의 변화를 감도 목록에 포함하지 않은 부분도 있었습니다.

### 수정과 이유

자리 선택을 시스템 `clk`의 상승 에지에서 처리하고 `if(tick)`일 때만 갱신하도록 바꿨습니다. 조합 출력은 `always @*`로 바꿔 선택 자리 외의 숫자·애니메이션 입력 변경도 반영하도록 했습니다.

```verilog
always @(posedge clk or posedge reset) begin
 if(reset) sel<=0;
 else if(tick) sel<=sel+1;
end
```

이 항목은 관찰된 오동작의 확정 원인 보고가 아니라 **기존 코드를 통합하며 수행한 구조 개선**입니다. [실제 수정 전후 코드](evidence/fnd_before_after.txt)와 [현재 FND 소스](../src/fnd_controller.v)를 증거로 남겼습니다.

## 6. XSIM 실행 실패: RTL 구문 분석과 도구 실행 단계를 구분

새 테스트벤치에 대해 xvlog 구문 분석과 xelab 정적 elaboration은 완료됐지만 생성된 `xsim_1.c` 컴파일에서 아래 오류가 발생했습니다.

```text
ERROR: [XSIM 43-3409] Failed to compile generated C file .../xsim_1.c.
ERROR: [XSIM 43-3915] Encountered a fatal error. Cannot continue. Exiting...
```

[기본 동작 테스트벤치의 실제 도구 로그](evidence/simulation_tool_log.txt)에서 분석 완료와 오류 단계를 확인할 수 있습니다.

이 오류를 RTL 동작 실패나 동작 PASS로 해석하지 않고 실행 환경 단계의 실패로 구분했습니다. 사용자 PC에서 기본 동작 테스트벤치를 실행한 로그와 파형을 받아 [검증 결과 페이지](VERIFICATION.md)에 반영할 예정입니다. **이 항목은 아직 동작 시뮬레이션 결과를 확보하지 못한 미완료 검증입니다.**

## 증거 자료 안내

`docs/evidence/`에는 실제 오류와 코드 비교, 개발 중 리포트를 텍스트로 보관합니다. 리포트의 호스트명·로컬 경로는 제외했고 분석 수치와 오류 문구는 유지했습니다. `SHA256.json`은 저장된 증거 파일의 식별용 해시이며 로그의 독립적 인증이나 외부 검증을 뜻하지 않습니다. 시연 사진·영상은 사용자가 제공한 실제 자료입니다.
