.ifndef _UART_ASM_
.define _UART_ASM_

.cseg

; configures pins and control registers
uart_init:
  ; tx port as output
  sbi uart_port_direction, uart_tx
  ; rx port as input
  cbi uart_port_direction, uart_rx
  sbi uart_port, uart_rx ; pull up resistor on rx
  sbi uart_port, uart_tx ; logic high on tx
  sbi TCCR0A, WGM00 ; set timer0 to clear on compare mode
  ldi acc, uart_timer_value
  out OCR0A, acc ; set timer0 limit to calculated uart timer value
  clr acc
  out TCNT0L, acc ; clear timer0 register
  out UCRA, acc ; clear UART control register
  out UTDR, acc ; clear temp data register
  clr UDBR ; clear data buffer register
  ; TIMSK has too high address to be supported by sbi and cbi
  in acc, TIMSK
  sbr acc, (1<<OCIE0A) ; interrupt on OCR0A compare match
  out TIMSK, acc

  ; INT1 is enabled on low level of tx pin
  in acc, GIMSK
  sbr acc, (1<<INT1)
  out GIMSK, acc
  ; after this subroutine timer0 is stopped in 8bit CTC mode with uart timer value
  ; in compare register A and interrupt is enabled when compare match happens
  sei ; enable interrupts
ret

; uart send byte
; func_arg_1 byte to be sent
uart_send_byte:
  ; wait until uart is free
  sbic UCRA, UBUSY
    rjmp uart_send_byte
  ; right now new data can be sent
  ; wait for two uart cycles so data is not sent right after last frame
  out UTDR, func_arg_1 ; save uart data to data buffer
  in acc, UCRA
  ldi acc, (1<<UBUSY) | (1<<USENDING) | (1<<UPARITY) ; 0 is even number so UPARITY is high
  out UCRA, acc ; load correct configuration to control register
  cbi uart_port, uart_tx ; set tx to logic low (start signal)
  in acc, TCCR0B
  sbr acc, (1<<CS01)
  out TCCR0B, acc  ; start clock with prescaler 1/8
ret ; in god we trust

; interrupt triggered on falling edge on rx pin
; starts receiving uart mode
uart_rx_begin_interrupt:
  ;sbi PORTA, PORTA7
  ; if uart is busy then return from interrupt
  ; because this means that it is currently sending data
  ; this return fucks up any next attempt of reading data
  ; as uart can finish sending and free module in the middle of incoming byte
  ; and random falling edge will be interpreted as start signal
  ; this is why this implementaion is no duplex
  ; user should avoid this situation at all costs
  sbic UCRA, UBUSY
    reti ; here
  ;push accumulator and status register to stack
  push acc
  in acc, SREG
  push acc
  in acc, GIMSK
  cbr acc, (1<<INT1) ; disable rx begin interrupt
  out GIMSK, acc
  ldi acc, (1<<UBUSY)|(1<<UCEVEN) ; load UCRA, USENDING is low because we are in reading mode
  ; UCEVEN is high because read cycles are offsetted by one so read happens in the middle of bit
  out UCRA, acc
  clr acc
  out UTDR, acc ; clear data buffer
  ; retrieve acc and sreg from stack
  in acc, TCCR0B
  sbr acc, (1<<CS01)
  out TCCR0B, acc  ; start clock with prescaler 1/8
  pop acc
  out SREG, acc
  pop acc
;  cbi PORTA, PORTA7
reti ; lets go

; uart timer interrupt
uart_interrupt:
  ;push accumulator and status register to stack
;  sbi PORTA, PORTA6
  push acc
  in acc, SREG
  push acc
  sbis UCRA, UBUSY ; if uart is not busy then why are we here
    rjmp uart_stop_loop ; stop the looop
  sbic UCRA, USENDING ; if sending byte is set then jump to sending func
    rjmp uart_send_bit
  rjmp uart_receive_bit ; otherwise do receiving

  uart_return_from_operation: ; here bit sending or receiving subs return
  ; update the cycle even/odd counter
  ; if the flag is high then set it to low and the opposite
  in acc, UCRA
  sbrc acc, UCEVEN
    cbi UCRA, UCEVEN
  sbrs acc, UCEVEN
    sbi UCRA, UCEVEN
  ; if UCEVEN is 0 then sbrc skips -> sbrs executes sbi
  ; if UCEVEN is 1 then sbrc clears -> and sbrs skips because acc holds previous UCEVEN value
  ; restore acc and status register
  uart_return_from_interrupt:
    pop acc
    out SREG, acc
    pop acc
