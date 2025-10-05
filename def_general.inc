.ifndef _DEF_GENERAL_INC_
.define _DEF_GENERAL_INC_

; this file contains general definitions for ATtiny system
; mainly register definitions and system frequency

.equ debug = 1
; registers
; r0  -
; r1  -
; r2  - used by sleep routines
; r3  - used by sleep routines
; r4  - used by sleep routines
; r5  - used by sleep routines
; r6  -
; r7  -
; r8  -
; r9  -
; r10 -
; r11 -
; r12 -
; r13 -
; r14 -
; r15 -

; r16 - accumulator
; r17 - accumulator (counter)
; r18 - accumulator (counter)
; r19
; r20 - func_arg_1
; r21 - func_arg_2
; r22 - func_arg_3
; r23 - func_arg_4
; r24 - func_return_1
; r25 - func_return_2
; r26 - XL
; r27 - XH
; r28 - YL
; r29 - YH
; r30 - ZL
; r31 - ZH

.equ sys_freq = 8 ; system frequency in Mhz
.equ sys_freq_hz = sys_freq*1000000 ; system frequency in hz
.message "System Clock Speed"
.message sys_freq
.message "Mhz"
.message sys_freq_hz
.message "hz"
; definitions
;
; registers from r0 to r15 act as status registers for important program data
; registers from r16 to r31 act as temporary registers
.def acc = r16 ; accumulator
.def func_arg_1 = r20 ; subroutine arguments should be passed to these registers
.def func_arg_2 = r21
.def func_arg_3 = r22
.def func_arg_4 = r23
.def func_return_1 = r24
.def func_return_2 = r25

.endif
