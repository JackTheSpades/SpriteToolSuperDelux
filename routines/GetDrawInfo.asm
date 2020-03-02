;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; This is a helper for the graphics routine.  It sets off screen flags, and sets up
; variables.
;
; Output:
;	Y = index to sprite OAM ($300)
;	$00 = sprite x position relative to screen boarder
;	$01 = sprite y position relative to screen boarder  
;
; It is adapted from the subroutine at $03B760
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

   LDA !14E0,x
   XBA
   LDA !E4,x
   REP #$20
   SEC : SBC $1A
   STA $00
   CLC
   ADC.w #$0040
   CMP.w #$0180
   SEP #$20
   LDA $01
   BEQ ?+
     LDA #$01
   ?+
   STA !15A0,x
   TDC
   ROL A
   STA !15C4,x
   BNE .Invalid

   LDA !14D4,x
   XBA
   LDA !190F,x
   AND #$20
   BEQ .CheckOnce
.CheckTwice
   LDA !D8,x
   REP #$21
   ADC.w #$001C
   SEC : SBC $1C
   SEP #$20
   LDA !14D4,x
   XBA
   BEQ .CheckOnce
   LDA #$02
.CheckOnce
   STA !186C,x
   LDA !D8,x
   REP #$21
   ADC.w #$000C
   SEC : SBC $1C
   SEP #$21
   SBC #$0C
   STA $01
   XBA
   BEQ .OnScreenY
   INC !186C,x
.OnScreenY
   LDY !15EA,x
   RTL
 
.Invalid
   PLA             ; destroy the JSL
   PLA
   PLA
   PLA             ; sneak in the bank
   PLY
   PHB
   PHY
   PHA
   RTL
