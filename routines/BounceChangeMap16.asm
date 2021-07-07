; Routine that changes the map16 tile of a block from inside of a bounce sprite.
; You'd be better using %InvisibleMap16() and %RevertMap16() instead of this routine.
;
; Input: 
;   A = Map16 to change into ($9C)
;
; Output:
;   N/A

?main:
    sta $9C
    lda !bounce_y_low,x
    clc
    adc #$08
    and #$F0
    sta $98
    lda !bounce_y_high,x
    adc #$00
    sta $99
    lda !bounce_x_low,x
    clc
    adc #$08
    and #$F0
    sta $9A
    lda !bounce_x_high,x
    adc #$00
    sta $9B
    lda !bounce_properties,x
    asl
    rol
    and #$01
    sta $1933|!addr
    phx
    jsl $00BEB0|!BankB
    plx
    rtl