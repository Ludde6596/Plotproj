/*
 * PlotterJoystick.asm
 *
 *  Created: 2020-03-05 11:15:13
 *   Author: ludbe973
 */ 
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
	call HW_INIT

WARM:
	call JOYSTICK
	rjmp WARM

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
	rjmp WAIT_1
	in r16,ADCL
	in r16,ADCH
	andi r16,$3
	cpi r16,$3
	brne X_CHECK
	INCSRAM POSX
	;;Skicka till plotter
	ldi r17,$04
	push r17
	call SEND
	pop r17
X_CHECK:
	cpi r16,0
	brne JOYSTICK_Y
	;DECSRAM POSX
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
	;;Skicka till plotter
	ldi r17,$01
	push r17
	call SEND
	pop r17
Y_CHECK:
	cpi r16,0
	brne Y_FIN
	DECSRAM POSY
	;;Skicka till plotter
	ldi r17,$02
	push r17
	call SEND
	pop r17
Y_FIN:
	pop r16
	ret

SEND:
	push ZH
	push ZL
	push r17
	in ZH,SPH
	in ZL,SPL
SEND1:
	sbis PINB,3
	rjmp SEND1
	ldd r17,Z+6
	out SPDR,r17
WAIT:
	sbis SPSR,SPIF
	rjmp WAIT
	in r17,SPDR

	pop r17
	pop ZL
	pop ZH
	ret

HW_INIT:
	ldi r16,$F0
	out DDRA,r16
	sbi DDRB,4
	sbi DDRB,5
	sbi DDRB,7
	cbi PORTB,4
	ldi r16, (1<<MSTR)|(1<<SPE)|(1<<SPR1)
	out SPCR,r16
	ret
