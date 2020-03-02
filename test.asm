//Test, osäker på om detta ens gör något

.dseg
POSX: .byte 1 ; Own position
POSY: .byte 1

.macro INCSRAM ; inc byte in SRAM
	lds r16,@0
	inc r16
	sts @0,r16
.endmacro

.macro DECSRAM ; dec byte in SRAM
	lds r16,@0
	dec r16
	sts @0,r16
.endmacro

;--------------------------------
;------------- KOD --------------
.cseg
START:
	ldi r16, HIGH(RAMEND)
	out SPH,r16
	ldi r16,LOW(RAMEND)
	out SPL,r16

JOYSTICK:
	push r16
	ldi r16,0
	out ADMUX,r16
	ldi r16,(1<<ADPS2)|(1<<ADPS1)|(1<<ADPS0)|(1<<ADEN)
	out ADCSRA,r16

CONVERT_1:
	sbi ADCSRA,ADSC

WAIT_1:
	sbic ADCSRA,ADSC
	jmp WAIT_1
	in r16,ADCL
	in r16,ADCH
	andi r16,$3
	cpi r16,$3
	brne X_CHECK
	INCSRAM POSX

X_CHECK:
	cpi r16,0
	brne JOYSTICK_Y
	DECSRAM POSX

JOYSTICK_Y:
	ldi r16,(1<<MUX0)
	out ADMUX,r16
	ldi r16,(1<<ADPS2)|(1<<ADPS1)|(1<<ADPS0)|(1<<ADEN)
	out ADCSRA,r16

CONVERT_2:
	sbi ADCSRA,ADSC

WAIT_2:
	sbic ADCSRA,ADSC
	jmp WAIT_2
	in r16,ADCL
	in r16,ADCH
	andi r16,$3
	cpi r16,$3
	brne Y_CHECK
	INCSRAM POSY

Y_CHECK:
	cpi r16,0
	brne Y_FIN
	DECSRAM POSY

Y_FIN:
	pop r16
	ret
