;-----------------------------------------------------------------------;
; Cluster Flower Petals - by Ladida                                     ;
; Can be anything, like petals, leaves, snow; just change the graphics. ;
; Edit of Roy's original Spike Hell sprite.                             ;
; pixi and sa-1 compabitility by JackTheSpades                          ;
;-----------------------------------------------------------------------;

!FlowerTile = $6F	;Tile # of the flower petal.
!FlowerSize = $00	;Size of flower petal. 8x8 by default
!FlowerPalPage = $35	;YXPPCCCT of tile. XY flip handled by Properties table.


SpeedTableY:
db $01,$02,$01,$02,$01,$02,$01,$02,$01,$02,$01,$02,$01,$02,$01,$02,$01,$02,$01,$02 ; Speed table, per sprite. Amount of pixels to move down each frame. 00 = still, 80-FF = rise, 01-7F = sink.

SpeedTableX:
db $FD,$FF,$FE,$FF,$FD,$FF,$FE,$FF,$FD,$FF,$FE,$FF,$FD,$FF,$FE,$FF,$FD,$FF,$FE,$FF ; Speed table, per sprite. Amount of pixels to move down each frame. 00 = still, 80-FF = rise, 01-7F = sink.

SpeedTableXTwo:
db $FF,$FE,$FD,$FE,$FF,$FE,$FD,$FE,$FF,$FE,$FD,$FE,$FF,$FE,$FD,$FE,$FF,$FE,$FD,$FE ; Speed table, per sprite. Amount of pixels to move down each frame. 00 = still, 80-FF = rise, 01-7F = sink.

OAMStuff:
db $40,$44,$48,$4C,$50,$54,$58,$5C,$60,$64,$68,$6C,$80,$84,$88,$8C,$B0,$B4,$B8,$BC ; These are all in $02xx

Properties:
db $00,$40,$80,$C0,$00,$40,$80,$C0,$00,$40,$80,$C0,$00,$40,$80,$C0,$00,$40,$80,$C0 ; Properties table, per sprite. YXPPCCCT.

PropertiesTwo:
db $80,$C0,$00,$40,$80,$C0,$00,$40,$80,$C0,$00,$40,$80,$C0,$00,$40,$80,$C0,$00,$40 ; Properties table, per sprite. YXPPCCCT.

IncrementByOne:
	LDA $1E02|!Base2,y              ; \ Increment Y position of sprite.
	INC A                           ; |
	STA $1E02|!Base2,y              ; |
	SEC                             ; | Check Y position relative to screen border Y position.
	SBC $1C                         ; | If equal to #$F0...
	CMP #$F0                        ; |
	BNE .return                     ; |
	LDA #$01                        ; | Appear.
	STA $1E2A|!Base2,y              ; /

.return
	RTL

print "MAIN ",pc
Main:                              ;The code always starts at this label in all sprites.
	LDA $1E2A|!Base2,y              ; \ If meant to appear, skip sprite intro code.
	BEQ IncrementByOne              ; /

	LDA $9D                         ; \ Don't move if sprites are supposed to be frozen.
	BNE Immobile                    ; /
	LDA $14                         ; \
	AND #$01                        ; | only every second frame
	BEQ +                           ; /
	LDA $1E02|!Base2,y              ; \
	CLC                             ; |
	ADC SpeedTableY,y               ; | Movement.
	STA $1E02|!Base2,y              ; /
+

	LDA $14
	LSR #5
	AND #$01
	BEQ +
	LDA $1E16|!Base2,y
	CLC
	ADC SpeedTableX,y
	BRA ++
+
	LDA $1E16|!Base2,y
	CLC
	ADC SpeedTableXTwo,y
++
	STA $1E16|!Base2,y

Immobile:                       ; OAM routine starts here.
	LDX.w OAMStuff,y             ; Get OAM index.
	LDA $1E02|!Base2,y           ; \ Copy Y position relative to screen Y to OAM Y.
	SEC                          ; |
	SBC $1C                      ; |
	STA $0201|!Base2,x           ; /
	LDA $1E16|!Base2,y           ; \ Copy X position relative to screen X to OAM X.
	SEC                          ; |
	SBC $1A                      ; |
	STA $0200|!Base2,x           ; /
	LDA #!FlowerTile             ; \ Tile
	STA $0202|!Base2,x           ; /
	LDA $14
	LSR #2
	AND #$01
	BEQ +
	LDA Properties,y
	ORA #!FlowerPalPage
	BRA ++
+
	LDA PropertiesTwo,y
	ORA #!FlowerPalPage
++
	STA $0203|!Base2,x
	PHX
	TXA
	LSR
	LSR
	TAX
	LDA #!FlowerSize
	STA $0420|!Base2,x
	PLX
	LDA $18BF|!Base2
	ORA $1493|!Base2
	BEQ .return                  ; Change BEQ to BRA if you don't want it to disappear at generator 2, sprite D2.
	LDA $0201|!Base2,x
	CMP #$F0                     ; As soon as the sprite is off-screen...
	BCC .return
	LDA #$00	                    ; Kill it.
	STA $1892|!Base2,y           ;

.return
	RTL
