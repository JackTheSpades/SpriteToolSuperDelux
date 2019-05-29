;monty mole hill that shimmies and then fucking explodes when mario walks over a certain spot, like the cheep cheep in vanilla
;edit the TriggerX and TriggerY tables to change the position they jump out at. index to the table is the extra byte

!smoke_id = $15

!showmole = !ow_sprite_misc_1
;whether or not the mole tile displays (only does if the mole is above ground basically)
;can be used to determine if the jumping is going on

!hillflip = !ow_sprite_misc_2
;direction the hill faces, used for the shimmie animation
;set to 00 or 40, saves some math in the graphics routine

!shimmietimer = !ow_sprite_timer_1
;hill flips while it ticks down

!waittimer = !ow_sprite_timer_2
;time till the mole jumps out

!waittime = $0030
;how long to shimmie before it jumps

!landshimmie = $0010
;how long to shimmie when the mole lands and digs back in

!jumppower = $0170
;how high the mole jumps

!gravity = $000A

!moletile = $68

!hilltile = $66

!props = $22
;yxppccct of mole and hill
;y and x flip added with code when needed

print "MAIN ",pc
;if timer is ticking, AND #$40 of it and store to flip to make the hill flip
        LDA !shimmietimer,x
        ASL #3
        AND #$0040
        STA !hillflip,x

        JSR GFX

;when the mole hits the floor with downward speed, 0 out the speed and position and stop displaying the tile
        LDA !ow_sprite_speed_z,x
        BPL .DisplayMole

        LDA !ow_sprite_z_pos,x
        BPL .NoSet00
        BRA .NoDisplayMole
.NoSet00
        BNE .DisplayMole

.NoDisplayMole
        STZ !ow_sprite_z_pos,x
        STZ !ow_sprite_speed_z,x
        STZ !showmole,x
;make mole shimmie a bit
        LDA #!landshimmie
        STA !shimmietimer,x

.DisplayMole
;if mole is during jump, just do gravity and ignore all the setup
        LDA !showmole,x
        BEQ +
        JMP init_Gravity
+

;if the flipping timer is about to be up, cause the mole to jump
;if there's no timer, check for the trigger
        LDA !waittimer,x
        BEQ init_CheckForTrigger
        DEC
        BEQ init_Jump
print "INIT ",pc
init:
        RTL

;Mario Position at which the Moles will jump out
;Wich position set is used depends on the extra byte
.TriggerX
        dw $01B6,$01A0
.TriggerY
        dw $0139,$0128


.CheckForTrigger
;prepare mario positions to compare them to the mole triggers
        LDY $0DD6|!Base2
        LDA $1F17|!Base2,y       ;   mario x position
        STA $00
        LDA $1F19|!Base2,y       ;   mario y position
        STA $02

;compare trigger positions to mario positions, if not the same dont jump
        LDA !ow_sprite_extra_bits,x
        ASL
        TAX
        LDA .TriggerX,x
        CMP $00
        BNE .DontJump
        LDA .TriggerY,x
        CMP $02
        BNE .DontJump
        LDX !ow_sprite_index
        LDA.w #!waittime
        STA !shimmietimer,x
        STA !waittimer,x
        RTL

.DontJump
        LDX !ow_sprite_index
        RTL


.Jump
        LDA #$0001
        STA !showmole,x
        LDA #!jumppower
        STA !ow_sprite_speed_z,x

;sfx
        %OverworldOffScreen()
        BCS .nosound
        SEP #$20
        LDA #$07
        STA $1DFC|!Base2
        REP #$20

  .nosound
;spawn 2 rock particles going diagonal and up
        LDX #$01
.SplashLoop
        STX $08

        LDX !ow_sprite_index
        LDA.w #!smoke_id
        STA $00
        LDA !ow_sprite_x_pos,x
        CLC
        ADC #$0004
        STA $02
        LDA !ow_sprite_y_pos,x
        CLC
        ADC #$0005
        STA $04
        STZ $06
        STZ $08
        %OverworldSpawnSprite()

;make it use the rock animation
        LDA #$0002
        STA !ow_sprite_misc_2,x

;make it move up and sideways
        LDA #$00A0
        STA !ow_sprite_speed_z,x

        PHX
        LDX $08
        TXA
        ASL
        TAX
        LDA .SplashSpeeds,x
        PLX
        STA !ow_sprite_speed_x,x

        LDX $08
        DEX
        BPL .SplashLoop
        LDX !ow_sprite_index
        RTL


!splash = $0040

.SplashSpeeds
        dw !splash,!splash^$FFFF+1

.Gravity
;decrease z speed up to a limit
        SEC
        LDA !ow_sprite_speed_z,x
        BPL .DecSpeed

        CMP #$FD04
        BCC .NoMoreDec
.DecSpeed
        SBC #!gravity
        STA !ow_sprite_speed_z,x

.NoMoreDec
        %OverworldZSpeed()
        RTL

GFX:
        LDA #$0001
        %OverworldGetDrawInfo()
        BCS .offscreen

;set size to 16x16 for both slots
        PHY
        TYA
        LSR #2
        TAY
        LDA #$0202              ;   16x16
        STA $041F|!Base2,y
        SEP #$20
        PLY

;MOLE TILE
        LDA !showmole,x
        BNE .DrawMoleTile
        LDA #$E0
        STA $0201,y
        BRA .HillTile

.DrawMoleTile
        LDA #!moletile
        STA $0202|!Base2,y       ;   mole tile
        LDA #!props
        STA $0203|!Base2,y       ;   props
        LDA $00
        STA $0200|!Base2,y       ;   x pos
        LDA $02
        STA $0201|!Base2,y       ;   y pos

;MOLE HILL TILE
.HillTile
        LDA #!hilltile
        STA $01FE|!Base2,y       ;   mole hill tile, one slot earlier
        LDA !hillflip,x         ;   !hillflip is either 00 or 40 (to flip on x), so just add the props
        CLC
        ADC #!props
        STA $01FF|!Base2,y       ;   props, one slot earlier
        LDA $00
        STA $01FC|!Base2,y       ;   x pos, one slot earlier
        LDA $02
        CLC
        ADC !ow_sprite_z_pos,x
        INC
        STA $01FD|!Base2,y       ;y pos, one slot earlier, adjusted for z position

        REP #$20
        SEP #$10
.offscreen
        RTS

