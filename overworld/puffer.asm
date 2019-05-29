;porcu puffer that tries to swim towards Mario angrily when he gets close (horizontally)


;X Positions between which the puffer bounces
!LeftEdge       = $0060
!RightEdge      = $0078

!dir = !ow_sprite_misc_1

print "INIT ",pc
        %OverworldHorzPos()
        TYA
        STA !dir,x
        LDA #$0010
        STA !ow_sprite_timer_1,x
        LDA !ow_sprite_y_pos,x
        CLC : ADC #$0003
        STA !ow_sprite_y_pos,x
        RTL

print "MAIN ",pc
        JSR Graphics
        LDA !dir,x
        ASL
        TAY
        LDA !ow_sprite_timer_1,x
        BNE +
        LDA #$0010
        STA !ow_sprite_timer_1,x
        %OverworldHorzPos()
        TYA
        STA !dir,x
        ASL
        TAY

+       LDA !ow_sprite_x_pos,x
        CMP #!LeftEdge
        BCS +

-       LDA !ow_sprite_speed_x,x
        EOR #$FFFF
        INC
        STA !ow_sprite_speed_x,x
        TYA
        EOR #$0002
        TAY
        BRA ++

+       CMP #!RightEdge
        BCS -

++      LDA $14
        AND #$0003
        BNE ++
        PHY
        %OverworldDistance()
        PLY
        LDA $06
        CMP #$0030
        BCC +

-       LDA !ow_sprite_speed_x,x
        BMI IsNegative
        LDY #$04
        BRA fuku
IsNegative:
        LDY #$06
        BRA fuku

+       LDA $08
        CMP #$0030
        BCS -

fuku:
        LDA !ow_sprite_speed_x,x
        CMP max,y
        BEQ ++
        CLC : ADC accel,y
        STA !ow_sprite_speed_x,x

++      %OverworldXSpeed()

        LDY !ow_sprite_misc_2,x
        LDA !ow_sprite_speed_y,x
        CMP maxy,y
        BNE +

        LDA !ow_sprite_misc_2,x
        EOR #$0002
        STA !ow_sprite_misc_2,x

+       LDA !ow_sprite_speed_y,x
        CLC : ADC accely,y
        STA !ow_sprite_speed_y,x
        %OverworldYSpeed()
        RTL

accel:
        dw $0008,$FFF8,$FFF8,$0008
max:
        dw $0080,$FF80,$0000,$0000
accely:
        dw $0002,$FFFE
maxy:
        dw $0030,$FFD0
tile:
        db $A0,$00,$A2
prop:
        db $62,$22

Graphics:
        %OverworldHorzPos()
        SEP #$20
        LDA prop,y
        XBA
        LDA $14
        AND #$02
        TAY
        LDA !ow_sprite_speed_x,x
        BNE +
        LDY #$00
+       LDA tile,y
        REP #$20
        STA $0A
        LDA #$0000
        %OverworldGetDrawInfo()
        BCS .offscreen

        SEP #$20
        LDA $00
        STA $0200|!Base2,y
        LDA $02
        STA $0201|!Base2,y
        REP #$20
        LDA $0A
        STA $0202|!Base2,y
        TYA
        LSR #2
        TAY
        SEP #$20
        LDA #$02
        STA $0420|!Base2,y
        REP #$20
        SEP #$10
.offscreen
        RTS

