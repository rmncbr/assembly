;
;This program will test out the functions library
;
;
;Include our external functions library functions
%include "./functions.inc"
 
SECTION .data
	openPrompt			db	"Welcome to my Program", 0dh, 0ah, 0h	;Prompt String
	goodbyePrompt		db 	"Program ending, have a nice day", 0dh, 0ah, 0h
	endl				db	0dh, 0ah, 0h
		.len			equ ($-endl)
	
	programTitle		db	"Encrypt/Decrypt Program", 0dh, 0ah
 						db	"1) Enter a String", 0dh, 0ah
 						db	"2) Enter an Encryption key", 0dh, 0ah
 						db 	"3) Print the input String", 0dh, 0ah
 	    				db	"4) Print the input Key", 0dh, 0ah
						db	"5) Encrypt/Display the Key", 0dh, 0ah
 						db	"6) Decrypt/Display the Key", 0dh, 0ah
 						db	"x) Exit the Program", 0dh, 0ah
 						db	"Please enter one: ", 0dh, 0ah, 0h

 	stringInput			db	"Please enter a string: ", 0h
 	keyInput			db	"Please enter a key for encrypting: ", 0h
 	outputStringPrompt	db	"This is the string you input: ", 0h
 	outputKeyPrompt		db	"This is the key you input: ", 0h
 	encryptionProc		db	"Encrypting your string...", 0dh, 0ah, 0h
 			.len		equ	($-encryptionProc)
 	encryptedData		db	"Here is your encrypted data: ", 0h
 			.len		equ	($-encryptedData)
 	decryptionProc		db	"Decrypting your string...", 0dh, 0ah, 0h
 			.len		equ	($-decryptionProc)
 	decryptedData		db	"Here is your decrypted data: ", 0h
 			.len		equ	($-decryptedData)
 	defaultPrompt		db	"Error - select an option from the menu", 0ah, 0dh, 0h
 			.len		equ ($-defaultPrompt)

	;Table-Driven Selection
    CaseTable:
        db	'1'
    	dd	Proc_1
	.entrySz equ ($-CaseTable)
        db	'2'
        dd	Proc_2
        db	'3'
        dd	Proc_3
        db	'4'
        dd	Proc_4
        db	'5'
        dd 	Proc_5
        db	'6'
        dd 	Proc_6
        db	'x'
        dd 	Proc_x
	.numEntries equ ($-CaseTable)/CaseTable.entrySz

SECTION .bss
	readbuffer 		resb	0FFh				;readbuffer
		.len		equ		($-readbuffer)

 	userString		resb	255					;user's input string 
 		.len 		equ 	($-userString)

 	userKey			resb	255					;user's input key
 		.len 		equ 	($-userKey)

 	encryptionArray	resb	255					;storage for encrypted data
 		.len		equ 	($-encryptionArray)

 	decryptionArray	resb	255					;storage for decrypted data
 		.len		equ 	($-decryptionArray)

 	ctrUserString		resb	0FFh	;counter variable for the user's String
	
	ctrUserKey			resb 	0FFh 	;counter variable for the user's Key


SECTION     .text
global      _start
_start:
	;Display Program Header
		call 	Printendl
    	push	openPrompt					;The prompt address - argument #1
		call 	PrintString
    	call 	Printendl
;MenuLoop
	MenuLoop:								;Start of MenuLoop

    	mov eax, 0
    	mov	esi, CaseTable           		;address of table to esi (indirect addressing)  0x804a230
		mov	ecx,CaseTable.numEntries		;number of items in switch

		push programTitle
		call PrintString

    	push readbuffer							;push readbuffer onto the stack
    	push readbuffer.len 					;push length of readbuffer onto the stack
    	call ReadText							; get input from the user

    	mov dl, [readbuffer]

;Switch
	Switch1:   						
        cmp	dl,[esi]       					;compare our value to the lookup table
        jne	Switch1_next   					;if this isn't the value we're looking for, next entry
        call NEAR [esi+1]   				;call function associated with value found
        jmp MenuLoop 						;Jump to MenuLoop
	Switch1_next:                   		;repeat loop above for next entry
        add	esi,CaseTable.entrySz 			;point to next entry in case table
    	loop Switch1                
	
	Switch1_default:                		;default case (no matching entries in table)
		call 	proc_default

		Jmp MenuLoop 						;Jump to MenuLoop
   
