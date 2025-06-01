;	8008 instruction executor for x86 Rev. 1.00
;
;	Copyright (C) 2025 by Gazelle
;
;Permission is hereby granted, free of charge, to any person
;obtaining a copy of this software and associated documentation
;files (the "Software"), to deal in the Software without
;restriction, including without limitation the rights to use,
;copy, modify, merge, publish, distribute, sublicense, and/or sell
;copies of the Software, and to permit persons to whom the
;Software is furnished to do so, subject to the following
;conditions:
;
;The above copyright notice and this permission notice shall be
;included in all copies or substantial portions of the Software.
;
;THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
;EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
;OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
;NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
;HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
;WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
;FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
;OTHER DEALINGS IN THE SOFTWARE.

;Repository https://github.com/Gazelle8087/8008-instruction-executor-for-x86
;
;2025/6/1 Rev. 1.00 Initial release

	page 0,100
	.model	small
	.code

	assume	ds:nothing,es:nothing,ss:nothing
;
;	Entry point : nnnn:0e0h (far call)
;	DS must point base of 8008 instruction code area
;
;	DI must be set as step counter.
;	If DI is 0 at entry, execute continuously without step break
;	
;	step counter is decremented by 1 each instruction executed,
;	break when step counter becomes 0.
;
;	return condition
;
;	SI have the address where the code here under was fetched.
;	DI have the return code corresponding to the code here under.
;
;	HLT(code 00)---- 0fdh
;	HLT(code 01)---- 0feh
;	HLT(code FF)---- 0ffh
;	Undefined code - 0fch
;
;	Step break ----- 0fbh
;
;	IN -- port number(00h-07h)
;	OUT - port number(08h-1fh)
;
;	register assign
;
;	A    : al
;	flag : ah (invisible from 8008 software)
;	B    : ch
;	C    : cl
;	D    : dh
;	E    : dl
;	H    : bh
;	L    : bl
;	PC   : si
;	SP   : bp (invisible from 8008 software)
;
;-----------------------------------------------
code_step	equ	0fbh
code_undef1	equ	0fch
code_HLT_00	equ	0fdh
code_HLT_01	equ	0feh
code_HLT_FF	equ	0ffh

address_mask	equ	3fffh
stack_mask	equ	0fh
stack_area	equ	4004h

step_flg	equ	word ptr ds:[4002h]
reg_h		equ	byte ptr ds:[4001h]
reg_l		equ	byte ptr ds:[4000h]
reg_w		equ	word ptr ds:[4000h]
;-------------------------------------
temp		equ	cx
;temp		equ	dx
;-------------------------------------
ifidni		temp,<dx>
temp_h		equ	dh
temp_l		equ	dl
B		equ	ch
C_reg		equ	cl
D		equ	reg_h
E		equ	reg_l
elseifidni	temp,<cx>
temp_h		equ	ch
temp_l		equ	cl
B		equ	reg_h
C_reg		equ	reg_l
D		equ	dh
E		equ	dl
endif

PC80		equ	si
SP80		equ	bp
HL		equ	bx

A		equ	al
H		equ	bh
L		equ	bl
M		equ	byte ptr ds:[di]
;======================================
		org	80h
continue:
		mov	di,step_flg
		and	di,di
		jnz	exe_count

		mov	temp_h,ds:[PC80]
		inc	PC80
		and	PC80,address_mask
		jmp	temp
exe_count:
		dec	di
		mov	step_flg,di
		jz	em_break

		mov	temp_h,ds:[PC80]
		inc	PC80
		and	PC80,address_mask
		jmp	temp
em_break:
		mov	temp,reg_w
		mov	di,code_step
		retf
;=======================================
		org	0e0h
entry:
		mov	reg_w,temp
		and	SP80,stack_mask
		mov	ds:step_flg,di

		mov	temp_h,ds:[PC80]
		mov	temp_l,0
		inc	PC80
		and	PC80,address_mask
		jmp	temp
