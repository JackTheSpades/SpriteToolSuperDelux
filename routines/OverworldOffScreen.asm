!offs_threshold_x = $0000
!offs_threshold_y = $0000

; void -> carry set if offscreen, else clear

        LDA !ow_sprite_x_pos,x
        SEC
        SBC $1A
        STA $00
        if !offs_threshold_x != 0
                CLC
                ADC #!offs_threshold_x
        endif
        CMP.w #$0100+(!offs_threshold_x*2)
        BCS .return
        LDA.w !ow_sprite_y_pos,x
        SEC
        SBC.w !ow_sprite_z_pos,x
        SEC
        SBC $1C
        STA $02
        if !offs_threshold_y != 0
                CLC
                ADC #!offs_threshold_y
        endif
        CMP.w #$00E0+(!offs_threshold_y*2)
.return
        RTL

