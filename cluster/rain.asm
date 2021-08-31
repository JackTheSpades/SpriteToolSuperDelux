;----------------------------------------------------;
; Cluster Rain - by Ladida                           ;
; Can be whatever you want, just change the graphics ;
; Edit of Roy's original Spike Hell sprite           ;
; pixi and sa-1 compabitility by JackTheSpades       ;
;----------------------------------------------------;

!RainTile = $22      ;Tile # of the rain.
!RainSize = $02      ;Size of rain tile. 16x16 by default
!RainProp = $36      ;Tile property of the rain.

SpeedTableYRain:
db $05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05 ; Speed table, per sprite. Amount of pixels to move down each frame. 00 = still, 80-FF = rise, 01-7F = sink.

SpeedTableXRain:
db $FF,$FE,$FF,$FE,$FF,$FE,$FF,$FE,$FF,$FE,$FF,$FE,$FF,$FE,$FF,$FE,$FF,$FE,$FF,$FE ; Speed table, per sprite. Amount of pixels to move down each frame. 00 = still, 80-FF = rise, 01-7F = sink.

OAMStuffRain:
db $40,$44,$48,$4C,$50,$54,$58,$5C,$60,$64,$68,$6C,$80,$84,$88,$8C,$B0,$B4,$B8,$BC ; These are all in $02xx


IncrementByOneRain:
   LDA !cluster_y_low,y              ; \ Increment Y position of sprite.
   INC A                           ; |
   STA !cluster_y_low,y              ; |
   SEC                             ; | Check Y position relative to screen border Y position.
   SBC $1C                         ; | If equal to #$F0...
   CMP #$F0                        ; |
   BNE +                           ; |
   LDA #$01                        ; | Appear.
   STA !cluster_y_high,y              ; /
+
   RTL

print "MAIN ",pc
Main:                              ;The code always starts at this label in all sprites.
   LDA !cluster_y_high,y              ; \ If meant to appear, skip sprite intro code.
   BEQ IncrementByOneRain          ; /

   LDA $9D                         ; \ Don't move if sprites are supposed to be frozen.
   BNE +                           ; /
   LDA !cluster_y_low,y              ; \
   CLC                             ; |
   ADC SpeedTableYRain,y           ;  | Movement.
   STA !cluster_y_low,y              ; /

   LDA !cluster_x_low,y
   CLC
   ADC SpeedTableXRain,y
   STA !cluster_x_low,y

+                                  ; OAM routine starts here.
   LDX.w OAMStuffRain,y            ; Get OAM index.
   LDA !cluster_y_low,y              ; \ Copy Y position relative to screen Y to OAM Y.
   SEC                             ; |
   SBC $1C                         ; |
   STA $0201|!Base2,x              ; /
   LDA !cluster_x_low,y              ; \ Copy X position relative to screen X to OAM X.
   SEC                             ; |
   SBC $1A                         ; |
   STA $0200|!Base2,x              ; /
   LDA #!RainTile                  ; \ Tile
   STA $0202|!Base2,x              ; /
   LDA #!RainProp
   STA $0203|!Base2,x
   PHX
   TXA
   LSR
   LSR
   TAX
   LDA #!RainSize
   STA $0420|!Base2,x
   PLX
   LDA $18BF|!Base2
   ORA $1493|!Base2
   BEQ +                           ; Change BEQ to BRA if you don't want it to disappear at generator 2, sprite D2.
   LDA $0201|!Base2,x              ;
   CMP #$F0                        ; As soon as the sprite is off-screen...
   BCC +
   LDA #$00                        ; Kill it.
   STA !cluster_num,y;

+  RTL