;======================================
fetch1		macro
		jmp	continue

;		mov	temp_h,ds:[PC80]
;		inc	PC80
;		and	PC80,address_mask
;		jmp	temp
endm
;======= M1 cycle ===============================

;--- LD	reg8,imm8
MVI		macro	dst

ifidni		dst,reg_l
		mov	temp_h,ds:[PC80]
		mov	dst,temp_h

elseifidni	dst,reg_h
		mov	temp_h,ds:[PC80]
		mov	dst,temp_h

elseifidni	dst,M
		mov	di,HL
		and	di,address_mask
		mov	temp_h,ds:[PC80]
		mov	dst,temp_h
else
		mov	dst,ds:[PC80]
endif
		inc	PC80
		and	PC80,address_mask
		fetch1
endm

;--- INC reg8
INR		macro	src

		sahf
		inc	src
		lahf
		fetch1
endm

;--- DEC reg8
DCR		macro	src

		sahf
		dec	src
		lahf
		fetch1
endm

;################################################
;--- LD ??,??
;LD		macro	dst,src
;
;		mov	di,HL
;		and	di,address_mask
;		mov	temp_h,src
;		mov	dst,temp_h
;
;		fetch1
;endm

LD		macro	dst,src
;================================================
ifidni		dst,src

else
	ifidni		dst,reg_l

		ifidni		src,reg_h
			mov	temp_h,src
			mov	dst,temp_h

		elseifidni	src,M
			mov	di,HL
			and	di,address_mask
			mov	temp_h,src
			mov	dst,temp_h
		else
			mov	dst,src
		endif

	elseifidni	src,reg_l

		ifidni		dst,reg_h
			mov	temp_h,src
			mov	dst,temp_h

		elseifidni	dst,M
			mov	di,HL
			and	di,address_mask
			mov	temp_h,src
			mov	dst,temp_h
		else
			mov	dst,src
		endif

	elseifidni	dst,reg_h

		ifidni		src,reg_l

			mov	temp_h,src
			mov	dst,temp_h

		elseifidni	src,M

			mov	di,HL
			and	di,address_mask
			mov	temp_h,src
			mov	dst,temp_h

		else
			mov	dst,src
		endif

	elseifidni	src,reg_h

		ifidni		dst,reg_l

			mov	temp_h,src
			mov	dst,temp_h

		elseifidni	dst,M

			mov	di,HL
			and	di,address_mask
			mov	temp_h,src
			mov	dst,temp_h

		else
			mov	dst,src
		endif

	elseifidni	dst,M
	
		ifidni		src,reg_l

			mov	di,HL
			and	di,address_mask
			mov	temp_h,src
			mov	dst,temp_h

		elseifidni	src,reg_h

			mov	di,HL
			and	di,address_mask
			mov	temp_h,src
			mov	dst,temp_h

		else
			mov	di,HL
			and	di,address_mask
			mov	dst,src
		endif

	elseifidni	src,M

		ifidni		dst,reg_l

			mov	di,HL
			and	di,address_mask
			mov	temp_h,src
			mov	dst,temp_h

		elseifidni	dst,reg_h

			mov	di,HL
			and	di,address_mask
			mov	temp_h,src
			mov	dst,temp_h

		else
			mov	di,HL
			and	di,address_mask
			mov	dst,src
		endif
	else
		mov	dst,src
	endif
;================================================
endif
			fetch1
endm
;################################################

;--- ADD A,reg8
ADD8	macro	src

ifidni	src,M
		mov	di,HL
		and	di,address_mask
endif
		add	A,src
		lahf
		fetch1
endm

;--- ADC A,reg8
ADC8		macro	src

ifidni	src,M
		mov	di,HL
		and	di,address_mask
endif
		sahf
		adc	A,src
		lahf
		fetch1
endm

;---  SUB reg8
SUB8	macro	src

ifidni	src,M
		mov	di,HL
		and	di,address_mask
