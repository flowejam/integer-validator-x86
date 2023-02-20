; Description: A program which includes macros and procedures for validating integers from string input
; without the help of additional third party procedures (such as some included in the Irvine library). 
; Additionally, tests the use of these functions on valid/invalid integer input, stores the input, and presents various
; statistics based on the input.

INCLUDE Irvine32.inc

; (insert macro definitions here)


; ---------------------------------------------------------------------------
; Name: mGetString
;
; Purpose: prompts a user for input, stores the number of bytes read and the input
; 
; Preconditions: none
;
; Postconditions: none
;
; Receives:
; promptStr		= address of prompt to be written
; maxInputLen	= size of buffer
; inputStr		= address where string read by mGetString is to be stored
; bytesRead		= the address where the number of bytes read from input is to be stored
;
; Returns: data written to inputStr
; ---------------------------------------------------------------------------

mGetString macro promptStr:req, maxInputLen:req, inputStr:req, bytesRead:req
	; preserve registers
	push	edx
	push	ecx
	push	eax
	; body
	mov		edx, promptStr
	call	WriteString
	
	mov		edx, inputStr
	mov		ecx, maxInputLen
	call	ReadString
	
	mov		[bytesRead], eax 
	
	; end body
	; restore registers
	pop		eax
	pop		ecx
	pop		edx
endm

; ---------------------------------------------------------------------------
; Name: mDisplayString
;
; Purpose: displays a string for the program user  
; 
; Preconditions: none
;
; Postconditions: none
;
; Receives:
; strToPrint = memory address of the string to be displayed
;
; Returns: none
; ---------------------------------------------------------------------------

mDisplayString macro strToPrint:req
	; preserve registers
	push	edx
	; body
	mov		edx, strToPrint
	call	WriteString
	; end body
	; restore registers
	pop		edx
endm 



; (insert constant definitions here)
PROMPT_OUTPUT_LEN	= 30
MAX_SDWORD_VAL		= 2147483647
MIN_SDWORD_VAL		= 2147483648

PROGRAM_TITLE		EQU <"Integer Validator - Developed by flowejam", 0>

.data

; (insert variable definitions here)
titleString				BYTE	PROGRAM_TITLE
programIntro			BYTE	"This program asks for a certain number of signed integers. These signed integers must fit inside a 32-bit register.",0


promptString			BYTE	"Please enter a valid 32-bit signed integer: ", 0
inputString				BYTE	PROMPT_OUTPUT_LEN DUP(0) 
numBytesRead			DWORD	0

valueRead				SDWORD	0		; input read by ReadVal is stored in this memory variable
valueReadError			BYTE	"Error: input is not a valid signed integer. Please try again.",0

arrayDisplayStr			BYTE	"Here are the values you entered: ",0
arrayValuesRead			SDWORD  10 DUP(0)

invalidIndicator		DWORD	0		; indicates if input is not a valid signed integer

intStrInput				BYTE	PROMPT_OUTPUT_LEN DUP(0) 
intStrOutput			BYTE	PROMPT_OUTPUT_LEN DUP(0) 

sumDisplayStr			BYTE	"Sum of the numbers entered: ", 0
sumResult				SDWORD	0

averageDisplayStr		BYTE	"Average (truncated) of the numbers entered: ", 0
averageResult			SDWORD	0

.code
main PROC

	; (insert executable instructions here)
	
	; display program intro
	mDisplayString	offset titleString
	call			CrLf
	mDisplayString	offset programIntro
	call			CrLf
	call			CrLf
	
	
	;----------------------------------------------
	; read valid signed integers and store them in an array
	;----------------------------------------------
	mov		ecx, 10
	mov		ebx, offset arrayValuesRead

_readLoop:
	push	offset valueReadError
	push	offset invalidIndicator
	push	offset valueRead
	push	offset promptString
	push	lengthof inputString
	push	offset inputString
	push	offset numBytesRead
	call	ReadVal

	cmp		invalidIndicator, 1
	jne		_finishRead
	mov		invalidIndicator, 0
	jmp		_readLoop

_finishRead:
	mov		eax, valueRead
	mov		[ebx], eax
	add		ebx, type arrayValuesRead

	dec		ecx
	jnz		_readLoop

	;----------------------------------------------
	; write the values stored in the array
	;----------------------------------------------
	call			CrLf
	mDisplayString	offset arrayDisplayStr
	call			CrLf
	
	mov		ecx, 10
	mov		ebx, offset arrayValuesRead
