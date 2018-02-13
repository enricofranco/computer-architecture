; Computer Architectures
; Lab 03 - Exercise 03
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
 	
 	MOV DX, PORTC
check_LSB_portC:
	IN AL, DX
	; MOV AH, AL
	AND AL, 01H	; Check LSB
	CMP AL, 1	
	JE check_LSB_portC	; No transaction
	IN AL, DX
	AND AL, 01H	; Check LSB
	CMP AL, 0	; No transaction
	JE check_LSB_portC
	; Transaction detected		 
	CALL PRINT_8255
	JMP check_LSB_portC	
.EXIT

INIT_8255	PROC
	PUSH AX
	PUSH DX
	MOV DX, CONTROL
	MOV AL, 10011001B	; Mode 0 A IN, MODE 0 B OUT, C IN
	OUT DX, AL
	POP DX
	POP AX
	RET
INIT_8255	ENDP

PRINT_8255	PROC
	PUSH AX
	PUSH DX
	MOV DX, PORTA
	IN AL, DX
	CMP AL, 'a'
	JB no_lowercase
	CMP AL, 'z'
	JA no_lowercase
	ADD AL, 'A'-'a'	; Conversion to uppercase char
	MOV DX, PORTB
	OUT DX, AL	
no_lowercase:	 	
	POP DX
	POP AX
	RET
PRINT_8255	ENDP

END