endif
		sub	A,src
		lahf
		fetch1
endm

;---  SBC A,reg8
SBC8	macro	src

ifidni	src,M
		mov	di,HL
		and	di,address_mask
endif
		sahf
		sbb	A,src
		lahf
		fetch1
endm

;--- AND reg8
ANA	macro	src

ifidni	src,M
		mov	di,HL
		and	di,address_mask
endif
		and	A,src
		lahf
		fetch1
endm

;---  OR reg8
ORA	macro	src

ifidni	src,M
		mov	di,HL
		and	di,address_mask
endif
		or	A,src
		lahf
		fetch1
endm

;--- XOR reg8
XRA	macro	src

ifidni	src,M
		mov	di,HL
		and	di,address_mask
endif
		xor	A,src
		lahf
		fetch1
endm

;--- CP reg8
CPA	macro	src

ifidni	src,M
		mov	di,HL
		and	di,address_mask
endif
		cmp	A,src
		lahf
		fetch1
endm

;--- CALL cc,nn
CALL80		macro	cc

ifnb		<cc>
		sahf
		j&cc	@f
		add	PC80,2
		and	PC80,address_mask
		fetch1
@@:
endif
		mov	temp_l,ds:[PC80]
		inc	PC80
		and	PC80,address_mask
		mov	temp_h,ds:[PC80]
		inc	PC80
		and	PC80,address_mask
		add	SP80,2
		and	SP80,stack_mask
		mov	ds:[SP80+stack_area],PC80
		mov	PC80,temp
		mov	temp_l,0
		fetch1
endm

;--- JP cc,nn
JP80		macro	cc

ifnb		<cc>
		sahf
		j&cc	@f
		add	PC80,2
		and	PC80,address_mask
		fetch1
@@:
endif
		mov	temp_l,ds:[PC80]
		inc	PC80
		and	PC80,address_mask
		mov	temp_h,ds:[PC80]
		mov	PC80,temp
		mov	temp_l,0
		fetch1
endm

;--- RET cc
RET80		macro	cc
ifnb		<cc>
		sahf
		j&cc	@f
		fetch1
@@:
endif
		mov	PC80,ds:[SP80+stack_area]
		sub	SP80,2
		and	SP80,stack_mask
		fetch1
endm

;--- RST n
RST		macro	nn
		add	SP80,2
		and	SP80,stack_mask
		mov	ds:[SP80+stack_area],PC80
		mov	PC80,nn
		fetch1
endm

;--- IN n
IN08		macro	nn
		mov	temp,reg_w
		mov	di,nn
		retf
endm

;--- OUT n
OUT08		macro	nn
		mov	temp,reg_w
		mov	di,nn
		retf
endm

;---- HLT
HLT08		macro	nn
		mov	temp,reg_w
		mov	di,nn
		retf
endm
;======================================
op2	=	0

M1	macro	nn
	rept	nn - op2
		org	op2 * 100h
		mov	temp,reg_w
		mov	di,code_undef1
		retf
		op2	= op2 + 1
	endm
	op2	= nn + 1
	org	nn * 100h
endm
;--------------------------------------
M1	00				;HLT
		HLT08	code_HLT_00

exe_msg		db	0dh,0ah,'8008 instruction executor for x86 Rev. 1.00  ',0dh,0ah
		db	'Copyright (c) 2025 by Gazelle.  ',0dh,0ah
		db	'https://github.com/Gazelle8087  ',0dh,0ah,24h

M1	01				;HLT
		HLT08	code_HLT_01

M1	02				;RLC	RLCA
		sahf
		rol	A,1
		lahf
		fetch1
M1	03				;RNC
		RET80	NC
M1	04				;ADI	n
		add	A,ds:[PC80]
		lahf
		inc	PC80
		and	PC80,address_mask
		fetch1
M1	05				;RST	0	
		RST	0
M1	06				;MVI	A,nn
		MVI	A
