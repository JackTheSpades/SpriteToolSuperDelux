;Usage:
;REP #$10
;LDX #!block_number
;%change_map16()
;SEP #$10


;todo optimize
	PHP
	
	PHX	
	REP #$10
	LDX $03
	
	SEP #$20
	PHB
	PHY
	LDA #$00				; \
	PHA					; | bank = 0
	PLB					; /
	REP #$30				; 
	PHX					;
	LDA $9A				; \
	STA $0C				; | $0C = x pos
	LDA $98				; | $0E = y pos
	STA $0E				; /
	LDA #$0000			; clear A
	SEP #$20				; A back 8 bit, X/Y still 16.
	LDA $5B				; bit 0,1 set = vertical level.
	STA $09				
	LDA $1933|!Base2	; layer being processed
	BEQ +
	LSR $09				; bit 0 set = processed layer being vertical	
+

	LDY $0E				; Y = y pos of block
	LDA $09
	AND #$01
	BEQ LeaveXY			; branch if layer horizontal
	LDA $9B				; \
	STA $00				; |
	LDA $99				; | swap low bytes of x and y position
	STA $9B				; |
	LDA $00				; |
	STA $99				; /
	LDY $0C				; Y = x pos of block
	
LeaveXY:
	CPY #$0200
	BCC NoEnd
	PLX
	PLY
	PLY
	PLB
	PLX
	PLP
	RTL
	
NoEnd:
	LDA $1933|!Base2	; layer being processed
	ASL A
	TAX
	LDA $BEA8,x			; \ [$65] = pointer to block pointer table
	STA $65				; | table contains $20 word sized entries (pointers)
	LDA $BEA9,x			; | indexed by the level header mdoe
	STA $66				; | 
	STZ $67				; /
	LDA $1925|!Base2	; \
	ASL A					; |
	TAY					; |
	LDA [$65],y			; | [$04] points to a table of long RAM addresses
	STA $04				; | 
	INY					; |
	LDA [$65],y			; |
	STA $05				; |
	STZ $06				; /
	LDA $9B				; \
	STA $07				; |
	ASL A					; | fetch RAM address indexed by x_pos high byte.
	CLC					; |
	ADC $07				; |
	TAY					; |
	LDA [$04],y			; | [$6B] = map16 low byte
	STA $6B				; | [$6E] = map16 high byte
	STA $6E				; |
	INY					; |
	LDA [$04],y			; |
	STA $6C				; |
	STA $6F				; |
	INY					; |
	LDA [$04],y			; |
	STA $6D				; |
	INC A					; |
	STA $70				; /
	
	LDA $09
	AND #$01
	BEQ SwitchXY		; branch if horizontal
	LDA $99		
	LSR A
	LDA $9B
	AND #$01
	BRA CurrentXY
SwitchXY:
	LDA $9B
	LSR A
	LDA $99
	
CurrentXY:
	ROL A
	ASL A
	ASL A
	ORA #$20
	STA $04
	CPX #$0000
	BEQ NoAdd
	CLC
	ADC #$10
	STA $04
NoAdd:
	LDA $98
	AND #$F0
	CLC
	ASL A
	ROL A
	STA $05
	ROL A
	AND #$03
	ORA $04
	STA $06
	LDA $9A
	AND #$F0
	REP 3 : LSR A
	STA $04
	LDA $05
	AND #$C0
	ORA $04
	STA $07
	REP #$20
	LDA $09
	AND #$0001
	BNE LayerSwitch
	LDA $1A
	SEC
	SBC #$0080
	TAX
	LDY $1C
	LDA $1933
	BEQ CurrentLayer
	LDX $1E
	LDA $20
	SEC
	SBC #$0080
	TAY
	BRA CurrentLayer
LayerSwitch: 
	LDX $1A
	LDA $1C
	SEC
	SBC #$0080
	TAY
	LDA $1933
	BEQ CurrentLayer
	LDA $1E
	SEC
	SBC #$0080
	TAX
	LDY $20
CurrentLayer:
	STX $08
	STY $0A
	LDA $98
	AND #$01F0
	STA $04
	LDA $9A
	REP 4 : LSR A
	AND #$000F
	ORA $04
	TAY
	PLA
	SEP #$20
	STA [$6B],y
	XBA
	STA [$6E],y
	XBA
	REP #$20
	ASL A
	TAY
	PHK
	PER $0006
	PEA $804C
	JML $00C0FB
	PLY
	PLB
	PLX
	PLP
	RTL
