;saws that go around the center level
;both in one cause that's easier

!props = $34
;yxPPcCct of the flag

!animationtimer = !ow_sprite_timer_1
;timer used for the animation
!animationframe = !ow_sprite_misc_1
;which frame to display right now

!XOff = !ow_sprite_misc_2
!YOff = !ow_sprite_misc_3
;offsets from the center for circle motion
!XMax = $000B

!frames = $0002
;how many animations frames there are
!frametime = $0006
;how many smw frames each sprite frame should show

; ; ----------------------------------

; ; Circle macros

; macro cos()
        ; PHX
        ; REP #$11
        ; ADC #$0080
        ; BIT #$0100
        ; PHP
        ; AND #$00FF
        ; ASL
        ; TAX
        ; LDA $07F7DB,x
        ; PLP
        ; SEP #$10
        ; BEQ ?l1
        ; EOR #$FFFF
        ; INC
; ?l1:    PLX
; endmacro

; macro sin()
       ; PHX
       ; REP #$10
       ; BIT #$0100
       ; PHP
       ; AND #$00FF
       ; ASL
       ; TAX
       ; LDA $07F7DB,x
       ; PLP
       ; SEP #$10
       ; BEQ ?l1
       ; EOR #$FFFF
       ; INC
; ?l1:   PLX
; endmacro

init:
        LDA #!XMax
        STA !XOff,x
        STZ !YOff,x

;y pos adjust to center on level dot
        LDA !ow_sprite_y_pos,x
        CLC
        ADC #$0002
        STA !ow_sprite_y_pos,x
        RTL


SineTable10toA:
        db $00,$FE,$FC,$FA,$F9,$F8,$F7,$F6
        db $F5,$F6,$F7,$F8,$F9,$FA,$FC,$FE
.middle
        db $00,$02,$04,$06,$07,$08,$09,$0A
        db $0B,$0A,$09,$08,$07,$06,$04,$02

main:
;x pos
        LDA $14                 ;   frame counter
        AND #$00FF
;keep the timer between C0 and 40 for the half circle
        CMP #$00C0
        BCC .NotHigh
        SBC #$0080
        BRA .DoneRange
.NotHigh
        CMP #$0040
        BCS .DoneRange
        ADC #$0080
.DoneRange
        ASL                     ;   double it
        %sin()                  ;   sine
        LSR #5
        CLC
        ADC #$0010              ;   +$10 so we dont have any negative index
        TAX
        SEP #$20
        LDA SineTable10toA,x
        LDX !ow_sprite_index
        STA !XOff,x             ;   8bit store so we don't have to double offset the table
        REP #$20

;y pos
        LDA $14                 ;   frame counter
        AND #$00FF
        ASL                     ;   double it
        %cos()                  ;   sinus
        LSR #5

;this little block is to make the saws stay on their side for priority
        AND #$00FF
        CMP #$0080
        BCC .NoInvertY
        EOR #$FFFF
        INC
.NoInvertY
        STA !YOff,x

;timer logic
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

GFX:
        LDA #$0000
        JSL get_draw_info_priority
        BCS .offscreen

        LDA !XOff,x
        STA $04
        LDA !YOff,x
        STA $06

        LDA #$0000
        SEP #$20

        LDX #$0001
.SawLoop
        PHX

;add x offset (negative or positive depending on index) to position and store
        LDA $04
        EOR .EORtable,x
        CLC
        ADC .INCtable,x
        CLC
        ADC $00
        STA $0200|!addr,y       ;   x pos
;add y offset (negative or positive depending on index) to position and store
        LDA $06
        EOR .EORtable,x
        CLC
        ADC .INCtable,x
        CLC
        ADC $02
        STA $0201|!addr,y       ;   y pos

        LDA #!props
        STA $0203|!addr,y       ;   props

        TXA
        LDX !ow_sprite_index
        EOR !animationframe,x
        TAX
        LDA .SawFrames,x
        LDX !ow_sprite_index
        STA $0202|!addr,y

;size table write
        PHY
        REP #$20
        TYA
        LSR #2
        TAY
        SEP #$20
        LDA #$02                ;   16x16
        STA $0420|!addr,y
        PLY

        ; DEY #4
;second tile should display behind everything, so we set Y directly here
        LDY #$01D0
        PLX
        DEX
        BPL .SawLoop

        LDX !ow_sprite_index
        REP #$20
        SEP #$10
.offscreen
        RTL

.SawFrames
        db $A0,$A2
.EORtable
        db $FF,$00
.INCtable
        db $01,$00

