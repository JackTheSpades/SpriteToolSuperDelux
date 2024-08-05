;Aiming Routine by MarioE. 
;Edited by Isikoro

;Input:  A   = 8 bit projectile speed
;        Y   = Angle to shift（Degree）
;				01~5A = Clockwise
;				FF~A6 = Counterclockwise
;        $00 = 16 bit (shooter x pos - target x pos)
;        $02 = 16 bit (shooter y pos - target y pos)
;        $08 = Sprite's Direction（Only used if the distance is 0.）
;
;Output: $02 = 8 bit X speed of projectile
;        $03 = 8 bit Y speed of projectile
					
					PHX
					STY $0B
					STA $0A
					REP #$21
					LDX #$01 : TXY
					LDA $00
					BPL +
					EOR #$FFFF : INC : STA $00 : DEX
+					LDA $02
					BPL +
					EOR #$FFFF : INC : STA $02 : DEY
					
+					STX $04 : STY $05
					LDA $00
					ADC $02
					BNE +
					LDA $08
					AND #$00FF
					ASL : DEC
					STA $00
					BPL +
					EOR #$FFFF : INC : STA $00 : DEC $04
+					STA $06
					JSR Aim_Dist0_Inverted
					SEP #$20
					
					JSR Aim_Degree_Math
					EOR $04
					ADC #$00
					STA $02
					
					TXA
					EOR #$FF
					INC
					SEC
					SBC #$A6
					TAX
					
					JSR Aim_Speed_Math
					EOR $05
					ADC #$00
					STA $03
					PLX
					RTL
					
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Aim_Not_Flag:		db $00,$FF,$FF
Aim_NotToNeg:		db $00,$01,$01
					
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					
Aim_Dist0_Inverted:	LDA $00 : BEQ Aim_XDist_Zero
					LDA $02 : BEQ Aim_YDist_Zero
					RTS
Aim_XDist_Zero:		SEP #$20
					LDA $05 : EOR #$01 : STA $04
					RTS
Aim_YDist_Zero:		SEP #$20
					LDA $04 : STA $05
					RTS
					
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					
Aim_Degree_Math:	
				if !SA1 == 0
					LDA $00 : STA $211B
					LDA $01 : STA $211B
					LDA #$5A
					STA $211C
				else
					STZ $2250
					LDA $00 : STA $2251
					LDA $01 : STA $2252
					LDA #$5A
					STA $2253
					STZ $2254
				endif
					;NOP #3
					LDY $0B
					REP #$20
					LDX #$0F
Aim_Division:	if !SA1 == 0
					LDA $2134
				else
					LDA $2306
				endif
					ASL A
					STA $00
					TDC
Aim_Division_Loop:	ROL A
					CMP $06
					BCC Aim_Division_Skip
					SBC $06
Aim_Division_Skip:	ROL $00
					DEX
					BPL Aim_Division_Loop
					STA $08
Aim_Rounding:		LDA $06
					INC
					LSR
					DEC
					SEC
					SBC $08
					SEP #$20
					LDA #$00
					ROL
					EOR #$01
					ADC $00
					JSR Angle_Shifted
					LDY #$00
					TAX
					
Aim_Speed_Math:		LDA $0A
				if !SA1 == 0
					STA $4202
					LDA.l SinHexTable,x
					STA $4203
					;NOP
					INY
					LDA $4216
					STA $4204
					LDA $4217
					STA $4205
					LDA #$64
					STA $4206
					LDA $03,y : EOR #$FF : INC : STA $03,y : LSR
					LDA $4214
				else
					STZ $2250
					STA $2251
					STZ $2252
					LDA.l SinHexTable,x
					STA $2253
					STZ $2254
					;NOP
					INY
					LDA #$01 : STA $2250
					LDA $2306 : STA $2251
					LDA $2307 : STA $2252
					LDA #$64
					STA $2253
					STZ $2254
					LDA $03,y : EOR #$FF : INC : STA $03,y : LSR
					LDA $2306
				endif
					RTS

SinHexTable:
db $00,$01,$03,$05,$06,$08,$0A,$0C
db $0D,$0F,$11,$13,$14,$16,$18,$19
db $1B,$1D,$1E,$20,$22,$23,$25,$27
db $28,$2A,$2B,$2D,$2E,$30,$31,$33
db $34,$36,$37,$39,$3A,$3C,$3D,$3E
db $40,$41,$42,$44,$45,$46,$47,$49
db $4A,$4B,$4C,$4D,$4E,$4F,$50,$51
db $52,$53,$54,$55,$56,$57,$58,$59
db $59,$5A,$5B,$5C,$5C,$5D,$5D,$5E
db $5F,$5F,$60,$60,$61,$61,$61,$62
db $62,$62,$63,$63,$63,$63,$63,$63
db $63,$63,$64
					
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					
Angle_Shifted:		STA $08
					STY $0B
					LDA $04
					EOR $05
					TAX
					LDA $0B
					EOR.l Aim_Not_Flag,x
					CLC
					ADC.l Aim_NotToNeg,x
					STA $0B
					CLC : ADC $08
					CMP #$5B
					BCS	.Over_90Deg
					RTS

.Over_90Deg:		PHA
					LDA $0B
					BMI .Minus_Deg
					LDA $05
					EOR #$01
					STA $05
					PLA
					EOR #$FF
					INC
					SBC #$4C
					RTS
					
.Minus_Deg:			LDA $04
					EOR #$01
					STA $04
					PLA
					EOR #$FF
					INC
					RTS
