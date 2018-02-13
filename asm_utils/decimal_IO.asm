.MODEL SMALL
.STACK
.DATA
; Strings
LF EQU 13					; Line feed
CR EQU 10					; Carriage Return
S_ENDLINE DB LF, CR, '$'	; Endline string
.CODE
.STARTUP
	MOV AX, 3
	PUSH AX
	CALL READ_DECIMAL
	POP AX
	
	PUSH AX
	CALL DISPLAY_DECIMAL
	POP AX
.EXIT

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
	
	POPA	
	POP BP
	RET
DISPLAY_DECIMAL ENDP

END