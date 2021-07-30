
;; Gets the OAM index to be used, deletes when off screen, etc.
;; ExtGetDraw_NoIndex variation to be used if handling OAM through alternate methods.
OAMPtr:	db $90,$94,$98,$9C,$A0,$A4,$A8,$AC

ExtGetDrawInfo2:
	LDY.w OAMPtr,x
ExtGetDraw2_NoIndex:
	LDA !extended_x_speed,x
	AND #$80
	EOR #$80
	LSR
	STA $00
	LDA !extended_x_low,x
	SEC
	SBC $1A
	STA $01
	LDA !extended_x_high,x
	SBC $1B
	BNE .erasespr
+	LDA !extended_y_low,x
	SEC
	SBC $1C
	STA $02
	LDA !extended_y_high,x
	ADC $1D
	BEQ .neg
	LDA $02
	CMP #$F0
	BCS .erasespr
	RTS
.neg	LDA $02
	CMP #$C0
	BCC .erasespr
	CMP #$E0
	BCC .hidespr
	RTS
.erasespr
	STZ !extended_num,x	; delete sprite.
.hidespr
	LDA #$F0	; prevent OAM flicker
	STA $02
+	RTS

;; sprite x + y speed handler; has gravity.
SpriteSpd:
	LDA !extended_y_speed,x
	CMP #$40
	BPL SpriteSpdNoGravity
	CLC
	ADC #$03
	STA !extended_y_speed,x

;; sprite x + y speed handler; no gravity.
SpriteSpdNoGravity:
	JSR SpriteYSpd

;; original sprite x speed handler.
SpriteXSpd:
	PHK
	PEA.w .donex-1
	PEA.w $B889-1
	JML $02B554|!bank
.donex	RTS

;; original sprite y speed handler.
SpriteYSpd:
	PHK
	PEA.w .doney-1
	PEA.w $B889-1
	JML $02B560|!bank
.doney	RTS

;; extended sprite -> mario interaction.
Hit_Mario:
	LDA !extended_x_low,x
	CLC
	ADC #$03
	STA $04
	LDA !extended_x_high,x
	ADC #$00
	STA $0A
	LDA #$0A
	STA $06
	STA $07
	LDA !extended_y_low,x
	CLC
	ADC #$03
	STA $05
	LDA !extended_y_high,x
	ADC #$00
	STA $0B
	JSL $03B664|!bank
	JSL $03B72B|!bank
	BCC .hitmar
	PHB
	LDA.b #$02|!bank8
	PHA
	PLB
	PHK
	PEA.w .retur-1
	PEA.w $B889-1
	JML $02A469|!bank
.retur	PLB 
.hitmar	RTS