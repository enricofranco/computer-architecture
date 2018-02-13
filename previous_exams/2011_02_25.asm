.MODEL SMALL
.STACK

.DATA
	NUMBER_ATHLETES EQU 8
	TIMES DB 00000110B ,01101110B,01100110B , 00000101B ,01001011B,00010101B , 00000011B ,00111111B,11011100B , 00000010B ,00101111B,10010100B , 00000111B ,01011111B,10110011B , 00000000B ,00101111B,01110011B , 00000001B ,10101011B,01101011B , 00000100B ,00000111B,01000011B ; INPUT ARRAY
 	STANDINGS DB NUMBER_ATHLETES DUP (?, ?, ?) ; ARRAY FOR STANDINGS
	DIFF_PREV DW NUMBER_ATHLETES DUP (?) ; ARRAY FOR TIME DIFFERENCE FROM PREVIOUS ATHLETE
	DIFF_FIRST DW NUMBER_ATHLETES DUP (?) ; ARRAY FOR TIME DIFFERENCE FROM FIRST ATHLETE
	DIFF_WR DW ? ; TIME DIFFERENCE OF WINNER FROM WORLD RECORD
	WR DW 0000111101000011B ; CURRENT WORLD RECORD
	
	ATHL DB NUMBER_ATHLETES DUP (?)
	CSECS DB NUMBER_ATHLETES DUP (?)
	SECS DB NUMBER_ATHLETES DUP (?)
	MINS DB NUMBER_ATHLETES DUP (?)
	
.CODE
.STARTUP
MAIN:
	CALL UNPACK
	CALL SORT_ARRAY
	CALL PACK
	CALL CALC_DIFF_PREV
	CALL CALC_DIFF_FIRST
	CALL CALC_DIFF_WR
.EXIT

UNPACK PROC
	PUSHA
	MOV CX, NUMBER_ATHLETES
	XOR SI, SI
	XOR DI, DI
	UNPACK_LOOP:
		MOV BH, TIMES[SI]			; Athlete code
		MOV ATHL[DI], BH
		MOV AH, TIMES[SI+1]
		MOV AL, TIMES[SI+2]			; AX = CCCCCCCSSSSSSMMM
		MOV MINS[DI], AL			; AL = SSSSSMMM
		AND MINS[DI], 07h			; Save MMM
		SHR AX, 3					; AX = 000CCCCCCCSSSSSS
		MOV SECS[DI], AL			; AL = CCSSSSSS
		AND SECS[DI], 3Fh			; Save SSSSSS
		SHR AX, 6					; AX = 000000000CCCCCCC
		MOV CSECS[DI], AL			; AL = 0CCCCCCC
		AND CSECS[DI], 7Fh			; Save CCCCCCC
		ADD SI, 3					; Next element in TIME
		INC DI						; Next element in unpacked arrays
	LOOP UNPACK_LOOP
	POPA
	RET
UNPACK ENDP

PACK PROC
	PUSHA
	MOV CX, NUMBER_ATHLETES
	XOR SI, SI
	XOR DI, DI
	PACK_LOOP:
		MOV BH, ATHL[DI]
		MOV STANDINGS[SI], BH
		MOV AL, CSECS[DI]
		SHL AX, 6
		ADD AL, SECS[DI]
		SHL AX, 3
		ADD AL, MINS[DI]
		MOV STANDINGS[SI+1], AH
		MOV STANDINGS[SI+2], AL
		ADD SI, 3
		INC DI
	LOOP PACK_LOOP
	POPA
	RET
PACK ENDP

