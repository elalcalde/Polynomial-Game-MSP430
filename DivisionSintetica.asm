;* Name: 	Jose A. Otero-Miranda									*
;* StudentID:	802-09-5640										*
;* Email: 	jose.otero7@upr.edu									*
;*													*
;* Name: 	Rafael A. Pol-Abellas									*
;* StudentID:	802-10-5568										*
;* Email: 	rafael.pol1@upr.edu									*
;*													*
;* Name: 	Wigberto Maldonado-Rodriguez								*
;* StudentID:	802-10-3924										*
;* Email: 	wigberto.maldonado@upr.edu								*
;*													*
;********************************************************************************************************

;****************************************POLYNOMIAL RANDOM GAME******************************************
;* HARDWARE NEEDED FOR PLAYING THE GAME:								*
;* 	1) BREADBOARD											*
;* 	2) WIRES											*	
;* 	3) 8 LEDS											*
;*	4) 8 RESITORS 15 Ohms										*
;* LEDS WILL BE CONNECTED FROM PORT 2.0 TO 2.5 AND THE LAST TWO IN XOUT AND XIN (For each port one LED 	*
;* and one resitor in series).										*
;* Layout of leds from right to left(2.0-2.5,Xin-Xout). LSB=2.0						*
;* 													*
;* About game:												*
;*	Polynomials:											*
;*		P0(x) = 25x3 − 2x2 + 102x + 5								*
;*		P1(x) = −9x3 + 6x2 − 13x + 15								*
;*		P2(x) = x3 + 25x2 − 6x + 7								*
;*		P3(x) = 4x3 + 106x2 − 110x + 87								*
;*	Values:												*
;*		x0 = 12, x1 = −10, x2 = −15, and x3 = −30						*
;* The LEDs are ﬂashing together. When the player pushes-and-releases the push button,			*
;* the LED’s turn on and the microcontroller evaluates the polynomial value Ph(xj), where h		*
;* and j are randomly selected. The polynomial evaluation is done using synthetic division. 		*
;* The result should be within −32,768 and 32,767. If it falls outside this range, then the red LED 	*
;* of the PCB is turned on and the player loses. If the evaluation is correct, then the green LED of	*
;* the PCB is turned on and the hex result will be read with the LED’s you added.			*
;* Since only eight LEDs are being used, the LSB will be shown first followed by the MSB.		*
;* Push the button again, and all LEDs should be turned off, including that in the launchpad PCB. 	*
;* Another game can be started by pressing the RESET push button.					*
;*													*
;********************************************************************************************************


#include "msp430.h"	

;---------------------------------------------------------------------------------------------------------
;			MACRO DEFINITIONS
;---------------------------------------------------------------------------------------------------------

; This is a delay macro that is being used for the initial 8 LEDs that are flashing waiting for user input

Delay2	MACRO	dato				; MACRO receives the delay counter to be used
	LOCAL	Loop1				; Label Initialization
	mov.w	dato,R10			; Copy Delay Counter to R10
Loop1:	dec	R10				; Decrement Counter (R10)
	nop					; Delay of one clock-cycle				
	nop					; Delay of one clock-cycle
	nop					; Delay of one clock-cycle
	nop					; Delay of one clock-cycle
	nop					; Delay of one clock-cycle
	nop					; Delay of one clock-cycle
	nop					; Delay of one clock-cycle
	nop					; Delay of one clock-cycle
	nop					; Delay of one clock-cycle
	nop					; Delay of one clock-cycle
	nop					; Delay of one clock-cycle
	nop					; Delay of one clock-cycle
	nop					; Delay of one clock-cycle
	nop					; Delay of one clock-cycle
	nop					; Delay of one clock-cycle
	jnz	Loop1				; if counter != 0, repeate Loop1
	ENDM					; END MACRO
	
; This is the multiplication MACRO. This will handle the multiplication of values in synthetic
; division and will also verify is any numbers went out of range.

