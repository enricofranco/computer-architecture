; Computer Architectures
; Lab 03 - Exercise 02
#start=8255.exe#
PORTA	EQU	80H
PORTB	EQU	PORTA+1
PORTC	EQU	PORTA+2
CONTROL	EQU	PORTA+3

.MODEL small
.STACK
.DATA
	READING	DB	?	
.CODE
.STARTUP
	CALL INIT_8255
	CALL PRINT_8255
.EXIT

INIT_8255	PROC
	PUSH AX
	PUSH DX
	MOV DX, CONTROL
	MOV AL, 10001001B	; Mode 0, A OUT, B OUT, C IN (C don't care)
	OUT DX, AL
	POP DX
	POP AX
	RET
INIT_8255	ENDP

PRINT_8255	PROC
	PUSH AX
	PUSH CX
	PUSH DX
	MOV CX, 0FFH	; Starting from 255
cycle:		
	MOV DX, PORTA
	MOV AL, CL
	OUT DX, AL
	
	DEC CL
	MOV DX, PORTB
	MOV AL, CL
	OUT DX, AL
	DEC CL	
	
	CMP CL, 0FFH	; During the last cycle CL becomes 255
	JB cycle		; Cycle until CL < 255
	
	POP DX
	POP CX
	POP AX
	RET
PRINT_8255	ENDP

END