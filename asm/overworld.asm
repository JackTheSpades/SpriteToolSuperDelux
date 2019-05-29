;=========================================================
; Custom Overworld Sprites
; LM Implementation by Erik
;
; This couldn't be done without resources/stuff made by:
; - Lui37, Medic et al.: original "custom ow sprites"
;   used in the ninth VLDC. Most of this is based on his
;   work.
;   See https://smwc.me/1413938
; - FuSoYa: added the custom overworld sprite support into
;   Lunar Magic, based on the format used by VLDC9.
;=========================================================
; Code commenting and slight improvments by JackTheSpades
;=========================================================

incsrc "sa1def.asm"              ;  sa-1 defines


assert read3($0EF55D) != $FFFFFF, "Please insert any custom overworld sprite with Lunar Magic first. (Press Insert when in sprite mode)"

org read3($0EF55D)
   map_offsets:


org $00A165                      ;   jump to new ow sprite load (this one will run in gamemode $0C)
   JML ow_sprite_load
org $009AA4                      ;   nuke jump to original ow sprite load
   BRA $02 : NOP #2
org $04F675                      ;   nuke original ow sprite load (which runs in gamemode $05)
   padbyte $EA : pad $04F6F8

;   main hijack, within vanilla freespace
org $04F675|!BankB
   autoclean dl ow_sprite_main_ptrs ; \ constant pointer to ow sprites main pointers for cleanup by tool.
   autoclean dl spawn_sprite        ; / random pointer to freecode for cleanup.   
ow_sprite_load:
   if !SA1
      LDA.b #.main
      STA $3180
      LDA.b #.main>>8
      STA $3181
      LDA.b #.main>>16
      STA $3182
      JSR $1E80
      JSL $04D6E9|!BankB
      JML $00A169|!BankB
   endif
.main
   PHB
   LDX $0DB3|!Base2              ; \
   LDA $1F11|!Base2,x            ; | submap of current player (times 2) into X for index to offset table.
   ASL                           ; |
   TAX                           ; /
   REP #$21                      ; 16 bit for A and CLC
   LDA.w #map_offsets            ; \
   ADC.l map_offsets,x           ; | get long map pointer into $6B
   STA $6B                       ; | by loading base location and adding the offset for the current map
   LDY.b #map_offsets>>16        ; | 
   STY $6D                       ; /
   
   LDY #$00                      ; loop counter = 0
.sprite_load_loop                ; loop for decoding sprite data and spawning sprite.
   LDA [$6B],y                   ; \ get first word of sprite data (yyyx xxxx  xnnn nnnn)
   BEQ .end_spawning             ; | 0x0000 indicates end of data
   AND #$007F                    ; |
   STA $00                       ; | mask out n bits (sprite number) and store to $00
   LDA [$6B],y                   ; |
   AND #$1F80                    ; | mask out x bits: ---xxxxx x-------
   XBA                           ; | swap bytes in A: x------- ---xxxXX
   ROL                           ; | rotate left:     -------- --xxxxxx
   ASL #3                        ; | multiple by 8 because x is in 8x8 blocks, not pixels.
   STA $02                       ; / store x position (in pixels) in $02
   INY
   
   LDA [$6B],y                   ; \ get 'middle' word of sprite data (zzzz zyyy  yyyx xxxx)
   AND #$07E0                    ; | mask out y bits:     -----yyy yyy-----
   LSR #2                        ; | shift y bits down by 2 (same as y multiplied by 8 to get pixels from 8x8)
   STA $04                       ; / store y position (in pixel) in $04
   
   LDA [$6B],y                   ; \ get 'middle' word of sprite data (zzzz zyyy  yyyx xxxx)
   AND #$F800                    ; | mask out z bits: zzzzz--- --------
   XBA                           ; | swap bytes:      -------- zzzzz---
   STA $06                       ; / store z position (in pixel) in $06
   
   INY #2                        ; \ 
   LDA [$6B],y                   ; | get high word or sprite data (____ ____  eeee eeee)
   STA $08                       ; / store extra byte to $08 (and garbage data to $09)

   JSL spawn_sprite              ; \ Routine to first spawn the sprite and put data into sprite tables:
                                 ; | Input (16 bit):
                                 ; |     $00 = Sprite number
                                 ; |     $02 = Sprite X position (in pixel)
                                 ; |     $04 = Sprite Y position (in pixel)
                                 ; |     $06 = Sprite Z position (in pixel)
                                 ; |     $08 = Extra Byte (not word!)
                                 ; | Output:
   BCC .end_spawning             ; |     Carry: Clear = No Spawn, Set = Spawn
                                 ; /     X:     Sprite Index (for RAM addresses) 
   
   PHY
   JSR execute_ow_sprite_init
   PLY

   INY
   BRA .sprite_load_loop

