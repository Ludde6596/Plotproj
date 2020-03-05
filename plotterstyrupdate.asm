;
; AssemblerApplication1.asm
;
; Created: 2020-03-02 05:27:58
; Author : Ludde
;


; Replace with your application code
SEKVENS:
 .db $01, $09, $08, $0A, $02, $06, $04, $05

COLD:
	ldi r16, HIGH(RAMEND)
	out SPH, r16
	ldi r16, LOW(RAMEND)
	out SPL, r16
	call HW_INIT

WARM:
	sbi PORTB,3		;Mastern kan skicka information
INPUT:
	sbis SPSR,SPIF
	rjmp INPUT
	in r16, SPDR
	cbi DDRB,3		;Mastern kan inte skicka information
	;Kontroll av indata för att veta hur plottern ska styras
	cpi r16,$01
	breq Y_UP
	cpi r16,$02
	breq Y_DOWN
	cpi r16,$04
	breq X_STEP
	cpi r16,$07
	breq X_BACK
	cpi r16,$05
	breq XY_UP
	cpi r16,$06
	breq XY_DOWN
	rjmp NO_MOV

Y_UP:
	call YUPSTEP
	rjmp NO_MOV
Y_DOWN:
	call YDOWNSTEP
	rjmp NO_MOV
X_STEP:
	call XSTEP
	rjmp NO_MOV
X_BACK:
	call XBACK
	rjmp NO_MOV
XY_UP:
	call YUPXSTEP
	rjmp NO_MOV
XY_DOWN:
	call YDOWNXSTEP
NO_MOV:
	rjmp WARM ;ENDOFMAIN

;UNDERPROGRAM
YDOWNXSTEP:
	push r16
	ldi r16,$14
YDOWNXSTEP1:
	call XRIGHT
	call YDOWN
	dec r16 
	brne YDOWNXSTEP1
	ret

YUPXSTEP:
	push r16
	ldi r16,$14
YUPXSTEP1:
	call XRIGHT
	call YUP
	dec r16 
	brne YUPXSTEP1
	ret

XSTEP:
	push r16
	ldi r16,$14
XSTEP1:
	call XRIGHT
	dec r16 
	brne XSTEP1
	ret

XBACK:
	push r16
	ldi r16,$14
XBACK1:
	call XLEFT
	dec r16 
	brne XBACK1
	ret

YUPSTEP:
	push r16
	ldi r16,$14
YUPSTEP1:
	call YUP
	dec r16 
	brne YUPSTEP1
	ret

YDOWNSTEP:
	push r16
	ldi r16,$14
YDOWNSTEP1:
	call YDOWN
	dec r16 
	brne YDOWNSTEP1
	ret

XRIGHT:
	push r16
	push r17
	push ZH
	push ZL
	ldi ZH,HIGH(SEKVENS*2)
	ldi ZL,LOW(SEKVENS*2)
	ldi r17, $00
XRIGHT2:
	lpm r16, Z+
	out PORTD, r16
	inc r17
	call DELAY
	cpi r17, $08
	brne XRIGHT2
	pop ZL
	pop ZH
	pop r17
	pop r16
	ret

XLEFT:
	push r16
	push r17
	push ZH
	push ZL
	ldi ZH,HIGH(SEKVENS*2)
	ldi ZL,LOW(SEKVENS*2)
	adiw Z,$07
	ldi r17, $00
XLEFT2:
	lpm r16, Z
	subi ZL,$01
	out PORTD, r16
	inc r17
	call DELAY
	cpi r17, $08
	brne XLEFT2
	pop ZL
	pop ZH
	pop r17
	pop r16
	ret

YUP:
	push r16
	push r17
	push ZH
	push ZL
	ldi ZH,HIGH(SEKVENS*2)
	ldi ZL,LOW(SEKVENS*2)
	ldi r17, $00
YUP2:
	lpm r16, Z+
	out PORTA, r16
	inc r17
	call DELAY
	cpi r17, $08
	brne YUP2
	pop ZL
	pop ZH
	pop r17
	pop r16
	ret

YDOWN:
	push r16
	push r17
	push ZH
	push ZL
	ldi ZH,HIGH(SEKVENS*2)
	ldi ZL,LOW(SEKVENS*2)
	adiw Z,$07
	ldi r17, $00
YDOWN2:
	lpm r16, Z
	subi ZL,$01
	out PORTA, r16
	inc r17
	call DELAY
	cpi r17, $08
	brne YDOWN2
	pop ZL
	pop ZH
	pop r17
	pop r16
	ret

DELAY: ;1ms delay
	push r16
	push r17
	ldi r16, 4
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

HW_INIT:
	push r16
	ldi r16,$FF
	out DDRA,r16
	out DDRD,r16
	ldi r16,$01
	out DDRB,r16

	sbi DDRB,3 ;controll bit för master
	sbi DDRB,6 ; slave setup
	ldi r16,(1<<SPE)
	out SPCR,r16
	ldi r16, $FF
	out SPDR, r16
	pop r16
	ret
