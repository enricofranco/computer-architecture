; Computer Architectures
; Lab 04 - Exercise 03
#start=8259.exe#
PORTA	EQU	80H
PORTB	EQU	PORTA+1
PORTC	EQU	PORTA+2
CONTROL	EQU	PORTA+3
PIC		EQU	40H

DIM		EQU	5
.MODEL small
.STACK
.DATA
	EOR			DB	?		; End of Read
	MSB_NUMBER	DB	?		; MSBYte of the number read
	EVENARRAY	DW	DIM	DUP	(?)
	ODDARRAY	DW	DIM	DUP	(?)
	EVENINDEX	DB	0
	ODDINDEX	DB	0
.CODE
.STARTUP
	CLI
	MOV EOR, 0
	CALL INIT_8255
	CALL INIT_8259
	CALL INIT_IVT
	STI
CYCLE:
	JMP CYCLE		
.EXIT

INIT_8255	PROC
	PUSH AX
	PUSH DX
	MOV DX, CONTROL                    
	MOV AL, 10110000B	;	Group A Mode 1 Intput
	OUT DX, AL
	MOV AL, 00001001B	;	Interrupt for group A
	OUT DX, AL
	POP DX
	POP AX
	RET
INIT_8255	ENDP

INIT_8259	PROC
	PUSH AX
	PUSH DX
	; ICW 1
	MOV DX, PIC
	MOV AL, 00010011B
	OUT DX, AL
	; ICW 2
	MOV DX, PIC+1
	MOV AL, 00100000B	;	ISR Address
	OUT DX, AL
	; ICW 4
	MOV AL, 00000011B
	OUT DX, AL
	; OCW 1
	MOV AL, 01111111B	;	CH7 Enabled (Port A)
	OUT DX, AL
	POP DX
	POP AX
	RET	
INIT_8259	ENDP

INIT_IVT	PROC
	PUSH AX
	PUSH BX
	PUSH DX
	PUSH DS
	
	XOR AX, AX
	MOV DS, AX
	MOV BX, 00100111B
	SHL BX, 1
	SHL BX, 1
	MOV AX, OFFSET ISR_PA_IN
	MOV DS:[BX], AX
	MOV AX, SEG ISR_PA_IN
	MOV DS:[BX+2], AX
	
	POP DS
	POP DX
	POP BX
	POP AX
	RET
INIT_IVT	ENDP

ISR_PA_IN	PROC
	PUSH AX
	PUSH BX
	PUSH DX
	MOV DX, PORTA
	IN AL, DX
	CMP EOR, 0
	JA TRANSFER_WORD	; EOR = 1 -> Save into the proper array
	MOV MSB_NUMBER, AL	; Save the less significant part
	INC EOR				; Next ISR will store the complete number
	JMP END_ISR			; End of the service routine
TRANSFER_WORD:
	XOR BH, BH
	MOV AH, MSB_NUMBER
	TEST AL, 1B			; Mask the LSB
	JZ EVEN_NUMBER		; LSB = 0 -> Even
	MOV BL, ODDINDEX
	CMP BL, DIM
	JB MOV_ODD			; BL < DIM -> Simply Transfer
	XOR BL, BL			; Reset BL (Circular buffer)
MOV_ODD:
	SHL BX, 1
	MOV ODDARRAY[BX], AX		
	INC ODDINDEX
	JMP EOT
EVEN_NUMBER:
	MOV BL, EVENINDEX
	CMP BL, DIM
	JB MOV_EVEN
	XOR BL, BL	
MOV_EVEN:
	SHL BX, 1
	MOV EVENARRAY[BX], AX
	INC EVENINDEX
EOT:					; End of transfer phase
	DEC EOR				; Next ISR will store the MSByte
END_ISR: 
	POP DX
	POP BX           
	POP AX
	IRET
ISR_PA_IN	ENDP