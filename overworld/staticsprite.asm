;   immobile sprite that just displays its graphics
;   extra byte decides which graphic to display

;   order: extra byte
;   1 = first index,
;   2 = second index,
;   etc.
props:
        db $12,$12,$12
tiles:
        db $00,$02,$04
tile_sizes:
        db $00,$00,$00

main:
        LDA #$0000
        JSL get_draw_info
        BCS init
        ; LDA #$0000
        SEP #$20

        LDA $00
        STA $0200|!addr,y       ;   x pos
        LDA $02
        STA $0201|!addr,y       ;   y pos


        LDA !ow_sprite_extra_byte,x
        TAX
        LDA props,x
        STA $0203|!addr,y       ;   props

        LDA tiles,x
        STA $0202|!addr,y       ;   tile

        REP #$20
        TYA
        LSR #2
        TAY
        SEP #$20
        LDA tile_sizes,x        ;   tile size
        STA $0420|!addr,y


        LDX !ow_sprite_index
        REP #$20
        SEP #$10
init:
        RTL

