; Routine used for spawning minor extended sprites with initial speed at the position (+offset)
; of the calling sprite and returns the sprite index in Y
; For a list of minor extended sprites see here: 
; https://www.smwcentral.net/?p=memorymap&a=detail&game=smw&region=ram&detail=11c9baba28dd

; Input:
;   A   = number
;   $00 = x offset
;   $01 = y offset
;   $02 = x speed
;   $03 = y speed

; Output:
;   Y = index to minor extended sprite ($FF means no sprite spawned)
;   C = Spawn status
;       Set = Spawn failed
;       Clear = Spawn successful

?main:
    xba 
    lda !15A0,x
    ora !186C,x
    ora !15D0,x
    ;bne ?.ret

    ldy.b #12-1
?.loop
    lda !minor_extended_num,y
    beq ?.found
    dey 
    bpl ?.loop
?.ret
    sec 
    rtl

?.found
    xba 
    sta !minor_extended_num,y
    
    lda $00
    clc 
    adc !E4,x
    sta !minor_extended_x_low,y
    lda #$00
    bit $00
    bpl $01
    dec 
    adc !14E0,x
    sta !minor_extended_x_high,y

    lda $01
    clc 
    adc !D8,x
    sta !minor_extended_y_low,y
    lda #$00
    bit $01
    bpl $01
    dec 
    adc !14D4,x
    sta !minor_extended_y_high,y

    lda $02
    sta !minor_extended_x_speed,y
    lda $03
    sta !minor_extended_y_speed,y
    
    clc 
    rtl
