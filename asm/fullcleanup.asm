

if read1($01C4CB) == $5C
	print "Remove poison mushroom hurt routine."
	autoclean read3($01C4CC)
		CMP.b #$21                
		BNE $69
endif

if read1($01C6D6) == $22
	print "Remove poison mushroom GFX routine."
	autoclean read3($01C6D7)
		TAX
		LDA.W $C609,X
endif

