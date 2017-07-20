;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Hammer:
;; Simply flies off the screen spinning in the direction it is
;; thrown in. Virtually identical to the one in SMW already, but
;; has a proper horizontal speed routine.
;; By Sonikku

Hammer:
	LDA $9D
	BNE .subgfx
	JSR SpriteSpd
	JSR Hit_Mario
	LDA $1779|!addr,x
	LDY $1747|!addr,x
	BPL +
	DEC
	DEC
+	INC
	STA $1779|!addr,x

.subgfx	JSR ExtGetDrawInfo2

	LDA $1779|!addr,x	; frame is indicated by $1779,x
	LSR : LSR
	AND #$07
	phx
	tax

	LDA $01
	STA $0200|!addr,y

	LDA $02
	STA $0201|!addr,y

	LDA $02A2DF,x	; tilemap is the same as original game's.
	STA $0202|!addr,y

	LDA $02A2E7,x	; same for the palette/flip (to make it consistant).
	ORA $64
	STA $0203|!addr,y


	TYA
	LSR : LSR
	TAX
	LDA #$02
	STA $0420|!addr,x
	PLX
.ret	RTS
