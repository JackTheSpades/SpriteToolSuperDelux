;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Piranha Plant/Venus Fire Trap, by imamelia
;;
;; This sprite encompasses all 48 Classic Piranha Plants and Venus Fire Traps,
;; using the extra property bytes to determine which sprite to act like.
;;
;; Uses first extra bit: YES
;; Uses extra property bytes: YES
;;
;; If the first extra bit is clear, the sprite will use the first extra property byte.
;; If the first extra bit is set, the sprite will use the second extra property byte.
;;
;; Extra Property Bytes:
;;
;; Bit 0: Direction.  0 = up/left, 1 = right/down.
;; Bit 1: Orientation.  0 = vertical, 1 = horizontal.
;; Bit 2: Stem length.  0 = long, 1 = short.
;; Bit 3: Color.  0 = green, 1 = red.
;; Bit 4: Sprite type.  0 = Piranha Plant, 1 = Venus Fire Trap.
;; Bit 5: Number of fireballs.  0 = spit 1, 1 = spit 2.  This is used only if bit 4 is set.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;incsrc subroutinedefsx.asm

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; defines and tables
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; $151C,x = holder for the sprite's initial Y position low byte
; $1528,x = holder for the sprite's initial X position low byte

Speed:			; the Piranha Plant's speed for each sprite state (inverted for down and right plants)
db $00,$F0,$00,$10		; in the pipe, moving forward, resting at the apex, moving backward

TimeInState:		; the time the sprite will spend in each sprite state, indexed by bits 2, 4, and 5 of the behavior table

db $30,$20,$30,$20	; long Piranha Plants
db $30,$18,$30,$18	; short Piranha Plants
db $30,$20,$60,$20	; long Venus Fire Traps spitting 1 fireball
db $30,$18,$60,$18	; short Venus Fire Traps spitting 1 fireball
db $FF,$FF,$FF,$FF		; null
db $FF,$FF,$FF,$FF		; null
db $30,$20,$90,$20	; long Venus Fire Traps spitting 2 fireballs
db $30,$18,$90,$18	; short Venus Fire Traps spitting 2 fireballs

; All of these tables are indexed by ----todf,
; where f = frame, d = direction, o = orientation, and t = type.

HeadXOffset:
db $00,$00,$00,$00,$00,$00,$10,$10,$00,$00,$00,$00,$00,$00,$10,$10

HeadYOffset:
db $00,$00,$10,$10,$00,$00,$00,$00,$00,$00,$10,$10,$00,$00,$00,$00

StemXOffset:
db $00,$00,$00,$00,$10,$10,$00,$00,$00,$00,$00,$00,$10,$10,$00,$00

StemYOffset:
db $10,$10,$00,$00,$00,$00,$00,$00,$10,$10,$00,$00,$00,$00,$00,$00

; up, down, left, right
; head:
; X=00/Y=00, X=00/Y=10, X=00/Y=00, X=10/Y=00
; stem:
; X=00/Y=10, X=00/Y=00, X=10/Y=00, X=00/Y=10

StemTilemap:			; the tiles used by the stem
db $CE,$CE,$CE,$CE,$E6,$E6,$E6,$E6,$CE,$CE,$CE,$CE,$E6,$E6,$E6,$E6

HeadTilemap:			; the tiles used by the head
db $AE,$AC,$AE,$AC,$80,$88,$80,$88,$C0,$C2,$C0,$C2,$C0,$C2,$C0,$C2

TileFlip:				; the X- and Y-flip of each tile
db $00,$00,$80,$80,$00,$00,$40,$40,$00,$00,$80,$80,$00,$00,$40,$40

; These two are different.  They are indexed by ------lc, where c = color and l = length.
; Add 1 to each of these values if you want the tile to use the second graphics page.

StemPalette:			; the palette of the stem tiles
db $0A,$08,$0A,$08

HeadPalette:			; the palette of the head tiles
db $08,$08,$0A,$08

; This tile will be invisible because it has sprite priority setting 0,
; but it will go in front of the plant tiles to cover it up when it is in a pipe.
; That way, the plant tiles don't need to have hardcoded priority.
; This tile should be as close to square as possible.
; Note: The default value WILL NOT completely hide the tiles unless you have changed its graphics!
; But the only completely square tile in a vanilla GFX00/01 is the message box tile, which is set to be overwritten by default.

!CoverUpTile = $40			; the invisible tile used to cover up the sprite when it is in a pipe

; these two tables are indexed by the direction and orientation

CoverUpXOffset:		;
db $00,$00,$00,$10	;

CoverUpYOffset:		;
db $00,$10,$00,$00	;

InitOffsetYLo:
db $FF,$EF,$08,$08

InitOffsetYHi:
db $FF,$FF,$00,$00

