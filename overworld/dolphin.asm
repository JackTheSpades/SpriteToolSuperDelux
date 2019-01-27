;dolphinio that pops out behind the cherry ghost house

!props = $22
;yxPpccCt of the dolphinoldino

!WaitTime = $0038
;how long to hide behind the house

!WarkTime = $0030
;how long to wark wark wark


!animationframe = !ow_sprite_misc_1
;which frame to display right now

!flip = !ow_sprite_misc_2
;x flip, ORAd into the props so store 40 to flip

!offset = !ow_sprite_misc_3
;diagonal offset for the dolphin tile

!state = !ow_sprite_misc_4
;current dolphin state
;0 = waiting
;1 = moving out
;2 = wark wark wark
;3 = moving in

!timer = !ow_sprite_timer_1
;timer used for states



init:
        DEC !ow_sprite_y_pos,x
        LDA #!WaitTime
        STA !timer,x
NoGFX:
        RTL

main:
        STX $06
        LDA !state,x
        ASL
        TAX
        JSR (DolphStates,x)

;don't show the tile if the dolphinerino is hiding
        LDA !offset,x
        BEQ NoGFX
;draw the sprite
        JMP GFX

DolphStates:
        dw Wait,Out,WarkWark,In

Wait:
;hide behind the house till timer is up
        LDX $06
        LDA !timer,x
        BNE .NoOut
        INC !state,x
.NoOut
        RTS

Out:
;move out from behind the house
        LDX $06
        LDA !offset,x
        INC
        CMP #$0009
        BCS .Next
        STA !offset,x
        RTS

.Next
        INC !state,x
        LDA #!WarkTime
        STA !timer,x
        RTS

WarkWark:
;WARK WARK WARK
        LDX $06

;animate
        LDA !timer,x
        BEQ .Next
        LSR #3
        AND #$0001
        STA !animationframe,x
        RTS

  .Next
        INC !state,x
        STZ !animationframe,x
        RTS

In:
;move back into safety wow that was scary huh everyone looked at you dolphin-chan aren't you embarrassed?
        LDX $06
        LDA $14
        AND #$0001
        BNE .NoMove
        LDA !offset,x
        DEC
        BMI .Next
        STA !offset,x
.NoMove
        RTS

.Next
;go back to waiting state
        STZ !state,x
        LDA #!WaitTime
        STA !timer,x

;flip around for next loop
        LDA !flip,x
        EOR #$0040
        STA !flip,x
        RTS

!ghosttile = $C6

GFX:
        LDA #$0001
        JSL get_draw_info
        BCS .offscreen
        LDA #$0000

;size table write
        PHY
        REP #$20
        TYA
        LSR #2
        TAY
        LDA #$0202              ;   16x16
        STA $041F|!addr,y
        PLY
        SEP #$21

        LDA $02
        SBC !offset,x
        STA $0201|!addr,y       ;   y pos
        LDA #!props
        ORA !flip,x
        STA $0203|!addr,y       ;   props
        LDA !animationframe,x
        TAX
        LDA .Frames,x
        LDX !ow_sprite_index
        STA $0202|!addr,y

;flip the offset depending on the current direction
        LDA !flip,x
        BEQ .NotFlipped

.Flipped
        LDA !offset,x
        EOR #$FF
        INC
        BRA .AddScreenPos

.NotFlipped
        LDA !offset,x
.AddScreenPos
        CLC
        ADC $00
        STA $0200|!addr,y       ;   x pos
        DEY #4

;GHOST HOUSE TILE FOR CLIP
        LDA $00
        STA $0200|!addr,y
        LDA $02
        STA $0201|!addr,y
        LDA #!ghosttile
        STA $0202|!addr,y
        LDA #$00
        STA $0203|!addr,y

        REP #$20
        SEP #$10
.offscreen
        RTS

.Frames
        db $AE,$CE
