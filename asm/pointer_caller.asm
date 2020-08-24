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

macro CallStatusPtr(label)
	BRA ?skipTable
	IndexPtrTable:
		db $09, $FF, $00, $03, $06, $0C
; states   $07, $08, $09, $0A, $0B, $0C
	?skipTable
	PHX                   ; \ Preserve X and Y.
	PHY                   ; /
	PHA					  ; preserve custom sprite number
	TXY                   ; save x in y	
	LDA $03
	SEC : SBC #$07
	TAX
	LDA.l IndexPtrTable, x
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