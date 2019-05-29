;spotlight thats basically just a static animation
;extra byte:
;xxxS POCF
;S = whether or not there's a spotlight tile
;P = priority
;O = setting this bit moves the sprite 4 pixels to the left on init
;C = palette to use, E or F
;F = flips it around

!animationtimer = !ow_sprite_timer_1
;timer used for the animation
!animationframe = !ow_sprite_misc_1
;which frame to display right now

!frames = $0006
;how many animations frames there are
!frametime = $000A
;how many smw frames each sprite frame should show

!props = $1C
;yxpPCCct of the light, without the third c bit and the x flip
!spotprops = $36
;yxPPcCCt of the actual spoitlight, x flip left up to code

!XOff = $04
!YOff = $05+$08

print "INIT ",pc
        LDA !ow_sprite_extra_bits,x
        AND #$0004
        BEQ .NoOffset

        LDA !ow_sprite_x_pos,x
        CLC
        ADC #$0004
        STA !ow_sprite_x_pos,x
.NoOffset
offscreen:
        RTL

print "MAIN ",pc
;timer logic
        LDA !animationtimer,x
        BNE GFX

        LDA.w #!frametime
        STA !animationtimer,x

        LDA !animationframe,x
        INC
        STA !animationframe,x
        CMP.w #!frames
        BCC GFX
        STZ !animationframe,x

GFX:
;decide whether to draw one or two tiles
        LDA !ow_sprite_extra_bits,x
        AND #$0010
        BEQ .OneTile
        LDA #$0001
        BRA .Done
.OneTile
        LDA #$0000
.Done
        %OverworldGetDrawInfo()
        BCS offscreen
        LDA #$0000
        SEP #$20

;load flip from extra byte
        LDA !ow_sprite_extra_bits,x
        LSR
        STZ $04
        BCC .DoneFlip
        LDA #$40
        STA $04
.DoneFlip

;SPOTLIGHT TILE
        LDA !ow_sprite_extra_bits,x
        AND #$10
        BEQ .NoSpot

        LDA $02
        CLC
        ADC #!YOff
        STA $0201|!Base2,y               ;   y pos

;calculate x offset based on flip
        LDA $04
        BEQ .NoFlipX
        LDA.b #-!XOff
        BRA .DoneFlipX
.NoFlipX
        LDA.b #!XOff+$08

.DoneFlipX
        CLC
        ADC $00
        STA $0200|!Base2,y               ;   x pos

;props, also based on flip
        LDA #!spotprops
        CLC
        ADC $04
        STA $0203|!Base2,y               ;   props

;animation frame
        LDA !animationframe,x
        TAX
        LDA .SpotFrames,x
        LDX !ow_sprite_index
        STA $0202|!Base2,y               ;   tile

;size table
        PHY
        REP #$20
        TYA
        LSR #2
        TAY
        SEP #$20
        LDA #$00                        ;   8x8
        STA $0420|!Base2,y
        PLY

        DEY #4

.NoSpot
;ACTUAL LIGHT BEAM TILES
        LDA $00
        STA $0200|!Base2,y               ;   x pos
        LDA $02
        STA $0201|!Base2,y               ;   y pos

;load frame based on animationtimer
        LDA !animationframe,x
        TAX
        LDA .LightFrames,x
        LDX !ow_sprite_index
        STA $0202|!Base2,y

;get extra priority bit
        LDA !ow_sprite_extra_bits,x
        AND #$08
        ASL #2
        STA $05

;add together extra byte flip, extra byte palette bit and the props
        LDA !ow_sprite_extra_bits,x
        AND #$02
        CLC
        ADC #!props
        CLC
        ADC $04
        CLC
        ADC $05
        STA $0203|!Base2,y

;size table write
        PHY
        REP #$20
        TYA
        LSR #2
        TAY
        SEP #$20
        LDA #$02                        ;   16x16
        STA $0420|!Base2,y
        PLY

        REP #$20
        SEP #$10
        RTL

.LightFrames
        db $E8,$EA,$EC,$EE,$EC,$EA

.SpotFrames
        db $D8,$D9,$C8,$C9,$C8,$D9

