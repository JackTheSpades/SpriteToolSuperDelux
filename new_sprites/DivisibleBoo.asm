PRINT "INIT ",pc
;Point to the current frame
!FramePointer = $C2,x

;Point to the current frame on the animation
!AnFramePointer = $1504,x

;Point to the current animation
!AnPointer = $1510,x

;Time for the next frame change
!AnimationTimer = $1540,x

!GlobalFlipper = $1534,x

!LocalFlipper = $1570,x

!moveTimer = $1528,x

!starting = $1594,x

!startingTimer = $154C,x

!maxStartingTime = #$60

!maxMoveTime = #$6A

;Tiles
!88 = $88 ;You can change the tiles of boo here
!8C = $8C

LDA !maxStartingTime
STA !startingTimer

LDA !maxMoveTime
STA !moveTimer 

LDA $7FAB10,x
AND #$04
BNE +
	STZ $AA,x
	STZ $B6,x
	STZ !starting
	STZ !startingTimer
+

LDA #$01
STA !FramePointer
LDA #$02
STA !AnPointer
STZ !AnFramePointer
LDA #$04
STA !AnimationTimer

RTL

PRINT "MAIN ",pc

PHB
PHK
PLB
JSR SpriteCode
PLB
RTL

;===================================
;Sprite Function
;===================================

Return:
	RTS

SpriteCode:

	JSR Graphics ;graphic routine

	LDA $14C8,x			;\
	CMP #$08			; | If sprite dead,
	BNE Return			;/ Return.

	LDA $9D				;\
	BNE Return			;/ If locked, return.
	JSR SUB_OFF_SCREEN_X0
	
	JSR InteractionWithMario
	JSR states
	JSR GraphicManager ;manage the frames of the sprite and decide what frame show
	JSL $018022
	JSL $01801A
	RTS

	
states:

	LDA !starting
	BEQ +
	
	LDA !startingTimer
	BNE ++
	STZ !starting
++

	DEC $AA,x
	BPL ++
	STZ $AA,x
++
	LDA $B6,x
	BMI ++
	DEC $B6,x
	BPL +++
	STZ $B6,x
	RTS
++
	INC $B6,x
	BMI +++
	STZ $B6,x
+++
	RTS
+

	LDA !AnPointer
	BNE +
	JSR follow
	RTS
+
	CMP #$02
	BNE +
	JSR idle
	RTS
+
	RTS
	
idle:
	STZ $AA,x
	LDA $E4,x
	STA $00
	LDA $14E0,x
	STA $01
	
	LDA !GlobalFlipper
	BNE +
	
	REP #$20
	LDA $94
	CLC
	ADC #$0018
	CMP $00
	SEP #$20
	BCC .c0
	
	LDA #$01
	STA !GlobalFlipper
	RTS
	
.c0
	LDA $76
	CMP !GlobalFlipper
	BNE ++
	
	STZ !AnPointer
	STZ !FramePointer
	STZ !AnFramePointer
++
	RTS
+
	REP #$20
	LDA $94
	CLC
	ADC #$FFF8
	CMP $00
	SEP #$20
	BCS .c1
	
	LDA #$00
	STA !GlobalFlipper
	RTS
	
.c1
	LDA $76
	CMP !GlobalFlipper
	BNE +
	
	STZ !AnPointer
	STZ !FramePointer
	STZ !AnFramePointer
+
	RTS

follow:

	LDA !GlobalFlipper
	CMP $76
	BEQ +
	
	LDA #$02
	STA !AnPointer
	LDA #$01
	STA !FramePointer
	STZ !AnFramePointer
	STZ $B6,x
	STZ $AA,x
	
	RTS
+
	
	JSR sinMove
	JSR xmov
	JSR ymov
	RTS
	
ymov:
	
	REP #$20
	LDA $96
	CLC
	ADC #$0010
	CMP $02
	SEP #$20
	BCS +
	
	REP #$20
	LDA $96
	CLC
	ADC #$0030
	CMP $02
	SEP #$20
	BCC ++
	
	INC $AA,x
	BMI ++
	STZ $AA,x
	RTS
++
	LDA $AA,x
	DEC A
	STA $AA,x
	BPL ++
	CMP #$F8
	BCS ++
	LDA #$F8
	STA $AA,x
++
	RTS
+
	REP #$20
	LDA $96
	CLC
	ADC #$FFF0
	CMP $02
	SEP #$20
	BCS ++
	
	DEC $AA,x
	BPL ++
	STZ $AA,x
	RTS
++

	LDA $AA,x
	INC A
	STA $AA,x
	BMI ++
	CMP #$08
	BCC ++
	LDA #$08
	STA $AA,x
++
	
	RTS
	
	
