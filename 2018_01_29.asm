; 251102 Franco Enrico
; Politecnico di Torino
; 02LSEOV - Computer Architectures
; 29th January 2018

.MODEL SMALL
.STACK
.DATA
; Database
N EQU 12
OBJ_PRICES DW 15000, 13000, 13000, 10000, 9999, 7001, 5000, 4999, 2099, 1999, 1000, 1000
; Output
TOTAL_PURCHASED DW ?
PERC_DISCOUNT DB ?
; Input
N_BUY DB ?
PRODUCTS DB 4 DUP (?)
; Jump table implementing switch-case menu
MENU_JT DW OPTIONA_LABEL, OPTIONB_LABEL, OPTIONC_LABEL, OPTIOND_LABEL, OPTIONE_LABEL, REINSERT, TERMINATE
; Strings
S_INSERT_NBUY DB 'Insert the number of products bought: ', '$'
S_NBUY_NEGATIVE DB 'Number of products can not be negative! Please reinsert: ', '$'
S_NBUY_TOOHIGH DB 'Number of products can not be greater than 4! Please reinsert: ', '$'
S_PRODUCTCODE_NEGATIVE DB 'Product code can not be negative! Please reinsert.', '$'
S_PRODUCTCODE_TOOHIGH DB 'Product code too high! Please reinsert.', '$'
S_INSERT_PRODUCTCODE DB 'Insert the code of the product purchased: ', '$'
S_PRINT_TOTALPURCHASED DB 'Total purchased (in cents): ', '$'
S_PRINT_PERCDISCOUNT DB 'Discount percentage: ', '$'
S_PRINT_PERCDISCOUNT_NEG DB 'Actually, you do not achieved any discount but a fantastic surcharge!', '$'
S_MENU	DB '1. Option A', 10, 13
		DB '2. Option B', 10, 13
		DB '3. Option C', 10, 13
		DB '4. Option D', 10, 13
		DB '5. Option E', 10, 13
		DB '6. Reinsert', 10, 13
		DB '7. Exit', 10, 13
		DB 'Please, insert your choice: ', '$'
S_INVALIDCHOICE DB 'Invalid choice, please insert a valid one.', 10, 13, '$'
S_ENDPROGRAM DB 'End of the program. Thank you.', '$'		
S_ENDLINE DB 10, 13, '$'

.CODE
.STARTUP
MAIN:
	; Input
	LEA DX, S_INSERT_NBUY
	MOV AH, 9
	INT 21H
INPUT_NBUY_LOOP:	
	MOV BX, 1									; Number on 2 bit maximum
	PUSH BX
	CALL READ_DECIMAL
	POP BX
	CMP BL, 0
	JG N_BUY_POSITIVE
	; N_BUY <= 0
	; Print an error message
	CALL PRINT_ENDLINE
	LEA DX, S_NBUY_NEGATIVE
	MOV AH, 9
	INT 21H
	JMP INPUT_NBUY_LOOP
	N_BUY_POSITIVE:
	CMP BL, 4
	JBE N_BUY_OK
	; N_BUY > 4
	; Print an error message
	CALL PRINT_ENDLINE
	LEA DX, S_NBUY_TOOHIGH
	MOV AH, 9
	INT 21H
	JMP INPUT_NBUY_LOOP
	N_BUY_OK:
	MOV N_BUY, BL
    
    ; Input array of produts
	MOV CL, N_BUY
	XOR CH, CH
	XOR DI, DI
	
INPUT_PRODUCTS_LOOP:
	; Print a message
	CALL PRINT_ENDLINE
	LEA DX, S_INSERT_PRODUCTCODE
	MOV AH, 9
	INT 21H
	MOV BX, 2									; Number on 2 bit maximum
	PUSH BX
	CALL READ_DECIMAL
	POP BX
	CMP BL, 0
	JGE PRODUCTCODE_POSITIVE
	; PRODUCT_CODE < 0
	; Print an error message
	CALL PRINT_ENDLINE
	LEA DX, S_PRODUCTCODE_NEGATIVE
	MOV AH, 9
	INT 21H
	JMP INPUT_PRODUCTS_LOOP
	PRODUCTCODE_POSITIVE:
	CMP BL, N
	JB PRODUCTCODE_OK
	; N_BUY >= N
	; Print an error message
	CALL PRINT_ENDLINE
	LEA DX, S_PRODUCTCODE_TOOHIGH
	MOV AH, 9
	INT 21H
	JMP INPUT_PRODUCTS_LOOP
	PRODUCTCODE_OK:
	MOV PRODUCTS[DI], BL
	INC DI
	LOOP INPUT_PRODUCTS_LOOP 
    
