;space world planets, do nothing but wave up and down
;!ow_sprite_extra determines which planet this is, changing the graphics and the wobble

!props = $16
;yxpPcCCt of the planets (both use the same)

!animationtimer = !ow_sprite_timer_1
;timer used for the animation
!animationframe = !ow_sprite_misc_1
;which frame to display right now
!animationdir = !ow_sprite_misc_4
;how much to add to the animation each frame

!frames = $000C
;how many animations frames there are
!frametime = $0006
;how many smw frames each sprite frame should show

!spawny = !ow_sprite_misc_2
;spawn y position to reapply the offset each frame

!currentoffset = !ow_sprite_misc_3
;how much the y position is offset this frame
;not used for anything by the sprite, might be useful to you though lui


print "INIT ",pc
;preserve y position (-0003 so the planet y offsets center it)
;(this doesn't waste processing cause we'd have to -0002 anyway to center it)
        LDA !ow_sprite_y_pos,x
        SEC
        SBC #$0005
        STA !spawny,x
        STA !ow_sprite_y_pos,x

;set initial position
        SEP #$20
        JSL $01ACF9|!BankB       ;   RNG generator
        REP #$20
        AND #$000F
        CMP #$000F
        BNE .Okay
        DEC #2
.Okay
        STA !animationframe,x

;set initial direction (0001 or FFFF)
        SEP #$20
        JSL $01ACF9|!BankB       ;   RNG generator
        REP #$20
        AND #$0001
        BNE .Not0
        DEC #2
.Not0
        STA !animationdir,x
        RTL

print "MAIN ",pc
;reset y position before applying offset later
        LDA !spawny,x
        STA !ow_sprite_y_pos,x

;timer logic
        LDA !animationtimer,x
        BNE .NoTimerSet
        LDA.w #!frametime
        STA !animationtimer,x

        LDA !animationframe,x
        CLC
        ADC !animationdir,x
        STA !animationframe,x
        BMI .SetForward
        CMP.w #!frames
        BCC .NoTimerSet

.SetBackward
        LDA #$FFFF
        STA !animationdir,x
        DEC !animationframe,x
        DEC !animationframe,x
        BRA .NoTimerSet

.SetForward
        LDA #$0001
        STA !animationdir,x
        STA !animationframe,x

.NoTimerSet
;apply current y offset to position
        LDA !animationframe,x
        ASL
        TAX
        LDA .YOffs,x
        LDX !ow_sprite_index
        STA !currentoffset,x
        CLC
        ADC !ow_sprite_y_pos,x
        STA !ow_sprite_y_pos,x

;before calling gfx, check and save which planet this is
        LDA !ow_sprite_extra_bits,x
        STA $0A

        LDA #$0003
        %OverworldGetDrawInfo()
        BCS .offscreen
        LDA #$0000
        SEP #$20

        LDX #$0003
.PlanetLoop
        PHX

;PLANET TILES
        LDA $00
        CLC
        ADC .XOff,x
        DEC                     ;   move one left to center graphics
        STA $0200|!Base2,y       ;   x pos
        LDA $02
        CLC
        ADC .YOff,x
        STA $0201|!Base2,y       ;   y pos
        LDA #!props
        STA $0203|!Base2,y       ;   props

        STX $04
        LDA $0A
        ASL #2                  ;   planet index * 4 to get the tiles 4 later
        CLC
        ADC $04                 ;   add current tile index to get the right tile
        PHX
        TAX
        LDA .Tiles,x
        PLX
        STA $0202|!Base2,y       ;   tile

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
        BPL .PlanetLoop

        LDX !ow_sprite_index

        REP #$20
        SEP #$10
.offscreen
        RTL

.XOff
        db $00,$10
        db $00,$10

.YOff
        db $00,$00
        db $10,$10

.Tiles
;templanet
        db $80,$82
        db $84,$86
;turniptune
        db $88,$8A
        db $8C,$8E

.YOffs
        dw $0000,$0000,$0001,$0001,$0002,$0003
        dw $0004,$0005,$0006,$0006,$0007,$0007

