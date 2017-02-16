
;original cluster sprite tool code by Alcaro
;slight modification and sa-1 compability by JackTheSpades

org $80A686
	JML NotQuiteMain

org $82F815
	JML Main

;-----------;
; Custom Rt ;
;-----------;

;TOOL LINE: freespace
db "STAR"
dw $8000-8-1
dw $8000-8-1^$FFFF;we want to reserve an entire bank so we know we can use that area later

Main:
LDA $0100             ; \ If in mosaic routine, don't run sprite.
CMP #$13              ;  |
BEQ Return            ; /
LDA $1892,x           ; \ Check if $1892,x is 00 (free slot). If so, return.
BEQ Return            ; /
CMP #$09              ; \ Check if >=09.
BCS Custom            ; / If so, run custom cluster sprite routine.
PEA $F81C             ; \ Go to old pointer.
JML $82F821           ; /

NotQuiteMain:
STZ $149A             ; Hijack code.
STZ $1498             ;
REP #$20
LDX #$9E              ; \ Set $1E02-$1EA1 to zero on level load.

Looplooploop:
STZ $1E02,x           ;  |
DEX                   ;  |
DEX                   ;  |
BNE Looplooploop      ; /
SEP #$20
JML $80A68C           ; Return.

Custom:
PHB                   ; \ Wrapper.
PHK                   ;  |
PLB                   ; /
SEC                   ; \ Subtract 9. (Also allows you to use slots up to $88 instead of $7F in this version.)
SBC #$09              ; / (Not that you'll ever use all of them though)
PHX                   ; \ Preserve X and Y.
PHY                   ; /
TXY                   ; 
ASL A		      ; Jump jump jump.
TAX                   ;
JSR (Ptr,x)           ;
PLY                   ; Pull everything back and return.
PLX
PLB

Return:
JML $82F81D

;--------------------------;
; Pointers. Do not adjust. ;
;--------------------------;

Ptr:
;TOOL LINE: pointers

;TOOL LINE: codes

;TOOL LINE: warnpc