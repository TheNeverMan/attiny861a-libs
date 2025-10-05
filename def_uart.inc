.ifndef _DEF_UART_INC_
.define _DEF_UART_INC_

; UART module
; uart configuration
.equ uart_port = PORTA
.equ uart_port_input = PINA
.equ uart_port_direction = DDRA
.equ uart_tx = 3
.equ uart_rx = 2
; uart registers
; this register holds currently sent or received byte
; it is modified by interrupt calls and should not be accessed by program
; in other conditions than putting to-be-sent value
.equ UTDR = GPIOR0
; uart buffer
; this register holds last received byte
; its value is only modified when full byte has been received
; it is safe to access from program side unlike UTDR
; (when receiving bytes UTDR not only stores bits as they arrive
; but also is immediately erased when new byte transmission starts
; unlike UDBR which is only modified when transmission of byte ends)
.def UDBR = r6
; this register holds status of uart
; uart sends 8bit frames with one stop bit
.equ UCRA = GPIOR1
  .equ UBUSY = 7 ; if set this means that uart is currently sending data and byte in uart_data should not be modified
  .equ UCEVEN = 6 ; timer counts every 8 uart cycles, one baud is 16 cycles so operations should be performed every 2 clock cycles
  ; if this byte is high operations should be performed
  .equ USENDING = 5 ; if is busy is set and this is high then uart is sending otherwise recieving data
  .equ UPARITY = 4 ; this holds temporary parity bit value
  ; value of this register is only used when parity sending mode is on
  .equ U8P = 3 ; this bit is high when last 8th bit was sent/received
  ; every time bit is sent/received this register is incremented (bits 1-3 hold index of bit that was last sent) so after
  ; 8th bit, uart_status looks like this xx01000, and stop bits can be send or receiving can end
; second control register of uart
.equ UCRB = GPIOR2
  .equ UNB = 7 ; this bit is set high every time recieving of byte ends and new value is copied to UDBR
  ; software can then set it to low after reading the byte and thus be informed when new value has appeared
  .equ UPERROR = 6 ; this bit is set high if parity bit of readen data is wrong

; baud rate calculations
; uart is timed using timer0
; timer0 generates irq every 8th uart cycle (uart cycle is 1/16 of one bit time)
; so for example when sending data, tx value should be changed every 2 timer0 cycles or 16 uart cycles
.equ uart_timer_prescaler = 8
.equ baud_rate = 9600
; uart modes of operation
.equ uart_stop_bits = 1
.equ send_parity_bit = 0 ; 1 if true
.equ negated_parity = 0 ; 1 if odd parity 0 if even
; length of full data frame (how many bits should be send)
.equ frame_length = 8 + uart_stop_bits + send_parity_bit
; this value should be put to timer0 compare register
.equ uart_timer_value = ((sys_freq_hz)/(baud_rate*uart_timer_prescaler*2))
.equ uart_us_per_cycle = (1000000/baud_rate)
.message "UART configuration"
.message "Baud Rate: "
.message baud_rate
.message "us per one baud"
.message uart_us_per_cycle
.message "Timer0 Prescaler"
.message uart_timer_prescaler
.message "Timer0 Value: "
.message uart_timer_value
.if uart_timer_value > 0xFF
  .error "Timer0 value too big to fit in 8bit register!"
.endif
.message "Stop Bits:"
.message uart_stop_bits
.message "Send Parity Bit:"
.message send_parity_bit
.message "Even Parity:"
.message negated_parity
.message "Final Frame Length"
.message (8+uart_stop_bits+send_parity_bit)

.endif
