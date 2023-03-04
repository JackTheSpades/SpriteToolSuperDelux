;Input:  A	 = Current Sprite Y_Offset
;		 Y = Target Sprite Index Num
;
; Usage:
; LDA #!Y_Offset
; %SubVertPos_New()
;
;Output: Y   = 0 => Target Sprite to the bottom of the Current Sprite,
;              1 => Target Sprite being on the top.
;        $0E = 16 bit difference beween Target Sprite Y Pos - Current Sprite Y Pos.


	STZ $0F
	BPL ?+
	DEC $0F
?+	CLC
	ADC !D8,x   : STA $0E
	LDA $0F
	ADC !14D4,x : STA $0F
	LDA !D8,y
	SEC : SBC $0E
	STA $0E
	LDA !14D4,y
	LDY #$00
	SBC $0F
	STA $0F
	BPL ?+
	INY
?+
	RTL
