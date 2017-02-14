
!foundExtSlot = FindExtOAMSlot_foundSlot

macro speedup(offset)
		LDA.w $01FD+<offset>+!base2	; get Y position of PREVIOUS tile in OAM
		CMP #$F0			; F0 means it's free (Y=F0 means it can't be seen)
		BEQ ?notFound			; \  if last isn't free
		LDA.b #<offset>			;  | (and this is), then
		JMP !foundExtSlot		; /  this is the index
?notFound:
endmacro

macro bulkSpeedup(arg)
		%speedup(<arg>+12)
		%speedup(<arg>+8)
		%speedup(<arg>+4)
		%speedup(<arg>)
endmacro

;----------------------------------
; cluster sprites
;----------------------------------

ClusterSprite09:
;RTL

ClusterSprite0A:
;RTL

ClusterSprite0B:
;RTL

ClusterSprite0C:
;RTL

ClusterSprite0D:
;RTL

ClusterSprite0E:
;RTL

ClusterSprite0F:
RTL

;----------------------------------
; extended sprites
;----------------------------------

ExtendedSprite13:
;RTL

ExtendedSprite14:
;RTL

ExtendedSprite15:
;RTL

ExtendedSprite16:
;RTL

ExtendedSprite17:
RTL


;----------------------------------
; minor extended sprites
;----------------------------------

MinorExSprite0C:
;RTL

MinorExSprite0D:
;RTL

MinorExSprite0E:
;RTL

MinorExSprite0F:
RTL

;----------------------------------
; bounce sprites
;----------------------------------

BounceSprite08:
;RTL

BounceSprite09:
;RTL

BounceSprite0A:
;RTL

BounceSprite0B:
RTL

;----------------------------------
; score sprites
;----------------------------------

ScoreSprite16:
;RTL

ScoreSprite17:
;RTL

ScoreSprite18:
;RTL

ScoreSprite19:
;RTL

ScoreSprite1A:
;RTL

ScoreSprite1B:
;RTL

ScoreSprite1C:
;RTL

ScoreSprite1D:
;RTL

ScoreSprite1E:
;RTL

ScoreSprite1F:
RTL

;----------------------------------
; smoke images
;----------------------------------

SmokeImage06:
;RTL

SmokeImage07:
RTL

;----------------------------------
; spinning coins
;----------------------------------

SpinningCoin02:
;RTL

SpinningCoin03:
RTL

;----------------------------------
; subroutines
;----------------------------------

;------------------------------------------------
; extended sprite/object contact routine
;------------------------------------------------

ExSprObjContact:

; $02A56E		;

STZ $0F			;
STZ $0E			;
STZ $0B			;
STZ $1694|!base2		;
LDA $140F|!base2		;
BNE Code02A5BC	;
LDA $0D9B|!base2		;
BPL Code02A5BC	;
AND #$40		;
BEQ Code02A592	;
LDA $0D9B|!base2		;
CMP #$C1		;
BEQ Code02A5BC	;
LDA $1715|!base2,x		;
CMP #$A8		;
RTS				;

Code02A592:		;
LDA $171F|!base2,x		;
CLC				;
ADC #$04		;
STA $14B4|!base2		;
LDA $1733|!base2,x		;
ADC #$00		;
STA $14B5|!base2		;
LDA $1715|!base2,x		;
CLC				;
ADC #$08		;
STA $14B6|!base2		;
LDA $1729|!base2,x		;
ADC #$00		;
STA $14B7|!base2		;
JSL $01CC9D|!base3		;
LDX $15E9|!base2		;
RTS				;

