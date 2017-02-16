;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Roto Disc, by mikeyk
;; asar, sa-1 compatible and cleaned version by JackTheSpades
;;
;; Description: This sprite circles a block.  Mario cannot touch it, even with a spin
;; jump.  
;;
;; NOTE: Like the Ball and Chain, this enemy should not be used in levels that
;; allow Yoshi.
;;
;; Uses first extra bit: YES
;; Set the first extra bit to make the roto disc go counter clockwise
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		!TILE = $8A
		!RADIUS = $38
		!SPEED = $03

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; sprite initialization JSL
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

print "INIT ",pc
            
		LDA #!RADIUS            
		STA !187B,x

		LDA #$80                ;set initial clock position
		STA !1602,x
		TXA
		AND #$01
		STA !151C,x         

		RTL
                    
                    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; sprite main JSL
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
            
print "MAIN ",pc                        
		PHB                     ; \
		PHK                     ;  | main sprite function, just calls local subroutine
		PLB                     ;  |
		JSR START_SPRITE_CODE   ;  |
		PLB                     ;  |
		RTL                     ; /


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; main sprite sprite code
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

START_SPRITE_CODE:
		LDA #$01
		%SubOffScreen()
		
		LDA $9D
		BNE DoMath

		;get speed (value to be added to the angle) in A
		LDA !extra_bits,x
		LDY #!SPEED
		AND #$04
		BNE +
		LDY.b #$100-!SPEED
+		TYA

		;make Y the "high byte" of the speed ($00 or $FF)
		LDY #$00
		CMP #$00
		BPL +
		DEY
+		CLC

		;add to angle low and high byte
		ADC !1602,x
		STA !1602,x
		TYA
		ADC !151C,x
		AND #$01
		STA !151C,x
						  
DoMath:

		; save sprite position
		LDA !E4,x
		PHA
		LDA !14E0,x
		PHA
		LDA !D8,x
		PHA
		LDA !14D4,x
		PHA
					
		;input for Circle routines
		LDA !1602,x : STA $04
		LDA !151C,x : STA $05
		LDA !187B,x : STA $06
		
		%CircleX()	;x offset in $07-08
		%CircleY()	;y offset in $09-0A
		
		LDA !E4,x
		CLC : ADC $07
		STA !E4,x
		LDA !14E0,x
		ADC $08
		STA !14E0,x
		
		LDA !D8,x
		CLC : ADC $09
		STA !D8,x
		LDA !14D4,x
		ADC $0A
		STA !14D4,x
		            
				
Interaction:
				
		JSL $01A7DC             ; check for mario/sprite contact
		BCC RETURN_EXTRA        ; (carry set = mario/sprite contact)
		LDA $1490|!Base2        ; \ if mario star timer
		BEQ No_star            ; / 
		%Star()		
		
		BRA RETURN_EXTRA        ; final return
No_star:
		LDA $1497|!Base2        ; \ if mario is invincible...
		BNE +                   ; /   ... return
		JSL $00F5B7             ; hurt mario
+		  
						  
						  
						  
RETURN_EXTRA:

		JSR SUB_GFX
                    
		LDA !14C8,x             
		CMP #$08
		BEQ .restore

		;clean stack
		PLA : PLA
		PLA : PLA
		RTS
                    
.restore
		;restore sprite position.
		PLA     
		STA !14D4,x
		PLA        
		STA !D8,x  
		PLA        
		STA !14E0,x
		PLA        
		STA !E4,x
		RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; graphics routine - specific to sprite
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SUB_GFX:
		%GetDrawInfo()         ; after: Y = index to sprite tile map ($300)
									  ;      $00 = sprite x position relative to screen boarder 
									  ;      $01 = sprite y position relative to screen boarder  

		LDA $00                 ; tile x position
		STA $0300|!Base2,y      ; 

		LDA $01                 ; tile y position
		STA $0301|!Base2,y      ; 

		LDA #!TILE               ; store tile
		STA $0302|!Base2,y       ;  
															
		LDA $14
		AND #$07
		ASL A
		ORA #$01

		ORA $64                    
		STA $0303|!Base2,y      ; store tile properties                 

		LDY #$02                ; \ 16x16 tile
		LDA #$00                ; | A = number of tiles drawn - 1
		JSL $01B7B3             ; / don't draw if offscreen

		RTS                     ; return
            