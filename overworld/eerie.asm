;eerie that spawns on the right side, moves over the map in wavy motion and then waits to do it again
;does not need a generator, it automatically loops by placing one of these
;timer and y position randomized (within boundaries)


!XSpeed = $00B0^$FFFF+1

!props = $32
;yxPPccCt of the flag

!mintime = $0040
;how long to wait AT LEAST
!randtime = $00110
;how many frames to leave up to fortuna the goddess of yummy big black dicks and luck

!randY = $0068
;the random aspect of the y position shuffle

!waittimer = !ow_sprite_timer_2
;how long to wait until it respawns
;used as a state machine of sorts, so don't use for anything else

!wavetimer = !ow_sprite_timer_3
;timer that counts down from FF and resets, used for the waves

!animationtimer = !ow_sprite_timer_1
;timer used for the animation
!animationframe = !ow_sprite_misc_1
;which frame to display right now

!frames = $0002
;how many animations frames there are
!frametime = $0008
;how many smw frames each sprite frame should show

; ----------------------------------

; Circle macros

macro cos()
        PHX
        REP #$11
        ADC #$0080
        BIT #$0100
        PHP
        AND #$00FF
        ASL
        TAX
        LDA $07F7DB,x
        PLP
        SEP #$10
        BEQ ?l1
        EOR #$FFFF
        INC
?l1:    PLX
endmacro

macro sin()
       PHX
       REP #$10
       BIT #$0100
       PHP
       AND #$00FF
       ASL
       TAX
       LDA $07F7DB,x
       PLP
       SEP #$10
       BEQ ?l1
       EOR #$FFFF
       INC
?l1:   PLX
endmacro


init:
        LDA #$00FF
        JSL get_rand_range
        STA !wavetimer,x

;init waittimer
        LDA #!randtime
        JSL get_rand_range
        CLC
        ADC #!mintime
        STA !waittimer,x

;move sprite offscreen
        LDA #$00E0
        STA !ow_sprite_x_pos,x

;store x speed (never changes lol)
        LDA #!XSpeed
        STA !ow_sprite_speed_x,x

;offset eerie animation timer by a bit depending on index
        TXA
        AND #$0001
        ASL #2
        STA !animationtimer,x
        RTL

main:
;warp eerie to the right just before timer ends
        LDA !waittimer,x
        DEC
        BNE .waiting

;move eerie to the right and randomize its y position a tad
        LDA #$00E0
        STA !ow_sprite_x_pos,x

        LDA #!randY
        JSL get_rand_range
        CLC
        ADC #$00B0
        STA !ow_sprite_y_pos,x

;if timer is up, check if eerie hit the left edge yet and if so reset timer
.waiting
        LDA !waittimer,x
        BNE .NoX

        LDA !ow_sprite_x_pos,x
        BPL .NoReset
        CMP #$FFF0
        BCS .NoReset

;if eerie on left edge, reset
        LDA #!randtime
        JSL get_rand_range
        CLC
        ADC #!mintime
        STA !waittimer,x
        BRA .NoX

;update eerie positions and do the wavie
.NoReset
        LDA !wavetimer,x
        ASL             ;double it
        %sin()          ;sine
        CMP #$0000
        BPL .Positive
        LSR #2
        ORA #$F000
        BRA .DoneLSR
.Positive
        LSR #2
.DoneLSR
        STA !ow_sprite_speed_y,x

        JSL update_x_pos
        JSL update_y_pos


;timer logic
.NoX
        LDA !animationtimer,x
        BNE .NoTimerSet

        LDA.w #!frametime
        STA !animationtimer,x

        LDA !animationframe,x
        INC
        STA !animationframe,x
        CMP.w #!frames
        BCC .NoTimerSet
        STZ !animationframe,x

.NoTimerSet
        JSR GFX

;keep resetting wavetimer
        DEC !wavetimer,x
        LDA !wavetimer,x
        BMI .WaveReset
        BNE .NoWaveReset

.WaveReset
        LDA #$0100
        STA !wavetimer,x

.NoWaveReset
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
        STA $0203|!addr,y       ;   props

        LDA !animationframe,x
        TAX
        LDA .EerieFrames,x
        LDX !ow_sprite_index
        STA $0202|!addr,y

;size table write
        REP #$20
        TYA
        LSR
        LSR
        TAY
        SEP #$20
        LDA #$02      ;16x16
        STA $0420|!addr,y

        REP #$20
        SEP #$10
.offscreen
        RTS

.EerieFrames
        db $A4,$A6

