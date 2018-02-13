; Computer Architectures
; Lab 02
MIN_LENGHT	EQU	20
MAX_LENGHT	EQU	50
CHARS_NUMBER	EQU	26*2	; Chars number

	.MODEL small
	.STACK
	.DATA
		SHORT_STR_ERR	DB	"String is too short", 0Ah, 0Dh, '$'
		LONG_STR_ERR	DB	"String is too long", 0Ah, 0Dh, '$'
		ENDLINE	DB	0Ah, 0Dh, '$'	; Endline + Carriage Return
		FIRST_ROW	DB	MAX_LENGHT, MAX_LENGHT+1 DUP (?)
		SECOND_ROW	DB	MAX_LENGHT, MAX_LENGHT+1 DUP (?)
		THIRD_ROW	DB	MAX_LENGHT, MAX_LENGHT+1 DUP (?)
		FOURTH_ROW	DB	MAX_LENGHT, MAX_LENGHT+1 DUP (?)
		COUNTER_ROW	DB	CHARS_NUMBER DUP (?)	; Characters counter, re-used for each row
		COUNTER_OVERALL	DB	CHARS_NUMBER DUP (?)	; Characters counter
		FIRST_ROW_CIPHERED	DB	MAX_LENGHT, MAX_LENGHT+1 DUP (?)
		SECOND_ROW_CIPHERED	DB	MAX_LENGHT, MAX_LENGHT+1 DUP (?)
		THIRD_ROW_CIPHERED	DB	MAX_LENGHT, MAX_LENGHT+1 DUP (?)
		FOURTH_ROW_CIPHERED	DB	MAX_LENGHT, MAX_LENGHT+1 DUP (?)
		K	DB	?	
	.CODE              
	.STARTUP
	; Request 1
	MOV BX, OFFSET FIRST_ROW
	PUSH BX
	CALL INPUT_STRING
	POP BX
	
	MOV BX, OFFSET SECOND_ROW
	PUSH BX
	CALL INPUT_STRING
	POP BX
	
	MOV BX, OFFSET THIRD_ROW
	PUSH BX
	CALL INPUT_STRING
	POP BX           
	
	MOV BX, OFFSET FOURTH_ROW
	PUSH BX
	CALL INPUT_STRING
	POP BX
	
	JMP four
	
	; Request 2
	; Reset the global counter
	LEA SI, COUNTER_OVERALL
	MOV CX, CHARS_NUMBER
reset_global_counter:
	MOV BYTE PTR [SI], 0
	INC SI
	LOOP reset_global_counter
	; End of reset phase
		
	MOV BX, OFFSET FIRST_ROW
	PUSH BX
	CALL COUNT_CHARS
	POP BX
	
	MOV BX, OFFSET SECOND_ROW
	PUSH BX
	CALL COUNT_CHARS
	POP BX
	
	MOV BX, OFFSET THIRD_ROW
	PUSH BX
	CALL COUNT_CHARS
	POP BX
	
	MOV BX, OFFSET FOURTH_ROW
	PUSH BX
	CALL COUNT_CHARS
	POP BX
	
	; Request 3
	CALL MOST_FREQUENT_CHAR

four:	
	; Request 4
	MOV BX, OFFSET FIRST_ROW
	PUSH BX
	MOV K, 3
	XOR CH, CH
	MOV CL, K
	PUSH CX
	CALL CIPHER_ROW
	POP CX
	POP BX
	
	
	
	.EXIT
	
INPUT_STRING	PROC	NEAR
	; Parameter 1: Array address
	PUSH BP
	MOV BP, SP
	PUSH AX
	PUSH BX
	PUSH DX
input:	MOV AH, 0AH	; Input buffer mode
	MOV DX, [BP]+4	; Buffer address
	MOV BX, DX	
	INT 21H
	; Preparing to print endline - Layout stuff
	MOV AH, 9
	LEA DX, ENDLINE
	INT 21H
	; Check the string lenght	
	CMP BYTE PTR [BX]+1, MIN_LENGHT	; [BX]+1 -> #Chars read
	JB shortstr
	JMP inputok
shortstr:	LEA DX, SHORT_STR_ERR
		MOV AH, 9
		INT 21H	
		JMP input ; Force a new insert
inputok:
	POP DX
	POP BX
	POP AX
	POP BP
	RET
INPUT_STRING	ENDP
	
COUNT_CHARS	PROC	NEAR
	; Parameter 1: String address
	PUSH BP
	MOV BP, SP
	PUSH AX
	PUSH BX
	PUSH CX
	PUSH SI
	PUSH DI

	; Reset counter
	LEA SI, COUNTER_ROW
	MOV CX, CHARS_NUMBER
reset_row_counter:
	MOV BYTE PTR [SI], 0
	INC SI
	LOOP reset_row_counter
	; End of reset
	
	MOV BX, [BP]+4	; String address
	XOR CH, CH	; Higher part is not used
	MOV CL, [BX]+1	; String lenght
	XOR AX, AX	; AX is used in computation
	; First two bytes are MAX_LENGHT, USED_LENGHT
	INC BX
	INC BX
count:
	LEA SI, COUNTER_ROW	; Address of the array storing the counter for a single row
	LEA DI, COUNTER_OVERALL	; Address of the array storing the global counter
	MOV AL, [BX]	; The char will be manipulated, I use a register to speed up
	CMP AL, 'a'	
	JAE lowerc	; Elaborate lower char
	; ASCII lowercase characters appear after the uppercase ones.
	AND AL, 1FH     ; A -> 41h. I use a mask to remove the "upper part"
	ADD AL, 25	; Index adapting. Uppercase is after the lower case in my array
	JMP endc
