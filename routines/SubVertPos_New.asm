;Input:  A	 = Current Sprite Y_Offset
;		 $00 = Target Sprite Index Num
;			   Current Sprite Index Num => For Mariorio
;
; Usage:
; LDA #!Y_Offset
; %SubVertPos_New()
;
;Output: Y   = 0 => Mario to the bottom of the sprite,
;              1 => Mario being on the top.
;        $0E = 16 bit difference beween Mario Y Pos - Sprite Y Pos.

	STZ $0F
	BPL +
	DEC $0F
+	CLC
	ADC !D8,x   : STA $0E
	LDA $0F
	ADC !14D4,x : STA $0F
	CPX $00 : BNE .For_Sprite
	LDY #$00
	REP #$20
	LDA $96
	SEC
	SBC $0E
	CLC
	ADC #$0010
	STA $0E
	SEP #$20
	BPL ?+
	INY
?+
	RTL
	
.For_Sprite:
	LDY $00
	LDA !D8,y
	SEC
	SBC $0E
	STA $0E
	LDA !14D4,y
	LDY #$00
	SBC $0F
	STA $0F
	BPL ?+
	INY
?+
	RTL
