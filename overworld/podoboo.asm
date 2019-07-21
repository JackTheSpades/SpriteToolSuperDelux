;podoboo that jumps in a very set interval up to as many tiles as set in the extra byte
;leaves flame trail
;extra byte 00-7F = height the podoboo jumps

!smoke_id = $03

!wait = $0080
;time to wait until next hop

!speed = $0118
;speed at which to rise

!slowdown = $000B
;how fast to slow down when it hits peak

!maxfall = !speed^$FFFF+1
;how fast the podoboo falls at its fastest

!animationspeed = $0004
;how fast to animated
;power of 2

!shadowtile = $CC
;tile for the podoboo shadow

!props = $22
;yxPpccCt of the podoboo
!shadowprops = $34
;yxpPcCct of the shadow

!flashtimer = !ow_sprite_timer_1
;timer used for the flashing
;set by rng so all podoboos flash differently

!jumptimer = !ow_sprite_timer_2
;timer used for the jump, set when the podoboo lands (and on init)

!direction = !ow_sprite_misc_1
;which direction the sprite is moving right now
;0 = waiting in lava until !jumptimer is up
;1 = jumping up until peak is reached, generate particles
;2 = falling down until ground is hit

!flip = !ow_sprite_misc_2
;this is ORAd into the props for the podoboo, set to 80 when podoboo falls

!priority = !ow_sprite_misc_3
;if set to 01, use the priority get draw info

!peak = !ow_sprite_misc_4
;how high the podoboo flies, set by the first 7 bits of the extra byte


print "INIT ",pc
        SEP #$20
;set random timer for the flashing
        JSL $01ACF9|!BankB       ;   RNG generator
        AND #$FE
        INC
        LDX !ow_sprite_index
        STA !flashtimer,x

;set random timer for the waiting
        JSL $01ACF9|!BankB       ;   RNG generator
        AND #$3F
        LDX !ow_sprite_index
        STA !jumptimer,x
        REP #$20
        STZ !ow_sprite_z_pos,x

        LDA !ow_sprite_extra_bits,x
        AND #$007F
        STA !peak,x
        RTL

print "MAIN ",pc
;if it shouldn't show, don't and wait for jump timer instead
        LDA !direction,x
        BEQ .Wait

;animate podoboo and store to $0A for later use
        LDA !flashtimer,x
        AND #!animationspeed
        BNE .PodoFrame2

        LDX #$00
        BRA .StoreTile

.PodoFrame2
        LDX #$01

.StoreTile
        LDA .PodoTiles,x
        LDX !ow_sprite_index
        STA $0A

;keep the flashing timer on loop
        LDA !flashtimer,x
        BNE .NoSet

        LDA #$FFFE
        STA !flashtimer,x

.NoSet
;set flip depending on z speed
        LDA !ow_sprite_speed_z,x
        BMI .FlipAround
        STZ !flip,x
        BRA .DoneFlip

.FlipAround
        LDA #$0080
        STA !flip,x
.DoneFlip
;display graphic
        JSR GFX

;actual movement goes here
        LDA !direction,x
        DEC
        BEQ .Rise
        BRA .Gravity

.Wait
        LDA !jumptimer,x
        BNE .DontJump

.Jump
        ;switch to the jumping state
        INC !direction,x
        LDA.w #!speed
        STA !ow_sprite_speed_z,x

;play fire sfx
        SEP #$20
        LDA #$27
        STA $1DFC|!Base2
        REP #$20

.DontJump
        RTL

.Rise
        %OverworldZSpeed()

;check if we've reached the peak set in the extra byte yet and if so, set position to peak for that perfect pizza
        LDA !ow_sprite_z_pos,x
        BMI .NotPeaked
        CMP !peak,x
        BCS .Peaked

.NotPeaked
        LDA $14
        AND #$000F
        BNE .NoSpawnParticle

