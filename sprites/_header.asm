@include

macro LDE()
	LDA !extra_bits,x
	AND #$04
endmacro

macro BigIncBin(binfile, labelname)
	incbin "<binfile>" -> <labelname>
	print "<labelname>_BIGINCBIN:", hex(<labelname>)
endmacro