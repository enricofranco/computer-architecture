.MODEL SMALL
.STACK
.DATA
N EQU 13	
IMAGE DB N DUP (01H, 01H, 01H, 02H, 03H, 01H, 03H, 03H, 03H, 03H, 03H, 03H, 02H)
COMPRESSED DB 2*N DUP (?)
.CODE
.STARTUP

RULE1 PROC
	PUSHA
	XOR SI, SI
	XOR DI, DI
 	XOR AH, AH		; Counter
CYCLE:
	MOV AL, IMAGE[SI]
	XOR AH, AH
	INC SI
	CYCLE_IN:
		CMP AL, IMAGE[SI]
		JE NEXT_ELEMENT
		; Store the result
		MOV COMPRESSED[DI], AH		; Counter
		MOV COMPRESSED[DI+1], AL	; Element
		INC DI
		INC DI
		MOV AH, -1
		MOV AL, IMAGE[SI]
		NEXT_ELEMENT:
		INC AH
		INC SI
	CMP SI, N
	JBE CYCLE_IN
	
	MOV AX, N
	SUB AX, DI
	MOV BX, 100
	MUL BX
	MOV BX, N
	DIV BX
	
	
	POPA
	RET
RULE1 ENDP

	
.EXIT
END