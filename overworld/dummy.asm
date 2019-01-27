;   each sprite is namespaced so your labels can be whatever :)

!dummy_turn_timer = !ow_sprite_timer_1
!dummy_anim_index = !ow_sprite_misc_1

!dummy_time = $0090


init:
        LDA #!dummy_time
        STA !dummy_turn_timer,x
        LDA #$0170
        STA !ow_sprite_speed_x,x
        RTL

main:
        JSR draw_gfx
        LDA $14
        AND #$0007
        BNE +
        LDA !dummy_anim_index,x
        INC
        AND #$0003
        STA !dummy_anim_index,x

+       LDA !dummy_turn_timer,x
        BNE +
        LDA !ow_sprite_speed_x,x
        EOR #$FFFF
        INC
        STA !ow_sprite_speed_x,x
        LDA #!dummy_time
        STA !dummy_turn_timer,x
+       JML update_x_pos

draw_gfx:
        LDA #$0001                      ;   draw 2
        JSL get_draw_info
        BCS .offscreen

        SEP #$20
        LDA !dummy_anim_index,x
        ASL
        STA $04

        LDX #$0001
.loop
        LDA $00                         ;   x pos
        CLC
        ADC .x_disp,x
        STA $0200|!addr,y
        LDA $02                         ;   y pos
        STA $0201|!addr,y
        PHX                             ;   tile
        TXA
        CLC
        ADC $04
        TAX
        LDA .tiles,x
        STA $0202|!addr,y
        PLX
        LDA #$20
        STA $0203|!addr,y
        PHY                             ;   tile size
        REP #$20
        TYA
        LSR #2
        TAY
        SEP #$20
        LDA #$00
        STA $0420|!addr,y
        PLY
        DEY #4                          ;   YOU HAVE TO DEY, NOT INY
        DEX
        BPL .loop

.done
        LDX !ow_sprite_index
        REP #$20
        SEP #$10
.offscreen
        RTS

.x_disp
        db $00,$08

.tiles
        db $D0,$D2              ;   anim frame 1
        db $D1,$D3              ;   anim frame 2
        db $D2,$D0              ;   etc
        db $D3,$D1

