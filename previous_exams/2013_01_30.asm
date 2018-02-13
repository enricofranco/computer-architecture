.MODEL SMALL
.STACK
.DATA
N EQU 4
;CLEAR DB N DUP (?)	; is the array of the N characters (N from 5 to 140) to be encrypted in its full length
CLEAR DB 'ABCD'
LAMBDA DB 20		; is the seed, with 0 <= LAMBDA < 30 received in input by the program
ENC_E DB N DUP (?)	; is the array of the encrypted text, according to ALGO_E
ENC_D DB N DUP (?)	; is the array of the encrypted text, according to ALGO_D
DEC_E DB N DUP (?)	; is the array of the decrypted text, according to ALGO_E and array ENC_E
DEC_D DB N DUP (?)	; is the array of the decrypted text, according to ALGO_D and array ENC_D
I DB ?				; position of a character either in the encrypted or decrypted array
DX_I DB ?			; decrypted character in position I
.CODE
.STARTUP
MAIN:
	CALL ENC_E_WHOLE_STRING
;	CALL DEC_E_WHOLE_STRING
	CALL ENC_D_WHOLE_STRING
	CALL DEC_D_WHOLE_STRING
	MOV I, 4
;	CALL DEC_E_IDX
	
.EXIT

ENC_E_WHOLE_STRING PROC
	PUSHA
	XOR SI, SI
	MOV CX, N-1
	MOV AL, CLEAR[0]
	ADD AL, LAMBDA
;	AND AL, 7Fh					; Module of division by 128
	PUSH AX
	CALL CALC_MODULE61
	POP AX
	MOV ENC_E[SI], AL
	ALGO_E_ENC1:
		INC SI	
		MOV AL, CLEAR[SI]
		ADD AL, ENC_E[SI-1]
;		AND AL, 7Fh
		PUSH AX
		CALL CALC_MODULE61
		POP AX
		MOV ENC_E[SI], AL		
		LOOP ALGO_E_ENC1
	POPA
	RET
ENC_E_WHOLE_STRING ENDP

DEC_E_WHOLE_STRING PROC
	PUSHA
	XOR SI, SI
	MOV CX, N-1
	MOV AL, ENC_E[0]
	SUB AL, LAMBDA
	AND AL, 7Fh					; Module of division by 128
	MOV DEC_E[SI], AL
	ALGO_E_DEC1:
		INC SI	
		MOV AL, ENC_E[SI]
		SUB AL, ENC_E[SI-1]
		AND AL, 7Fh
		MOV DEC_E[SI], AL		
		LOOP ALGO_E_DEC1
	POPA
	RET
DEC_E_WHOLE_STRING ENDP

ENC_D_WHOLE_STRING PROC
	PUSHA
	XOR SI, SI
	MOV CX, N
	ENCD_WHOLE_STRING_OUTER:
		MOV AL, CLEAR[SI]
		ADD AL, LAMBDA
;		AND AL, 7Fh				; Module of division by 128
		PUSH AX
		CALL CALC_MODULE61
		POP AX
		; Sum previous element
		CMP SI, 0				; Check if first element
		JE NEXT_CHAR_ENCD
		PUSH CX
		XOR DI, DI
		MOV CX, SI
		ENCD_WHOLE_STRING_INNER:
			ADD AL, ENC_D[DI]
;			AND AL, 7Fh
			PUSH AX
			CALL CALC_MODULE61
			POP AX
			INC DI
			LOOP ENCD_WHOLE_STRING_INNER
		POP CX
		NEXT_CHAR_ENCD:
		MOV ENC_D[SI], AL
		INC SI		
		LOOP ENCD_WHOLE_STRING_OUTER
	POPA
	RET
ENC_D_WHOLE_STRING ENDP

DEC_D_WHOLE_STRING PROC
	PUSHA
	XOR SI, SI
	MOV CX, N
	DECD_WHOLE_STRING_OUTER:
		MOV AL, ENC_D[SI]
		SUB AL, LAMBDA
;		AND AL, 7Fh				; Module of division by 128
		PUSH AX
		CALL CALC_MODULE61
		POP AX
		; Sub previous element
		CMP SI, 0				; Check if first element
		JE NEXT_CHAR_DECD
		PUSH CX
		XOR DI, DI
		MOV CX, SI
		DECD_WHOLE_STRING_INNER:
			SUB AL, ENC_D[DI]
;			AND AL, 7Fh
			PUSH AX
			CALL CALC_MODULE61
			POP AX			
			INC DI
			LOOP DECD_WHOLE_STRING_INNER
		POP CX
		NEXT_CHAR_DECD:
		ADD AL, 61
		MOV DEC_D[SI], AL
		INC SI		
		LOOP DECD_WHOLE_STRING_OUTER
	POPA
	RET
DEC_D_WHOLE_STRING ENDP

DEC_E_IDX PROC
	PUSHA
	; First char
	XOR SI, SI
	XOR CH, CH
	MOV CL, I
	DEC CX
	MOV AL, ENC_E[0]
	SUB AL, LAMBDA
	AND AL, 7Fh					; Module of division by 128
	DEC_E_IDX_LOOP:
		MOV BL, ENC_E[SI]		; Previous char
		INC SI	
		MOV AL, ENC_E[SI]
		SUB AL, BL
		AND AL, 7Fh
		LOOP DEC_E_IDX_LOOP
	MOV DX_I, AL
	POPA
	RET
DEC_E_IDX ENDP

CALC_MODULE61 PROC
	PUSH BP
	MOV BP, SP
	PUSHA
	MOV AX, [BP+4]
	TEST AL, 80h				; Test MSB
	JZ POSITIVE_NUMBER
	ADD AL, 61
	POSITIVE_NUMBER:
	CMP AL, 61
	JB END_MODULE61
	MODULE61_LOOP:
		SUB AL, 61
		CMP AL, 61
		JAE MODULE61_LOOP	
	END_MODULE61:
	MOV [BP+4], AX
	POPA
	POP BP
	RET
CALC_MODULE61 ENDP

END