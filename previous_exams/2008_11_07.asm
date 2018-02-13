.MODEL SMALL
.STACK
.DATA
N_CITIZENS	EQU	5
N_STATES	EQU	2
LF			EQU	10
CR			EQU	13

VOTES		DW	N_CITIZENS	DUP(0007H, 0C07H, 0002H, 9602H, 3603H)
; Male, 18, State 1, Candidate 2
; Male, 30, State 1, Candidate 2
; Male, 18, State 0, Candidate 1
; Female, 40, State 0, Candidate 1
; Male, 72, State 0, Candidate 2

STATES		DB	N_STATES	DUP(4, 20)

VOTES_STATE	DW	N_STATES	DUP(?,?,?,?)

POINTS_C1	DW	?
POINTS_C2	DW	?

ALL_NOT_VALID	DW	?
ALL_BLANK		DW	?
ALL_VOTES_C1	DW	?
ALL_VOTES_C2	DW	?

ALL_NOT_VALID_P	DW	?
ALL_BLANK_P		DW	?
ALL_VOTES_C1_P	DW	?
ALL_VOTES_C2_P	DW	?
                
F_VOTES			DW	1 DUP (?,?,?,?)
M_VOTES			DW	1 DUP (?,?,?,?)

AGE18_25		DW	1 DUP (?,?,?,?)
AGE26_35		DW	1 DUP (?,?,?,?)
AGE36_50		DW	1 DUP (?,?,?,?)
AGE51_70		DW	1 DUP (?,?,?,?)
AGE71			DW	1 DUP (?,?,?,?)

S_NOT_VALID		DB	'Not valid percentage: ', '$'
S_BLANK			DB	'Blank percentage: ', '$'
S_VOTES_C1		DB	'Candidate 1 percentage: ', '$'
S_VOTES_C2		DB	'Candidate 2 percentage: ', '$'
S_STATE			DB	'Statistics for state ', '$'
S_GLOBAL		DB	'Global statistics', '$'
S_MALE			DB	'Male statistics', '$'
S_FEMALE		DB	'Female statistics', '$'
S_AGE18_25		DW	'18-25 statistics', '$'
S_AGE26_35		DW	'26-35 statistics', '$'
S_AGE36_50		DW	'26-50 statistics', '$'
S_AGE51_70		DW	'51-70 statistics', '$'
S_AGE71			DW	'>70 statistics', '$'
                                         
S_WINNER1		DB	'Winner is candidate 1', '$'
S_WINNER2		DB	'Winner is candidate 2', '$'

S_ENDLINE		DB	LF, CR, '$'

S_MENU			DB	'Possible choiches:', LF, CR, '$'
S_ITEM1			DB	'1. Overall statistics', LF, CR, '$'
S_ITEM2			DB	'2. Statistics by state', LF, CR, '$'
S_ITEM3			DB	'3. Statistics per sex', LF, CR, '$'
S_INSERT		DB	'Enter your choice: ', '$'
S_INVALID		DB	'Invalid option', LF, CR, '$'

TO_DISPLAY		DW	?

MENU_SWITCH		DW	1 DUP (?, ?, ?)

.CODE
.STARTUP

MAIN:
	; Mandatory part
	CALL INIT
	CALL EXTRACT_VOTES	
	CALL COMPUTE_TOTAL_VOTES
	CALL WINNER
	
	; Display menu
	MOV AH, 9
	LEA DX, S_MENU
	INT 21H
	LEA DX, S_ITEM1
	INT 21H
	LEA DX, S_ITEM2
	INT 21H
	LEA DX, S_ITEM3
	INT 21H
	LEA DX, S_INSERT
	INT 21H
	
	; Input char
	MOV AH, 1H
	INT 21H
	; Character is stored in AL
	PUSH AX

	; Print endline
	LEA DX, S_ENDLINE
	MOV AH, 9
	INT 21H	
	POP BX							; Retieve char from the stack

	XOR BH, BH
	CMP BL, '1'
	JB INVALID_OPTION
	CMP BL, '3'
	JA INVALID_OPTION
	SUB BL, '1'
	SHL BX, 1
	ADD BX, OFFSET MENU_SWITCH
	JMP [BX]
	
ITEM1:
	CALL COMPUTE_TOTAL_STATISTICS
	CALL DISPLAY_PERCENTAGES
	JMP END_MAIN
ITEM2:
	CALL COMPUTE_STATISTICS_STATE
	JMP END_MAIN
ITEM3:	
	CALL DISPLAY_STATISTICS_SEX
	JMP END_MAIN
	
INVALID_OPTION:
	LEA DX, S_INVALID
	MOV AH, 9
	INT 21H
	JMP END_MAIN
			
	END_MAIN:

.EXIT

