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