InitOffsetXLo:
db $08,$08,$FF,$EF

InitOffsetXHi:
db $00,$00,$FF,$FF

VenusFrames:		; which head tile the Venus Fire Trap should use for each sprite state
db $00,$00,$01,$00

Clipping:
db $01,$14

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; init routine wrapper
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

print "INIT ",pc
PHB
PHK
PLB
JSR PiranhaInit
PLB
RTL

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; init routine
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PiranhaInit:

LDA !extra_bits,x	; check the extra bit
AND #$04	; if the extra bit is clear...
BNE EP2		;
LDA !extra_prop_1,x	; use the extra property byte 1
BRA StoreEP	;
EP2:		;
LDA !extra_prop_2,x	;
StoreEP:		;
STA !1510,x	;

AND #$03	;
TAY		; direction and orientation used to index inital offsets
LDA !D8,x	;
CLC		;
ADC InitOffsetYLo,y	; Y position low byte
STA !D8,x	;
LDA !14D4,x	;
ADC InitOffsetYHi,y	; Y position high byte
STA !14D4,x	;
LDA !E4,x	;
CLC		;
ADC InitOffsetXLo,y	; X position low byte
STA !E4,x		;
LDA !14E0,x	;
ADC InitOffsetXHi,y	; X position high byte
STA !14E0,x	;

TYA		;
LSR		;
TAY		;
LDA Clipping,y	;
STA !1662,x	;

LDA !1510,x	; get the bits for the sprite state timer index
AND #$04	; bit 2
STA !1504,x	;
LDA !1510,x	;
AND #$10	; bit 4
LSR		;
ORA !1504,x	;
STA !1504,x	;
LDA !1510,x	;
AND #$30	; bits 4 and 5
CMP #$30		; if the sprite is a Venus Fire Trap that spits 2 fireballs...
BNE No2Fireballs	;
LDA !1504,x	; then add another 4 to the index
CLC		;
ADC #$04	;
STA !1504,x	;
No2Fireballs:	;

EndInit1:		;

LDA !D8,x	;
STA !151C,x	; back up the sprite's initial XY position (low bytes)
LDA !E4,x	;
STA !1528,x	;

RTS


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; main routine wrapper
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

print "MAIN ",pc
PHB
PHK
PLB
JSR PiranhaPlantsMain
PLB
RTL

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; main routine
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EndMain:
RTS

PiranhaPlantsMain:

;LDA $1594,x		; if the sprite is in a pipe and the player is near...
;BNE NoGFX		; don't draw the sprite
LDA !C2,x		;
BEQ NoGFX		;

JSR PiranhaPlantGFX		; draw the sprite

NoGFX:			;

LDA #$00
%SubOffScreen()		;

LDA $9D			; if sprites are locked...
BNE EndMain		; terminate the main routine right here

LDA !1510,x		;
AND #$10		; if the sprite is a Venus Fire Trap...
BEQ PiranhaAnimation	; use a different routine for its animation

LDY !C2,x		;
LDA VenusFrames,y		;
STA !1602,x		;
CPY #$02			;
BNE SkipPiranhaAnimation	;
JSR FacePlayer		; always face the player if the Venus Fire Trap is out of the pipe
BRA SkipPiranhaAnimation	;

Fire:			;
JMP SpitFireball		;

PiranhaAnimation:		;

JSR SetAnimationFrame	; determine which frame the plant should show

SkipPiranhaAnimation:	;

LDA !1594,x		; if the plant is in a pipe...
BNE NoInteraction		; don't let it interact with the player

JSL $01803A|!BankB		; interact with the player and other sprites

NoInteraction:		;

LDA !1510,x		;
AND #$10		; if the sprite isn't a Venus Fire Trap...
BEQ NoFireCheck		; don't check to see if it should spit a fireball

LDA !C2,x		; if the sprite is a Venus Fire Trap...
CMP #$02			; then make sure it's in the correct sprite state (resting at the apex)
BNE NoFireCheck		;

LDA !1540,x		;
CMP #$61			; if the fire timer
BEQ Fire			; is at certain numbers...
CMP #$19			; spit a fireball
BEQ Fire			;

NoFireCheck:

LDA !C2,x		; use the sprite state
AND #$03		; to determine what the sprite's speed should be
TAY			;
LDA !1540,x		; if the timer for changing states has run out...
BEQ ChangePiranhaState	;

LDA !1510,x		; check whether the sprite is rightside-up/left or upside-down/right
LSR			;
LDA Speed,y		; load the base speed
BCC StoreSpeed		; if upside-down/right...
EOR #$FF			; flip its speed
INC			;
StoreSpeed:		;
TAY			; transfer the speed value to Y because we need to use A
LDA !1510,x		; check the secondary sprite state
AND #$02		; check whether the sprite is vertical or horizontal
BNE MoveHorizontally	;

