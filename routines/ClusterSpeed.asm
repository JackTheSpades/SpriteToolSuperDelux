
;Input:  A   = type of speed update
;              0 ... x+y with gravity
;              1 ... x+y without gravity
;              2 ... x only
;              3 ... y only

?main:
   BEQ ?.XY_Speed
   DEC : BEQ ?.XY_SpeedNoGravity
   DEC : BEQ ?.X_Speed
   DEC : BEQ ?.Y_Speed
   RTL
   
?.X_Speed:
PHY
TYA
CLC
ADC #!ClusterSize	; YSpeed to XSpeed
TAY
JSL ?.Y_Speed
PLY
RTL

?.XY_Speed:
LDA !cluster_misc_1e52,y	; YSpeed
CMP #$40 : BPL ?.XY_SpeedNoGravity
CLC : ADC #$02
STA !cluster_misc_1e52,y	; YSpeed

?.XY_SpeedNoGravity:
PHY
TYA
CLC
ADC #$14	; YSpeed to XSpeed
TAY
JSL ?.Y_Speed
PLY

?.Y_Speed:
LDA !cluster_misc_1e52,y	; YSpeed
ASL #4
CLC
ADC !cluster_misc_1e7a,y	; YSpeed fraction
STA !cluster_misc_1e7a,y	; YSpeed fraction
PHP
LDX #$00
LDA !cluster_misc_1e52,y	; YSpeed
LSR #4
CMP #$08
BCC ?+
ORA #$F0
DEX
?+
PLP
ADC !cluster_y_low,y	; Yposition Low byte.
STA !cluster_y_low,y	; Yposition Low byte.
TXA
ADC !cluster_y_high,y	; Yposition High byte.
STA !cluster_y_high,y	; Yposition High byte.
RTL