INIT PROC
	PUSHA
	MOV POINTS_C1, 0		; Used as a counter
	MOV POINTS_C2, 0		; Used as a counter
	MOV ALL_NOT_VALID, 0	; Used as a counter
	MOV ALL_BLANK, 0		; Used as a counter
	MOV ALL_VOTES_C1, 0		; Used as a counter
	MOV ALL_VOTES_C2, 0		; Used as a counter
	
	MOV F_VOTES, 0
	MOV F_VOTES+2, 0
	MOV F_VOTES+4, 0
	MOV F_VOTES+6, 0
	
	MOV M_VOTES, 0
	MOV M_VOTES+2, 0
	MOV M_VOTES+4, 0
	MOV M_VOTES+6, 0
	
	MOV MENU_SWITCH, OFFSET ITEM1  
	MOV MENU_SWITCH+2, OFFSET ITEM2
	MOV MENU_SWITCH+4, OFFSET ITEM3

	XOR SI, SI				; Index
	MOV CX, N_STATES
	INIT_LOOP:                      
		MOV VOTES_STATE[SI], WORD PTR 0
		MOV VOTES_STATE[SI+2], WORD PTR 0
		MOV VOTES_STATE[SI+4], WORD PTR 0
		MOV VOTES_STATE[SI+6], WORD PTR 0
		ADD SI, 8			; Element are composed by 4 words 	
		LOOP INIT_LOOP
	POPA
	RET
INIT ENDP

EXTRACT_VOTES PROC
	PUSHA
	; FAAAAAAA SSSSSSVV
	XOR SI, SI
	XOR DI, DI				; Will contain the index of VOTES_STATE
	MOV CX, N_CITIZENS		; Loop for all citizens
	LOOP_VOTES:
		MOV AX, VOTES[SI]
		MOV DI, AX
		; SHR DI, 2
		SHR DI, 1
		SHR DI, 1			; ...SSSSSS
		AND DI, 003FH		; Extract state value
		; DI * 8 = SHL DI, 3
		SHL DI, 1
		SHL DI, 1
		SHL DI, 1
		MOV BX, AX
		AND BX, 0003H		; Vote value
		SHL BX, 1			; Each cell is a word, not a byte
		INC VOTES_STATE[DI][BX]	; Increment the corresponding state and vote
		TEST AX, 8000H		; Test sex
		JZ MALE
		; Female
		INC F_VOTES[BX]
		JMP AGE_CMP
		MALE:
		INC M_VOTES[BX]
		AGE_CMP:
		AND AX, 7F00H		; Age
		XCHG AH, AL			; Age in AL
		ADD AL, 18
		CMP AL, 25
		JBE AGE1
		CMP AL, 35
		JBE AGE2
		CMP AL, 50
		JBE AGE3
		CMP AL, 70
		JBE AGE4
		; If here, Age > 71
		ADD BX, OFFSET AGE71
		JMP NEXT_ELEMENT
		AGE1:				; 18-25
		ADD BX, OFFSET AGE18_25
		JMP NEXT_ELEMENT	
		AGE2:				; 26-35
		ADD BX, OFFSET AGE26_35
		JMP NEXT_ELEMENT	
		AGE3:				; 36-50
		ADD BX, OFFSET AGE36_50
		JMP NEXT_ELEMENT	
		AGE4:				; 51-70
		ADD BX, OFFSET AGE51_70
		JMP NEXT_ELEMENT	
		
		NEXT_ELEMENT:
		INC [BX]		
		INC SI
		INC SI				; Cells are word	
	LOOP LOOP_VOTES
	POPA		
	RET	
EXTRACT_VOTES ENDP

COMPUTE_TOTAL_VOTES PROC
	PUSHA
	XOR SI, SI
	XOR DI, DI
	MOV CX, N_STATES
	LOOP_WINNER:
		MOV DI, SI
		; DI * 8 = SHL DI, 3
		SHL DI, 1
		SHL DI, 1
		SHL DI, 1
		XOR DH, DH
		MOV DL, STATES[SI]			; DX stores the number of votes assigned to the state
		MOV AX, VOTES_STATE[DI+6]	; Votes of candidate 2
		MOV BX, VOTES_STATE[DI+4]	; Votes of candidate 1
		CMP AX, BX
		JB C1_WINS					; Jump if C2 < C1
		; C2 gets all points
		ADD POINTS_C2, DX
		JMP NEXT_STATE
		C1_WINS:
			ADD POINTS_C1, DX
		NEXT_STATE:
		INC SI
	LOOP LOOP_WINNER	
	POPA
	RET
COMPUTE_TOTAL_VOTES ENDP

