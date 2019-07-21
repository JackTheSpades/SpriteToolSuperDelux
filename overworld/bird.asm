;==============================================================
; Bird
; By Erik
;
; Description: This is a bird.
;
; Extra byte: Index to the palette table. The default for
; every value is:
;   * 00 - Yellow
;   * 01 - Blue
;   * 02 - Red
;   * 03 - Green
; Anything else will glitch unless you add more values to the
; table.
;==============================================================

palette:
        db $04,$06,$08,$0A
bird_tilemap:
        db $D2,$D3,$D0,$D1,$1B
bird_x_speed_adds:
        dw $0008,-$0008

;---

print "INIT ",pc
        LDA !ow_sprite_z_pos,x
        SEC
        SBC #$0004
        STA !ow_sprite_misc_1,x
        JSR draw_sprite
        RTL

;---

print "MAIN ",pc
shy_birb:
        JSR draw_sprite
        %OverworldXSpeed()
        %OverworldZSpeed()

        LDA !ow_sprite_timer_1,x
        BEQ +
        LDA #$0004
        STA !ow_sprite_misc_4,x
+       LDA !ow_sprite_speed_z,x
        SEC
        SBC #$0003
        STA !ow_sprite_speed_z,x
        LDA !ow_sprite_misc_3,x
        BEQ moving_around

        STZ !ow_sprite_speed_z,x
        STZ !ow_sprite_speed_x,x
        STZ !ow_sprite_misc_4,x
        LDA !ow_sprite_timer_2,x
        BEQ .no_pecking
        CMP #$0008
        BCS return
        INC !ow_sprite_misc_4,x
        RTL

.no_pecking
        LDA !ow_sprite_misc_5,x
        BEQ start_movement
        DEC !ow_sprite_misc_5,x
        SEP #$20
        JSL $01ACF9|!BankB
        REP #$20
        AND #$001F
        ORA #$000A
        STA !ow_sprite_timer_2,x
        RTL

start_movement:
        STZ !ow_sprite_misc_3,x
        SEP #$20
        JSL $01ACF9|!BankB
        REP #$20
        LSR
        BCS no_flip_dir
        LDA !ow_sprite_misc_2,x
flip_dir:
        EOR #$0001
        STA !ow_sprite_misc_2,x
        LDA #$000A
        STA !ow_sprite_timer_1,x
no_flip_dir:
        SEP #$20
        JSL $01ACF9|!BankB
        REP #$21
        AND #$0003
        ADC #$0002
        STA !ow_sprite_misc_5,x
return:
        RTL

moving_around:
        LDA !ow_sprite_misc_2,x
        ASL
        TAY
        LDA bird_x_speed_adds,y
        STA !ow_sprite_speed_x,x
        STZ !ow_sprite_misc_4,x
        LDA !ow_sprite_speed_z,x
        BPL return
        LDA !ow_sprite_z_pos,x
        CMP !ow_sprite_misc_1,x
        BCS return
        AND #$FFF8
        STA !ow_sprite_z_pos,x
        LDA #$0010
        STA !ow_sprite_speed_z,x
        LDA !ow_sprite_x_pos,x
        AND #$00FF
        EOR flip_values,y
        CMP #$0030
        BCC .check_if_flip
        LDA !ow_sprite_misc_5,x
        BEQ .stop_moving
        DEC !ow_sprite_misc_5,x
        RTL

.stop_moving
        INC !ow_sprite_misc_3,x
        SEP #$20
        JSL $01ACF9|!BankB
        REP #$20
        AND #$0003
        ASL
        TAY
        LDA stop_values,y
        STA !ow_sprite_misc_5,x
        RTL

.check_if_flip
        LDA !ow_sprite_timer_1,x
        BEQ flip_dir
        RTL

stop_values:
        dw $0002,$0003,$0005,$0001
flip_values:
        dw $00FF,$0000

bird_flip:
        db $50,$10

;-

draw_sprite:
	LDA #$0001
	%OverworldGetDrawInfoPriority()
        BCS .offscreen
        PHY
        TYA
        LSR #2
        TAY
        SEP #$20
        LDA #$00
        STA $0420|!Base2,y
        SEP #$30
        LDA !ow_sprite_extra_bits,x
        TAY
        LDA palette,y
        LDY !ow_sprite_misc_2,x
        ORA bird_flip,y
        STA $0F
        REP #$10
        PLY
        DEY #4
        LDA $00
        STA $0200|!Base2,y
        LDA $02
        STA $0201|!Base2,y
        LDA !ow_sprite_misc_4,x
        TAX
        LDA bird_tilemap,x
        STA $0202|!Base2,y
        LDX !ow_sprite_index
        LDA $0F
        STA $0203|!Base2,y
        REP #$20
        SEP #$10
.offscreen
        RTS

