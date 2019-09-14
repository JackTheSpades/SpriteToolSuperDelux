;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; SpawnSpinningCoin:
;;    Spawns a spinning coin in the highest free slot and automatically sets its
;;    position relative to the sprite which spawned it.
;;
;; Input:
;;    A (8-bit): Spinning coin number to spawn (note that you need a custom patch to use coin other than SMW's only one)
;;    X (8-bit): Index of the current normal sprite
;;    $00: X Offset
;;    $01: Y Offset
;;
;; Output:
;;    Y (8-bit): Index of the new spinning coin or $FF if no slot was found
;;    Carry: Set if the spinning coin couldn't be spawned
;;
;; Clobbers:
;;    A
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	XBA
	LDY #$03
-	LDA $17D0|!Base2,y
	BEQ +
	DEY
	BPL -
	SEC
	RTL

+	XBA
	STA $17D0|!Base2,y
	JSL $05B34A|!BankB
	LDA !D8,x
	CLC : ADC $01
	STA $17D4|!Base2,y
	LDA #$00
	BIT $01
	BPL +
	DEC
+	ADC !14D4,x
	STA $17E8|!Base2,y
	LDA !E4,x
	CLC : ADC $00
	STA $17E0|!Base2,y
	LDA #$00
	BIT $00
	BPL +
	DEC
+	ADC !14E0,x
	STA $17EC|!Base2,y
	LDA $1933|!Base2
	STA $17E4|!Base2,y
	LDA #$D0
	STA $17D8|!Base2,y
	CLC
	RTL

