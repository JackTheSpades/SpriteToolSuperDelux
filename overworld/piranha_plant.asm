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
!props  = $32

; %OverworldOffScreen()
print "INIT ",pc
        LDA !ow_sprite_extra_bits,x
        BEQ .no_disappear
        TAY
        SEP #$20
        LDA $1EA2|!Base2,y
        BPL .no_disappear
        REP #$20
        STZ !ow_sprite_num,x
        RTL
.no_disappear
        REP #$20
print "MAIN ",pc
        LDA #$0000
        %OverworldGetDrawInfo()
        BCS .offscreen
        SEP #$20
        LDA $00
        ; ADC #$08
        STA $0200|!Base2,y
        LDA $02
        ; CLC
        ADC #$04
        STA $0201|!Base2,y
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
        STA $0202|!Base2,y
        LDA #!props
        STA $0203|!Base2,y
        REP #$20
        TYA
        LSR #2
        TAY
        SEP #$20
        LDA #$02
        STA $0420|!Base2,y

        REP #$20
        SEP #$10
.offscreen
        RTL
