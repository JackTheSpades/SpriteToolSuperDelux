;the bad looking earth planet from that temple level
;peeks in rarely and then fucks off cause nobody likes it

!props = $26
;yxPpcCCt of the fuck ass piece of planet turd

Tiles:
        db $A4,$A6,$A8,$AA

!mintime = $0480
!maxtime = $0E10
;minimum and maximum wait time for the lazy fucking sack of shit to show its disgusting face

!yspeed = $0010
;how fast to move down

!waittimer = !ow_sprite_timer_1
;how much time the ugly ass motherfucker has left to wait

!animationframe = !ow_sprite_misc_1
;which frame to display right now, will be 0 for most of it until it fucks off

print "INIT ",pc
        LDA #!yspeed
        STA !ow_sprite_speed_y,x

reinit:
;set timer and position back to how it was so it can all start over
        LDA.w #!maxtime-!mintime+1
        %GetRandomRange()
        CLC
        ADC #!mintime
        STA !waittimer,x
        STZ !animationframe,x

        LDA $1C
        CLC
        ADC #$0020
        STA !ow_sprite_y_pos,x
        RTL

KillThisEarth:
        STZ !ow_sprite_num,x
        RTL

print "MAIN ",pc
;do nothing if the timer is ticking
        LDA !waittimer,x
        BNE GFX_offscreen

        LDA $1C
        CLC
        ADC #$002F
        CMP !ow_sprite_y_pos,x
        BMI +
        %OverworldYSpeed()
        BRA GFX

;if timer is done and we're at the goal, display our animation and reinit if it's over
+       LDA $14
        LSR
        BCS GFX

;increase animation frame and if the new value is more than we have, reinit and don't draw any more
        LDA !animationframe,x
        INC
        CMP #$0004
        BCS KillThisEarth
        ; BCS reinit            ;   uncomment this and delete the line above this one to make it reappear
        STA !animationframe,x

GFX:
        LDA #$0000
        %OverworldGetDrawInfo()
        BCS .offscreen
        LDA #$0000
        SEP #$20

        LDA $00
        STA $0200|!Base2,y       ;   x pos
        LDA $02
        STA $0201|!Base2,y       ;   y pos
        LDA #!props
        STA $0203|!Base2,y       ;   props

        LDA !animationframe,x
        TAX
        LDA Tiles,x
        STA $0202|!Base2,y       ;   tile

        ;size table write
        REP #$20
        TYA
        LSR #2
        TAY
        SEP #$20
        LDA #$02                ;   16x16
        STA $0420|!Base2,y

        LDX !ow_sprite_index

        REP #$20
        SEP #$10
.offscreen
        RTL

