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

;------------------------------------------------------
; Sous-programme : Petite pause (~1ms)
delay:
    ldi r18, 255
delay_loop:
    dec r18
    brne delay_loop
    ret

;------------------------------------------------------
; Sous-programme : Longue pause (~50ms)
long_delay:
    ldi r19, 100
long_delay_loop:
    rcall delay
    dec r19
    brne long_delay_loop
    ret

;------------------------------------------------------
; Routine de démarrage
RESET:
    ; Configurer PORTB comme sortie (bus de données LCD)
    ldi r16, 0xFF
    out DDRB, r16

    ; Configurer PC5 (E), PC6 (RW), PC7 (RS) comme sorties
    ldi r16, 0b11100000
    out DDRC, r16

    ; Attendre la stabilisation du LCD (~50ms)
    rcall long_delay

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
    rcall long_delay

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
    ldi r20, 0x00

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

    ; Toggle PD3 (par exemple LED)
    sbi PIND, 3 ; Inverser l’état de PD3

    ; Effacer l’écran
    ldi r16, 0b00000001
    rcall lcd_command

    ; Pause après effacement
    rcall long_delay

    ; Vérifier l'état actuel et afficher ON ou OFF
    tst r20          ; Tester si r20 == 0 (OFF)
    breq afficher_ON ; Si OFF, passer à ON

afficher_OFF:
    ; Afficher 'OFF'
    ldi r16, 'O'
    rcall lcd_data
    ldi r16, 'F'
    rcall lcd_data
    ldi r16, 'F'
    rcall lcd_data

    ; Mettre le flag à 0
    ldi r20, 0x00
    rjmp fin_ISR

afficher_ON:
    ; Afficher 'ON'
    ldi r16, 'O'
    rcall lcd_data
    ldi r16, 'N'
    rcall lcd_data

    ; Mettre le flag à 1
    ldi r20, 0x01

fin_ISR:
    ; Restaurer registres
    pop r18
    pop r17
    pop r16

    reti
