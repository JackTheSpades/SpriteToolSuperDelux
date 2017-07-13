
;original extended sprite routine by imamelia
;slight modification and sa-1 compability by JackTheSpades

incsrc "sa1def.asm"
incsrc "pointer_caller.asm"

org $029B1B
	autoclean JML Main
	autoclean dl Ptr      ; org $029B1F, default $176FBC
	
freecode
Main:
.sub

	CMP #$13              ;
	BCC .NotCustom        ;

	SEC : SBC #$13        ; 13 is the first custom one
	AND #$7F              ;	
	%CallSprite(Ptr)      ;
	JML $029B15           ; JML back to an RTS
	
.NotCustom
	LDY $9D               ; \
	BNE +                 ; | restore code
	LDY $176F|!Base2,x    ; /
	JML $029B22           ; check if timer is to be decreases.
+	JML $029B27           ; execute vanilla code.

;tool generated pointer table
Ptr:
	incbin "_ExtendedPtr.bin"