.end_spawning
   ; STZ !ow_sprite_index
   SEP #$20
   PLB
   if !SA1 == 0
      JSL $04D6E9|!BankB
      JML $00A169|!BankB
   else
      RTL
   endif
warnpc $04F6F8|!BankB



org $04F76E|!BankB
run_ow_sprite:
   PHB                           ;
   REP #$21                      ;
   LDA #!oam_start               ;
   STA !ow_sprite_oam            ;
   LDA #!oam_start_p             ;
   STA !ow_sprite_oam_p          ;
   
   LDX.b #!OwSprSize*2-2         ; \
-  LDA !ow_sprite_num,x          ; | Main loop.
   BEQ .no_sprite                ; | Call execute_ow_sprite for all sprites where    
   LDA !ow_sprite_init,x         ; | !ow_sprite_num,x is not zero.
   BNE +                         ; |
   JSR execute_ow_sprite_init    ; | Or, in case !ow_sprite_init,x is still zero,
   INC !ow_sprite_init,x         ; | call execute_ow_sprite_init and then INC it.
   BRA .no_sprite                ; |
+  JSR execute_ow_sprite         ; |
.no_sprite                       ; |
   DEX #2                        ; |
   BPL -                         ; /
   
   ; STZ !ow_sprite_index        ; \
   SEP #$20                      ; | 
   PLB                           ; | Restore bank byte.
   RTS                           ; /
   
;--------------------------------------------------------------------------------
; Routine that calls the ow-sprites main function
; Also reduces the sprite's timers by 1.
; Input: X                 = sprite index
;        !ow_sprite_num,x  = sprite number   
;--------------------------------------------------------------------------------
execute_ow_sprite:
   STX !ow_sprite_index

   LDA !ow_sprite_timer_1,x      ; \
   BEQ +                         ; |
   DEC !ow_sprite_timer_1,x      ; |
+                                ; |
   LDA !ow_sprite_timer_2,x      ; | Decrease Timers (unless already zero) 
   BEQ +                         ; | 
   DEC !ow_sprite_timer_2,x      ; |
+                                ; |
   LDA !ow_sprite_timer_3,x      ; |
   BEQ +                         ; |
   DEC !ow_sprite_timer_3,x      ; |
+                                ; /

   LDA !ow_sprite_num,x          ; \
   ASL                           ; | Sprite number times 3 in x
   ADC !ow_sprite_num,x          ; |
   TXY                           ; |
   TAX                           ; /
   
   LDA.l ow_sprite_main_ptrs-3,x ; \ 
   STA $00                       ; | Get sprite main pointer in $00
   SEP #$20                      ; | sprite number 00 is <end> so the table...
   LDA.l ow_sprite_main_ptrs-1,x ; | ... is actually 1 indexed (hence those subtractions)
   STA $02                       ; /
   
   PHA                           ; \ 
   PLB                           ; | Setup bank (value still in A)
   REP #$20                      ; | A in 16 bit
   TYX                           ; / Restore X with sprite index.
   
   PHK                           ; \
   PEA.w .return_execute-1       ; |
   JML.w [!Base1]                ; | workaround for JSL [$0000]
