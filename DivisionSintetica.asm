#include "msp430.h"
; Rafa PAto
Delay2	MACRO
	LOCAL	Loop1
	mov.w	#50000,R10
Loop1:	dec	R10
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	jnz	Loop1
	ENDM
	
Mult	MACRO	dato1, dato2
	LOCAL	Par, Finish, Over, Loop, end, Neg,Pos,Return
	mov.w	#0,R11			; (Boolean) Check if the value overpass range		
	mov.w	#0,R12			; "boolean" (use for checking the number of negatives)
	mov.w	#0,R15			; Result
	mov.w	dato1,R13		; M
	mov.w	dato2,R14		; N   (M x N)
	call	#Helper			; Helper method for negatives
Loop:	tst	R13			; checking if M=0
	jz	Finish			; Finish if M=0
	bit.b	#1,R13			; Testing if M is odd or even
	jz	Par			; if even jump
	add.w	R14,R15			; if odd Result= Result + N
	jc	Over			; if carry the value is out of range
Par:	clrc				; make sure that the rrc roll zeros
	rrc	R13			; M/2
	rla	R14			; N*2
	jc	Over			; if carry the value is out of range
	jmp	Loop			; Continue Loop	
Finish:	cmp	#1,R12			; Loop finised, if there was one negative invert 
	jnz	end			; else finish
	inv	R15			; Result needs to be negative
	add.w	#1,R15			; 2's complement of R4
	jmp	end			
end:	bit.w	#08000h,R15		; testing the result for overflow
	jn	Neg		
	jz	Pos
Neg:	cmp.w	#1,R12			; if the result is negative and N or M where not negatives result has overflow
	jnz	Over				
	jmp	Return
Pos:	cmp.w	#0,R12			; if result is positive and N or M where not both positive or negative result has overflow
	jnz	Over		
	jmp	Return
Over:	mov	#1,R11			; (Boolean) Result Overflow=True		
Return:	ENDM
;---------------------------------------------------------------
		ORG	0F800h			; Program Start
;---------------------------------------------------------------
P0		DW	25,-2,102,5
X0		DW	12
P1		DW	-9,6,-13,15
X1		DW	-10
P2		DW	1,25,-6,7
X2		DW	-15
P3		DW	4,106,-110,87
X3		DW	-30
		EVEN
RESET		mov.w	#0280h,SP		; Initialize stackpointer
StopWDT 	mov.w	#WDTPW+WDTHOLD,&WDTCTL	; StopWDT
		bic.b	#11000000b,P2SEL	; Selecting pins for output ////////NO SE SI ESTO ESTA CORRECTO/////////////
		bis.b	#11111111b,P2DIR	; P2.0-P2.7 as output ports
LOW		bic.b	#0xFF,P2OUT		; All pins set to low output. Place breakpoint
		bis.b	#01000001b,P1DIR	; P1.0 and P1.6 as output
		bic.b	#11111111b,P1OUT	; Clear output in P1
		bis.b	#00001000b,P1REN	; Select internal Resistor
		bis.b	#00001000b,P1OUT	; Make it pull up	
		bis.b	#00001000b,P1IE		; enable P1.3 int.
		eint				; global interrup enable	
		mov.w	#0,R7	
;--------------------Loop Waiting for player------------------------
Loop		mov	#30000,R4		; Delay
		xor.b	#0xFF,P2OUT		; Toggle LEDs
DELAY		cmp	#1,R7			; Check if the player pressed button in P1.3
		jz	OutOfInterrupt		; Start Game
		add.w	#1,0200h		; Value use for choosing random polynomial 
		add.w	#1,0202h		; Value use for choosing random X value
		dec	R4			; Decrement Delay
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		jnz	DELAY
		jmp	Loop
OutOfInterrupt	bic.b	#0xFF,P2OUT		; Turn off LEDs		
;----------------Chossing the polynomial------------
		cmp	#0,R8			; Check wich polynomial was chosen randomly
		jnz	Next			; Save the address of the first coeficient 
		mov.w	#P0,R5			; in R5
		jmp	Out
Next		cmp	#1,R8
		jnz	Next1
		mov.w	#P1,R5
		jmp	Out
Next1		cmp	#2,R8
		jnz	Next2
		mov.w	#P2,R5
		jmp	Out
Next2		mov.w	#P3,R5			; by default is P3,  Address of P is located in R5
;-----------------Chossing the X Value--------------
Out		cmp	#0,R6			; Check wich X value was chosen randomly
		jnz	Next3			; Save the number in R9
		mov.w	X0,R9
		jmp	Out1
Next3		cmp	#1,R6
		jnz	Next4
		mov.w	X1,R9
		jmp	Out1
Next4		cmp	#2,R6
		jnz	Next5
		mov.w	X2,R9
		jmp	Out1
