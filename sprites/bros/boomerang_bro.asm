;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Boomerang Brother, by mikeyk
;;
;; Description: Similar to his role in SMB3, this guy throws boomerangs at Mario. 
;;
;; BIG FAT NOTE: This sprite depends on the boomerang sprite.  Make sure you insert the
;; boomerang as the very next sprite.  (ex. If this is sprite 1B, make the boomerang 1C)
;;
;; Uses first extra bit: NO
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



;Graphical Properties for the tile the bro is holding up before throwing it
	!Throw_Tile = $4E
	!Throw_Prop = $83
	!Throw_XOff = $0A




	!JUMP_TIMER = !163E            ;Decrements itself per frame!!!!
	!RAM_ThrowTimer = !1504        ;DOESN'T decrement itself!!!!!!!

	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Routine that spawns the sprite to be thrown
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SpawnThrowSprite:
		LDA !157C,x
		TAY
		LDA Throw_Offset,y
		STA $00
		LDA #$F2
		STA $01
		STZ $02
		STZ $03

		LDA !new_sprite_num,x   ; \ sprite number is this' number +1
		INC                     ; /
		SEC                     ; set spawn to be custom sprite
		%SpawnSprite()          ; spawn sprite
		BCS +                   ; return if failed
				
		LDA !157C,x             ; \ same direction as bro is facing.
		STA !157C,y             ; /
		LDA #$4E                ; \ set timer until change direction
		STA !1540,y             ; / 
		
+		RTS
	
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; sprite data
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;16x16 body tile, 8x8 foot tile 1, 8x8 foot tile 2, dummy
TILEMAP:            db $46,$4A,$7F,$00		;walking 1
                    db $46,$5A,$2F,$00		;walking 2
                    db $48,$4A,$7F,$00		;throwing 1
                    db $48,$5A,$2F,$00		;throwing 2

HORZ_DISP:          db $00,$00,$08         ;facing left
                    db $00,$08,$00         ;facing right
VERT_DISP:          db $F8,$08,$08
TILE_SIZE:          db $02,$00,$00

PROPERTIES:         db $40,$00             ;xyppccct format

						  
Throw_Offset:       db $100-!Throw_XOff,!Throw_XOff

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; init JSL
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

print "INIT ",pc
		%SubHorzPos()
		TYA
		STA !157C,x

		TXA                     ; \ use sprite index as base for a touch of randomness
		AND #$03                ; |
		ASL #5                  ; |
		STA !JUMP_TIMER,x       ; / jump timer randomly $00, $20, $40, $60
		CLC
		ADC #$32
		STA !RAM_ThrowTimer,x                 

		RTL

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; main sprite JSL
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

print "MAIN ",pc
		PHB                     ; \
		PHK                     ;  | main sprite function, just calls local subroutine
		PLB                     ;  |
		JSR START_HB_CODE       ;  |
		PLB                     ;  |
		RTL                     ; /
		
DecTimers:
		LDA !RAM_ThrowTimer,x
		BEQ .done
		DEC !RAM_ThrowTimer,x
.done:
		RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; main sprite routine
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;indexed by 151C
X_SPEED:            db $00,$F8,$00,$08     ;rest at bottom, moving up, rest at top, moving down
TIME_IN_POS:        db $48,$10,$48,$10     ;moving up, rest at top, moving down, rest at bottom

;indexed by C2
TIME_TILL_THROW:    db $F7,$62

;STAR:               INC !RAM_ThrowTimer,x

Return:
		RTS                    
