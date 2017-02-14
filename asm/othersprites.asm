;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Custom Other Sprites, by imamelia
;;
;; This patch allows you to insert custom extended, cluster, minor extended,
;; bounce, score, smoke, and spinning coin sprites (!).  It comes with a few sample
;; subroutines for use with some of these sprites.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

if read1($00FFD5) == $23
	sa1rom	
	!base1	= $3000
	!base2	= $6000
	!base3	= $000000
	!7E	= $40
	!14D4	= $3258
	!14E0	= $326E
	!D8	= $3216
	!E4	= $322C
else	
	lorom	
	!base1	= $0000
	!base2	= $0000
	!base3	= $800000
	!7E	= $7E
	!D8	= $D8
	!E4	= $E4
	!14D4	= $14D4
	!14E0	= $14E0
endif


; cluster sprites, extended sprites, minor extended sprites, bounce sprites, score sprites, smoke images, spinning coin from block

org $02F815|!base3
autoclean JML ClusterSpriteHack
NOP
;LDA $1892,x
;BEQ $03       

org $029B1B|!base3
autoclean JML ExtendedSpriteHack
;LDY $9D
;BNE $08

org $028B6C|!base3
autoclean JML MinorExSpriteHack
;BEQ $06
;STX $1698

org $029052|!base3
autoclean JML BounceSpriteHack
;LDY $9D
;BNE $08

org $02ADC9|!base3
autoclean JML ScoreSpriteHack
;LDA $9D
;BEQ $03

org $0296C3|!base3
autoclean JML SmokeImageHack
;BEQ $12
;AND #$7F

org $0299F1|!base3
autoclean JML SpinningCoinHack
;LDA $9D
;BNE $13

org $028A7D|!base3
autoclean JSL SpinningCoinFix

reset bytes
freecode : prot AllTheCodes

SpinningCoinFix:
JSL $05B34A|!base3		;Fixes Spinning coins.
STZ $17D0|!base2,x
RTL 

ClusterSpriteHack:

LDA $1892|!base2,x			; cluster sprite number
BEQ .Return				;
CMP #$09				;
BCC .NotCustom			;

PHB					;
PHK					;
PLB					;
SEC					;
SBC #$09				; 09 is the first custom one
REP #$30				; 16-bit AXY
AND.w #$00FF			; clear the high byte
ASL					; x2
TAY					; into Y
LDA ClusterPtrs,y			; pointers to the cluster sprites
STA $08				; low and high bytes
SEP #$30				; 8-bit AXY
LDA.b #AllTheCodes>>16	; bank byte
STA $0A				;
PHA					;
PLB					;
PHK					;
PEA.w .PtrRet-$01			; push a return address
JML [$0008|!base1]			;
.PtrRet				;
PLB					;

.Return				;
JML $02F81D|!base3		;
.NotCustom				;
JML $02F81A|!base3		;

ExtendedSpriteHack:

CMP #$13				;
BCC .NotCustom			;

PHB					;
PHK					;
PLB					;
SEC					;
SBC #$13				; 13 is the first custom one
REP #$30				; 16-bit AXY
AND.w #$00FF			; clear the high byte
ASL					; x2
TAY					; into Y
LDA ExtendedPtrs,y		; pointers to the extended sprites
STA $08				; low and high bytes
SEP #$30				; 8-bit AXY
LDA.b #AllTheCodes>>16	; bank byte
STA $0A				;
PHA					;
PLB					;
PHK					;
PEA.w .PtrRet-$01			; push a return address
JML [$0008|!base1]				;
.PtrRet				;
PLB					;

JML $029B15|!base3		;
.NotCustom				;
LDY $9D				;
BNE .Return2			;
JML $029B1F|!base3		;
.Return2				;
JML $029B27|!base3		;

MinorExSpriteHack:

BEQ .Return1			;
STX $1698|!base2			;
CMP #$0C				;
BCC .NotCustom			;

PHB					;
PHK					;
PLB					;
SEC					;
SBC #$0C				; 0C is the first custom one
REP #$30				; 16-bit AXY
AND.w #$00FF			; clear the high byte
ASL					; x2
TAY					; into Y
LDA MinorExtendedPtrs,y	; pointers to the minor extended sprites
STA $08				; low and high bytes
SEP #$30				; 8-bit AXY
LDA.b #AllTheCodes>>16	; bank byte
STA $0A				;
PHA					;
PLB					;
PHK					;
PEA.w .PtrRet-$01			; push a return address
JML [$0008|!base1]			;
.PtrRet				;
PLB					;

.Return1				;
JML $028B74|!base3		;			;
.NotCustom				;
JML $028B71|!base3		;

BounceSpriteHack:

CMP #$08				;
BCC .NotCustom			;

