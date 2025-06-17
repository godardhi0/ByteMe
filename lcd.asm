.include "m2560def.inc"

.org 0x0000 ; vecteur RESET
	rjmp RESET

.org 0x0002 ; vecteur d'interruption INT0
	rjmp INT0_ISR ; ISR : Interruption Service Routine


read_enable:
	sbi PORTC, 5 ; Set E high
	rcall delay ; wait 
	cbi PORTC, 5 ; set E low
	rcall delay ; wait 
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

;------------------------------------------------------
; Sous-programe : configuration du timer2 
delay_def:

	ldi r24, 0
	sts TCNT2, r24
	
	ldi r24, (1 << WGM21)  ; Mode CTC
    sts TCCR2A, r24

    ldi r24, (1 << CS22) | (1 << CS21) ; prescaler 64
    sts TCCR2B, r24

    ldi r24, 499 ; Delay = (OCRnA + 1) * Prescaler / F_CPU : ~2ms
    sts OCR2A, r24

	ret

;------------------------------------------------------
; Sous-programme : (~44ms) avec Timer2
delay:
   ldi r19, 5 ;  delay  : 22 * 2ms ~ 44 ms
wait_compare:
	sbis TIFR2, OCF2A
	rjmp wait_compare
 
    ldi r24, (1 << OCF2A) ; Effacer le flag
    out TIFR2, r24
	dec r19
	brne wait_compare
    ret

RESET:

	; configuration du timer2
	rcall delay_def

	
	ldi r16, 0b11111111 ; set all pin on port B to output
	out DDRB, r16

	ldi r16, 0b11100000 ; set top 3 pins on port C to output
	out DDRC, r16 

	rcall delay

	;command
	ldi r16, 0b00111000 ; Function set : set 8-bit mode; 2-line display ; 5x8 font
	rcall send_command


	;command
	ldi r16, 0b00001110 ; Display ON/OFF : Display on; Cursor on; Blink off
	rcall send_command


	;command
	ldi r16, 0b00000110 ; Increment and shift cursor and no shift display
	rcall send_command


	;command
	ldi r16, 0b00000001 ;Clear display
	rcall send_command


	rcall delay

	ldi r16, 0b00000100  ; Configurer PD0 comme entrée et PD3 comme sortie
	out DDRD, r16


    ; Activer pull-up sur PD0
    ldi r16, (1 << PORTD0)
    out PORTD, r16

    ; Configurer INT0 sur front montant
    ldi r16, (1 << ISC01) | (0 << ISC00)
    sts EICRA, r16

    ; Activer l’interruption INT0
    ldi r16, (1 << INT0)
    out EIMSK, r16

    ; Activer les interruptions globales
    sei
	
main: 
	rjmp main ; boucle infinie
	

;------------------------------------------------------
; Routine d'interruption INT0
INT0_ISR:

    ; Sauvegarder registre utilisé
	push r16
	push r17
	push r18

	
    in r17, PORTD
   	ldi r18, (1<<PORTD3)
    eor r17, r18
    out PORTD, r17

    
    ; Effacer l'écran
    ldi r16, 0b00000001
    rcall send_command

    ; Pause après effacement
    rcall delay

	; vérifie l'état actuel et afficher ON ou OFF
	tst r20 ; Tester si r20==0 (OFF)
	breq _LED_ON

_LED_OFF:
		
    ; Afficher le caractère 'Led Off'
    ldi r16, 'L'
    rcall send_data
	ldi r16, 'e'
    rcall send_data
	ldi r16, 'd'
    rcall send_data
	ldi r16, ' '
    rcall send_data
	
    ldi r16, 'O'
    rcall send_data
    ldi r16, 'f'
    rcall send_data
    ldi r16, 'f'
    rcall send_data

    
    ;Metter le flag à 0
    ldi r20, 0
    rjmp end_ISR


_LED_ON:
		
    ; Afficher le caractère 'Led On'
    ldi r16, 'L'
    rcall send_data
	ldi r16, 'e'
    rcall send_data
	ldi r16, 'd'
    rcall send_data
	ldi r16, ' '
    rcall send_data
	
    ldi r16, 'O'
    rcall send_data
    ldi r16, 'n'
    rcall send_data

    ;Metter le flag à 1
    ldi r20, 1
   

end_ISR:
	POP r18
	POP r17
	POP r16
	reti

