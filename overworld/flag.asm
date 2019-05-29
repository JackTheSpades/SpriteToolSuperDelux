;swiss flag, animates and does nothing else

!XOff = $0007
!YOff = $0000

!props = $14
;yxpPcCct of the flag

!animationtimer = !ow_sprite_timer_1
;timer used for the animation
!animationframe = !ow_sprite_misc_1
;which frame to display right now

!frames = $0003
;how many animations frames there are
!frametime = $000A
;how many smw frames each sprite frame should show


print "INIT ",pc
        LDA !ow_sprite_x_pos,x
        CLC
        ADC #!XOff
        STA !ow_sprite_x_pos,x

        LDA !ow_sprite_y_pos,x
        CLC
        ADC #!YOff
        STA !ow_sprite_y_pos,x
        RTL

print "MAIN ",pc
        JSR GFX
;timer logic
        LDA !animationtimer,x
        BNE .NoTimerSet

        LDA.w #!frametime
        STA !animationtimer,x

        LDA !animationframe,x
        INC
        STA !animationframe,x
        CMP.w #!frames
        BCC .NoTimerSet
        STZ !animationframe,x
.NoTimerSet
        RTL

GFX:
        LDA #$0000
        %OverworldGetDrawInfo()
        BCS .offscreen

        LDA #$0000
        SEP #$20

        LDA $00
        STA $0200|!Base2,y     ;   x pos
        LDA $02
        STA $0201|!Base2,y     ;   y pos
        LDA #!props
        STA $0203|!Base2,y     ;   props

        LDA !animationframe,x
        TAX
        LDA .FlagFrames,x
        LDX !ow_sprite_index
        STA $0202|!Base2,y

;size table write
        REP #$20
        TYA
        LSR #2
        TAY
        SEP #$20
        LDA #$00        ;   8x8
        STA $0420|!Base2,y

        REP #$20
        SEP #$10
.offscreen
        RTS

.FlagFrames
        db $AE,$AF,$BE

