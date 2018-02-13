.MODEL SMALL
.STACK
NUTR EQU 5
ACT EQU 5
REC EQU 4
.DATA
; Input data
NUTRITION DB 101, 20, 120, 33, 85
TASKS DB 31, 27, 100, 72, 61
BIAS_GENDER DB 175, 125
PERSON DW 0000000000000000b, 1000011000000011b, 1100010000000001b, 1000101100000010b

; Variables
CALORIES_SURVIVAL DW ?
CALORIES_EATEN DW ?
CALORIES_BURNT DW ?
CALORIES_EXCESS DW ?

NUTRITION_COPY DB NUTR DUP (?)
TASKS_COPY DB ACT DUP (?)

TASKS_EXCESS DW ACT DUP (?)
NUTRITIONS_DEFECT DW NUTR DUP (?)

; Jump tables
EXTRACTION_JT DW MALE_CASE, FEMALE_CASE, NUTRITION_CASE, TASK_CASE
.CODE
.STARTUP
MAIN:
	CALL READ_PERSON
	CALL CALC_DIFF_CALORIES   
.EXIT

READ_PERSON PROC
	PUSHA
	MOV CALORIES_EATEN, 0
	MOV CALORIES_BURNT, 0
	XOR SI, SI
	MOV CX, REC
	EXTRACTION:
		MOV BX, PERSON[SI]
		MOV AX, BX					; Copy record
		ROL BX, 2
		AND BX, 03h					; Save 'index'
		SHL BX, 1					; BX used to access the jump table
		JMP EXTRACTION_JT[BX]
		MALE_CASE:
			MOV AL, BIAS_GENDER[0]
			XOR AH, AH 
			SHL AX, 3
			MOV CALORIES_SURVIVAL, AX
			JMP NEXT_EXTRACTION	
		FEMALE_CASE:
			MOV AL, BIAS_GENDER[1]
			XOR AH, AH 
			SHL AX, 3
			MOV CALORIES_SURVIVAL, AX
			JMP NEXT_EXTRACTION
		NUTRITION_CASE:
			MOV DI, AX
			AND DI, 7Fh				; Index of array
			MOV AL, AH
			AND AL, 1Fh				; Quantity
			MUL NUTRITION[DI]
			ADD CALORIES_EATEN, AX
			JMP NEXT_EXTRACTION
		TASK_CASE:
			MOV DI, AX
			AND DI, 7Fh				; Index of array
			MOV AL, AH
			AND AL, 1Fh				; Quantity
			MUL TASKS[DI]
			ADD CALORIES_BURNT, AX

		NEXT_EXTRACTION:
		ADD SI, 2
	LOOP EXTRACTION	
	POPA
	RET
READ_PERSON ENDP

CALC_DIFF_CALORIES PROC
	PUSHA
	MOV AX, CALORIES_EATEN
	SUB AX, CALORIES_SURVIVAL
	SUB AX, CALORIES_BURNT
	MOV CALORIES_EXCESS, AX
	POPA
	RET
CALC_DIFF_CALORIES ENDP

; Desc order
SORT_ARRAY PROC
	PUSH BP
	MOV BP, SP	
	PUSHA
	SORT_OUTER_LOOP:				; Outer loop
		MOV DL, 1					; DL is a flag, which tells us if at least one swap has
									; been performed in the inner loop
		
		MOV DI, [BP+4]				; DI is initialized to the first item
		MOV CX, [BP+6]				; CX is initialized with the length of the array
		DEC CX						; Last element has not to be checked
		SORT_INNER_LOOP:			; Inner loop
		MOV AL, [DI]                ; Transfer memory data into registers
        
        ; Make comparisons
        CMP [DI+1], AL
		JBE SORT_CONTINUE			; [DI] <= [DI+1], no swap required
		SWAP_ITEMS:
		XCHG [DI+1], AL
		MOV [DI], AL				; Athlete swap
		XOR DL, DL					; DL=0: one swap has been performed
		SORT_CONTINUE:
		INC DI						; Go to the next element of the array
		LOOP SORT_INNER_LOOP
		CMP DL, 0					; If (DL=0) then at least one swap has been performed
		JE SORT_OUTER_LOOP			; therefore continue with the outer loop
		; else no swaps performed ­> all the items are in order ­> the sorting ends.
	POPA
	POP BP
	RET	
SORT_ARRAY ENDP

END