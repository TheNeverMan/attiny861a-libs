.ifndef _DEBUG_ASM_
.define _DEBUG_ASM_

.cseg

; debug uart tx by sending some data
debug_abn_uart:
  ldi func_arg_1, 0xAA
  rcall uart_send_byte ; send 10101010 on uart

  ldi func_arg_1, 0x55
  rcall uart_send_byte ; send 01010101 on uart

  ldi func_arg_1, 13
  rcall uart_send_byte ; send cr on uart

  ldi func_arg_1, 10
  rcall uart_send_byte ; send newline on uart
ret

wait_for_half_second:
  ldi func_arg_1, 250
  ldi func_arg_2, 2
  rcall sleep_ms
ret

; cat program on uart
debug_cat_uart:
  ldi func_arg_1, low(ram_lcd_vram_1_sstring)
  ldi func_arg_2, high(ram_lcd_vram_1_sstring) ; ram string address
  rcall uart_receive_ntstring ; tries to receive string
  ; after that sends it back
  ldi func_arg_1, low(ram_lcd_vram_1_sstring)
  ldi func_arg_2, high(ram_lcd_vram_1_sstring) ; ram string address
  rcall uart_send_sntstring ; tries to receive string
ret

; prints received char from uart on lcd
; if lcd is full then clears lcd and prints on clear
; this does not use high level lcd_update or vram operations (which sucks)
debug_uart_screen:
  sbi debug_led_port, debug_led
  lds acc, ram_lcd_cursor_pos_byte
  cpi acc, 16 ; if reached end of first line
brne debug_uart_screen_check_if_last_char
  ldi func_arg_1, (1<<lcd_command_set_ddram)|0x40 ; switch to second line
  rcall lcd_send_instruction

  debug_uart_screen_check_if_last_char:
    lds acc, ram_lcd_cursor_pos_byte
    cpi acc, 33
brne debug_uart_screen_check_uart ; if not equal then ignore
  rcall lcd_clear ; if 32 characters were displayed then clear screen
  clr acc
  sts ram_lcd_cursor_pos_byte, acc ; reset cursor pos
  rcall lcd_update_cursor
  debug_uart_screen_check_uart:
    ; check if there are new bytes on uart
    sbis UCRB, UNB
rjmp debug_uart_screen ; if there is no new byte then loop
  cbi debug_led_port, debug_led
  ; otherwise print byte
  cbi UCRB, UNB ; mark byte as readen
  mov func_arg_1, UDBR
  rcall lcd_send_data ; print byte on lcd
  lds acc, ram_lcd_cursor_pos_byte
  inc acc
  sts ram_lcd_cursor_pos_byte, acc ; increase cursor position
  mov func_arg_1, acc
  rcall uart_send_byte
ret

; debugs reader mode (shows string from uart)
debug_reader_mode:
  ldi func_arg_1, low(ram_uart_buffer)
  ldi func_arg_2, high(ram_uart_buffer)
  rcall uart_receive_ntstring ; get string from uart
  ; i think that func_arg_1 and func_arg_2 still hold original values
  ldi func_arg_3, 0x0A ; newline
  rcall mem_string_length
  mov SLENR, func_return_1 ; get string length and put it to limit
  movw func_arg_4:func_arg_3, func_arg_2:func_arg_1
  mov acc, PHONECRB
  cbr acc, (1<<NKEYPRESS) ; clear first keypress
  mov PHONECRB, acc
  rcall ui_reader_mode
ret

; loads string 1 from eeprom puts it to ram and sends in on uart
debug_hello_world_uart:
  ldi func_arg_1, low(mem_sztstring_test)
  ldi func_arg_2, high(mem_sztstring_test) ; eeprom string address
  ldi func_arg_3, low(ram_lcd_vram_1_sstring)
  ldi func_arg_4, high(ram_lcd_vram_1_sstring) ; ram string address
  rcall load_sztstring_from_eeprom ; load string
  ldi func_arg_1, low(ram_lcd_vram_1_sstring)
  ldi func_arg_2, high(ram_lcd_vram_1_sstring)
  rcall uart_send_sztstring ; send string on uart
ret

; decreases lcd anode brightness to zero in a slow loop
debug_decrease_brightness_slowly:
  ldi func_arg_1, 100
  ldi func_arg_2, 1
  rcall sleep_ms ; wait for 100 ms
  rcall lcd_decrease_brightness ; decrease brightness
  in acc, lcd_brigthness_register
  tst acc ; if not zero then loop
brne debug_decrease_brightness_slowly
ret

; increases lcd anode brightness to zero in a slow loop
debug_increase_brightness_slowly:
  ldi func_arg_1, 100
  ldi func_arg_2, 1
  rcall sleep_ms ; wait for 100 ms
  rcall lcd_increase_brightness ; increase brightness
  in acc, lcd_brigthness_register
  cpi acc, 0xFF ; if not max then loop
brne debug_increase_brightness_slowly
ret

.endif