xmov:
	LDA $E4,x
	STA $00
	LDA $14E0,x
	STA $01
	
	LDA !GlobalFlipper
	BEQ +
	
	REP #$20
	LDA $94
	CLC
	ADC #$0018
	CMP $00
	SEP #$20
	BCS .c0
	
	DEC $B6,x
	BPL ++
	STZ $B6,x
	LDA #$02
	STA !AnPointer
	LDA #$01
	STA !FramePointer
	STZ !AnFramePointer
++
	RTS
	
.c0
	LDA $B6,x
	INC A
	STA $B6,x
	BMI ++
	CMP #$08
	BCC ++
	LDA #$08
	STA $B6,x
++
	RTS
+
	REP #$20
	LDA $94
	CLC
	ADC #$FFF8
	CMP $00
	SEP #$20
	BCC .c1
	
	INC $B6,x
	BMI ++
	STZ $B6,x
	LDA #$02
	STA !AnPointer
	LDA #$01
	STA !FramePointer
	STZ !AnFramePointer
++
	RTS
	
.c1
	LDA $B6,x
	DEC A
	STA $B6,x
	BPL ++
	CMP #$F8
	BCS ++
	LDA #$F8
	STA $B6,x
++
	RTS
	
sinMove:

	LDA $D8,x
	STA $02
	LDA $14D4,x
	STA $03
	
	LDA $14
	AND #$03
	BNE .next
	
	LDA !moveTimer
	BNE +
	LDA !maxMoveTime
	STA !moveTimer
	BRA ++	
+
	DEC A
	DEC A
	STA !moveTimer
++
	TAY
	
	REP #$20
	LDA $02
	CLC
	ADC .sin,y
	STA $02
	SEP #$20
	
	LDA $02
	STA $D8,x
	LDA $03
	STA $14D4,x
.next

	RTS
.sin 	dw $0000,$0000,$0000,$0000,$0001,$0000,$0000,$0001,$0000,$0001,$0000,$0001,$0001,$0001,$0001,$0001
		dw $0001,$0000,$0001,$0000,$0001,$0000,$0000,$0001,$0000,$0000,$0000,$0000,$0000,$0000,$FFFF,$0000
		dw $0000,$FFFF,$0000,$FFFF,$0000,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$0000,$FFFF,$0000,$FFFF,$0000
		dw $0000,$FFFF,$0000,$0000,$0000,$0000
		
summonBoo:

	JSL $02A9DE
	BMI .EndSpawn

	LDA #$01
	STA $14C8,y
	
	LDA $7FAB9E,x
	PHX
	TYX
	STA $7FAB9E,x
	PLX
	
	LDA $E4,x
	STA $00E4,y
	LDA $14E0,x
	STA $14E0,y
	
	LDA $D8,x
	STA $00D8,y
	LDA $14D4,x
	STA $14D4,y
	
	PHX
	TYX
	JSL $07F7D2
	LDA #$0C
	STA $7FAB10,x
	
	LDA $00
	STA $B6,x
	
	LDA #$10
	STA $AA,x
	
	LDA #$01
	STA !starting
	
	PLX
.EndSpawn
	RTS

;===================================
;Graphic Manager
;===================================	
GraphicManager:

	;if !AnimationTimer is Zero go to the next frame
	LDA !AnimationTimer
	BEQ ChangeFrame
	RTS

ChangeFrame:

	LDA !FramePointer
	CMP #$05
	BNE +

	STZ $14C8,x	
	RTS
	
+

	;Load the animation pointer X2
	LDA !AnPointer
	
	REP #$30
	AND #$00FF
	TAY
	
	
	LDA !AnFramePointer
	CLC
	ADC EndPositionAnim,y
	TAY
	SEP #$30
	
	LDA AnimationsFrames,y
	STA !FramePointer
	
	LDA AnimationsNFr,y
	STA !AnFramePointer
	
	LDA AnimationsTFr,y
	STA !AnimationTimer
	
	LDA !GlobalFlipper
	EOR AnimationsFlips,y
	STA !LocalFlipper
	
	RTS	


;===================================
;Animation
;===================================
EndPositionAnim:
	dw $0000,$0001,$0002

AnimationsFrames:
normalFrames:
	db $00
hideFrames:
	db $01
dieFrames:
	db $02,$03,$04,$05

AnimationsNFr:
normalNext:
	db $00
hideNext:
	db $00
dieNext:
	db $01,$02,$03,$00

AnimationsTFr:
normalTimes:
	db $04
hideTimes:
	db $04
dieTimes:
	db $04,$04,$04,$04

AnimationsFlips:
normalFlip:
	db $00
hideFlip:
	db $00
dieFlip:
	db $00,$00,$00,$00


;===================================
;Interaction
;===================================
InteractionWithMario:

	LDA !FramePointer
	TAY
	LDA TotalHitboxes,y
	BPL +
	RTS