START_HB_CODE:

		JSR SUB_GFX             ; draw hammer bro gfx
		LDA !14C8,x             ; \ if hammer bro status != 8...
		;CMP #$02                ;  }   ... not (killed with spin jump [4] or STAR[2])
		;BEQ STAR
		CMP #$08
		BNE Return              ; /    ... RETURN
		LDA $9D                 ; \ if sprites locked...
		BNE Return              ; / return
				
		JSR DecTimers           ; decrement timers (that aren't self decrementing)
				
		LDA #$00                ; sub_off_screen_x0
		%SubOffScreen()         ; only process hammer bro while on screen
						  
		%SubHorzPos()           ; \ always face mario
		TYA                     ;  | 
		STA !157C,x             ; /
						  
		;1570 = on screen frame counter
		;151C = speed phase
		;         00 = stand still
		;         01 = move back
		;         02 = stand still
		;         03 = move forward
		;1602 = animation display frame counter
		
		INC !1570,x             ; increment number of frames hammer bro has been on screen
		
;Code to handle the "base" animation frame to display
;$1602 will be either 0 or 1, throwing code may offset it by 2.
		LDA !151C,x             ; \
		AND #$01                ; | skip if we're in a "stant still" phase
		BEQ +                   ; /
						  
		LDA !1570,x             ; \ calculate which frame to show:
		LSR #3                  ; | 
		AND #$01                ; | update every 16 cycles if normal
		BRA ++                  ; / skip ahead and just store
		
+		LDA !151C,x             ; \ if in "stand still phase 0", set frame to 0
		BEQ ++                  ; | 
		LDA #$01                ; | if in "stand still phase 2", set frame to 1
++		STA !1602,x             ; / write frame to show

;Code to handle the throw timer
		LDA !RAM_ThrowTimer,x   ; \  
		CMP #$22                ; | Check throw timer
		BCS Jumping             ; | skip if it's more than the limit already
		INC !1602,x             ; | if not, move animation frame into the "throwing" range.
		INC !1602,x             ; /
                
		LDA !RAM_ThrowTimer,x   ; \ 
		BNE +                   ; | if it's not time to throw yet, skip over stuff
		LDY !C2,x               ; | set throw timer again (depending on $C2)
		LDA TIME_TILL_THROW,y   ; |
		STA !RAM_ThrowTimer,x   ; /
+		CMP #$01                ; \
		BNE Jumping             ; | when timer = 1
		LDA !C2,x               ; | invert $C2 for next reset of timer
		EOR #$01                ; | and spawn the sprite
		STA !C2,x               ; | if not, skip ahead.
		JSR SpawnThrowSprite    ; /

;Code to handle the jumping part.
Jumping:
		LDA !JUMP_TIMER,x       ; \ if timer still above $28
		CMP #$28                ; | just go to normal walking code
		BCS Speed               ; /
		LDA !JUMP_TIMER,x       ; \
		CMP #$21                ; | if timer is $21, do jump
		BNE .reset              ; / if not, do skip
		LDA !1570,x             ; \
		LSR A                   ; |
		AND #01                 ; |
		BEQ .reset              ; /
		LDA #$D0                ; \ set y speed
		STA !AA,x               ; | and just move to updating speeds
		BRA Speed_apply         ; / 
						  
.reset
		CMP #$00                ; \
		BNE Speed               ; | check if it's time to reset the jump timer
		LDA #$FE                ; | and do if so.
		STA !JUMP_TIMER,x       ; /

;Code to handle the sprite's back and forth movement.
Speed:
		LDA !151C,x             ; \ speed phase in Y
		TAY                     ; /
		LDA !1540,x             ; \ change speed phase and reset timer if timer is up.
		BEQ .change             ; /
		LDA X_SPEED,y           ; \ set x speed based on phase.
		STA !B6,x               ; /
		BRA .apply
                    
.change
		LDA TIME_IN_POS,y       ; \
		STA !1540,x             ; | set turning timer (decrements itself)
		LDA !151C,x             ; |
		INC A                   ; | and increment the speed phase.
		AND #$03                ; |
		STA !151C,x             ; /                    
.apply
		JSL $01802A             ; update position based on speed values


		LDA !1588,x             ; \ if hammer bro is not touching the side of an object...
		AND #$03                ; | skip ahead
		BEQ +                   ; /
		LDA !151C,x             ; \
		INC A                   ; | if he is, move to next speed phase.
		AND #$03                ; |
		STA !151C,x             ; /      
+

;Code to handle basic contact routine
		JSL $018032             ; interact with other sprites               
		JSL $01A7DC             ; check for mario/hammer bro contact
		RTS



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; graphics routine
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SUB_GFX:
		%GetDrawInfo()          ; after: Y = index to sprite tile map ($300)
									   ;      $00 = sprite x position relative to screen boarder 
									   ;      $01 = sprite y position relative to screen boarder  
		LDA !1602,x             ; \
		ASL #2                  ;  | $03 = index to frame start (frame to show * 2 tile per frame)
		STA $03                 ; /
		LDA !157C,x             ; \ $02 = sprite direction
		STA $02                 ; /
		PHX                     ; push sprite index

		LDX #$02                ; loop counter = (number of tiles) - 1
.loop
		PHX                     ; push current tile number
         
		TXA                     ; \  put tile number in A
		LDX $02                 ;  | 
		BNE +                   ;  | and if sprite faces left, add 3
		CLC                     ;  | and put it back in X
		ADC #$03                ;  |
+     TAX                     ; /
		LDA $00                 ; \  tile x position + offset depending on direction
		CLC : ADC HORZ_DISP,x   ;  | 
		STA $0300|!Base2,y      ; /   
		
		PLX                     ; get tile number back in X
								 
		LDA $01                 ; \ tile y position = sprite y location ($01) + tile displacement
		CLC                     ;  |
		ADC VERT_DISP,x         ;  |
		STA $0301|!Base2,y      ; /

		LDA TILE_SIZE,x         ; get size for current tile
		PHX                     ; \ preserve A (tile size) and X (tile number)
		PHA                     ; /
		TYA                     ; \  get index to sprite property map ($460)...
		LSR A                   ; |    ...we use the sprite OAM index...
		LSR A                   ; |    ...and divide by 4 OAM has 4 bytes per slot and this only 1.
		TAX                     ; | 
		PLA                     ; | store tile size (2 = 16x16, 0 = 8x8)
		STA $0460|!Base2,x      ; / 
		PLX                     ; restore tile number             

		PHX							; save tile number again
		TXA                     ; \  X = index to horizontal displacement
		ORA $03                 ;  | get index of tile (index to first tile of frame + current tile number)
		TAX                     ; /

		LDA TILEMAP,x           ; \ store tile
		STA $0302|!Base2,y      ; / 

		LDX $02                 ; \
		LDA PROPERTIES,x        ;  | get tile PROPERTIES using sprite direction
		LDX $15E9|!Base2        ;  |
		ORA !15F6,x             ;  | get palette info
		ORA $64                 ;  | put in level PROPERTIES
		STA $0303|!Base2,y      ; / store tile PROPERTIES

		PLX                     ; \  pull, X = current tile of the frame we're drawing
		INY                     ;  | increase index to sprite tile map ($300)...
		INY                     ;  |    ...we wrote 1 16x16 tile...
		INY                     ;  |    ...sprite OAM is 8x8...
		INY                     ;  |    ...so increment 4 times
		DEX                     ;  | go to next tile of frame and loop
		BPL .loop               ; / 

		PLX                     ; pull, X = sprite index
                    
		LDA !RAM_ThrowTimer,x
		CMP #$02
		BCC .DontShowTTile
		CMP #30
		BCS .DontShowTTile
		LDA !1602,x
		CMP #$02
		BCS .ShowThrowTile
                    
.DontShowTTile
		LDY #$FF                ; \ 02, because we didn't write to 460 yet
		LDA #$02                ;  | A = number of tiles drawn - 1
		JSL $01B7B3             ; / don't draw if offscreen
		RTS                     ; RETURN

.ShowThrowTile
		PHX                     ; preserve sprite index
                    
		LDA $00                 ; \
		LDX $02                 ;  | x position + offset (depending on sprite direction)
		CLC : ADC Throw_Offset,x;  |
		STA $0300|!Base2,y      ; /

		LDA $01                 ; \ 
		CLC : ADC #$F2          ; | y position + offset
		STA $0301|!Base2,y      ; /

		LDA #!Throw_Tile        ; \ store tile
		STA $0302|!Base2,y      ; / 

		TYA                     ; \  get index to sprite property map ($460)...
		LSR A                   ; |    ...we use the sprite OAM index...
		LSR A                   ; |    ...and divide by 4 OAM has 4 bytes per slot and this only 1.
		TAX                     ; | 
		LDA #$02                ; | store tile size (2 = 16x16, 0 = 8x8)
		STA $0460|!Base2,x      ; /  

		LDA #!Throw_Prop        ; \  load throw tile properties.
		BIT $02                 ;  | depending on sprite direction...
		BEQ +                   ;  | ... add x-flip bit to properties
		ORA #$40                ;  |
+		ORA $64                 ;  | put in level properties
		STA $0303|!Base2,y      ; /  store tile properties

		PLX                     ; retore sprite index

		LDY #$FF                ; \  
		LDA #$03                ;  | A = number of tiles drawn - 1
		JSL $01B7B3             ; /  don't draw if offscreen
		RTS                     ; RETURN
