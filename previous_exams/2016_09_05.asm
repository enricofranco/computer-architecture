.MODEL SMALL
.STACK
.DATA
XA DB ?
XB DB ?
XC DB ?
YC DB ?
AREA DW ?

XT DB 40
YT DB 32

A DW ?	; Stores |4Yc - 3Xc|
B DB ?	; Stores |Xa - Xb|

MENU_JT DW ITEM1, ITEM2, ITEM3, BONUS, TERMINATE

; Strings
S_ENDLINE DB 10, 13, '$'
S_INSERTXA DB 'Insert Xa: ', '$'                                   
S_INSERTXB DB 'Insert Xb: ', '$'                                   
S_INSERTXC DB 'Insert Xc: ', '$'
S_INSERTYC DB 'Insert Yc: ', '$'
S_INSERTXT DB 'Insert Xt: ', '$'
S_INSERTYT DB 'Insert Yt: ', '$'
S_BELONGS DB 'The point T belongs to the line y = 3/4 x', '$'
S_NOTBELONGS DB 'The point T does not belong to the line y = 3/4 x', '$'
S_AREA DB 'Area: ', '$'
S_MENU 	DB 'Please, insert your choice', 10, 13
		DB '1. Compute area, assuming base = 30', 10, 13
		DB '2. Compute area, assuming base = 12', 10, 13
		DB '3. Compute area, inserting your coordinates', 10, 13,
		DB '4. Check if a point belongs to line y = 3/4 x', 10, 13,
		DB '5. Exit', 10, 13, '$'

S_INVALIDCHOICE DB 'Unvalid choice, please insert a valid one.', 10, 13, '$'
S_ENDPROGRAM DB 'End of program. Thank you.', '$'

.CODE
.STARTUP
MAIN:
    MOV AH, 9
    ; Get XC
    LEA DX, S_INSERTXC
    INT 21H
    MOV BX, 3
    PUSH BX
    CALL READ_DECIMAL
    POP BX
	MOV XC, BL
	
    CALL PRINT_ENDLINE

    ; Get YC
    LEA DX, S_INSERTYC
    INT 21H
    MOV BX, 3
    PUSH BX
    CALL READ_DECIMAL
    POP BX
    MOV YC, BL
    
	CALL COMPUTE_4YC_MINUS_3XC
    CALL PRINT_ENDLINE
    
MENU_LOOP:
	; Print menu
	MOV AH, 9
	LEA DX, S_MENU
	INT 21H
	; Get the choice
	MOV AH, 1
	INT 21H
	CALL PRINT_ENDLINE
	; AL stores the inserted char
	SUB AL, '0'
	; Check the choice
	CMP AL, 0
	JBE INVALID_CHOICE
	CMP AL, 5
	JA INVALID_CHOICE
	; If it is valid, use the jump table
	DEC AL
	XOR BH, BH
	MOV BL, AL
	SHL BX, 1				; BX = BX*2
	JMP MENU_JT[BX]
	ITEM1:			
		CALL ITEM1_PROC
		CALL PRINT_AREA
		JMP MENU_LOOP
	ITEM2:
		CALL ITEM2_PROC
		CALL PRINT_AREA   
		JMP MENU_LOOP
	ITEM3:
	    MOV AH, 9
	    ; Get XA
	    LEA DX, S_INSERTXA
	    INT 21H
	    MOV BX, 3
	    PUSH BX
	    CALL READ_DECIMAL
	    POP BX
		MOV XA, BL
		
	    CALL PRINT_ENDLINE
	
	    ; Get XB
	    LEA DX, S_INSERTXB
	    INT 21H
	    MOV BX, 3
	    PUSH BX
	    CALL READ_DECIMAL
	    POP BX
	    MOV XB, BL  
	    
		CALL COMPUTE_XA_MINUS_XB
		CALL ITEM3_PROC
		CALL PRINT_ENDLINE
  		CALL PRINT_AREA
		JMP MENU_LOOP
	BONUS:
	    MOV AH, 9
	    ; Get XT
	    LEA DX, S_INSERTXT
	    INT 21H
	    MOV BX, 3
	    PUSH BX
	    CALL READ_DECIMAL
	    POP BX
		MOV XT, BL
		
	    CALL PRINT_ENDLINE
	
	    ; Get YT
	    LEA DX, S_INSERTYT
	    INT 21H
	    MOV BX, 3
	    PUSH BX
	    CALL READ_DECIMAL
	    POP BX
	    MOV YT, BL

	    CALL PRINT_ENDLINE
		CALL CHECK_BELONGING
	    CALL PRINT_ENDLINE
		JMP MENU_LOOP
	INVALID_CHOICE:
		MOV AH, 9
		LEA DX, S_INVALIDCHOICE
		INT 21H
		JMP MENU_LOOP 
	TERMINATE:
		MOV AH, 9
		LEA DX, S_ENDPROGRAM
		INT 21H
.EXIT

COMPUTE_4YC_MINUS_3XC PROC
	PUSHA
	MOV AL, XC
	MOV AH, 3
	MUL AH					; AX = 3*XC
	MOV BL, YC
	XOR BH, BH
	SHL BX, 2				; BX = 4*YC
	SUB AX, BX				; 3*XC - 4*YC
	CMP AX, 0
	JGE A_POS
	; Here if number is negative
	NEG AX
	A_POS:
	MOV A, AX				; Store the result	
	POPA
	RET
COMPUTE_4YC_MINUS_3XC ENDP

COMPUTE_XA_MINUS_XB PROC
	PUSHA
	MOV AL, XA
	SUB AL, XB
	CMP AL, 0
	JGE B_POS
	; Here if number is negative
	NEG AL
	B_POS:
	MOV B, AL				; Store the result	
	POPA
	RET
COMPUTE_XA_MINUS_XB ENDP

ITEM1_PROC PROC
	PUSHA
	MOV AX, A
	MOV BX, 15
	MUL BX
	MOV BX, 5
	DIV BX
	MOV AREA, AX 
	POPA
	RET
ITEM1_PROC ENDP

ITEM2_PROC PROC
	PUSHA
	MOV AX, A
	MOV BX, 6
	MUL BX
	MOV BX, 5
	DIV BX
	MOV AREA, AX 
	POPA
	RET
ITEM2_PROC ENDP

ITEM3_PROC PROC
	PUSHA
	MOV AL, B
	MOV AH, 5
	MUL AH
	MUL A
	MOV BX, 40
	DIV BX
	MOV AREA, AX
	POPA
	RET
ITEM3_PROC ENDP

CHECK_BELONGING PROC
	PUSHA
	MOV AL, XT
	SHR AL, 2				; Div 4
	MOV AH, 3
	MUL AH
	CMP AL, YT
	JE T_BELONGS
	; T doesn't belong to the line
	; Print something
	LEA DX, S_NOTBELONGS
	JMP END_CHECK_BELONGING
	T_BELONGS:
	; Print something
	LEA DX, S_BELONGS
	END_CHECK_BELONGING:
	MOV AH, 9
	INT 21H
	POPA
	RET
CHECK_BELONGING ENDP

PRINT_ENDLINE PROC
	PUSHA
	MOV AH, 9
	LEA DX, S_ENDLINE
	INT 21H
	POPA
	RET
PRINT_ENDLINE ENDP

PRINT_AREA PROC
	PUSHA
	MOV AH, 9
	LEA DX, S_AREA
	INT 21H
	PUSH AREA
	CALL DISPLAY_DECIMAL
	POP AREA				; Dummy pop
	CALL PRINT_ENDLINE
	POPA
	RET
PRINT_AREA ENDP

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

END