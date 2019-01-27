;worst world muncher burping generator
;coughs out smoke sprites left and right (figuratively, it's actually only to the right)

!xspeed = $0180
;speed of the cloud

main:
        LDA $14
        AND #$000F
        BNE init

;   spawn particles with right speed
        LDA.w #!smoke_id
        STA $00
        LDA !ow_sprite_x_pos,x
        STA $02
        LDA !ow_sprite_y_pos,x
        STA $04
        LDA !ow_sprite_z_pos,x
        STA $06
        STZ $08
        JSL spawn_sprite
        BCC init

;   make it fly right
        LDA #!xspeed
        STA !ow_sprite_speed_x,x

;   make it be the burps
        LDA #$0004
        STA !ow_sprite_misc_2,x
        LDX !ow_sprite_index
init:
        RTL