STY !AA,x		; store the speed value to the sprite Y speed table
JSL $01801A|!BankB	; update sprite Y position without gravity
RTS			;

MoveHorizontally:		;

STY !B6,x			; store the speed value to the sprite X speed table
JSL $018022|!BankB	; update sprite X position without gravity
RTS			;

ChangePiranhaState:	;

LDA !1510,x		;
AND #$10		; if the sprite is a Venus Fire Trap...
BEQ NoFacePlayer		;
LDA !C2,x		; and it is about to come out of the pipe...
BNE NoFacePlayer		;

JSR FacePlayer		;

NoFacePlayer:		;

LDA !C2,x		; sprite state
AND #$03		; 4 possible states, so we need only 2 bits
STA $00			; store to scratch RAM for subsequent use
LDA !1510,x		;
AND #$08		; if the plant is a red one...
ORA $00			; or the sprite isn't in the pipe...
BNE NoProximityCheck	; don't check to see if the player is near

%SubHorzPos()		; get the horizontal distance between the player and the sprite

LDA #$01			;
STA !1594,x		; set the invisibility flag if necessary
LDA $0E			;
CLC			;
ADC #$1B			; if the sprite is within a certain distance...
CMP #$37			;
BCC EndStateChange	; don't change the sprite state

NoProximityCheck:		;

STZ !1594,x		; if the sprite is out of range, clear the invisibility flag
LDA !C2,x		;
INC			; increment the sprite state
AND #$03		;
STA !C2,x		;
STA $00			;
LDA !1510,x		;
AND #$04		; use the stem length bit
TSB $00			;
LDA !1510,x		;
AND #$30		; and the Venus Fire Trap bits
LSR			;
ORA $00
TAY			; to set the timer for changing sprite state
LDA TimeInState,y		;
STA !1540,x		; set the time to change state

EndStateChange:		;

RTS

SetAnimationFrame:		;

INC !1570,x		; $1570,x - individual sprite frame counter, in this context
LDA !1570,x		;
LSR #3			; change image every 8 frames
AND #$01		;
STA !1602,x		; set the resulting image
RTS

FacePlayer:		;

%SubVertPos()		;
TYA			;
ASL			;
STA !157C,x		;

LDA !1510,x		;
AND #$02		;
BNE FixedH		; the sprite's horizontal direction is always the same if it is a horizontally-moving Venus Fire Trap

%SubHorzPos()		;
TYA			; make it face the player
ORA !157C,x		;
STA !157C,x		;

RTS			;

FixedH:

LDA !1510,x		;
AND #$01		;
EOR #$01			;
STA $00			;
LDA !157C,x		;
AND #$02		;
ORA $00			;
STA !157C,x		;

RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; graphics routine
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PiranhaPlantGFX:		; I made my own graphics routine, since the Piranha Plant uses a shared routine.

%GetDrawInfo()		; set some variables up for writing to OAM

LDA !1510,x		;
AND #$04		; stem length
LSR			;
STA $04			;
LDA !1510,x		;
AND #$08		;
LSR #3			; plus color
TSB $04			;

LDA !1602,x		;
STA $03			; frame = bit 0 of the index
LDA !1510,x		;
AND #$03		; direction and orientation
ASL			;
TSB $03			; bits 1 and 2 of the index
LDA !1510,x		;
AND #$10		; type
LSR			;
ORA $03			; bit 3 of the index
STA $03			;

LDA !1510,x		;
AND #$04		; if the plant has a short stem...
BNE AlwaysCovered		; then the stem is always partially obscured by the cover-up tile

LDA !C2,x		;
CMP #$02			; if the sprite is all the way out of the pipe...
BEQ StemOnly		; then draw just the stem

AlwaysCovered:		;

LDA !1510,x		;
AND #$01		;
STA $08			; save the direction bit for use with the cover-up routine

LDA !D8,x		;
SEC			;
SBC !151C,x		;
STA $06			;
LDA !E4,x		;
SEC			;
SBC !1528,x		;
CLC			;
ADC $06			;
LDX $08			;
BEQ NoFlipCheckVal	;
EOR #$FF			;
INC			;
NoFlipCheckVal:		;
CLC			;
ADC #$10		;
CMP #$20			;
BCC CoverUpTileOnly	;

StemAndCoverUpTile:	;

JSR DrawCoverUpTile	;
INY #4			;
JSR DrawStem		;
LDA #$02			;
EndGFX:			;
PHA			;
INY #4			;
LDX $03			;
JSR DrawHead		; the head tile is always drawn
PLA			;
LDY #$02			;
LDX $15E9|!Base2		;
JSL $01B7B3|!BankB		;
RTS			;

