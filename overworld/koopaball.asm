;2 koopas playing with a volleyball in the pool, throwing it to each other

!props = $12
;yxppccct of koopas

!ballprops = $22
;yxppccct of the ball

!shadowtile = $CB
;tile used for the shadow

!shadowprops = $14
;yxpPcCct of the shadow

!spawnX = !ow_sprite_misc_1
!spawnY = !ow_sprite_misc_2
;original x and y positions of the sprite, used to keep the koopas in place

!ballframe = !ow_sprite_misc_3
;animation frame for the beach ball right now
;0 or 1

!direction = !ow_sprite_misc_4
;which direction the ball bounces in next
;0 or 1

!animationspeed = !ow_sprite_misc_5
;how often the frame changed in this toss, used cause it's supposed to rotate slower as time goes on

!hoptimer = !ow_sprite_timer_1
;timer used to prop up a koopa to show a little hop

!animationtimer = !ow_sprite_timer_2
;how long to wait until the next frame is shown

;dont change, this is precise
!jumppower = $00EA
;how high the volleyball flies

!gravity = $0007
;how fast the volleyball sinks

!ballxspd = $0068
;how fast the ball moves horizontally on each toss

!ballyspd = $0048
;how fast the ball moves vertically on each toss

!yoff = $08
!xoff = $18
;off screen despawn protection

init:
        LDA !ow_sprite_x_pos,x
        SEC
        SBC #$0002
        STA !ow_sprite_x_pos,x
        STA !spawnX,x

        LDA !ow_sprite_y_pos,x
        CLC
        ADC #$0004
        STA !ow_sprite_y_pos,x
        STA !spawnY,x
        RTL

AnimationSpeeds:
        dw $0001,$0002,$0004,$0007,$000A,$00FF

main:
        LDA !ow_sprite_x_pos,x
        PHA
        SEC
        SBC.w #!xoff
        STA !ow_sprite_x_pos,x
        LDA !ow_sprite_y_pos,x
        PHA
        SEC
        SBC.w #!yoff
        STA !ow_sprite_y_pos,x

        JSR GFX

        PLA
        STA !ow_sprite_y_pos,x
        PLA
        STA !ow_sprite_x_pos,x

;ball animations
        LDA !animationtimer,x
        BNE .NoNewFrame

        LDA !ballframe,x
        EOR #$0001
        STA !ballframe,x

        LDA !animationspeed,x
        ASL
        TAX
        LDA AnimationSpeeds,x
        LDX !ow_sprite_index
        STA !animationtimer,x
        INC !animationspeed,x

.NoNewFrame

;when the mole (er I mean ball!) hits the floor with downward speed, 0 out the speed and position and bounce it up
        LDA !ow_sprite_speed_z,x
        BPL .MovingUp
        LDA !ow_sprite_z_pos,x
        BPL .NoSet00
        STZ !ow_sprite_z_pos,x
        BRA .Bump
.NoSet00
        BNE .MovingUp

.Bump
;code to bump up the ball again goes here
        LDA #!jumppower
        STA !ow_sprite_speed_z,x

        LDA !direction,x
        ASL
        TAX
        LDA .BallXSpeeds,x
        PHA
        LDA .BallYSpeeds,x
        LDX !ow_sprite_index
        STA !ow_sprite_speed_y,x
        PLA
        STA !ow_sprite_speed_x,x

        LDA !direction,x
        EOR #$0001
        STA !direction,x

;cosmetic stuff
        LDA #$0004
        STA !hoptimer,x

        STZ !animationspeed,x
        STZ !animationtimer,x

.MovingUp
.Gravity
;decrease z speed up to a limit
        LDA !ow_sprite_speed_z,x
        BPL .DecSpeed
        CMP #$FD04
        BCC .NoMoreDec
.DecSpeed
        SBC #!gravity
        STA !ow_sprite_speed_z,x

.NoMoreDec
        JSL update_x_pos
        JSL update_y_pos
        JML update_z_pos

.BallXSpeeds
        dw !ballxspd,-!ballxspd
.BallYSpeeds
        dw !ballyspd,-!ballyspd

