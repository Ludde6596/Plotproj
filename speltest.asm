/*
 * speltest.asm
 *
 *  Created: 2019-12-15 14:33:33
 *   Author: ludbe973
 */ 
 ; --- lab4spel.asm

	.equ VMEM_SZ     = 5 ; #rows on display
	.equ AD_CHAN_X   = 0 ; ADC0=PA0, PORTA bit 0 X-led
	.equ AD_CHAN_Y   = 1 ; ADC1=PA1, PORTA bit 1 Y-led
	.equ GAME_SPEED  = 150 ; inter-run delay (millisecs)
	.equ PRESCALE    = 7 ; AD-prescaler value
	.equ BEEP_PITCH  = 8 ; Victory beep pitch
	.equ BEEP_LENGTH = 100 ; Victory beep length

; ---------------------------------------
; --- Memory layout in SRAM
.dseg
.org SRAM_START
POSX: .byte 1 ; Own position
POSY: .byte 1
TPOSX: .byte 1 ; Target position
TPOSY: .byte 1
LINE: .byte 1 ; Current line
VMEM: .byte VMEM_SZ ; Video MEMory
SEED: .byte 1 ; Seed for Random

; ---------------------------------------
; --- Macros for inc/dec-rementing
; --- a byte in SRAM
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

; ---------------------------------------
; --- Code
.cseg
.org $0
jmp START
.org INT0addr
jmp MUX


START:
	ldi r16, HIGH(RAMEND)
	out SPH,r16
	ldi r16,LOW(RAMEND)
	out SPL,r16
	call HW_INIT
	call WARM
RUN:
	call JOYSTICK
	call ERASE_VMEM
	call UPDATE
	call GAME_DELAY

;*** Avgör om träff ***
	lds r17,POSX
	lds r16,TPOSX
	cp r17,r16
	brne NO_HIT

	lds r17,POSY
	lds r16,TPOSY
	cp r17,r16
	brne NO_HIT

	ldi r16,BEEP_LENGTH
	call BEEP
	call WARM
NO_HIT:
	jmp RUN

; ---------------------------------------
; --- Multiplex display
MUX:
	push r20
	in r20,SREG
	push r20
	push r16
	push XH
	push XL

	INCSRAM SEED ;plussar på seed
	lds r16,LINE
	ldi XH,HIGH(VMEM)
	ldi XL,LOW(VMEM)
	add XL,r16
	ld r20,X
	swap r16
	out PORTA,r16
	out PORTB,r20
	swap r16
	inc r16
	cpi r16,5
	brne MUX_2
	clr r16
MUX_2:
	sts LINE,r16

	pop XL
	pop XH
	pop r16
	pop r20
	out SREG,r20
	pop r20
	reti

; ---------------------------------------
; --- JOYSTICK Sense stick and update POSX, POSY
; --- Uses r16
JOYSTICK:
	push r16
	ldi r16,AD_CHAN_X
	out ADMUX,r16
	ldi r16,PRESCALE|(1<<ADEN)
	out ADCSRA,r16
CONVERT_1:
	sbi ADCSRA,ADSC
WAIT_1:
	sbic ADCSRA,ADSC
	jmp WAIT_1
	in r16,ADCH
	andi r16,$3

	cpi r16,$3
	brne X_CHECK
	INCSRAM POSX
X_CHECK:
	cpi r16,$0
	brne JOYSTICK_Y
	DECSRAM POSX

JOYSTICK_Y:
	ldi r16,AD_CHAN_Y
	out ADMUX,r16
	ldi r16,PRESCALE|(1<<ADEN)
	out ADCSRA,r16
CONVERT_2:
	sbi ADCSRA,ADSC
WAIT_2:
	sbic ADCSRA,ADSC
	jmp WAIT_2
	in r16,ADCH
	andi r16,$3
	
	cpi r16,$3
	brne Y_CHECK
	INCSRAM POSY
Y_CHECK:
	cpi r16,$0
	brne JOY_LIM
	DECSRAM POSY
JOY_LIM:
	call LIMITS ; don't fall off world!
	pop r16
	ret

; ---------------------------------------
; --- LIMITS Limit POSX,POSY coordinates
; --- Uses r16,r17
LIMITS:
	lds r16,POSX ; variable
	ldi r17,7 ; upper limit+1
	call POS_LIM ; actual work
	sts POSX,r16
	lds r16,POSY ; variable
	ldi r17,5 ; upper limit+1
	call POS_LIM ; actual work
	sts POSY,r16
	ret

POS_LIM:
	ori r16,0 ; negative?
	brmi POS_LESS ; POSX neg => add 1
	cp r16,r17 ; past edge
	brne POS_OK
	subi r16,2
POS_LESS:
	inc r16
POS_OK:
	ret