SORT_ARRAY PROC
	PUSHA
	SORT_OUTER_LOOP:				; Outer loop
		MOV DL, 1					; DL is a flag, which tells us if at least one swap has
									; been performed in the inner loop
		
		MOV CX, NUMBER_ATHLETES		; CX is initialized with the length of the array
		DEC CX						; Last element has not to be checked
		XOR DI, DI					; DI is initialized to the first item
		SORT_INNER_LOOP:			; Inner loop
		MOV AH, ATHL[DI]
		MOV AL, CSECS[DI]
		MOV BH, SECS[DI]
		MOV BL, MINS[DI]			; Transfer memory data into registers
        
        ; Make comparisons
        CMP MINS[DI+1], BL
		JA SORT_CONTINUE			; MINS[DI] < MINS[DI+1], no swap required
		JB SWAP_ITEMS				; MINS[DI] > MINS[DI+1], swap required
		;  MINS[DI] = MINS[DI+1],compare seconds 
		CMP SECS[DI+1], BH
		JA SORT_CONTINUE			; SECS[DI] < SECS[DI+1], no swap required
		JB SWAP_ITEMS				; SECS[DI] > SECS[DI+1], swap required
		;  SECS[DI] = SECS[DI+1],compare 100th seconds 
		CMP CSECS[DI+1], AL
		JA SORT_CONTINUE			; CSECS[DI] < CSECS[DI+1], no swap required
		; CSECS[DI] > CSECS[DI+1], swap required
		SWAP_ITEMS:
		XCHG ATHL[DI+1], AH
		MOV ATHL[DI], AH			; Athlete swap
		XCHG CSECS[DI+1], AL
		MOV CSECS[DI], AL			; 100th seconds swap
		XCHG SECS[DI+1], BH
		MOV SECS[DI], BH			; Seconds swap
		XCHG MINS[DI+1], BL
		MOV MINS[DI], BL		    ; Minutes swap
		XOR DL, DL					; DL=0: one swap has been performed
		SORT_CONTINUE:
		INC DI						; Go to the next element of the array
		LOOP SORT_INNER_LOOP
		CMP DL, 0					; If (DL=0) then at least one swap has been performed
		JE SORT_OUTER_LOOP			; therefore continue with the outer loop
		; else no swaps performed ­> all the items are in order ­> the sorting ends.
	POPA
	RET	
SORT_ARRAY ENDP

CALC_DIFF_PREV PROC
	PUSHA
	MOV DIFF_PREV[0], 0				; First athlete
	MOV CX, NUMBER_ATHLETES-1		; First athlete already considered
	MOV SI, 2						; Index of DIFF_PREV (Word array)
	MOV DI, 1						; Index of unpacked arrays (Byte arrays)
	DIFF_PREV_LOOP:
		MOV AH, SECS[DI]
		MOV AL, CSECS[DI]
		MOV BL, MINS[DI]
		SUB AL, CSECS[DI-1]
		CMP AL, 0					; Check for possible borrow
	 	JGE CSECS1_OK				; If subtraction > 0, no borrow is required
	 	; Manage borrow from SECS
	 	CMP AH, 1					; Check if there are seconds to subtract from
	 	JGE MINS_BORROW1_OK
	 	; No minutes available, require borrow from minutes
	 	DEC BL						; One minute used
	 	MOV AH, 60					; So 60 seconds are available
	 	MINS_BORROW1_OK:
	 	DEC AH						; One second used
	 	ADD AL, 100					; So 100 100th seconds are available
	 	CSECS1_OK:
	 	; Here, subtract seconds
	 	SUB AH, SECS[DI-1]
	 	CMP AH, 0					; Check for possible borrow
	 	JGE SECS1_OK				; If subtraction > 0, no borrow is required
	 	; Manage borrow from MINS
	 	DEC BL						; One minute used
	 	ADD AH, 60					; So 60 seconds are available
		SECS1_OK:
		SUB BL, MINS[DI-1]
		; Subtraction completed
		; Pack the result into the array
		MOV DL, AL					; 100th second
		SHL DX, 6
		ADD DL, AH					; Seconds
		SHL DX, 3
		ADD DL, BL					; Minutes
		MOV DIFF_PREV[SI], DX		; Store the result
		
		INC DI
		ADD SI, 2
		LOOP DIFF_PREV_LOOP
	POPA
	RET
CALC_DIFF_PREV ENDP	

CALC_DIFF_FIRST PROC
	PUSHA
	MOV DIFF_PREV[0], 0				; First athlete
	MOV CX, NUMBER_ATHLETES-1		; First athlete already considered
	MOV SI, 2						; Index of DIFF_PREV (Word array)
	MOV DI, 1						; Index of unpacked arrays (Byte arrays)
	DIFF_FIRST_LOOP:
		MOV AH, SECS[DI]
		MOV AL, CSECS[DI]
		MOV BL, MINS[DI]
		SUB AL, CSECS[0]
		CMP AL, 0					; Check for possible borrow
	 	JGE CSECS2_OK				; If subtraction > 0, no borrow is required
	 	; Manage borrow from SECS
	 	CMP AH, 1					; Check if there are seconds to subtract from
	 	JGE MINS_BORROW2_OK
	 	; No minutes available, require borrow from minutes
	 	DEC BL						; One minute used
	 	MOV AH, 60					; So 60 seconds are available
	 	MINS_BORROW2_OK:
	 	DEC AH						; One second used
	 	ADD AL, 100					; So 100 100th seconds are available
	 	CSECS2_OK:
	 	; Here, subtract seconds
	 	SUB AH, SECS[0]
	 	CMP AH, 0					; Check for possible borrow
	 	JGE SECS2_OK				; If subtraction > 0, no borrow is required
	 	; Manage borrow from MINS
	 	DEC BL						; One minute used
	 	ADD AH, 60					; So 60 seconds are available
		SECS2_OK:
		SUB BL, MINS[0]
		; Subtraction completed
		; Pack the result into the array
		MOV DL, AL					; 100th second
		SHL DX, 6
		ADD DL, AH					; Seconds
		SHL DX, 3
		ADD DL, BL					; Minutes
		MOV DIFF_FIRST[SI], DX		; Store the result
		
		INC DI
		ADD SI, 2
		LOOP DIFF_FIRST_LOOP
	POPA
	RET
