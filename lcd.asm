.include "m2560def.inc"

.equ E  = 0b00100000 ; Enable
.equ RW = 0b01000000 ; Read/Write
.equ RS = 0b10000000 ; Register Select


.org 0x0000
	rjmp main


read_enable:
	sbi PORTC, 5 ; Set E high
	;rcall delay ; wait 
	cbi PORTC, 5 ; set E low
	;rcall delay ; wait 
	ret

	
send_data:
	out PORTB, r16 ; put data on data bus
	sbi PORTC, 7 ; set RS High = character
	cbi PORTC, 6 ; set RW LOW = sending data to lcd
	rcall read_enable
	ret
	
send_command:
	out PORTB, r16 ; put data on data bus
	cbi PORTC, 7 ; set RS LOW = character
	cbi PORTC, 6 ; set RW LOW = sending data to lcd
	rcall read_enable
	ret 

main: 

	ldi r16, 0b11111111 ; set all pin on port B to output
	out DDRB, r16

	ldi r16, 0b11100000 ; set top 3 pins on port C to output
	out DDRC, r16 

	; rcall powerUP_delay

	;command
	ldi r16, 0b00111000 ; Function set : set 8-bit mode; 2-line display ; 5x8 font
	rcall send_command



	;command
	ldi r16, 0b00001110 ; Display ON/OFF : Display on; Cursor on; Blink off
	rcall send_command


	;command
	ldi r16, 0b00000110 ; Increment and shift cursor and no shift display
	rcall send_command


	;data	
	ldi r16, '6' ; 
	out PORTB, r16

	;data	
	ldi r16, 'H' ; 
	out PORTB, r16
loop:
	jmp loop

