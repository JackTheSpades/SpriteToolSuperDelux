;ninji, just jumps up and down in semi random intervals

;yxPPcCct of the ninji and its shadow
!props          = $34
;tile for the pollen shadow
!shadowtile     = $CC

;how fast the pollen fall at their fastest
!maxfall        = $FEC0
;how fast to accelerate falling
!gravity        = $0012
;how high the ninji jumps
!jumppower      = $01E8

;what value to take from the rng for the timer
;multiple of 2 minus 1
!rngAND         = $3F
;how much time the ninji has to wait for every jump baseline
;should be time till land + a bit
!basetime       = $0070

;whether the ninji flips around or not
!flip           = !ow_sprite_misc_2

;timer used for the jump
!jumptimer      = !ow_sprite_timer_1
;which frame to display right now
!animationframe = !ow_sprite_misc_1


print "INIT ",pc
        JSR main_Randomize
        LDA !ow_sprite_x_pos,x
        SEC
        SBC #$0006
        STA !ow_sprite_x_pos,x

print "MAIN ",pc
main:
        JSR GFX

        ;face mario
        LDA !ow_sprite_x_pos,x
        PHA
        CLC
        ADC #$0006
        STA !ow_sprite_x_pos,x

        %OverworldHorzPos()
        LDA #$0000
        TYA
        BEQ .StoreFlip
        ; BNE .DoFlip

        ; LDA #$0000
        ; BRA .StoreFlip

.DoFlip
        LDA #$0040

.StoreFlip
        STA !flip,x

        PLA
        STA !ow_sprite_x_pos,x

.Behave
        ;do behaviour
        LDA.w !jumptimer,x
        BNE .Gravity

        ;jump
        LDA #!jumppower
        STA !ow_sprite_speed_z,x
        LDA #$0001
        STA !animationframe,x

        ;re-set the timer
        JSR .Randomize

.Gravity
        ;don't do gravity if sprite is standing still
        LDA !ow_sprite_speed_z,x
        ORA !ow_sprite_z_pos,x
        BEQ .Done

;accelerate z -> the ground
        LDA !ow_sprite_speed_z,x
        SEC
        SBC #!gravity
        BPL .StoreZ
        CMP #!maxfall
        BCS .StoreZ
        LDA #!maxfall
.StoreZ
        STA.w !ow_sprite_speed_z,x

        ;update z position when it's done
        %OverworldZSpeed()

        ;make the ninji sit still when it lands
        LDA.w !ow_sprite_z_pos,x
        BEQ .HitFloor
        BMI .HitFloor
.Done
        RTL


.HitFloor
        STZ !animationframe,x
        STZ !ow_sprite_speed_z,x
        STZ !ow_sprite_z_pos,x
        RTL


.Randomize
        LDA #$0000
        SEP #$20
        JSL $01ACF9|!BankB       ;RNG generator
        LDA $148D|!Base2         ;load RNG result
        AND #!rngAND
        REP #$21
        ADC #!basetime
        LDX !ow_sprite_index
        STA !jumptimer,x
        RTS

GFX:
        LDA.w !ow_sprite_extra_bits,x
        BEQ .noPriority

        LDA #$0001
        %OverworldGetDrawInfoPriority()
        BRA .Draw

.noPriority
        LDA #$0001
        %OverworldGetDrawInfoPriority()
.Draw
        BCS OffScreen

        LDA #$0000
        SEP #$21

        ;SHADOW TILE
        LDA $00
        ADC #$03
        STA $0200|!Base2,y
        LDA $02
        CLC
        ADC !ow_sprite_z_pos,x
        CLC
        ADC #$09
        STA $0201|!Base2,y
        LDA #!shadowtile
        STA $0202|!Base2,y

        LDA #!props
        STA $0203|!Base2,y

        PHY
        REP #$20
        TYA
        LSR #2
        TAY
        SEP #$20
        LDA #$00                ;8x8
        STA $0420|!Base2,y
        PLY

        DEY #4

        ;NINJI TILE
        LDA $00
        STA $0200|!Base2,y       ;x pos
        LDA $02
        STA $0201|!Base2,y       ;y pos

        LDA !animationframe,x
        TAX
        LDA .NinjiFrames,x
        LDX !ow_sprite_index
        STA $0202|!Base2,y

        LDA !ow_sprite_extra_bits,x
        TAX
        LDA .props,x
        LDX !ow_sprite_index
        ORA !flip,x
        STA $0203|!Base2,y       ;props

        ;size table write
        REP #$20
        TYA
        LSR #2
        TAY
        SEP #$20
        LDA #$02      ;16x16
        STA $0420|!Base2,y

        REP #$20
        SEP #$10
OffScreen:
        RTS

GFX_NinjiFrames:
        db $84,$82

GFX_props:
        db !props,!props+$20

