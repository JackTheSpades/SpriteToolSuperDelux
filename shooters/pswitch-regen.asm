;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Regenerating P-Switch, by yoshicookiezeus
;;
;; Description: This shooter generates a P-Switch at its position, but
;; only if there doesn't already exist another P-Switch of the same type
;; and a P-Switch of the same type isn't active.
;;
;; Uses first extra bit: YES
;; If the extra bit is clear, a blue P-Switch is spawned; if it is set,
;; a silver one is spawned instead. Both types can be used alongside each other.
;;  
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; defines - don't mess with these
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	!RAM_ScreenBndryXLo	= $1A
	!RAM_ScreenBndryXHi	= $1B
	!RAM_ScreenBndryYLo	= $1C
	!RAM_ScreenBndryYHi	= $1D

	!RAM_MarioXPos		= $94

	!RAM_SpriteNum		= $9E
	!RAM_SpriteSpeedY	= $AA
	!RAM_SpriteSpeedX	= $B6
	!RAM_SpriteState	= $C2
	!RAM_SpriteYLo		= $D8
	!RAM_SpriteXLo		= $E4
	!RAM_SpriteStatus	= $14C8
	!RAM_SpriteYHi		= $14D4
	!RAM_SpriteXHi		= $14E0
	!RAM_SpritePal		= $15F6

	!RAM_BluePSwitchTimer	= $14AD

	!RAM_ShooterNum		= $1783
	!RAM_ShooterYLo		= $178B
	!RAM_ShooterYHi		= $1793
	!RAM_ShooterXLo		= $179B
	!RAM_ShooterXHi		= $17A3
	!RAM_ShooterTimer	= $17AB

	!RAM_SmokeNum		= $17C0
	!RAM_SmokeYLo		= $17C4
	!RAM_SmokeXLo		= $17C8
	!RAM_SmokeTimer		= $17CC


	!FindFreeSlotLowPri	= $02A9DE
	!InitSpriteTables	= $07F7D2

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; sprite code JSL
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
	print "INIT ",pc	                
	print "MAIN ",pc
	PHB	 
	PHK	 
	PLB	 
	JSR Main
	PLB	 
	RTL      

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; main bullet bill shooter code
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;               

PSwitchPalettes:
	db $06, $02

Main:
	LDA !RAM_ShooterNum,x		;\  get extra bit
	AND #$40			; |
	LSR				; |
	LSR				; |
	LSR				; |
	LSR				; |
	LSR				; |
	LSR				; |
	TAY				; |
	LDA !RAM_BluePSwitchTimer,y	; | if appropriate p-switch is active,
	BNE Return2			;/ return
	STY $00

	LDY #$09			; check if appropriate p-switch type already exists in level
LoopStart:
	LDA !RAM_SpriteStatus,y
	BEQ Next
	LDA.w !RAM_SpriteNum,y
	CMP #$3E
	BNE Next
	LDA $00
	CMP $151C,y
	BEQ Return2
Next:
	DEY
	BPL LoopStart
	BRA Spawn
Return2:
	RTS
	
Spawn:
	LDA !RAM_ShooterYLo,x		;\ don't generate if off screen vertically
	CMP !RAM_ScreenBndryYLo		; |
	LDA !RAM_ShooterYHi,x		; |
	SBC !RAM_ScreenBndryYHi		; |
	BNE Return			;/
	LDA !RAM_ShooterXLo,x		;\ don't generate if off screen horizontally
	CMP !RAM_ScreenBndryXLo		; |
	LDA !RAM_ShooterXHi,x		; |
	SBC !RAM_ScreenBndryXHi		; |
	BNE Return			;/
	LDA !RAM_ShooterXLo,x		;\ don't generate if partway off screen?
	SEC				; | 
	SBC !RAM_ScreenBndryXLo		; |
	CLC				; |
	ADC #$10			; |
	CMP #$10			; |
	BCC Return			;/
	LDA !RAM_MarioXPos		;\ don't generate if Mario is next to generator
	SBC !RAM_ShooterXLo,x		; |
	CLC				; |
	ADC #$11			; |
	CMP #$22			; |
	BCC Return			;/
	JSL !FindFreeSlotLowPri		;\ get an index to an unused sprite slot, return if all slots full
	BMI Return			;/ after: Y has index of sprite being generated

	LDA #$03			;\ play sound effect
	STA $1DFC			;/
	LDA #$0A			;\ set sprite status for new sprite
	STA !RAM_SpriteStatus,y		;/
	LDA #$3E			;\ set sprite number for new sprite
	STA.w !RAM_SpriteNum,y		;/

	LDA !RAM_ShooterXLo,x		;\ set x position for new sprite
	STA.w !RAM_SpriteXLo,y		; |
	LDA !RAM_ShooterXHi,x		; |
	STA.w !RAM_SpriteXHi,y		;/
	LDA !RAM_ShooterYLo,x		;\ set y position for new sprite
	STA.w !RAM_SpriteYLo,y		; |
	LDA !RAM_ShooterYHi,x		; |
	STA.w !RAM_SpriteYHi,y		;/

	PHX				;\ before: X must have index of sprite being generated
	TYX				; | routine clears *all* old sprite values...
	JSL !InitSpriteTables		;/ ...and loads in new values for the 6 main sprite tables

	LDA $00				;\ set P-switch type
	STA $151C,y			;/
	TAX
	LDA PSwitchPalettes,x		;\ set P-switch palette
	STA !RAM_SpritePal,y		;/
	PLX
	
	JSR SpawnSmoke			; display smoke graphic
Return:
	RTS


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; display smoke effect for bullet bill shooter
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SpawnSmoke:
	LDY #$03			; find a free slot to display effect
.LoopStart
	LDA !RAM_SmokeNum,y
	BEQ .FoundSlot
	DEY
	BPL .LoopStart
	RTS				; return if no slots open

.FoundSlot
	LDA #$01			;\ set effect graphic to smoke graphic
	STA !RAM_SmokeNum,y		;/
	LDA !RAM_ShooterYLo,x		;\ smoke y position = generator y position
	STA !RAM_SmokeYLo,y		;/
	LDA !RAM_ShooterXLo,x		;\ smoke x position = shooter x position
	STA !RAM_SmokeXLo,y		;/
	LDA #$1B			;\ set time to show smoke
	STA !RAM_SmokeTimer,y		;/
	RTS	 