_writeLoop:
	mov		eax, [ebx]

	push	lengthof intStrInput
	push	eax 
	push	offset intStrInput
	push	offset intStrOutput
	call	WriteVal

	call	CrLf
	add		ebx, type arrayValuesRead
	loop	_writeLoop

	;----------------------------------------------
	; calculate and display the sum
	;----------------------------------------------
	push			offset sumResult
	push			type arrayValuesRead
	push			lengthof arrayValuesRead 
	push			offset arrayValuesRead
	call			arraySum
	
	call			CrLf
	mDisplayString	offset sumDisplayStr
	
	push			lengthof intStrInput
	push			sumResult 
	push			offset intStrInput
	push			offset intStrOutput
	call			WriteVal
	call			CrLf
	
	;----------------------------------------------
	; calculate and display the average
	;----------------------------------------------
	call			CrLf
	mDisplayString	offset averageDisplayStr
	
	push			offset averageResult
	push			lengthof arrayValuesRead
	push			sumResult
	call			calcAvg
	
	push			lengthof intStrInput
	push			averageResult 
	push			offset intStrInput
	push			offset intStrOutput
	call			WriteVal
	call			CrLf


	Invoke ExitProcess,0	; exit to operating system
main ENDP

; (insert additional procedures here)

; ---------------------------------------------------------------------------
; Name: ReadVal 
;
; Purpose: gets user input and determines if input is a valid signed integer for storing as an SDWORD type
; 
; Preconditions: none 
;
; Postconditions: none
;
; Receives:
; [ebp + 32] = address of error message in the case of an invalid input string
; [ebp + 28] = address of invalidIndicator (for determining if string input is not a valid signed integer)
; [ebp + 24] = address where the value read is to be stored
; [ebp + 20] = address of prompt to be written
; [ebp + 16] = size of buffer
; [ebp + 12] = address where string read by mGetString is to be stored
; [ebp + 8]  = the address where the number of bytes read from input is to be stored

; Returns: 
; 1) value read in SDWORD global variable valueRead 
; 2) invalid indicator (1 or 0) in global variable invalidIndicator
; ---------------------------------------------------------------------------
ReadVal proc 
	; local vars
	local sign:DWORD,  \
		lengthOfIntString:DWORD, \
		unsignedValue:DWORD, \
		signedValue:DWORD, \
		bytesReadAddr:DWORD
	
	; preserve registers
	push	eax
	push	edx
	push	ecx
	push	ebx
	
	; body
	
	; read the input string
	mov			ebx, [ebp+8]
	mov			bytesReadAddr, ebx  
	mGetString	[ebp + 20], [ebp + 16], [ebp + 12], bytesReadAddr 
	
	mov			ebx, bytesReadAddr
	mov			lengthOfIntString, ebx
	
	; process & validate the input string
	push		[ebp + 28]
	push		[ebp + 12]
	push		lengthOfIntString
	call		processAsSignedInt
	mov			sign, ebx
	mov			unsignedValue, edx
	
	; test if it is invalid
	mov			edx, [ebp+28]
	cmp			dword ptr [edx], 1
	je			_errorReadVal
	
	; test if it is out of range for an SDWORD type
	push		[ebp+28]
	push		unsignedValue
	push		sign
	call		applySignCheckRange
	mov			signedValue, edx
	
	; test if it is invalid
	mov			edx, [ebp+28]
	cmp			dword ptr [edx], 1
	je			_errorReadVal
	
	jmp			_endReadVal
	; write error message
_errorReadVal:
		mDisplayString	[ebp+32]
		call			CrLf
		jmp				_restoreReg
		
_endReadVal:
	; save the value read
	mov			edx, [ebp+24]
	mov			ebx, signedValue
	mov			[edx], ebx
	
	; end body
	
	; restore registers
_restoreReg:
	pop			ebx
	pop			ecx
	pop			edx
	pop			eax
	ret			28
ReadVal endp


