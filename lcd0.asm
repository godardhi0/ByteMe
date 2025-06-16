.include "m2560def.inc"

; Define control bits
.equ E  = 0b00100000 ; PC5
.equ RW = 0b01000000 ; PC6
.equ RS = 0b10000000 ; PC7

.org 0x0000
    rjmp main

; Short delay (~1ms)
delay:
    ldi r18, 255
delay_loop:
    dec r18
    brne delay_loop
    ret

; Long delay (~50ms)
long_delay:
    ldi r19, 100
long_delay_loop:
    rcall delay
    dec r19
    brne long_delay_loop
    ret

; Pulse Enable
pulse_enable:
    sbi PORTC, 5   ; Set E high
    rcall delay
    cbi PORTC, 5   ; Set E low
    rcall delay
    ret

; Send command to LCD
lcd_command:
    out PORTB, r16 ; Put command on data bus
    cbi PORTC, 7   ; RS = 0
    cbi PORTC, 6   ; RW = 0
    rcall pulse_enable
    ret

; Send data to LCD
lcd_data:
    out PORTB, r16 ; Put data on data bus
    sbi PORTC, 7   ; RS = 1
    cbi PORTC, 6   ; RW = 0
    rcall pulse_enable
    ret

main:
    ; Set all PORTB pins (data lines) to output
    ldi r16, 0xFF
    out DDRB, r16

    ; Set PC5 (E), PC6 (RW), PC7 (RS) as output
    ldi r16, 0b11100000
    out DDRC, r16

    ; Wait for LCD power-up (~50ms)
    rcall long_delay

    ; Function set: 8-bit, 2-line, 5x8 font
    ldi r16, 0b00111000
    rcall lcd_command

    ; Display ON, cursor ON, blink ON
    ldi r16, 0b00001110
    rcall lcd_command

    ; Entry mode: increment, no shift
    ldi r16, 0b00000110
    rcall lcd_command

    ; Clear display
    ldi r16, 0b00000001
    rcall lcd_command

    ; Wait longer after clear (~50ms)
    rcall long_delay

    ; Write 'H'
    ldi r16, 'H'
    rcall lcd_data

    ; Write 'H'
    ldi r16, '6'
    rcall lcd_data

loop:
    rjmp loop
