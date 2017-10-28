;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; SubOffScreen - Optimized version
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Argument
; A: type (#$00=X0, #$01=X1 ... #$07=X7)
; Only last 3 bits are used
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 
    AND #$07
    ASL
 
    TAY
    LDA !15A0,x
    ORA !186C,x
    BEQ .Return2
    LDA !167A,x
    AND #$04
    BNE .Return2
    LDA $5B
    LSR A
    BCS .VerticalLevel
    LDA !D8,x
    ADC #$50
    LDA !14D4,x
    ADC #$00
    CMP #$02
    BCS .EraseSprite
    LDA !14E0,x
    XBA
    LDA !E4,x
    REP #$21
    ADC .AddTable,y
    SEC : SBC $1A
    CMP .CmpTable,y
.Common
    SEP #$20
    BCC .Return2
.EraseSprite
    LDA !14C8,x
    CMP #$08
    BCC .KillSprite
    LDY !161A,x
    CPY #$FF
    BEQ .KillSprite
    if !SA1 == 0
        LDA $1938,y
        AND #$FE
        STA $1938,y
    else
        PHX : TYX
        LDA $418A00,x
        AND #$FE
        STA $418A00,x
        PLX
    endif
.KillSprite
    STZ !14C8,x
.Return2
    RTL
 
.VerticalLevel
    LDA $13
    LSR A
    BCS .CheckY
    LDA !14E0,x
    XBA
    LDA !E4,x
    REP #$21
    ADC.w #$0040
    CMP.w #$0280
    BRA .Common
.CheckY
    LDA !14D4,x
    XBA
    LDA !D8,x
    REP #$20
    SBC $1C
    CLC
    ADC.w #$0070
    CMP.w #$01D0
    BRA .Common
 
.AddTable
    dw $0040,$0040,$0010,$0070
    dw $0090,$0050,$0080,$FFC0
.CmpTable
    dw $0170,$01E0,$01B0,$01D0
    dw $0230,$01B0,$0220,$0160