M1	07				;RET
		RET80
;--------------------------------------
M1	08				;INR	B
		INR	B
M1	09				;DCR	B
		DCR	B
M1	0AH				;RRC	RRCA
		sahf
		ror	A,1
		lahf
		fetch1
M1	0BH				;RNZ
		RET80	NZ
M1	0CH				;ACI	nn
		sahf
		adc	A,ds:[PC80]
		lahf
		inc	PC80
		and	PC80,address_mask
		fetch1
M1	0DH				;RST	1
		RST	8
M1	0EH				;MVI	B
		MVI	B
M1	0FH				;RET
		RET80
;--------------------------------------
M1	10H				;INR	C
		INR	C_reg
M1	11h				;DCR	C
		DCR	C_reg
M1	12H				;RAL	RLA
		sahf
		rcl	A,1
		lahf
		fetch1
M1	13H				;RP
		RET80	NS
M1	14H				;SUI	nn
		sub	A,ds:[PC80]
		lahf
		inc	PC80
		and	PC80,address_mask
		fetch1
M1	15H				;RST	2
		RST	10h
M1	16H				;MVI	C,nn
		MVI	C_reg
M1	17H				;RET
		RET80
;--------------------------------------
M1	18H				;INR	D
		INR	D
M1	19H				;DCR	D
		DCR	D
M1	1AH				;RAR		RRA
		sahf
		rcr	A,1
		lahf
		fetch1
M1	1BH				;RPO
		RET80	PO
M1	1CH				;SBI	n
		sahf		
		sbb	A,ds:[PC80]
		lahf
		inc	PC80
		and	PC80,address_mask
		fetch1
M1	1DH				;RST	3
		RST	18H
M1	1EH				;MVI	D,n
		MVI	D
M1	1FH				;RET
		RET80
;--------------------------------------
M1	20H				;INR	E
		INR	E
M1	21H				;DCR	E
		DCR	E
M1	23H				;RC
		RET80	C
M1	24H				;ANI	n
		AND	A,ds:[PC80]
		lahf
		inc	PC80
		and	PC80,address_mask
		fetch1
M1	25H				;RST	4
		RST	20H
M1	26H				;MVI	E,nn
		MVI	E
M1	27H				;RET
		RET80
;--------------------------------------
M1	28H				;INR	H
		INR	H
M1	29H				;DCR	H
		DCR	H
M1	2BH				;RZ
		RET80	Z
M1	2CH				;XRI	n
		XOR	A,ds:[PC80]
		lahf
		inc	PC80
		and	PC80,address_mask
		fetch1
M1	2DH				;RST	5
		RST	28H
M1	2EH				;MVI	H,n
		MVI	H
M1	2FH				;RET
		RET80
;--------------------------------------
M1	30H				;INR	L
		INR	L
M1	31H				;DCR	L
		DCR	L
M1	33H				;RM
		RET80	S
M1	34H				;ORI	nn
		OR	A,ds:[PC80]
		lahf
		inc	PC80
		and	PC80,address_mask
		fetch1
M1	35H				;RST	6
		RST	30H
M1	36H				;MVI	L,nn
		MVI	L
M1	37H				;RET
		RET80
;--------------------------------------
M1	3BH				;RPE
		RET80	PE
M1	3CH				;CPI	nn
		CMP	A,ds:[PC80]
		lahf
		inc	PC80
		and	PC80,address_mask
		fetch1
M1	3DH				;RST	7
		RST	38h
M1	3EH				;MVI	M,nn
		MVI	M
M1	3FH				;RET
		RET80
;--------------------------------------
M1	40H
		JP80	NC
M1	41H
		IN08	0
M1	42H
		CALL80	NC
M1	43H
		IN08	1
M1	44H
		JP80
M1	45H
		IN08	2
M1	46H
		CALL80
M1	47H
		IN08	3
;--------------------------
M1	48H
		JP80	NZ
