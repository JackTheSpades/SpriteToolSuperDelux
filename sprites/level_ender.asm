;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Level end trigger, by mikeyk
;; asar and sa-1 compability by JackTheSpades
;;
;; Description: This sprite will cause the level to end when all the enemies on screen
;; are killed.  This version ignnores sprites that don't turn into a coin when the goal
;; tape is passed.
;;
;; Uses first extra bit: YES
;; When the first extra bit is clear, the sprite will trigger the regular exit.  When it
;; is set, the sprite will trigger the secret exit.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;                          

                    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; sprite init JSL
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

print "INIT ",pc
		RTL                 


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; sprite code JSL
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

print "MAIN ",pc

Main:
		LDA $1493|!Base2
		BNE Return
		LDA $13C6|!Base2
		BNE Return

		LDY #!SprSize-1
.loop
		LDA !14C8,y
		CMP #$08
		BCS .tweaker
.continue
		DEY
		BPL .loop

		LDA #$FF                ; \ set time before Return to overworld
		STA $1493|!Base2        ; /
		LDA !extra_bits,x       ; set secret exit if first extra bit is set
		LSR #3
		AND #$01
		EOR #$01
		STA $141C|!Base2

		LDA !extra_prop_1,x
		CMP #$01
		BEQ +
		DEC $13C6|!Base2        ; prevent mario from walking at level end
+
		LDA !extra_prop_2,x
		STA $1DFB|!Base2       
	
.tweaker
		LDA !1686,y
		AND #$20
		BNE .continue
Return:
		RTL                    