Code02A5BC:		;
JSR Code02A611	;
ROL $0E			;
LDA $1693|!base2		;
STA $0C			;
LDA $5B			;
BPL Code02A60C	;
INC $0F			;
LDA $171F|!base2,x		;
PHA				;
CLC				;
ADC $26			;
STA $171F|!base2,x		;
LDA $1733|!base2,x		;
PHA				;
ADC $27			;
STA $1733|!base2,x		;
LDA $1715|!base2,x		;
PHA				;
CLC				;
ADC $28			;
STA $1715|!base2,x		;
LDA $1729|!base2,x		;
PHA				;
ADC $29			;
STA $1729|!base2,x		;
JSR Code02A611	;
ROL $0E			;
LDA $1693|!base2		;
STA $0D			;
PLA				;
STA $1729|!base2,x		;
PLA				;
STA $1715|!base2,x		;
PLA				;
STA $1733|!base2,x		;
PLA				;
STA $171F|!base2,x		;
Code02A60C:		;
LDA $0E			;
CMP #$01		;
RTS				;

Code02A611:		;
LDA $0F			;
INC				;
AND $5B			;
BEQ Code02A679	;
LDA $1715|!base2,x		;
CLC				;
ADC #$08		;
STA $98			;
AND #$F0		;
STA $00			;
LDA $1729|!base2,x		;
ADC #$00		;
CMP $5D			;
BCS Code02A677	;
STA $03			;
STA $99			;
LDA $171F|!base2,x		;
CLC				;
ADC #$04		;
STA $01			;
STA $9A			;
LDA $1733|!base2,x		;
ADC #$00		;
CMP #$02		;
BCS Code02A677	;
STA $02			;
STA $9B			;
LDA $01			;
LSR #4			;
ORA $00			;
STA $00			;
LDX $03			;
LDA $00BA80|!base3,x	;
LDY $0F			;
BEQ Code02A660	;
LDA $00BA8E|!base3,x	;
Code02A660:		;
CLC				;
ADC $00			;
STA $05			;
LDA $00BABC|!base3,x	;
LDY $0F			;
BEQ Code02A671	;
LDA $00BACA|!base3,x	;
Code02A671:		;
ADC $02			;
STA $06			;
BRA Code02A6DB	;

Code02A677:		;
CLC				;
RTS				;

Code02A679:		;
LDA $1715|!base2,x		;
CLC				;
ADC #$08		;
STA $98			;
AND #$F0		;
STA $00			;
LDA $1729|!base2,x		;
ADC #$00		;
STA $02			;
STA $99			;
LDA $00			;
SEC				;
SBC $1C			;
CMP #$F0		;
BCS Code02A677	;
LDA $171F|!base2,x		;
CLC				;
ADC #$04		;
STA $01			;
STA $9A			;
LDA $1733|!base2,x		;
ADC #$00		;
CMP $5D			;
BCS Code02A677	;
STA $03			;
STA $9B			;
LDA $01			;
LSR #4			;
ORA $00			;
STA $00			;
LDX $03			;
LDA $00BA60|!base3,x	;
LDY $0F			;
BEQ Code02A6C6	;
LDA $00BA70|!base3,x	;
Code02A6C6:		;
CLC				;
ADC $00			;
STA $05			;
LDA $00BA9C|!base3,x	;
LDY $0F			;
BEQ Code02A6D7	;
LDA $00BAAC|!base3,x	;
Code02A6D7:		;
ADC $02			;
STA $06			;

Code02A6DB:		;
LDA.b #!7E			;
STA $07			;
LDX $15E9|!base2		;
LDA [$05]		;
STA $1693|!base2		;
INC $07			;
LDA [$05]		;
JSL $00F545|!base3		;
CMP #$00		;
BEQ Code02A729	;
LDA $1693|!base2		;
CMP #$11		;
BCC Code02A72B	;
CMP #$6E		;
BCC Code02A727	;
CMP #$D8		;
BCS Code02A735	;
LDY $9A			;
STY $0A			;
LDY $98			;
STY $0C			;
JSL $00FA19|!base3		;
LDA $00			;
CMP #$0C		;
BCS Code02A718	;
CMP [$05],y		;
BCC Code02A729	;
Code02A718:		;
LDA [$05],y		;
STA $1694|!base2		;
PHX				;
LDX $08			;
LDA $00E53D|!base3,x	;
PLX				;
STA $0B			;
Code02A727:		;
SEC				;
RTS				;

