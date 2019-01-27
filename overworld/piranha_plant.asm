;====================================================
; Overworld Piranha Plant "Disassembly"
; By Erik
;
; Description: This is a "disassembly" of the piranha
; plant overworld sprite found in the vanilla Super
; Mario World. Did you know it can do one feature
; apart from just animating?
;
; Uses extra byte: YES
; tl;dr: Set this to a level number (13BF format)
; and when said level is beaten this sprite will
; no longer appear. 0 = it won't do any of that
;-
; The original sprite was meant to be put over a
; level and disappeared when you beat it. This is
; kind of similar in the sense I'm forced to use
; event flags instead of just checking whether the
; level was just beaten.
;====================================================

!tile1  = $2A
!tile2  = $2C
!props  = $34

init:
        LDA !ow_sprite_extra_byte,x
        BEQ .no_disappear
        TAY
        SEP #$20
        LDA $1EA2|!addr,y
        BPL .no_disappear
        REP #$20
        STZ !ow_sprite_num,x
        RTL
.no_disappear
        REP #$20
main:
        LDA #$0000
        JSL get_draw_info
        BCS .offscreen
        SEP #$20
        LDA $00
        ADC #$08
        STA $0200|!addr,y
        LDA $02
        CLC
        ADC #$08
        STA $0201|!addr,y
        PHY
        SEP #$10
        LDX #!tile1
        LDA $14
        AND #$08
        BNE +
        LDX #!tile2
+       TXA
        REP #$10
        PLY
        LDX !ow_sprite_index
        STA $0202|!addr,y
        LDA #!props
        STA $0203|!addr,y
        REP #$20
        TYA
        LSR #2
        TAY
        SEP #$20
        LDA #$02
        STA $0420|!addr,y

        REP #$20
        SEP #$10
.offscreen
        RTL