CALC_DIFF_FIRST ENDP

CALC_DIFF_WR PROC
	PUSHA
	; Unpack world record in AX, BL
	MOV AX, WR
	MOV BL, AL
	AND BL, 07h						; Minutes
	SHR AX, 1						; 0CCCCCCC SSSSSSMM
	SHR AL, 2						; 0CCCCCCC 00SSSSSS
	XCHG AH, AL						; In order to re-use former instruction by copying and pasting
									; AX = 00SSSSSS 0CCCCCC
	CMP MINS[0], BL
	JL RECORD_BROKEN
	JG RECORD_MANTAINED
	CMP SECS[0], AH
	JL RECORD_BROKEN
	JG RECORD_MANTAINED
	CMP CSECS[0], AL
	JL RECORD_BROKEN
	
	RECORD_MANTAINED:
		MOV CH, SECS[0]
		MOV CL, CSECS[0]
		MOV DL, MINS[0]
		
		SUB CL, BL
		CMP CL, 0					; Check for possible borrow
	 	JGE CSECS4_OK				; If subtraction > 0, no borrow is required
	 	; Manage borrow from SECS
	 	CMP CH, 1					; Check if there are seconds to subtract from
	 	JGE MINS_BORROW4_OK
	 	; No minutes available, require borrow from minutes
	 	DEC DL						; One minute used
	 	MOV CH, 60					; So 60 seconds are available
	 	MINS_BORROW4_OK:
	 	DEC CH						; One second used
	 	ADD CL, 100					; So 100 100th seconds are available
	 	CSECS4_OK:
	 	; Here, subtract seconds
	 	SUB CH, SECS[0]
	 	CMP CH, 0					; Check for possible borrow
	 	JGE SECS4_OK				; If subtraction > 0, no borrow is required
	 	; Manage borrow from MINS
	 	DEC DL						; One minute used
	 	ADD CH, 60					; So 60 seconds are available
		SECS4_OK:
		SUB DL, MINS[0]
		; Subtraction completed

		; Pack the result into the array
		MOV BL, CL					; 100th second
		SHL BX, 6
		ADD BL, CH					; Seconds
		SHL BX, 3
		ADD BL, DL					; Minutes
		MOV DIFF_WR, BX				; Store the result

		JMP END_CALC_DIFF_WR
			
	RECORD_BROKEN:
		SUB AL, CSECS[0]
		CMP AL, 0					; Check for possible borrow
	 	JGE CSECS3_OK				; If subtraction > 0, no borrow is required
	 	; Manage borrow from SECS
	 	CMP AH, 1					; Check if there are seconds to subtract from
	 	JGE MINS_BORROW3_OK
	 	; No minutes available, require borrow from minutes
	 	DEC BL						; One minute used
	 	MOV AH, 60					; So 60 seconds are available
	 	MINS_BORROW3_OK:
	 	DEC AH						; One second used
	 	ADD AL, 100					; So 100 100th seconds are available
	 	CSECS3_OK:
	 	; Here, subtract seconds
	 	SUB AH, SECS[0]
	 	CMP AH, 0					; Check for possible borrow
	 	JGE SECS3_OK				; If subtraction > 0, no borrow is required
	 	; Manage borrow from MINS
	 	DEC BL						; One minute used
	 	ADD AH, 60					; So 60 seconds are available
		SECS3_OK:
		SUB BL, MINS[0]
		; Subtraction completed

		; Pack the result into the array
		MOV DL, AL					; 100th second
		SHL DX, 6
		ADD DL, AH					; Seconds
		SHL DX, 3
		ADD DL, BL					; Minutes
		MOV DIFF_WR, DX				; Store the result
		
		; Pack the new record
		MOV DL, CSECS[0]			; 100th second
		SHL DX, 6
		ADD DL, SECS[0]				; Seconds
		SHL DX, 3
		ADD DL, MINS[0]				; Minutes
		MOV WR, DX					; Store the result		
	
	END_CALC_DIFF_WR:
	POPA
	RET
CALC_DIFF_WR ENDP

END