M1	49H
		IN08	4
M1	4AH
		CALL80	NZ
M1	4BH
		IN08	5
M1	4CH
		JP80
M1	4DH
		IN08	6
M1	4EH
		CALL80
M1	4FH
		IN08	7
;--------------------------
M1	50H
		JP80	NS
M1	51H
		OUT08	8
M1	52H
		CALL80	NS
M1	53H
		OUT08	9
M1	54H
		JP80
M1	55H
		OUT08	0Ah
M1	56H
		CALL80
M1	57H
		OUT08	0Bh
;--------------------------
M1	58H
		JP80	PO
M1	59H
		OUT08	0Ch
M1	5AH
		CALL80	PO
M1	5BH
		OUT08	0Dh
M1	5CH
		JP80
M1	5DH
		OUT08	0Eh
M1	5EH
		CALL80
M1	5FH
		OUT08	0Fh
;--------------------------
M1	60H
		JP80	C
M1	61H
		OUT08	10h
M1	62H
		CALL80	C
M1	63H
		OUT08	11h
M1	64H
		JP80
M1	65H
		OUT08	12h
M1	66H
		CALL80
M1	67H
		OUT08	13h
;--------------------------
M1	68H
		JP80	Z
M1	69H
		OUT08	14h
M1	6AH
		CALL80	Z
M1	6BH
		OUT08	15h
M1	6CH
		JP80
M1	6DH
		OUT08	16h
M1	6EH
		CALL80
M1	6FH
		OUT08	17h
;--------------------------
M1	70H
		JP80	S
M1	71H
		OUT08	18h
M1	72H
		CALL80	S
M1	73H
		OUT08	19h
M1	74H
		JP80
M1	75H
		OUT08	1Ah
M1	76h
		CALL80
M1	77H
		OUT08	1BH
;--------------------------
M1	78H
		JP80	PE
M1	79H
		OUT08	1Ch
M1	7AH
		CALL80	PE
M1	7BH
		OUT08	1Dh
M1	7CH
		JP80
M1	7DH
		OUT08	1Eh
M1	7EH
		CALL80
M1	7FH
		OUT08	1Fh
;--------------------------
M1	80H
		ADD8	A
M1	81H
		ADD8	B
M1	82H
		ADD8	C_reg
M1	83H
		ADD8	D
M1	84H
		ADD8	E
M1	85H
		ADD8	H
M1	86H
		ADD8	L
M1	87H
		ADD8	M
;--------------------------
M1	88H
		ADC8	A
M1	89H
		ADC8	B
M1	8AH
		ADC8	C_reg
M1	8BH
		ADC8	D
M1	8CH
		ADC8	E
M1	8DH
		ADC8	H
M1	8EH
		ADC8	L
M1	8FH
		ADC8	M
;--------------------------
M1	90H
		SUB8	A
M1	91H
		SUB8	B
M1	92H
		SUB8	C_reg
M1	93H
		SUB8	D
M1	94H
		SUB8	E
M1	95H
		SUB8	H
M1	96H
		SUB8	L
M1	97H
		SUB8	M
;--------------------------
M1	98H
		SBC8	A
M1	99H
		SBC8	B
M1	9AH
		SBC8	C_reg
M1	9BH
		SBC8	D
M1	9CH
		SBC8	E
M1	9DH
		SBC8	H
M1	9EH
		SBC8	L
M1	9FH
		SBC8	M
;--------------------------
M1	0A0H
		ANA	A
M1	0A1H
		ANA	B
M1	0A2H
		ANA	C_reg
M1	0A3H
		ANA	D
M1	0A4H
		ANA	E
M1	0A5H
		ANA	H
M1	0A6H
		ANA	L
M1	0A7H
		ANA	M
;--------------------------
M1	0A8H
		XRA	A
M1	0A9H
		XRA	B
M1	0AAH
		XRA	C_reg
M1	0ABH
		XRA	D
