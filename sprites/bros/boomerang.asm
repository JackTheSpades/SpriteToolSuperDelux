;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Boomerang (for Boomerang Brother), by mikeyk
;; asar and sa-1 version by JackTheSpades
;;
;; Description: This is the boomerang that the Boomerang Brother throws.
;;
;; BIG FAT NOTE: This sprite depends on the boomerang brother sprite.  Make sure you
;; insert the boomerang brother right before this sprite.  (ex. If this is sprite 1C,
;; make the boomerang brother 1B)
;;
;; Uses first extra bit: NO
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	!SLOW_DOWN_TIMER = !1504
                    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; sprite data
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	!SLOWDOWN_TIME = $20
	!TIME_UNTIL_CHANGE = $38

TILEMAP:            db $4B,$4E,$4B,$4E
PROPERTIES:         db $C3,$03,$03,$C3

X_SPEED:            db $20,$E0,$18,$E8     ; speed of sprite, right, left
Y_SPEED:            db $F8,$F8,$09,$09
                    db $00,$00,$08,$08



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; init JSL
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

print "INIT ",pc
		STZ !SLOW_DOWN_TIMER,x
		RTL
                    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; main sprite JSL
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

print "MAIN ",pc
		PHB                     ; \
		PHK                     ;  | main sprite function, just calls local subroutine
		PLB                     ;  |
		JSR DECREMENTTIMERS
		JSR START_SPRITE_CODE   ;  |
		PLB                     ;  |
		RTL                     ; /
		
DECREMENTTIMERS:
		LDA !14C8,x
		CMP #$08
		BNE .done
		LDA $9D
		BNE .done
		LDA !SLOW_DOWN_TIMER,x
		BEQ .done
		DEC !SLOW_DOWN_TIMER,x
.done
		RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; main sprite routine
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

START_SPRITE_CODE:
		JSR SUB_GFX             ; draw sprite gfx
		LDA !14C8,x             ; \ if sprite status != 8...
		CMP #$08                ;  }   
		BNE .return             ; /    ... RETURN
		LDA $9D                 ; \ if sprites locked...
		BNE .return             ; /    ... RETURN

		LDA #$00
		%SubOffScreen()         ; only process sprite while on screen
		
		INC !1570,x             ; increment number of frames sprite has been on screen
                    
		LDY !157C,x             
		LDA !SLOW_DOWN_TIMER,x  ; \ if the slow down timer is set, 
		BNE .slower             ; / then slow down the sprite
		LDA !1540,x             ; \ also slow down the sprite if its about
		BEQ .set_speed          ;  | to change direction.
		CMP #!SLOWDOWN_TIME     ;  | ( 0 < timer < !SLOWDOWN_TIME )
		BCS .set_speed          ; /
						  
.slower   
		INY                     ; \ increment index to use slower speeds
		INY                     ; /
.set_speed
		LDA X_SPEED,y           ; \ set the x speed
		STA !B6,x               ; / 
                    
		LDA !C2,x   
		BEQ +
		INY
		INY
		INY
		INY
+		LDA Y_SPEED,y
		STA !AA,x  
                    
		JSL $01802A             ; update position based on speed values

		LDA !1540,x             ; \ check if its time to change directions
		CMP #$01                ;  | ($1540 about to expire)
		BNE +                   ; /
		LDA !157C,x             ; \ change direction
		EOR #$01                ;  |
		STA !157C,x             ; /
		LDA #!SLOWDOWN_TIME     ; \ set time to slow down sprite
		STA !SLOW_DOWN_TIMER,x  ; /
		INC !C2,x               ; increment turn count
+            
		JSL $01A7DC             ; check for mario/sprite contact
.return
		RTS                     ; RETURN


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; graphics routine
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SUB_GFX:           
		%GetDrawInfo()         ; after: Y = index to sprite tile map ($300)
									  ;      $00 = sprite x position relative to screen boarder 
									  ;      $01 = sprite y position relative to screen boarder  

		LDA !1570,x            ; \  calculate which frame to show
		LSR A                  ;  | based on how long sprite's been alive
		LSR A                  ;  |   
		AND #$03               ;  | 
		STA $03                ; /

		; LDA !157C,x            ; \ $02 = sprite direction
		; PHY
		; LDY !1540,x 
		; BEQ +
		; CPY #!SLOWDOWN_TIME
		; BCS +
		; EOR #$01
		
; +		PLY
		; STA $02                 ; /		
                                        
		LDA $00                 ; \ tile x position = sprite x location ($00)
		STA $0300|!Base2,y      ; /

		LDA $01                 ; \ tile y position = sprite y location ($01) + tile displacement
		STA $0301|!Base2,y      ; /

		PHX                     ; push sprite index
		LDX $03                 ; \
		LDA TILEMAP,x           ;  | get sprite tile
		STA $0302|!Base2,y      ; / 
		LDA PROPERTIES,x        ; \  get sprite pallette
		PLX                     ;  | pull, X = sprite index
		ORA !15F6,x             ;  | get palette info
		ORA $64                 ;  | put in level PROPERTIES
		STA $0303|!Base2,y      ; / store tile PROPERTIES

		LDY #$02                ; \ 02, because 16x16 tiles
		LDA #$00                ;  | A = number of tiles drawn - 1
		JSL $01B7B3             ; / don't draw if offscreen
		RTS                     ; RETURN
             