+
	LDA !LocalFlipper
	TAY
	LDA !FramePointer
	CLC
	ADC FlipAdder,y
	REP #$30
	AND #$00FF
	CLC
	ASL
	TAY ;load the frame pointer on X
	
	LDA StartPositionHitboxes,y
	STA $08
	
	LDA EndPositionHitboxes,y
	STA $0A
	
	LDA #$000C ;load y disp of mario on $04
	STA $04
	
	LDA $19
	BEQ +
	LDA #$0004 ;if mario is big the y disp is 4
	STA $04
+
	LDA $96
	CLC
	ADC $04
	STA $04 ;$04 is position + ydisp
	BPL +
	LDA #$0000 ;if $04 is negative then change it to 0
+
	STA $04 
	
	LDA $04
	CLC
	ADC #$0014
	STA $06 ;$06 = bottom
	LDA $19
	BEQ +
	LDA $06
	CLC
	ADC #$0008
	STA $06 ;if mario is big then add 8 to bottom 
+	
	LDA $187A
	BEQ +
	LDA $06
	CLC
	ADC #$0010 ;if mario is riding yoshi then add 16 to bottom
	STA $06
+
	LDA $06
	BPL +
	SEP #$20
	RTS
+

	SEP #$20
	
	LDA $E4,x
	STA $00
	LDA $14E0,x
	STA $01
	
	LDA $D8,x
	STA $02
	LDA $14D4,x
	STA $03
	
	REP #$30
	
	LDY $08
	
.loop

	LDA $00
	CLC
	ADC FramesHitboxXDisp,y
	STA $0E
	CLC
	ADC FramesHitboxWidth,y
	BMI .next ;if x + xdisp + width < xMario || x + xdisp + width < 0 then goto next
	CMP $94
	BCC .next
	
	LDA $0E
	BPL +
	STZ $000E ;if x+xdisp < 0 then x+xdisp = 0
+
	
	LDA $94
	CLC
	ADC #$0010
	CMP $0E
	BCC .next ;if xMario + widthMario < x+xdisp then goto next
	
	LDA $02
	CLC
	ADC FramesHitboxYDisp,y
	STA $0E
	CLC
	ADC FramesHitboxHeigth,y
	BMI .next
	CMP $04
	BCC .next ;if y + ydisp + height < yMario + ydispMario || y + ydisp + height < 0 then goto next

	LDA $0E
	BPL +
	STZ $000E ;if y + ydisp < 0 then y + ydisp = 0
+	
	LDA $06
	CMP $0E
	BCC .next ;if yMario + ydispMario + heigthMario < y + ydisp then gotonext
	
	PHY
	LDA FramesHitboxAction,y
	STA $0E
	SEP #$30
	TXY
	LDX #$00
	JSR ($000E,x) ;make action of this hitbox
	REP #$30
	PLY
	BRA .ret
.next
	DEY
	DEY
	BMI .ret
	CPY $0A
	BCS .loop
.ret	
	SEP #$30
RTS

hurt:
	TYX
	LDA $187A
	BNE .loseYoshi
	JSL $00F5B7
	RTS
.loseYoshi
	JSR LOSEYOSHI
	RTS
	
vel: db $20,$E0
LOSEYOSHI:	
	LDA $187A
	BEQ NOYOSHI
	PHX
	LDX $18E2
	LDA #$10
	STA $163D,x
	LDA #$03
	STA $1DFA
	LDA #$13
	STA $1DFC
	LDA #$02
	STA $C1,x
	STZ $187A
	STZ $0DC1
	LDA #$C0
	STA $7D
	STZ $7B
	LDY $157B,x
	PHX
	TYX
	LDA vel,x
	PLX
	STA $B5,x
	STZ $1593,x
	STZ $151B,x
	STZ $18AE
	LDA #$30
	STA $1497
	PLX
NOYOSHI:
	RTS
;===================================
;Actions
;===================================
high:
	TYX
	LDA $7D
	BMI +
	
	JSL $81AA33
	JSL $81AB99
	JSR points
	LDA #$04
	STA !AnPointer
	STA !AnimationTimer
	LDA #$02
	STA !FramePointer
	STZ !AnFramePointer
	STZ $B6,x
	STZ $AA,x
	
	LDA $7FAB10,x
	AND #$04
	BNE ++
	
	LDA #$20
	STA $00
	JSR summonBoo
	LDA #$E0
	STA $00
	JSR summonBoo
	
++
	RTS
+
	JSR hurt
	RTS
points:
	PHY		;
	LDA $1697	; consecutive enemies stomped
	CLC		;
	ADC $1626,x	; plus number of enemies this sprite has killed (...huh?)
	INC $1697	; increment the counter
	TAY		; -> Y
	INY		; increment
	CPY #$08		; if the result is 8+...
	BCS NoSound	; don't play a sound effect
	TYX		;
	LDA $037FFF,x	; star sounds (X is never 0 here; they start at $038000)
	STA $1DF9	;
	LDX $15E9	;
	NoSound:		;
	TYA		;
	CMP #$08		; if the number is 8+...
	BCC GivePoints	;
	LDA #$08		; just use 8 when giving points
	GivePoints:	;
	JSL $82ACE5	;
	PLY		;
	RTS		;