.return_execute                  ; |
   RTS                           ; /

;--------------------------------------------------------------------------------
; Routine that calls the ow-sprites init function
; Also reduces the sprite's timers by 1.
; Input: X                 = sprite index
;        !ow_sprite_num,x  = sprite number   
;--------------------------------------------------------------------------------
execute_ow_sprite_init:
   STX !ow_sprite_index

   LDA !ow_sprite_num,x          ; \
   ASL                           ; | Sprite number times 3 in x
   ADC !ow_sprite_num,x          ; |
   TXY                           ; |
   TAX                           ; /
   
   LDA.l ow_sprite_init_ptrs-3,x ; \ 
   STA $00                       ; | Get sprite init pointer in $00
   SEP #$20                      ; | sprite number 00 is <end> so the table...
   LDA.l ow_sprite_init_ptrs-1,x ; | ... is actually 1 indexed (hence those subtractions)
   STA $02                       ; /
   
   PHA                           ; \ 
   PLB                           ; | Setup bank (value still in A)
   REP #$20                      ; | A in 16 bit
   TYX                           ; / Restore X with sprite index.
   
   PHK                           ; \
   PEA.w .return_execute-1       ; |
   JML.w [!Base1]                ; | workaround for JSL [$0000]
.return_execute                  ; |
   RTS                           ; /

warnpc $04F8A6|!BankB


freedata
   ow_sprite_init_ptrs:
      incbin "_OverworldInitPtr.bin"
   ow_sprite_main_ptrs:
      incbin "_OverworldMainPtr.bin"

freecode

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
spawn_sprite:
   LDX.b #!OwSprSize*2-2
-
   LDA !ow_sprite_num,x          ; 
   BEQ .found_slot               ; If zero then the slot is unused, so jump to found_slot subroutine.
   DEX #2                        ; Decrease Y by 2 for next loop
   BPL -                         ; If we're not past Y=0 yet, keep going.
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
   STZ !ow_sprite_timer_1,x      ; | Clear other tables
   STZ !ow_sprite_timer_2,x      ; |
   STZ !ow_sprite_timer_3,x      ; |
   STZ !ow_sprite_misc_1,x       ; |
   STZ !ow_sprite_misc_2,x       ; |
   STZ !ow_sprite_misc_3,x       ; |
   STZ !ow_sprite_misc_4,x       ; |
   STZ !ow_sprite_misc_5,x       ; /
   SEC                           ; Set Carry to indicate we found a slot
   RTL


;   lm disassembly stuff below:
;
; org $0EF55D
;         autoclean dl ow_spr_table     ;   this corresponds to sprite_data in luiz's patch
;
; freecode                              ;   org $12AB6C
;
; ow_spr_table:                         ;   here, these are offsets instead of rom addresses
;         dw main_map                   ;   dw $000E ($12AB7A-$12AB6C)
;         dw yoshis_island              ;   dw $0010 ($12AB7C-$12AB6C)
;         dw vanilla_dome               ;\
;         dw forest_of_illusion         ; |
;         dw bowsers_valley             ; | dw $0014 ($12AB80-$12AB6C)
;         dw special_world              ; |
;         dw star_world                 ;/
;
; main_map:                             ;   org $12AB7A
;         dw $0000                      ;   data end
; yoshis_island:
;         db $01,$E3,$01,$02            ;   format below
; vanilla_dome:
; forest_of_illusion:
; bowsers_valley:
; special_world:
; star_world:
;         dw $0000
;
; ;   info ripped from luiz
; ;   sprite data format
; ;   eeee eeee  zzzz zyyy  yyyx xxxx  xnnn nnnn (big endian)
; ;
; ;   -nnn nnnn	sprite id
; ;   --xx xxxx	x pos, in 8x8s, get the values from lm
; ;   --yy yyyy	y pos etc
; ;   ---z zzzz	z pos etc
; ;   eeee eeee	extra byte
; ;
; ;   0 means data end (duh)

