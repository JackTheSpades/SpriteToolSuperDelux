;crow sprite that just follows an animation loop as set by the animationframes and animationframe tables
;set extra byte to $8x to flip the sprite around
;add any other value to push the animation forward by that many frames
;(eg put $89 to make the sprite x flipped and start its animation 9 frames in)

!props = $12
;yxpPccCt of the crow



!animationtimer = !ow_sprite_timer_1
;timer used for the animation
!animationframe = !ow_sprite_misc_1
;which frame in the animation we're at

!frame = !ow_sprite_misc_2
;the tile to display right now
!flip = !ow_sprite_misc_3
;whether or not to x flip the crow
;set with the last bit of the extra byte
;(eg if it's $8x instead of $0x)


print "INIT ",pc
;move right a bit
        LDA !ow_sprite_x_pos,x
        CLC
        ADC #$0004
        STA !ow_sprite_x_pos,x

;set flip if desired
        LDA !ow_sprite_extra_bits,x
        AND #$0080
        BEQ .NoFlip

        LDA #$0040
        STA !flip,x

.NoFlip
        LDA !ow_sprite_extra_bits,x
        AND #$004F
        STA !animationframe,x
        RTL

!wing           = $00E8
!wingblink      = $00EE
!peck1          = $00EA
!peck2          = $00EC
!blink          = $00CE
!caw            = $00AE
!peek           = $00AC
!idle           = $00C8

AnimationFrames:
        dw !idle,!peek,!idle,!blink,!idle,!blink,!idle,!blink
        dw !idle,!peek,!idle,!wing,!peck1,!peck2,!peck1,!peck2
        dw !peck1,!peck2,!peck1,!peck2,!peck1,!wing,!wingblink,!wing
        dw !peck1,!peck2,!peck1,!peck2,!peck1,!wing,!idle,!caw
        dw !idle,!caw

AnimationSpeeds:
        dw $0090,$0078,$0018,$0006,$0004,$0006,$00A0,$0008
        dw $0040,$0038,$0090,$0008,$000A,$0004,$0008,$0004
        dw $0028,$0004,$0004,$0004,$0030,$0020,$0006,$0010
        dw $0014,$0008,$0004,$0008,$0004,$001B,$0038,$000B
        dw $0010,$0014
        dw $FFFF


print "MAIN ",pc
main:
;crow animation, edited from the lotus
        LDA !animationtimer,x
        BNE .NoNewFrame

;load the current frame's tile and length and store it to the timer
        LDA !animationframe,x
        ASL
        TAX
        LDA AnimationFrames,x
        LDX !ow_sprite_index
        STA !frame,x

        INC !animationframe,x

        LDA AnimationSpeeds,x
        CMP #$FFFF
        BNE .NoNewFrame

;when FFFF is reached set timer and frame to 0
        STZ !animationtimer,x
        STZ !animationframe,x
        BRA main

.NoNewFrame
        STA !animationtimer,x

GFX:
        LDA #$0000
        %OverworldGetDrawInfo()
        BCS .off_screen

        LDA #$0000
        SEP #$20

;CROW TILE
        LDA $00
        STA $0200|!Base2,y       ;   x pos
        LDA $02
        STA $0201|!Base2,y       ;   y pos
        LDA #!props
        ORA !flip,x
        STA $0203|!Base2,y       ;   props

        LDA !frame,x
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
.off_screen
        RTL
