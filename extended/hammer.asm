;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Hammer:
;; Simply flies off the screen spinning in the direction it is
;; thrown in. Virtually identical to the one in SMW already, but
;; has a proper horizontal speed routine.
;; By Sonikku

print "MAIN ",pc
Hammer:
	LDA $9D
	BNE SubGfx
	%Speed()
	%ExtendedHurt()
	LDA !extended_behind,x
	LDY !extended_x_speed,x
	BPL +
	DEC
	DEC
+	INC
	STA !extended_behind,x

SubGfx:

   %ExtendedGetDrawInfo()

	LDA !extended_behind,x	; frame is indicated by $1779,x
	LSR : LSR
	AND #$07
	phx
	tax

	LDA $01
	STA $0200|!Base2,y

	LDA $02
	STA $0201|!Base2,y

	LDA $02A2DF,x	; tilemap is the same as original game's.
	STA $0202|!Base2,y

	LDA $02A2E7,x	; same for the palette/flip (to make it consistant).
	ORA $64
	STA $0203|!Base2,y


	TYA
	LSR : LSR
	TAX
	LDA #$02
	STA $0420|!Base2,x
	PLX
.ret
	RTL
