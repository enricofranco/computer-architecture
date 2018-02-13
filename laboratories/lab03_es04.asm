; Computer Architectures
; Lab 03 - Exercise 04
#start=8255.exe#
PORTA	EQU	80H
PORTB	EQU	PORTA+1
PORTC	EQU	PORTA+2
CONTROL	EQU	PORTA+3

.MODEL small
.STACK
.DATA
	RES	DB	?
.CODE
.STARTUP
	CALL INIT_8255
	CALL READ_8255
	CALL WRITE_8255
.EXIT

INIT_8255	PROC
	PUSH AX
	PUSH DX
	
	MOV DX, CONTROL
	MOV AL, 10010010B	; MODE 0 A IN, MODE 0 B IN, C OUT
	OUT DX, AL	
	
	POP DX
	POP AX
	RET
INIT_8255	ENDP

READ_8255	PROC
	PUSH AX
	PUSH DX
	
	MOV DX, PORTA
	IN AL, DX
	MOV AH, AL	; Store the first operand
	MOV DX, PORTB
	IN AL, DX
	XOR AH, AL
	NOT AH
	MOV RES, AH		
	
	POP DX
	POP AX
	RET
READ_8255	ENDP

WRITE_8255	PROC
	PUSH AX
	PUSH BX
	PUSH CX
	PUSH DX

	MOV DX, CONTROL	
	MOV CL, 0	; Position of the single bit	
	MOV BL, 1	; Mask LSB
	MOV CH, RES	; Transfer operand on chip to speed up
	XOR AL, AL
cycle:
	MOV AL, CL	; Transfer the position
	SHL AL, 1	; Position is from D3 to D1
	MOV AH, CH	; AH is uesed to find the bit, according to the mask
	AND AH, BL	; Find the bit, according to the mask
	SHR AH, CL	; Transfer the bit in the LSB position
	OR AL, AH	; "Add" the LSB to the output value
	OUT DX, AL 
	SHL BL, 1	; Mask next bit
	INC CL
	CMP CL, 8
	JB cycle	; Repeat for 8 bits	
	
	POP DX
	POP CX
	POP BX
	POP AX
	RET
WRITE_8255	ENDP

END