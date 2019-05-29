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


print "INIT ",pc
;set flip with RNG if it's not zzz or above
        LDA !animation,x
        CMP #$0003
        BCS .NoFlip
        SEP #$20
        JSL $01ACF9|!BankB       ;   RNG generator
        REP #$20
        AND #$0040
        STA !flip,x

  .NoFlip
        JSR GFX
        RTL

print "MAIN ",pc
;timer logic
        LDA !animationtimer,x
        BNE .NoTimerSet

        LDA.w #!frametime
        STA !animationtimer,x

        LDA !animationframe,x
        INC
        CMP.w #!frames
        BCS .Die
        STA !animationframe,x
        CMP.w #!frames
        BCC .NoTimerSet
        STZ !animationframe,x

.NoTimerSet
;draw graphics
        JSR GFX

        LDA !ow_sprite_speed_x,x
        ORA !ow_sprite_speed_y,x
        ORA !ow_sprite_speed_z,x
        BEQ .NoUpdate

        %OverworldXSpeed()
        %OverworldYSpeed()
        %OverworldZSpeed()
.NoUpdate

;make sprite not drop through the floor ever
        LDA !ow_sprite_z_pos,x
        BPL .NoCorrectZ
        STZ !ow_sprite_z_pos,x
        STZ !ow_sprite_speed_z,x
.Die
        STZ !ow_sprite_num,x
.NoCorrectZ
        RTL

GFX:
        LDA #$0000
        %OverworldGetDrawInfoPriority()
        BCS .offscreen
        LDA #$0000
        SEP #$20
        LDA $00
        STA $0200|!Base2,y       ;   x pos
        LDA $02
        STA $0201|!Base2,y       ;   y pos
        LDA #!props
        ORA !flip,x
        STA $06                 ;   temp store props to add animation props later

;check which animation to run
        LDA !animation,x
        TAX
        LDA $06
        ORA .UniqueProps,x
        STA $0203|!Base2,y       ;   props


;reload animation index and do tiles
        LDX !ow_sprite_index
        LDA !animation,x
        ASL #2
        CLC
        ADC !animationframe,x
        TAX
        LDA .SmokeFrames,x
        STA $0202|!Base2,y
        LDX !ow_sprite_index

;size table write
        REP #$20
        TYA
        LSR #2
        TAY
        SEP #$20
        LDA #$00                ;   8x8
        STA $0420|!Base2,y

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

