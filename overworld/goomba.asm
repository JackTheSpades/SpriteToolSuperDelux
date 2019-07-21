;============================================================
; My back is hurting from the chair I'm sitting on
; Where's the Tylenol
; If I lie down flat on the floor it usually kinda
; Fixes it
; Tony Danza from Who's The Boss says Eeooeeooeeooeeoo
;============================================================

x_positions:
        dw $0050,$0070,$0050,$0070
y_positions:
        dw $00FC,$00FC,$011C,$011C

x_speeds:
        dw $0000,-$0200,$0000,$0200
y_speeds:
        dw -$0200,$0000,$0200,$0000

;-

tilemap:
        db $E8,$EA,$E8,$EA
        db $EC,$EE,$EC,$EE
        db $EC,$EE,$EC,$EE
        db $86,$88,$86,$88
props:
        db $2C,$2C,$4C,$2C

;---

print "INIT ",pc
init:
        SEP #$20
        JSL $01ACF9|!Base2
        AND #$03
        ASL
        TAY
        STA !ow_sprite_misc_2,x
        REP #$20
        LDA $0DE9
        AND #$00FF
        BNE .kill
        LDA $0DD5
        AND #$00FF
        BEQ .normal
        CMP #$0080
        BCS .pre_normal
.kill
        STZ !ow_sprite_num,x
        STZ $0EF7
        INC $0DE9
        RTL
.pre_normal
        LDA $1F17
        SEC
        SBC #$0008
        STA !ow_sprite_x_pos,x
        LDA $1F19
        SEC
        SBC #$000C
        STA !ow_sprite_y_pos,x
        BRA .return
.normal
        LDA x_positions,y
        STA !ow_sprite_x_pos,x
        LDA y_positions,y
        STA !ow_sprite_y_pos,x
.return
        JSR draw_sprite
        INC !ow_sprite_init,x
        RTL

;---

print "MAIN ",pc
main:
        JSR draw_sprite
        JSR interact
        BCC +
        ROR $0EF7
        LDA #$0003
        STA $13D9
        STZ $0DCF
        STZ $0DD1
        RTL
+       %OverworldXSpeed()
        %OverworldYSpeed()
        REP #$10
        LDA !ow_sprite_speed_y,x
        BEQ .check_x
        LDA #$0000
        LDY !ow_sprite_speed_y,x
        BPL .store_frame
        LDA #$000C
        BRA .store_frame
.check_x
        LDA !ow_sprite_speed_x,x
        BEQ .store_frame
        LDA #$0004
        LDY !ow_sprite_speed_x,x
        BMI .store_frame
        LDA #$0008
.store_frame
        STA $00
        SEP #$30
        LDA $14
        LSR #3
        AND #$03
        ORA $00
        REP #$20
        STA !ow_sprite_misc_1,x
        LDY !ow_sprite_misc_2,x

        ; LDA !ow_sprite_x_pos,x
        ; CMP x_positions,y
        ; BEQ .stop_moving
        ; LDA !ow_sprite_y_pos,x
        ; CMP y_positions,y
        ; BNE +
; .stop_moving
        ; STZ !ow_sprite_speed_x,x
        ; STZ !ow_sprite_speed_y,x

        LDY #$06
-       LDA !ow_sprite_x_pos,x
        CMP x_positions,y
        BNE .decrease
        LDA !ow_sprite_y_pos,x
        CMP y_positions,y
        BNE .decrease
        STZ !ow_sprite_speed_x,x
        STZ !ow_sprite_speed_y,x
        BRA +
.decrease
        DEY #2
        BPL -

+       LDA $13D9
        AND #$00FF
        CMP #$0002
        BEQ +
        CMP #$0003
        BEQ +
        CMP #$0005
        BEQ +
        ; CMP #$0004
        ; BNE .return
        ; wdm
        
        ; LDA !ow_sprite_speed_x,x
        ; ORA !ow_sprite_speed_y,x
        ; BEQ .return
        ; LDA #$0005
        ; STA $13D9
        ; STZ $0DCF
        ; STZ $0DD1
.return
        RTL

+       LDA !ow_sprite_speed_x,x
        ORA !ow_sprite_speed_y,x
        BNE .lock
        LDA $0DCF
        ORA $0DD1
        BEQ .return
.loop
        SEP #$20
-       JSL $01ACF9|!Base2
        AND #$03
        ASL
        TAY
        CMP !ow_sprite_misc_2,x
        BEQ -
        STA !ow_sprite_misc_2,x
        REP #$20
        LDA !ow_sprite_x_pos,x
        CMP x_positions,y
        BNE .correct
        LDA !ow_sprite_y_pos,x
        CMP y_positions,y
        BEQ .loop
.correct
        LDA x_speeds,y
        STA !ow_sprite_speed_x,x
        LDA y_speeds,y
        STA !ow_sprite_speed_y,x

        LDA !ow_sprite_x_pos,x
        PHA
        LDA !ow_sprite_y_pos,x
        PHA
        %OverworldXSpeed()
        %OverworldYSpeed()

        LDA !ow_sprite_x_pos,x
        CMP #$0050
        BCC .wrong_step
        CMP #$0071
        BCS .wrong_step
        LDA !ow_sprite_y_pos,x
        CMP #$00FC
        BCC .wrong_step
        CMP #$011D
        BCC .restore
.wrong_step
        PLA
        STA !ow_sprite_y_pos,x
        PLA
        STA !ow_sprite_x_pos,x
        STZ !ow_sprite_speed_x,x
        STZ !ow_sprite_speed_y,x
        BRA .loop
.restore
        PLA
        STA !ow_sprite_y_pos,x
        PLA
        STA !ow_sprite_x_pos,x
        RTL

.lock
        STZ $0DCF
        STZ $0DD1
        RTL

max_x_positions:
        dw $004F,$0071
max_y_positions:
        dw $00FB,$011D

;-

interact:
        LDA $1F17
        SEC
        SBC #$0008
        AND #$FFFE
        CMP !ow_sprite_x_pos,x
        BNE .return
        LDA !ow_sprite_y_pos,x
        AND #$FFFE
        STA $00
        LDA $1F19
        SEC
        SBC #$000C
        AND #$FFFE
        CMP $00
        BNE .return
        SEC
        RTS
.return
        CLC
        RTS

;-

draw_sprite:
        LDY $0DD6|!Base2
        LDA $1F19|!Base2,y
        SEC
        SBC #$0008
        CMP !ow_sprite_y_pos,x
        LDA #$0000
        BCS .normalinfo
        %OverworldGetDrawInfoPriority()
        BRA .doneinfo
.normalinfo
        %OverworldGetDrawInfo()
.doneinfo
        BCS .offscreen
        LDA #$0000
        SEP #$20
        STZ $0F
        LDA !ow_sprite_misc_1,x
        AND #$0C
        BEQ .change_flip
        CMP #$0C
        BNE .no_change
.change_flip
        LDA !ow_sprite_misc_1,x
        AND #$03
        CMP #$03
        BNE .no_change
        LDA #$40
        STA $0F
.no_change
        LDA $00
        STA $0200|!Base2,y
        LDA $02
        STA $0201|!Base2,y
        LDA !ow_sprite_misc_1,x
        TAX
        LDA tilemap,x
        STA $0202|!Base2,y
        TXA
        LSR #2
        TAX
        LDA props,x
        ORA $0F
        STA $0203|!Base2,y
        REP #$20
        TYA
        LSR #2
        TAY
        SEP #$20
        LDA #$02
        STA $0420|!Base2,y
        LDX !ow_sprite_index
        REP #$20
        SEP #$10
.offscreen
        RTS

