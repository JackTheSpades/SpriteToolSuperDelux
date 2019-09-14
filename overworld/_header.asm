@include

; Circle macros

macro cos()
        PHX
        REP #$11
        ADC #$0080
        BIT #$0100
        PHP
        AND #$00FF
        ASL
        TAX
        LDA $07F7DB,x
        PLP
        SEP #$10
        BEQ ?l1
        EOR #$FFFF
        INC
?l1:    PLX
endmacro

macro sin()
       PHX
       REP #$10
       BIT #$0100
       PHP
       AND #$00FF
       ASL
       TAX
       LDA $07F7DB,x
       PLP
       SEP #$10
       BEQ ?l1
       EOR #$FFFF
       INC
?l1:   PLX
endmacro