MENU_LOOP:
	; Init variables
	MOV TOTAL_PURCHASED, 0
	MOV PERC_DISCOUNT, 0
	; Print menu
	CALL PRINT_ENDLINE
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
	CMP AL, 7
	JA INVALID_CHOICE
	; If it is valid, use the jump table
	DEC AL
	XOR BH, BH
	MOV BL, AL
	SHL BX, 1									; BX = BX*2
	JMP MENU_JT[BX]
	OPTIONA_LABEL:
		CALL OPTIONA   
		; Print results
		CALL PRINT_RESULTS
		JMP MENU_LOOP
	OPTIONB_LABEL:
		CALL OPTIONB
		; Print results
		CALL PRINT_RESULTS
		JMP MENU_LOOP
	OPTIONC_LABEL:
		CALL OPTIONC
		; Print results
		CALL PRINT_RESULTS
		JMP MENU_LOOP
	OPTIOND_LABEL:
		CALL OPTIOND
		; Print results
		CALL PRINT_RESULTS
		JMP MENU_LOOP
	OPTIONE_LABEL:
		CALL OPTIONE
		; Print results
		CALL PRINT_RESULTS
		JMP MENU_LOOP
	REINSERT:
		CALL PRINT_ENDLINE
		JMP MAIN	
	INVALID_CHOICE:
		CALL PRINT_ENDLINE
		MOV AH, 9
		LEA DX, S_INVALIDCHOICE
		INT 21H
		JMP MENU_LOOP 
	TERMINATE:
		CALL PRINT_ENDLINE
		MOV AH, 9
		LEA DX, S_ENDPROGRAM
		INT 21H
.EXIT

; Minimum purchase: 2 products
; Pay the most expensive products at its full price and the least expensive with 50% of discount
OPTIONA PROC
	PUSHA
	MOV AX, 0								; Used to contain the discount
	MOV SI, 1
	MOV CL, N_BUY
	XOR CH, CH
	CMP CX, 1
	JBE TOTAL_OPTIONA						; If N_BUY <= 1, no discount
	; Here if N_BUY > 1
	; Search the minimum and save the index (product number)
	; Min price corresponds to highest product number
	MOV BL, PRODUCTS[0]
	DEC CX									; First item considered in the previous line
	MINPRICE_LOOPA:
		CMP BL, PRODUCTS[SI]				; Current max product number
		JA NEXTELEM_LOOPA					; If higher, no update
		; Higher product number found
		MOV BL, PRODUCTS[SI]
		NEXTELEM_LOOPA:
		INC SI
		LOOP MINPRICE_LOOPA
	; BL contains the index of the product with min price
	XOR BH, BH
	SHL BX, 1								; Array OBJ_PRICES stores WORD, so I need a multiplication by 2 for its index
	MOV AX, OBJ_PRICES[BX]
	SHR AX, 1								; AX contains the discount
	
	TOTAL_OPTIONA:
	XOR CH, CH
	MOV CL, N_BUY							; Number of loops
	XOR BH, BH
	XOR DI, DI
	MOV TOTAL_PURCHASED, 0
	TOTAL_OPTIONA_LOOP:
		MOV BL, PRODUCTS[DI]				; Index of the product
		SHL BX, 1							; Array OBJ_PRICES stores WORD, so I need a multiplication by 2 for its index
		MOV DX, OBJ_PRICES[BX]				; Price
		ADD TOTAL_PURCHASED, DX
		INC DI
		LOOP TOTAL_OPTIONA_LOOP
	
	MOV BX, TOTAL_PURCHASED
	SUB TOTAL_PURCHASED, AX					; Discount
	; Computer discount percentage
	MOV CX, 100
	MUL CX
	DIV BX
	MOV PERC_DISCOUNT, AL
	POPA
	RET
OPTIONA ENDP

