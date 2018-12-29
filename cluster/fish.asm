;------------------------------------------------------;
; Cluster Fish - by Ladida                             ;
; Meant to be a replacement of the normal Layer 3 fish ;
; Edit of Roy's original Spike Hell sprite             ;
; pixi and sa-1 compabitility by JackTheSpades         ;
;------------------------------------------------------;

!FishTile = $1D	;Tile # of the fish.

!FishSize = $00	;Size of fish tile. 8x8 by default

!FishProp1 = $34	;Fish Color 1. YXPPCCCT
!FishProp2 = $36	;Fish Color 2. YXPPCCCT
!FishProp3 = $38	;Fish Color 3. YXPPCCCT
!FishProp4 = $3A	;Fish Color 4. YXPPCCCT

!FishSpeed = $FF	;Fish "speed". Goes slowly to the left by default.


OAMStuffFish:
db $40,$44,$48,$4C,$50,$54,$58,$5C,$60,$64,$68,$6C,$80,$84,$88,$8C,$B0,$B4,$B8,$BC ; These are all in $02xx

FishProperties:
db !FishProp1,!FishProp2,!FishProp3,!FishProp4,!FishProp1,!FishProp2,!FishProp3,!FishProp4,!FishProp1,!FishProp2,!FishProp3,!FishProp4,!FishProp1,!FishProp2,!FishProp3,!FishProp4,!FishProp1,!FishProp2,!FishProp3,!FishProp4 ; Properties table, per sprite. YXPPCCCT.


print "MAIN ",pc
Main:				;The code always starts at this label in all sprites.
LDA #$01
STA $1E2A|!Base2,y

LDA $9D				; \ Don't move if sprites are supposed to be frozen.
BNE ImmobileFish		; /

LDA $14
AND #$01
BEQ +
LDA $1E16|!Base2,y
CLC
ADC #!FishSpeed
STA $1E16|!Base2,y
+

ImmobileFish:                   ; OAM routine starts here.
LDX.w OAMStuffFish,y 		; Get OAM index.
LDA $1E02|!Base2,y			; \ Copy Y position relative to screen Y to OAM Y.
SEC                             ;  |
SBC $1C				;  |
STA $0201|!Base2,x			; /
LDA $1E16|!Base2,y			; \ Copy X position relative to screen X to OAM X.
SEC				;  |
SBC $1A				;  |
STA $0200|!Base2,x			; /
LDA #!FishTile			; \ Tile
STA $0202|!Base2,x                     ; /
LDA FishProperties,y
STA $0203|!Base2,x
PHX
TXA
LSR
LSR
TAX
LDA #!FishSize
STA $0420|!Base2,x
PLX
LDA $18BF|!Base2
ORA $1493|!Base2
BEQ +            ; Change BEQ to BRA if you don't want it to disappear at generator 2, sprite D2.
LDA $0201|!Base2,x
CMP #$F0                                    	; As soon as the sprite is off-screen...
BCC +
LDA #$00					; Kill it.
STA $1892|!Base2,y					;

+  RTL
