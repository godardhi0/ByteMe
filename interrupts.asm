.include "m2560def.inc" ; Inclusion des définitions pour ATmega2560


.org 0x0000
    rjmp RESET          ; Vecteur de reset

.org 0x0002
    rjmp INT0_ISR       ; Vecteur d’interruption externe INT0

;------------------------------------------------------
; Sous-programme : Pulse Enable pour LCD
pulse_enable:
    sbi PORTC, 5        ; Mettre E à 1
    rcall delay
    cbi PORTC, 5        ; Mettre E à 0
    rcall delay
    ret

;------------------------------------------------------
; Sous-programme : Envoyer une commande au LCD
lcd_command:
    out PORTB, r16      ; Envoyer la commande sur le bus de données
    cbi PORTC, 7        ; RS = 0 (commande)
    cbi PORTC, 6        ; RW = 0 (écriture)
    rcall pulse_enable
    ret

;------------------------------------------------------
; Sous-programme : Envoyer des données au LCD
lcd_data:
    out PORTB, r16      ; Envoyer les données sur le bus de données
    sbi PORTC, 7        ; RS = 1 (données)
    cbi PORTC, 6        ; RW = 0 (écriture)
    rcall pulse_enable
    ret

    
delay_def:

	ldi r24, 0
	sts TCNT2, r24
	
	ldi r24, (1 << WGM21)  ; Mode CTC
    sts TCCR2A, r24

    ldi r24, (1 << CS22) | (1 << CS21) ; prescaler 64
    sts TCCR2B, r24

    ldi r24, 249 ; Delay = (OCRnA + 1) * Prescaler / F_CPU : 
    sts OCR2A, r24

	ret

;------------------------------------------------------
; Sous-programme : (~1ms) avec Timer2
delay:
   ldi r19, 10 ;  
wait_compare:
	sbis TIFR2, OCF2A
	rjmp wait_compare
 
    ldi r24, (1 << OCF2A) ; Effacer le flag
    out TIFR2, r24
	dec r19
	brne wait_compare
    ret

;------------------------------------------------------
; Routine de démarrage
RESET:

	;configuratuon du Timer2

	rcall delay_def


    ; Configurer PORTB comme sortie (bus de données LCD)
    ldi r16, 0xFF
    out DDRB, r16

    ; Configurer PC5 (E), PC6 (RW), PC7 (RS) comme sorties ; PC1 comme entre
    ldi r16, 0b11100000
    SBI PORTC, 1
    out DDRC, r16

    ; Attendre la stabilisation du LCD (~50ms)
    rcall delay

    ; Initialisation LCD
    ; Fonction : 8 bits, 2 lignes, 5x8 points
    ldi r16, 0b00111000
    rcall lcd_command

    ; Affichage ON, curseur ON, clignotement ON
    ldi r16, 0b00001110
    rcall lcd_command

    ; Mode entrée : incrément, pas de décalage
    ldi r16, 0b00000110
    rcall lcd_command

    ; Effacer l’écran
    ldi r16, 0b00000001
    rcall lcd_command

    ; Pause longue après effacement
    rcall delay

    ; Configurer PD0 comme entrée et PD3 comme sortie
    ldi r16, 0b00001000 ; PD3 sortie
    out DDRD, r16

    ; Activer pull-up sur PD0
    ldi r16, (1 << PORTD0)
    out PORTD, r16

    ; Configurer INT0 sur front descendant (pression bouton)
    ldi r16, (1 << ISC01)
    sts EICRA, r16

    ; Activer l’interruption INT0
    ldi r16, (1 << INT0)
    out EIMSK, r16

    ; Initialiser le flag d’état à OFF (0)
    ldi r20, 0

    ; Activer les interruptions globales
    sei

main:
    rjmp main

;------------------------------------------------------
; Routine d'interruption INT0
INT0_ISR:
    ; Sauvegarder registres utilisés
    push r16
    push r17
    push r18
    push r21

    ; toggle the port at which the led is connected to
    in r17, PORTD ; read value 
   	ldi r18, (1<<PORTD3)
    eor r17, r18 ; 
    out PORTD, r17

    ; Effacer l’écran
    ldi r16, 0b00000001
    rcall lcd_command

    ; Pause après effacement
    rcall delay

 

	ldi r21, (1<<PD3)
	in r18, PIND
	and r18, r21
	cpi r18, 0
	breq afficher_OFF

	; Afficher 'ON'
    ldi r16, 'L'
    rcall lcd_data
    ldi r16, 'E'
    rcall lcd_data
    ldi r16, 'D'
    rcall lcd_data
    ldi r16, 'O'
    rcall lcd_data
    ldi r16, 'N'
    rcall lcd_data

	rjmp fin_ISR

afficher_OFF:
    ; Afficher 'OFF'
    ldi r16, 'L'
    rcall lcd_data
    ldi r16, 'E'
    rcall lcd_data
    ldi r16, 'D'
    rcall lcd_data
    ldi r16, 'O'
    rcall lcd_data
    ldi r16, 'F'
    rcall lcd_data
	ldi r16, 'F'
    rcall lcd_data

    rjmp fin_ISR

fin_ISR:
    ; Restaurer registres
    pop r18
    pop r17
    pop r16
    pop r21

    reti ; The processor pops the return address and status register from the stack, 
    		;restoring the state before the interrupt occurred.
