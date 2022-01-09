;-----------------------------------------------------------------------;
; Cluster Sandstorm - by Ladida                                         ;
; Great for desert levels! Can also be a snowstorm, or very strong wind.;
; Edit of Roy's original Spike Hell sprite.                             ;
; pixi and sa-1 compabitility by JackTheSpades                          ;
;-----------------------------------------------------------------------;

!SandTile = $65		;Tile # of the sand tile.
!SandSize = $00		;Size of sand tile. 8x8 by default
!SandPalPage = $30	;YXPPCCCT of tile.


SpeedTableY:
db $01,$02,$01,$02,$01,$02,$01,$02,$01,$02,$01,$02,$01,$02,$01,$02,$01,$02,$01,$02 ; Speed table, per sprite. Amount of pixels to move down each frame. 00 = still, 80-FF = rise, 01-7F = sink.

SpeedTableX:
db $F9,$FB,$FA,$FB,$F9,$FB,$FA,$FB,$F9,$FB,$FA,$FB,$F9,$FB,$FA,$FB,$F9,$FB,$FA,$FB ; Speed table, per sprite. Amount of pixels to move down each frame. 00 = still, 80-FF = rise, 01-7F = sink.

OAMStuff:
db $40,$44,$48,$4C,$50,$54,$58,$5C,$60,$64,$68,$6C,$80,$84,$88,$8C,$B0,$B4,$B8,$BC ; These are all in $02xx

Properties:
db $00,$40,$80,$C0,$00,$40,$80,$C0,$00,$40,$80,$C0,$00,$40,$80,$C0,$00,$40,$80,$C0 ; Properties table, per sprite. YXPPCCCT.

PropertiesTwo:
db $80,$C0,$00,$40,$80,$C0,$00,$40,$80,$C0,$00,$40,$80,$C0,$00,$40,$80,$C0,$00,$40 ; Properties table, per sprite. YXPPCCCT.


IncrementByOne:
	LDA !cluster_y_low,y              ; \ Increment Y position of sprite.
	INC A                           ;  |
	STA !cluster_y_low,y              ;  |
	SEC                             ;  | Check Y position relative to screen border Y position.
	SBC $1C                         ;  | If equal to #$F0...
	CMP #$F0                        ;  |
	BNE +                           ;  |
	LDA #$01                        ;  | Appear.
	STA !cluster_y_high,y              ; /

+
	RTL

print "MAIN ",pc
Main:                              ;The code always starts at this label in all sprites.
	LDA !cluster_y_high,y              ; \ If meant to appear, skip sprite intro code.
	BEQ IncrementByOne              ; /

	LDA $9D                         ; \ Don't move if sprites are supposed to be frozen.
	BNE Immobile                    ; /
	LDA $14
	AND #$03
	BEQ +
	LDA !cluster_y_low,y              ; \
	CLC                             ;  |
	ADC SpeedTableY,y               ;  | Movement.
	STA !cluster_y_low,y              ; /
+

	LDA !cluster_x_low,y
	CLC
	ADC SpeedTableX,y
	STA !cluster_x_low,y

Immobile:                          ; OAM routine starts here.
	LDX.w OAMStuff,y                ; Get OAM index.
	LDA !cluster_y_low,y              ; \ Copy Y position relative to screen Y to OAM Y.
	SEC                             ;  |
	SBC $1C                         ;  |
	STA $0201|!Base2,x              ; /
	LDA !cluster_x_low,y              ; \ Copy X position relative to screen X to OAM X.
	SEC                             ;  |
	SBC $1A                         ;  |
	STA $0200|!Base2,x              ; /
	LDA #!SandTile                  ; \ Tile
	STA $0202|!Base2,x              ; /
	LDA $14
	LSR #2
	AND #$01
	BEQ +
	LDA Properties,y
	ORA #!SandPalPage
	BRA ++
+
	LDA PropertiesTwo,y
	ORA #!SandPalPage
++
	STA $0203|!Base2,x
	PHX
	TXA
	LSR
	LSR
	TAX
	LDA #!SandSize
	STA $0420|!Base2,x
	PLX
	LDA $18BF|!Base2
	ORA $1493|!Base2
	BEQ +                           ; Change BEQ to BRA if you don't want it to disappear at generator 2, sprite D2.
	LDA $0201|!Base2,x
	CMP #$F0                        ; As soon as the sprite is off-screen...
	BCC +
	LDA #$00                        ; Kill it.
	STA !cluster_num,y              ;

+	RTL
