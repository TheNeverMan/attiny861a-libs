.ifndef _UI_ASM_
.define _UI_ASM_

.cseg

; this subroutine performs icall jump to address stored in
; third and fourth byte of keyboard vector table of given key index
; func_arg_1 - key index (0-12)
;ui_keyboard_jump:;
;  ldi XL, low(ram_key_0_word_1)
;  ldi XH, high(ram_key_0_word_1)
;  ui_keyboard_jump_loop:
;    tst func_arg_1
;  breq ui_keyboard_jump_loop_end ; leave loop if func_arg_1 is zero
;    adiw XH:XL, 4 ; move to next key in table
;    dec func_arg_1
;  rjmp ui_keyboard_jump_loop
;  ui_keyboard_jump_loop_end:
;    adiw XH:XL, 2 ; move to second pair of values
;    ld ZL, X+
;    ld ZH, X ; fetch address to index Z register
;  icall ; jump
;et

; starts reader mode
; func_arg_3 - lsb of beginning of string to be displayed
; func_arg_4 - msb of beginning of string to be displayed
; SLENR contains length of string to be displayed
ui_reader_mode:
  ; clear SINDR as no chars were displayed yet
  clr SINDR
  ; display first chunk of data
  rcall ui_reader_display_next_screen
  cp SINDR, SLENR ; if end of text has been already achieved string is shorter than 31 chars
breq ui_reader_last_key ; then leave the whole looop
  ; main reader loop
  ; wait until new key is pressed
  ; if key index is 11 (exit) then return end exit reader mode
  ; if eos is encountered then return and exit
  ui_reader_main_loop:
    sbrs PHONECRB, NKEYPRESS ; wait for new keypress
      rjmp ui_reader_main_loop
    mov acc, PHONECRB
    cbr acc, (1<<NKEYPRESS) ; clear new key press flag
    mov PHONECRB, acc
    andi acc, PRKEYCDE_MASK ; extract last pressed key code out of register
    cpi acc, 11 ; if pressed key is exit key (#) then leave loop and terminate
  breq ui_reader_mode_end ; forcibly exit
    rcall ui_reader_display_next_screen ; on event of any other key display next screen
  cpse SINDR, SLENR
    rjmp ui_reader_main_loop
  ; now last characters have been displayed
  ; however we cant just leave the loop because everything can write to lcd now
  ; wait for one more keypress
  ui_reader_last_key:
    sbrs PHONECRB, NKEYPRESS
      rjmp ui_reader_last_key
  mov acc, PHONECRB
  cbr acc, (1<<NKEYPRESS) ; clear new key press flag
  mov PHONECRB, acc
  ui_reader_mode_end: ; after # keypress
ret

; displays next part of the text
; func_arg_3 - lsb holder of current string position
; func_arg_4 - msb holder of current string postiion
ui_reader_display_next_screen:
  ; firstly clear vram
  push func_arg_3 ; save current arguments to stack
  push func_arg_4
  ldi func_arg_1, low(ram_lcd_vram_1_sstring)
  ldi func_arg_2, high(ram_lcd_vram_2_sstring) ; area to clean begins at vram beginning
  ldi func_arg_3, 32 ; clear whole screen
  ldi func_arg_4, ' ' ; fill it with spaces
  rcall mem_fill_with_byte
  pop func_arg_4 ; restore current string address
  pop func_arg_3
  ; then amount of displayed bytes should be determined
  mov acc, SLENR
  sub acc, SINDR ; get difference between displayed bytes and length of string
  cpi acc, 31 ; if difference is bigger than 31 then operate normally, otherwise this is last sceen
brsh ui_reader_normal_display ; display normal screen
  ; otherwise display shorter string
  ; move length, information character
  ldi r17, c_stop ; stop character that will be displayed in the corner
rjmp ui_reader_copy_string
  ; standard display of 31 characters
  ui_reader_normal_display:
    ldi r17, c_right_arrow ; this in the corner will inform user that next screen is available
    ldi acc, 31 ; 31 characters will be displayed
  ; finally copy string
  ui_reader_copy_string:
    add SINDR, acc ; update index
    mov func_return_2, acc
    mov func_arg_1, func_arg_3
    mov func_arg_2, func_arg_4 ; move string address to source address
    ldi func_arg_3, low(ram_lcd_vram_1_sstring)
    ldi func_arg_4, high(ram_lcd_vram_2_sstring) ; destination is vram
    rcall mem_copy
    movw func_arg_4:func_arg_3, XH:XL ; save new string address
    sts ram_lcd_vram_last_char, r17 ; put information character to vram
    clr func_arg_1 ; update lcd with no cursor preservation
    rcall lcd_update ; update
ret

.endif
