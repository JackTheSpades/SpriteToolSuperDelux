

?main:
    lda !spinning_coin_layer,x
    asl #2
    tay
    rep #$20
    lda.w $1C|!dp,y
    sta $02
    lda.w $1A|!dp,y
    sta $04
    sep #$20
    lda !spinning_coin_y_low,x
    cmp $02
    lda !spinning_coin_y_high,x
    sbc $04
    bne ?.return
    lda !spinning_coin_x_low,x
    sbc $03
    cmp #$F8
    bcs ?.kill
    sta $00
    lda !spinning_coin_y_low,x
    sec 
    sbc $02
    sta $01
    lda.l $0299E9|!BankB,x
    tay
    sec 
    rtl
?.kill
    stz !spinning_coin_num,x
?.return
    clc 
    rtl 