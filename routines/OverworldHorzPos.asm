; void -> Y = 0 if player is on the right, else Y = 1

        LDY $0DD6|!Base2
        LDA $1F17|!Base2,y
        LDY #$0000
        SEC : SBC #$0008
        SEC : SBC !ow_sprite_x_pos,x
        BPL $01
        INY
        RTL
