/*
-------------------------------------------------------
SHA.s
Secured Hash Algorithm
-------------------------------------------------------
Author:  Jikyung Colin kim
ID:      150773520
Email:   kimx3520@mylaurier.ca
Date:    2018-03-13   
-------------------------------------------------------
*/
.equ SWI_Exit, 0x11     @ Terminate program code
.equ SWI_Open, 0x66     @ Open a file
                        @ inputs - R0: address of file name, R1: mode (0: input, 1: write, 2: append)
                        @ outputs - R0: file handle, -1 if open fails
.equ SWI_Close, 0x68    @ Close a file
                        @ inputs - R0: file handle
.equ SWI_RdInt, 0x6c    @ Read integer from a file
                        @ inputs - R0: file handle
                        @ outputs - R0: integer
.equ SWI_PrInt, 0x6b    @ Write integer to a file
                        @ inputs - R0: file handle, R1: integer
.equ SWI_RdStr, 0x6a    @ Read string from a file
                        @ inputs - R0: file handle, R1: buffer address, R2: buffer size
                        @ outputs - R0: number of bytes stored
.equ SWI_PrStr, 0x69    @ Write string to a file
                        @ inputs- R0: file handle, R1: address of string
.equ SWI_PrChr, 0x00    @ Write a character to stdout
                        @ inputs - R0: character

.equ inputMode, 0     @ Set file mode to input
.equ outputMode, 1    @ Set file mode to output
.equ appendMode, 2    @ Set file mode to append
.equ stdout, 1        @ Set output target to be Stdout


@-------------------------------------------------------
@ Main Program
	LDR R1, =message
	BL	strlen
	LDR R2, =_message	@ Load address of end of the string to R2
	LDR R3, =paddedMes	@ Load address of paddedMes string to R3
	STMFD SP!, {R3}		@ Push address of paddedMes string to stack
	STMFD SP!, {R0}		@ Push length of the string to stack
	STMFD SP!, {R2}		@ Push address of end of the string to stack
	STMFD SP!, {R1}		@ Push address of string to stack
	BL PaddingZero
	ADD SP, SP, #16
	
	LDR R3, =paddedMag	@ Load address of paddedmag string to R3
	STMFD SP!, {R3}		@ Push address of paddedmag string to stack
	STMFD SP!, {R0}		@ Push length of the string to stack
	STMFD SP!, {R2}		@ Push address of end of the string to stack
	STMFD SP!, {R1}		@ Push address of string to stack
	BL PaddingMag
	ADD SP, SP, #16
	
@-------------------------------------------------------
strlen:
    /*
    -------------------------------------------------------
    Determines the length of a string.
    -------------------------------------------------------
    Uses:
    R0 - returned length
    R1 - address of string
    R2 - current character
    -------------------------------------------------------
    */
    STMFD   SP!, {R1-R2, LR}
    MOV     R0, #0          @ Initialize length    

strlenLoop:
    LDRB    R2, [R1], #1    @ Read address with post-increment (R2 = *R1, R1 += 1)
    CMP     R2, #0          @ Compare character with null
    ADDNE   R0, R0, #1
    BNE     strlenLoop      @ If not at end, continue
    
    LDMFD   SP!, {R1-R2, PC}