;===================================
;Graphic Routine
;===================================
FlipAdder: db $00,$06
Graphics:
	REP #$10
	LDY #$0000
	SEP #$10

	JSR GET_DRAW_INFO
	
	PHX
	LDA !LocalFlipper
	PHA
	LDA !FramePointer
	PLX
	CLC
	ADC FlipAdder,x
	REP #$30

	AND #$00FF
	ASL
	TAX
	
	LDA EndPositionFrames,x
	STA $0D
	
	LDA StartPositionFrames,x
	TAX
	SEP #$20

.loop
	LDA FramesXDisp,x 
	CLC
	ADC $00
	STA $0300,y ;load the tile X position

	LDA FramesYDisp,x
	CLC
	ADC $01
	STA $0301,y ;load the tile Y position

	LDA FramesPropertie,x
	ORA $64
	STA $0303,y ;load the tile Propertie

	LDA FramesTile,x
	STA $0302,y ;load the tile

	INY
	INY
	INY
	INY ;next slot

	DEX
	BMI +
	CPX $0D
	BCS .loop ;if Y < 0 exit to loop
+
	SEP #$10
	PLX
	
	LDA !FramePointer
	TAY
	LDA FramesTotalTiles,y ;load the total of tiles on $0E
	LDY #$02 ;load the size
	JSL $01B7B3 ;call the oam routine
	RTS
	
;===================================
;Frames
;===================================
FramesTotalTiles:

	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

StartPositionFrames:
	dw $0000,$0001,$0002,$0003,$0004,$0005,$0006,$0007,$0008,$0009,$000A,$000B

EndPositionFrames:
	dw $0000,$0001,$0002,$0003,$0004,$0005,$0006,$0007,$0008,$0009,$000A,$000B

TotalHitboxes:
	db $01,$01,$FF,$FF,$FF,$FF,$01,$01,$FF,$FF,$FF,$FF

StartPositionHitboxes:
	dw $0002,$0006,$0008,$000A,$000C,$000E,$0012,$0016,$0018,$001A,$001C,$001E

EndPositionHitboxes:
	dw $0000,$0004,$0008,$000A,$000C,$000E,$0010,$0014,$0018,$001A,$001C,$001E

FramesXDisp:
f1XDisp:
	db $00
f2XDisp:
	db $00
die1XDisp:
	db $00
die2XDisp:
	db $00
die3XDisp:
	db $00
die4XDisp:
	db $00
f1FlipXXDisp:
	db $00
f2FlipXXDisp:
	db $00
die1FlipXXDisp:
	db $00
die2FlipXXDisp:
	db $00
die3FlipXXDisp:
	db $00
die4FlipXXDisp:
	db $00


FramesYDisp:
f1yDisp:
	db $00
f2yDisp:
	db $00
die1yDisp:
	db $00
die2yDisp:
	db $00
die3yDisp:
	db $00
die4yDisp:
	db $00
f1FlipXyDisp:
	db $00
f2FlipXyDisp:
	db $00
die1FlipXyDisp:
	db $00
die2FlipXyDisp:
	db $00
die3FlipXyDisp:
	db $00
die4FlipXyDisp:
	db $00


FramesPropertie:
f1Properties:
	db $33
f2Properties:
	db $33
die1Properties:
	db $32
die2Properties:
	db $32
die3Properties:
	db $32
die4Properties:
	db $32
f1FlipXProperties:
	db $73
f2FlipXProperties:
	db $73
die1FlipXProperties:
	db $72
die2FlipXProperties:
	db $72
die3FlipXProperties:
	db $72
die4FlipXProperties:
	db $72


FramesTile:
f1Tiles:
	db !88
f2Tiles:
	db !8C
die1Tiles:
	db $60
die2Tiles:
	db $62
die3Tiles:
	db $64
die4Tiles:
	db $66
f1FlipXTiles:
	db $88
f2FlipXTiles:
	db $8C
die1FlipXTiles:
	db $60
die2FlipXTiles:
	db $62
die3FlipXTiles:
	db $64
die4FlipXTiles:
	db $66


FramesHitboxXDisp:
f1HitboxXDisp:
	dw $0002,$0002
f2HitboxXDisp:
	dw $0002,$0002
die1HitboxXDisp:
	dw $FFFF
die2HitboxXDisp:
	dw $FFFF
die3HitboxXDisp:
	dw $FFFF
die4HitboxXDisp:
	dw $FFFF
f1FlipXHitboxXDisp:
	dw $0002,$0002
f2FlipXHitboxXDisp:
	dw $0002,$0002
