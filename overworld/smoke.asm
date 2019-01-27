;particle sprite, disappears after a short while
;this sprite is a helper used in a bunch of other sprites, DO NOT DELETE IT
;it doesn't only handle smoke, but also the podoboo's lava particles and the monty moles' rock splashes

!props = $12
;yxpPccCt of the particle

!pooftimer = !ow_sprite_timer_2
;when this hits 0 the sprite ends

!animationtimer = !ow_sprite_timer_1
;timer used for the animation
!animationframe = !ow_sprite_misc_1
;which frame to display right now

!animation = !ow_sprite_misc_2
;which animation to display
;store the corresponding value when spawning for proper effect
;00 = smoke cloud
;01 = lava particle
;02 = rock particle

!flip = !ow_sprite_misc_3
;whether or not to flip the particle on the x axis
;set with RNG during init

!frames = $0004
;how many animations frames there are
!frametime = $0004
;how many smw frames each sprite frame should show


init:
;set flip with RNG if it's not zzz or above
        LDA.w !animation,x
        CMP #$0003
        BCS .NoFlip
        SEP #$20
        JSL $01ACF9|!bank       ;   RNG generator
        REP #$20
        AND #$0040
        STA.w !flip,x

  .NoFlip
        JSR GFX
        RTL

main:
;timer logic
        LDA.w !animationtimer,x
        BNE .NoTimerSet

        LDA.w #!frametime
        STA.w !animationtimer,x

        LDA.w !animationframe,x
        INC
        CMP #!frames
        BCS .Die
        STA.w !animationframe,x
        CMP.w #!frames
        BCC .NoTimerSet
        STZ.w !animationframe,x

.NoTimerSet
;draw graphics
        JSR GFX

        LDA.w !ow_sprite_speed_x,x
        ORA.w !ow_sprite_speed_y,x
        ORA.w !ow_sprite_speed_z,x
        BEQ .NoUpdate

        JSL update_x_pos
        JSL update_y_pos
        JSL update_z_pos
.NoUpdate

;make sprite not drop through the floor ever
        LDA.w !ow_sprite_z_pos,x
        BPL .NoCorrectZ
        STZ.w !ow_sprite_z_pos,x
        STZ.w !ow_sprite_speed_z,x
.Die
        STZ.w !ow_sprite_num,x
.NoCorrectZ
        RTL

GFX:
        LDA #$0000
        JSL get_draw_info_priority
        BCS .offscreen
        LDA #$0000
        SEP #$20
        LDA $00
        STA $0200|!addr,y       ;   x pos
        LDA $02
        STA $0201|!addr,y       ;   y pos
        LDA #!props
        ORA !flip,x
        STA $06                 ;   temp store props to add animation props later

;check which animation to run
        LDA.w !animation,x
        TAX
        LDA $06
        ORA .UniqueProps,x
        STA $0203|!addr,y       ;   props


;reload animation index and do tiles
        LDX.w !ow_sprite_index
        LDA.w !animation,x
        ASL #2
        CLC
        ADC.w !animationframe,x
        TAX
        LDA .SmokeFrames,x
        STA $0202|!addr,y
        LDX.w !ow_sprite_index

;size table write
        REP #$20
        TYA
        LSR #2
        TAY
        SEP #$20
        LDA #$00                ;   8x8
        STA $0420|!addr,y

        REP #$20
        SEP #$10
.offscreen
        RTS

.SmokeFrames
;smoke
        db $C0,$C1,$C2,$C3
;lava particle
        db $AC,$BC,$AD,$BD
;rock particle
        db $C5,$C6,$D5,$D6
;zzz particle
        db $2C,$2D,$3C,$3D
;burp smoke particle (208)
        db $9C,$9D,$9E,$9F


.UniqueProps
        db $00
        db $00
        db $00
        db $00
        db $30

