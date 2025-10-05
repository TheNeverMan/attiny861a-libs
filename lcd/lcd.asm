; ATTiny861A
; program do obsługi ekranów lcd 16x2 kompatybilnych z hitachi coś tam
.ifndef _LCD_ASM_
.define _LCD_ASM_

; lcd
.cseg
; set lcd data ports to output
lcd_set_ports_output:
  in acc, lcd_port_dir
  sbr acc, (1<<lcd_d4)|(1<<lcd_d5)|(1<<lcd_d6)|(1<<lcd_d7)
  out lcd_port_dir, acc
ret

.if lcd_has_rw_line != 0
  ; set lcd data ports to input
  lcd_set_ports_input:
    in acc, lcd_port_dir
    cbr acc, (1<<lcd_d4)|(1<<lcd_d5)|(1<<lcd_d6)|(1<<lcd_d7)
    out lcd_port_dir, acc
  ret
.endif

; send 1 byte to lcd
; func_arg_1 - byte to be sent
lcd_send_byte:
  ; set lcd ports 4-7 to output
  .if lcd_has_rw_line != 0
    rcall lcd_set_ports_output
    cbi lcd_port, lcd_rw ; set to write mode (L)
  .endif
  ; send older half byte
  sbi lcd_e_port, lcd_e ; set E line to high to signify that bytes are going to be sent
  cbi lcd_port, lcd_d4
  cbi lcd_port, lcd_d5
  cbi lcd_port, lcd_d6
  cbi lcd_port, lcd_d7 ; clear lcd port
  ; to do: change this crap
  sbrc func_arg_1, 7
  sbi lcd_port, lcd_d7
  sbrc func_arg_1, 6
  sbi lcd_port, lcd_d6
  sbrc func_arg_1, 5
  sbi lcd_port, lcd_d5
  sbrc func_arg_1, 4
  sbi lcd_port, lcd_d4
  nop
  cbi lcd_e_port, lcd_e ; validate data, send data
  nop
  nop ; wait for two cycles (probably needs to be adjusted for clockrate faster than 8/8 Mhz)
  ; send younger half byte
  sbi lcd_e_port, lcd_e ; set E line to high to signify that bytes are going to be sent
  cbi lcd_port, lcd_d4
  cbi lcd_port, lcd_d5
  cbi lcd_port, lcd_d6
  cbi lcd_port, lcd_d7 ; clear lcd port
  ; to do: change this crap
  sbrc func_arg_1, 3
  sbi lcd_port, lcd_d7
  sbrc func_arg_1, 2
  sbi lcd_port, lcd_d6
  sbrc func_arg_1, 1
  sbi lcd_port, lcd_d5
  sbrc func_arg_1, 0
  sbi lcd_port, lcd_d4
  nop
  cbi lcd_e_port, lcd_e ; validate data, send data
  push func_arg_1
  ldi func_arg_1, 5
  rcall sleep_us ; sleep for 50 us (generic slowdown for most of the commands)
  pop func_arg_1
ret

; send instruction to lcd
; func_arg_1 - instruction byte to be send
lcd_send_instruction:
  cbi lcd_port, lcd_rs ; set RS line to low (instruction data )
  rcall lcd_send_byte
ret
; send data to lcd
; func_arg_1 - data byte to be send
lcd_send_data:
  sbi lcd_port, lcd_rs ; set RS line to high (data data data data data data)
  rcall lcd_send_byte
ret

.if lcd_has_rw_line != 0
; read byte from lcd
; func_return_1 - output byte
lcd_read_byte:
  ; set lcd ports 4-7 to input
  rcall lcd_set_ports_input
  ; read older half byte
  sbi lcd_port, lcd_rw ; set to read mode (H)
  ldi func_arg_1, 1
  rcall sleep_us
  sbi lcd_e_port, lcd_e ; begin E pulse
  ldi func_arg_1, 5 ; wait for at least 50 us
  rcall sleep_us
  in acc, lcd_port_input ; read input state
  bst acc, lcd_d7 ; copy bits to output location
  bld func_return_1, 7
  bst acc, lcd_d6 ; copy bits to output location
  bld func_return_1, 6
  bst acc, lcd_d5 ; copy bits to output location
  bld func_return_1, 5
  bst acc, lcd_d4 ; copy bits to output location
  bld func_return_1, 4
  cbi lcd_e_port, lcd_e ; finish pulse

  ldi func_arg_1, 10
  rcall sleep_us

  ; read younger half byte
  sbi lcd_port, lcd_rw ; set to read mode (H)
  ldi func_arg_1, 1
  rcall sleep_us
  sbi lcd_e_port, lcd_e ; begin E pulse
  ldi func_arg_1, 5 ; wait for at least 50 us
  rcall sleep_us
  in acc, lcd_port_input ; read input state
  bst acc, lcd_d7 ; copy bits to output location
  bld func_return_1, 3
  bst acc, lcd_d6 ; copy bits to output location
  bld func_return_1, 2
  bst acc, lcd_d5 ; copy bits to output location
  bld func_return_1, 1
  bst acc, lcd_d4 ; copy bits to output location
  bld func_return_1, 0
  cbi lcd_e_port, lcd_e ; finish pulse
  ldi func_arg_1, 5
  rcall sleep_us ; sleep for 50 us (generic slowdown for most of the commands)
