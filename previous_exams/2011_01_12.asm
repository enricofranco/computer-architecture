.MODEL SMALL
.STACK
.DATA
; Constants
N			EQU		6
; Input
; A			DB		N DUP (81h, 0Fh, 0FFh, 55h, 12h, 03h)	; -127, 15, -1, 85, 18, 3	-> -1905, -85, 54		-> 8743950 
; B			DB		N DUP (01h, 88h, 2Fh, 44h, 21h, 0AEh)	; 1, -120, 47, 68, 33, -82	-> -120, 3196, -2706	-> 1037805120
A			DB		N DUP (01h, 0FFh, 0Ah, 0Eh, 02h, 03h)	; 1, -1, 10, 14, 2, 3		-> -1, 140, 6			-> -840
B			DB		N DUP (08h, 0F8h, 01h, 0FFh, 0Ah, 0F6h)	; 8, -8, 1, -1, 10, -10		-> -64, -1, -100		-> -6400
; Output             
MULT_A		DB		N DUP (?)
MULT_B		DB		N DUP (?)
; Variable
COUNTER		DB		?
TMP_RESULT	DW		N/2 DUP (?)
MULT_ABS_A	DB		N DUP (?)
MULT_ABS_B	DB		N DUP (?)
; Strings
LF				EQU	10
CR          	EQU	13
S_LARGEST1		DB	'Largest value is the first number', LF, CR, '$'	
S_LARGEST2   	DB	'Largest value is the second number', LF, CR, '$'
S_EQUAL		   	DB	'Values are equals', LF, CR, '$'
S_ABSLARGEST1	DB	'Largest absolute value is the first number', LF, CR, '$'
S_ABSLARGEST2	DB	'Largest absolute value is the second number', LF, CR, '$'
S_ABSEQUAL		DB	'Absolute values are equals', LF, CR, '$'
.CODE
.STARTUP

MAIN:
	LEA SI, A
	LEA DI, MULT_A
	PUSH SI
	PUSH DI
	CALL MULTIPLY_ARRAY
	POP DI
	POP SI

	LEA SI, B
	LEA DI, MULT_B
	PUSH SI
	PUSH DI
	CALL MULTIPLY_ARRAY
	POP DI
	POP SI
    
    CALL LARGEST_VALUE

.EXIT

MULTIPLY_ARRAY PROC
	PUSH BP
	MOV BP, SP
	PUSHA
	MOV SI, [BP]+6				; Address of source
	MOV DI, [BP]+4				; Address of result
	; Multiply each pair of number
	; 8 bit * 8 bit multiplication
	MOV AL, [SI]				; First element
	MOV BL, [SI]+1				; Second element
	IMUL BL
	MOV TMP_RESULT, AX			; Store the first multiplication
	
	MOV AL, [SI]+2				; Third element
	MOV BL, [SI]+3				; Fourth element
	IMUL BL
	MOV TMP_RESULT+2, AX		; Store the second multiplication
	
	MOV AL, [SI]+4				; Fiveth element
	MOV BL, [SI]+5				; Sixth element
	IMUL BL
	MOV TMP_RESULT+4, AX		; Store the third multiplication
    
    ; Multiply the first part of the result
    ; 16 bit * 16 bit multiplication
    MOV AX, TMP_RESULT			; First partial result
    MOV BX, TMP_RESULT+2		; Second partial result
    IMUL BX
    MOV TMP_RESULT, DX			; Higher part
    MOV TMP_RESULT+2, AX		; Lower part
    
    ; Check the sign
    MOV CL, 0					; Count the number of negative operands
    TEST WORD PTR TMP_RESULT, 8000h	; Test the first bit (sign)
    JZ H_POS					; If result is zero, number is positive
    ; The operand is negative
	; Change representation and store the 'negativity'
	INC CL						; Count negative operand
	XOR TMP_RESULT+2, 0FFFFh	; Change all bits
	XOR TMP_RESULT, 0FFFFh
	INC TMP_RESULT+2
	ADC TMP_RESULT, 0   
	H_POS:						; Here when operand is positive
	; Now, test the lower part
	TEST WORD PTR TMP_RESULT+4, 8000h	; Test the first bit (sign)
	JZ L_POS
	XOR TMP_RESULT+4, 0FFFFh
	INC TMP_RESULT+4
	INC CL
	L_POS:
	; Both operands are now positive
	MOV AX, TMP_RESULT+4
	MUL TMP_RESULT+2
	MOV [DI]+4, AX				; Final lower part
	MOV [DI]+2, DX				; Tmp middle part
	MOV AX, TMP_RESULT+4
	MUL TMP_RESULT
	ADD [DI]+2, AX				; Final middle part
	ADC DX, 0
	MOV [DI], DX				; Final higher part
	
	TEST CL, 01H				; Test LSB
	JZ POS_SIGN
	; Operand must be negative
	XOR [DI]+4, 0FFFFh
	XOR [DI]+2, 0FFFFh
	XOR [DI], 0FFFFh
	INC WORD PTR [DI]+4
	ADC WORD PTR [DI]+2, 0		
	ADC WORD PTR [DI], 0	
    POS_SIGN:
	POPA
	POP BP
	RET                   
