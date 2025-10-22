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
        jsl $01ACF9|!bank               ; first byte in both A and $148D, second in $148E
        sta $4204                       ; dividend, low byte
        lda $148E|!addr : sta $4205     ; dividend, high byte
        pla : inc
        sta $4206                       ; divisor
        nop #5 : bra $00                ; wait 16 cycles (3 cycles are taken up the lda that reads the result, so we only need to wait 13 more)
                                        ; explanation is below
        lda $4216                       ; remainder
    else
        lda #$01 : sta $2250            ; select division
        jsl $01ACF9|!bank               ; first byte in both A and $148D, second in $148E
        sta $2251                       ; dividend, low byte
        lda $148E|!addr : lsr           ; workaround for snes9x bug: https://github.com/snes9xgit/snes9x/issues/799 (don't really want a negative dividend anyway)
        sta $2252                       ; dividend, high byte
        pla : inc
        sta $2253                       ; divisor, low byte
        stz $2254                       ; divisor, high byte
        nop                             ; wait 2 cycles
                                        ; SA-1 research by Vitor shows that the necessary number of 10.74 MHz cycles to wait to get a result from division is 5
                                        ; however, the lda that reads the result takes 3 cycles to fetch the opcode and operands, and so we just need to wait 2 cycles beforehand
        lda $2308                       ; remainder, low byte
    endif

    plp : plx
    rtl

?.powOf2:
    jsl $01ACF9|!bank
    pla
    and $148D|!addr
    plp : plx
    rtl