; ---------------------------------------------------------------------------
; Name: processAsSignedInt 
;
; Purpose: validate input and process string as a signed integer.
; 
; Preconditions: none 
;
; Postconditions: value of 1 or 0 in invalidIndicator global variable 
;
; Receives:
; [ebp + 16] = address of invalidIndicator (for determining if string input is not a valid signed integer)
; [ebp + 12] = memory address of string to be processed
; [ebp + 8]  = length of the string to be processed
;
; Returns: 
; ebx = sign of the processed integer
; edx = unsigned value of integer 
; ---------------------------------------------------------------------------
processAsSignedInt proc
	; local vars
	local	currentValue:DWORD, multiplier:DWORD
	; preserve registers
	push	esi
	push	edi
	push	eax
	
	; body
	
	; initialize vars for loop
	mov		ebx, 0
	mov		edx, 0
	mov		eax, 0
	mov		esi, [ebp + 12]
	cld
	mov		ecx, [ebp + 8]

_processLoop:
	lodsb
	; if on first iteration, check for a sign
	cmp		ecx, [ebp+8]
	jne		_notFirst
	cmp		al, 43				; positive
	je		_isSign
	cmp		al, 45				; negative
	je		_isSign
	jmp		_notFirst

_isSign:
	movzx	ebx, al
	jmp		_continueLoop

_notFirst:
	; determine whether the num is valid
	movzx	eax, al
	mov		currentValue, eax	; preserve value 
	push	currentValue
	push	[ebp + 16] 
	call	notDigit

	; if it is not a digit, break
	mov		eax, [ebp+16]
	cmp		dword ptr [eax], 1
	je		_endProcessInt

	; if it IS a valid digit, apply multiplier to value in edx and add the current value
	sub		currentValue, 48	; subtract the ascii value for '0' to get the decimal digit
	mov		eax, edx
	mov		multiplier, 10
	mul		multiplier
	; carry flag checks for cases where the value entered is > (2^32)-1
	jc		_invalidCarry
	mov		edx, eax
	add		edx, currentValue
	jc		_invalidCarry
	

_continueLoop:
	dec		ecx
	jnz		_processLoop

	jmp		_endProcessInt

_invalidCarry:	
	mov		eax, [ebp+16]
	mov		dword ptr [eax], 1
	
	; end body
_endProcessInt:
	; restore registers
	pop		eax
	pop		edi
	pop		esi
	ret		12
processAsSignedInt endp


; ---------------------------------------------------------------------------
; Name: notDigit 
;
; Purpose: determines whether a character is a digit or not 
; 
; Preconditions: none
;
; Postconditions: none
;
; Receives:
; [ebp + 12] = the value being tested
; [ebp +8] =  address of invalidIndicator (for determining if string input is not a valid signed integer)
;
; Returns: either a 1 (indicating the value is not a digit) or a 0 (indicating the value is a digit) 
; ---------------------------------------------------------------------------
notDigit proc
	push	ebp
	mov		ebp, esp
	; local vars
	; preserve registers
	push	eax
	push	ebx
	; body
	mov		eax, [ebp+12]
	mov		ebx, [ebp+8]  
	
	cmp		eax, 48				; 48d is the ascii value for '0'
	jl		_markNotValid
	cmp		eax, 57				; 57d is the ascii value for '9'
	jg		_markNotValid
	
	jmp		_endNotDigit

_markNotValid:
	mov		dword ptr [ebx], 1

; end body
_endNotDigit:
	; restore registers
	pop		ebx
	pop		eax
	
	mov		esp, ebp
	pop		ebp
	ret		8
notDigit endp


; ---------------------------------------------------------------------------
; Name: applySignCheckRange 
;
; Purpose: checks that the signed integer fits within an SDWORD type (i.e., -2^31 =< num <= (+2^31)-1 )
; 
; Preconditions: none
;
; Postconditions: value of 1 or 0 in invalidIndicator global variable 
;
; Receives:
; [ebp + 16] =  address of invalidIndicator
; [ebp + 12] = the unsigned value of the integer 
; [ebp + 8] = the sign for the integer
;
; Returns: 
; edx = signed value
; ---------------------------------------------------------------------------
applySignCheckRange proc
	push	ebp
	mov		ebp, esp
	; local vars
	; preserve registers
	push	eax
	push	ebx
	
	; body
	mov		ebx, [ebp+16]
	mov		dword ptr [ebx], 0
	
	mov		edx, [ebp + 12]
	mov		eax, [ebp + 8]
	
	cmp		eax, 43			; positive
	je		_applyPositive
	cmp		eax, 45			; negative
	je		_applyNegative

