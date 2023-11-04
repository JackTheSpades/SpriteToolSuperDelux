
;Input:  A   = type of speed update
;              0 ... x+y with gravity
;              1 ... x+y without gravity
;              2 ... x only
;              3 ... y only

?main:
   BEQ ?.XY_Speed
   DEC : BEQ ?.XY_SpeedNoGravity
   DEC : BEQ ?.X_Speed
   BRA ?.Y_Speed
   RTL
   
?.X_Speed:
PHX
TXA
CLC
ADC #!ClusterSize	; YSpeed to XSpeed
TAX
JSL ?.Y_Speed
PLX
RTL

?.XY_Speed:
LDA !cluster_misc_1e52,x	; YSpeed
BMI $04
CMP #$40 : BPL ?.XY_SpeedNoGravity
CLC : ADC #$02
STA !cluster_misc_1e52,x	; YSpeed

?.XY_SpeedNoGravity:
PHX
TXA
CLC
ADC #$14	; YSpeed to XSpeed
TAX
JSL ?.Y_Speed
PLX

?.Y_Speed:
LDA !cluster_misc_1e52,x	; YSpeed
ASL #4
CLC
ADC !cluster_misc_1e7a,x	; YSpeed fraction
STA !cluster_misc_1e7a,x	; YSpeed fraction
PHP
LDY #$00
LDA !cluster_misc_1e52,x	; YSpeed
LSR #4
CMP #$08
BCC ?+
ORA #$F0
DEY
?+
PLP
ADC !cluster_y_low,x	; Yposition Low byte.
STA !cluster_y_low,x	; Yposition Low byte.
TYA
ADC !cluster_y_high,x	; Yposition High byte.
STA !cluster_y_high,x	; Yposition High byte.
RTL