GFX:
        LDA #$0002
        JSL get_draw_info
        BCC +
        SEP #$10
        REP #$20
        RTS

+       LDA $05,s
        STA !ow_sprite_x_pos,x
        LDA $03,s
        STA !ow_sprite_y_pos,x

        LDA $00
        ADC.w #!xoff
        STA $00
        LDA $02
        CLC
        ADC.w #!yoff
        STA $02

;size table
        PHY
        TYA
        LSR #2
        TAY
        LDA #$0202              ;   16x16 koopas
        STA $041E|!addr,y
        SEP #$20
        LDA #$00                ;   8x8
        STA $0420|!addr,y
        PLY

;SHADOW TILE
        LDA $00
        STA $0200|!addr,y

        LDA $02
        CLC
        ADC !ow_sprite_z_pos,x
        STA $0201|!addr,y

        LDA #!shadowtile
        STA $0202|!addr,y

        LDA #!shadowprops
        STA $0203|!addr,y

        DEY #4


;KOOPA TILES
!offsetX = $04
!offsetY = $0E

        REP #$20
        LDA !ow_sprite_x_pos,x
        SEC
        SBC !spawnX,x
        STA !offsetX

        LDA !ow_sprite_y_pos,x
        SEC
        SBC !spawnY,x
        STA !offsetY
        SEP #$20

        LDX #$0001
.KoopaLoop
        PHX

;actual drawing code starts here
        LDA #!props
        STA $0203|!addr,y

        LDA .KoopaTiles,x
        STA $0202|!addr,y

        LDA .KoopaXOff,x
        BPL +
        XBA
        LDA #$FF                ;   sign extend
        XBA
+
        REP #$21
        ADC $00
        SEC
        SBC !offsetX
        CMP #$0100
        SEP #$20
        BCS .koopa_offscreen
        STA $0200|!addr,y
        BRA +
.koopa_offscreen
        LDA #$F0
        STA $0201|!addr,y
        BRA .next_koopa

;check if one of the koopas should be bouncing
+       STZ $07
        LDX !ow_sprite_index
        LDA !hoptimer,x
        BEQ .NoBounceHere
        LDA !direction,x
        EOR #$01
        PLX
        PHX
        STX $06
        CMP $06
        BNE .NoBounceHere
        LDA #$01
        STA $07

.NoBounceHere
        PLX
        PHX

;calculate y position for the koopas
        LDA $02
        SEC
        SBC !offsetY            ;   offset to spawn position from the ball
        CLC
        ADC .KoopaYOff,x        ;   add offset for the bottom koopa if applicable
        LDX !ow_sprite_index
        CLC
        ADC !ow_sprite_z_pos,x  ;   keep the koopas in the water
        SEC
        SBC $07                 ;   bounce koopa a little if needed
        STA $0201|!addr,y

.next_koopa
        DEY #4
        PLX
        DEX
        BPL .KoopaLoop

        LDX !ow_sprite_index

        REP #$20
        JSL is_offscreen
        SEP #$20
        BCC .ball_on_screen
; delete shadow
        LDA #$F0
        STA $0201+12|!addr,y
        REP #$20
        SEP #$10
.offscreen
        RTS

.ball_on_screen
;BALL TILE
        REP #$20
        LDA #$0000
        JSL get_draw_info_priority
        BCS .offscreen
        SEP #$21
        LDA $00
        STA $0200,y
        LDA $02
        SBC #$06
        STA $0201|!addr,y
        LDA #!ballprops
        STA $0203|!addr,y
        LDA !ballframe,x
        TAX
        LDA .BallTiles,x
        LDX !ow_sprite_index
        STA $0202|!addr,y

;size table
        PHY
        REP #$20
        TYA
        LSR
        LSR
        TAY
        SEP #$20
        LDA #$00                ;   8x8
        STA $0420|!addr,y
        PLY

        REP #$20
        SEP #$10
        RTS


.BallTiles
        db $CA,$DA
.KoopaTiles
        db $A7,$A9
.KoopaXOff
        db $FC,$18
.KoopaYOff
        db $FE,$11

