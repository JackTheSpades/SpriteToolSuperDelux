; From Ladida's cluster sprite package. Slightly modified.
;
; Cluster sprite number is set in the CFG file as extra property byte 1.

!SpikeCount       = $09   ; Amount of sprites to fall down, -1. Values outside of 00-13 are not recommended.

print "INIT ",pc

	PHY                    ; \ Wrapper for bank (and preserve Y for some reason)
	PHB                    ; |
	PHK                    ; |
	PLB                    ; /

	LDY #!SpikeCount
-
	LDA !extra_prop_1,x    ; \ set cluster sprite number
	CLC                    ; |
	ADC #!ClusterOffset    ; | add offset due to original cluster sprites.
	STA !cluster_num,y     ; /

	LDA InitXY,y           ; \ Initial X and Y position of each sprite.
	PHA                    ; | Is relative to screen border.
	AND #$F0               ; |
	STA !cluster_x_low,y   ; |
	PLA                    ; |
	ASL #4                 ; |
	STA !cluster_y_low,y   ; /
	
	DEY                    ; \ Loop until all slots are done.
	BPL -                  ; /

	LDA #$01               ; \ Run cluster sprite routine.
	STA $18B8|!Base2       ; /

	PLB                    ; \ restore bank and y
	PLY                    ; /
	RTL                    ; Return.


; Initial X and Y position table of sprites.
; Relative to screen border.
; Format: $xy
InitXY:
db $06,$45,$9E,$E2,$A7,$BC,$59,$40,$61,$F5,$D6,$24,$7B,$33,$C6,$0B,$00,$39,$70,$A1


print "MAIN ",pc
	STZ $14C8,x      ; \ self destruct
	RTL              ; /