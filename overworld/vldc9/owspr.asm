;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Custom Overworld Sprites
;  by Lui37
;
; This patch allows you to insert and use custom overworld sprites without having to
; adhere to SMW's (and Lunar Magic's) extremely limited overworld sprite system.
;
; Usage instructions can be found in the included readme.
; Only use the included p4sar.exe to apply this patch. It will not work in other assemblers.
; This patch only works on SA-1 ROMs. Non-sA-1 compatibility is attempted, but the
; free-RAM picked in defs.asm is not usable on vanilla ROMs and all included sprites
; are coded for SA-1 only.
;
; ---
;
; The "best[sprite]" series in the included sprites refers to the sprites used in
; Best World in VLDC9. They are remakes of level sprites to work on the map.
; They won't fit into most maps, but they would work as-is.
;
; Among the included sprites you will find a folder named "VLDC9 Specifics"; these
; sprites are fine to edit and use, but they will not work out of the box at all.
; ASM knowledge is required.
;
; All graphics needed for these sprites can be found in the GRAPHICS folder next to all
; the sprite ASM files. Palettes are included as well.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



;sa1rom

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;SA1 detector:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
if read1($00FFD5) == $23
	!SA1 = 1
	sa1rom
else
	!SA1 = 0
endif

; Example usage
if !SA1
	; SA-1 base addresses	;Give thanks to absentCrowned for this:
				;http://www.smwcentral.net/?p=viewthread&t=71953
	!Base1 = $3000		;>$0000-$00FF -> $3000-$30FF
	!Base2 = $6000		;>$0100-$0FFF -> $6100-$6FFF and $1000-$1FFF -> $7000-$7FFF
else
	; Non SA-1 base addresses
	!Base1 = $0000
	!Base2 = $0000
endif
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



incsrc "owsprites/defs.asm"
incsrc "owsprites/dma.asm"


freedata
	main_ptr:
		incsrc "_OverworldMainPtr.bin"
		dw $0000
	init_ptr:
		incsrc "_OverworldInitPtr.bin"
		dw $0000

org $0086C1
	autoclean JML mask_controls

; restore
org $04840D
	JSR $F708
	
org $048410
	JMP ow_hijack
	
org $04EF3E
	autoclean dl main_ptr         ; for cleanup by PIXI

ow_hijack:
	JSR $862E                     ; hijacked code
	
	LDA hidemario                 ; \
	BEQ +                         ; |
	LDA #$F0                      ; | clear Mario's OAM data
	STA.w $029D|!Base2            ; | when hidden
	STA.w $029D|!Base2+4          ; |
	STA.w $029D|!Base2+8          ; |
	STA.w $029D|!Base2+12         ; |
	STA.w $029D|!Base2+16         ; |
	STA.w $029D|!Base2+20         ; |
	STA.w $029D|!Base2+24         ; |
	STA.w $029D|!Base2+28         ; /
+
	
	LDA #ow_sprites>>16           ; \
	PHA                           ; |
	PLB                           ; | wrapper and jump to overworld sprites code
	autoclean JSL ow_sprites      ; |
	PLB                           ; /
	RTL

	
freecode
ow_sprites:
	LDX.w $0DB3|!Base2            ; \ player overworld times 2.
	LDA.w $1F11|!Base2,x          ; |  
	ASL                           ; /
	STA map_index
	
	LDA init_done
	BNE main                      ; prolly gonna throw an error LOL
	
; ---- init ----
	
init:
	REP #$20
	STZ sprite.next_index		; clear all sprite slots
	LDX #!slots*2-2
.clear_loop:
	STZ sprite.number,x
	DEX
	DEX
	BPL .clear_loop
	
	LDX map_index
	LDA sprite_data,x
	STA $6B
	LDY #$00
	
.data_loop:
	LDA ($6B),y
	BEQ .data_end
	
	LDA ($6B),y			; get sprite number
	AND #$007F
	STA $00
	LDA ($6B),y			; get x position
	LSR #7				; could prolly optimize the shifts
	AND #$003F			; but w/e
	ASL #3
	STA $02
	INY				; get y position
	LDA ($6B),y
	LSR #5
	AND #$003F
	ASL #3
	STA $04
	INY
	LDA ($6B),y			; get z position
	LSR #3
	AND #$001F
	ASL #3
	STA $06
	
	JSR spawn_sprite
	
	INY
	LDA ($6B),y
	AND #$00FF
	STA sprite.extra,x
	
	INY
	BRA .data_loop
	
.data_end:
	SEP #$20
	INC init_done
	
	RTL
	
; ---- main ----
	
main:
	REP #$20
	LDA #!oam_start
	STA sprite.oam_index
	LDA #!oam_start_p
	STA sprite.oam_index_p
	
	LDX #!slots*2-2
.exec_loop:
	LDA sprite.number,x
	BEQ .next
	LDA sprite.initialized,x
	BEQ .init
	JSR exec_sprite_main
	BRA +
	
.init:
	JSR exec_sprite_init
	INC sprite.initialized,x

+

	; dunno if $9D is still pause flag
	
	LDA sprite.timer1,x
	BEQ +
	DEC sprite.timer1,x
+	
	LDA sprite.timer2,x
	BEQ +
	DEC sprite.timer2,x
+
	LDA sprite.timer3,x
	BEQ +
	DEC sprite.timer3,x
+

.next:
	DEX
	DEX
	BPL .exec_loop
	
	
	SEP #$20
	
	RTL


exec_sprite_main:
	STX sprite.curr_index
	LDA sprite.number,x
	ASL
	TAY
	LDA main_ptrs-2,y
	STA $00
	JMP.w ($0000|!Base1)
	
exec_sprite_init:
	
	STX sprite.curr_index
	LDA sprite.number,x
	ASL
	TAY
	LDA init_ptrs-2,y
	STA $00
	JMP.w ($0000|!Base1)
	
; ----------------------------------

mask_controls:
	LDA.w $0DA8|!Base2,x
	STA $18
	LDA controls_mask_low
	TRB $15
	TRB $16
	LDA controls_mask_high
	TRB $17
	TRB $18
	STZ controls_mask_low
	STZ controls_mask_high
	JML $0086C6
	
; ----------------------------------

incsrc "owsprites/subs.asm"
	


	