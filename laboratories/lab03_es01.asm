; Computer Architectures
; Lab 03 - Exercise 01
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
	CALL ACQUIRE_8255
.EXIT

INIT_8255	PROC
	PUSH AX
	PUSH DX
	MOV DX, CONTROL
	MOV AL, 10001001B	; Mode 0, A OUT, B OUT, C IN
	OUT DX, AL
	POP DX
	POP AX
	RET
INIT_8255	ENDP

PRINT_8255	PROC
	PUSH AX
	PUSH DX
	MOV DX, PORTA
	MOV AL, 'O'
	OUT DX, AL
	MOV DX, PORTB
	MOV AL, 'K'
	OUT DX, AL	
	POP DX
	POP AX
	RET
PRINT_8255	ENDP

ACQUIRE_8255	PROC
	PUSH AX
	PUSH DX
	MOV DX, PORTC
	IN AL, DX
	MOV READING, AL	
	POP DX
	POP AX	
	RET
ACQUIRE_8255	ENDP

END