@include

macro BigIncBin(binfile, labelname)
	incbin "<binfile>" -> <labelname>
	print "<labelname>_BIGINCBIN:", hex(<labelname>)
endmacro