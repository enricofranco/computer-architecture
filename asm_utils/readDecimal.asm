; Procedure to read a decimal number up to 65'536 (16 bits)
; Number of digits is read from the stack, 
; so it must be pushed before the procedure call
; Procedure will provide the decimal number stored in the stack
; so it must be popped after the procedure call
READ_DECIMAL PROC
	PUSH BP
	MOV BP, SP
	PUSHA
	MOV CX, [BP+4]			; Max number of digits to be read
	MOV DX, 0
READ_LOOP:
	MOV AH, 1
	INT 21H
	CMP AL, 13				; 13 = End Line
	JE END_READ_LOOP		; If 'Enter' is pressed, end reading

	SUB AL, '0'
	MOV CH, AL

	MOV AX, DX
	MOV DX, 10
	MUL DX
	MOV DX, AX

	ADD DL, CH
	ADC DH, 0

	XOR CH, CH
	LOOP READ_LOOP

END_READ_LOOP:    
	MOV [BP+4], DX
	POPA
	POP BP
	RET
READ_DECIMAL ENDP