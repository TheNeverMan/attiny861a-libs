.ifndef _MEMORY_ASM_
.define _MEMORY_ASM_

.cseg

; (16t)EEP -> RAM
; loads short string (up to 16 chars or shorter and null terminated) from eeprom
; to location in ram
; does NOT copy the terminator
; func_arg_1 - eeprom address lsb
; func_arg_2 - eeprom address msb
; func_arg_3 - ram address lsb
; func_arg_4 - ram address msb
; r17 - counter of loaded bytes
; r18 - ????
load_sztstring_from_eeprom:
  mov XL, func_arg_3 ; load ram address to X pointer register
  mov XH, func_arg_4
  push r17 ; save r17 value
  push r18
  ldi r18, 0x1
  clr r17
  load_sztstring_loop:
    out EEARL, func_arg_1
    out EEARH, func_arg_2 ; load eeprom register
    ldi acc, (1<<EERE) ; load read enable to acc (next instrucion executes after 4 cycles, this is where real read happens)
    out EECR, acc ; read eeprom byte to EEDR
    in acc, EEDR ; load readen byte to acc
    tst acc ; if character is null
  breq load_sztstring_loop_end
    st X+, acc ; put value to ram
    inc func_arg_1
    brne load_sztstring_continue
    inc func_arg_2
    load_sztstring_continue: ;increment eeprom pointer
      inc r17 ; increment byte counter
      cpi r17, 16 ; if 16th character had been loaded
    breq load_sztstring_loop_end ; end loop
    rjmp load_sztstring_loop
  load_sztstring_loop_end:
    pop r18
    pop r17
ret

; (*)x -> RAM
; fills area in ram with given byte value
; fills length after start pointer
; func_arg_1 - start address lsb
; func_arg_2 - start address msb
; func_arg_3 - how many bytes should be filled
; func_arg_4 - value
; r17 - counter
; todo: remove r17 from here and decrease func_arg_3 instead
mem_fill_with_byte:
  movw XH:XL, func_arg_2:func_arg_1 ; maybe ???
  push r17
  clr r17
  mem_fill_loop:
    cp func_arg_3, r17 ; compare how many bytes were filled
  breq mem_fill_loop_end ; if both values are equal then leave, this way even if func_arg_3 is zero no undefined
    ; behaviours will happen
    st X+, func_arg_4 ; fill memory
    inc r17 ; increment counter
  rjmp mem_fill_loop
  mem_fill_loop_end:
    pop r17
ret

; (*t)RAM -> RAM
; copies given amount of bytes to ram location
; and stops if terminator is got (terminator is NOT copied)
; func_arg_1 - source address lsb
; func_arg_2 - source address msb
; func_arg_3 - destination address lsb
; func_arg_4 - destination address msb
; func_return_1 - terminator
; func_return_2 - maximum length
; after return func_return_1 is 0x01 if terminator was encountered
; or 0x00 if whole length was copied
mem_copy_with_terminator:
  movw XH:XL, func_arg_2:func_arg_1 ; copy source address
  movw YH:YL, func_arg_4:func_arg_3 ; copy destination address
  mov func_arg_1, func_return_1 ; move terminator somewhere else as func_return_1 will be used
  clr func_return_1
  mem_copy_with_terminator_loop:
    ld acc, X+ ; load source character
    cp acc, func_return_1 ; compare it to terminator
  breq mem_copy_with_terminator_end_terminator ; if equal then end
    st Y+, acc ; store it to destination
    dec func_return_2
  breq mem_copy_with_terminator_end ; decrement string length index and leave if all is copied
  rjmp mem_copy_with_terminator_loop
  mem_copy_with_terminator_end_terminator:
    ldi func_return_1, 0x01 ; loop has been interrupted by terminator, set returned value to 0x01
  mem_copy_with_terminator_end:
ret

; (*)RAM -> RAM
; copies given amount of bytes to ram location
; func_arg_1 - source address lsb
; func_arg_2 - source address msb
; func_arg_3 - destination address lsb
; func_arg_4 - destination address msb
; func_return_2 - length
mem_copy:
  movw XH:XL, func_arg_2:func_arg_1 ; copy source address
  movw YH:YL, func_arg_4:func_arg_3 ; copy destination address
  mem_copy_loop:
    ld acc, X+ ; load source byte
    st Y+, acc ; store it to destination
    dec func_return_2
  breq mem_copy_end ; decrement string length index and leave if all is copied
  rjmp mem_copy_loop
  mem_copy_end:
ret

; (*)FLASH -> RAM
; loads given amount of bytes from flash memory to ram location
; func_arg_1 - source address lsb
; func_arg_2 - source addres msb
; func_arg_3 - destination address lsb
; func_arg_4 - destination address msb
; func_return_2 - length
load_from_flash:
  movw ZH:ZL, func_arg_2:func_arg_1 ; copy source address (it MUST be Z register)
  movw YH:YL, func_arg_4:func_arg_3 ; copy destination address
  load_from_flash_loop:
    lpm acc, Z+ ; load source byte from flash
    st Y+, acc ; store it to destination
    dec func_return_2
  breq load_from_flash_loop_end ; decrement string length index and leave if all is copied
  rjmp load_from_flash_loop
  load_from_flash_loop_end:
ret

; (*)EEP -> RAM
; loads given amount of bytes from eeprom to ram location
; func_arg_1 - source address lsb
; func_arg_2 - source addres msb
; func_arg_3 - destination address lsb
; func_arg_4 - destination address msb
; func_return_2 - length
load_from_eeprom:
  mov XL, func_arg_3 ; load ram address to X pointer register
  mov XH, func_arg_4
  load_eep_loop:
    out EEARL, func_arg_1
    out EEARH, func_arg_2 ; load eeprom register
    ldi acc, (1<<EERE) ; load read enable to acc (next instrucion executes after 4 cycles, this is where real read happens)
    out EECR, acc ; read eeprom byte to EEDR
    in acc, EEDR ; load readen byte to acc
    st X+, acc ; put value to ram
    inc func_arg_1 ; increment address stored in register
    brne load_eep_continue ; if no overflow in lsb
    inc func_arg_2 ; otherwise increment msb
    load_eep_continue: ;increment eeprom pointer
      dec func_return_2 ; increment byte counter
    breq load_eep_loop_end ; if all bytes copied then end
    rjmp load_eep_loop
  load_eep_loop_end:
ret

; calculates length until terminator char is got
; func_arg_1 - string beginning lsb
; func_arg_2 - string beginning msb
; func_arg_3 - terminator
; func_return_1 - length
mem_string_length:
  movw XH:XL, func_arg_2:func_arg_1
  clr func_return_1
  mem_string_length_loop:
    ld acc, X+
    cp acc, func_arg_3
  breq mem_string_length_loop_end
    inc func_return_1
  rjmp mem_string_length_loop
  mem_string_length_loop_end:
ret


.endif
