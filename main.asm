
!__debug = 1
incsrc "sa1def.asm"		;sa-1 defines

; ---------------------------------------------------
; per/level sprite table locations, one bank each
; ---------------------------------------------------
org $00BA4D
TableLoc:
	db table1>>16
	db table2>>16
	db table3>>16
	db table4>>16
	
warnpc $00BA60

InitSpriteTables = $07F7D2|!BBank

org $05D8B9
	JSR Levelnum 
org $05DC46
	Levelnum:
	LDA $0E
	STA $010B 
	ASL A
	RTS


	
; ---------------------------------------------------
; original sprite_tool hijacks, credit to roy.	
; ---------------------------------------------------


; patch goal tape init to get extra bits in $187B
org $01C089
	LDA !extra_bits,x
	NOP
	NOP
	NOP
	NOP
	STA !187B,x
	
;hammer bro init pointer to null
org $0182B3
	db $C2,$85
;status routine wrapper
org $01D43E
		JSR $8133
		RTL
	

; store extra bits separate from $14D4
org $02A963
	autoclean JSL SubLoadHack
	NOP

; sprite init call subroutine
org $018172
	autoclean JSL SubInitHack
	NOP

; sprite code call subroutine					
org $0185C3
	autoclean JSL SubCodeHack
	NOP

; clear init bit when changing sprites
org $07F785
	autoclean JSL EraserHack
	NOP

org $018151
	autoclean JSL EraserHack2
	NOP
	
org $02A94B
	autoclean JSL SubLoadHack2
	NOP
	
org $02A866
	autoclean JML SubGenLoad

org $02ABA0
	autoclean JSL SubShootLoad
	NOP

org $02AFFE
	autoclean JSL SubGenExec
	NOP

org $02B395
	autoclean JML SubShootExec
	NOP
	
org $0187A7
	autoclean JML SetSpriteTables
	
org $018127
	autoclean JML SubHandleStatus
	
org $02A9C9
	autoclean JSL InitKeepextra_bits
	
org $02A9A6
	autoclean JSL TestSilverCoinBit
	NOP

 
; ---------------------------------------------------
; 80% original sprite_tool code, credit to roy.	
; 20% edits by Jack for sprites B0-BF being on
;     individual levels.
; --------------------------------------------------- 
freecode
SubLoadHack:
	PHA
	AND #$0D
	STA !extra_bits,x
	AND #$01
	STA !14D4,x
	LDA $05
	STA !new_sprite_num,x
	PLA
	RTL

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; convert regular sprite to custom sprite and call initialization
; routine
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SubInitHack:
	%debugmsg("Init hack")

	LDA #$08
	STA !14C8,x

	LDA !extra_bits,x
	AND #!CustomBit
	BNE .IsCustom
.R		
	RTL
.IsCustom
	JSL SetSpriteTables
	LDA !new_code_flag
	BEQ .R

	PLA	;pull lower 16-bit address
	PLA

	PEA $85C1
	LDA #$01
	JML [$0000]


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; call main code
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


SubCodeHack:
	%debugmsg("Main hack")
	STZ $1491|!Base2
	LDA !extra_bits,x
	AND #!CustomBit
	BNE .IsCustom
	LDA !9E,x
	RTL
.IsCustom
	LDA !new_sprite_num,x
	JSR GetMainPtr

	PLA
	PLA

	PEA $85C1
	LDA !14C8,x
	JML [$0000]

GetMainPtr:
	%debugmsg("Main Pointer hack")
	PHB
	PHK
	PLB
	PHP
	REP #$30
	AND #$00FF
	
	CMP #$00B0
	BCC .normal
	CMP #$00C0
	BCC .perlevel	
	SBC #$0010	;carry already set
.normal
	ASL #$04
	TAY

	LDA TableStart+$0B,y
	STA $00
	LDA TableStart+$0C,y
	STA $01
	PLP
	PLB
	RTS

	
.perlevel
	LDY #$000B
	JSR GetPerLevelPtr
	PLP
	PLB
	RTS

	
; Input, Y for in table offset
;        A=Sprite number (inbetween B0-BF)
;        Y=08 -> init
;        Y=0B -> main
GetPerLevelPtr:
	JSR GetPerLevelAddr
	LDA [$00]			; load low-high byte of pointer
	PHA					; save
	INC $00				; inc offset
	LDA [$00]			; load high-bank byte of pointer
	STA $01				; 00=x, 01=high, 02=bank
	PLA					; load
	STA $00				; 00=low, 01=high, 02=bank
	
	RTS
	
