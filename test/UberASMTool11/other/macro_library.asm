; This file is automatically included into all other UberASM Tool files.
; Useful for putting macros, defines, etc.
; Putting code or data is NOT recommend though or you will end up wasting lot of space.
; Put data or code at library folder instead.

!sa1	= 0			; 0 if LoROM, 1 if SA-1 ROM.
!dp	= $0000			; $0000 if LoROM, $3000 if SA-1 ROM.
!addr	= $0000			; $0000 if LoROM, $6000 if SA-1 ROM.
!bank	= $800000		; $80:0000 if LoROM, $00:0000 if SA-1 ROM.
!bank8	= $80			; $80 if LoROM, $00 if SA-1 ROM.

!sprite_slots = 12		; 12 if LoROM, 22 if SA-1 ROM.

; Check if SA-1 is present.
if read1($00ffd5) == $23
	!sa1	= 1
	!dp	= $3000
	!addr	= $6000
	!bank	= $000000
	!bank8	= $00
	
	!sprite_slots = 22
	
	sa1rom
endif

; Protect binary file.
macro prot_file(file, label)
	pushpc
		freedata cleaned
		print "_prot ", pc
		
		<label>:
			incbin "/../<file>"
	pullpc
endmacro

; Protect external source code.
macro prot_source(file, label)
	pushpc
		freecode cleaned
		print "_prot ", pc
		
		<label>:
			incsrc "/../<file>"
	pullpc
endmacro

; Generic macro for moving data blocks.
; Destroys A/X/Y.
; Parameters: src = source to read, dest = destination to write, len = total bytes to copy.
macro move_block(src,dest,len)
	PHB
	REP #$30
	LDA.w #<len>-1
	LDX.w #<src>
	LDY.w #<dest>
	MVN <dest>>>16,<src>>>16
	SEP #$30
	PLB
endmacro

; Macro for calling SA-1 CPU. Label should point to a routine which ends in RTL.
; Data bank is not set, so use PHB/PHK/PLB ... PLB in your SA-1 code.
macro invoke_sa1(label)
	LDA.b #<label>
	STA $3180
	LDA.b #<label>>>8
	STA $3181
	LDA.b #<label>>>16
	STA $3182
	JSR $1E80
endmacro

; Macro for calling SNES CPU (from SA-1 CPU). Label should point to a routine which ends in RTL.
; Data bank is not set automatically.
macro invoke_snes(addr)
	LDA.b #<addr>
	STA $0183
	LDA.b #<addr>/256
	STA $0184
	LDA.b #<addr>/65536
	STA $0185
	LDA #$D0
	STA $2209
-	LDA $018A
	BEQ -
	STZ $018A
endmacro
