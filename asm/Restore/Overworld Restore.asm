

incsrc "sa1def.asm"

; sort of main guard to check if OW sprites have even been patched.
; if not, well, no real reason to try and unpatch them
;   actually, since we'll try to unpatch all the sprites first by reading their pointers
;   doing this without having previously patched this routine will probably try to delete some important
;   stuff by accident.
if read4($009AA5) != $04F675


!OwSprPtrs = read3($04F677|!BankB)
!counter = 0
!removed = 0

while !counter < $80    
   if(read3(!OwSprPtrs) != $018021)       ; $018021 being the default address to an RTL used by Pixi for uninserted sprites
      autoclean read3(!OwSprPtrs)         ;
      !removed #= !removed+1
   endif            
   !counter #= !counter+1
   !OwSprPtrs #= !OwSprPtrs+3
endif

print "Removed ",dec(!removed)," overworld sprites."

; freespace used by the patch.
autoclean read3($04F677|!BankB)  ; sprite init and main pointer tables.
autoclean read3($04F679|!BankB)  ; sub routines

org $00A165|!BankB
   JSL $04D6E9
org $009AA4|!BankB
   JSL $04F675

org $04F675|!BankB
   
   PHB : PHK : PLB
   LDX.B #$0C
   LDY.B #$4B
   
Beginning:
   LDA.W $F616,Y
   STA.W $0DE8,X
   CMP.B #$01
   BEQ +
   CMP.B #$02
   BNE ++
+
   LDA.B #$40
   STA.W $0E58,X
++
   LDA.W $F617,Y
   STA.W $0E38,X
   LDA.W $F618,Y
   STA.W $0E68,X
   LDA.W $F619,Y
   STA.W $0E48,X
   LDA.W $F61A,Y
   STA.W $0E78,X
   TYA
   SEC : SBC.B #$05
   TAY
   DEX
   BPL Beginning
   LDX.B #$0D
   
--
   STZ.W $0E25,X
   LDA.W $FD22
   DEC A
   STA.W $0EB5,X
   LDA.W $F665,X
-
   PHA
   STX.W $0DDE
   JSR.W $F853
   PLA
   DEC A
   BNE -
   INX
   CPX.B #$10
   BCC --
   PLB
   RTL

DATA_04F6D0:
   db $70,$7F,$78,$7F,$70,$7F,$78,$7F
DATA_04F6D8:
   db $F0,$FF,$20,$00,$C0,$00,$F0,$FF
   db $F0,$FF,$80,$00,$F0,$FF,$00,$00
DATA_04F6E8:
   db $70,$00,$60,$01,$58,$01,$B0,$00
   db $60,$01,$60,$01,$70,$00,$60,$01

   
   warnpc $04F6F8|!BankB
endif



;org $04F675|!BankB
   ; db $8B, $4B, $AB, $A2, $0C, $A0, $4B, $B9
   ; db $16, $F6, $9D, $E8, $0D, $C9, $01, $F0
   ; db $04, $C9, $02, $D0, $05, $A9, $40, $9D
   ; db $58, $0E, $B9, $17, $F6, $9D, $38, $0E
   ; db $B9, $18, $F6, $9D, $68, $0E, $B9, $19
   ; db $F6, $9D, $48, $0E, $B9, $1A, $F6, $9D
   ; db $78, $0E, $98, $38, $E9, $05, $A8, $CA
   ; db $10, $CD, $A2, $0D, $9E, $25, $0E, $AD
   ; db $22, $FD, $3A, $9D, $B5, $0E, $BD, $65
   ; db $F6, $48, $8E, $DE, $0D, $20, $53, $F8
   ; db $68, $3A, $D0, $F5, $E8, $E0, $10, $90
   ; db $E3, $AB, $6B, $70, $7F, $78, $7F, $70
   ; db $7F, $78, $7F, $F0, $FF, $20, $00, $C0
   ; db $00, $F0, $FF, $F0, $FF, $80, $00, $F0
   ; db $FF, $00, $00, $70, $00, $60, $01, $58
   ; db $01, $B0, $00, $60, $01, $60, $01, $70
   ; db $00, $60, $01