_applyPositive: 
; by default, (if no positive or negative sign), this block is applied
	cmp		edx, MAX_SDWORD_VAL 
	ja		_markOutOfRange
	jmp		_endApplySign

_applyNegative: 
	cmp		edx, MIN_SDWORD_VAL 
	; ja is applied even to the "negative" value since the neg instruction
	; will set to -2^31 if it is out of range. This is why neg is only applied
	; after the range has been tested.
	ja		_markOutOfRange   
	neg		edx
	jmp		_endApplySign

_markOutOfRange:
	mov		dword ptr [ebx], 1
; end body
_endApplySign:
; restore registers
	pop		ebx
	pop		eax
	
	mov		esp, ebp
	pop		ebp
	ret		12 
applySignCheckRange endp


; ---------------------------------------------------------------------------
; Name: WriteVal 
;
; Purpose: converts a signed integer of type SDWORD to a string 
; 
; Preconditions: both string arguments used must be of the same length  
;
; Postconditions: none
;
; Receives:
; [ebp + 20] = length of string parameters
; [ebp + 16] = value of signed integer to be displayed
; [ebp+12] = address of string to be reversed before being displayed
; [ebp+8] = address of string to be displayed
;
; Returns: 
; the signed integer converted to a string in global variable intStrOutput
; ---------------------------------------------------------------------------
WriteVal proc
	; local vars
	local	sign:DWORD, absVal:DWORD
	; preserve registers
	; body
	push	eax
	push	ebx
	push	edi
	push	ecx
	; end body
	cmp		sdword ptr [ebp+16], 0
	jl		_negSign
	mov		sign, 43					; set sign to positive
	mov		ebx, [ebp+16]
	mov		absVal, ebx
	jmp		_continueWriteVal
_negSign:
	mov		sign, 45					; set sign to negative
	mov		ebx, [ebp+16]
	neg		ebx
	mov		absVal, ebx

_continueWriteVal:

	push	[ebp + 20]
	push	[ebp+8]
	push	sign
	push	absVal
	push	[ebp+12]
	call	intToStr  

	; display the string and then overwrite with nulls
	mDisplayString	[ebp+8]
	cld 
	mov				ecx, [ebp+20]
	mov				al, 0
	mov				edi, [ebp+8]
	rep				stosb
	
	; restore registers
	pop		ecx
	pop		edi
	pop		ebx
	pop		eax
	ret		16
WriteVal endp

; ---------------------------------------------------------------------------
; Name: intToStr  
;
; Purpose: given a sign (negative or positive), and an unsigned integer,
; converts the integer to a string of ascii digits.
; 
; Preconditions: none
;
; Postconditions: none
;
; Receives:
; [ebp+24] = length of string parameters 
; [ebp+20] = address of string to be returned    
; [ebp+16] = sign for the converted integer
; [ebp+12] = unsigned integer value to be converted 
; [ebp+8] = address of string to be reversed   
; 
; Returns: 
; reversed string of ascii digits in global variable intStrInput
; ---------------------------------------------------------------------------
intToStr proc
	; local vars
	local accum:DWORD 
	; preserve registers
	push	eax
	push	edx
	push	ebx
	push	ecx
	push	edi
	; body
	cld
	mov		edi, [ebp+8]
	
	mov		ecx, 10
	mov		ebx, [ebp+12]
	mov		accum, ebx			; accum holds the unsigned integer value result, to be converted to a string
	mov		ebx, 0				; store the character count in ebx
	
	cmp		accum, 0 
	je		_valueIsZero

_intToStrLoop:
	cmp		accum, 0
	jbe		_endIntToStrLoop
	; if the character count is >= length of the string argument, stop and reverse string
	cmp		ebx, [ebp+24]
	jae		_skipSignAppend    
	mov		eax, accum
	mov		edx, 0
	div		ecx
	; store integer quotient in local variable before string primitives are used
	mov		accum, eax
	mov		eax, edx
	; convert digit to ascii character
	add		al, 48
	stosb
	inc		ebx			
	jmp		_intToStrLoop