Mult	MACRO	dato1, dato2			; MACRO receives the two values to multiply
	LOCAL	Par, Finish, Over, Loop, end, Neg,Pos,Return ; Label Initialization
	mov.w	#0,R11				; Flag, to verify if the value is out of range		
	mov.w	#0,R12				; Flag, to count the number of negative numbers that entered the MACRO
	mov.w	#0,R15				; Result of the multiplication
	mov.w	dato1,R13			; Copy value of M into R13
	mov.w	dato2,R14			; Copy value of N into R14
	call	#Helper				; Returns the 2's complement of negative numbers
Loop:	tst	R13				; if M = 0, 
	jz	Finish				; skip these steps and go to Finish
	bit.b	#1,R13				; else, test if M is odd or even
	jz	Par				; if even, skip the next steps and jump to the 'Par' Loop
	add.w	R14,R15				; else, M is odd, thus Result = Result + N
	jc	Over				; Check Carry flag, if enabled, value is out of range, skip the game and jump to the End (You lose)
Par:	clrc					; Clear Carry Bit to make sure that the rrc rolls zeroes
	rrc	R13				; M/2, Rotate right with carry R13
	rla	R14				; N*2, Rotate left R14
	jc	Over				; Check Carry flag, if enabled, value is out of range, skip the game and jump to the End (You lose)
	jmp	Loop				; else, repeat Loop until M = 0	
Finish:	cmp	#1,R12				; Loop finised, check if there was only one negative number
	jnz	end				; if not, proceed to finish the multiplication (jump to Finish)
	inv	R15				; if yes, Result needs to be negative, thus take the 1's complement of the result (R15)
	add.w	#1,R15				; increment by one the Result to obtain the 2's complement of R15		
end:	bit.w	#08000h,R15			; testing the result for overflow
	jn	Neg				; Check Negative flag, if enabled, verify the validity of the result		
	jz	Pos				; else, the result should be positive, proceed to verify the validity of the result
Neg:	cmp.w	#1,R12				; if the result is negative and N or M where not negatives result has overflow
	jnz	Over				
	jmp	Return
Pos:	cmp.w	#0,R12				; if result is positive and N or M where not both positive or negative, result has overflow
	jnz	Over				; if R12 is not Zero, overflow occured, thus you lose. Enable manual Overflow flag		
	jmp	Return				; else, the result is valid so proceed to the end
Over:	mov	#1,R11				; if any of the results caused an overflow, R11 is enabled.		
Return:	ENDM

;----------------------------------------------------------------------------------------------------------------------------------
		ORG	0F800h			; Program Start
;----------------------------------------------------------------------------------------------------------------------------------
P0		DW	25,-2,102,5		; Initialize P0 Polynomial
X0		DW	12			; Initialize X0 Value
P1		DW	-9,6,-13,15		; Initialize P1 Polynomial
X1		DW	-10			; Initialize X1 Value
P2		DW	1,25,-6,7		; Initialize P2 Polynomial
X2		DW	-15			; Initialize X2 Value
P3		DW	4,106,-110,87		; Initialize P3 Polynomial
X3		DW	-30			; Initialize X3 Value
		EVEN				; To ensure that addresses are even
RESET		mov.w	#0280h,SP		; Initialize Stack-Pointer
StopWDT 	mov.w	#WDTPW+WDTHOLD,&WDTCTL	; StopWDT
		bic.b	#11000000b,P2SEL	; Selecting Port 2 Pins for output
						; P2.7 and P2.6, their default operation is set for module operation.
		bis.b	#11111111b,P2DIR	; Set P2.0-P2.7 as output ports
LOW		bic.b	#0xFF,P2OUT		; Set P2.0-P2.7 as low output
		bis.b	#11110111b,P1DIR	; P1.0- P1.2 & P1.4-P1.7 as output ports
		bic.b	#11110111b,P1OUT	; Clear output in Port 1 (except P1.3)
		bis.b	#00001000b,P1REN	; Select Internal Resistor
		bis.b	#00001000b,P1OUT	; Make it Pull-Up (P1.3)	
		bis.b	#00001000b,P1IE		; Enable P1.3 interrupt
		eint				; Global Interrupt Enable	
		mov.w	#0,R7			; Interrupt Counter	

