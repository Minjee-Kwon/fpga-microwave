# 프로젝트 빌드

## Vivado 2020.2

1. 저장소를 내려받습니다.
2. Vivado Tcl Console에서 저장소 폴더로 이동해 `source create_project.tcl`을 실행합니다. 새 프로젝트는 `vivado_project/`에 생성됩니다.
3. 직접 프로젝트를 만든다면 `src/*.v` 9개와 `constraints/basys3_microwave.xdc` 하나를 추가합니다.
4. 최상위를 `microwave_top`으로 지정합니다.
5. Synthesis → Implementation → Generate Bitstream 순서로 진행합니다.
6. Hardware Manager에서 보드에 프로그램하고 SW15를 0으로 유지합니다.

기존 로터리 프로젝트 XDC나 이전 통합 소스를 함께 등록하지 마세요. 코드의 `btn[6:0]`, `pwm_out`, `in1_in2[1:0]`와 XDC의 포트 이름이 일치해야 합니다.


시뮬레이션은 [검증 문서](VERIFICATION.md)를 참고합니다.