Code02A729:		;
CLC				;
RTS				;

Code02A72B:		;
LDA $98			;
AND #$0F		;
CMP #$06		;
BCS Code02A729	;
SEC				;
RTS				;

Code02A735:		;
LDA $98			;
AND #$0F		;
CMP #$06		;
BCS Code02A729	;
LDA $1715|!base2,x		;
SEC				;
SBC #$02			;
STA $1715|!base2,x		;
LDA $1729|!base2,x		;
SBC #$00			;
STA $1729|!base2,x		;
JMP Code02A611	;

;------------------------------------------------
; speed routines
;------------------------------------------------

ExSprUpdateXPos:

LDA $1747|!base2,x		;
ASL #4			;
CLC				;
ADC $175B|!base2,x		;
STA $175B|!base2,x		;
PHP				;
LDY #$00			;
LDA $1747|!base2,x		;
LSR #4			;
CMP #$08		;
BCC $03			;
ORA #$F0		;
DEY				;
PLP				;
ADC $171F|!base2,x		;
STA $171F|!base2,x		;
TYA				;
ADC $1733|!base2,x		;
STA $1733|!base2,x		;
RTS				;

ExSprUpdateYPos:

LDA $173D|!base2,x		;
ASL #4			;
CLC				;
ADC $1751|!base2,x		;
STA $1751|!base2,x		;
PHP				;
LDY #$00			;
LDA $173D|!base2,x		;
LSR #4			;
CMP #$08		;
BCC $03			;
ORA #$F0		;
DEY				;
PLP				;
ADC $1715|!base2,x		;
STA $1715|!base2,x		;
TYA				;
ADC $1729|!base2,x		;
STA $1729|!base2,x		;
RTS				;

ClusterUpdateXPos:

LDA $1E66|!base2,x			;
ASL #4				;
CLC					;
ADC $1E8E|!base2,x			;
STA $1E8E|!base2,x			;
PHP					;
LDA $1E66|!base2,x			;
LSR #4				;
CMP #$08			;
LDY #$00				;
BCC $03				;
ORA #$F0			;
DEY					;
PLP					;
ADC $1E16|!base2,x			;
STA $1E16|!base2,x			;
TYA					;
ADC $1E3E|!base2,x			;
STA $1E3E|!base2,x			;
RTS					;

ClusterUpdateYPos:

LDA $1E52|!base2,x			;
ASL #4				;
CLC					;
ADC $1E7A|!base2,x			;
STA $1E7A|!base2,x			;
PHP					;
LDA $1E52|!base2,x			;
LSR #4				;
CMP #$08			;
LDY #$00				;
BCC $03				;
ORA #$F0			;
DEY					;
PLP					;
ADC $1E02|!base2,x			;
STA $1E02|!base2,x			;
TYA					;
ADC $1E2A|!base2,x			;
STA $1E2A|!base2,x			;
RTS					;

MinorExUpdateXPos:

LDA $182C|!base2,x		;
ASL #4			;
CLC				;
ADC $1844|!base2,x		;
STA $1844|!base2,x		;
PHP				;
LDA $182C|!base2,x		;
LSR #4			;
CMP #$08		;
BCC $02			;
ORA #$F0		;
PLP				;
ADC $1808|!base2,x		;
STA $1808|!base2,x		;
RTS				;

MinorExUpdateYPos:

LDA $1820|!base2,x		;
ASL #4			;
CLC				;
ADC $1838|!base2,x		;
STA $1838|!base2,x		;
PHP				;
LDA $1820|!base2,x		;
LSR #4			;
CMP #$08		;
BCC $02			;
ORA #$F0		;
PLP				;
ADC $17FC|!base2,x		;
STA $17FC|!base2,x		;
RTS				;

;------------------------------------------------
; screen boundary check/OAM index setters
;------------------------------------------------

GetDrawInfoE:

LDA $171F|!base2,x			; if the sprite is offscreen either horizontally or vertically,
SEC					; then return (Z = 0)
SBC $1A				;
STA $00				; X position relative to screen boundary into $00
LDA $1733|!base2,x			;
SBC $1B				;
BNE .Erase			;
LDA $1715|!base2,x			;
SEC					;
SBC $1C				; Y position relative to screen boundary into $01
STA $01				;
LDA $1729|!base2,x			;
SBC $1D				;
BNE .Erase			;
JSR FindExtOAMSlot		; if no slot is found, then Z = 0 anyway
LDA #$00			;
RTL					;
.Erase				;
STZ $170B|!base2,x			;
LDA #$01			;
RTS					;

GetDrawInfoC:

LDA $1E16|!base2,x			; if the sprite is offscreen either horizontally or vertically,
SEC					; then return (Z = 0)
SBC $1A				;
STA $00				; X position relative to screen boundary into $00
LDA $1E3E|!base2,x			;
SBC $1B				;
BNE .Erase			;
LDA $1E02|!base2,x			;
SEC					;
SBC $1C				; Y position relative to screen boundary into $01
STA $01				;
LDA $1E2A|!base2,x			;
SBC $1D				;
BNE .Erase			;
JSR FindExtOAMSlot		; if no slot is found, then Z = 0 anyway
LDA #$00			;
RTS					;
.Erase				;
STZ $1892|!base2,x			;
LDA #$01			;
RTS					;

;------------------------------------------------
; OAM slot routine
;------------------------------------------------

FindExtOAMSlot:

%bulkSpeedup($F0)		;
%bulkSpeedup($E0)		;
%bulkSpeedup($D0)	;
%bulkSpeedup($C0)		;
%bulkSpeedup($B0)		;
%bulkSpeedup($A0)		;
%bulkSpeedup($90)		;
%bulkSpeedup($80)		;
%bulkSpeedup($70)		;
%bulkSpeedup($60)		;
%bulkSpeedup($50)		;
%bulkSpeedup($40)		;
LDA #$3C			;
.foundSlot			;
TAY					;
RTS					;

;------------------------------------------------
; clipping routines
;------------------------------------------------

GetExSprClipping2:		; extended sprite clipping routine, equivalent to $03B69F

LDA $1733|!base2,x			;
XBA					;
LDA $171F|!base2,x			;
REP #$20				;
CLC					;
ADC $08				;
STA $08				; $08-$09 = sprite X position plus X displacement
;LDA $0C				;
;STA $0C				; $0C-$0D = sprite clipping width
SEP #$20				;
LDA $1729|!base2,x			;
XBA					;
LDA $1715|!base2,x			;
REP #$20				;
CLC					;
ADC $0A				;
STA $0A				; $0A-$0B = sprite Y position plus Y displacement
;LDA $0E				;
;STA $0E				; $0E-$0F = sprite clipping height
SEP #$20				;
RTL					;

GetClusterClipping2:	; cluster sprite clipping routine, equivalent to $03B69F

LDA $1E3E|!base2,x			;
XBA					;
LDA $1E16|!base2,x			;
REP #$20				;
CLC					;
ADC $08				;
STA $08				; $08-$09 = sprite X position plus X displacement
;LDA $0C				;
;STA $0C				; $0C-$0D = sprite clipping width
SEP #$20				;
LDA $1E2A|!base2,x			;
XBA					;
LDA $1E02|!base2,x			;
REP #$20				;
CLC					;
ADC $0A				;
STA $0A				; $0A-$0B = sprite Y position plus Y displacement
;LDA $0E				;
;STA $0E				; $0E-$0F = sprite clipping height
SEP #$20				;
RTS					;


GetPlayerClipping2:		; modified player clipping routine, based off and equivalent to $03B664