;----------------------------------------------------Loop Waiting for player--------------------------------------------------------------
; In this loop, the eight LEDs connected to the pins at Port 2 are flashing on and off waiting for user
; interaction. Once the user presses the P1.3 button, the interrupt service will take you out of this loop
; by incrementing the value in R7.
;-----------------------------------------------------------------------------------------------------------------------------------------

Loop		mov	#30000,R4		; Copy Delay for flashing LEDs to R4
		xor.b	#0xFF,P2OUT		; Toggle all LEDs
DELAY		cmp	#1,R7			; Check if the player pressed button in P1.3
		jz	OutOfInterrupt		; if false, keep waiting
		add.w	#1,0200h		; Increment value at Address 0x200 to make it random. This is used to select the Polynomial
		add.w	#1,0202h		; Increment value at Address 0x202 to make it random. This is used to select the X value
		dec	R4			; Decrement Delay
		nop				; Delay of one clock-cycle
		nop				; Delay of one clock-cycle
		nop				; Delay of one clock-cycle
		nop				; Delay of one clock-cycle
		nop				; Delay of one clock-cycle
		nop				; Delay of one clock-cycle
		nop				; Delay of one clock-cycle
		nop				; Delay of one clock-cycle
		nop				; Delay of one clock-cycle
		jnz	DELAY			; if not zero, repeate DELAY again
		jmp	Loop			; else, repeate Loop again
OutOfInterrupt	bic.b	#0xFF,P2OUT		; Turn off LEDs

;-----------------------------------------Chossing the polynomial---------------------------------------------------------------------------
; In this part of the code, we will randomly choose which polynomial to play with. Since the 0x200 address initially had
; dummy data, we kept incrementing that dummy data by one. 
;-------------------------------------------------------------------------------------------------------------------------------------------

		cmp	#0,R8			; Check if random number is 0
		jnz	Next			; If not zero, keep checking
		mov.w	#P0,R5			; Save the address of the first coeficient of P0 to R5
		jmp	Out			; Finish choosing Polynomial		
Next		cmp	#1,R8			; Check if random number is 1
		jnz	Next1			; If not one, keep checking
		mov.w	#P1,R5			; Save the address of the first coeficient of P1 to R5 
		jmp	Out			; Finish choosing Polynomial
Next1		cmp	#2,R8			; Check if random number is 2
		jnz	Next2			; If not two, keep checking
		mov.w	#P2,R5			; Save the address of the first coeficient of P2 to R5 
		jmp	Out			; Finish choosing Polynomial
Next2		mov.w	#P3,R5			; if not any of the three past polynomials, by default its P3,  Address of P3 is copied to R5

;-----------------Chossing the X Value-------------- Check which X value was chosen randomly ----------------------------------------------
; In this part of the code, we will randomly choose which X value to play with the polynomial. Since the 0x202 address initially had
; dummy data, we kept incrementing that dummy data by one. 
;------------------------------------------------------------------------------------------------------------------------------------------

Out		cmp	#0,R6			; Check if random number is 0
		jnz	Next3			; If not zero, check next value
		mov.w	X0,R9			; Save the address of the first coeficient (X0) in R9
		jmp	Out1			; Finish choosing random X Value
Next3		cmp	#1,R6			; Check if random number is 1
		jnz	Next4			; If not one, check next value
		mov.w	X1,R9			; Save the address of the first coeficient (X1) in R9 
		jmp	Out1			; Finish choosing random X Value
Next4		cmp	#2,R6			; Check if random number is 2
		jnz	Next5			; If not two, check next value
		mov.w	X2,R9			; Save the address of the first coeficient (X2) in R9 
		jmp	Out1			; Finish choosing random X Value
Next5		mov.w	X3,R9			; If not any of three past X value, by default its X3. The address is copies to R9  

