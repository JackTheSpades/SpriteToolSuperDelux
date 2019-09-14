; void
; ->
; Y: mangled
; $00: absolute value of the distance between player and sprite, x axis
; $02: absolute value of the distance between player and sprite, y axis
; $06: distance between player and sprite, x axis
; $08: distance between player and sprite, y axis

        LDA !ow_sprite_x_pos,x
        CLC
        ADC #$0008
        LDY $0DD6|!Base2         ;   Mario: 00   Luigi: 04
        SEC
        SBC $1F17|!Base2,y       ;   Mario/Luigi x position
        STA $00
        BPL ?+
        EOR #$FFFF              ;   if distance is minus, do bit reverse
        INC
?+      STA $06                 ;   x distance between mario/luigi and sprite
        LDA !ow_sprite_y_pos,x
        CLC
        ADC #$0008
        LDY $0DD6|!Base2         ;   Mario: 00  Luigi: 04
        SEC
        SBC $1F19|!Base2,y       ;   Mario/Luigi y position
        STA $02
        BPL ?+
        EOR #$FFFF              ;   if distance is minus, do bit reverse
        INC
?+      STA $08                 ;   y distance between mario/luigi and sprite
        RTL

