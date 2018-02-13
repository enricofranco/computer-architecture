.MODEL SMALL
.STACK
.DATA
GMT_START DB 11
GMT_END DB -5
HOUR_START DB 12
HOUR_END DB ?
DAY_START DB 1
DAY_END DB ?
MONTH_START DB 3
MONTH_END DB ?

; Support
MONTHS DB 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31
.CODE
.STARTUP
MAIN:
	CALL ITEMA_PROC
.EXIT

ITEMA_PROC PROC
	PUSHA
	; Move input data into output data
	MOV AH, DAY_START
	MOV DAY_END, AH
	MOV AH, MONTH_START
	MOV MONTH_END, AH
	
	MOV AL, GMT_END
	SUB AL, GMT_START
	; AL contains the difference between GMTs
	ADD AL, HOUR_START
	MOV HOUR_END, AL
	CMP HOUR_END, 0
	JL DAY_BEFORE
	CMP HOUR_END, 23
	JA DAY_AFTER
	; Day is correct
	JMP END_ITEMA
	DAY_BEFORE:
		ADD HOUR_END, 24
		DEC DAY_END
		CMP DAY_END, 0
		JG END_ITEMA
		; Here, it means that I have to 'remove' a month
		; I need to identify how many days there are in the previous month
	    MOV BL, MONTH_START
	    XOR BH, BH
	    MOV AH, MONTHS[BX-2]	; Days of the previous month
	    MOV DAY_END, AH
	    DEC MONTH_END
	    JMP END_ITEMA
	DAY_AFTER:
		SUB HOUR_END, 24
		INC DAY_END
		; It is possible that I exceed the month
		; I need to check how many days there are in the current month
		MOV BL, MONTH_END
		XOR BH, BH
		MOV AL, DAY_END
		CMP AL, MONTHS[BX-1]
		JBE END_ITEMA
		; Here, it means that I need to switch to next month
		MOV DAY_END, 1
		INC MONTH_END
	END_ITEMA:
	POPA
	RET
ITEMA_PROC ENDP

END