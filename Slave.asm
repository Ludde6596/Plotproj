
COLD:
	ldi r16,HIGH(RAMEND)
	out SPH,r16
	ldi r16,LOW(RAMEND)
	out SPL,r16
	call HW_INIT

RECEIVE:
	sbi PORTB,1
	sbis SPSR,SPIF
	rjmp RECEIVE
	in r16,SPDR
	cbi PORTB,1
	out PORTA,r16
	call DELAY
	rjmp RECEIVE

HW_INIT:
	ldi r16,$FF
	out DDRA,r16
	sbi DDRB,1
	sbi DDRB,6
	ldi r16,(1<<SPE)||(1<< SPR1)
	out SPCR,r16
	ldi r16,$07
	out SPDR,r16
	ret

DELAY:
	;1ms delay
	push r16
	push r17
	ldi r16, $0F
DELAY1:
	ldi r17, $FF
DELAY2:
	dec r17
	brne DELAY2
	dec r16
	brne DELAY1
	pop r17
	pop r16
	ret