COMPUTE_TOTAL_STATISTICS PROC
	PUSHA
	XOR DI, DI
	MOV CX, N_STATES
	LOOP_STATISTICS:
		MOV AX, VOTES_STATE[DI]
		ADD ALL_NOT_VALID, AX
		MOV AX, VOTES_STATE[DI+2]
		ADD ALL_BLANK, AX
		MOV AX, VOTES_STATE[DI+4]
		ADD ALL_VOTES_C1, AX
		MOV AX, VOTES_STATE[DI+6]
		ADD ALL_VOTES_C2, AX
		ADD DI, 8					; Next element
	LOOP LOOP_STATISTICS
	; Compute percentages
	MOV BX, N_CITIZENS	
	MOV CX, 100
	MOV AX, ALL_NOT_VALID
	XOR DX, DX
	MUL CX
	DIV BX
	MOV ALL_NOT_VALID_P, AX
	
	MOV AX, ALL_BLANK
	XOR DX, DX
	MUL CX
	DIV BX
	MOV ALL_BLANK_P, AX
	
	MOV AX, ALL_VOTES_C1
	XOR DX, DX
	MUL CX
	DIV BX
	MOV ALL_VOTES_C1_P, AX
	
	MOV AX, ALL_VOTES_C2
	XOR DX, DX
	MUL CX
	DIV BX
	MOV ALL_VOTES_C2_P, AX
	POPA
	RET
COMPUTE_TOTAL_STATISTICS ENDP

COMPUTE_STATISTICS_STATE PROC
	PUSHA
	XOR DI, DI
	MOV SI, 1
	MOV BP, 100
	MOV CX, N_STATES
	LOOP_STATISTICS_STATE:
		LEA DX, S_STATE				; Print string
		MOV AH, 9
		INT 21H
		
		MOV TO_DISPLAY, SI			; Print state identifier
		CALL DISPLAY_NUMBER
		
		; Compute the total number of citizens in the state
		MOV BX, VOTES_STATE[DI]
		ADD BX, VOTES_STATE[DI+2]
		ADD BX, VOTES_STATE[DI+4]
		ADD BX, VOTES_STATE[DI+6]
		
		; Compute percentage of not valid
		MOV AX, VOTES_STATE[DI]
		XOR DX, DX
		MUL BP
		DIV BX
		MOV TO_DISPLAY, AX
		; Display message
		LEA DX, S_NOT_VALID
		MOV AH, 9
		INT 21H
		; Display number
		CALL DISPLAY_NUMBER
	
		; Compute percentage of blank
		MOV AX, VOTES_STATE[DI+2]
		XOR DX, DX
		MUL BP
		DIV BX
		MOV TO_DISPLAY, AX
		; Display message
		LEA DX, S_BLANK
		MOV AH, 9
		INT 21H
		; Display number
		CALL DISPLAY_NUMBER
	
		; Compute percentage of candidate 1
		MOV AX, VOTES_STATE[DI+4]
		XOR DX, DX
		MUL BP
		DIV BX
		MOV TO_DISPLAY, AX
		; Display message
		LEA DX, S_VOTES_C1
		MOV AH, 9
		INT 21H
		; Display number
		CALL DISPLAY_NUMBER

		; Compute percentage of blank
		MOV AX, VOTES_STATE[DI+6]
		XOR DX, DX
		MUL BP
		DIV BX
		MOV TO_DISPLAY, AX
		; Display message
		LEA DX, S_VOTES_C2
		MOV AH, 9
		INT 21H
		; Display number
		CALL DISPLAY_NUMBER
		
		ADD DI, 8					; Next state
		ADD SI, 1	                
	LOOP LOOP_STATISTICS_STATE                     
	                     
	POPA
	RET
COMPUTE_STATISTICS_STATE ENDP

; In order to execute this procedure, load the number to display into the variable TO_DISPLAY
DISPLAY_NUMBER PROC
	PUSHA
	MOV AX, TO_DISPLAY
	MOV BX, 10						; Divisor
	XOR DX, DX
	XOR CX, CX
	
	;Splitting process starts here
Dloop1:
	XOR DX, DX						; Clear DX
	DIV BX
	PUSH DX							; Push the digit
	INC CX							; Increments the number of digits
	CMP AX, 0						; Checks if there something else to divide
	JNE Dloop1
	
Dloop2:
	POP DX							; Pop the digit
	ADD DX, 30H						; ASCII conversion
	MOV AH, 02H						; Identification code     
	INT 21H
	LOOP Dloop2
	
	LEA DX, S_ENDLINE
	MOV AH, 9
	INT 21H
	
	POPA	
	RET
DISPLAY_NUMBER  ENDP

