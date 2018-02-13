.MODEL SMALL
.STACK
.DATA
; Input
RECORD DB 4 DUP (?) ; 00h, 00h, 00h, 0A3h
RATES DB 3 DUP (?) ; 2, 11, 50
; Output
DURATION_OF_RENTAL DW ?
COST_TO_BE_CHARGED DW ?
; Variables
HOURS DB ?
DAYS DW ?
WEEKS DB ?

COST_HOURS DW ?
COST_DAYS DW ?
COST_WEEKS DW ?

; Strings
S_ENDLINE DB 10, 13, '$' 
S_STARTINGDAY DB 'Starting day: $' 
S_STARTINGHOUR DB 'Starting hour: $' 
S_ENDINGDAY DB 'Ending day: $' 
S_ENDINGHOUR DB 'Ending hour: $'

S_HOURRATE DB 'Hourly rate: $' 
S_DAYRATE DB 'Daily rate: $'
S_WEEKRATE DB 'Weekly rate: $'

S_CHARGEDCOST DB 'Cost to be charged: $'

.CODE
.STARTUP
MAIN:
	CALL INPUT
	CALL CALCULATE_DURATION
;	CALL COST_ITEM1
	CALL COST_ITEM2
	CALL OUTPUT
.EXIT

CALCULATE_DURATION PROC
	PUSHA
	MOV AH, RECORD
	MOV AL, RECORD+1		; AX = XXDDDDDDDDDHHHHH
	MOV BH, RECORD+2
	MOV BL, RECORD+3		; BX = XXDDDDDDDDDHHHHH
	AND AX, 001Fh			; Hours
	AND BX, 001Fh			; Hours
	SUB BL, AL
	MOV HOURS, BL
	MOV AH, RECORD
	MOV AL, RECORD+1		; AX = XXDDDDDDDDDHHHHH
	MOV BH, RECORD+2
	MOV BL, RECORD+3		; BX = XXDDDDDDDDDHHHHH
	SHR AX, 5				; AX = 00000XXDDDDDDDDD	
	SHR BX, 5				; BX = 00000XXDDDDDDDDD
	AND AX, 01FFh			; Days
	AND BX, 01FFh			; Days
	CMP HOURS, 0			; Check for possible borrow
	JGE HOURS_OK
	; Hours negative, borrow from days
	ADD HOURS, 24
	DEC BX					; One day 'used'
	HOURS_OK:
	SUB BX, AX
	MOV DAYS, BX
	
	; Store weeks and days
	MOV AX, DAYS
	MOV BL, 7
	DIV BL					; AH = #days, AL = #weeks
	MOV WEEKS, AL
	; Move days, be careful with Little Endian
	MOV BYTE PTR DAYS+1, 0
	MOV BYTE PTR DAYS, AH
	
	; Pack the result
	MOV BL, AL
	SHL BX, 3
	ADD BX, DAYS
	SHL BX, 5
	ADD BL, HOURS
	MOV DURATION_OF_RENTAL, BX
		
	POPA
	RET
CALCULATE_DURATION ENDP	

COST_ITEM1 PROC
	PUSHA
	MOV BL, RATES			; Hourly rate
	MOV AL, HOURS
	MUL BL
	MOV COST_TO_BE_CHARGED, AX
	; Daily rate is 24*Hourly rate
	MOV AL, BL
	MOV BL, 24
	MUL BL
	MOV BX, AX				; Daily rate
	MOV AX, DAYS
	MUL BL
	ADD COST_TO_BE_CHARGED, AX
	; Week rate is 7*Daily rate	
	MOV AL, BL
	MOV BL, 7
	MUL BL
	MOV BX, AX				; Weekly rate
	MOV AL, WEEKS
	MUL BL
	ADD COST_TO_BE_CHARGED, AX
	POPA
	RET
COST_ITEM1 ENDP

