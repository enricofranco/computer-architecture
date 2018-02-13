; Procedure to display a decimal number up to 65'536 (16 bits)
; The value is read from the stack, 
; so it must be pushed before the procedure call
DISPLAY_DECIMAL PROC
	PUSH BP
	MOV BP, SP
	PUSHA
	MOV AX, [BP+4]
	MOV BX, 10				; Divisor
	XOR DX, DX
	XOR CX, CX
	
	;Splitting process starts here
DLOOP1:
	XOR DX, DX				; Clear DX
	DIV BX
	PUSH DX					; Push the digit
	INC CX					; Increments the number of digits
	CMP AX, 0				; Checks if there something else to divide
	JNE DLOOP1
	
DLOOP2:
	POP DX					; Pop the digit
	ADD DX, 30H				; ASCII conversion
	MOV AH, 02H				; Identification code     
	INT 21H
	LOOP DLOOP2
	
	LEA DX, S_ENDLINE
	MOV AH, 9
	INT 21H
	
	POP BP
	POPA	
	RET
DISPLAY_DECIMAL ENDP

