; Input: A = 00  = Targets Thrown shell only.
;			 01~ = Targets Thrown shell and Fireball.
; Output: C = Clear = The target sprite is not in front of you.
;			  Set	= The target sprite is in front of you.

STA $0E
TXA : EOR $13 : AND #$03
BNE End
LDA !1588,x : AND #$04
BEQ End
JSL $03B69F|!BankB
LDY #!SprSize-1
.Loops:
LDA !14C8,y : CMP #$0A
BEQ .Slipping_Shell
.Next
DEY : BPL .Loops
+
LDA $0E : BEQ End
BRA JumpOverFire

.Slipping_Shell:
SEC
LDA !E4,y : SBC #$22 : STA $00
LDA !14E0,y : SBC #$00 : STA $08
LDA #$54 : STA $02
LDA !D8,y : STA $01
LDA !14D4,y : STA $09
LDA #$10 : STA $03
JSL $03B72B|!BankB
BCC .Next
LDA !157C,y : CMP !157C,x
BEQ .Next
SEC : RTL

End:
CLC : RTL

JumpOverFire:
LDY #09
.Loops:
LDA $170B|!Base2,y
CMP #$05 : BEQ .FireBall
.Next
DEY : BPL .Loops
+
CLC : RTL

.FireBall:
SEC
LDA $171F|!Base2,y : SBC #$4A : STA $00
LDA $1733|!Base2,y : SBC #$00 : STA $08
LDA #$9C : STA $02
LDA $1715|!Base2,y : STA $01
LDA $1729|!Base2,y : STA $09
LDA #$10 : STA $03
JSL $03B72B|!BankB
BCC .Next
STZ $00
LDA $1747|!Base2,y : BPL +
INC $00
+
LDA $00 : CMP !157C,x
BEQ .Next
SEC : RTL