COST_ITEM2 PROC
	PUSHA
	MOV AL, HOURS
	MOV BL, RATES			; Hourly rate
	MUL BL
	MOV COST_HOURS, AX
		
	MOV AX, DAYS
	MOV BL, RATES+1			; Daily rate
	MUL BL
	MOV COST_DAYS, AX
	
	MOV AL, WEEKS
	MOV BL, RATES+2			; Weekly rate
	MUL BL
	MOV COST_WEEKS, AX
	
	XOR CH, CH
	MOV CL, RATES+1			; Daily rate
	CMP CX, COST_HOURS
	JA WEEKLY_COST			; Daily rate > Cost hours
	; Here, if a daily rate is more convenient than multiple hourly rates
	MOV COST_HOURS, 0		; No hours
	ADD COST_DAYS, CX		; One more day to pay
	
	WEEKLY_COST:
	XOR CH, CH
	MOV CL, RATES+2			; Weekly rate
	CMP CX, COST_DAYS
	JA STORE_COST			; Weekly rate > Cost days
	; Here, if a weekly rate is more convenient than multiple daily rates
	MOV COST_HOURS, 0		; No hours
	MOV COST_DAYS, 0		; No days
	ADD COST_WEEKS, CX		; One more week to pay
	
	STORE_COST:
	MOV AX, COST_HOURS
	ADD AX, COST_DAYS
	ADD AX, COST_WEEKS
	
	MOV COST_TO_BE_CHARGED, AX
	
	POPA
	RET
COST_ITEM2 ENDP

INPUT PROC
	PUSHA
	; Read starting day and hour
	; Print info string
	LEA DX, S_STARTINGDAY
	MOV AH, 9
	INT 21H
	; Read starting day
	MOV CX, 3						; Day on 3 digits
	PUSH CX
	CALL READ_DECIMAL
	POP CX							; Number
	SHL CX, 5						; Leave space for hour

	; Print info string
	LEA DX, S_ENDLINE
	INT 21H
	LEA DX, S_STARTINGHOUR
	INT 21H
	; Read starting hour
	MOV BX, 2						; Hour on 2 digits
	PUSH BX
	CALL READ_DECIMAL
	POP BX							; Number
	ADD CL, BL
	MOV RECORD, CH
	MOV RECORD+1, CL
	
	; Read ending day and hour
	; Print info string
	LEA DX, S_ENDLINE
	INT 21H
	LEA DX, S_ENDINGDAY
	INT 21H
	; Read ending day
	MOV CX, 3						; Day on 3 digits
	PUSH CX
	CALL READ_DECIMAL
	POP CX							; Number
	SHL CX, 5						; Leave space for hour

	; Print info string
	LEA DX, S_ENDLINE
	INT 21H
	LEA DX, S_ENDINGHOUR
	INT 21H
	; Read ending hour
	MOV BX, 2						; Hour on 2 digits
	PUSH BX
	CALL READ_DECIMAL
	POP BX							; Number
	ADD CL, BL
	MOV RECORD+2, CH
	MOV RECORD+3, CL
	
	; Read rates
	; Print info string
	LEA DX, S_ENDLINE
	INT 21H
	LEA DX, S_HOURRATE
	INT 21H
	; Hourly rate
	MOV CX, 2
	PUSH CX
	CALL READ_DECIMAL
	POP BX
	MOV RATES, BL	

	; Print info string
	LEA DX, S_ENDLINE
	INT 21H
	LEA DX, S_DAYRATE
	INT 21H
	; Daily rate
	PUSH CX
	CALL READ_DECIMAL
	POP BX
	MOV RATES+1, BL

	; Print info string
	LEA DX, S_ENDLINE
	INT 21H
	LEA DX, S_WEEKRATE
	INT 21H
	; Weekly rate
	PUSH CX
	CALL READ_DECIMAL
	POP BX
	MOV RATES+2, BL		
	
	POPA
	RET
INPUT ENDP

OUTPUT PROC
	PUSHA
	; Print info string
	MOV AH, 9
	LEA DX, S_ENDLINE
	INT 21H
	LEA DX, S_CHARGEDCOST
	INT 21H
	PUSH COST_TO_BE_CHARGED
	CALL DISPLAY_NUMBER
	POP DI							; Fake pop
	POPA
	RET
OUTPUT ENDP

;Procedure to read a decimal number up to 65'536 (16 bits)
READ_DECIMAL proc
    push bp
    mov bp, sp
    PUSHA
        
    mov cx, [bp+4]  ;max number of digits to be read
    mov dx, 0
readLoop:
    mov ah, 1
    int 21h
    cmp al, 13
    je endReadLoop
    
    sub al, '0'
    mov ch, al
    
    mov ax, dx
    mov dx, 10
    mul dx
    mov dx, ax
    
    add dl, ch
    adc dh, 0
    
    xor ch, ch
    loop readLoop

endReadLoop:    
    mov [bp+4], dx
          
    POPA
	pop bp
    ret
READ_DECIMAL endp

DISPLAY_NUMBER PROC
	PUSH BP
	MOV BP, SP
	PUSHA
	MOV AX, [BP+4]
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
	
	POP BP
	POPA	
	RET
DISPLAY_NUMBER  ENDP

END