;
; mapcreation.asm
;
; Created: 2020-03-02 02:22:47
; Author : Ludde
;


; Replace with your application code
  .equ MAPSIZE = 50
.equ STEPSIZE = 5
.equ ORIGO = 31		;63 riktiga värdet

.dseg
.org $0100
Y_VAL: .byte MAPSIZE
Y_CORD:	.byte 1
X_CORD:	.byte 1
POINTS: .byte 1

.cseg
.org 0
jmp COLD	
;.org OVF0addr interrupt address
;jmp GEN_SEED
COLD: 
	ldi r16,HIGH(RAMEND)
	out SPH,r16
	ldi r16,LOW(RAMEND)
	out SPL,r16
	call HW_INIT
WARM:
	sbis PINB,2
	rjmp WARM
	call MAP_CREATION
	call PEN_DOWN
	call PLOT_MAP
	call PEN_UP
	call RESET_MAP
FINISH:
	rjmp FINISH

MAP_CREATION:
	push r16
	push r17
	push r18
	push ZH
	push ZL
	push YH
	push YL
	
	ldi r16,MAPSIZE ;antal loops
	ldi ZH,HIGH(Y_VAL)
	ldi ZL,LOW(Y_VAL)
MAP_1:
	ldi r17,STEPSIZE
	ldi r18,ORIGO
	cpi r16,MAPSIZE
	breq MAP_2
RANDOM:
	in r18,TCNT0
	mov YL,r18
	ld r18,Y		;Tar utom "random" rader ur minnet
	andi r18,$3F	;and med $7F för att få bort msb 
	cpi r18,$3E		
	brpl R_ADJUST	;kontroll av rand för att den ej ska bli större än 126	
	rjmp MAP_2
R_ADJUST:
	subi r18,ORIGO
MAP_2:
	;set Y_CORD VALUES WITH RANDOM
	st Z+,r18
	dec r16
	dec r17
	brne MAP_2
	cpi r16,$00
	brne MAP_1
	
	pop YL
	pop YH
	pop ZL
	pop ZH
	pop r18
	pop r17
	pop r16
	ret

PLOT_MAP:
	push r16
	push r17
	push r18
	push r19
	push ZH
	push ZL

	ldi r16,ORIGO	;sätter ut y-origo
	ldi r18,$00		;sätter ut x-origo
	ldi ZH,HIGH(Y_VAL)
	ldi ZL,LOW(Y_VAL)
PLOT_LOOP:
	ld r17,Z+
	out PORTA,r17
	cp r17,r16			;Jämför Y_VAL med nuvarande y-koord
	breq X_ADJUST
	brpl YUP_ADJUST
YDOWN_ADJUST:
	;;Skicka till plotter
	ldi r19,$02
	push r19
	call SEND
	pop r19
	dec r16
	cp r17,r16
	brne YDOWN_ADJUST
	rjmp X_ADJUST
YUP_ADJUST:
	;;Skicka till plotter
	ldi r19,$01
	push r19
	call SEND
	pop r19
	inc r16
	cp r17,r16
	brne YUP_ADJUST
	rjmp X_ADJUST
X_ADJUST:
	;;Skicka till plotter
	ldi r19,$04
	push r19
	call SEND
	pop r19
	inc r18
	cpi r18,MAPSIZE
	brne PLOT_LOOP
	sts Y_CORD,r16
	sts X_CORD,r18
	pop ZL
	pop ZH
	pop r19
	pop r18
	pop r17 
	pop r16
	ret


RESET_MAP:
	push r17
	push r18
	push r19

	lds	r18, X_CORD		;LADDAR x-koordinat från sram
	lds r17, Y_CORD		;LADDAR y-koordinat från sram
X_RESET:
	;;Skicka till plotter
	ldi r19,$06
	push r19
	call SEND
	pop r19
	dec r18
	brne X_RESET
Y_RESET:
	cpi r17,ORIGO
	breq RESET_DONE
	brpl Y_RESET2
Y_RESET2:
	;;Skicka till plotter
	ldi r19,$01
	push r19
	call SEND
	pop r19
	inc r17
	cpi r17,ORIGO
	brmi Y_RESET2
	rjmp RESET_DONE
Y_RESET1:
	;;Skicka till plotter
	ldi r19,$02
	push r19
	call SEND
	pop r19
	dec r17
	cpi r17,ORIGO
	brpl Y_RESET1
RESET_DONE:

	pop r19
	pop r18
	pop r17
	ret

;;SEND underprogram finns i både plotterjoy och mapcreation
SEND:
	push ZH
	push ZL
	push r17
	in ZH,SPH
	in ZL,SPL
SEND1:
	sbis PINB,1
	rjmp SEND1
	;call DELAY
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

HW_INIT:

	ldi r16,$FF
	out DDRA,r16
	;Timer0--------------
	ldi r16,(1<<CS00) 
	out TCCR0,r16
	;ldi r16,(1<<TOIE0)|(1<<OCIE1A)
	;out TIMSK,r16
	;sei interrupt code
;SPI SETUP----------------
	sbi DDRB,4
	sbi DDRB,5
	sbi DDRB,7
	ldi r16, (1<<MSTR)|(1<<SPE)|(1<<SPR1)
	sbi PORTB,4
	out SPCR,r16
	
	ret
