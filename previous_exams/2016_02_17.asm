.MODEL SMALL
.STACK
.DATA
BASE_SCORE EQU 6
DECKS DB	00010001b, 00110001b, 00101011b

TOKEN DB 3
SCORE DB ?
SEEDS DB 'S', 'H', 'D', 'C'

EXCESS_FIGURES DB ?
EXCESS_ACES DB ?

S_QUESTIONCARD DB 'Do you want to extact a card? (Y/N) ', '$'
S_CARDEXTRACTED DB 'Card extracted: ', '$'
S_CUTFIGURES DB 'Do you want to "cut" figure values to 10? (Y/N) ', '$'
S_CUTACES DB 'Do you want to change value to all aces? (Y/N) ', '$'
S_FINALSCORE DB 'Your final score is: ', '$'
S_PASSED DB 'You passed the exam. I am so proud of you!', '$'
S_NOTPASSED DB 'You did not pass the exam. I am so happy to see you in another call!', '$'
S_ENDLINE DB 10, 13, '$'

.CODE
.STARTUP
	
;	CALL ITEM1_PROC
;	CALL ITEM2_PROC
	CALL ITEM3_PROC
		
.EXIT

ITEM1_PROC PROC
	PUSHA
	MOV CL, TOKEN
	XOR CH, CH
	XOR BH, BH
	XOR SI, SI
	MOV SCORE, BASE_SCORE
	ITEM1_LOOP:
		LEA DX, S_QUESTIONCARD
		MOV AH, 9
		INT 21H
		; Input char
		MOV AH, 1
		INT 21H
		CALL PRINT_ENDLINE
		; Char is in AL
		CMP AL, 'y'
		JE ITEM1_EXTRACT_CARD
		CMP AL, 'Y'
		JE ITEM1_EXTRACT_CARD
		JMP ITEM1_EXIT_LOOP
	ITEM1_EXTRACT_CARD:
		; Print a string
		LEA DX, S_CARDEXTRACTED
		MOV AH, 9
		INT 21H
		; Extract card value
		MOV BL, DECKS[SI]
		MOV AL, BL
		XOR AH, AH
		AND AL, 0Fh					; Number
		ADD SCORE, AL				; Update the score
		; Display the number
		PUSH AX
		CALL PRINT_DECIMAL
		POP AX
		
		; Extract card seed 		
		SHR BL, 4
		AND BL, 03h					; Seed
		MOV DL, SEEDS[BX]			; Retrieve char corresponding to the seed
		; Display the seed
		MOV AH, 2
		INT 21H
		CALL PRINT_ENDLINE
		INC SI						; Next card
		LOOP ITEM1_LOOP
	
	ITEM1_EXIT_LOOP:
	; Print final score
	CALL PRINT_ENDLINE
	LEA DX, S_FINALSCORE
	MOV AH, 9
	INT 21H
	XOR AH, AH
	MOV AL, SCORE
	PUSH AX
	CALL PRINT_DECIMAL
	POP AX
	CALL PRINT_ENDLINE

	CMP SCORE, 18
	JB ITEM1_REJECT
	CMP SCORE, 30
	JA ITEM1_REJECT
	; Here, it means a good result
	; Print a string informing that the exam is passed
	LEA DX, S_PASSED
	JMP ITEM1_END
	
	ITEM1_REJECT:
	; Print a string informing that the exam is not passed
	LEA DX, S_NOTPASSED
	ITEM1_END:
	MOV AH, 9
	INT 21H
	POPA
	RET
ITEM1_PROC ENDP