PHX					;
REP #$20				;
LDA $94				;
CLC					;
ADC #$0002			;
STA $00				; $00-$01 = player X position plus X displacement
LDA #$000C			;
STA $04				; $04-$05 = player clipping width
SEP #$20				;
LDX #$00				;
LDA $73				;
BNE .Inc1				;
LDA $19				;
BNE .Next1			;
.Inc1				;
INX					;
.Next1				;
LDA $187A|!base2		;
BEQ .Next2			;
INX #2				;
.Next2				;
LDA $03B660|!base3,x		;
STA $06				; $06-$07 = player clipping height
STZ $07				;
LDA $03B65C|!base3,x		;
REP #$20				;
AND #$00FF			;
CLC					;
ADC $96				;
STA $02				; $02-$03 = player Y position plus Y displacement
SEP #$20				;
PLX					;
RTS					;

GetSpriteClippingA2:	; custom sprite clipping routine, equivalent to $03B69F

LDA !14E0,x			;
XBA					;
LDA !E4,x			;
REP #$20				;
CLC					;
ADC #$0002			;
STA $08				; $08-$09 = sprite X position plus X displacement
LDA #$000C			;
STA $0C				; $0C-$0D = sprite clipping width
SEP #$20				;
LDA !14D4,x			;
XBA					;
LDA !D8,x			;
REP #$20				;
CLC					;
ADC #$0006			;
STA $0A				; $0A-$0B = sprite Y position plus Y displacement
LDA #$000C			;
STA $0E				; $0E-$0F = sprite clipping height
SEP #$20				;
RTS					;

GetSpriteClippingB2:	; custom sprite clipping routine, equivalent to $03B6E5

LDA !14E0,x			;
XBA					;
LDA !E4,x			;
REP #$20				;
CLC					;
ADC #$0002			;
STA $00				; $00-$01 = sprite X position plus X displacement
LDA #$000C			;
STA $04				; $04-$05 = sprite clipping width
SEP #$20				;
LDA !14D4,x			;
XBA					;
LDA !D8,x			;
REP #$20				;
CLC					;
ADC #$0006			;
STA $02				; $02-$03 = sprite Y position plus Y displacement
LDA #$000C			;
STA $06				; $06-$07 = sprite clipping height
SEP #$20				;
RTS					;

CheckForContact2:		; custom contact check routine, equivalent to $03B72B

REP #$20				;

.CheckX				;
LDA $00				; if the sprite's clipping field is to the right of the player's,
CMP $08				; subtract the former from the latter;
BCC .CheckXSub2		; if the player's clipping field is to the right of the sprite's,
.CheckXSub1			; subtract the latter from the former
SEC					;
SBC $08				;
CMP $0C				;
BCS .ReturnNoContact	;
BRA .CheckY			;
.CheckXSub2			;
LDA $08				;
SEC					;
SBC $00				;
CMP $04				;
BCS .ReturnNoContact	;

.CheckY				;
LDA $02				; if the sprite's clipping field is below the player's,
CMP $0A				; subtract the former from the latter;
BCC .CheckYSub2		; if the player's clipping field is above the sprite's,
.CheckYSub1			; subtract the latter from the former
SEC					;
SBC $0A				;
CMP $0E				;
BCS .ReturnNoContact	;
.ReturnContact		;
SEC					;
SEP #$20				;
RTS					;
.CheckYSub2			;
LDA $0A				;
SEC					;
SBC $02				;
CMP $06				;
BCC .ReturnContact		;
.ReturnNoContact		;
CLC					;
SEP #$20				;
RTS					;

;------------------------------------------------
; smoke routine for cluster sprites
;------------------------------------------------

ClusterSmoke:

LDY #$03
.LoopStart
LDA $17C0|!base2,y
BEQ .SlotFound
DEY
BPL .LoopStart
RTS

.SlotFound
LDA #$01
STA $17C0|!base2,y
LDA $1E02|!base2,x
STA $17C4|!base2,y
LDA $1E16|!base2,x
STA $17C8|!base2,y
LDA #$18
STA $17CC|!base2,y
.EndSmoke
RTS