die1FlipXHitboxXDisp:
	dw $FFFF
die2FlipXHitboxXDisp:
	dw $FFFF
die3FlipXHitboxXDisp:
	dw $FFFF
die4FlipXHitboxXDisp:
	dw $FFFF


FramesHitboxYDisp:
f1HitboxyDisp:
	dw $0004,$0002
f2HitboxyDisp:
	dw $0004,$0002
die1HitboxyDisp:
	dw $FFFF
die2HitboxyDisp:
	dw $FFFF
die3HitboxyDisp:
	dw $FFFF
die4HitboxyDisp:
	dw $FFFF
f1FlipXHitboxyDisp:
	dw $0004,$0002
f2FlipXHitboxyDisp:
	dw $0004,$0002
die1FlipXHitboxyDisp:
	dw $FFFF
die2FlipXHitboxyDisp:
	dw $FFFF
die3FlipXHitboxyDisp:
	dw $FFFF
die4FlipXHitboxyDisp:
	dw $FFFF


FramesHitboxWidth:
f1HitboxWith:
	dw $000C,$000C
f2HitboxWith:
	dw $000C,$000C
die1HitboxWith:
	dw $FFFF
die2HitboxWith:
	dw $FFFF
die3HitboxWith:
	dw $FFFF
die4HitboxWith:
	dw $FFFF
f1FlipXHitboxWith:
	dw $000C,$000C
f2FlipXHitboxWith:
	dw $000C,$000C
die1FlipXHitboxWith:
	dw $FFFF
die2FlipXHitboxWith:
	dw $FFFF
die3FlipXHitboxWith:
	dw $FFFF
die4FlipXHitboxWith:
	dw $FFFF


FramesHitboxHeigth:
f1HitboxHeigth:
	dw $000A,$0002
f2HitboxHeigth:
	dw $000A,$0002
die1HitboxHeigth:
	dw $FFFF
die2HitboxHeigth:
	dw $FFFF
die3HitboxHeigth:
	dw $FFFF
die4HitboxHeigth:
	dw $FFFF
f1FlipXHitboxHeigth:
	dw $000A,$0002
f2FlipXHitboxHeigth:
	dw $000A,$0002
die1FlipXHitboxHeigth:
	dw $FFFF
die2FlipXHitboxHeigth:
	dw $FFFF
die3FlipXHitboxHeigth:
	dw $FFFF
die4FlipXHitboxHeigth:
	dw $FFFF


FramesHitboxAction:
f1HitboxAction:
	dw hurt,high
f2HitboxAction:
	dw hurt,high
die1HitboxAction:
	dw $FFFF
die2HitboxAction:
	dw $FFFF
die3HitboxAction:
	dw $FFFF
die4HitboxAction:
	dw $FFFF
f1FlipXHitboxAction:
	dw hurt,high
f2FlipXHitboxAction:
	dw hurt,high
die1FlipXHitboxAction:
	dw $FFFF
die2FlipXHitboxAction:
	dw $FFFF
die3FlipXHitboxAction:
	dw $FFFF
die4FlipXHitboxAction:
	dw $FFFF


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; GET_DRAW_INFO
; This is a helper for the graphics routine.  It sets off screen flags, and sets up
; variables.  It will return with the following:
;
;       Y = index to sprite OAM ($300)
;       $00 = sprite x position relative to screen boarder
;       $01 = sprite y position relative to screen boarder  
;
; It is adapted from the subroutine at $03B760
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


SPR_T1:              db $0C,$1C
SPR_T2:             db $01,$02

GET_DRAW_INFO:       STZ $186C,x             ; reset sprite offscreen flag, vertical
                    STZ $15A0,x             ; reset sprite offscreen flag, horizontal
                    LDA $E4,x               ; \
                    CMP $1A                 ;  | set horizontal offscreen if necessary
                    LDA $14E0,x             ;  |
                    SBC $1B                 ;  |
                    BEQ ON_SCREEN_X         ;  |
                    INC $15A0,x             ; /

ON_SCREEN_X:         LDA $14E0,x             ; \
                    XBA                     ;  |
                    LDA $E4,x               ;  |
                    REP #$20                ;  |
                    SEC                     ;  |
                    SBC $1A                 ;  | mark sprite invalid if far enough off screen
                    CLC                     ;  |
                    ADC #$0040            ;  |
                    CMP #$0180            ;  |
                    SEP #$20                ;  |
                    ROL A                   ;  |
                    AND #$01                ;  |
                    STA $15C4,x             ; / 
                    BNE INVALID             ; 
                    
                    LDY #$00                ; \ set up loop:
                    LDA $1662,x             ;  | 
                    AND #$20                ;  | if not smushed (1662 & 0x20), go through loop twice
                    BEQ ON_SCREEN_LOOP      ;  | else, go through loop once
                    INY                     ; / 
