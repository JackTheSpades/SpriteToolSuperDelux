;lantern that just hangs from the ceiling mate
;extra byte determines how long the rope is ($00 is one rope tile)
;if 7th extra byte bit is set ($80 and up) then don't display any light
;shoots a lethal cone of light that melts mario instantly
;ive been told it is not lethal sorry

!props = $36
;yxPPcCCt of the lotus and rope

!lightprops = $28
;yxPpCcct of the light cone

!LanternTile = $90
;tile for the lantern

!RopeTile = $80
;tile for the ropes


print "INIT ",pc
init:
        RTL
print "MAIN ",pc
;decide whether the lamp is on or off
        LDA !ow_sprite_extra_bits,x
        AND #$0080
        BNE .Skip4Tiles

        LDA #$0006
        STA $00
        BRA .AddTiles

.Skip4Tiles
        LDA #$0002
        STA $00

.AddTiles
        LDA !ow_sprite_extra_bits,x
        AND #$007F
        CLC
        ADC $00        ;rope tiles + 2 lantern tiles + 4 cone tiles
        %OverworldGetDrawInfo()
        BCS init
        LDA #$0000
        SEP #$20

;don't render lantern if last extra bit is set
        LDA !ow_sprite_extra_bits,x
        BMI .NoLight

;CONE TILES
        LDX #$0003
.ConeLoop
        PHX

        LDA $00
        CLC
        ADC .ConeXOff,x
        SEC
        SBC #$08
        STA $0200|!Base2,y       ;   x pos
        LDA $02
        CLC
        ADC .ConeYOff,x
        CLC
        ADC #$04
        STA $0201|!Base2,y       ;   y pos
        LDA #!lightprops
        ORA .ConeFlip,x
        STA $0203|!Base2,y       ;   props
        LDA .ConeTiles,x
        STA $0202|!Base2,y       ;   tiles

;size table write
        PHY
        REP #$20
        TYA
        LSR #2
        TAY
        SEP #$20
        LDA #$02                ;   16x16
        STA $0420|!Base2,y
        PLY

        DEY #4

        PLX
        DEX
        BPL .ConeLoop

.NoLight
;LANTERN TILES
        LDX #$0001
.LanternLoop
        PHX

        LDA $00
        CLC
        ADC .LanternXOff,x
        STA $0200,y             ;   x pos
        LDA $02 
        STA $0201,y             ;   y pos
        LDA #!props
        ORA .ConeFlip,x
        STA $0203,y             ;   props

        LDX !ow_sprite_index
        LDA !ow_sprite_extra_bits,x
        ROL #2
        AND #$01
        CLC
        ADC #!LanternTile
        STA $0202|!Base2,y       ;   tiles

;size table write
        PHY
        REP #$20
        TYA
        LSR #2
        TAY
        SEP #$20
        LDA #$00      ;8x8
        STA $0420,y
        PLY

        DEY #4

        PLX
        DEX
        BPL .LanternLoop

;ROPE TILES
        LDX !ow_sprite_index
        LDA !ow_sprite_extra_bits,x
        AND #$7F
        TAX
.RopeLoop
        PHX

        LDA $00
        CLC
        ADC #$04
        STA $0200|!Base2,y       ;   x pos
        LDA #!props
        STA $0203|!Base2,y       ;   props
        LDA #!RopeTile
        STA $0202|!Base2,y       ;   tiles

        TXA
        ASL #3                  ;   current index (which is !ow_sprite_extra) * 8
        STA $08

        LDA $02
        SEC
        SBC $08                 ;   use the index * 8 and move this rope that many pixels up
        SEC
        SBC #$08
        STA $0201|!Base2,y       ;   y pos

;size table write
        PHY
        REP #$20
        TYA
        LSR #2
        TAY
        SEP #$20
        LDA #$00                ;   8x8
        STA $6420,y
        PLY

        DEY #4

        PLX
        DEX
        BPL .RopeLoop

        LDX !ow_sprite_index
        REP #$20
        SEP #$10
        RTL

.LanternXOff
        db $00,$08
.ConeTiles
        db $86,$86
        db $88,$88
.ConeFlip
        db $00,$40
        db $00,$40
.ConeXOff
        db $00,$10
        db $00,$10
.ConeYOff
        db $00,$00
        db $10,$10

