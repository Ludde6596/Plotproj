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
	call PEN_DOWN
SPELAR_LOOP:
	call JOYSTICK
	rjmp SPELAR_LOOP

JOYSTICK:
	push r16
	push r17
	
	ldi r16,0
	out ADMUX,r16
	ldi r16,(1<<ADPS2)|(1<<ADPS1)|(1<<ADPS0)|(1<<ADEN)
	out ADCSRA,r16
CONVERT_1:
	sbi ADCSRA,ADSC
WAIT_1:
	sbic ADCSRA,ADSC
	rjmp WAIT_1
	in r16,ADCH
	cpi r16,$03
	brne X_CHECK
	INCSRAM POSX
	;;Skicka till plotter
	ldi r17,$04
	push r17
	call SEND
	pop r17
	rjmp JOYSTICK_Y
X_CHECK:
	cpi r16,$00
	brne JOYSTICK_Y
	DECSRAM POSX
	;;Skicka till plotter
	ldi r17,$06
	push r17
	call SEND
	pop r17
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
	in r16,ADCH
	cpi r16,$03
	brne Y_CHECK
	INCSRAM POSY
	;;Skicka till plotter
	ldi r17,$01
	push r17
	call SEND
	pop r17
	rjmp Y_FIN
Y_CHECK:
	cpi r16,$00
	brne Y_FIN
	DECSRAM POSY
	;;Skicka till plotter
	ldi r17,$02
	push r17
	call SEND
	pop r17
Y_FIN:
	
	pop r17
	pop r16
	ret

SEND:
	push ZH
	push ZL
	push r17
	in ZH,SPH
	in ZL,SPL
SEND1:
	sbis PINB,1
	rjmp SEND1
	cbi PORTB,4		;Aktiverar slavens spi
	ldd r17,Z+6
	out SPDR,r17
WAIT:
	sbis SPSR,SPIF
	rjmp WAIT
	in r17,SPDR
	sbi PORTB,4

	pop r17
	pop ZL
	pop ZH
	ret

PEN_DOWN:
	push r19
	
	;;Skicka till plotter
	ldi r19,$03
	push r19
	call SEND
	pop r19

	pop r19
	ret

PEN_UP:
	push r19
	
	;;Skicka till plotter
	ldi r19,$05
	push r19
	call SEND
	pop r19

	pop r19
	ret

PLAYER_DELAY: ;250ms delay på 8MHz
	push r16
	push r17
	ldi r16, $04
PLAYER_DELAY1:
	ldi r17, $FA
PLAYER_DELAY2:
	dec r17
	brne PLAYER_DELAY2
	dec r16
	brne PLAYER_DELAY1
	pop r17
	pop r16
	ret

DELAY: ;1ms delay på 8MHz
	push r16
	push r17
	ldi r16, $A0
DELAY1:
	ldi r17, $FA
DELAY2:
	dec r17
	brne DELAY2
	dec r16
	brne DELAY1
	pop r17
	pop r16
	ret


HW_INIT:
	ldi r16,$F0
	out DDRA,r16
	sbi DDRB,4
	sbi DDRB,5
	sbi DDRB,7
	sbi PORTB,4
	ldi r16, (1<<MSTR)|(1<<SPE)|(1<<SPR1)
	out SPCR,r16
	ret
