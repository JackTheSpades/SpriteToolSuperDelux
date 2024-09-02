
;Input:  A   = type of speed update
;              0 ... x+y with gravity (YSpeed +3 exery flame)
;              1 ... x+y without gravity
;              2 ... x only
;              3 ... y only
;              4 ... x+y with low gravity (YSpeed +1 exery flame)
;              5 ... x+y with gravity (YSpeed +2 exery flame)
;              6 ... x+y with gravity (YSpeed +3 exery flame)(Same as 0)
;              7 ... x+y with high gravity (YSpeed +4 exery flame)


?main:
   CMP #$04 : BCS ?+ : CMP #$00
   BEQ ?.XY_Speed
   DEC : BEQ ?.XY_SpeedNoGravity
   DEC : BEQ ?.X_Speed
   BRA ?.Y_Speed
?+ SBC #$03
   LDY !cluster_misc_1e52,x
   BMI $04
   CPY #$40 : BPL ?.XY_SpeedNoGravity
   CLC : ADC !cluster_misc_1e52,x
   STA !cluster_misc_1e52,x
   BRA ?.XY_SpeedNoGravity
   
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
CLC : ADC #$03
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