;  cbi PORTA, PORTA6
reti

uart_send_bit:
; send bits only on even cycles
  sbis UCRA, UCEVEN
    rjmp uart_return_from_operation
  ; loop can only end on even cycle so there is no need to wait for one timer cycle
  ; after sending last bit in stop loop to finish sending it
  sbic UCRA, U8P ; if 8 bits have been send then we can send stop bits or parity bit
    rjmp uart_send_control_bits
  ; now we can send bit
  ; increase sent bit counter
  uart_send_bit_return: ;this label is used to send control bits from jump uart_send_control_bits
    sbic UTDR, 0 ; write out lowest bit of the byte
      sbi uart_port, uart_tx
    sbis UTDR, 0
      cbi uart_port, uart_tx
    ; calculate parity bit
    ; only on data bits (before 8bit)
    sbic UCRA, U8P
      rjmp uart_send_modify_control_and_data_registers_after_sending
    ; now if sent bit (lowest in acc) is high then negate UPARITY
    sbis UTDR, 0
      rjmp uart_send_modify_control_and_data_registers_after_sending
    ; now negate UPARITY because sent bit was high
    ; why negating bits is such a pain
    in acc, UCRA
    sbrc acc, UPARITY
      cbi UCRA, UPARITY
    sbrs acc, UPARITY
      sbi UCRA, UPARITY
    ; by using acc as holder of previous UPARITY value this works
    uart_send_modify_control_and_data_registers_after_sending: ; long
      in acc, UCRA
      inc acc ; increment sent bit counter
      out UCRA, acc

      in acc, UTDR
      lsr acc ; rotate data right so that bit0 in uart buffer has value of next bit
      out UTDR, acc
rjmp uart_return_from_operation

uart_receive_bit:
; read bits only on even cycles
  sbis UCRA, UCEVEN
    rjmp uart_return_from_operation
  ; uart reads start bit as first value
  ; so transmission is finished after 9th bit
  in acc, UCRA
  andi acc, 0b00001111 ; mask out all control bits
  ; now acc holds amount of received bytes
  cpi acc, 8+1 ; frame plus start
breq uart_receive_finish ; copy temp buffer to output and set UNB high
  in acc, uart_port_input ; read port input
  bst acc, uart_rx ; store rx value
  in acc, UTDR
  lsr acc ; rotate UTDR left so LSB stays low
  bld acc, 7 ; put stored rx value to most significant bit of temp register
  out UTDR, acc
  in acc, UCRA
  inc acc
  out UCRA, acc ; increment received bits counter
  ; now parity checks
  ; if currently recieved bit is high then negate uperror
  brtc uart_end_receive_bit
  in acc, UCRB
  ; negate uperror
  sbrc acc, UPERROR
    cbi UCRB, UPERROR
  sbrs acc, UPERROR
    sbi UCRB, UPERROR
  uart_end_receive_bit:
rjmp uart_return_from_operation



uart_receive_finish:
  in acc, UTDR
  mov UDBR, acc ; copy temp value to output register
  sbi UCRB, UNB ; notify about new value
  cbi UCRB, UPERROR ; for now say that every byte was received successfully
  ; do parity checks here
  .if send_parity_bit != 0
    in acc, uart_port_input ; read port input
    bst acc, uart_rx ; store rx value
    push r17
    clr r17
    clr acc
    sbic UCRB, UPERROR
      inc acc
    ; acc is 0x1 if uperror is set
    bld r17, 0
    eor acc, r17 ; 0 if they are same, 1 if different
    .if negated_parity == 1
      com acc
    .endif
    bst acc, 0
    in acc, UCRB
    bld acc, UPERROR
    out UCRB, acc
    pop r17
  .endif
  .if uart_mimics_keyboard != 0
    ldi acc, 0b11110000
    and PHONECRB, acc
    mov acc, UDBR
    andi acc, 0b00001111
    sbr acc, (1<<NKEYPRESS)
    or PHONECRB, acc
    ; save keycode to PHONECRB
  .endif