;---X value is located in R9 and the address of the polynomial in R5----

;----------------------------------------------------------------------------------------------------------------------------------------------------------
;			Syntethic Division
;
; In this part of the code, we implement synthetic division. The randomly chosen value for X is located at R9 and the address for the 
; randomly chosen polynomial is at R5. 
;----------------------------------------------------------------------------------------------------------------------------------------------------------

Out1		mov.w	@R5+,R4			; Initialize the first coeficient of the polynomial and update address of the next coeficient (in R5)
Continue	Mult	R4,R9			; Multiply the first coeficient of the polynomial by X
		cmp	#1,R11			; Compare if the result is out of range
		jz	Lose			; If out of range, you lose
		mov.w	R15,R4			; Move the Result of the Multiplication to R4
		add.w	@R5+,R4			; add the next coeficient of the polynomial to X	
		Mult 	R4,R9			; Multiply the result of the addition by X
		cmp	#1,R11			; Compare if result is out of range
		jz	Lose			; If out of range, you lose
		mov.w	R15,R4			; Move the Result of the Multiplication to R4
		add.w	@R5+,R4			; add the next coeficient of the polynomial to X
		Mult	R4,R9			; Multiply the result of the addition by X
		cmp	#1,R11			; Compare if result is out of range
		jz	Lose			; If out of range, you lose
		mov.w	R15,R4			; Move the Result of the Multiplicatin to R4
		add.w	@R5+,R4			; add the last coeficient of the polynomial to X
		
;-------------------------------------------------------------Player Wins-----------------------------------------------------------------------------------
; In this part of the code, we have already determined that the player has won and therefore will proceed to flash the proper LEDs. 
;-----------------------------------------------------------------------------------------------------------------------------------------------------------

		bis.b	#01000000b,P1OUT	; Player Wins, turn on greend LED (P1.6)
		mov	#0,R6			; Initialize R6, this will be used as the MSB of the result
		mov.w	R4,R5			; Copy the result of the synthetic division result to R5
		mov.w	#0,R8			; Counter to determine the movement for MSB and LSB
Roll		cmp	#8,R8			; if R8 is not 8, roll the most significant bit of R5 to R6
		jz	OrganizeR5		; This will extract MSB from R5 to R6
		clrc				; Clear Carry Bit to make sure that the rla rolls zeroes
		rla	R5			; Roll left R5, move MSB to Carry		
		rlc	R6			; Copy carry to R6
		inc	R8			; Increment R8
		jmp	Roll			; Repeat until 8 bits have been rolled to carry
OrganizeR5	mov 	#0,R8			; Since we rolled left R5, we have to roll them to the right again
Again		cmp	#8,R8			; if R8 is not 8, we need to reorganize R5
		jz	FlashMSB		; If the reorganization is done, proceed to flash the result
		clrc				; Clear Carry Bit to make sure that the rra rolls zeroes 
		rra	R5			; Roll right R5, move MSB to LSB
		inc	R8			; Increment R8
		jmp	Again			; Repeat until 8 bits have been rolled to the right
FlashMSB	bis.b	R5,P2OUT		; Copy LSB in Port 2, LEDs in BreadBoard will show the LSB
		Delay2	#50000			; Delay 
		Delay2	#50000			; This delay will give us time to write down the LSB
		Delay2	#50000			; This delay will give us time to write down the LSB
		Delay2	#50000			; This delay will give us time to write down the LSB
		Delay2	#50000			; This delay will give us time to write down the LSB
		Delay2	#50000			; This delay will give us time to write down the LSB
		Delay2	#50000			; This delay will give us time to write down the LSB
		bic.b	#0xFF,P2OUT		; Turn off LEDs, so that the next portion of numbers can flash
		Delay2	#30000			; Delay of LEDs turned off
		bis.b	R6,P2OUT		; Copy MSB in Port 2, LEDs in BreadBoard will show the MSB
		jmp	$			; Wait for user interaction
		
