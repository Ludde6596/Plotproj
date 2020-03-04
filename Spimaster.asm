/*
 * Spimaster.asm
 *
 *  Created: 2020-03-03 15:34:54
 *   Author: robjo672
 */ 
COLD:
	ldi r16,HIGH(RAMEND)
	out SPH,r16
	ldi r16,LOW(RAMEND)
	out SPL,r16
	call HW_INIT
SEND:
	sbis PINB,1
	rjmp SEND
	;sbi PORTB,0
	ldi r16,$07
	out SPDR,r16
WAIT:
	sbis SPSR,SPIF
	rjmp WAIT
	in r16,SPDR
	cbi PORTB,5
DONE:
	rjmp SEND

HW_INIT:
	sbi DDRB,0
	sbi DDRB,4
	sbi DDRB,5
	sbi DDRB,7
	cbi PORTB,4
	ldi r16, (1<<MSTR)|(1<<SPE)|(1<<SPR1)
	out SPCR,r16
	ret


