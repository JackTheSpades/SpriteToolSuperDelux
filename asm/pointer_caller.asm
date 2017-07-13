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
