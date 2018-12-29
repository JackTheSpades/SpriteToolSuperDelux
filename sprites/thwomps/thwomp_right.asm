;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Right Horizontal Thwomp, by mikeyk
;; cleanup, asar and sa-1 support by JackTheSpades
;;
;; Description: 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        
                    ; symbolic names for RAM addresses (don't change these)
                    !SPRITE_STATE    = $C2
						  
                    !ORIG_X_POS      = !151C
                    !EXPRESSION      = !1528
                    !FREEZE_TIMER    = !1540
                    
                    ; definitions of bits (don't change these)
                    !OBJ_CHECK       = $03             
                    
                    ; sprite data
                    !SPRITE_GRAVITY  = $04
                    !MAX_X_SPEED     = $3E 
                    !RETURN_SPEED    = $F0
                    !TIME_TO_SHAKE   = $18
                    !SOUND_EFFECT    = $09 
                    !TIME_ON_GROUND  = $40
                                                      
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; sprite init JSL
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

print "INIT ",pc
		LDA !sprite_x_low,x  
		CLC        
		ADC #$08   
		STA !sprite_x_low,x  
		STA !ORIG_X_POS,x
		RTL
      

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; sprite code JSL
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

print "MAIN ",pc                                    
		PHB                     
		PHK                     
		PLB                     
		JSR SPRITE_CODE_START   
		PLB                     
		RTL       
		
		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; sprite main code 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RETURN:              RTS  

SPRITE_CODE_START:
		JSR SUB_GFX

		LDA !14C8,x             ; RETURN if sprite status != 8
		CMP #$08            	 
		BNE RETURN                               
		LDA $9D			        ; RETURN if sprites locked
		BNE RETURN    

		LDA #$00
		%SubOffScreen()

		JSL $01A7DC             ; interact with mario as per CFG settings

		LDA !SPRITE_STATE,x     
		CMP #$01
		BEQ ATTACKING
		CMP #$02
		BEQ RETURNING

;-----------------------------------------------------------------------------------------
; state 0
;-----------------------------------------------------------------------------------------

WAITING:
		LDA !sprite_off_screen_vert,x       ;fall if offscreen vertically
		ORA !sprite_off_screen_horz,x       ;RETURN if offscreen horizontally
		BNE Return0

		STZ !EXPRESSION,x
		%SubHorzPos()            ;determine if mario is close and act accordingly
		TYA                      ;after which $0E has the 16bit value of mario x - sprite x
		STA !157C,x              ;0 = right, 1 = left.
		BNE Return0              ;return if Mario is on the left side.
                    
		LDA $0E                  ; get low byte of distance between mario and sprite. 
		CLC                      ; 
		ADC #$40                 ; \ Add 40 (4 blocks)
		PHA                      ; | if it's still less than B8, the original value was <= 78 (7 1/2 blocks)
		CMP #$B8                 ; |
		BCS +                    ; /
		LDA #$01                
		STA !EXPRESSION,x 
+		PLA
		CMP #$A0                ; \ if result is more than A0, return.
		BCS Return0             ; / so the original value was <= 60 (6 blocks)

		LDA #$02                ;set expression    
		STA !EXPRESSION,x  
		INC !SPRITE_STATE,x     ;chage state to ATTACKING

		LDA #$01     
		STA !sprite_speed_x,x   ;set initial speed
                    
Return0:
		RTS        

;-----------------------------------------------------------------------------------------
; state 1
;-----------------------------------------------------------------------------------------

ATTACKING:
		STZ !sprite_speed_y,x
		JSL $01802A             ;apply speed

		LDA !sprite_speed_x,x   ;increase speed if below the max
		CMP #!MAX_X_SPEED
		BCS .dontInc
		CLC
		ADC #!SPRITE_GRAVITY
		STA !sprite_speed_x,x    
						  
.dontInc
		LDA !sprite_x_low,x     ; \
		PHA                     ; |
		CLC                     ; |
		ADC #$08                ; | move sprite x position from center of thwomp
		STA !sprite_x_low,x     ; | to the right side.
		LDA !sprite_x_high,x    ; |
		PHA                     ; |
		ADC #$00                ; |
		STA !sprite_x_high,x    ; /

		JSL $019138             ;interact with objects

		PLA                     ; \
		STA !sprite_x_high,x    ; | put it back in the center
		PLA                     ; |
		STA !sprite_x_low,x     ; /              
		
		LDA !sprite_blocked_status,x    ;RETURN if not in contact
		AND #!OBJ_CHECK
		BEQ .return

		JSR SUB_9A04            ; ?? speed related

		;LDA #!TIME_TO_SHAKE      ;shake ground
		;STA $1887    

		;LDA #!SOUND_EFFECT       ;play sound effect
		;STA $1DFC    

		LDA #!TIME_ON_GROUND     ; \ set time to stay on ground
		STA !FREEZE_TIMER,x      ; /
		INC !SPRITE_STATE,x      ;go to RETURNING state
.return:
		RTS                   

;-----------------------------------------------------------------------------------------
; state 2
;-----------------------------------------------------------------------------------------

RETURNING:
		LDA !FREEZE_TIMER,x      ;RETURN if it's not time to move the sprite
		BNE .return

		STZ !EXPRESSION,x        ;reset expression

		LDA !sprite_x_low,x      ;check if the sprite is in original position
		CMP !ORIG_X_POS,x  
		BNE .rise

		STZ !SPRITE_STATE,x      ;reset state to WAITING
		RTS                     

.rise
		LDA #!RETURN_SPEED       ;set RETURNING speed and apply it
		STA !sprite_speed_x,x     
		STZ !sprite_speed_y,x
		JSL $01802A             
.return
		RTS                       


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; graphics routine
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

!ANGRY_TILE      = $CA  

;fifth entry is the mildly angry face.
;in case of "angry", the 5th tile will be replaced by the define above.
X_OFFSET:            db $FC,$04,$FC,$04,$00 
Y_OFFSET:            db $00,$00,$10,$10,$08 
TILE_MAP:            db $8E,$8E,$AE,$AE,$C8 
PROPERTIES:          db $03,$43,$03,$43,$03


SUB_GFX:             
		%GetDrawInfo()
                    
		LDA !EXPRESSION,x   
		STA $02       
						  
		PHX                     ; preserve sprite index.
		LDX #$03                ; set loop counter
		CMP #$00                ; if expression is not 0 (not calm)
		BEQ .loop               ;
		INX                     ; increase loop counter to include the other faces.
						  
.loop
		
		LDA $00                 ; pretty default GFX routine for x,y and prop
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

		LDA TILE_MAP,x          ;
		CPX #$04                ; \ check tile index and
		BNE .normal             ; / only mess with the tile if it's the face.
		PHX                     
		LDX $02    
		CPX #$02                ; if the face is included, check if it should be angry
		BNE +                   ; if not, skip
		LDA #!ANGRY_TILE        ; if yes, make it so...
+		PLX                     
.normal:
		STA $0302|!Base2,y

		INY #4                  ; common graphics routine from here on out.                     
		DEX                     
		BPL .loop

		PLX                     
						  
		LDY #$02                ; \ 460 = 2 (all 16x16 tiles)
		LDA #$04                ;  | A = (number of tiles drawn - 1)
		JSL $01B7B3             ; / don't draw if offscreen
		RTS                     ; RETURN


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; speed related
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                    
SUB_9A04:           
		LDA !sprite_blocked_status,x
		BMI +
		LDA #$00                
		LDY !15B8,x
		BEQ ++
+		LDA #$18
++		STA !sprite_speed_x,x  
		RTS                                   
