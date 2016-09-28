;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; $B817 - horizontal mario/sprite check - shared
; Y = 1 if mario left of sprite??
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;org $03B817        

SUB_HORZ_POS:
	LDY #$00
	LDA $94
	SEC
	SBC $E4,x
	STA $0E
	LDA $95
	SBC $14E0,x
	STA $0F
	BPL LABEL16
	INY
LABEL16:
	RTL