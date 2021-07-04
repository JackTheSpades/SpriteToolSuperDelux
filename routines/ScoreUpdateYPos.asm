
?main:
    bcs ?.already_set
    lda #$04
?.already_set
    sta $00
    phb
    phk
    plb
    lda !score_y_speed,x
    lsr #4
    tay 
    lda $13
    and ?.point_speed_y,y
    bne ?.return
    lda !score_y_low,x
    tay 
    sec 
    sbc $1C 
    cmp $00
    bcc ?.return
    dec !score_y_low,x
    tya 
    bne ?.return
    dec !score_y_high,x
?.return
    plb
    rtl

?.point_speed_y 
    db $03,$01,$00,$00