ON_SCREEN_LOOP:      LDA $D8,x               ; \ 
                    CLC                     ;  | set vertical offscreen if necessary
                    ADC SPR_T1,y            ;  |
                    PHP                     ;  |
                    CMP $1C                 ;  | (vert screen boundry)
                    ROL $00                 ;  |
                    PLP                     ;  |
                    LDA $14D4,x             ;  | 
                    ADC #$00                ;  |
                    LSR $00                 ;  |
                    SBC $1D                 ;  |
                    BEQ ON_SCREEN_Y         ;  |
                    LDA $186C,x             ;  | (vert offscreen)
                    ORA SPR_T2,y            ;  |
                    STA $186C,x             ;  |
ON_SCREEN_Y:         DEY                     ;  |
                    BPL ON_SCREEN_LOOP      ; /

                    LDY $15EA,x             ; get offset to sprite OAM
                    LDA $E4,x               ; \ 
                    SEC                     ;  | 
                    SBC $1A                 ;  | $00 = sprite x position relative to screen boarder
                    STA $00                 ; / 
                    LDA $D8,x               ; \ 
                    SEC                     ;  | 
                    SBC $1C                 ;  | $01 = sprite y position relative to screen boarder
                    STA $01                 ; / 
                    RTS                     ; return

INVALID:             PLA                     ; \ return from *main gfx routine* subroutine...
                    PLA                     ;  |    ...(not just this subroutine)
                    RTS                     ; /;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; $B85D - off screen processing code - shared
; sprites enter at different points
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SPR_T12:             db $40,$B0
SPR_T13:             db $01,$FF
SPR_T14:             db $30,$C0,$A0,$C0,$A0,$F0,$60,$90		;bank 1 sizes
		            db $30,$C0,$A0,$80,$A0,$40,$60,$B0		;bank 3 sizes
SPR_T15:             db $01,$FF,$01,$FF,$01,$FF,$01,$FF		;bank 1 sizes
					db $01,$FF,$01,$FF,$01,$00,$01,$FF		;bank 3 sizes

SUB_OFF_SCREEN_X1:   LDA #$02                ; \ entry point of routine determines value of $03
                    BRA STORE_03            ;  | (table entry to use on horizontal levels)
SUB_OFF_SCREEN_X2:   LDA #$04                ;  | 
                    BRA STORE_03            ;  |
SUB_OFF_SCREEN_X3:   LDA #$06                ;  |
                    BRA STORE_03            ;  |
SUB_OFF_SCREEN_X4:   LDA #$08                ;  |
                    BRA STORE_03            ;  |
SUB_OFF_SCREEN_X5:   LDA #$0A                ;  |
                    BRA STORE_03            ;  |
SUB_OFF_SCREEN_X6:   LDA #$0C                ;  |
                    BRA STORE_03            ;  | OMG YOU FOUND THIS HIDDEN z0mg place!111 you win a cookie!
SUB_OFF_SCREEN_X7:   LDA #$0E                ;  |
STORE_03:			STA $03					;  |            
					BRA START_SUB			;  |
SUB_OFF_SCREEN_X0:   STZ $03					; /

