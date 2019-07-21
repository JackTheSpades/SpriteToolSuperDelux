;--------------------------------------------------------------------------------
; Routine to first spawn the sprite and put data into sprite tables:
; Input (16 bit):
;     $00 = Sprite number
;     $02 = Sprite X position (in pixel)
;     $04 = Sprite Y position (in pixel)
;     $06 = Sprite Z position (in pixel)
;     $08 = Extra Byte (not word!)
; Output:
;     Carry: Clear = No Spawn, Set = Spawn
;     X:     Sprite Index (for RAM addresses)
;--------------------------------------------------------------------------------

   LDX.b #!OwSprSize*2-2
?-
   LDA !ow_sprite_num,x          ; 
   BEQ .found_slot               ; If zero then the slot is unused, so jump to found_slot subroutine.
   DEX #2                        ; Decrease Y by 2 for next loop
   BPL ?-                        ; If we're not past Y=0 yet, keep going.
   CLC                           ; Clear Carry since we couldn't find a slot
   RTL                           ;

.found_slot
   LDA $00                       ; \
   STA !ow_sprite_num,x          ; |
   LDA $02                       ; | 
   STA !ow_sprite_x_pos,x        ; |
   LDA $04                       ; | Move data from $00-$08 to their respective addresses.
   STA !ow_sprite_y_pos,x        ; |
   LDA $06                       ; |
   STA !ow_sprite_z_pos,x        ; |
   LDA $08                       ; |
   AND #$00FF                    ; |
   STA !ow_sprite_extra_bits,x   ; /
   
   STZ !ow_sprite_speed_x,x      ; \
   STZ !ow_sprite_speed_x_acc,x  ; |
   STZ !ow_sprite_speed_y,x      ; |
   STZ !ow_sprite_speed_y_acc,x  ; |
   STZ !ow_sprite_speed_z,x      ; |
   STZ !ow_sprite_speed_z_acc,x  ; |
   STZ !ow_sprite_timer_1,x      ; |
   STZ !ow_sprite_timer_2,x      ; | Clear other tables
   STZ !ow_sprite_timer_3,x      ; |
   STZ !ow_sprite_misc_1,x       ; |
   STZ !ow_sprite_misc_2,x       ; |
   STZ !ow_sprite_misc_3,x       ; |
   STZ !ow_sprite_misc_4,x       ; |
   STZ !ow_sprite_misc_5,x       ; |
   STZ !ow_sprite_init,x         ; /
   SEC                           ; Set Carry to indicate we found a slot
   RTL