ITEM2_PROC PROC
	PUSHA
	MOV EXCESS_FIGURES, 0
	MOV CL, TOKEN
	XOR CH, CH
	XOR BH, BH
	XOR SI, SI
	MOV SCORE, BASE_SCORE
	ITEM2_LOOP:
		LEA DX, S_QUESTIONCARD
		MOV AH, 9
		INT 21H
		; Input char
		MOV AH, 1
		INT 21H
		CALL PRINT_ENDLINE
		; Char is in AL
		CMP AL, 'y'
		JE ITEM2_EXTRACT_CARD
		CMP AL, 'Y'
		JE ITEM2_EXTRACT_CARD
		JMP ITEM2_EXIT_LOOP
	ITEM2_EXTRACT_CARD:
		; Print a string
		LEA DX, S_CARDEXTRACTED
		MOV AH, 9
		INT 21H
		; Extract card value
		MOV BL, DECKS[SI]
		MOV AL, BL
		XOR AH, AH
		AND AL, 0Fh					; Number
		ADD SCORE, AL				; Update the score
		CMP AL, 10
		JBE ITEM2_NOFIGURE
		; If here, the card is a figure. So manage the 'excess'
		ADD EXCESS_FIGURES, AL
		SUB EXCESS_FIGURES, 10
		ITEM2_NOFIGURE:
			
		; Display the number
		PUSH AX
		CALL PRINT_DECIMAL
		POP AX
		
		; Extract card seed 		
		SHR BL, 4
		AND BL, 03h					; Seed
		MOV DL, SEEDS[BX]			; Retrieve char corresponding to the seed
		; Display the seed
		MOV AH, 2
		INT 21H
		CALL PRINT_ENDLINE
		INC SI						; Next card
		LOOP ITEM2_LOOP
	
	ITEM2_EXIT_LOOP:
	CMP CL, 0
	JA ITEM2_PRINT
	; Here if all tokens are used. So it is possible to 'cut' figures
	CALL PRINT_ENDLINE
	LEA DX, S_CUTFIGURES
	MOV AH, 9
	INT 21H
	; Input char
	MOV AH, 1
	INT 21H
	CALL PRINT_ENDLINE
	; Char is in AL
	CMP AL, 'y'
	JE ITEM2_CUT_FIGURES
	CMP AL, 'Y'
	JE ITEM2_CUT_FIGURES
	JMP ITEM2_PRINT
	
	ITEM2_CUT_FIGURES:
	MOV AH, SCORE
	SUB AH, EXCESS_FIGURES
	MOV SCORE, AH
	
	ITEM2_PRINT:	
	; Print final score
	CALL PRINT_ENDLINE
	LEA DX, S_FINALSCORE
	MOV AH, 9
	INT 21H
	XOR AH, AH
	MOV AL, SCORE
	PUSH AX
	CALL PRINT_DECIMAL
	POP AX
	CALL PRINT_ENDLINE

	CMP SCORE, 18
	JB ITEM2_REJECT
	CMP SCORE, 30
	JA ITEM2_REJECT
	; Here, it means a good result
	; Print a string informing that the exam is passed
	LEA DX, S_PASSED
	JMP ITEM2_END
	
	ITEM2_REJECT:
	; Print a string informing that the exam is not passed
	LEA DX, S_NOTPASSED
	ITEM2_END:
	MOV AH, 9
	INT 21H
	POPA
	RET
ITEM2_PROC ENDP