START_SUB:           JSR SUB_IS_OFF_SCREEN   ; \ if sprite is not off screen, return
                    BEQ RETURN_35           ; /
                    LDA $5B                 ; \  goto VERTICAL_LEVEL if vertical level
                    AND #$01                ; |
                    BNE VERTICAL_LEVEL      ; /     
                    LDA $D8,x               ; \
                    CLC                     ; | 
                    ADC #$50                ; | if the sprite has gone off the bottom of the level...
                    LDA $14D4,x             ; | (if adding 0x50 to the sprite y position would make the high byte >= 2)
                    ADC #$00                ; | 
                    CMP #$02                ; | 
                    BPL ERASE_SPRITE        ; /    ...erase the sprite
                    LDA $167A,x             ; \ if "process offscreen" flag is set, return
                    AND #$04                ; |
                    BNE RETURN_35           ; /
                    LDA $13                 ;A:8A00 X:0009 Y:0001 D:0000 DB:01 S:01F1 P:envMXdiZcHC:0756 VC:176 00 FL:205
                    AND #$01                ;A:8A01 X:0009 Y:0001 D:0000 DB:01 S:01F1 P:envMXdizcHC:0780 VC:176 00 FL:205
                    ORA $03                 ;A:8A01 X:0009 Y:0001 D:0000 DB:01 S:01F1 P:envMXdizcHC:0796 VC:176 00 FL:205
                    STA $01                 ;A:8A01 X:0009 Y:0001 D:0000 DB:01 S:01F1 P:envMXdizcHC:0820 VC:176 00 FL:205
                    TAY                     ;A:8A01 X:0009 Y:0001 D:0000 DB:01 S:01F1 P:envMXdizcHC:0844 VC:176 00 FL:205
                    LDA $1A                 ;A:8A01 X:0009 Y:0001 D:0000 DB:01 S:01F1 P:envMXdizcHC:0858 VC:176 00 FL:205
                    CLC                     ;A:8A00 X:0009 Y:0001 D:0000 DB:01 S:01F1 P:envMXdiZcHC:0882 VC:176 00 FL:205
                    ADC SPR_T14,y           ;A:8A00 X:0009 Y:0001 D:0000 DB:01 S:01F1 P:envMXdiZcHC:0896 VC:176 00 FL:205
                    ROL $00                 ;A:8AC0 X:0009 Y:0001 D:0000 DB:01 S:01F1 P:eNvMXdizcHC:0928 VC:176 00 FL:205
                    CMP $E4,x               ;A:8AC0 X:0009 Y:0001 D:0000 DB:01 S:01F1 P:eNvMXdizCHC:0966 VC:176 00 FL:205
                    PHP                     ;A:8AC0 X:0009 Y:0001 D:0000 DB:01 S:01F1 P:envMXdizCHC:0996 VC:176 00 FL:205
                    LDA $1B                 ;A:8AC0 X:0009 Y:0001 D:0000 DB:01 S:01F0 P:envMXdizCHC:1018 VC:176 00 FL:205
                    LSR $00                 ;A:8A00 X:0009 Y:0001 D:0000 DB:01 S:01F0 P:envMXdiZCHC:1042 VC:176 00 FL:205
                    ADC SPR_T15,y           ;A:8A00 X:0009 Y:0001 D:0000 DB:01 S:01F0 P:envMXdizcHC:1080 VC:176 00 FL:205
                    PLP                     ;A:8AFF X:0009 Y:0001 D:0000 DB:01 S:01F0 P:eNvMXdizcHC:1112 VC:176 00 FL:205
                    SBC $14E0,x             ;A:8AFF X:0009 Y:0001 D:0000 DB:01 S:01F1 P:envMXdizCHC:1140 VC:176 00 FL:205
                    STA $00                 ;A:8AFF X:0009 Y:0001 D:0000 DB:01 S:01F1 P:eNvMXdizCHC:1172 VC:176 00 FL:205
                    LSR $01                 ;A:8AFF X:0009 Y:0001 D:0000 DB:01 S:01F1 P:eNvMXdizCHC:1196 VC:176 00 FL:205
                    BCC SPR_L31             ;A:8AFF X:0009 Y:0001 D:0000 DB:01 S:01F1 P:envMXdiZCHC:1234 VC:176 00 FL:205
                    EOR #$80                ;A:8AFF X:0009 Y:0001 D:0000 DB:01 S:01F1 P:envMXdiZCHC:1250 VC:176 00 FL:205
                    STA $00                 ;A:8A7F X:0009 Y:0001 D:0000 DB:01 S:01F1 P:envMXdizCHC:1266 VC:176 00 FL:205
SPR_L31:             LDA $00                 ;A:8A7F X:0009 Y:0001 D:0000 DB:01 S:01F1 P:envMXdizCHC:1290 VC:176 00 FL:205
                    BPL RETURN_35           ;A:8A7F X:0009 Y:0001 D:0000 DB:01 S:01F1 P:envMXdizCHC:1314 VC:176 00 FL:205
ERASE_SPRITE:        LDA $14C8,x             ; \ if sprite status < 8, permanently erase sprite
                    CMP #$08                ; |
                    BCC KILL_SPRITE         ; /    
                    LDY $161A,x             ;A:FF08 X:0007 Y:0001 D:0000 DB:01 S:01F3 P:envMXdiZCHC:1108 VC:059 00 FL:2878
                    CPY #$FF                ;A:FF08 X:0007 Y:0000 D:0000 DB:01 S:01F3 P:envMXdiZCHC:1140 VC:059 00 FL:2878
                    BEQ KILL_SPRITE         ;A:FF08 X:0007 Y:0000 D:0000 DB:01 S:01F3 P:envMXdizcHC:1156 VC:059 00 FL:2878
                    LDA #$00                ;A:FF08 X:0007 Y:0000 D:0000 DB:01 S:01F3 P:envMXdizcHC:1172 VC:059 00 FL:2878
                    STA $1938,y             ;A:FF00 X:0007 Y:0000 D:0000 DB:01 S:01F3 P:envMXdiZcHC:1188 VC:059 00 FL:2878
KILL_SPRITE:         STZ $14C8,x             ; erase sprite
RETURN_35:           RTS                     ; return

