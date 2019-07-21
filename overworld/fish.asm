;======================================
; Bernie Sanders is about to become a
; Twitch streamer
;======================================

x_positions:
        dw $0140,$0160,$0180,$0180,$0160,$0140
y_positions:
        dw $019C,$019C,$019C,$01BC,$01BC,$01BC

x_speeds:
        dw $0000,$0200,$0200,$0000,-$0200,-$0200,$0000,$0000
        dw -$0200,-$0200,$0000,$0200,$0200,$0000,$0000,$0000
y_speeds:
        dw -$0200,$0000,$0000,$0200,$0000,$0000,$0000,$0000
        dw $0000,$0000,-$0200,$0000,$0000,$0200,$0000,$0000

;---

tilemap:
        db $82,$84
        db $A0,$A2
        db $A0,$A2
        db $8C,$8E
props:
        db $22,$22,$62,$22

;---


print "INIT ",pc
init:
        wdm
        LDA #$0006
        %GetRandomRange()
        ASL
        TAY
        STA !ow_sprite_misc_2,x
        REP #$20
        LDA $0DEA
        AND #$00FF
        BNE .kill
        LDA $0DD5
        AND #$00FF
        BEQ .normal
        CMP #$0080
        BCS .pre_normal
        LDA $0EF7
        AND #$00FF
        CMP #$0080
        BCC .normal
.kill
        STZ !ow_sprite_num,x
        STZ $0EF7
        INC $0DEA
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
        LDA #$0006
        BRA .store_frame
.check_x
        LDA !ow_sprite_speed_x,x
        BEQ .store_frame
        LDA #$0002
        LDY !ow_sprite_speed_x,x
        BMI .store_frame
        LDA #$0004
.store_frame
        STA $00
        SEP #$30
        LDA $14
        LSR #3
        AND #$01
        ORA $00
        REP #$20
        STA !ow_sprite_misc_1,x
        LDY !ow_sprite_misc_2,x

        LDY #$0A
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
.return
        RTL

+       LDA !ow_sprite_speed_x,x
        ORA !ow_sprite_speed_y,x
        BNE .lock
        LDA $0DCF
        ORA $0DD1
        BEQ .return
        wdm
        SEP #$20
        JSL $01ACF9|!BankB
        AND #$01
        TAY
        LDA !ow_sprite_misc_2,x
        ; STA $00
        LSR
        CLC
        ADC adds,y
        BMI .overflow
        CMP #$06
        BCC .store
        LDA #$00
        BRA .store
.overflow
        LDA #$05
.store
        ASL
        STA !ow_sprite_misc_2,x
        REP #$20
        TYA
        ASL #4
        ORA !ow_sprite_misc_2,x
        AND #$00FF
        TAY
        LDA x_speeds,y
        STA !ow_sprite_speed_x,x
        LDA y_speeds,y
        STA !ow_sprite_speed_y,x
        RTL

.lock
        STZ $0DCF
        STZ $0DD1
        RTL

adds:
        db $01,$FF

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
        LDA $00
        STA $0200|!Base2,y
        LDA $02
        STA $0201|!Base2,y
        LDA !ow_sprite_misc_1,x
        TAX
        LDA tilemap,x
        STA $0202|!Base2,y
        TXA
        LSR
        TAX
        LDA props,x
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