; Minimum purchase: 2 products
; Pay the most expensive product with a surcharge of 25% and get the least expensive for free
OPTIONB PROC
	PUSHA
	MOV AX, 0								; Used to contain the discount
	CMP N_BUY, 1
	JBE TOTAL_OPTIONB						; If N_BUY <= 1, no discount
	; Here if N_BUY > 1
	MOV CL, N_BUY
	XOR CH, CH
	; Search the minimum and save the index (product number)
	; Min price corresponds to highest product number
	; Max price corresponds to lowest product number
	MOV DH, PRODUCTS[0]						; DH contains the lowest code (highest price)
	MOV DL, DH								; DL contains the highest code (lowest price)
	DEC CX
	MOV SI, 1
	MINMAX_LOOPB:
		CMP DL, PRODUCTS[SI]
		JAE CHECK_MAX_OPTIONB
		; Higher product number found
		MOV DL, PRODUCTS[SI]
		CHECK_MAX_OPTIONB:
		CMP DH, PRODUCTS[SI]
		JBE NEXTELEM_OPTIONB
		; Lower product number found
		MOV DH, PRODUCTS[SI]
		NEXTELEM_OPTIONB:
		INC SI
		LOOP MINMAX_LOOPB
	MOV BL, DL								; DL contains the highest code -> Lowest price
	XOR BH, BH
	SHL BX, 1								; Array OBJ_PRICES stores WORD, so I need a multiplication by 2 for its index
	MOV AX, OBJ_PRICES[BX]                  ; Total discount for product with the lowest price
	MOV BL, DH                              ; DH contains the lowest code -> Highest price
	SHL BX, 1								; Array OBJ_PRICES stores WORD, so I need a multiplication by 2 for its index
	MOV CX, OBJ_PRICES[BX]
	SHR CX, 2								; Division by 4 -> 25% surcharge
	SUB AX, CX								; CX contains a surcharge, not a discount
	
	TOTAL_OPTIONB:
	XOR CH, CH
	MOV CL, N_BUY
	XOR BH, BH
	XOR DI, DI
	MOV TOTAL_PURCHASED, 0
	TOTAL_OPTIONB_LOOP:
		MOV BL, PRODUCTS[DI]
		SHL BX, 1							; Array OBJ_PRICES stores WORD, so I need a multiplication by 2 for its index
		MOV DX, OBJ_PRICES[BX]
		ADD TOTAL_PURCHASED, DX
		INC DI
		LOOP TOTAL_OPTIONB_LOOP
	
	MOV BX, TOTAL_PURCHASED
	SUB TOTAL_PURCHASED, AX
	
	CMP AX, 0
	JL DISCOUNT_NEG
	; AX >= 0, compute percentage
	MOV CX, 100
	MUL CX
	DIV BX
	MOV PERC_DISCOUNT, AL
	JMP END_OPTIONB
	DISCOUNT_NEG:
		MOV PERC_DISCOUNT, 0FFh				; In this way, I can identify a negative discount and print a string
	
	END_OPTIONB:
	POPA
	RET
OPTIONB ENDP

; Minimum purchase: 4 products
; Get the flat discount of 12.5% over the full purchase
OPTIONE PROC
	; Compute the total purchase. Then, if N_BUY = 4, apply the discount
	PUSHA
	XOR BH, BH
	MOV CL, N_BUY
	XOR CH, CH
	XOR DI, DI
	MOV TOTAL_PURCHASED, 0
	TOTAL_OPTIONE_LOOP:
		MOV BL, PRODUCTS[DI]
		SHL BX, 1
		MOV DX, OBJ_PRICES[BX]
		ADD TOTAL_PURCHASED, DX
		INC DI
		LOOP TOTAL_OPTIONE_LOOP
	MOV PERC_DISCOUNT, 0
	CMP N_BUY, 4
	JB END_OPTIONE
	; N_BUY = 4
	MOV AX, TOTAL_PURCHASED
	MOV BX, AX
	SHR AX, 3								; 12.5 %
	SUB TOTAL_PURCHASED, AX
	MOV CX, 100
	MUL CX
	DIV BX
	MOV PERC_DISCOUNT, AL
	END_OPTIONE:
	POPA
	RET
OPTIONE ENDP

