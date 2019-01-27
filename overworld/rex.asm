;rex that walks back and forth a little
;spawns squished if Mario enters the overworld from a specific level tile

!props = $12
;yxpPccCt of the flag

!levelX = $002F*$8
!levelY = $000D*$8
;coordinates of the level that triggers squishiness (bottom right tile)

!animationtimer = !ow_sprite_timer_1
;timer used for the animation
!animationframe = !ow_sprite_misc_1
;which frame to display right now

!frames = $0002
;how many animations frames there are
!frametime = $000C
;how many smw frames each sprite frame should show
!frametimesquish = $0008
;how many smw frames each sprite frame should show when it's squished (this is faster)

!flip = !ow_sprite_misc_2
;x flip, ORAd into the props so store 40 to flip

!squished = !ow_sprite_misc_3
;whether or not the rex is squished

!direction = !ow_sprite_misc_4
;which direction rex is supposed to be walking right now
!fliptimer = !ow_sprite_timer_2
;when this reaches zero rex turns around

!spawnx = !ow_sprite_misc_5
;where the sprite spawned

!walklength = $0016
;how far to walk to the right

init:
;check if mario is on the level tile
        LDY $0DD6|!addr
        LDA $1F17|!addr,y       ;   mario x position
        CMP.w #!levelX
        BNE .NoSquish
        LDA $1F19|!addr,y       ;   mario y position
        CMP.w #!levelY
        BNE .NoSquish
        INC !squished,x

.NoSquish
;store spawn position
        LDA !ow_sprite_x_pos,x
        STA !spawnx,x
        LDA !ow_sprite_y_pos,x
        CLC
        ADC #$0005
        STA !ow_sprite_y_pos,x
        RTL

        !XNormal =   $0040
        !XSquished = !XNormal/2+!XNormal

        !YNormal =   $0010
        !YSquished = !YNormal/2+!YNormal

XSpeeds:
        dw !XNormal^$FFFF+1,!XNormal
        dw !XSquished^$FFFF+1,!XSquished
;normal, squished
YSpeeds:
        dw !YNormal^$FFFF,!YNormal
        dw !YSquished^$FFFF,!YSquished
;normal, squished

main:
;walk around
        LDA !squished,x
        ASL #2
        STA $04

        LDA !direction,x
        ASL
        CLC
        ADC $04           ;add squished *4 + direction *2 cause its words
        TAX
        LDA XSpeeds,x
        PHA
        LDA YSpeeds,x
        LDX !ow_sprite_index
        STA !ow_sprite_speed_y,x
        PLA
        STA !ow_sprite_speed_x,x

        JSL update_x_pos
        JSL update_y_pos


;check if we hit a boundary, and if so, return the other direction
        LDA !direction,x
        BNE .WalkingRight

;check for left boundary
.WalkingLeft
        LDA !spawnx,x
        CMP !ow_sprite_x_pos,x
        BCC .NotHit

;left boundary hit
        STA !ow_sprite_x_pos,x
        BRA .SwitchDir

.FrameTimes
dw !frametime,!frametimesquish

;check for right boundary
.WalkingRight
        LDA !spawnx,x
        CLC
        ADC #!walklength
        CMP !ow_sprite_x_pos,x
        BCS .NotHit

;right boundary hit
        STA !ow_sprite_x_pos,x

.SwitchDir
        LDA !direction,x
        EOR #$0001
        STA !direction,x

        STZ !ow_sprite_speed_x_acc
        STZ !ow_sprite_speed_y_acc

.NotHit
;flip the rex if it's walking right
        STZ !flip,x
        LDA !ow_sprite_speed_x,x
        BMI .GoingLeft
        LDA #$0040
        STA !flip,x

.GoingLeft
;timer logic
        LDA !animationtimer,x
        BNE GFX

        LDA !squished,x
        ASL
        TAX
        LDA .FrameTimes,x
        LDX !ow_sprite_index
        STA !animationtimer,x

        LDA !animationframe,x
        INC
        STA !animationframe,x
        CMP.w #!frames
        BCC GFX
        STZ !animationframe,x

GFX:
        LDA #$0000
        JSL get_draw_info
        BCS .offscreen
        LDA #$0000
        SEP #$20

        LDA $00
        STA $0200|!addr,y       ;   x pos
        LDA $02
        STA $0201|!addr,y       ;   y pos
        LDA #!props
        ORA !flip,x
        STA $0203|!addr,y       ;   props

        LDA !squished,x
        ASL
        CLC
        ADC !animationframe,x
        TAX
        LDA .Frames,x
        LDX !ow_sprite_index
        STA $0202|!addr,y

;size table write
        REP #$20
        TYA
        LSR #2
        TAY
        SEP #$20
        LDA #$02                ;   16x16
        STA $0420|!addr,y

        REP #$20
        SEP #$10
.offscreen
        RTL

.Frames
        db $8C,$8E
        db $E0,$A4