; Input, Y for in table offset
;        A=Sprite number (inbetween B0-BF)
GetPerLevelAddr:
	SEC
	SBC #$00B0	;carry already set
	PHX
	
	ASL #4		; sprite number * 0x10
	CLC			; +
	ADC #$8000	; high-low byte of table
	STA $00		; table always takes full bank and starts at $8000
	
	LDA $010B	; level number
	AND #$007F	; table stretches accross 4 banks, so only get in table bits
	XBA			; times 0x100
	ADC $00		; carry has to be clear because of ASL
	STA $00
	
	TYA				; add Y for in table offset
	AND #$00FF		;
	CLC : ADC $00	;
	STA $00			;
	
	
	LDA $010B	; \	
	ASL			; | two high bits of level number
	XBA			; |
	AND #$00FF	; /
	TAX 
	
	LDA.l TableLoc,x	; bank byte of table
	STA $02
	PLX
	RTS
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; clear init bit when changing sprites
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EraserHack:
	STZ !15AC,x
	LDA #$01
	STA !15A0,x
	DEC A
	STA !extra_bits,x
	RTL

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; clear init bit when changing sprites
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EraserHack2:
	LDA #$FF
	STA !161A,x
	INC A
	STA !extra_bits,x
	RTL


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; store extra bits - vertical level
; ROM 0x12B4B
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SubLoadHack2:
	PHA
	AND #$0D
	STA !extra_bits,x
	AND #$01
	STA !14E0,x
	LDA $05
	STA !new_sprite_num,x
	PLA
	RTL

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; hijack main sprite loader to handle custom gens and shooters
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SubGenLoad:
	PHA
	LDA #$00
	STA !new_code_flag
	PLA
	CMP #$C0
	BCC .NotGen
	CMP #$E0
	BCS .NotGen

;TestExtraBit:
	DEY
	LDA [$CE],y
	AND #$08
	BEQ .NotCustom

;GetType:
	LDA [$CE],y
	AND #$0C
	ASL #$04
	STA !new_code_flag
	INY

	LDA $05
	CMP #$D0
	BCS .IsCustomGen

.IsCustomShooter
	JML $02A8D8

.IsCustomGen
	LDA !new_code_flag
	STA $18B9|!Base2
	LDA $05
	SEC
	SBC #$CF
	ORA $18B9
	JML $02A8B8|!BBank

.NotCustom
	INY
	LDA $05
.NotGen		
	CMP #$E7
	BCC .Loc2
	JML $02A86A|!BBank
.Loc2		
	JML $02A88C|!BBank


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; hijack shooter table setter to insert extra bits
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SubShootLoad:
	LDA !new_code_flag
	BNE .IsCustom
	LDA $04
	SEC
	SBC #$C8
	RTL
.IsCustom
	STA $1783|!Base2,x
	LDA $04
	SEC
	SBC #$BF
	ORA $1783|!Base2,x
	RTL

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SubShootExec:
	LDY $1783|!Base2,x
	BMI .IsCustom
	LDY $17AB|!Base2,x
	BEQ .Loc2
	JML $82B39A
.Loc2		
	JML $82B3A4

.IsCustom	
	LDY $17AB|!Base2,x
	BEQ .CallSprite
	PHA
	LDA $13
	LSR A
	BCC .NoDecTimer
	DEC $17AB|!Base2,x
.NoDecTimer	
	PLA
.CallSprite	
	AND #$3F
	CLC
	ADC #$BF

	JSR GetMainPtr

	LDA #$82
	PHA
	PEA $B3A6
	JML [$0000]


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SubGenExec:
	LDA $18B9|!Base2
	BMI .IsCustom
	PLA
	PLA
	PLA
	LDA $18B9
	BEQ .Loc2
	JML $02B003|!BBank
.Loc2		
	JML $02B02A|!BBank

.IsCustom	
	AND #$3F
	CLC
	ADC #$CF

	JSR GetMainPtr

	PLA
	PLA
	PEA $B029
	JML [$0000]


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; set sprite tables from main table
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetSpriteTables:
	PHY
	PHB
	PHK
	PLB
	PHP

	LDA !new_sprite_num,x
	REP #$30
	AND #$00FF
	
	
	CMP #$00B0
	BCC .normal	
	CMP #$00C0
	BCC .perlevel
	
	SBC #$0010	; carry already set, sub 0x10
	
.normal
	
	ASL #$04
	TAY
	SEP #$20

	LDA TableStart,y
	STA !new_code_flag
	LDA TableStart+$01,y
	STA !9E,x
	LDA TableStart+$02,y
	STA !1656,x
	LDA TableStart+$03,y
	STA !1662,x
	LDA TableStart+$04,y
	STA !166E,x
	AND #$0F
	STA !15F6,x
	LDA TableStart+$05,y
	STA !167A,x
	LDA TableStart+$06,y
	STA !1686,x
	LDA TableStart+$07,y
	STA !190F,x