Next5		mov.w	X3,R9			; by default is X3

;---X value is located in R9 and the address of the polynomial in R5----

;-------------------------------------------------------------------------
;			Syntethic Division
;-------------------------------------------------------------------------
Out1		mov.w	@R5+,R4			; Initialize the first coeficient and update address of the next coeficient (in R5)
Continue	Mult	R4,R9			; Mult the first coeficient with X
		cmp	#1,R11			; Compare if result is out of range
		jz	Lose
		mov.w	R15,R4			; Move the Result of the Mult in R4
		add.w	@R5+,R4			; add the next coeficient to x	
		Mult 	R4,R9			; Mult the result with x
		cmp	#1,R11			; Compare if result is out of range
		jz	Lose
		mov.w	R15,R4			; Move the Result of the Mult in R4
		add.w	@R5+,R4			; add the next coeficient to x
		Mult	R4,R9			; Mult the result with x
		cmp	#1,R11			; Compare if result is out of range
		jz	Lose
		mov.w	R15,R4			; Move the Result of the Mult in R4
		add.w	@R5+,R4			; add the last coeficient to x
		jc	Lose
		
;----------------Player Wins-----------------------------------
		bis.b	#01000000b,P1OUT	; Player Wins, green LED on
		mov	#0,R6			
		mov.w	R4,R5			; Copy result in R5
		clrc
		rla	R5			; Extract MSB from R5 to R6
		rlc	R6
		rla	R5
		rlc	R6
		rla	R5
		rlc	R6
		rla	R5
		rlc	R6
		rla	R5
		rlc	R6
		rla	R5
		rlc	R6
		rla	R5
		rlc	R6
		rla	R5
		rlc	R6
	
		rra	R5			; Reorganize R5 with LSB 
		rra	R5
		rra	R5
		rra	R5
		rra	R5
		rra	R5
		rra	R5
		rra	R5
		bis.b	R5,P2OUT		; Copy LSB in Port 2, LEDs in BreadBoard will show the LSB
		Delay2
		Delay2
		Delay2
		Delay2
		Delay2
		Delay2
		Delay2
		bic.b	#0xFF,P2OUT		; Turn off LEDs
		Delay2
		bis.b	R6,P2OUT		; Copy MSB in Port 2, LEDs in BreadBoard will show the LSB
		jmp	$
		
;---------------------Player Loses--------------------------
Lose		bis.b	#00000001b,P1OUT	; Player Loses, red LED on
		jmp	$

;---------------------------------------------------------------
;		Helper Method For Negatives
;---------------------------------------------------------------
Helper		bit.w	#1000000000000000b,R13	; Checking sign of R13
		jz	Check2			; if negative R13 return from subroutine
		inv	R13			; else invert
		add.w	#1,R13			; 2's complement of R13
		add.w	#1,R12			; Counter for negatives
Check2		bit.w	#1000000000000000b,R14	; Checking sign of R9
		jz	Return			; if negative R9=positive Return from subroutine
		inv	R14			
		add.w	#1,R14			; 2's complement of R9
		add.w	#1,R12			; Counter for negatives
Return		cmp.w	#2,R12
		jnz	Return1
		mov.w	#0,R12
Return1		ret
;-------------------------------------------------------------
;		P1.3 Interrup Service Routine
;-------------------------------------------------------------
PBISR		bic.b	#00001000b,P1IFG	; clear int. flag
		cmp	#1,R7			; Check if it was the second time to press the button in P1.3
		jz	Restart			; If true jump 
		mov.w	#1,R7			; (True) Use for checking how many pushes have been made
		mov.w	#0,R4
		mov.w	#0,R8
		mov.w	#0,R6
;------------------Random Algorithm------------------------------
First		cmp	#2,R4			; Loop done twice?
		jz	Exit			; If true Exit
		rra	&0200h			; Move least significant bit to carry
		rlc	R8			; Roll left the carry to R8
		inc	R4			; R8 will have the posibility of having a number from
		jmp	First			; 0 to 3
Exit		mov.w	#0,R4			; initialize counter
Second		cmp	#2,R4			; Loop done twice?
		jz	Exit2			; If true Exit
		rra	&0202h			; Move least significant bit to carry
		rlc	R6			; Roll left the carry to R6
		inc	R4			
		jmp	Second
Restart		bic.b	#11111111b,P2OUT	; Turn off all LEDs 
		bic.b	#11111111b,P1OUT
		bis.w	#CPUOFF +GIE,SR		; Sleep CPU
Exit2		reti 				; return from ISR
;--------------------------------------------------
;	Interrrupt Vectors
;-------------------------------------------------
		ORG	0FFFEh			; MSP430 Reset Vector
		DW	RESET			;
		ORG	0FFE4h		; interrupt vector 2
		DW	PBISR		; address of label PBISR
		END
