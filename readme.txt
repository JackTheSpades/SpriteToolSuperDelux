Sprite Tool Super Delux (or STSD for short) is an updated version of romi's sprite tool.
The mayor advantages of this version compared to romi's are:

	* sa-1 check/compability and default labels within the sprites
	* softcoded. Code that gets inserted is available as .asm files and can be edited.
	* shared routines. This one was 99% stolen, er I mean borrowed from p4plus2's GPS.
	* per level sprites. More info below.
	* asar only, so no more TRASM (yes, that's a good thing)
	

- Usage
-- Normal Sprites
	The usage is essentially copied from GPS (because common behaviour and usage of tools is nice).
	You create a file called "list.txt". In it, you define the sprites you want to insert into your rom
	and the sprite number you want to give them like this: id SPACE cfg_file	
	(NOTE: you can't put comments in the actual list file, this is just for demonstration!!!!)
	
		00 Blue.cfg				;insert sprite Blue.cfg on sprite number 00
		01 Green.cfg			;insert sprite Green.cfg on number 01
		C0 Shooter.cfg			;insert shooter
		D0 Generator.cfg		;insert generator
		
	Keep in mind that the areas for sprites (00-BF), shooters (C0-CF) and generators (D0-FF) are fixed.
	So if you want to insert a shooter, it has to be in the range of C0 to CF.
		
-- Per Level Sprites
	The slots B0 to BF are special, in that you have to assign a level to them. The sprite will only use
	the slot for that level. So you can assign sprite B0 of level 105 to a thwomp and B0 of level 106 to
	a hammer bro. Keep in mind that the id has to be inbetween B0 and BF for this
	The format goes like this: level COLON id SPACE cfg_file
	(NOTE: again, you can't put comments in the actual list file, this is just for demonstration!!!!)
	
		00 Blue.cfg				;insert sprite Blue.cfg on sprite number 00
		01 Green.cfg			;insert sprite Green.cfg on number 01

		105:B0 Red.cfg			;insert sprite Red.cfg on sprite number B0 for level 105
		105:B1 Yellow.cfg		;insert sprite Yellow.cfg on sprite number B1 for level 105
		106:B0 Boo.cfg			;insert sprite Boo.cfg on sprite number B0 for level 106
									;sprite number B1 is unused in level 106
	
-- Default Paths/Files
	The tool assumes a lot of default paths and files. You can change them when calling the tool from
	the command line interface.
	This is copy of the output when calling stsd.exe --help
	
		Usage: STSD <options> <ROM>
		Options are:
		-d              Enable debug output
		-k              Keep debug files
		-l <listpath>   Specify a custom list file (Default: list.txt)
		-p <sprites>    Specify a custom generators directory (Default sprites/)
		-o <shooters>   Specify a custom generators directory (Default shooters/)
		-g <generators> Specify a custom generators directory (Default generators/)
		-s <sharedpath> Specify a shared routine directory (Default routines/)
		
	Example:
		
		stsd.exe -l newlistfile.txt rom.smc
		
		
		
		
	
- New Stuff
-- SA-1 detection and default labels
	The file asm/sa1defs.asm contains all the necessary defines and macros for coding sprites.
	The file will be included by default in any sprite, so you don't have to manually do that for
	every sprite you code.
	
	You can check the file out yourself, but the most important stuff is the usual !Base1 and !Base2
	defines, two !SA1 and !SA_1 defines (just to avoid spelling errors) and a define !SprSize for
	the total amount of sprites. It's either $0C or $16.
	
	Furthermore, there are defines for all sprite tables either by address or by name. The two lines
	below both do the same (note that it's !9E and not $9E)
	
		LDA !9E,x
		LDA !sprite_num,x
	
-- Per Level Sprites
	Now what do I mean with this? It means, I've sacrificed 16 normal sprite slots (B0-BF) to make room
	for slots that can change depending on the level.
	For example, sprite B0 could be a horizontal thwomp in level 105 and a hammer bro in level 106, or
	a birdo in level 107.
	All in all the 16 slots from B0 to BF can be different for any level from 000 to 1FF. Including the
	global srites from 00-AF and C0-FF that is $F0+$200*$10= $20F0 or 8432 sprites you can use in your
	hack... I think your rom will be full before you can even reach that number.
	Consequentially, you can also use the per level sprites within shooters. A shooter that shoots sprite
	B0 will spawn something different depending on it's level (the shooter is the same for all levels
	though)
	
-- CFG files
	The cfg files haven't really changed at all, but the assembler bit is now unused, as it will always
	use asar, no questions asked.
	99.9% of the time, xkas code will work just fine with asar, the other 0.1% is either relying on
	faulty xkas math or the usage of codes like this
	
		JMP (label,x)
		JSR (label,x)
		
	Which asar can't resolve, you need to make it JMP.w or JSR.w for it to work.
	