;volcano lotus that spits 4 pollen diagonally

!PollenZ = $0080
!PollenSpd = !PollenZ-$0020
;pollen speeds

!lotuspollen_id = $06

!props = $36
;yxPPcCCt of the lotus

!animationtimer = !ow_sprite_timer_1
;timer used for the animation
!animationframe = !ow_sprite_misc_1
;which frame to display right now
!animationspeed = !ow_sprite_misc_5
;how often the frame changed in this toss, used cause it's supposed to rotate slower as time goes on


!bulletpattern = !ow_sprite_misc_2
;which table to read the "bullet pattern" from

print "INIT ",pc
        LDA !ow_sprite_y_pos,x
        SEC
        SBC #$0002
        STA !ow_sprite_y_pos,x
        LDA !ow_sprite_x_pos,x
        CLC
        ADC #$0007
        STA !ow_sprite_x_pos,x

        INC !animationspeed,x
        RTL

AnimationSpeeds:
        dw $00B8,$000B,$000B,$000B,$000B,$000B,$000B,$000B,$000B,$0028,$FFFF

print "MAIN ",pc
;lotus animations
        LDA !animationtimer,x
        BNE .NoNewFrame
        LDA !animationspeed,x
        ASL
        TAX
        LDA AnimationSpeeds,x
        LDX !ow_sprite_index
        STA !animationtimer,x
        INC !animationspeed,x
        INC
        BNE .NoNewFrame
        JSR .ShootFire
.NoNewFrame
        LDA !animationspeed,x
        AND #$0001
        STA !animationframe,x
        JSR GFX
        RTL

.PollenX
        dw $0000,$0000,!PollenSpd/3+!PollenSpd,!PollenSpd/3+!PollenSpd^$FFFF+$1
        dw !PollenSpd^$FFFF+$1,!PollenSpd^$FFFF+$1,!PollenSpd,!PollenSpd

.PollenY
        dw !PollenSpd/3+!PollenSpd,!PollenSpd/3+!PollenSpd^$FFFF+$1,$0000,$0000
        dw !PollenSpd^$FFFF+$1,!PollenSpd,!PollenSpd,!PollenSpd^$FFFF+$1

.ShootFire
        STZ !animationspeed,x
        STZ !animationtimer,x
        STZ !animationframe,x

        LDA !bulletpattern,x
        EOR #$0001
        STA !bulletpattern,x

;pollen spit code here
        LDX #$03
.SpitLoop
        wdm
        PHX
        LDX !ow_sprite_index

;move lotus positions to the pollen
        LDA.w #!lotuspollen_id
        STA $00
        LDA !ow_sprite_x_pos,x
        CLC
        ADC #$0004
        STA $02
        LDA !ow_sprite_y_pos,x
        CLC
        ADC #$0002
        STA $04
        LDA !ow_sprite_z_pos,x
        CLC
        ADC #$0006
        STA $06
        STZ $08
        %OverworldSpawnSprite()
        BCC .full
        LDA $01,s
        ASL
        STA $04

;and add the bullet pattern offset
        PHX
        LDX !ow_sprite_index
        LDA !bulletpattern,x
        PLX
        ASL #3     ;*4 and then *2 for dw
        CLC
        ADC $04
        TAY                 ;index
        LDA .PollenX,y
        STA !ow_sprite_speed_x,x
        LDA .PollenY,y
        STA !ow_sprite_speed_y,x
        LDA.w #!PollenZ
        STA !ow_sprite_speed_z,x
.full
        PLX
        DEX
        BPL .SpitLoop
        LDX !ow_sprite_index
        RTS

GFX:
        LDA #$0000
        %OverworldGetDrawInfo()
        BCS .offscreen
        LDA #$0000
        SEP #$20

;LOTUS TILE
        LDA $00
        STA $0200|!Base2,y       ;   x pos
        LDA $02
        STA $0201|!Base2,y       ;   y pos
        LDA #!props
        STA $0203|!Base2,y       ;   props

        LDA !animationframe,x
        TAX
        LDA .LotusTiles,x
        LDX !ow_sprite_index
        STA $0202|!Base2,y

;size table write
        REP #$20
        TYA
        LSR #2
        TAY
        SEP #$20
        LDA #$02                ;   16x16
        STA $0420|!Base2,y

        REP #$20
        SEP #$10
.offscreen
        RTS

.LotusTiles
        db $CE,$E3

