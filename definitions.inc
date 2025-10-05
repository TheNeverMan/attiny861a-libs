.ifndef _DEFINITIONS_INC_
.define _DEFINITIONS_INC_

; this file contains all custom register names and bit definitions used in the
; program
; keeping it in one file makes it easier to search and reduces risk of
; redifining register names
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






; phone control registers
.def PHONECRA = r7 ; general phone control register

; keyboard control registers
; phone control register which contains keyboard configuration options
.def PHONECRB = r8
  .equ KIMODE = 7 ; keyboard input mode, high if in text mode, low if in numeric
  .equ KEVENP = 6 ; was last keypress even or odd, used in input mode, odd is low, even is high
  .equ NICOLN = 5 ; numeric input column number, used in numeric input to determine which column in vector table was selected
  .equ NKEYPRESS = 4 ; high if new key was pressed during last keyboard poll (should be set to low by software after reading PRKEYCDR)
  ; actually last pressed key code can fit there i am dumb
  .equ PRKEYCDE_3 = 3
  .equ PRKEYCDE_2 = 2
  .equ PRKEYCDE_1 = 1
  .equ PRKEYCDE_0 = 0 ; this nybble contains last pressed key code (0-11)
  .equ PRKEYCDE_MASK = 0b00001111
.def KEYVRA = r9
  .equ KEY_0 = 7
  .equ KEY_1 = 6
  .equ KEY_2 = 5
  .equ KEY_3 = 4
  .equ STATE_0 = 3
  .equ STATE_1 = 2
  .equ STATE_2 = 1
  .equ STATE_3 = 0
.def KEYVRB = r10
.def KEYVRC = r11
.def SLENR = r13 ; string length register used in input and reader mode as limiter of length of displayed or inputted content
.def SINDR = r14 ; similarly to SLINR, this register tracks how much of content was already displayed or inputted

; i2c definitions
; ports
.equ i2c_port = PORTB
.equ i2c_port_direction = DDRB
.equ i2c_sda = PORTB0
.equ i2c_scl = PORTB2
; protocol
.equ i2c_sla_w = 0
.equ i2c_sla_r = 1
.equ i2c_gca = 0

.endif