;spawn particles with downward z speed and some x speed
        LDA.w #!smoke_id
        STA $00
        LDA !ow_sprite_x_pos,x
        STA $02
        LDA !ow_sprite_y_pos,x
        STA $04
        LDA !ow_sprite_z_pos,x
        STA $06
        STZ $08
        %OverworldSpawnSprite()
;make it use the lava animation
        LDA #$0001
        STA !ow_sprite_misc_2,x

;make it fall down
        LDA #$FF50
        STA !ow_sprite_speed_z,x
        LDX !ow_sprite_index
.NoSpawnParticle
        RTL

.Peaked
;set position to the peak position
        LDA !peak,x
        STA !ow_sprite_z_pos,x

;make the podoboo fall
        INC !direction,x
        RTL

.Gravity
;accelerate z -> the ground
        LDA !ow_sprite_speed_z,x
        SEC
        SBC #!slowdown
        BPL .StoreZ
        CMP #!maxfall
        BCS .StoreZ
        LDA #!maxfall
.StoreZ
        STA !ow_sprite_speed_z,x
;while not going down, spawn particles
        BMI .Downwards
        JSL .NotPeaked

.Downwards
;update position and kill sprite if it hits the floor
        %OverworldZSpeed()

        LDA !ow_sprite_z_pos,x
        BPL .NoHide
        CMP #$FFFC
        BCC .HideBoo
.NoHide
        RTL

  .HideBoo
;hide the sprite and make it wait
        STZ !direction,x
        LDA #!wait
        STA !jumptimer,x
        STZ !ow_sprite_z_pos,x
        STZ !ow_sprite_speed_z,x

;spawn 2 lava splooshes going diagonal and up
        LDX #$01
  .SplashLoop
        STX $0A
        LDX !ow_sprite_index
        LDA.w #!smoke_id
        STA $00
        LDA !ow_sprite_x_pos,x
        STA $02
        LDA !ow_sprite_y_pos,x
        STA $04
        LDA #$0000
        STA $06
        STZ $08
        %OverworldSpawnSprite()
;make it use the lava animation
        LDA #$0001
        STA !ow_sprite_misc_2,x

;make it move up and sideways
        LDA #$00A0
        STA !ow_sprite_speed_z,x
        PHX
        LDX $0A
        TXA
        ASL
        TAX
        LDA .SplashSpeeds,x
        PLX
        STA !ow_sprite_speed_x,x

        LDX $0A
        DEX
        BPL .SplashLoop
        LDX !ow_sprite_index
        RTL


!splash = $0040

.SplashSpeeds
        dw !splash,!splash^$FFFF+1
.PodoTiles
        db $C7,$D7


GFX:
;load mario's y position and if it's above the podoboo, priority
        LDY $0DD6|!Base2
        LDA $1F19|!Base2,y
        CMP !ow_sprite_y_pos,x
        BCS .normalinfo

        LDA #$0001
        %OverworldGetDrawInfoPriority()
        BRA .doneinfo

.normalinfo
        LDA #$0001
        %OverworldGetDrawInfo()
.doneinfo
        BCS .offscreen
        LDA #$0000
        SEP #$20

;SHADOW TILE
        LDA $00
        STA $0200,y
        LDA $02
        CLC
        ADC !ow_sprite_z_pos,x
        CLC
        ADC #$02
        STA $0201,y
        LDA #!shadowtile
        STA $0202,y
        LDA #!shadowprops
        STA $0203,y

        PHY
        REP #$20
        TYA
        LSR #2
        TAY
        LDA #$0000      ;8x8
        STA $041F,y
        SEP #$20
        PLY
        DEY #4

;PODOBOO TILE
        LDA $00
        STA $0200,y
        LDA $02
        STA $0201,y
        LDA $0A
        STA $0202,y
        LDA #!props
        ORA !flip,x
        STA $0203,y

        REP #$20
        SEP #$10
.offscreen
        RTS

