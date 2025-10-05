.ifndef _SLEEP_ASM_
.define _SLEEP_ASM_

.cseg

; sleep ms
; func_arg_1 - sleep in ms (0 equals 256 ms)
; func_arg_2 - multiply sleep (0 equals x256)
; uses r2-r5 registers
; this subroutine is interrupt friendly and does not modify registers
sleep_ms:
  push r5
  push r4
  push r3
  push r2
  mov r5, func_arg_1
  ldi acc, sys_freq
  mov r2, acc
  sleep_ms_0:
    mov r3, func_arg_2
  sleep_ms_1:
    mov r4,r5
  sleep_ms_2:
    ldi acc, 249
    nop
  sleep_ms_3:
    nop
    dec acc
  brne sleep_ms_3
    dec r4
  brne sleep_ms_2
    dec r3
  brne sleep_ms_1
    dec r2
  brne sleep_ms_0
    pop r2
    pop r3
    pop r4
    pop r5
ret

; sleep us
; func_arg_1 - sleep in us  (0 equals 2560 us)
; uses r2-r3 registers
; this subroutine is interrupt friendly and does not modify registers
sleep_us:
  push r3
  push r2
  mov r3, func_arg_1
  ldi acc, sys_freq
  mov r2, acc
  sleep_us_0:
    mov acc,r3
  sleep_us_1:
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    dec acc
  brne sleep_us_1
    dec r2
  brne sleep_us_0
    pop r2
    pop r3
ret


.endif