ITEM3_PROC PROC
	PUSHA
	MOV EXCESS_FIGURES, 0
	MOV EXCESS_ACES, 0
	MOV CL, TOKEN
	XOR CH, CH
	XOR BH, BH
	XOR SI, SI
	MOV SCORE, BASE_SCORE
	ITEM3_LOOP:
		LEA DX, S_QUESTIONCARD
		MOV AH, 9
		INT 21H
		; Input char
		MOV AH, 1
		INT 21H
		CALL PRINT_ENDLINE
		; Char is in AL
		CMP AL, 'y'
		JE ITEM3_EXTRACT_CARD
		CMP AL, 'Y'
		JE ITEM3_EXTRACT_CARD
		JMP ITEM3_EXIT_LOOP
	ITEM3_EXTRACT_CARD:
		; Print a string
		LEA DX, S_CARDEXTRACTED
		MOV AH, 9
		INT 21H
		; Extract card value
		MOV BL, DECKS[SI]
		MOV AL, BL
		XOR AH, AH
		AND AL, 0Fh					; Number
		ADD SCORE, AL				; Update the score
		CMP AL, 10
		JBE ITEM3_NOFIGURE
		; If here, the card is a figure. So manage the 'excess'
		ADD EXCESS_FIGURES, AL
		SUB EXCESS_FIGURES, 10
		ITEM3_NOFIGURE:
		CMP AL, 1
		JNE ITEM3_NOACE
		; If here, the card is an ace. So manage the 'excess'
		ADD EXCESS_ACES, 13
				
		ITEM3_NOACE:	
		; Display the number
		PUSH AX
		CALL PRINT_DECIMAL
		POP AX
		
		; Extract card seed 		
		SHR BL, 4
		AND BL, 03h					; Seed
		MOV DL, SEEDS[BX]			; Retrieve char corresponding to the seed
		; Display the seed
		MOV AH, 2
		INT 21H
		CALL PRINT_ENDLINE
		INC SI						; Next card
		LOOP ITEM3_LOOP
	
	ITEM3_EXIT_LOOP:
	CMP CL, 0
	JA ITEM3_PRINT
	; Here if all tokens are used. So it is possible to 'cut' figures
	CALL PRINT_ENDLINE
	LEA DX, S_CUTFIGURES
	MOV AH, 9
	INT 21H
	; Input char
	MOV AH, 1
	INT 21H
	CALL PRINT_ENDLINE
	; Char is in AL
	CMP AL, 'y'
	JE ITEM3_CUT_FIGURES
	CMP AL, 'Y'
	JE ITEM3_CUT_FIGURES
	JMP ITEM3_QUESTION_CUT_ACES
	
	ITEM3_CUT_FIGURES:
	MOV AH, SCORE
	SUB AH, EXCESS_FIGURES
	MOV SCORE, AH
	
	ITEM3_QUESTION_CUT_ACES:
	CALL PRINT_ENDLINE
	LEA DX, S_CUTACES
	MOV AH, 9
	INT 21H
	; Input char
	MOV AH, 1
	INT 21H
	CALL PRINT_ENDLINE
	; Char is in AL
	CMP AL, 'y'
	JE ITEM3_CUT_ACES
	CMP AL, 'Y'
	JE ITEM3_CUT_ACES
	JMP ITEM3_PRINT

	ITEM3_CUT_ACES:
	MOV AH, SCORE
	ADD AH, EXCESS_ACES
	MOV SCORE, AH
	
	ITEM3_PRINT:	
	; Print final score
	CALL PRINT_ENDLINE
	LEA DX, S_FINALSCORE
	MOV AH, 9
	INT 21H
	XOR AH, AH
	MOV AL, SCORE
	PUSH AX
	CALL PRINT_DECIMAL
	POP AX
	CALL PRINT_ENDLINE

	CMP SCORE, 18
	JB ITEM3_REJECT
	CMP SCORE, 30
	JA ITEM3_REJECT
	; Here, it means a good result
	; Print a string informing that the exam is passed
	LEA DX, S_PASSED
	JMP ITEM3_END
	
	ITEM3_REJECT:
	; Print a string informing that the exam is not passed
	LEA DX, S_NOTPASSED
	ITEM3_END:
	MOV AH, 9
	INT 21H
	POPA
	RET
ITEM3_PROC ENDP

; Procedure to display a decimal number up to 65'536 (16 bits)
; The value is read from the stack, 
; so it must be pushed before the procedure call
PRINT_DECIMAL PROC
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
	
	POPA	
	POP BP
	RET
PRINT_DECIMAL ENDP

PRINT_ENDLINE PROC
	PUSHA
	MOV AH, 9
	LEA DX, S_ENDLINE
	INT 21H
	POPA
	RET
PRINT_ENDLINE ENDP

END