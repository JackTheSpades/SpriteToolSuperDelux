
incsrc "sa1def.asm"

if(read1($029B1B|!BankB) != $A4)

   ; cleanup extended sprites themselves.
   ; pointer to the sprite table sits at $029B1B+4 which points to a table containing
   ; 0x80 long sprite pointers to their respective main routines (no init anyway)
   ; so we loop over that and remove any that aren't the default value of $018021 (-> RTL).

   !ExSprPtrs = read3($029B1B+4|!BankB)
   !counter = 0
   !removed = 0

   while !counter < $80    
      if(read3(!ExSprPtrs) != $018021)       ; $018021 being the default address to an RTL used by Pixi for uninserted sprites
         autoclean read3(!ExSprPtrs)         ;
         !removed #= !removed+1
      endif            
      !counter #= !counter+1
      !ExSprPtrs #= !ExSprPtrs+3
   endif

   print "Removed ",dec(!removed)," extended sprites."

   ; cleanup freespace used by extended patch itself.
   autoclean read3($029B1B+4|!BankB)

   ; restore vanilla game code.
   org $029B1B|!BankB
      LDY $9D
      BNE $08           
      LDY.W $176F|!Base2,x
   
else
   print "Extended patch has not been installed to the ROM."
endif