ret

; read instruction from lcd
; func_return_1 - output
lcd_read_instruction:
  cbi lcd_port, lcd_rs
  rcall lcd_read_byte
ret

; read data from lcd
; func_return_1 - output
lcd_read_data:
  sbi lcd_port, lcd_rs
  rcall lcd_read_byte
ret


; waits until busy flag
lcd_wait_if_busy:
  rcall lcd_read_instruction ; read busy flag byte from lcd
  sbrs func_return_1, 7 ; if busy flag is set skip return
ret
  ldi func_arg_1, 5
  rcall sleep_us ; sleep for 50 us
rjmp lcd_wait_if_busy ; loop program
.endif

.if lcd_has_brightness == 1
; increases brightness by 16
lcd_increase_brightness:
  push r17
  ldi r17, 16
  in acc, lcd_brigthness_register
  add acc, r17
  brcc lcd_increase_brightness_end ; if no carry then exit
  ldi acc, 0xFF ; otherwise set maximum brighness
  lcd_increase_brightness_end:
    out lcd_brigthness_register, acc ; set new brightness
    pop r17
ret

; decrease brightness by 16
lcd_decrease_brightness:
  push r17
  ldi r17, 16
  in acc, lcd_brigthness_register
  sub acc, r17
  brcc lcd_decrease_brightness_end ; maybe this will work as intended
  ldi acc, 0x0 ; otherwise set maximum brighness
  lcd_decrease_brightness_end:
    out lcd_brigthness_register, acc ; set new brightness
    pop r17
ret
.endif

; lcd initialization subroutine
lcd_init:
  clr acc
  sts ram_lcd_cursor_pos_byte, acc ; set cursor tracker pos to 0

  ;lcd init brightness control
  .if lcd_has_brightness == 1
    ; set OC1A as output
    sbi DDRB, PORTB1
    ; turn on anode on pwm pin controlled by timer1 on OC1A
    ldi acc, 0xFF
    out OCR1C, acc ; set TOP value of timer1 to max
    ldi acc, lcd_default_brightness
    out lcd_brigthness_register, acc ; set default brighness value
    ldi acc, (1<<COM1A1)|(1<<PWM1A)
    out TCCR1A, acc ; enable Phase Correct PWM mode on OC1A pin
    ldi acc, (1<<WGM10)
    out TCCR1D, acc
    ldi acc, (1<<CS12)|(1<<CS11)|(1<<CS10)
    out TCCR1B, acc ; start timer1 clock with 1/64 prescaler counting to OCR1C value
    ; and outputting PWM signal on OC1A pin controlled by OCR1A register
    ; set special lines to output
  .endif

  sbi lcd_port_dir, lcd_rs
  sbi lcd_e_port_dir, lcd_e
  .if lcd_has_rw_line != 0
    sbi lcd_port_dir, lcd_rw
  .endif
  rcall lcd_set_ports_output ; set data lines to output
  ; set to write instruction mode
  cbi lcd_port, lcd_rs
  cbi lcd_port, lcd_rw
  cbi lcd_e_port, lcd_e
  ; wait for 45 ms (if display was just turned on)
  ldi func_arg_1, 45
  ldi func_arg_2, 1
  rcall sleep_ms
  ; send 8bit interface instruction
  sbi lcd_e_port, lcd_e
  sbi lcd_port, lcd_d4
  sbi lcd_port, lcd_d5
  cbi lcd_port, lcd_d6
  cbi lcd_port, lcd_d7
  nop
  nop
  cbi lcd_e_port, lcd_e ; send instruction
  ; wait for 5 ms
  ldi func_arg_1, 5
  ldi func_arg_2, 1
  rcall sleep_ms
  ldi r17, 2
  ; send above instrucion twice waiting for 200 us in between
  lcd_init_0:
    sbi lcd_e_port, lcd_e
    ldi func_arg_1, 1
    rcall sleep_us
    cbi lcd_e_port, lcd_e
    ldi func_arg_1, 20
    rcall sleep_us
    dec r17
    brne lcd_init_0 ; loop
  sbi lcd_e_port, lcd_e
  cbi lcd_port, lcd_d4 ; clear d4 (d5 is on)
  ldi func_arg_1, 1
  rcall sleep_us
  cbi lcd_e_port, lcd_e
  ldi func_arg_1, 10 ; send 0010 instruction
  rcall sleep_us
  ; now proper instructions can be sent
  ; lcd is initialized
ret

