
;original extended sprite routine by imamelia
;slight modification and sa-1 compability by JackTheSpades

incsrc "sa1def.asm"
incsrc "pointer_caller.asm"

org $029B1B|!BankB
   autoclean JML Main
   autoclean dl Ptr      ; org $029B1F, default $176FBC
   
freecode
Main:
.sub
   LDY $9D               ; \
   BNE +                 ; | restore code
   LDY !extended_timer,x ; |
   BEQ +                 ; |
   DEC !extended_timer,x ; /
+
   CMP #!ExtendedOffset  ; check if number higher than #$13
   BCC .NotCustom        ;

   SEC
   SBC #!ExtendedOffset  ; 13 is the first custom one
   AND #$7F              ;   
   %CallSprite(Ptr)      ;
   JML $029B15|!BankB    ; JML back to an RTS
   
.NotCustom
   JML $029B27|!BankB    ; execute vanilla code.

;tool generated pointer table
Ptr:
   incbin "_ExtendedPtr.bin"
