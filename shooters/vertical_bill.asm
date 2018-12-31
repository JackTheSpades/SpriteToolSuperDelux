;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; original shooters by mikey and 682
; update and sa-1 support by JackTheSpades
;
; Vertical (up and down) Bullet Bill Shooter
; 
; Extra Bit Set   = Shoots Up
; Extra Bit Clear = Shoots Down
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


; Cheat Sheet for Bullet Bill $C2,x                    
; #$00 = Right
; #$01 = Left
; #$02 = Up
; #$03 = Down
; #$04 = Right Up
; #$05 = Right Down
; #$06 = Left Down
; #$07 = Left Up

!C2ExSet = $02
!C2ExClr = $03

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; sprite code JSL
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
print "INIT ",pc 
print "MAIN ",pc                                    
      PHB                     
      PHK                     
      PLB                     
      JSR SPRITE_CODE_START   
      PLB                     
      RTL      

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; main bullet bill shooter code
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Return:
      RTS                     ; RETURN
      
SPRITE_CODE_START:
      
      LDA #$60 : CLC          ; \ if necessary, restore timer to 60 and ignore Mario next to shooter
      %ShooterMain()          ; | check if time to shoot, return if not. (Y now contains new sprite index)
      BCS Return              ; /

Shoot:
      LDA #$09                ; \ play sound effect
      STA $1DFC|!Base2        ; /
      ;LDA #$01                ; \ set sprite status for new sprite
      ;STA !14C8,y             ; /
      LDA #$1C                ; \ set sprite number for new sprite
      STA.w !9E,y             ; /
      LDA $179B|!Base2,x      ; \ set x position for new sprite
      STA.w !E4,y             ;  |
      LDA $17A3|!Base2,x      ;  |
      STA !14E0,y             ; /
      LDA $178B|!Base2,x      ; \ set y position for new sprite
      SEC                     ;  | (y position of generator - 1)
      SBC #$01                ;  |
      STA.w !D8,y             ;  |
      LDA $1793|!Base2,x      ;  |
      SBC #$00                ;  |
      STA !14D4,y             ; /
      PHX                     ; \ before: X must have index of sprite being generated
      TYX                     ;  | routine clears old sprite values...
      JSL $07F7D2             ;  | ...and loads in new values for the 6 main sprite tables
      PLX                     ; / 
      LDA #$08                ;
      STA !14C8,y             ;

      
      LDA $1783|!Base2,x      ; \
      AND #$40                ;  |
      BEQ +                   ;  |
      LDA #!C2ExSet           ;  | get C2 value depending on extra bit of sprite.
      BRA ++                  ;  |
+     LDA #!C2ExClr           ;  |
++    STA.w !C2,y             ; /
      
      JSR Smoke_spawn
      RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; display smoke effect bullet bill shooter
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
     
Smoke:
.y_off:   db $00,$00,$00,$00,$FA,$04,$04,$FA
.x_off:   db $00,$00,$00,$00,$04,$04,$FA,$FA     

.spawn
      PHX                     ;
      LDA !C2,y               ; \ Get index for smoke sprite offset.
      TAX                     ; | 
      LDA .x_off,x : STA $00  ; | x offset
      LDA .y_off,x : STA $01  ; | y offset
      LDA #$1B : STA $02      ; | smoke timer
      LDA #$01                ; | smoke sprite
      TYX                     ; | cheating*
      %SpawnSmoke()           ; / ~SPAWNING~
      PLX
      RTS           
      
;*cheating because the SmokeSprite routine is actually intended for sprites, not shooters.
;however, since we just spawned a sprite (which's index is in Y) we can just take it's index
;and put it into x