StemOnly:		;

JSR DrawStem		;
LDA #$01			;
BRA EndGFX		;

CoverUpTileOnly:		;

JSR DrawCoverUpTile	;
LDA #$01			;
BRA EndGFX		;

DrawHead:

LDA $00			;
CLC			;
ADC HeadXOffset,x		; set the X offset for the head tile
STA $0300|!Base2,y		;

LDA $01			;
CLC			;
ADC HeadYOffset,x		; set the Y offset for the head tile
STA $0301|!Base2,y		;

LDA HeadTilemap,x		; set the tile for the head
STA $0302|!Base2,y

LDX $15E9|!Base2		;
LDA !1510,x		;
AND #$10		;
BNE VenusFlip		;

LDX $03			;
LDA TileFlip,x		; load the XY flip for the tiles
LDX $04			; load the palette index
ORA HeadPalette,x		; add in the palette/GFX page bits
ORA $64			; and the level's sprite priority
STA $0303|!Base2,y		;

RTS

VenusFlip:		;

LDA !157C,x		;
ROR #3			;
AND #$C0		;
EOR #$40			;
LDX $04			;
ORA HeadPalette,x		;
ORA $64			;
STA $0303|!Base2,y		;

RTS			;

DrawStem:

LDX $03

LDA $00			;
CLC			;
ADC StemXOffset,x		; set the X offset for the stem tile
STA $0300|!Base2,y		;

LDA $01			;
CLC			;
ADC StemYOffset,x		; set the Y offset for the stem tile
STA $0301|!Base2,y		;

LDA StemTilemap,x		; set the tile for the stem
STA $0302|!Base2,y

LDA TileFlip,x		; load the XY flip for the tiles
LDX $04			; load the palette index
ORA StemPalette,x		; add in the palette/GFX page bits
ORA $64			; and the level's sprite priority
STA $0303|!Base2,y		;

RTS			;

DrawCoverUpTile:		;

LDX $15E9|!Base2		;

LDA !1528,x		;
STA $09			;
LDA !151C,x		; make backups of the XY init positions
STA $0A			;

LDA !1510,x		;
AND #$03		;
TAX

LDA $09			;
SEC			;
SBC $1A			;
CLC			;
ADC CoverUpXOffset,x	;
STA $0300|!Base2,y		;

LDA $0A			;
SEC			;
SBC $1C			;
CLC			;
ADC CoverUpYOffset,x	;
STA $0301|!Base2,y		;

LDA #!CoverUpTile		;
STA $0302|!Base2,y		;

LDA #$00			;
STA $0303|!Base2,y		;

RTS			;

LDX $15E9|!Base2		; sprite index back into X
LDY #$02			; the tiles were 16x16
LDA $05			; we drew 2 or 3 tiles
JSL $01B7B3|!BankB		;

RTS			;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Venus Fire Trap fireball-spit routine
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FireXOffsetsLo:
db $0F,$FA,$0E,$00,$0E,$FE,$0D,$FE,$FB,$FB,$FE,$FE,$1D,$1D,$1D,$1D
FireXOffsetsHi:
db $00,$FF,$00,$00,$00,$FF,$00,$FF,$FF,$FF,$FF,$FF,$00,$00,$00,$00
FireYOffsetsLo:
db $09,$09,$FF,$FF,$18,$18,$13,$13,$06,$06,$01,$01,$0A,$0A,$01,$01
FireYOffsetsHi:
db $00,$00,$FF,$FF,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
FireXSpeeds:
db $08,$F8,$08,$F8
FireYSpeeds:
db $06,$06,$FA,$FA

SpitFireball:

LDY #$07
ExSpriteLoop:
LDA !extended_num,y
BEQ FoundExSlot
DEY
BPL ExSpriteLoop
RTS

FoundExSlot:

STY $00

LDA #$02
STA !extended_num,y

LDA !1510,x
AND #$03
ASL
ASL
STA $01
LDA !157C,x
TSB $01

LDA !157C,x
STA $02

LDA !E4,x
LDY $01
CLC
ADC FireXOffsetsLo,y
LDY $00
STA !extended_x_low,y
LDA !14E0,x
LDY $01
ADC FireXOffsetsHi,y
LDY $00
STA !extended_x_high,y

LDA !D8,x
LDY $01
CLC
ADC FireYOffsetsLo,y
LDY $00
STA !extended_y_low,y
LDA !14D4,x
LDY $01
ADC FireYOffsetsHi,y
LDY $00
STA !extended_y_high,y

LDY $02
LDA FireXSpeeds,y
LDY $00
STA !extended_y_speed,y
LDY $02
LDA FireYSpeeds,y
LDY $00
STA !extended_x_speed,y

LDA #$FF
STA !extended_timer,y

RTS