VERTICAL_LEVEL:      LDA $167A,x             ; \ if "process offscreen" flag is set, return
                    AND #$04                ; |
                    BNE RETURN_35           ; /
                    LDA $13                 ; \
                    LSR A                   ; | 
                    BCS RETURN_35           ; /
                    LDA $E4,x               ; \ 
                    CMP #$00                ;  | if the sprite has gone off the side of the level...
                    LDA $14E0,x             ;  |
                    SBC #$00                ;  |
                    CMP #$02                ;  |
                    BCS ERASE_SPRITE        ; /  ...erase the sprite
                    LDA $13                 ;A:0000 X:0009 Y:00E4 D:0000 DB:01 S:01F3 P:eNvMXdizcHC:1218 VC:250 00 FL:5379
                    LSR A                   ;A:0016 X:0009 Y:00E4 D:0000 DB:01 S:01F3 P:envMXdizcHC:1242 VC:250 00 FL:5379
                    AND #$01                ;A:000B X:0009 Y:00E4 D:0000 DB:01 S:01F3 P:envMXdizcHC:1256 VC:250 00 FL:5379
                    STA $01                 ;A:0001 X:0009 Y:00E4 D:0000 DB:01 S:01F3 P:envMXdizcHC:1272 VC:250 00 FL:5379
                    TAY                     ;A:0001 X:0009 Y:00E4 D:0000 DB:01 S:01F3 P:envMXdizcHC:1296 VC:250 00 FL:5379
                    LDA $1C                 ;A:001A X:0009 Y:0001 D:0000 DB:01 S:01F3 P:eNvMXdizcHC:0052 VC:251 00 FL:5379
                    CLC                     ;A:00BD X:0009 Y:0001 D:0000 DB:01 S:01F3 P:eNvMXdizcHC:0076 VC:251 00 FL:5379
                    ADC SPR_T12,y           ;A:00BD X:0009 Y:0001 D:0000 DB:01 S:01F3 P:eNvMXdizcHC:0090 VC:251 00 FL:5379
                    ROL $00                 ;A:006D X:0009 Y:0001 D:0000 DB:01 S:01F3 P:enVMXdizCHC:0122 VC:251 00 FL:5379
                    CMP $D8,x               ;A:006D X:0009 Y:0001 D:0000 DB:01 S:01F3 P:eNVMXdizcHC:0160 VC:251 00 FL:5379
                    PHP                     ;A:006D X:0009 Y:0001 D:0000 DB:01 S:01F3 P:eNVMXdizcHC:0190 VC:251 00 FL:5379
                    LDA $001D             ;A:006D X:0009 Y:0001 D:0000 DB:01 S:01F2 P:eNVMXdizcHC:0212 VC:251 00 FL:5379
                    LSR $00                 ;A:0000 X:0009 Y:0001 D:0000 DB:01 S:01F2 P:enVMXdiZcHC:0244 VC:251 00 FL:5379
                    ADC SPR_T13,y           ;A:0000 X:0009 Y:0001 D:0000 DB:01 S:01F2 P:enVMXdizCHC:0282 VC:251 00 FL:5379
                    PLP                     ;A:0000 X:0009 Y:0001 D:0000 DB:01 S:01F2 P:envMXdiZCHC:0314 VC:251 00 FL:5379
                    SBC $14D4,x             ;A:0000 X:0009 Y:0001 D:0000 DB:01 S:01F3 P:eNVMXdizcHC:0342 VC:251 00 FL:5379
                    STA $00                 ;A:00FF X:0009 Y:0001 D:0000 DB:01 S:01F3 P:eNvMXdizcHC:0374 VC:251 00 FL:5379
                    LDY $01                 ;A:00FF X:0009 Y:0001 D:0000 DB:01 S:01F3 P:eNvMXdizcHC:0398 VC:251 00 FL:5379
                    BEQ SPR_L38             ;A:00FF X:0009 Y:0001 D:0000 DB:01 S:01F3 P:envMXdizcHC:0422 VC:251 00 FL:5379
                    EOR #$80                ;A:00FF X:0009 Y:0001 D:0000 DB:01 S:01F3 P:envMXdizcHC:0438 VC:251 00 FL:5379
                    STA $00                 ;A:007F X:0009 Y:0001 D:0000 DB:01 S:01F3 P:envMXdizcHC:0454 VC:251 00 FL:5379
SPR_L38:             LDA $00                 ;A:007F X:0009 Y:0001 D:0000 DB:01 S:01F3 P:envMXdizcHC:0478 VC:251 00 FL:5379
                    BPL RETURN_35           ;A:007F X:0009 Y:0001 D:0000 DB:01 S:01F3 P:envMXdizcHC:0502 VC:251 00 FL:5379
                    BMI ERASE_SPRITE        ;A:8AFF X:0002 Y:0000 D:0000 DB:01 S:01F3 P:eNvMXdizcHC:0704 VC:184 00 FL:5490

SUB_IS_OFF_SCREEN:   LDA $15A0,x             ; \ if sprite is on screen, accumulator = 0 
                    ORA $186C,x             ; |  
                    RTS                     ; / 
