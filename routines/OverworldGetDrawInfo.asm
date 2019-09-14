; A: tiles to draw -1
; ->
; Y BECOMES 16 BIT REGARDLESS: oam index to use
; $00: x pos, screen relative
; $02: y pos, screen relative
; $04: mangled
; $06: mangled
; $08: mangled
; carry set: off screen
   
   !oam_start      = $00BC
   !oam_limit      = $01E8
   !oam_start_p    = $0070

        REP #$10
        LDY.w !ow_sprite_oam
        ASL #2
        STA $04
        STZ $06
        %OverworldOffScreen()
        BCS .offscreen
        SEP #$20

; dude spaghetti L M A O
        
.oam_loop
        CPY #!oam_limit
        BCC ?+
.loop_back
        LDY #!oam_start
        LDA $06                 ; don't loop back forever
        BNE .good
        INC $06
?+      LDA $0201|!Base2,y
        CMP #$F0
        BEQ .check_tile_amount  ; see if there are enough free tiles
.oam_next
        INY #4
        BRA .oam_loop

.check_tile_amount
        REP #$21                ; calc ideal end index
        TYA
        ADC $04
        STA $08
        SEP #$20
.tile_amount_loop
        CPY $08
        BEQ .good
        INY #4
        CPY #!oam_limit
        BCS .loop_back
        LDA $0201|!Base2,y
        CMP #$F0
        BEQ .tile_amount_loop
        BRA .oam_next

.good
        REP #$21
        TYA
        ADC #$0004
        STA !ow_sprite_oam
        ; CLC
        RTL

.offscreen
        SEP #$11
        RTL