@-------------------------------------------------------
PaddingZero:
    /*
    -------------------------------------------------------
    Pad the message to be multiple of 512 first 448
    -------------------------------------------------------
    Uses:
    R1 - Address of String
	R2 - Address of end of string
	R3 - length of the String
	R4 - length of padding required
	R5 - address of padded string 
	R6 - current character
	R7 - counter
	R8 - zero place holder
    -------------------------------------------------------
    */
    STMFD SP!, {FP, LR}
    MOV FP, SP
	
	STMFD SP!, {R1-R8}
	
	LDR R1, [FP, #8]	@ Get address of the string
	LDR R2, [FP, #12]	@ Get address of the end of the string
	LDR R3, [FP, #16]	@ Get length of the string
	LDR R5, [FP, #20]	@ Get address of the padded String
	
	MOV R4, #56		@ Initialize length of the padding required 448bits = 56 byte
	MOV R7, #0		@ Initialize counter 
	CMP R3, R4
	BLT addzero
	
addzero:
	LDRB R6, [R1], #1
	STRB R6, [R5], #1
	ADD R7, R7, #1
	CMP R7, R3
	BNE addzero
	
	MOV R8, #0x10
	STRB R8, [R5],#1
	ADD R7, R7, #1
	MOV R8, #0
zeroloop:
	STRB R8, [R5], #1
	ADD R7, R7, #1
	CMP R7, R4
	BNE zeroloop
	
    LDMFD SP!, {R1-R8}
	LDMFD SP!, {FP, PC}
    
@-------------------------------------------------------
PaddingMag:
    /*
    -------------------------------------------------------
    Pad the message to be multiple of 512 last 64
    -------------------------------------------------------
    Uses:
    R1 - Address of String
	R2 - Address of end of string
	R3 - length of the String
	R4 - address of padded string 
	R5 - counter
	R6 - bit length of the string
	R7 - TEMP
    -------------------------------------------------------
    */
	STMFD SP!, {FP, LR}
    MOV FP, SP
	
	STMFD SP!, {R1-R7}
	
	LDR R1, [FP, #8]	@ Get address of the string
	LDR R2, [FP, #12]	@ Get address of the end of the string
	LDR R3, [FP, #16]	@ Get length of the string
	LDR R4, [FP, #20]	@ Get address of the paddedMag
	
	MOV R5, #0
	MOV R6, #0
	
lenloop:
	ADD R6, R6, #8
	ADD R5, R5, #1
	CMP R5, R3
	BNE lenloop

	ADD R4,R4, #7
	STRB R6, [R4]
	
	LDMFD SP!, {R1-R7}
	LDMFD SP!, {FP, PC}
	
	

   
    
@-------------------------------------------------------
ROTL:
    /*
    -------------------------------------------------------
    The rotate left (circular left shift) operation, where x
	is a w-bit word and n is an integer with 0 ≤ n < w, is
	defined by 
	ROTL^n(x) = (x << n) V (x>> w - n).
    -------------------------------------------------------
    Uses:
    R0    - set to '\n'
    (SWI_PrChr automatically prints to stdout)
    -------------------------------------------------------
    */
    STMFD    SP!, {R0, LR}
    MOV    R0, #'\n'    @ Define the line feed character
    SWI    SWI_PrChr    @ Print the character to Stdout
    LDMFD   SP!, {R0, PC}
    
@-------------------------------------------------------
ROTR:
    /*
    -------------------------------------------------------
    The rotate right (circular right shift) operation, where x
	is a w-bit word and n is an integer with 0 ≤ n < w, is
	defined by 
	ROTL^n(x) = (x >> n) V (x << w - n).
    -------------------------------------------------------
    Uses:
    R0    - set to '\n'
    (SWI_PrChr automatically prints to stdout)
    -------------------------------------------------------
    */
    STMFD    SP!, {R0, LR}
    MOV    R0, #'\n'    @ Define the line feed character
    SWI    SWI_PrChr    @ Print the character to Stdout
    LDMFD   SP!, {R0, PC}
    
@-------------------------------------------------------
SHR:
    /*
    -------------------------------------------------------
    The right shift operation, where x is a w-bit word and 
	n is an integer with 0 ≤ n < w, is defined by 
	SHR^n(x)=x >> n.
    -------------------------------------------------------
    Uses:
    R0    - set to '\n'
    (SWI_PrChr automatically prints to stdout)
    -------------------------------------------------------
    */
    STMFD    SP!, {R0, LR}
    MOV    R0, #'\n'    @ Define the line feed character
    SWI    SWI_PrChr    @ Print the character to Stdout
    LDMFD   SP!, {R0, PC}
    
@-------------------------------------------------------
Ch:
    /*
    -------------------------------------------------------
    Ch(x,y,z) = (x && y) EOR (-x and z)
	0 ≤ t ≤ 19
    -------------------------------------------------------
    Uses:
    R0    - set to '\n'
    (SWI_PrChr automatically prints to stdout)
    -------------------------------------------------------
    */
    STMFD    SP!, {R0, LR}
    MOV    R0, #'\n'    @ Define the line feed character
    SWI    SWI_PrChr    @ Print the character to Stdout
    LDMFD   SP!, {R0, PC}
    
@-------------------------------------------------------
Parity:
    /*
    -------------------------------------------------------
    Parity(x,y,z) = x EOR y EOR z
	20 ≤ t ≤ 39
	60 ≤ t ≤ 79
    -------------------------------------------------------
    Uses:
    R0    - set to '\n'
    (SWI_PrChr automatically prints to stdout)
    -------------------------------------------------------
    */
    STMFD    SP!, {R0, LR}
    MOV    R0, #'\n'    @ Define the line feed character
    SWI    SWI_PrChr    @ Print the character to Stdout
    LDMFD   SP!, {R0, PC}
    
@-------------------------------------------------------
Maj:
    /*
    -------------------------------------------------------
    Maj(x,y,z) = (x && y) EOR (x && z) EOR (y^z) 
    -------------------------------------------------------
    Uses:
    R0    - set to '\n'
    (SWI_PrChr automatically prints to stdout)
    -------------------------------------------------------
    */
    STMFD    SP!, {R0, LR}
    MOV    R0, #'\n'    @ Define the line feed character
    SWI    SWI_PrChr    @ Print the character to Stdout
    LDMFD   SP!, {R0, PC}
    
@-------------------------------------------------------
Mod:
    /*
    -------------------------------------------------------
    Find mod of two value
    -------------------------------------------------------
    Use this to call the subroutine
	
	MOV R1, #DIVISOR
	STMFD SP!, {R1}
	MOV R1, #DIVIDEND
	STMFD SP!, {R1}
	BL Mod
	ADD SP, SP, #8
	
	
	Uses:
    R0 - return mod of values
	R1 - dividend
	R2 - divisor
	R3 - quotient
	R4 - dividend holder
	R5 - temp
    -------------------------------------------------------
    */
    STMFD SP!, {FP, LR}
    MOV FP, SP
    STMFD SP!, {R1-R5}
    
	LDR R1, [FP, #8]	@ Get dividend
	LDR R2, [FP, #12]	@ Get divisor
	
	MOV R3, #0	@ initialize quotient
	MOV R4, R1	@ dividend holder
	MOV R5, #0	@ initialize temp
	
DivLoop:
	SUB R1, R1, R2
	CMP R1, #0
	ADDGE R5, R5, R2
	BGT DivLoop
	BLE _Mod
_Mod:
	SUB R0, R4, R5
	LDMFD SP!, {R1-R5}
	LDMFD SP!, {FP, PC}
@-------------------------------------------------------

message: .asciz "abchjhgig"
_message:
paddedMes: .space 56
paddedMag: .space 8
a: .asciz "a"
kconstant: .word  0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5, 0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174, 0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da, 0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967, 0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85, 0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070, 0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3, 0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2
hconstant: .word  0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a, 0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19





@place holder