.join
	
	LDA !new_code_flag
	BNE .IsCustomNormal
.notCustom
	PLP
	PLB
	PLY
	LDA #$00
	STA !extra_bits,x
	RTL

.IsCustomNormal
	REP #$20
	LDA TableStart+$08,y
	STA $00
	SEP #$20
	LDA TableStart+$0A,y
	STA $02
	LDA TableStart+$0E,y
	STA !extra_prop_1,x
	LDA TableStart+$0F,y
	STA !extra_prop_2,x

.ret
	PLP
	PLB
	PLY
	RTL
	
.perlevel	
	LDY #$0000
	JSR GetPerLevelAddr	
	SEP #$20

	LDA [$00]				;0
	STA !new_code_flag
	INC $00					;no need for 16bit check, since table always starts at 0, 1
	LDA [$00]
	STA !9E,x
	INC $00					;2
	LDA [$00]
	STA !1656,x
	INC $00					;3
	LDA [$00]
	STA !1662,x
	INC $00					;4
	LDA [$00]
	STA !166E,x
	AND #$0F
	STA !15F6,x
	INC $00					;5
	LDA [$00]
	STA !167A,x
	INC $00					;6
	LDA [$00]
	STA !1686,x
	INC $00					;7
	LDA [$00]
	STA !190F,x
	INC $00					;8

	LDA !new_code_flag
	BEQ .notCustom
		
	REP #$20
	LDA [$00]
	PHA
	INC $00					;9
	LDA [$00]
	PHA						;INIT pointer on stack
	
	LDA #$0005
	CLC : ADC $00
	STA $00
	
	;INC $00					;A 
	;INC $00					;B 
	;INC $00					;C
	;INC $00					;D
	;INC $00					;E
	
	LDA [$00]
	STA !extra_prop_1,x
	INC $00						;F
	LDA [$00]
	STA !extra_prop_2,x

	PLA : STA $01
	PLA : STA $00				;init pointer to [$00]
	BRA .ret
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Call Main after handling status > 9
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SubHandleStatus:
	LDA !14C8,x
	CMP #$02
	BCC .CallDefault
.NoEraseOrInit
	CMP #$08
	BNE .NoMainRoutine
	JML $0185C3|!BBank
.NoMainRoutine
	PHA
	LDA !extra_bits,x
	AND #!CustomBit
	BNE .HandleCustomSprite
	PLA
.CallDefault
	JML $018133|!BBank		;call regular status handler

.HandleCustomSprite
	LDA !extra_prop_2,x
	BMI .CallMain
	PHA
	LDA $02,s
	JSL $01D43E|!BBank		;handle sprite based on status
	PLA
	ASL A
	BMI .CallMain
	PLA
	CMP #$09
	BCS .CallMain2
	CMP #$03
	BEQ .CallMain2
	JML $0185C2|!BBank
.CallMain2
	PHA
.CallMain
	LDA !new_sprite_num,x
	JSR GetMainPtr
	PLA

	LDY #$81
	PHY
	PEA $85C1
	JML [$0000]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Keep extra bits around when setting the sprite tables during
; level loading
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitKeepextra_bits:
	LDA !extra_bits,x
	PHA
	JSL InitSpriteTables
	PLA
	STA !extra_bits,x
	RTL
			
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Test a custom sprite's an ACTUAL bit so that the sprite ALWAYS won't be
; transformed to a silver coin.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
TestSilverCoinBit:
	PHA
	LDA !extra_bits,x
	AND #!CustomBit
	BNE .Custom
	PLX
	LDA $07F659|!BBank,x	;SMW sprite's $190F,x table
	RTL

.Custom
	PLA
	LDA !new_sprite_num,x
	PHP
	REP #$30
	AND #$00FF
	
	CMP #$00B0
	BCC .normal
	CMP #$00C0
	BCC .perlevel
	SBC #$0010	
.normal
	ASL #$04
	TAX
	LDA TableStart+$07,x
	PLP
	RTL
	
.perlevel
	LDY #$0007
	JSR GetPerLevelAddr
	LDA [$00]
	PLP
	RTL

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Custom sprites' table
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
TableStart:
	incbin "_DefaultTables.bin"
  

; ---------------------------------------------------
; per-level tables for sprite B0-BF 0x8000 bytes each.
; ---------------------------------------------------
freedata align,cleaned
table1:
	incbin "_PerLevelT1.bin"
freedata align,cleaned
table2:
	incbin "_PerLevelT2.bin"
freedata align,cleaned
table3:
	incbin "_PerLevelT3.bin"
freedata align,cleaned
table4:
	incbin "_PerLevelT4.bin"