; ---------------------------------------
; --- UPDATE VMEM
; --- with POSX/Y, TPOSX/Y
; --- Uses r16, r17
UPDATE:
	clr ZH
	ldi ZL,LOW(POSX)
	call SETPOS
	clr ZH
	;kod för att målet ska blinka
	lds r16,SEED
	andi r16,$01
	cpi r16,1
	breq BLINK
	;BLINKKOD
	ldi ZL,LOW(TPOSX)
	call SETPOS
BLINK:
	ret

; --- SETPOS Set bit pattern of r16 into *Z
; --- Uses r16, r17
; --- 1st call Z points to POSX at entry and POSY at exit
; --- 2nd call Z points to TPOSX at entry and TPOSY at exit
SETPOS:
	ld r17,Z+   ; r17=POSX
	call SETBIT ; r16=bitpattern for VMEM+POSY
	ld r17,Z ; r17=POSY Z to POSY
	ldi ZL,LOW(VMEM)
	add ZL,r17 ; *(VMEM+T/POSY) ZL=VMEM+0..4
	ld r17,Z ; current line in VMEM
	or r17,r16 ; OR on place
	st Z,r17 ; put back into VMEM
	ret

; --- SETBIT Set bit r17 on r16
; --- Uses r16, r17
SETBIT:
	ldi r16,$01 ; bit to shift
SETBIT_LOOP:
	dec r17
	brmi SETBIT_END ; til done
	lsl r16 ; shift
	jmp SETBIT_LOOP
SETBIT_END:
	ret

HW_INIT:
	ldi r16,$F0
	out DDRA,r16
	ldi r16,$FF
	out DDRB,r16

	ldi r16,0
	out PORTA,r16
	out PORTB,r16

	;avbrott
	ldi r16,(1<<ISC01)|(1<<ISC00)|(1<<ISC11)|(1<<ISC10)
	out MCUCR,r16
	ldi r16,(1<<INT0)|(1<<INT1)
	out GICR,r16
	sei ; display on

	ldi r16,0  ;nollställer line
	ldi XH,HIGH(LINE)
	ldi XL,LOW(LINE)
	st X,r16
	ret

WARM:
	push r17
	ldi r17,0
	sts POSX,r17
	ldi r17,2
	sts POSY,r17

	push r0
	push r0
	call RANDOM ; RANDOM returns x,y on stack
	pop r17
	sts TPOSY,r17
	pop r17
	sts TPOSX,r17
	call ERASE_VMEM
	pop r17
	ret

RANDOM:
	push r16
	push ZH
	push ZL
	in r16,SPH
	mov ZH,r16
	in r16,SPL
	mov ZL,r16

	lds r16,SEED
	andi r16,$7
	cpi r16,4
	brpl Y_ADJUST
	std Z+6,r16
	jmp X_RAND
Y_ADJUST:
	subi r16,3
	std Z+6,r16
X_RAND:
	lds r16,SEED
	swap r16
	andi r16,$7
	cpi r16,6
	brpl X_ADJUST
	cpi r16,2
	brmi X_ADJUST2
	std Z+7,r16
	jmp READY
X_ADJUST:
	subi r16,1
	std Z+7,r16
	jmp READY
X_ADJUST2:
	subi r16,-2
	std Z+7,r16
	jmp READY
READY:
	pop ZL
	pop ZH
	pop r16
	ret

ERASE_VMEM:
	push ZH
	push ZL
	push r16
	ldi ZH,HIGH(VMEM)
	ldi ZL,LOW(VMEM)
	ldi r16,0
	st Z+,r16
	st Z+,r16
	st Z+,r16
	st Z+,r16
	st Z+,r16
	pop r16
	pop ZL
	pop ZH
	ret

BEEP:
	push r17
	ldi r17, BEEP_LENGTH
	call BEEP_1
	cbi PORTA,7
	call GAME_DELAY
	ldi r17, BEEP_LENGTH
	call BEEP_1
	cbi PORTA,7
	call GAME_DELAY
	ldi r17,BEEP_LENGTH*2
	call BEEP_1
	pop r17
	ret

BEEP_1:
	sbi PORTA,7
	rcall BEEP_DELAY
	cbi PORTA,7
	rcall BEEP_DELAY
	dec r17
	brne BEEP_1
	ret

BEEP_DELAY:
	push r18
	push r19
	ldi r18,BEEP_PITCH
delayYttreLoop:
	ldi r19,$1F
delayInreLoop:
	dec r19
	brne delayInreLoop
	dec r18
	brne delayYttreLoop
	pop r19
	pop r18
    ret

GAME_DELAY:
	push r16
	ldi r16,GAME_SPEED
MAIN_DELAY_LOOP:
	call MSDELAY
	dec r16
	brne MAIN_DELAY_LOOP
	pop r16
	ret

MSDELAY:
	push r18
	push r19
	ldi r18,10
gdelayYttreLoop:
	ldi r19,$1F
gdelayInreLoop:
	dec r19
	brne gdelayInreLoop
	dec r18
	brne gdelayYttreLoop
	pop r19
	pop r18
	ret

