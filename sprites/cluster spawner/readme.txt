Extra property byte 1 (or the 1st value in the 4th line when opening in text editor)
is the number the cluster sprite got inserted at.
So, for example, if you inserted flower.asm in cluster slot 04, then flowerspawn.cfg looks like this:

01
36
00 B7 33 BF 01 00
04 00
clusterspawn.asm
00:00