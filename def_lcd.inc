.ifndef _DEF_LCD_INC_
.define _DEF_LCD_INC_

; does interface has option to read from lcd (1 if true)
.equ lcd_has_rw_line = 1
.if lcd_has_rw_line == 0
  .message "LCD No RW"
.else
  .message "LCD Has RW"
.endif
; LCD definitons
; lcd on PORTA
.equ lcd_port_dir = DDRA
.equ lcd_port = PORTA
.equ lcd_port_input = PINA
; e pin is on a different port due to size limits
.equ lcd_e_port_dir = DDRB
.equ lcd_e_port = PORTB
; port configuration 4bit mode
.equ lcd_rs = 0
.equ lcd_rw = 1
.equ lcd_e  = 3
.equ lcd_d7 = 7
.equ lcd_d6 = 6
.equ lcd_d5 = 5
.equ lcd_d4 = 4

; this constant defines the cgram type of HD44780
; this way special characters such as arrows could be used with ui
; 0 - generic (only ASCII will be used)
; 1 - japanese
; 2 - european
; 3 - custom
.equ lcd_type = 1
.equ lcd_is_two_line = 1 ; is one line (0) or two line (1) display
.equ lcd_display_characters = 32 ; how many characters IN TOTAL lcd can display on screen
.equ lcd_per_line_characters = 16 ; how many characters are in ONE LINE on the display
.message "Display Has "
.message lcd_display_characters
.message "Characters"

.equ lcd_has_brightness = 1 ; does mcu control brightness of lcd with pwm counter 0/1
.equ lcd_default_brightness = 127 ; this is the default brightness value that will be loaded to OCR1A on on init
.if lcd_has_brightness == 1
  .message "LCD Default Brightness"
  .message lcd_default_brightness
.else
  .message "LCD Has No Brightness Control"
.endif



.if lcd_type == 1
  .message "LCD Has Japanese CGRAM"
.endif

.if lcd_type == 2
  .message "LCD Has European CGRAM"
.endif

.if lcd_type == 3
  .message "LCD User Defined CGRAM"
.endif

; lcd busy flag bit
.equ lcd_bf_bit = 7
; lcd command bits
.equ lcd_command_clear            = 0
.equ lcd_command_return_home      = 1
.equ lcd_command_entry_mode_set   = 2
  .equ lcd_cursor_move_right        = 1
  .equ lcd_move_window              = 0
.equ lcd_command_display_control  = 3
  .equ lcd_display_on               = 2
  .equ lcd_cursor_on                = 1
  .equ lcd_blinking_on              = 0
.equ lcd_command_shift            = 4
  .equ lcd_shift_window             = 3
  .equ lcd_shift_right              = 1
.equ lcd_command_function_set     = 5
  .equ lcd_8bit_interface           = 4
  .equ lcd_two_line_display         = 3
  .equ lcd_5x10_chars               = 2
.equ lcd_command_set_cgram        = 6
.equ lcd_command_set_ddram        = 7
; lcd command options

; lcd backlight brightness value register
;.equ lcd_brigthness_pin = OC1A
.equ lcd_brigthness_register = OCR1A

.endif
