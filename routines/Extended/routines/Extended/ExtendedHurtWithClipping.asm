;Input: C = Size ( Clear = 8x8 , Set = 16x16 )
;Output: None

;; extended sprite -> mario interaction.
	LDY #$01 : LDA #$06 : BCC +
	LDY #$03 : LDA #$0A : CLC
	
+	STA $06
	STA $07
	
	TYA
	ADC !171F,x
	STA $04
	LDA !1733,x
	ADC #$00
	STA $0A
	
	CLC
	
	TYA
	ADC !1715,x
	STA $05
	LDA !1729,x
	ADC #$00
	STA $0B
	
	JSL $03B664|!BankB
	JSL $03B72B|!BankB
	BCC .skip
	PHB
	LDA.b #($02|!BankB>>16)
	PHA : PLB : PHK
	PEA.w .return-1
	PEA.w $B889-1
	JML $02A469|!BankB
.return
	PLB 
.skip
	RTL
