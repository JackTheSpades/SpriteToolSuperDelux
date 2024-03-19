; Ranged pseudorandom number generation.
; Input: A = max value
; Output: A = random number in the interval [0, A]
 
?main:
    phx : php
    sep #$30

    pha
    inc
    and $01,s
    beq ?.powOf2                        ; max of the form 2^n - 1, so we can just use a bitwise and instead of a divide

?.divide:
    if !sa1 == 0
        jsl $01ACF9|!bank               ; first byte in both A and $148C, second in $148D
        sta $4204                       ; dividend, low byte
        lda $148D|!addr : sta $4205     ; dividend, high byte
        pla : inc
        sta $4206                       ; divisor
        nop #8                          ; wait 16 cycles
        lda $4216                       ; remainder
    else
        lda #$01 : sta $2250            ; select division
        jsl $01ACF9|!bank               ; first byte in both A and $148C, second in $148D
        sta $2251                       ; dividend, low byte
        lda $148D|!addr : lsr           ; workaround for snes9x bug: https://github.com/snes9xgit/snes9x/issues/799 (don't really want a negative dividend anyway)
        sta $2252                       ; dividend, high byte
        pla : inc
        sta $2253                       ; divisor, low byte
        stz $2254                       ; divisor, high byte
        nop : bra $00                   ; wait 5 cycles
        lda $2308                       ; remainder, low byte
    endif

    plp : plx
    rtl

?.powOf2:
    jsl $01ACF9|!bank
    pla
    and $148C|!addr
    plp : plx
    rtl
