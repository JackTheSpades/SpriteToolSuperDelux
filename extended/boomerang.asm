;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Boomerang:
;; Flies to the left or right depending on direction thrown,
;; then flies back toward the direction it was thrown.
;; Can be caught by the Boomerang Bros (if they're coded to do that).
;; By Sonikku

;; LX5's note: needs a block of FreeRAM in order to animate (!extra_extended)

Boomerang:
	JSR .subgfx
	LDA $9D
	BNE .ret
	JSR SpriteSpdNoGravity

	JSR Hit_Mario

	lda !extra_extended,x
	inc
	sta !extra_extended,x
	LDA $176F|!addr,x	; if timer isn't zero, branch.
	BNE .nodecre

	LDA $1765|!addr,x
	TAY
	LDA $1747|!addr,x	; accelerate sprite based on "direction."
	CMP .xmax,y
	BEQ .nodecre
	LDA $1747|!addr,x
	CLC
	ADC .xinc,y
	STA $1747|!addr,x
.nodecre
	LDA $14		; run every other frame.
	LSR
	BCS .ret
	LDA $1779|!addr,x
	CMP #$01
	BCS ++
	LDA $1779|!addr,x	; increment/decrement y speed based on stuff.
	AND #$01
	TAY
	LDA $173D|!addr,x
	CMP .ymax,y
	BNE +
	INC $1779|!addr,x
+	LDA $173D|!addr,x
	CLC
	ADC .yinc,y
	STA $173D|!addr,x
	RTS
++	LDA $173D|!addr,x
	BEQ .ret
	DEC $173D|!addr,x	; decrement timer used by the x speed.
.ret	RTS
.xinc	db $01,$FF
.xmax	db $20,$E0
.yinc	db $01,$FF
.ymax	db $12,$EE

.subgfx
	JSR ExtGetDrawInfo2

	LDA $1747|!addr,x
	STA $03

	LDA !extra_extended,x	; get frame based on $0E05,x
	LSR : LSR
	AND #$03
	PHX
	TAX

	LDA $01
	STA $0200|!addr,y

	LDA $02
	STA $0201|!addr,y

	LDA .tilemap,x
	STA $0202|!addr,y

	LDA #$09	; palette
	PHY
	TXY
	LDX $03		; flip based on direction.
	BPL +
	INY : INY : INY : INY
+	ORA .prop,y	; set properties.
	ORA $64
	PLY
	STA $0203|!addr,y


	TYA
	LSR : LSR
	TAX
	LDA #$02
	STA $0420|!addr,x
	PLX
	RTS
.prop	db $40,$40,$80,$80
	db $00,$00,$C0,$C0
.tilemap
	db $24,$26,$24,$26