MULTIPLY_ARRAY ENDP

LARGEST_VALUE PROC
	PUSHA
	; Upper parts
	MOV AX, WORD PTR MULT_A
	CMP AX, WORD PTR MULT_B
	JL	LARGEST2
	JG	LARGEST1
	; If equals, middle parts
	MOV AX, WORD PTR MULT_A+2
	CMP AX, WORD PTR MULT_B+2
	JL	LARGEST2
	JG	LARGEST1
	; If equals, lower parts
	MOV AX, WORD PTR MULT_A+4
	CMP AX, WORD PTR MULT_B+4
	JL	LARGEST2
	JG	LARGEST1
	LEA DX, S_EQUAL
	JMP END_LARGEST
LARGEST1:
	LEA DX, S_LARGEST1
	JMP END_LARGEST
LARGEST2:
	LEA DX, S_LARGEST2
END_LARGEST:
	MOV AH, 9
	INT 21H	
	
	POPA
	RET
LARGEST_VALUE ENDP

LARGEST_ABS_VALUE PROC
	PUSHA
	; First, move the results into new variables
	MOV AX, WORD PTR MULT_A
	MOV WORD PTR MULT_ABS_A, AX
	MOV AX, WORD PTR MULT_A+2
	MOV WORD PTR MULT_ABS_A+2, AX
	MOV AX, WORD PTR MULT_A+4
	MOV WORD PTR MULT_ABS_A+4, AX	
	
	MOV AX, WORD PTR MULT_B
	MOV WORD PTR MULT_ABS_B, AX
	MOV AX, WORD PTR MULT_B+2
	MOV WORD PTR MULT_ABS_B+2, AX
	MOV AX, WORD PTR MULT_B+4
	MOV WORD PTR MULT_ABS_B+4, AX
	
	; Then, convert both numbers in pure binary		
	TEST WORD PTR MULT_ABS_A, 8000H		; Test MSB
	JZ A_POS_SIGN
	; Operand must be negative
	XOR WORD PTR MULT_ABS_A+4, 0FFFFh
	XOR WORD PTR MULT_ABS_A+2, 0FFFFh
	XOR WORD PTR MULT_ABS_A, 0FFFFh
	INC WORD PTR MULT_ABS_A+4
	ADC WORD PTR MULT_ABS_A+2, 0		
	ADC WORD PTR MULT_ABS_A, 0	
    A_POS_SIGN:
	; Proceed with the second number
	TEST WORD PTR MULT_ABS_B, 8000H		; Test MSB
	JZ B_POS_SIGN
	; Operand must be negative
	XOR WORD PTR MULT_ABS_B+4, 0FFFFh
	XOR WORD PTR MULT_ABS_B+2, 0FFFFh
	XOR WORD PTR MULT_ABS_B, 0FFFFh
	INC WORD PTR MULT_ABS_B+4
	ADC WORD PTR MULT_ABS_B+2, 0		
	ADC WORD PTR MULT_ABS_B, 0	
    B_POS_SIGN:

	; Finally, compare the numbers
		; Upper parts
	MOV AX, WORD PTR MULT_ABS_A
	CMP AX, WORD PTR MULT_ABS_B
	JL	LARGEST_ABS2
	JG	LARGEST_ABS1
	; If equals, middle parts
	MOV AX, WORD PTR MULT_ABS_A+2
	CMP AX, WORD PTR MULT_ABS_B+2
	JL	LARGEST_ABS2
	JG	LARGEST_ABS1
	; If equals, lower parts
	MOV AX, WORD PTR MULT_ABS_A+4
	CMP AX, WORD PTR MULT_ABS_B+4
	JL	LARGEST_ABS2
	JG	LARGEST_ABS1
	LEA DX, S_ABSEQUAL
	JMP END_LARGEST_ABS
LARGEST_ABS1:
	LEA DX, S_ABSLARGEST1
	JMP END_LARGEST
LARGEST_ABS2:
	LEA DX, S_ABSLARGEST2
END_LARGEST_ABS:
	MOV AH, 9
	INT 21H	
	
	POPA
	RET
LARGEST_ABS_VALUE ENDP	

END