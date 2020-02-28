/*
 * AssemblerApplication5.asm
 *
 *  Created: 2020-02-28 11:43:04
 *   Author: ludbe973
 */ 

COLD:
	ldi r16,HIGH(RAMEND)
	out SPH,r16
	ldi r16,LOW(RAMEND)
	out SPL,r16
	ldi r17,$00
	ldi r18,$00
	call HW_INIT
 
WARM:
	call JOYSTICK
	rjmp WARM

JOYSTICK:
	push r16
	ldi r16,(1<<MUX0)|(1<<MUX3)
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
	inc r17
	sbi PORTA,7
X_CHECK:
	cpi r16,0
	brne JOYSTICK_Y
	sbi PORTA,6
	dec r17

JOYSTICK_Y:
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
	inc r18
	sbi PORTA,5
Y_CHECK:
	cpi r16,0
	brne Y_FIN
	dec r18
	sbi PORTA,4
Y_FIN:
	pop r16
	ret

HW_INIT:
	ldi r16,$F0
	out DDRA,r16
	ret