_endIntToStrLoop:
	cmp		dword ptr [ebp+16], 45
	jne		_skipSignAppend
	
	; if the sign is negative, append it to the string and increase the character count
	mov		eax, [ebp+16]
	stosb
	inc		ebx
	jmp		_skipSignAppend

; handle the case where the value read is zero
_valueIsZero:
	add		accum, 48
	mov		eax, accum
	stosb
	inc		ebx

_skipSignAppend:
	push	[ebp+8]
	push	[ebp+20]
	push	ebx ; ebx holds the character count
	call	reverseString
	
	cld
	; fill input string with nulls:
	mov		ecx, [ebp+24]
	mov		edi, [ebp+8]
	mov		al, 0
	rep		stosb
		
	; end body
	; restore registers
	pop		edi
	pop		ecx
	pop		ebx
	pop		edx
	pop		eax
	ret		20
intToStr endp


; ---------------------------------------------------------------------------
; Name: reverseString 
;
; Purpose: places values from the input string into the output string in reverse order
; 
; Preconditions: none
;
; Postconditions: none
;
; Receives:
; [ebp + 16] = address of source string
; [ebp + 12] = address of destination string
; [ebp + 8] = character count to go into ecx
;
; Returns: 
; reversed output string in global variable intStrOutput
; ---------------------------------------------------------------------------
reverseString proc
	push	ebp 
	mov		ebp, esp
	
	push	ecx
	push	esi
	push	edi
	push	eax
	
	
	mov		ecx, [ebp+8]
	mov		eax, 0
	
	mov		esi, [ebp+16]
	mov		edi, [ebp+12]
	
	add		esi, [ebp+8]
	cmp		dword ptr [ebp+8], 0
	jz		_skipDecrEsi			; if no characters were ended, jump to the end of the proc
	dec		esi						; decrease to get 0-indexed end element 
	
	std
aLoop:
	lodsb
	cld
	stosb
	std
	loop	aLoop

	; reset with cld
	cld
	
_skipDecrEsi:
	pop		eax
	pop		edi
	pop		esi
	pop		ecx
	
	mov		esp, ebp
	pop		ebp
	ret		12
reverseString endp

; ---------------------------------------------------------------------------
; Name: arraySum 
;
; Purpose: calculates the sum of signed integers in an array
; 
; Preconditions: none
;
; Postconditions: none
;
; Receives:
; [ebp + 20] = address of global variable sumResult
; [ebp + 16] = type of array
; [ebp + 12] = length of array
; [ebp + 8] = address of array
;
; Returns: result of summation in global variable sumResult
; ---------------------------------------------------------------------------
arraySum proc
	push	ebp
	mov		ebp, esp
	; local vars
	; preserve registers
	push	ecx
	push	esi
	push	ebx
	; body
	mov		ecx, [ebp+12]
	mov		esi, [ebp+8]
	mov		ebx, 0

_arraySumLoop:
	add		ebx, [esi]
	add		esi, [ebp+16]
	loop	_arraySumLoop

	; store the result
	mov		ecx, [ebp+20]
	mov		[ecx], ebx
	
	; end body
	; restore registers
	pop		ebx
	pop		esi
	pop		ecx
	
	mov		esp, ebp
	pop		ebp
	ret		16
arraySum endp

; ---------------------------------------------------------------------------
; Name: calcAvg 
;
; Purpose: given the sum of some values, and the number of values summed, return the truncated average 
; 
; Preconditions: none
;
; Postconditions: none
;
; Receives:
; [ebp+16] = address of global variable averageResult where the result is to be stored.
; [ebp+12] = the number of values  
; [ebp+8] = sum of the values
;
; Returns: truncated average result in global variable averageResult
; ---------------------------------------------------------------------------
calcAvg proc
	push	ebp 
	mov		ebp, esp
	; local vars
	; preserve registers
	push	eax
	push	edx
	push	ebx
	; body
	mov		eax, [ebp+8]
	cdq
	mov		ebx, [ebp+12]
	idiv	ebx
	
	mov		ebx, [ebp+16]
	mov		[ebx], eax
	; end body
	; restore registers
	pop		ebx
	pop		edx
	pop		eax
	
	mov		esp, ebp
	pop		ebp
	ret		12
calcAvg endp

; =====================================================================================
END main
