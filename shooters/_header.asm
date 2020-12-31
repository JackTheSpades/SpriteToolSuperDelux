@include

macro LDE()
	LDA !shoot_num,x
	AND #$40
endmacro

macro BigIncBin(binfile, labelname)
	incbin "<binfile>" -> <labelname>
	print "<labelname>_BIGINCBIN:", hex(<labelname>)
endmacro