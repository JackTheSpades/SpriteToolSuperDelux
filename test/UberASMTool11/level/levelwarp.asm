
!Counter = $58    ;needs to be DB or Long (2 or 6 digits, not 4)
table table.txt

if read1($00FFD5) == $23
   !SA1 = 1
	!Base2 = $6000
else
   !SA1 = 0
	!Base2 = $0000
endif

init:
   ;LDA #$00             ; \ Reset Counter
   ;STA !Counter         ; / if you want
   RTL

main:

   LDA $16              ; \
   ORA $18              ; | branch if neither A nor B is being pressed
   AND #$80             ; |
   BEQ +                ; /
 
   REP #$30             ; \
   LDA !Counter         ; |
   AND #$00FF           ; |
   ASL                  ; | Get level to teleoprt to.
   TAX                  ; |
   LDA.l TableLevels,x  ; |
   SEP #$30             ; /
   
   ;warp
	LDX $95			      ; \
	STA $19B8|!Base2,x   ; |
	XBA				      ; | Teleport the player to level.
   ORA #$04             ; |
	STA $19D8|!Base2,x   ; |
	LDA #$06			      ; |
	STA $71			      ; |
	STZ $89			      ; |
	STZ $88			      ; /
   RTL   
+

   LDA $16              ; \
   AND #$03             ; |
   TAX                  ; | increase or decrease counter based on
   LDA.l Add,x          ; | pushing left or right.
   CLC                  ; |
   ADC !Counter         ; /
   
   CMP #$FF                                  ; \
   BNE +                                     ; |
   LDA.b #(TableLevels_end-TableLevels)/2-1  ; |
   BRA ++                                    ; | Limit A to [0, n) with n being the number of
+  CMP.b #(TableLevels_end-TableLevels)/2    ; | options available and have it loop around.
   BNE ++                                    ; |
   LDA #$00                                  ; /
++
   STA !Counter         ; /

   PHB
if !SA1 = 1
   PEA $4141
else
   PEA $7F7F
endif
   PLB : PLB

   REP #$30          ; A,X,Y in 16bit mode
   LDY $837B         ; stripe index in Y
      
   ;sripe upload header
   LDA #$0258        ; layer 3, 
   STA $837D+0,y     ;
   LDA #$1F00        ; uploading 32 bytes of data
   STA $837D+2,y     ;
      
   ;get table offset in X
   LDA !Counter
   AND #$00FF
   ASL #4
   TAX
   SEP #$20
   
   ;loop counter
   LDA #$0F
   STA $00
   
.loop
   LDA.l TableNames,x   ; \ 
   STA $837D+4,y        ; | Write letter to stripe upload
   LDA #$38             ; | yxpccctt = 0011-1000
   STA $837D+5,y        ; /
   
   INX
   INY : INY
   
   DEC $00
   BPL .loop
   
   ;stripe terminator
   LDA #$FF
   STA $837D+4,y
   
   ;update index and store back
   INY : INY
   INY : INY
   STY $837B
   
   PLB   
   SEP #$10
   
   RTL
   
;values to add when pressing left or right
Add:
   db $00, $01, $FF, $00
   
   
; Names, always 16 byte
; Use capital letters only
TableNames:
   db "BROS            "
   db "CLUSTER-FISH    "
   db "CLUSTER-FLOWER  "
   db "CLUSTER-RAIN    "
   db "CLUSTER-SAND    "
   db "BULLET BILL     "
   
   
macro level(level, midway)
   dw <level>|(<midway><<11)
endmacro

macro secen(num, water)
   dw <num>&$FF|((<num>&$F00)<<12)|(<water><<11)|$200
endmacro
   
; note, add $800 to go to midpoint (needs seperate midpoint settings enabled)
; or see https://www.smwcentral.net/?p=nmap&m=smwram#7E19D8 for more details on the high byte.
TableLevels:
   %level($0001, 0)
   %secen($0000, 1)
   %secen($0001, 0)
   %secen($0002, 0)
   %secen($0003, 0)
   %level($0003, 0)
.end
