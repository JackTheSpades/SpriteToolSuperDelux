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

org read3($0EF55D)
   map_offsets:


org $00A165                      ;   jump to new ow sprite load (this one will run in gamemode $0C)
   JML ow_sprite_load_gm
org $04DBA3                      ;   jump to new ow sprite load (this one will run in map transitions)
   JMP.w ow_sprite_load_sm
org $009AA4                      ;   nuke jump to original ow sprite load
   BRA $02 : NOP #2
org $04F675                      ;   nuke original ow sprite load (which runs in gamemode $05)
   padbyte $EA : pad $04F6F8

;   main hijack, within vanilla freespace
org $04F675|!BankB
   autoclean dl ow_sprite_main_ptrs ; \ constant pointer to ow sprites main pointers for cleanup by tool.
   autoclean dl spawn_sprite        ; / random pointer to freecode for cleanup.   

ow_sprite_load_main:
   if !SA1
      LDA.b #.main
      STA $3180
      LDA.b #.main>>8
      STA $3181
      LDA.b #.main>>16
      STA $3182
      JSR $1E80
      RTS
   endif
.main
   PHB
   LDA.l $0EF55E                 ; you wouldn't put this table in WRAM
   BEQ .end_spawning
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

   INY
   BRA .sprite_load_loop

.end_spawning
   SEP #$20
   PLB
   if !SA1
     RTL
   else
     RTS
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
return:
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
   PEA.w return-1                ; | workaround for JSL [$0000]
   JML.w [!Base1]                ; /

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
   PEA.w return-1       ; | workaround for JSL [$0000]
   JML.w [!Base1]                ; /

;---

math pri off

clear_ram:
   REP #$30
   LDX.w #!OwSprSize*2*21+4
-  STZ !ow_sprite_num,x
   DEX #2
   BPL -
   SEP #$30
   RTS

;---

ow_sprite_load:
.gm
   JSR ow_sprite_load_main
   JSL $04D6E9|!BankB
   JML $00A169|!BankB
.sm
   PHX
   JSR clear_ram
   JSR ow_sprite_load_main
   PLX
   LDA $1F11|!Base2,x
   JMP $DBA6

warnpc $04F928|!BankB           ; This warnpc can be moved MUCH further. I just put it here since I'm too lazy to count where.
                                ; And besides, it's more than enough space.


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

pushpc                           ; Move these OAM mirrors somewhere else; fixes the overworld border sometimes breaking
   org $0485F5                   ; Too lazy to fix the OAM routine itself :shrug:
      STA $0210|!Base2,x
   org $0485FF
      STA $0211|!Base2,x
   org $048604
      STA $0212|!Base2,x
   org $048609
      STA $0213|!Base2,x
   org $048610
      STA $0424|!Base2,x

   org $04EC3A
      STA $0200|!Base2,y
   org $04EC43
      STA $0201|!Base2,y
   org $04EC48
      STA $0202|!Base2,y
   org $04EC4E
      STA $0203|!Base2,y
   org $04EC5A
      STZ $0420|!Base2
      STZ $0421|!Base2
      STZ $0422|!Base2
      STZ $0423|!Base2
pullpc