rjmp uart_stop_loop ; finish interrupt and end loop

; manages sending parity and stop bits after 8th bit has been sent
uart_send_control_bits:
  in acc, UCRA
  bst acc, UPARITY ; save parity bit
  andi acc, 0b00001111 ; mask out all control bits
  ; now acc holds amount of sent bytes
  ; if all bits have been sent then stop the loop
  cpi acc, frame_length
breq uart_stop_loop
  ; not all bits have been sent
  ; if parity bit is supposed to be sent
  .if send_parity_bit == 1
    ; parity bit is always 9th bit, so if eigth was sent then we can go
    cpi acc, 8
brne uart_send_stop_bits ; if its not 9th bit time then do something else idk
    in acc, UTDR
    bld acc, 0 ; load uart data register and store parity bit in the lowest cell
    .if negated_parity == 1
      com acc ; even parity (use one's complement rather than u2 neg command)
    .endif
    out UTDR, acc
rjmp uart_send_bit_return ; send parity bit
  .endif
  uart_send_stop_bits:
    ; it is not necessary to check how many bits do we need to send, it is done above
    ; stop bits are last bits so just send them until frame length is correct
    sbi UTDR, 0
rjmp uart_send_bit_return

uart_stop_loop:
  ; TCCR0B is to high to be supported by sbi and cbi
  in acc, TCCR0B
  cbr acc, (1<<CS00)|(1<<CS01)|(1<<CS02); clear CS0-2 bits this way clock is halted no matter which prescaler is used
  out TCCR0B, acc ; stop the clock
  clr acc
  out UCRA, acc ; uart is not busy anymore
  out TCNT0L, acc ; clear clock
  ; INT1 is enabled
  in acc, GIMSK
  sbr acc, (1<<INT1) ; enable INT1 on low state of rx
  out GIMSK, acc
rjmp uart_return_from_interrupt

; sends short string (up to 16 chars or shorter and char terminated) from ram
; func_arg_1 - ram address lsb
; func_arg_2 - ram address msb
; func_arg_3 - terminator character
; r17 - counter of sent bytes
uart_send_sstring:
  mov XL, func_arg_1
  mov XH, func_arg_2 ; load ram address to x pointer register
  push r17
  clr r17 ; save r17 and clear it
  uart_send_loop:
    ld acc, X+
    cpi r17, 16 ; if 16 bytes were sent then finish
  breq uart_send_end_loop
    mov func_arg_1, acc
    push acc
    rcall uart_send_byte ; send byte
    pop acc
    cp acc, func_arg_3
  breq uart_send_end_loop ; if byte is terminator then finish
    inc r17 ; increment sent byte counter
  rjmp uart_send_loop
  uart_send_end_loop:
    pop r17 ; restore r17
ret

; sends short null terminated string (up to 16 chars or shorter and null terminated) from ram
; func_arg_1 - ram address lsb
; func_arg_2 - ram address msb
uart_send_sztstring:
  ldi func_arg_3, 0 ; null value to terminator
  rcall uart_send_sstring
ret

; sends short newline terminated string (up to 16 chars or shorter and null terminated) from ram
; func_arg_1 - ram address lsb
; func_arg_2 - ram address msb
uart_send_sntstring:
  ldi func_arg_3, 10 ; newline value to terminator
  rcall uart_send_sstring
ret

; keeps copying UDBR value when new bit flag is set
; until UDBR has value of newline (newline is copied)
; func_arg_1 - ram address lsb
; func_arg_2 - ram address msb
; to ram location
uart_receive_ntstring:
  mov XL, func_arg_1
  mov XH, func_arg_2 ; load ram address to x pointer register
  uart_receive_loop:
    ;sbi PORTA, PORTA7
    sbis UCRB, UNB
  rjmp uart_receive_loop ; wait until new character appears in UCRB
  ;  cbi PORTA, PORTA7
    mov acc, UDBR
    st X+, acc ; store
    cbi UCRB, UNB ; clear new character bit
    cpi acc, 10 ; compare byte to newline
  brne uart_receive_loop ; if it is not newline then continue looping
ret

.endif