;Exit	
	Exit:
    	push 	goodbyePrompt
    	call 	PrintString
		;Setup the registers for exit and poke the kernel
		mov		eax,sys_exit				;What are we going to do? Exit!
		mov		ebx,0						;Return code
		int		80h							;Poke the kernel

    
;Case Table Processes

	Proc_1:									;PROC_1
	mov ecx, readbuffer.len					;loop counter
	clearStringLoop:						;start of clearStringLoop; clear previous string
		mov BYTE [readbuffer + ecx-1], 0	;
		mov BYTE [userString + ecx-1], 0	;..traverse through readbuffer and userString clearing each byte-sized element
	LOOP clearStringLoop					;Loop

	mov ecx, 0								;reset ecx : loop counter
	push stringInput				  		;prompt the user
	call PrintString 						;

	push readbuffer					  		;
	push readbuffer.len						;
	call ReadText							;get input from the user

	mov esi, 0						  		;reset index register
	mov ecx, eax					  		;move eax (amount of characters input by the user) to ecx - loop counter
	
	sub eax, 1								;exclude last element of user input (\n) for PROC_5 encryption loop
	mov [ctrUserString], eax 				;ctrUserString - how many characters the user typed in
	
  	stringLoop: 							; start of stringLoop; store string	
		mov  eax, [readbuffer + esi]   		; get char from source 
		mov  [userString + esi], eax  		; store it in the target 
		inc  esi      				  		; move to next character 
  	loop stringLoop   
	ret 									;end of PROC_1, return to menu

	Proc_2:									;PROC_2
	mov ecx, readbuffer.len					;loop counter
	clearKeyLoop:							;start of clearKeyLoop; clear previous key
		mov BYTE [readbuffer + ecx-1], 0	;
		mov BYTE [userKey + ecx-1], 0 		;..traverse through readbuffer and userKey clearing each byte-sized element
	LOOP clearKeyLoop 						;Loop

	push keyInput 							;prompt the user
	call PrintString 						;

	push readbuffer							;
	push readbuffer.len 					;
	call ReadText 							;get input from the user

	mov esi, 0								;reset index
	mov ecx, eax							;mov eax (# of characters input by the user) to loop counter ecx

	sub eax, 1								;exclude last element of user input (\n)
	mov [ctrUserKey], eax					;ctrUserKey - how many characters the user input
	
	encryptionKeyLoop:						;start of encryptionKeyLoop; store key
		mov al, [readbuffer + esi]			;get char from source			
		mov [userKey + esi], al				;store it in the target
		inc esi								;move to the next character
	loop encryptionKeyLoop 					;Loop
	ret 									;end of PROC_2, return to menu

	Proc_3:									;PROC_3
	push outputStringPrompt					;output prompt
	call PrintString 						;
	push userString 						;output user's input string
	call PrintString 						;
	ret 									;end of PROC_3, return to menu

	Proc_4:									;PROC_4
	push outputKeyPrompt 					;output prompt
	call PrintString 						;
	push userKey 							;output user's input key
	call PrintString 						;
	ret 									;end of PROC_4, return to menu

	Proc_5:									;PROC_5
	mov		ecx, encryptionProc 					;ecx:	contain the address of the string you wish to print
	mov		edx, encryptionProc.len 				;edx:	contain the length of the string
	mov		eax, 04h 								;eax:	contains the action we want to take: 4h = write
	mov		ebx, 01h								;ebx:	contains the destination of the action: 1h = stdout
	int 80h											;tickle the kernel

	xor ecx, ecx

		mov ecx, readbuffer.len					;loop counter
	clearEncArrLoop:							;start of clearKeyLoop; clear previous key
		mov BYTE [readbuffer + ecx-1], 0	;
		mov BYTE [encryptionArray + ecx-1], 0 		;..traverse through readbuffer and userKey clearing each byte-sized element
	LOOP clearEncArrLoop 						;Loop

	mov cl, [ctrUserString]					;8-bit loop counter stored in PROC_2

	mov esi, 0								;index 0 in buffer
	mov edi, 0								;index 0 in key buffer
	mov eax, 0 								; clear eax
	
	encryptLoop:							;start of encryptLoop; encrypt the user's string
		cmp edi, [ctrUserKey]					;compare key index to max size of key
		je resetKeyIndex						;[if] key index is same as max key size, set key index to 0
		jne encrypt								;			[else], encrypt
	resetKeyIndex:							;	[if]
		mov edi, 0
	
	encrypt:								;	[else]
		mov al, [userString + esi]				; move element of userString into al / move from userString to a register
		xor al,  BYTE [userKey + edi]			; translate a BYTE / xor register with key
		mov [encryptionArray + esi], al			; move from register (result of XOR) to encryptionArray
		inc esi									; point to next byte in userString
		inc edi             					; point to next byte in userKey
	LOOP encryptLoop 						; Loop!


	;Print out the data
	mov		ecx, encryptedData 						;ecx:	contain the address of the string you wish to print
	mov		edx, encryptedData.len 					;edx:	contain the length of the string
	mov		eax, 04h 								;eax:	contains the action we want to take: 4h = write
	mov		ebx, 01h								;ebx:	contains the destination of the action: 1h = stdout
	int 80h 										;tickle the kernel

	mov		ecx, encryptionArray					;ecx:	contain the address of the string you wish to print
	mov		edx, encryptionArray.len 				;edx:	contain the length of the string
	mov		eax, 04h 								;eax:	contains the action we want to take: 4h = write
	mov		ebx, 01h								;ebx:	contains the destination of the action: 1h = stdout
	int 80h 										;tickle the kernel

	mov ecx, endl 								;
	mov edx, endl.len
	mov eax, 04h
	mov ebx, 01h
	int 80h 									; "																"

	ret 									;end of PROC_5, return to menu
	
	Proc_6:									;PROC_6
	mov		ecx, decryptionProc 					;ecx:	contain the address of the string you wish to print
	mov		edx, decryptionProc.len 				;edx:	contain the length of the string
	mov		eax, 04h 								;eax:	contains the action we want to take: 4h = write
	mov		ebx, 01h								;ebx:	contains the destination of the action: 1h = stdout
	int 80h											;tickle the kernel

	xor ecx, ecx 							;clear ecx

			mov ecx, readbuffer.len					;loop counter
	clearDecArrLoop:							;start of clearKeyLoop; clear previous key
		mov BYTE [readbuffer + ecx-1], 0	;
		mov BYTE [decryptionArray + ecx-1], 0 		;..traverse through readbuffer and userKey clearing each byte-sized element
	LOOP clearDecArrLoop 						;Loop

	mov cl, [ctrUserString]					;loop counter

	mov esi, 0								;string index
	mov edi, 0								;key index
	mov eax, 0 								;clear eax

	decryptLoop:
		cmp edi, [ctrUserKey]					;compare key index with size of key
		je resetKeyIndex2						;if equal, reset index
		jne decrypt								;if not equal, decrypt
	resetKeyIndex2:
		mov edi, 0
	
	decrypt:
		mov al, [encryptionArray + esi]
		xor al,  BYTE [userKey + edi]			;translate a BYTE
		mov [decryptionArray + esi], al
		mov al, 0
		inc esi									;point to next byte
		inc edi
	LOOP decryptLoop

	;Print out the data
	mov		ecx, decryptedData 						;ecx:	contain the address of the string you wish to print
	mov		edx, decryptedData.len 					;edx:	contain the length of the string
	mov		eax, 04h 								;eax:	contains the action we want to take: 4h = write
	mov		ebx, 01h								;ebx:	contains the destination of the action: 1h = stdout
	int 80h											;tickle the kernel

	mov		ecx, decryptionArray 					;ecx:	contain the address of the string you wish to print
	mov		edx, decryptionArray.len 				;edx:	contain the length of the string
	mov		eax, 04h 								;eax:	contains the action we want to take: 4h = write
	mov		ebx, 01h								;ebx:	contains the destination of the action: 1h = stdout
	int 80h											;tickle the kernel
	
	mov ecx, endl
	mov edx, endl.len
	mov eax, 04h
	mov ebx, 01h
	int 80h 										;"															"

	ret 									;end of PROC_6, return to menu

	Proc_x: 								;Exit process
	jmp Exit 								;jump to Exit label
 	ret 									;end of PROC_X, return to menu

 	proc_default: 							;Default process
    push	defaultPrompt
    push 	defaultPrompt.len
    call	PrintText
    ret                                     ;end of PROC_DEFAULT, return to menu
