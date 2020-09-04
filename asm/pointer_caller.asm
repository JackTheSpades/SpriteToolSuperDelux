@include

;input:  A     = Custom Sprite Number
;        X     = Sprite RAM Index
;        label = 3 byte Pointer label
macro CallSprite(label)
	PHX                   ; \ Preserve X and Y.
	PHY                   ; /
	
	TXY                   ; save x in y	
	REP #$30              ; \ 16 bit indexing and math
	AND #$00FF            ; / clear high byte
	
	STA $00               ; \
	ASL A		             ; |
	CLC : ADC $00         ; | x = A*3
	TAX                   ; /
	
	;pointer in [$00]
	LDA.l <label>+0,x : STA $00
	SEP #$20
	LDA.l <label>+2,x : STA $02
	SEP #$10
		
	TYX	                ; put y back in x
		
	PHB : PHA : PLB       ; set bank to cluster sprite bank	
	PHK                   ; \
	PEA ..return-1        ; | because there is no JSL [$xxxx]
	JML [!Base1]          ; |
..return                 ; /	
	PLB
	
	PLY                   ; \ 
	PLX                   ; / Pull everything back and return.
endmacro

;input:  A     = Custom Sprite Number
;        X     = Sprite RAM Index
;		 $03   = Status
;        label = 3 byte Pointer label

macro CallStatusPtr(label, indextable, vanillaroutine)
	PHX                   ; \ Preserve X and Y.
	PHY                   ; /

	PHA					  ; preserve custom sprite number
	TXY                   ; save x in y	
	LDA $03
	SEC : SBC #$07
	TAX
	LDA.l <indextable>, x
	STA $03
	; $09 => 00, $0A => 03, $0B => 06, $0C => 12, $07 => 09
	PLA					  ; 
	REP #$30              ; \ 16 bit indexing and math
	AND #$00FF            ; / clear high byte
	
	STA $00               ; \
	ASL #4		          ; |
	SEC : SBC $00         	  ; | x = A*15 + (status * 3)
	SEP #$30
	CLC : ADC $03
	REP #$30
	TAX                   ; /
	
	;pointer in [$00]
	LDA.l <label>+0,x : STA $00
	SEP #$20
	LDA.l <label>+2,x : STA $02
	SEP #$10

	CMP #$FF
	BNE ?continue
	PLY : PLX
	LDA !14C8,x
	JMP <vanillaroutine>
	?continue

	TYX	                ; put y back in x
		
	PHB : PHA : PLB       ; set bank to cluster sprite bank	
	PHK                   ; \
	PEA ?return-1        ; | because there is no JSL [$xxxx]
	JML [!Base1]          ; |
?return                 ; /	
	PLB
	PLY                   ; \ 
	PLX                   ; / Pull everything back and return.
endmacro


macro CallPerLevelStatusPtr(label, indextable, vanillaroutine)
	PHX
	PHY

	SEP #$30
	LDA $03
	SEC : SBC #$07
	TAX
	LDA.l <indextable>,x
	REP #$30
	AND #$00FF
	STA $03

	LDA $01, s			; load Y from stack
	CLC : ADC $03
	TAX

	LDA.l <label>+0,x : STA $00
	SEP #$20
	LDA.l <label>+2,x : STA $02
	SEP #$10

	CMP #$FF
	BNE ?continue
	PLY : PLX
	LDA !14C8,x
	JMP <vanillaroutine> 	; if the bank if FF, (aka invalid, just go back to running old main.asm code)
	?continue

	LDA $03, s			; get x back from stack
	TAX

	PHB : PHA : PLB
	PHK 
	PEA ?return-1
	JML [!Base1]
?return
	PLB
	REP #$30
	PLY
	PLX
endmacro