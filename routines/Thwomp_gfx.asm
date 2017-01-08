

!EXPRESSION	= !1528
!ANGRY_TILE	= $CA  

; default order:
; top-left, top-right, bottom-left, bottom-right, face 2 (not fully angry yet)
X_OFFSET:
	db $FC,$04,$FC,$04,$00 
Y_OFFSET:
	db $00,$00,$10,$10,$08 
TILE_MAP:
	db $8E,$8E,$AE,$AE,$C8 
PROPERTIES:
	db $03,$43,$03,$43,$03

	
	
ThwompGFX:
	;JSR GET_DRAW_INFO
                    
	LDA !EXPRESSION,x
	STA $02
	PHX
	LDX #$03
	CMP #$00
	BEQ LOOP_START
	INX
	
LOOP_START:
	LDA $00    
	CLC                     
	ADC X_OFFSET,x
	STA $0300|!Base2,y

	LDA $01    
	CLC                     
	ADC Y_OFFSET,x
	STA $0301|!Base2,y

	LDA PROPERTIES,x
	ORA $64    
	STA $0303|!Base2,y

	LDA TILE_MAP,x
	CPX #$04                
	BNE NORMAL_TILE
	PHX                     
	LDX $02    
	CPX #$02                
	BNE NOT_ANGRY
	LDA #ANGRY_TILE               
	
NOT_ANGRY:
	PLX                     
NORMAL_TILE:
	STA $0302|!Base2,y

	INY                     
	INY                     
	INY                     
	INY                     
	DEX                     
	BPL LOOP_START

	PLX                     
					  
	LDY #$02                ; \ 460 = 2 (all 16x16 tiles)
	LDA #$04                ;  | A = (number of tiles drawn - 1)
	JSL $01B7B3             ; / don't draw if offscreen
	RTL                     ; return
