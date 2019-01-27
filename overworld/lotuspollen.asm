;pollen that rises and then falls down slowly, spawned by the lotus

!risetime = $0030
;how long to rise before falling

!slowdown = $0004
;how fast to slow down when it hits peak

!maxfall = $FFC8
;how fast the pollen fall at their fastest

!shadowtile = $CC
;tile for the pollen shadow

!risetimer = !ow_sprite_timer_1
;when this hits 0 the sprite starts falling

!props = $32
;yxPPccCt of the pollen

!shadowprops = $36

!behaviour = !ow_sprite_misc_2
;behaviour while falling
;$00 = accelerating to 0
;$01 = moving back and forth

!priority = !ow_sprite_misc_3
;if set to 01, use the priority get draw info


init:
        LDA #!risetime
        STA !risetimer,x

;give sprite priority if it moves upwards
        LDA !ow_sprite_speed_y,x
        BEQ .CheckIfRight
        BPL .Nothing
.IncPriority
        INC !priority,x
.Nothing
        RTL
.CheckIfRight
        LDA !ow_sprite_speed_x,x
        BMI .Nothing
        BRA .IncPriority

main:
;animate pollen and store to $0A for later use
        LDA $14
        AND #$000C
        BNE .PollenFrame2

        LDX #$00
        BRA .GoLoop

.PollenFrame2
        LDX #$01

.GoLoop
        LDA .PollenTiles,x
        LDX !ow_sprite_index
        STA $0A

;display graphic
        JSR GFX

;fall when the timer is up
        LDA !risetimer,x
        BNE .NoFall

;accelerate x -> 0
        LDA !ow_sprite_speed_x,x
        BEQ .DoneX                      ;if x speed is already 0, skip all this
        BMI .NegativeX
        SEC
        SBC.w #!slowdown                ;slow down x speed
        BPL .NoSetX0                    ;if it's still positive, don't bother setting it to 0
        BRA .SetX0
.NegativeX
        CLC
        ADC.w #!slowdown                ;slow down x speed
        BMI .NoSetX0                    ;if it's still negative, don't bother setting it to 0
.SetX0
        LDA #$0000                      ;otherwise set it to 0000 so it doesn't keep flipping around
.NoSetX0
        STA !ow_sprite_speed_x,x        ;store the new x speed

.DoneX
;accelerate y -> 0
        LDA !ow_sprite_speed_y,x
        BEQ .DoneY                      ;if x speed is already 0, skip all this
        BMI .NegativeY
        SEC
        SBC.w #!slowdown                ;slow down y speed
        BPL .NoSetY0                    ;if it's still positive, don't bother setting it to 0
        BRA .SetY0
.NegativeY
        CLC
        ADC.w #!slowdown                ;slow down y speed
        BMI .NoSetY0                    ;if it's still negative, don't bother setting it to 0
.SetY0
        LDA #$0000                      ;otherwise set it to 0000 so it doesn't keep flipping around
.NoSetY0
        STA !ow_sprite_speed_y,x        ;store the new y speed

.DoneY
        LDA !ow_sprite_speed_x,x
        ORA !ow_sprite_speed_y,x
        BNE .Gravity

;if it's at a standstill
        LDA $14
        BIT #$0007                      ;every 8 frames, shift by 1 pixel
        BNE .Gravity
        AND #$0010
        BNE .GoLeft
.GoRight
        INC !ow_sprite_x_pos,x
        BRA .Gravity
.GoLeft
        DEC !ow_sprite_x_pos,x

.Gravity
;accelerate z -> the ground
        LDA !ow_sprite_speed_z,x
        SEC
        SBC #$0008
        CMP #!maxfall
        BCS .StoreZ
        LDA #!maxfall
.StoreZ
        STA !ow_sprite_speed_z,x

.NoFall
;update position and kill sprite if it hits the floor
        JSL update_x_pos
        JSL update_y_pos
        JSL update_z_pos

        LDA !ow_sprite_z_pos,x
        BEQ .KillPollen
        BMI .KillPollen
        RTL

.KillPollen
        STZ !ow_sprite_num,x
        JML disappear_in_smoke

.PollenTiles
        db $F2,$E2

GFX:
        LDA !priority,x
        BEQ .normalinfo
        LDA #$0001
        JSL get_draw_info_priority
        BRA .doneinfo
.normalinfo
        LDA #$0001
        JSL get_draw_info
.doneinfo
        BCS .offscreen
        LDA #$0000
        SEP #$20

;SHADOW TILE
        LDA $00
        STA $0200|!addr,y
        LDA $02
        CLC
        ADC !ow_sprite_z_pos,x
        DEC
        STA $0201|!addr,y
        LDA #!shadowtile
        STA $0202|!addr,y
        LDA #!shadowprops
        STA $0203|!addr,y

        PHY
        REP #$20
        TYA
        LSR #2
        TAY
        LDA #$0000              ;   8x8
        STA $041F|!addr,y
        PLY
        SEP #$20

        DEY #4

;POLLEN TILE
        LDA $00
        STA $0200|!addr,y
        LDA $02
        STA $0201|!addr,y
        LDA $0A
        STA $0202|!addr,y
        LDA #!props
        STA $0203|!addr,y

        REP #$20
        SEP #$10
.offscreen
        RTS

