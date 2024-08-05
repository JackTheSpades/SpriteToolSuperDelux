;Input:  A	 = Current Sprite X_Offset
;		 Y = Target Sprite Index Num
;
; Usage:
; LDA #!X_Offset
; %SubHorzPosForOtherSprite()
;
;Output: Y   = 0 => Target Sprite to the right of the Current Sprite,
;              1 => Target Sprite being on the left.
;        $0E = 16 bit difference beween Target Sprite X Pos - Current Sprite X Pos.

	STZ $0F
	BPL ?+
	DEC $0F
?+	CLC
	ADC !E4,x   : STA $0E
	LDA $0F
	ADC !14E0,x : STA $0F
	LDA !E4,y
	SEC : SBC $0E
	STA $0E
	LDA !14E0,y
	LDY #$00
	SBC $0F
	STA $0F
	BPL ?+
	INY
?+
	RTL
