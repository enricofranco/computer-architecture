; Computer Architectures
; Lab 01
	.MODEL small
	.STACK
	.DATA
		DIM	EQU	10
		VECTA	DB	DIM DUP (?)
		VECTB	DB	DIM-1 DUP (?)
		MAT	DW	(DIM-1)*(DIM-1) DUP (?)
	.CODE
	.STARTUP
; Inizialization
	MOV VECTA, 5
	MOV VECTA+1, 1
	MOV VECTA+2, 80
	MOV VECTA+3, 10
	MOV VECTA+4, 7
	MOV VECTA+5, 88
	MOV VECTA+6, 12
	MOV VECTA+7, 9
	MOV VECTA+8, 55
	MOV VECTA+9, 61     
; Exercise 01
	MOV CX, DIM-1
	XOR SI, SI
cycle1:	MOV AL, VECTA[SI]
	ADD AL, VECTA[SI]+1
	MOV VECTB[SI], AL
	INC SI
	LOOP cycle1
; Exercise 02
; Array A
	MOV AL, VECTA[0]	; Minimum initial value, supposing unsigned values
	MOV SI, 1
	MOV CX, DIM
cycle2a:CMP VECTA[SI], AL
	JA endc2a	; No update needed
	MOV AL, VECTA[SI]	; Update current minimum
endc2a:	INC SI
	LOOP cycle2a	 	
; Array B
	MOV AL, VECTB[0]	; Minimum initial value, supposing unsigned values
	MOV SI, 1
	MOV CX, DIM-1
cycle2B:CMP VECTB[SI], AL
	JA endc2b	; No update needed
	MOV AL, VECTB[SI]	; Update current minimum
endc2b:	INC SI
	LOOP cycle2b	 	
; Exercise 03
	XOR SI, SI	; Index for VECTA
	XOR BX, BX	; Index for MAT	
	MOV CX, DIM-1
outl:	XOR DI, DI	; Index for VECTB 
	PUSH CX
	MOV CX, DIM-1   
intl:	MOV AL, VECTA[SI]
	MUL VECTB[DI]       
	MOV MAT[BX], AX
	INC BX
	INC BX		; Next element in the matrix
	INC DI		; Next element in VECTB
	LOOP intl
	POP CX
	INC SI		; Next element in VECTA
	LOOP outl
; Exercise 04
	MOV AX, MAT	; Minimum initial value
	MOV SI, 2	; Starting position
	MOV CX, (DIM-1)*(DIM-1)
	DEC CX		; First position already managed
cycle4:	CMP MAT[SI], AX
	JA endc4	; No update needed
	MOV AX, MAT[SI]
endc4:	INC SI
	INC SI     	; Next element in the matrix
	LOOP cycle4			 	
	.EXIT
	END	 