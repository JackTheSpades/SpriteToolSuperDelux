
;original cluster sprite tool code by Alcaro
;slight modification and sa-1 compability by JackTheSpades

incsrc "sa1def.asm"

org $00A686
	autoclean JML NotQuiteMain
	autoclean dl Ptr      ; org $0x00A68A, default dl $9C1498

org $02F815
	autoclean JML Main


freecode
NotQuiteMain:
	STZ $149A|!Base2      ; \ Hijack restore code.
	STZ $1498|!Base2      ; | 
	STZ $1495|!Base2      ; /
	REP #$20
	LDX #$9E              ; \ Set $1E02-$1EA1 to zero on level load.
.loop                    ; |
	STZ $1E02|!Base2,x    ; |
	DEX                   ; |
	DEX                   ; |
	BNE .loop             ; /
	SEP #$20
	JML $00A68F|!BankB    ; Return.


Main:
	LDA $0100|!Base2      ; \ If in mosaic routine, don't run sprite.
	CMP #$13              ;  |
	BEQ .return           ; /
	LDA $1892|!Base2,x    ; \ Check if $1892,x is 00 (free slot). If so, return.
	BEQ .return           ; /
	CMP #$09              ; \ Check if >=09.
	BCS .custom           ; / If so, run custom cluster sprite routine.
	PEA $F81C             ; \ Go to old pointer.
	JML $02F821|!BankB    ; /


.custom:
	;PHB : PHK : PLB       ; magic bank wrapper
	SEC                   ; \ Subtract 9. (Also allows you to use slots up to $88 instead of $7F in this version.)
	SBC #$09              ; / (Not that you'll ever use all of them though)
	PHX                   ; \ Preserve X and Y.
	PHY                   ; /
	
	TXY                   ; save x in y
	STA $00               ; \
	ASL A		             ; |
	CLC : ADC $00         ; | x = A*3
	TAX                   ; /
	
	LDA.l Ptr+0,x : STA $00
	LDA.l Ptr+1,x : STA $01
	LDA.l Ptr+2,x : STA $02		
	TYX	                ; put y back in x
	
	PHB : PHA : PLB       ; set bank to cluster sprite bank	
	PHK                   ; \
	PEA ..return-1        ; | because there is no JSL [$xxxx]
	JML [!Base1]          ; |
..return                 ; /
	
	PLB
	PLY                   ; \ 
	PLX                   ; / Pull everything back and return.

.return:
	JML $02F81D|!BankB


Ptr:
	incbin "_ClusterPtr.bin"