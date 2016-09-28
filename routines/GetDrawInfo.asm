;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; This is a helper for the graphics routine.  It sets off screen flags, and sets up
; variables.
;
; Output:
;	Y = index to sprite OAM ($300)
;	$00 = sprite x position relative to screen boarder
;	$01 = sprite y position relative to screen boarder  
;
; It is adapted from the subroutine at $03B760
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GET_DRAW_INFO:
    	STZ !186C,x
    	STZ !15A0,x
    	LDA !E4,x
    	CMP $1A
    	LDA !14E0,x
    	SBC $1B
    	BEQ .on_screen_X
    	INC !15A0,x
     
    .on_screen_X
    	LDA !14E0,x
    	XBA
    	LDA !E4,x
    	REP #$20
    	SEC
    	SBC $1A
    	CLC
    	ADC #$0040
    	CMP #$0180
    	SEP #$20
    	ROL
    	AND #$01
    	STA !15C4,x
    	BNE .invalid
     
    	PHB
    	PHK
    	PLB
    	LDY #$00
    	LDA !1662,x
    	AND #$20
    	BEQ .loop
    	INY
    .loop
    	LDA !D8,x
    	CLC
    	ADC .data_1,y
    	PHP
    	CMP $1C
    	ROL $00
    	PLP
    	LDA !14D4,x
    	ADC #$00
    	LSR $00
    	SBC $1D
    	BEQ .on_screen_Y
    	LDA !186C,x
    	ORA .data_2,y
    	STA !186C,x
     
    .on_screen_Y
    	DEY
    	BPL .loop
    	PLB
     
    	LDY !15EA,x
    	LDA !E4,x
    	SEC
    	SBC $1A
    	STA $00
    	LDA !D8,x
    	SEC
    	SBC $1C
    	STA $01
    	RTL
     
    .invalid
    	PLA			; destroy the JSL
    	PLA
    	PLA
    	PLA			; sneak in the bank
    	PLY
    	PHB
    	PHY
    	PHA
    	RTL
     
    .data_1
    	db $0C,$1C
    .data_2
    	db $01,$02