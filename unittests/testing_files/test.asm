;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; SMW Sumo Brother (sprite 9A), by imamelia
;;
;; This is a disassembly of sprite 9A in SMW, the Sumo Brother.
;;
;; Uses first extra bit: NO
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; defines and tables
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
!DEF_sprite_to_spawn = $2B		; Sprite to spawn.
!DEF_spawn_custom = 0			; Spawned sprite is custom (0 = no, 1 = yes)

!StompSound = $09
!StompSoundBank = $1DFC

XSpeed:
db $20,$E0

XDisp:
db $FF,$07,$FC,$04,$FF,$07,$FC,$04
db $FF,$FF,$FC,$04,$FF,$FF,$FC,$04
db $02,$02,$F4,$04,$02,$02,$F4,$04
db $09,$01,$04,$FC,$09,$01,$04,$FC
db $01,$01,$04,$FC,$01,$01,$04,$FC
db $FF,$FF,$0C,$FC,$FF,$FF,$0C,$FC

YDisp:
db $F8,$F8,$00,$00,$F8,$F8,$00,$00
db $F8,$F0,$00,$00,$F8,$F8,$00,$00
db $F8,$F8,$01,$00,$F8,$F8,$FF,$00

Tilemap:
db $98,$99,$A7,$A8,$98,$99,$AA,$AB
db $8A,$66,$AA,$AB,$EE,$EE,$C5,$C6
db $80,$80,$C1,$C3,$80,$80,$C1,$C3

TileSize:
db $00,$00,$02,$02,$00,$00,$02,$02
db $02,$02,$02,$02,$02,$02,$02,$02
db $02,$02,$02,$02,$02,$02,$02,$02

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; init routine
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

print "INIT ",pc

LDA #$03		;
STA !C2,x		;prepare to spawn a lightning bolt

LDA #$70		;
STA !1540,x		;

RTL

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; main routine wrapper
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

print "MAIN ",pc
PHB
PHK
PLB
JSR SumoBrotherMain
PLB
RTL

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; main routine
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SumoBrotherMain:

JSR SumoBroGFX		; draw the Sumo Brother

LDA $9D			;
BNE Return00		;
LDA !14C8,x		; return if sprites are locked or the sprite is not in normal status
CMP #$08		;
BNE Return00		;
LDA #$00
%SubOffScreen()
JSL $01803A|!bank	; interact with the player and with other sprites
JSL $01802A|!bank	; update sprite position based on speed values

LDA !1588,x		;
AND #$04		; if the sprite is on the ground...
BEQ RunStateCode	;
STZ !AA,x		; give it zero X speed and zero Y speed
STZ !B6,x		;

RunStateCode:		;

LDA !C2,x		; sprite state
JSL $0086DF|!bank	; 16-bit pointer subroutine

dw State00		;
dw State01		;
dw State02		;
dw State03		;

Return00:		;
RTS			;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; code for sprite state 00
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

State00:
LDA #$01		;
STA !1602,x		; animation frame = 01

LDA !1540,x		; if the state-change timer has reached zero...
BNE Return00		;
STZ !1602,x		; set the animation frame to 00

LDA #$03		;

SetTimer1:		;
STA !1540,x		; the timer to 03,
INC !C2,x		; and the sprite state to 01

Return01:		;
RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; code for sprite state 01
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

State01:

LDA !1540,x		;
BNE Return01		;

INC !1602,x		; here, we want to increment the animation frame

LDA #$03		;
BRA SetTimer1		;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; code for sprite state 02
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

State02:

LDA !1558,x		;
BNE SetFrame01		;

LDY !157C,x		;
LDA XSpeed,y		;
STA !B6,x		;

LDA !1540,x		;
BNE Return01		;

INC !1570,x		;
LDA !1570,x		;
AND #$01		;
BNE NoResetAniTimer	;

LDA #$20		;
STA !1558,x		;

NoResetAniTimer:	;
LDA !1570,x		;
CMP #$03		;
BNE SetTimer2		;

STZ !1570,x		;

LDA #$70		;
BRA SetTimer1		;

SetTimer2:		;
LDA #$03		;

SetTimer3:		;
JSR SetTimer1		;
STZ !C2,x		;
RTS

SetFrame01:
LDA #$01		;
STA !1602,x		;
RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; code for sprite state 03
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

State03:

LDA #$03		;
LDY !1540,x		;
BEQ Turn		;
CPY #$2E		;
BNE NoLightning		;
PHA			;
LDA !15A0,x		;
ORA !186C,x		;
BNE PullAndSkip		;

LDA #$30		;
STA $1887|!addr		;shake the ground

LDA #!StompSound		;
STA !StompSoundBank|!addr	;

PHY			;
JSR GenSumoLightning	;
PLY			;

PullAndSkip:
PLA

NoLightning:
CPY #$30		;
BCC SetFrameX		;
CPY #$50		;
BCS SetFrameX		;
INC			;
CPY #$44		;
BCS SetFrameX		;
INC			;
SetFrameX:		;
STA !1602,x		;
RTS

Turn:
LDA !157C,x		;
EOR #$01		;
STA !157C,x		;

LDA #$40		;
BRA SetTimer3		;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; lightning generation subroutine
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GenSumoLightning:
LDA #$04
STA $00 : STZ $01
STZ $02 : STZ $03
if !DEF_spawn_custom == 1
	SEC
else
	CLC
endif
LDA #!DEF_sprite_to_spawn
%SpawnSprite()

BCS Return02
LDA #$10		;
STA !1FE2,y		;timer for lightning to disable object interaction
Return02:
RTS			;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; graphics routine
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SumoBroGFX:
%GetDrawInfo()

LDA !157C,x		;
LSR			;
ROR #2			;
AND #$40		;
EOR #$40		;
STA $02			;

;LDY !15EA,x		;
LDA !1602,x		;
ASL #2			;
PHX			;
TAX			;
LDA #$03		;
STA $05			; 

GFXLoop:

PHX			;
LDA $02			;
BEQ NoXShift		;
TXA			;
CLC			;
ADC #$18		;
TAX			;
NoXShift:		;
LDA $00			;
CLC			;
ADC XDisp,x		;
STA $0300|!addr,y	;

PLX			;
LDA $01			;
CLC			;
ADC YDisp,x		;
STA $0301|!addr,y	;

LDA Tilemap,x		;
STA $0302|!addr,y	;

CMP #$66		;
SEC			;
BNE SetGFXPage		;
CLC			;
SetGFXPage:		;
LDA #$34		;
ADC $02			;
STA $0303|!addr,y	;
      
PHY			;
TYA			;
LSR #2			;
TAY			;
LDA TileSize,x		;
STA $0460|!addr,y	;
PLY			;

INY #4			;
INX			;
DEC $05			;
BPL GFXLoop		;

PLX			;
LDY #$FF		;
LDA #$03		;
%FinishOAMWrite()	;
RTS			;