DISPLAY_PERCENTAGES PROC
	PUSHA              
	LEA DX, S_GLOBAL
	MOV AH, 9
	INT 21H
	LEA DX, S_ENDLINE
	MOV AH, 9
	INT 21H
		
	LEA DX, S_NOT_VALID
	MOV AH, 9
	INT 21H
	MOV AX, ALL_NOT_VALID_P
	MOV TO_DISPLAY, AX
	CALL DISPLAY_NUMBER

	LEA DX, S_BLANK
	MOV AH, 9
	INT 21H
	MOV AX, ALL_BLANK_P
	MOV TO_DISPLAY, AX
	CALL DISPLAY_NUMBER

	LEA DX, S_VOTES_C1
	MOV AH, 9
	INT 21H
	MOV AX, ALL_VOTES_C1_P
	MOV TO_DISPLAY, AX
	CALL DISPLAY_NUMBER

	LEA DX, S_VOTES_C2
	MOV AH, 9
	INT 21H
	MOV AX, ALL_VOTES_C2_P
	MOV TO_DISPLAY, AX
	CALL DISPLAY_NUMBER
	POPA
	RET
DISPLAY_PERCENTAGES ENDP	

DISPLAY_STATISTICS_SEX PROC
	PUSHA
	LEA DX, S_MALE
	MOV AH, 9
	INT 21H
	LEA DX, S_ENDLINE
	MOV AH, 9
	INT 21H
	
	MOV BP, 100

	MOV BX, M_VOTES  
	ADD BX, M_VOTES+2
	ADD BX, M_VOTES+4
	ADD BX, M_VOTES+6
	         
 	; Compute percentage of not valid
	MOV AX, M_VOTES
	XOR DX, DX
	MUL BP
	DIV BX
	MOV TO_DISPLAY, AX
	; Display message
	LEA DX, S_NOT_VALID
	MOV AH, 9
	INT 21H
	; Display number
	CALL DISPLAY_NUMBER

	; Compute percentage of blank
	MOV AX, M_VOTES+2
	XOR DX, DX
	MUL BP
	DIV BX
	MOV TO_DISPLAY, AX
	; Display message
	LEA DX, S_BLANK
	MOV AH, 9
	INT 21H
	; Display number
	CALL DISPLAY_NUMBER

	; Compute percentage of candidate 1
	MOV AX, M_VOTES+4
	XOR DX, DX
	MUL BP
	DIV BX
	MOV TO_DISPLAY, AX
	; Display message
	LEA DX, S_VOTES_C1
	MOV AH, 9
	INT 21H
	; Display number
	CALL DISPLAY_NUMBER

	; Compute percentage of blank
	MOV AX, M_VOTES+6
	XOR DX, DX
	MUL BP
	DIV BX
	MOV TO_DISPLAY, AX
	; Display message
	LEA DX, S_VOTES_C2
	MOV AH, 9
	INT 21H
	; Display number
	CALL DISPLAY_NUMBER
	
	
	LEA DX, S_FEMALE
	MOV AH, 9
	INT 21H
	LEA DX, S_ENDLINE
	MOV AH, 9
	INT 21H

    MOV BX, F_VOTES  
	ADD BX, F_VOTES+2
	ADD BX, F_VOTES+4
	ADD BX, F_VOTES+6
	         
 	; Compute percentage of not valid
	MOV AX, F_VOTES
	XOR DX, DX
	MUL BP
	DIV BX
	MOV TO_DISPLAY, AX
	; Display message
	LEA DX, S_NOT_VALID
	MOV AH, 9
	INT 21H
	; Display number
	CALL DISPLAY_NUMBER

	; Compute percentage of blank
	MOV AX, F_VOTES+2
	XOR DX, DX
	MUL BP
	DIV BX
	MOV TO_DISPLAY, AX
	; Display message
	LEA DX, S_BLANK
	MOV AH, 9
	INT 21H
	; Display number
	CALL DISPLAY_NUMBER

	; Compute percentage of candidate 1
	MOV AX, F_VOTES+4
	XOR DX, DX
	MUL BP
	DIV BX
	MOV TO_DISPLAY, AX
	; Display message
	LEA DX, S_VOTES_C1
	MOV AH, 9
	INT 21H
	; Display number
	CALL DISPLAY_NUMBER

	; Compute percentage of blank
	MOV AX, F_VOTES+6
	XOR DX, DX
	MUL BP
	DIV BX
	MOV TO_DISPLAY, AX
	; Display message
	LEA DX, S_VOTES_C2
	MOV AH, 9
	INT 21H
	; Display number
	CALL DISPLAY_NUMBER
         
	POPA
	RET
DISPLAY_STATISTICS_SEX ENDP

WINNER PROC
	PUSHA
	MOV AX, POINTS_C1
	CMP AX, POINTS_C2
	JB WINNER2
	; Winner is 1
	LEA DX, S_WINNER1
	JMP END_WINNER
	WINNER2:
	LEA DX, S_WINNER2	
	END_WINNER:
	MOV AH, 9
	INT 21H
	LEA DX, S_ENDLINE
	INT 21H	
	POPA
	RET	
WINNER ENDP	

END