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

print "MAIN ",pc
        LDA #$0000
        %OverworldGetDrawInfo()
        BCS return
        ; LDA #$0000
        SEP #$20

        LDA $00
        STA $0200|!Base2,y       ;   x pos
        LDA $02
        STA $0201|!Base2,y       ;   y pos


        LDA !ow_sprite_extra_bits,x
        TAX
        LDA props,x
        STA $0203|!Base2,y       ;   props

        LDA tiles,x
        STA $0202|!Base2,y       ;   tile

        REP #$20
        TYA
        LSR #2
        TAY
        SEP #$20
        LDA tile_sizes,x        ;   tile size
        STA $0420|!Base2,y


        LDX !ow_sprite_index
        REP #$20
        SEP #$10
print "INIT ",pc
return:
        RTL

