.ifndef _I2C_ASM_
.define _I2C_ASM_

; i2c on USI read and write

.cseg

; configures pins and USI control registers (and normal registers)
uart_init:
  ldi acc, 0xFF
  out USIDR, acc ; fill shift register with 1s
  ldi acc, (1<<USIOIF)|(1<<USIDC)
  out USISR, acc ; clear interrupt requests
  ldi acc, (1<<USIWM1)||(1<<USICS1)
  out USICR, acc

.endif