M1	0ACH
		XRA	E
M1	0ADH
		XRA	H
M1	0AEH
		XRA	L
M1	0AFH
		XRA	M
;--------------------------
M1	0B0H
		ORA	A
M1	0B1H
		ORA	B
M1	0B2H
		ORA	C_reg
M1	0B3H
		ORA	D
M1	0B4H
		ORA	E
M1	0B5H
		ORA	H
M1	0B6H
		ORA	L
M1	0B7H
		ORA	M
;--------------------------
M1	0B8H
		CPA	A
M1	0B9H
		CPA	B
M1	0BAH
		CPA	C_reg
M1	0BBH
		CPA	D
M1	0BCH
		CPA	E
M1	0BDH
		CPA	H
M1	0BEH
		CPA	L
M1	0BFH
		CPA	M
;--------------------------
M1	0C0H
		LD	A,A
M1	0C1H
		LD	A,B
M1	0C2H
		LD	A,C_reg
M1	0C3H
		LD	A,D
M1	0C4H
		LD	A,E
M1	0C5H
		LD	A,H
M1	0C6H
		LD	A,L
M1	0C7H
		LD	A,M
;--------------------------
M1	0C8H
		LD	B,A
M1	0C9H
		LD	B,B
M1	0CAH
		LD	B,C_reg
M1	0CBH	
		LD	B,D
M1	0CCH
		LD	B,E
M1	0CDH
		LD	B,H
M1	0CEH
		LD	B,L
M1	0CFH
		LD	B,M
;--------------------------
M1	0D0H
		LD	C_reg,A
M1	0D1H
		LD	C_reg,B
M1	0D2H
		LD	C_reg,C_reg
M1	0D3H
		LD	C_reg,D
M1	0D4H
		LD	C_reg,E
M1	0D5H
		LD	C_reg,H
M1	0D6H
		LD	C_reg,L
M1	0D7H
		LD	C_reg,M
;--------------------------
M1	0D8H
		LD	D,A
M1	0D9H
		LD	D,B
M1	0DAH
		LD	D,C_reg
M1	0DBH
		LD	D,D
M1	0DCH
		LD	D,E
M1	0DDH
		LD	D,H
M1	0DEH
		LD	D,L
M1	0DFH
		LD	D,M
;--------------------------
M1	0E0H
		LD	E,A
M1	0E1H
		LD	E,B
M1	0E2H
		LD	E,C_reg
M1	0E3H
		LD	E,D
M1	0E4H
		LD	E,E
M1	0E5H
		LD	E,H
M1	0E6H
		LD	E,L
M1	0E7H
		LD	E,M
;-------------------------
M1	0E8H
		LD	H,A
M1	0E9H
		LD	H,B
M1	0EAH
		LD	H,C_reg
M1	0EBH
		LD	H,D
M1	0ECH
		LD	H,E
M1	0EDH
		LD	H,H
M1	0EEH
		LD	H,L
M1	0EFH	
		LD	H,M
;-------------------------
M1	0F0H
		LD	L,A
M1	0F1H
		LD	L,B
M1	0F2H
		LD	L,C_reg
M1	0F3H
		LD	L,D
M1	0F4H
		LD	L,E
M1	0F5H
		LD	L,H
M1	0F6H
		LD	L,L
M1	0F7H
		LD	L,M
;--------------------------
M1	0F8H
		LD	M,A
M1	0F9H
		LD	M,B
M1	0FAH
		LD	M,C_reg
M1	0FBH
		LD	M,D
M1	0FCH
		LD	M,E
M1	0FDH
		LD	M,H
M1	0FEH
		LD	M,L
M1	0FFH
		HLT08	code_HLT_FF

;================================================
exe_start:	mov	ax,cs
		mov	ds,ax
		mov	dx,offset exe_msg
		mov	ah,09h
		int	21h
		mov	ax,4c00h
		int	21h

		.data
		.stack

		end	exe_start
