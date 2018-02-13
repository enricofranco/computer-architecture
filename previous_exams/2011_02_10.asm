.MODEL SMALL
.STACK
.DATA
; Constant
N	EQU	5
; Input data
;A	DW	0166h		; 546 (7)	-> 279
;B	DW	001Dh		; 035 (7)	-> 26
;A	DW	8166h		; -546 (7)	-> -279
;B	DW	801Dh		; -035 (7)	-> -26
A	DW	6ACAh		; 65312 (7)	-> 16277
B	DW	4D03h		; 46403 (7)	-> 11861
; Output data
RESULT	DW	?
; Variables
X	DB	N+1	DUP (?)
Y	DB	N+1	DUP (?)
Z	DB 	N+1 DUP (?)
.CODE
.STARTUP

MAIN:
	CALL UNPACK_NUMBERS
;	CALL ADD_POSITIVE
;	CALL ADD_NEGATIVE
;	CALL NEG_MINUS_POS
;	CALL POS_MINUS_NEG
	CALL POS_MINUS_POS
	CALL PACK_RESULT
ERROR:    
.EXIT

UNPACK_NUMBERS PROC
	PUSHA
	; Unpack operands
	MOV CX, N
	MOV SI, N
	MOV AX, A
	MOV BX, B
	UNPACK_LOOP:
		MOV X[SI], AL
		AND X[SI], 07h	; Save three LSBs
		MOV Y[SI], BL
		AND Y[SI], 07h	; Save three LSBs
		DEC SI			; Next digit
		; ROR AX, 3
		; Next 3 LSBs       	 
		ROR AX, 1
		ROR AX, 1
		ROR AX, 1 
		; ROR BX, 3
		; Next 3 LSBs       	 
		ROR BX, 1
		ROR BX, 1
		ROR BX, 1
	LOOP UNPACK_LOOP
	
	TEST A, 8000h		; Test sign
	JZ A_POS
	MOV X[0], 1			; Negative
	A_POS:
	TEST B, 8000h		; Test sign
	JZ B_POS
	MOV Y[0], 1			; Negative
	B_POS:
	
	POPA
	RET
UNPACK_NUMBERS ENDP

PACK_RESULT PROC
	PUSHA
	MOV CX, N
	XOR BX, BX
	MOV SI, 1
	PACK:
		; ROL BX, 3
		ROL BX, 3
		ADD BL, Z[SI]
		INC SI
	LOOP PACK
	MOV RESULT, BX
	POPA
	RET
PACK_RESULT ENDP

ADD_POSITIVE PROC
	PUSHA
	MOV CX, 5
	MOV SI, 5
	MOV BH, 7			; Base of the enumeration system
	MOV AH, 0			; Used to store carry
	SUM_POS:
		MOV AL, X[SI]
		ADD AL, Y[SI]
		ADD AL, AH		; Carry
		XOR AH, AH
		DIV BH
		XCHG AL, AH
		MOV Z[SI], AL
		DEC SI
	LOOP SUM_POS
	
	POPA
	RET	
ADD_POSITIVE ENDP

ADD_NEGATIVE PROC
	PUSHA
	MOV Z, 1			; Result will be negative
	CALL ADD_POSITIVE
	POPA
	RET
ADD_NEGATIVE ENDP

POS_MINUS_NEG PROC
	PUSHA
	MOV Z, 0			; Result will be positive
	CALL ADD_POSITIVE
	; Not considering the sign, it is like an addition between positive numbers
	POPA
	RET
POS_MINUS_NEG ENDP	

NEG_MINUS_POS PROC
	PUSHA
	MOV Z, 1			; Result will be negative
	CALL ADD_POSITIVE
	; Not considering the sign, it is like an addition between positive numbers
	POPA
	RET
NEG_MINUS_POS ENDP

POS_MINUS_POS PROC
	PUSHA
	MOV CX, N
	MOV SI, N
	SUB_LOOP:
		MOV AL, X[SI]
		SUB AL, Y[SI]
		CMP AL, 0
		JGE NO_BORROW
		; Borrow required
		MOV DI, SI
		SEARCH_GOOD_DIGIT:
			DEC DI
			CMP DI, 0
			JL ERROR 
			CMP X[DI], 1
			JAE FOUND_GOOD_DIGIT
			; Continue the search
		    JMP SEARCH_GOOD_DIGIT
		FOUND_GOOD_DIGIT:
		DEC X[DI]					; Borrow
		ADD AL, 7					; Borrow
		NO_BORROW:
		MOV Z[SI], AL
		DEC SI
	LOOP SUB_LOOP
	POPA
	RET
POS_MINUS_POS ENDP

END