PHB					;
PHK					;
PLB					;
SEC					;
SBC #$08				; 08 is the first custom one
REP #$30				; 16-bit AXY
AND.w #$00FF			; clear the high byte
ASL					; x2
TAY					; into Y
LDA BouncePtrs,y			; pointers to the bounce sprites
STA $08				; low and high bytes
SEP #$30				; 8-bit AXY
LDA.b #AllTheCodes>>16	; bank byte
STA $0A				;
PHA					;
PLB					;
PHK					;
PEA.w .PtrRet-$01			; push a return address
JML [$0008|!base1]			;
.PtrRet				;
PLB					;

JML $02904C|!base3		;
.NotCustom				;
LDY $9D				;
BNE .Return2			;
JML $029056|!base3		;
.Return2				;
JML $02905E|!base3		;

ScoreSpriteHack:

CMP #$16				;
BCC .NotCustom			;

PHB					;
PHK					;
PLB					;
SEC					;
SBC #$16				; 16 is the first custom one
REP #$30				; 16-bit AXY
AND.w #$00FF			; clear the high byte
ASL					; x2
TAY					; into Y
LDA ScorePtrs,y			; pointers to the score sprites
STA $08				; low and high bytes
SEP #$30				; 8-bit AXY
LDA.b #AllTheCodes>>16	; bank byte
STA $0A				;
PHA					;
PLB					;
PHK					;
PEA.w .PtrRet-$01			; push a return address
JML [$0008|!base1]			;
.PtrRet				;
PLB					;

JML $02ADC5|!base3		;
.NotCustom				;
LDY $9D				;
BNE .Return2			;
JML $02ADD0|!base3		;
.Return2				;
JML $02AE5B|!base3		;

SmokeImageHack:

BEQ .Return1			;
AND #$7F				;
CMP #$06				;
BCC .NotCustom			;

PHB					;
PHK					;
PLB					;
SEC					;
SBC #$06				; 06 is the first custom one
REP #$30				; 16-bit AXY
AND.w #$00FF			; clear the high byte
ASL					; x2
TAY					; into Y
LDA SmokePtrs,y			; pointers to the smoke images
STA $08				; low and high bytes
SEP #$30				; 8-bit AXY
LDA.b #AllTheCodes>>16	; bank byte
STA $0A				;
PHA					;
PLB					;
PHK					;
PEA.w .PtrRet-$01			; push a return address
JML [$0008|!base1]			;
.PtrRet				;
PLB					;

.Return1				;
JML $0296D7|!base3		;
.NotCustom				;
JML $0296C7|!base3		;

SpinningCoinHack:

CMP #$02				;
BCC .NotCustom			;

PHB					;
PHK					;
PLB					;
SEC					;
SBC #$02				; 02 is the first custom one
REP #$30				; 16-bit AXY
AND.w #$00FF			; clear the high byte
ASL					; x2
TAY					; into Y
LDA SpinCoinPtrs,y		; pointers to the spinning coins
STA $08				; low and high bytes
SEP #$30				; 8-bit AXY
LDA.b #AllTheCodes>>16	; bank byte
STA $0A				;
PHA					;
PLB					;
PHK					;
PEA.w .PtrRet-$01			; push a return address
JML [$0008|!base1]			;
.PtrRet				;
PLB					;

JML $0299E8|!base3		;
.NotCustom				;
LDY $9D				;
BNE .Return2			;
JML $0299F5|!base3		;
.Return2				;
JML $029A08|!base3		;

ClusterPtrs:
dw ClusterSprite09
dw ClusterSprite0A
dw ClusterSprite0B
dw ClusterSprite0C
dw ClusterSprite0D
dw ClusterSprite0E
dw ClusterSprite0F
;dw ClusterSprite10
;...
;dw ClusterSpriteFF

ExtendedPtrs:
dw ExtendedSprite13
dw ExtendedSprite14
dw ExtendedSprite15
dw ExtendedSprite16
dw ExtendedSprite17
;dw ExtendedSprite18
;...
;dw ExtendedSpriteFF

MinorExtendedPtrs:
dw MinorExSprite0C
dw MinorExSprite0D
dw MinorExSprite0E
dw MinorExSprite0F
;dw MinorExSprite10
;...
;dw MinorExSpriteFF

BouncePtrs:
dw BounceSprite08
dw BounceSprite09
dw BounceSprite0A
dw BounceSprite0B
;dw BounceSprite0C
;...
;dw BounceSpriteFF

ScorePtrs:
dw ScoreSprite16
dw ScoreSprite17
dw ScoreSprite18
dw ScoreSprite19
dw ScoreSprite1A
dw ScoreSprite1B
dw ScoreSprite1C
dw ScoreSprite1D
dw ScoreSprite1E
dw ScoreSprite1F
;dw ScoreSprite20
;...
;dw ScoreSpriteFF


SmokePtrs:
dw SmokeImage06
dw SmokeImage07
;dw SmokeImage08
;...
;dw SmokeImage7F

SpinCoinPtrs:
dw SpinningCoin02
dw SpinningCoin03
;dw SpinningCoin04
;...
;dw SpinningCoinFF

print "Freespace used by hacks and pointers: ",bytes," bytes."

reset bytes
freecode
AllTheCodes:
incsrc otherspritecode.asm

print "Freespace used by custom code: ",bytes," bytes."
