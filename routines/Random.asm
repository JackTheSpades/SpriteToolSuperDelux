; Ranged pseudorandom number generation.
; Input: A = max value
; Output: A = random number in the interval [0, A]
 
    PHX : PHP
    SEP #$30
    PHA
    JSL $01ACF9|!BankB
    PLX
    CPX #$FF
    BNE .normal
    LDA $148D|!Base2
    BRA .end
 
.normal
    INX
    LDA $148D|!Base2
 
    if !SA1 == 0
        STA $4202               ; Write first multiplicand.
        STX $4203               ; Write second multiplicand.
        NOP #4                  ; Wait 8 cycles.
        LDA $4217               ; Read multiplication product (high byte).
    else
        STZ $2250               ; Set multiplication mode.
        STA $2251               ; Write first multiplicand.
        STZ $2252
        STX $2253               ; Write second multiplicand.
        STZ $2254
        NOP : BRA $00           ; Wait 5 cycles.
        LDA $2307               ; Read multiplication product.
    endif
.end
    PLP : PLX
    RTL
