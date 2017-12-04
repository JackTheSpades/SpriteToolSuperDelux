;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; GetBlock - SA-1 Hybrid version
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; this routine will get Map16 value
; If position is invalid range, will return 0xFFFF.
;
; input:
; $98-$99 block position Y
; $9A-$9B block position X
; $1933   layer
;
; output:
; A Map16 lowbyte
; Y Map16 highbyte
;
; $65-$68 will be destructed.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetBlock:	LDA $5B
		AND #$01
		TAY
		LDA #$20
		CPY #$01
		BCC .Horz0
		LDA #$1C
.Horz0		BIT $5B
		BPL .Layer1_0
		LSR A
.Layer1_0	CPY #$01
		BCC .Horz1
		CMP $99
		BCC .RangeOver
		LDA $9B
		CMP #$02
		BCC .Next
.RangeOver	LDA #$FF
		TAY
		RTL

.Horz1		CMP $9B
		BCC .RangeOver
		LDA $98
		CMP #$B0
		LDA $99
		SBC #$01
		BCS .RangeOver
.Next		LDA $1933|!addr
		REP #$21
		BEQ .Layer1_1
		TYA
		BEQ .Horz2
		LDA $98
		ADC.w #$0E00
		AND.w #$FFF0
		STA $67
		BRA +
.Horz2		LDA $98
		AND.w #$FFF0
		STA $67
		LDA $9A
		ADC.w #$1000
		BRA .Common0
.Layer1_1	LDA $98
		AND.w #$FFF0
		STA $67
+		LDA $9A
.Common0	SEP #$20
		LSR #4
		STA $65
		XBA
		CPY #$01
		BCC .Horz3
		STA $66
		ASL $68
		REP #$21
		LDA.w #$0000
		BRA .Common1
.Horz3

; non SA-1 rom - use 5A22's multiplication register
if !sa1 == 0
		ASL A
		STA $4202
		LDA #$D8
		STA $4203
		NOP			;\
		STZ $66			; | wait 8 cycles...
		REP #$21		;/
		LDA $4216

; SA-1 rom - use SA-1's arithmetic register
else
		STA $2252
		REP #$20
		STZ $2250
		LDA.w #$01B0
		STA $2253
		LDY #$00		;\ wait 5 cycles...
		STY $66			;/
		LDA $2307
endif

.Common1	ADC $67
		ADC $65
		ADC.w #$C800
		STA $65
		SEP #$20
if !sa1 == 0
		LDA #$7F		; non SA-1 - bank $7F
else
		LDA #$41		; SA-1     - bank $41
endif
		STA $67
		LDA [$65]
		TAY
		DEC $67
		LDA [$65]
		RTL