; lcd setup,
; setups lcd in 4bit mode 2 line mode with 5x8 characters
; cursor moves right
; cursor is invisible
; then cleans lcd
lcd_setup:
  ldi func_arg_1, (1<<lcd_command_function_set)|(1<<lcd_two_line_display)
;  .if lcd_has_rw_line != 0
;    rcall lcd_wait_if_busy
;  .endif
  rcall lcd_send_instruction
  ldi func_arg_1, (1<<lcd_command_entry_mode_set)|(1<<lcd_cursor_move_right)
;  .if lcd_has_rw_line != 0
;    rcall lcd_wait_if_busy
;  .endif
  rcall lcd_send_instruction
  ldi func_arg_1, (1<<lcd_command_display_control)|(1<<lcd_display_on)|(1<<lcd_blinking_on)|(1<<lcd_cursor_on) ; cursor is turned on
;  .if lcd_has_rw_line != 0
;    rcall lcd_wait_if_busy
;  .endif
  rcall lcd_send_instruction
  ldi func_arg_1, (1<<lcd_command_clear)
;  .if lcd_has_rw_line != 0
;    rcall lcd_wait_if_busy
;  .endif
  rcall lcd_send_instruction
  ldi func_arg_1, 4
  ldi func_arg_2, 1
  rcall sleep_ms ; bigger delay after clear
ret

; clears lcd
; doesnt use any arguments but subs it calls use func_arg_1 and func_arg_2
; so they are pushed to stack
lcd_clear:
  push func_arg_1
  push func_arg_2
  ldi func_arg_1,  (1<<lcd_command_clear)
  rcall lcd_send_instruction ; clear screen
  ldi func_arg_1, 4
  ldi func_arg_2, 1
  rcall sleep_ms ; sleep after clearing screen
  pop func_arg_2
  pop func_arg_1
ret

; updates lcd cursor to position stored in ram (ram_lcd_cursor_pos_byte)
lcd_update_cursor:
  lds acc, ram_lcd_cursor_pos_byte ; load cursor position
  ; cursor postion in ram is just an index
  ; however in lcd second row has addresses between 0x40 and 0x4F
  cpi acc, (0x0F + 1)
  brlo lcd_update_cursor_send_instruction ; if value is lower than 0xF then nothing should be done
  ; otherwise add 0x40 to the address by substracting negated value
  ; yes there is no addi instruction
  subi acc, -64
  lcd_update_cursor_send_instruction:
    ldi func_arg_1, (1<<lcd_command_set_ddram)
    or func_arg_1, acc ; set command with new address
    rcall lcd_send_instruction ; maybe this will work
    ; it is hard to tell if this will actually shift cursor
    ; potentialy shift instructions should be used instead
ret

; cleans display, writes out whole vram (stored at the beginning of ram)
; then backs cursor to previous position (if wanted)
; func_arg_1(0) - should cursor position be preserved
; r17 - loop counter
lcd_update:
  ldi XL, low(ram_lcd_vram_1_sstring)
  ldi XH, high(ram_lcd_vram_1_sstring) ; load beginning of vram to X register
  push func_arg_1 ; save current arguments
  push r17 ; save counter
  rcall lcd_clear
  ldi r17, lcd_display_characters ; loop counter total characters displayed
  lcd_update_loop:
    ld func_arg_1, X+ ; load next character
    rcall lcd_send_data ; print character
    .if lcd_is_two_line == 1 ; if lcd has multiline display
      cpi r17, (lcd_per_line_characters+1) ; if first row was achieved
      brne lcd_update_continue
      ; send command to change to second row
      ldi func_arg_1, (1<<lcd_command_set_ddram)|0x40
      rcall lcd_send_instruction
    .endif
    lcd_update_continue:
      dec r17
  breq lcd_update_loop_end ; if all characters were printed
  rjmp lcd_update_loop
  lcd_update_loop_end:
    pop r17
    pop func_arg_1 ; now we can check is it necessary to update cursor
    sbrc func_arg_1, 0
      rcall lcd_update_cursor ; if bit is set then move cursor to saved position
ret

; send 64 byte custom character table to CGRAM
; func_arg_1 - begginning of table in RAM lsb
; func_arg_2 - begginning of table in RAM msb
; r17 - loop counter
lcd_send_character_table:
  mov XL, func_arg_1
  mov XH, func_arg_2
  push r17
  ; reset CGRAM address to zero
  ldi func_arg_1, 0|(1<<lcd_command_set_cgram)
  rcall lcd_send_instruction
  ldi r17, 64 ; 64 bytes (8 characters with 8 lines each will be copied)
  lcd_send_character_loop:
    ld func_arg_1, X+ ; load next byte
    rcall lcd_send_data ; send it as data to CGRAM
    dec r17
  breq lcd_send_character_loop_end ; if all 64 bytes were sent
  rjmp lcd_send_character_loop
  lcd_send_character_loop_end:
    ldi func_arg_1 0|(1<<lcd_command_set_ddram) ; return to DDRAM display
    rcall lcd_send_instruction
    pop r17
ret
.endif
