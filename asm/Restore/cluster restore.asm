
incsrc "sa1def.asm"

if(read1($00A686|!BankB) != $9C)

   ; cleanup cluster sprites themselves.
   ; pointer to the sprite table sits at $00A686+4 which points to a table containing
   ; 0x80 long sprite pointers to their respective main routines (no init anyway)
   ; so we loop over that and remove any that aren't the default value of $018021 (-> RTL).

   !ClusterSprPtrs = read3($00A686+4|!BankB)
   !counter = 0
   !removed = 0

   while !counter < $80    
      if(read3(!ClusterSprPtrs) != $018021)        ; \ 
         autoclean read3(!ClusterSprPtrs)          ; | $018021 being the default address to an RTL used by Pixi for uninserted sprites
         !removed #= !removed+1                    ; / keep count of removed sprites
      endif            
      !counter #= !counter+1                       ;
      !ClusterSprPtrs #= !ClusterSprPtrs+3         ; move to next pointer
   endif

   print "Removed ",dec(!removed)," cluster sprites."

   ; cleanup freespace used by cluster pointer table itself.
   autoclean read3($00A686+4|!BankB)
   ; cleanup freecode used by the patch.
   autoclean read3($00A686+1|!BankB)   

   ; restore vanilla game code.
   org $00A686|!BankB ;(7 bytes)
      STZ $149A|!Base2              ; \ 
      STZ $1498|!Base2              ; | 
      STZ $1495|!Base2              ; |      
   org $02F815|!BankB ;(4 bytes)    ; | Hijack restore code.
      LDA.w $1892|!Base2,x          ; |
      BEQ $03                       ; /
   
else
   print "Cluster patch has not been installed to the ROM."
endif