; Minimum purchase: 3 products
; Pay the most expensive product with 6.25% of discount, the second most expensive with 12.5% and the least expensive with 25% of discount
OPTIOND PROC
	PUSHA
	MOV AX, 0
	CMP N_BUY, 2
	JBE TOTAL_OPTIOND
	
	; Sort product array in ascending order on product code. So, on descending order on price
	CALL SORT_ARRAY
	
	MOV BL, N_BUY
	XOR BH, BH
	DEC BX									; Last element is the cheapest
	MOV CL, PRODUCTS[BX]					; Index of the cheapest product
	MOV BL, CL
	SHL BX, 1
	MOV AX, OBJ_PRICES[BX]
	SHR AX, 2								; 25 %
	
	MOV BL, PRODUCTS[0]						; Index of the most expensive
	SHL BX, 1
	MOV CX, OBJ_PRICES[BX]
	SHR CX, 4								; 6.25 %
	ADD AX, CX
	
	; Now search the second most expensive. Which is the first with code different from PRODUCTS[0], if it exists	
	MOV DL, PRODUCTS[0]
	MOV CL, N_BUY
	DEC CL
	XOR CH, CH
	MOV DI, 1
	CHECK_SECONDMAX_LOOP:
		CMP DL, PRODUCTS[DI]
		JNE SECONDMAX_FOUND
		INC DI
		LOOP CHECK_SECONDMAX_LOOP
	; Here, no second max exists. So not consider a contribution for the discount
	JMP TOTAL_OPTIOND
	
	SECONDMAX_FOUND:
	; Get the price of the product and discount
	MOV BL, PRODUCTS[DI]
	XOR BH, BH
	SHL BX, 1
	MOV CX, OBJ_PRICES[BX]
	SHR CX, 3								; 12.5 %
	ADD AX, CX	
	
	TOTAL_OPTIOND:
	MOV CL, N_BUY
	XOR CH, CH
	XOR BH, BH
	XOR DI, DI
	MOV TOTAL_PURCHASED, 0
	TOTAL_OPTIOND_LOOP:
		MOV BL, PRODUCTS[DI]
		SHL BX, 1
		MOV DX, OBJ_PRICES[BX]
		ADD TOTAL_PURCHASED, DX
		INC DI
		LOOP TOTAL_OPTIOND_LOOP
	
	MOV BX, TOTAL_PURCHASED
	SUB TOTAL_PURCHASED, AX
	; Computer discount percentage
	MOV CX, 100
	MUL CX
	DIV BX
	MOV PERC_DISCOUNT, AL
	POPA
	RET
OPTIOND ENDP

; Minimum purchase: 2 products
; Pay the most expensive product with a 12.5% of discount and the least expensive for with 25% of discount
OPTIONC PROC
	PUSHA
	MOV AX, 0								; Used to contain the discount
	CMP N_BUY, 1
	JBE TOTAL_OPTIONC						; If N_BUY <= 1, no discount
	; Here if N_BUY > 1
	MOV CL, N_BUY
	XOR CH, CH
	; Search the minimum and save the index (product number)
	; Min price corresponds to highest product number
	; Max price corresponds to lowest product number
	MOV DH, PRODUCTS[0]						; DH contains the lowest code (highest price)
	MOV DL, DH								; DL contains the highest code (lowest price)
	DEC CX
	MOV SI, 1
	MINMAX_LOOPC:
		CMP DL, PRODUCTS[SI]
		JAE CHECK_MAX_OPTIONC
		; Higher product number found
		MOV DL, PRODUCTS[SI]
		CHECK_MAX_OPTIONC:
		CMP DH, PRODUCTS[SI]
		JBE NEXTELEM_OPTIONC
		; Lower product number found
		MOV DH, PRODUCTS[SI]
		NEXTELEM_OPTIONC:
		INC SI
		LOOP MINMAX_LOOPC
	MOV BL, DL								; DL contains the highest code -> Lowest price
	XOR BH, BH
	SHL BX, 1								; Array OBJ_PRICES stores WORD, so I need a multiplication by 2 for its index
	MOV AX, OBJ_PRICES[BX]                  ; Lowest price
	SHR AX, 2								; Division by 4 -> 25% discount
	MOV BL, DH                              ; DH contains the lowest code -> Highest price
	SHL BX, 1								; Array OBJ_PRICES stores WORD, so I need a multiplication by 2 for its index
	MOV CX, OBJ_PRICES[BX]                  ; Highest price
	SHR CX, 3								; Division by 8 -> 12.5% surcharge
	ADD AX, CX
	
	TOTAL_OPTIONC:
	MOV CL, N_BUY
	XOR CH, CH
	XOR DI, DI
	XOR BH, BH
	TOTAL_OPTIONC_LOOP:
		MOV BL, PRODUCTS[DI]
		SHL BX, 1
		MOV DX, OBJ_PRICES[BX]
		ADD TOTAL_PURCHASED, DX
		INC DI
		LOOP TOTAL_OPTIONC_LOOP
	
	MOV BX, TOTAL_PURCHASED
	SUB TOTAL_PURCHASED, AX					; Discount
	; Computer discount percentage
	MOV CX, 100
	MUL CX
	DIV BX
	MOV PERC_DISCOUNT, AL
	POPA
	RET