;---------------------Player Loses-------------------------------------------------------------------------------------------------------------------
;When the player loses, only the red LED will flash on the MSP430. 
;----------------------------------------------------------------------------------------------------------------------------------------------------

Lose		bis.b	#00000001b,P1OUT	; Player Loses, red LED turns on
		jmp	$			; Wait for user interaction

;----------------------------------------------------------------------------------------------------------------------------------------------------
;					Helper Method For Negatives
; This part of the code, will verify if any numbers (coefficients of the polynomial or the X values) are negative
; and will take the 2's Complement of that number to perform the other operations.
;-----------------------------------------------------------------------------------------------------------------------------------------------------

Helper		bit.w	#1000000000000000b,R13	; Checking sign of R13 (M)
		jz	Check2			; if postive R13, check other number
		inv	R13			; else invert R13
		add.w	#1,R13			; 2's complement of R13
		add.w	#1,R12			; increment counter for negatives
Check2		bit.w	#1000000000000000b,R14	; Checking sign of R14 (N)
		jz	Return			; if positive return from subroutine
		inv	R14			; else, invert R14	
		add.w	#1,R14			; 2's complement of R14
		add.w	#1,R12			; increment counter for negatives
Return		cmp.w	#2,R12			; Two negative is the same as no negatives
		jnz	Return1			; if only one negative, return
		mov.w	#0,R12			; Easier to compare later in the Multiplication MACRO
Return1		ret				; Return from subroutine

;-------------------------------------------------------------------------------------------------------------------------------------------------------
;		P1.3 Interrupt Service Routine
;-------------------------------------------------------------------------------------------------------------------------------------------------------

PBISR		bic.b	#00001000b,P1IFG	; clear int. flag
		cmp	#1,R7			; Check if it was the second time the button in P1.3 was pressed
		jz	Restart			; If true, proceed to turn off MSP430
		mov.w	#1,R7			; else, initialize counter used for checking how many pushes have been made
		mov.w	#0,R4			; initialize random selection counter
		mov.w	#0,R8			; initialize Random number for Polynomial selection
		mov.w	#0,R6			; initialize Random number for value selection

;--------------------------------------------------Random Algorithm-------------------------------------------------------------------------------------
;
; This part of the code deals with the selection of random numbers for choosing the polynomial and value of X. The idea is to
; copy the two LSB of an address to a Register and that can yield a value from 0 to 3 and we apply the same principal at two
; different addresses to obtain totally different values for polynomial selection and X value selection.
;-------------------------------------------------------------------------------------------------------------------------------------------------------

First		cmp	#2,R4			; if loop done twice
		jz	Exit			; exit
		rra	&0200h			; else, Move least significant bit to carry (Polynomial)
		rlc	R8			; Roll left the carry to R8
		inc	R4			; increment R4 by one, R8 will have the posibility of having a number from 0 to 3
		jmp	First			; repeat again
Exit		mov.w	#0,R4			; initialize random selection counter to zero
Second		cmp	#2,R4			; if loop done twice
		jz	Exit2			; Exit
		rra	&0202h			; else, Move least significant bit to carry (X Value)
		rlc	R6			; Roll left the carry to R6
		inc	R4			; increment R4 by one, R6 will have the posibility of having a number from 0 to 3	
		jmp	Second			; repeat loop
Restart		bic.b	#11111111b,P2OUT	; Turn off all Port 2 LEDs 
		bic.b	#11111111b,P1OUT	; Turn off all Port 1 LEDs
		bis.w	#CPUOFF +GIE,SR		; Sleep CPU
Exit2		reti 				; return from ISR
;--------------------------------------------------------------------------------------------------------------------------------------------------------
;	Interrrupt Vectors
;--------------------------------------------------------------------------------------------------------------------------------------------------------
		ORG	0FFFEh			; MSP430 Reset Vector
		DW	RESET			; Address of label RESET
		ORG	0FFE4h			; interrupt vector 2
		DW	PBISR			; address of label PBISR
		END