lowerc:
	AND AL, 1FH	; a -> 61h. I use a mask to remove the "upper part"
	DEC AL		; Index adapting
endc:
	ADD SI, AX	; AX contains the 'index' of the char
	ADD DI, AX
	INC [SI]	; Simply count the character
	INC	[DI]	 
	INC BX
	LOOP count
	
	; Search maximum
	MOV AL, COUNTER_ROW ; Stores the maximum
	LEA SI, COUNTER_ROW+1	; Runs throught the occurency vector
	MOV CX, CHARS_NUMBER-1	; One position used to save the initial max
	
search_max:
	CMP [SI], AL 
	JB continue	; If below, continue
	MOV AL, [SI]	; Stores the new max
continue:
	INC SI
	LOOP search_max
	; AL contains the maximum, I'm interested on the half value
	SHR AL, 1
	
	MOV AH, 02H	; Display a char
	LEA SI, COUNTER_ROW	
	MOV CX, 26	; Lowercase char	
	XOR BX, BX
	; BX contains the offset in the string. 
	; Used to retrieve the corresponding ASCII char
check_lower_char:
	CMP [SI][BX], AL
	JNE continue_check_lower_char
	MOV DX, BX	; DL is used to print a char
	ADD DL, 'a'	; ASCII lowercase offset
	PUSH AX
	INT 21H		; Write DL content into AL. Why? Not written in the interrupt table
				; Push/Pop needed to store AL (AX) content.
	POP AX		
continue_check_lower_char:
	INC BX
	LOOP check_lower_char
	
	MOV AH, 02H	; Display a char
	LEA SI, COUNTER_ROW+25	; Starting from uppercase	
	MOV CX, 26	; Uppercase char	
	XOR BX, BX
	; BX contains the offset in the string. 
	; Used to retrieve the corresponding ASCII char
check_upper_char:
	CMP [SI][BX], AL
	JNE continue_check_upper_char
	MOV DX, BX	; DL is used to print a char
	ADD DL, 'A'	; ASCII uppercase offset
	PUSH AX
	INT 21H		; Write DL content into AL. Why? Not written in the interrupt table
				; Push/Pop needed to store AL (AX) content.
	POP AX		
continue_check_upper_char:
	INC BX
	LOOP check_upper_char		
	
	POP DI		
	POP SI
	POP CX
	POP BX
	POP AX
	POP BP
	RET
COUNT_CHARS	ENDP

MOST_FREQUENT_CHAR PROC
	PUSH SI
	PUSH DI
	PUSH AX
	PUSH BX
	PUSH CX
	PUSH DX
	
	; Search maximum
	LEA DI, COUNTER_OVERALL ; Stores the address of the maximum
	LEA SI, COUNTER_OVERALL+1	; Runs throught the occurency vector
	MOV CX, CHARS_NUMBER-1	; One position used to save the initial max	
search_max_overall:
	MOV AL, [DI]	; Cannot compare two memory cells
	CMP [SI], AL 
	JB continue_overall	; If below, continue
	MOV DI, SI	; Stores the address of the new max
continue_overall:
	INC SI
	LOOP search_max_overall
	; DI contains the address of the maximum
	
	LEA SI, COUNTER_OVERALL
	SUB DI, SI	; I obtain the offset, the position
	MOV DX, DI
	CMP DL, 25	; Check if lowercase/uppercase
	JA	uppercase_char
	ADD DL, 'a'
	JMP print_char
uppercase_char:
	SUB DL, 26	; Upperchars start from index 26
	ADD DL, 'A'
print_char:
	MOV AH, 02H	; Print single char
	INT 21H
		
	POP DX	
	POP CX
	POP BX
	POP AX
	POP DI
	POP SI
	RET		
MOST_FREQUENT_CHAR ENDP

CIPHER_ROW	PROC
	; Parameter 1: String address
	; Parameter 2: Key
	PUSH BP
	MOV BP, SP
	PUSH SI
	PUSH BX
	PUSH CX
	
	MOV SI, [BP]+6	; String address
	MOV BX, [BP]+4	; Key
	XOR CH, CH
	MOV CL, [SI]+1	; String lenght
	ADD SI, 2		; First char
	
cipher:
	MOV AL, [SI]	; Transfer the char on chip, in order to speed up
					; Because multiple operations are needed
	CMP AL, 'A'
	JB continue_cipher	; Not a cipherable char
	CMP AL, 'Z'
	JBE cipher_upper
	CMP AL, 'a'
	JB continue_cipher	; Not a cipherable char
	CMP AL, 'z'
	JBE cipher_lower
	JMP continue_cipher	; Not a cipherable char
		
cipher_upper:
	ADD AL, BL	; Add the offset
	CMP AL, 'Z'
	JBE	continue_cipher
	; Char > 'Z' -> Out of bound
	; I need to map it into a lowercase char
	SUB AL, 'Z'		
	ADD AL, 'a'-1	; Minus 1 to mantain the correct offset
	JMP continue_cipher
	
cipher_lower:
	ADD AL, BL
	CMP AL, 'z'
	JBE continue_cipher
	; Char > 'z' -> Out of bound
	; I need to map it into an uppercase char
	SUB AL, 'z'
	ADD AL, 'A'-1	; Minus 1 to mantain the correct offset

continue_cipher:
	MOV [SI], AL
	INC SI	
	LOOP cipher	
	
	POP CX
	POP BX
	POP SI	
	POP BP
	RET
CIPHER_ROW	ENDP
		
	END