# 코드와 신호 흐름

## 1. 최상위 연결: microwave_top

`microwave_top`은 직접 긴 제어 로직을 구현하기보다 8개 기능 블록을 연결합니다.

- `btn[6:0] → btn_debounce → clean_pulse[6:0] → microwave_fsm`
- `s1/s2 → rotary → inc/dec → timer`
- `timer.remaining → fnd_controller.seconds`
- `timer.running/done → microwave_fsm`
- `timer.done → buzzer_controller.done`
- `microwave_fsm.motor_enable/mode → motor_controller`
- `microwave_fsm.door_open → servo_controller.open`

`inc/dec`는 종료 표시를 중단하는 조건에도 쓰이므로 FSM에도 전달되지만, 시간값 자체는 `timer`가 저장·변경합니다.

## 2. 버튼: btn_debounce

제공한 `btn_debouncer`는 7개의 입력을 각각 동기화하고 약 10ms 안정 상태를 확인합니다. 출력 `clean_btn`은 버튼을 누르는 동안 유지되는 레벨입니다.

외부 `btn_debounce` 모듈은 이전 상태를 저장하고 `clean_btn & ~prev_btn`으로 한 클록짜리 누름 펄스를 만듭니다. 따라서 버튼을 길게 눌러도 시작이나 모드 전환이 매 클록 반복되지 않습니다.

## 3. 로터리: rotary

시계 방향 전이는 `00 → 10 → 11 → 01 → 00`, 반시계는 그 반대입니다. 2단 동기화 후 현재·이전 상태를 비교해 유효 전이를 누적합니다.

- 정방향 4개 누적 → `inc` 한 클록
- 역방향 4개 누적 → `dec` 한 클록
- 중간의 반대 방향 전이 → 누적량 상쇄
- 잘못된 두 비트 동시 전이 → 누적량 초기화

`s1/s2`에는 일반 버튼 디바운서를 넣지 않았고 `key`도 사용하지 않습니다. 한 detent에 실제 몇 개 전이가 발생하는지는 연결한 엔코더의 사양에 따릅니다.

## 4. 타이머: timer

`remaining`은 총 남은 초를 저장하는 13비트 레지스터입니다. 정지 상태에서는 0~5999 범위에서 증감하며, 운전 중에는 증감 입력을 사용하지 않습니다.

100MHz에서 카운터 0~99,999,999가 1초를 만듭니다. 마지막 1초가 끝나면 `remaining=0`, `running=0`으로 바꾸고 `done`을 한 클록 출력합니다. 취소 시 시간값은 보존하고 초 분주 카운터를 초기화합니다. 재시작하면 새 1초 구간부터 셉니다.

## 5. 제어: microwave_fsm

- `start`: C 입력이며 문이 닫혀 있고 취소/열기 입력이 겹치지 않을 때 타이머에 전달
- `pause`: L 취소, 문 열기, 운전 중 열린 문 상태
- `motor_enable`: 운전 중이면서 문이 닫혀 있고 취소/열기 요청이 없는 경우
- `mode`: U/D에 따라 0·1·2 순환
- `door_open`: btn5로 1, btn6으로 0. 두 입력이 동시에 들어오면 닫기를 우선
- `door_event`: 문 상태가 실제로 바뀔 때 한 클록 출력
- `finish/blank`: 완료 후 0.5초 단위 6개 구간으로 ON/OFF 3회 표시

코드에 `READY` 같은 단일 상태 enum은 없습니다. README의 FSM은 `running`, `door_open`, `finish`를 기준으로 동작을 묶은 개념도입니다.

## 6. FND: fnd_controller

총 초를 분/초로 나누고 기존 FND 입력인 `{dot, minutes[6:0], seconds[5:0]}`로 묶습니다. 내부 `fnd_core`, `fnd_digit_select`, `bin2bcd_4digit`, `fnd_digit_display`는 제공한 코드의 구성을 활용합니다.

운전 중에는 숫자와 원형 애니메이션을 1초씩 교대로 표시합니다. 종료 시에는 숫자를 0으로 만들고 `blank` 구간에 모든 자리와 세그먼트를 끕니다. 1ms마다 자리를 전환하므로 각 자리는 약 250Hz로 갱신됩니다.

## 7. 부저: buzzer_controller

제공한 `play_melody`의 7개 음계 카운터를 사용하며 시퀀서가 한 번에 하나의 음을 선택합니다.

- 일반 버튼: 짧은 BEEP
- 열림: 낮은 음 → 높은 음
- 닫힘: 높은 음 → 낮은 음
- 종료: 도·미·솔 패턴을 두 번 재생

취소/재설정 이벤트는 종료 멜로디보다 우선하며, 문 상태 전환은 별도의 알림음으로 처리합니다.

## 8. DC 모터: motor_controller

`active = enable && ready && (current_dir == desired)`이며 다음과 같이 출력합니다.

| 조건 | pwm_out(EN) | IN1 | IN2 |
|---|---|---|---|
| 정지/반전 대기 | 0 | 0 | 0 |
| 정회전 | 1 | 1 | 0 |
| 역회전 | 1 | 0 | 1 |

`pwm_out`은 이 버전에서 주기적인 PWM 파형이 아닌 EN입니다. 모드2는 100MHz × 3초 카운터로 방향을 뒤집고, 방향 전환 시 5ms 동안 출력을 끕니다. 핀의 HIGH는 모터 전원 자체가 아니라 드라이버 제어 신호입니다.

## 9. 서보: servo_controller

100MHz 기준 카운터 0~1,999,999가 20ms 프레임을 만듭니다. 프레임 경계에서 `open`을 저장해 펄스 중간에 목표값이 바뀌어 폭이 잘리는 것을 피합니다.

- 닫힘: 100,000클록 = 1ms
- 열림: 150,000클록 = 1.5ms
- 출력 주기: 2,000,000클록 = 20ms = 50Hz

이는 위치 목표 신호이며 모터의 실제 도착 여부를 읽는 센서는 없습니다.