OPTIONC ENDP

PRINT_RESULTS PROC
	PUSHA
	CALL PRINT_ENDLINE
	LEA DX, S_PRINT_TOTALPURCHASED
	MOV AH, 9
	INT 21H
	PUSH TOTAL_PURCHASED
	CALL PRINT_DECIMAL
	POP BX									; Dummy pop
	
	CMP PERC_DISCOUNT, 0
	JL PRINT_PERCDISCOUNT_NEG
	; Discount percentage is positive, so print it
	LEA DX, S_PRINT_PERCDISCOUNT
	MOV AH, 9
	INT 21H
	MOV BL, PERC_DISCOUNT
	XOR BH, BH
	PUSH BX
	CALL PRINT_DECIMAL
	POP BX									; Dummy pop
	JMP END_PRINT_RESULT
	PRINT_PERCDISCOUNT_NEG:
	LEA DX, S_PRINT_PERCDISCOUNT_NEG
	MOV AH, 9
	INT 21H
	CALL PRINT_ENDLINE
 	END_PRINT_RESULT:
	POPA
	RET
PRINT_RESULTS ENDP

SORT_ARRAY PROC
	PUSHA
	SORT_OUTER_LOOP:				; Outer loop
		MOV DL, 1					; DL is a flag, which tells us if at least one swap has
									; been performed in the inner loop
		MOV CL, N_BUY				; CX is initialized with the length of the array
		XOR CH, CH
		DEC CX						; Last element has not to be checked
		XOR DI, DI					; DI is initialized to the first item
		SORT_INNER_LOOP:			; Inner loop
		MOV AH, PRODUCTS[DI]        ; Transfer memory data into registers
        
        ; Make comparisons
        CMP PRODUCTS[DI+1], AH
		JAE SORT_CONTINUE			; PRODUCTS[DI] <= PRODUCTS[DI+1], no swap required
		SWAP_ITEMS:
		XCHG PRODUCTS[DI+1], AH
		MOV PRODUCTS[DI], AH		; Swap performed
		XOR DL, DL					; DL=0: one swap has been performed
		SORT_CONTINUE:
		INC DI						; Go to the next element of the array
		LOOP SORT_INNER_LOOP
		CMP DL, 0					; If (DL=0) then at least one swap has been performed
		JE SORT_OUTER_LOOP			; therefore continue with the outer loop
		; Else no swaps performed ­> all the items are in order ­> the sorting ends.
	POPA
	RET	
SORT_ARRAY ENDP

; Procedure to read a decimal number up to 65'536 (16 bits)
; Number of digits is read from the stack, 
; so it must be pushed before the procedure call
; Procedure will provide the decimal number stored in the stack,
; so it must be popped after the procedure call
READ_DECIMAL PROC
	PUSH BP
	MOV BP, SP
	PUSHA
	MOV CX, [BP+4]				; Max number of digits to be read
	MOV DX, 0
READ_LOOP:
	MOV AH, 1
	INT 21H
	CMP AL, 13					; 13 = End Line
	JE END_READ_LOOP			; If 'Enter' is pressed, end reading

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
PRINT_DECIMAL PROC
	PUSH BP
	MOV BP, SP
	PUSHA
	MOV AX, [BP+4]
	MOV BX, 10					; Divisor
	XOR DX, DX
	XOR CX, CX
	
	;Splitting process starts here
DLOOP1:
	XOR DX, DX					; Clear DX
	DIV BX
	PUSH DX						; Push the digit
	INC CX						; Increments the number of digits
	CMP AX, 0					; Checks if there something else to divide
	JNE DLOOP1
	
DLOOP2:
	POP DX						; Pop the digit
	ADD DX, 30H					; ASCII conversion
	MOV AH, 02H					; Identification code     
	INT 21H
	LOOP DLOOP2
	
	LEA DX, S_ENDLINE
	MOV AH, 9
	INT 21H
	
	POP BP
	POPA	
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

; 29th January 2018
; 02LSEOV - Computer Architectures
; Politecnico di Torino
; 251102 Franco Enrico