;Input:  A	 = Current Sprite X_Offset
;		 $00 = Target Sprite Index Num
;			   Current Sprite Index Num => For Mario
;
; Usage:
; LDA #!X_Offset
; %SubVertPos_New()
;
;Output: Y   = 0 => Mario to the right of the sprite,
;              1 => Mario being on the left.
;        $0E = 16 bit difference beween Mario X Pos - Sprite X Pos.

	STZ $0F
	BPL +
	DEC $0F
+	CLC
	ADC !E4,x   : STA $0E
	LDA $0F
	ADC !14E0,x : STA $0F
	CPX $00 : BNE .For_Sprite
	LDY #$00
	REP #$20
	LDA $94
	SEC
	SBC $0E
	STA $0E
	SEP #$20
	BPL ?+
	INY
?+
	RTL
	
.For_Sprite:
	LDY $00
	LDA !E4,y
	SEC
	SBC $0E
	STA $0E
	LDA !14E0,y
	LDY #$00
	SBC $0F
	STA $0F
	BPL ?+
	INY
?+
	RTL
