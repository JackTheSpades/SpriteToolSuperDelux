;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 
;	SubVertPos that actually considers Player Clipping
;	Y = 0 if player is below
;	y = 1 if player is above
;	$0C = low byte difference
;	$0D = high byte difference
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Get Player Y Clipping Position
PHX
LDX #$00
LDA $73					; is ducking
BNE +
	LDA $19
	BNE .checkForTheHorseGuy
+
	INX
.checkForTheHorseGuy:
	LDA $187A
	BEQ +
		INX
		INX
+
LDA $96
CLC
ADC.L PlayerClipDispY,x
STA $0C
LDA $97
ADC #$00
STA $0D
PLX

LDY #$00
LDA $0C
SEC
SBC !D8,x
STA $0C
LDA $0D
SBC !14D4,x
STA $0D
BPL .spriteAbove
INY
.spriteAbove:
RTL

PlayerClipDispY:
	db $06,$14,$10,$18


