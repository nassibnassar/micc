	__CONFIG b'11111111111001'
	CBLOCK	0x20
		x
		y
		z
		t
		_____asmtemp
		uservar
	ENDC
	VARIABLE nextvar=uservar

stack		equ	0x7F
spsave		equ	0x7F


	movlw stack			; init stack
	movwf FSR

        call ___main
exit
	goto exit


pokew macro
	movwf INDF
	endm

pushw macro
	decf FSR, F
	pokew
	endm

peekw macro
	movf INDF, W
	endm

drop macro
	incf FSR, F
	endm

popw macro
	peekw
	drop
	endm

savesp macro
	movf FSR, W
	movwf spsave
	endm

loadsp macro
	movf spsave, W
	movwf FSR
	endm


bank0 macro
	bcf STATUS, RP0
	bcf STATUS, RP1
	endm

bank1 macro
	bsf STATUS, RP0
	bcf STATUS, RP1
	endm

;___bank2
;	bcf STATUS, RP0
;	bsf STATUS, RP1
;	return

;___bank3
;	bsf STATUS, RP0
;	bsf STATUS, RP1
;	return


_____setportb
	movf _____asmtemp, W
	movwf PORTB
	pushw
	return

_____settrisb
	movf _____asmtemp, W
	bank1
	movwf TRISB
	bank0
	pushw
	return

___getportb
	movf PORTB, W
	pushw
	return

___gettrisb
	bank1
	movf TRISB, W
	bank0
	pushw
	return


;;; serial communications

txport  equ     PORTA
txpin   equ     D'0'

generalinit macro
	bsf STATUS, RP0			; bank 1
	bcf STATUS, RP1
	clrf TRISA			; set all ports to output
	clrf TRISB
	clrf TRISC
	clrf TRISD
	clrf TRISE
	bcf STATUS, RP0			; bank 0
	bsf txport, txpin		; set serial send pin to high
	endm

; 1/1200 seconds = 0.0008334 seconds = 4167 cycles at 20 MHz
; (error = -0.008000400032 %)
; minus 12 cycles = 4155 cycles

; delay for 4155 cycles
sendw1200_delay
			;4148 cycles
	movlw	0x3D
	movwf	x
	movlw	0x04
	movwf	y
sendw1200_delay_0
	decfsz	x, f
	goto	$+2
	decfsz	y, f
	goto	sendw1200_delay_0

			;3 cycles
	goto	$+1
	nop

			;4 cycles (including call)
	return

; 1200 8-N-1
sendw1200
	movwf z				; store the character in z

	bsf STATUS, RP0			; select bank 1 for TRISB
	bcf STATUS, RP1
	bcf TRISB, txpin		; configure PORTB for output
	bcf STATUS, RP0			; select bank 0 for PORTB

	movlw 10			; store loop counter in t
	movwf t

	bcf STATUS, C			; prepare start bit
sendw1200_bit
	btfsc STATUS, C			; set the output bit based on C
	goto sendw1200_set		; [this part of the loop uses 7 cycles]
	goto sendw1200_clear
sendw1200_set
	bsf txport, txpin
	nop				; nop to keep cycle count the same
	goto sendw1200_cont
sendw1200_clear
	bcf txport, txpin
	goto sendw1200_cont
sendw1200_cont
	call sendw1200_delay		; delay for 1/1200 sec. minus 12 cycles
	bsf STATUS, C			; set C so that our stop bit (when we
					;    get there) will be 1 [1 cycle]
	rrf z, F			; rotate bits through C [1 cycle]
	decfsz t, F			; if --t == 0 then we are done
					;    [1 cycle within loop]
	goto sendw1200_bit		; [2 cycles]
	return


; These assume 20 MHz clock frequency and were written by Nikolai
; Golovchenko's delay code generator.


___delay100us

; Delay = 0.0001 seconds
; Clock frequency = 20 MHz

; Actual delay = 0.0001 seconds = 500 cycles
; Error = 0 %

			;496 cycles
	movlw	0xA5
	movwf	x
_100us_0
	decfsz	x, f
	goto	_100us_0

			;4 cycles (including call)
	pushw
	return


___delay1ms

; Delay = 0.001 seconds
; Clock frequency = 20 MHz

; Actual delay = 0.001 seconds = 5000 cycles
; Error = 0 %

			;4993 cycles
	movlw	0xE6
	movwf	x
	movlw	0x04
	movwf	y
_1ms_0
	decfsz	x, f
	goto	$+2
	decfsz	y, f
	goto	_1ms_0

			;3 cycles
	goto	$+1
	nop

			;4 cycles (including call)
	pushw
	return


___delay10ms

; Delay = 0.01 seconds
; Clock frequency = 20 MHz

; Actual delay = 0.01 seconds = 50000 cycles
; Error = 0 %

			;49993 cycles
	movlw	0x0E
	movwf	x
	movlw	0x28
	movwf	y
_10ms_0
	decfsz	x, f
	goto	$+2
	decfsz	y, f
	goto	_10ms_0

			;3 cycles
	goto	$+1
	nop

			;4 cycles (including call)
	pushw
	return


_____putchar
	movf _____asmtemp, W
	call sendw1200
	pushw
	return


logicnot
	movf INDF, F
	btfss STATUS, Z
	goto logicnot_clr
	bsf INDF, 0
	return
logicnot_clr
	clrf INDF
	return


equal
	popw
	subwf INDF, F
	btfss STATUS, Z
	goto equal_clr
	bsf INDF, 0
	return
equal_clr
	clrf INDF
	return


shiftleft
	popw
	movwf x
	movf x, F
	btfsc STATUS, Z
	return
shiftleft_loop
	bcf STATUS, C
	rlf INDF, F
	decfsz x, F
	goto shiftleft_loop
	return


shiftright
	popw
	movwf x
	movf x, F
	btfsc STATUS, Z
	return
shiftright_loop
	bcf STATUS, C
	rrf INDF, F
	decfsz x, F
	goto shiftright_loop
	return


