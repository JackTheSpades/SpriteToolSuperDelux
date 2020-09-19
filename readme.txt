PIXI is a tool to insert custom sprites into Super Mario World ROMs.
It assembles using Asar, meaning TRASM sprites are not supported.

ReadMe Contents:
- The List File
-- Normal Sprites
-- Per-Level Sprites
-- Other sprite types (cluster/extended)

- Sprite Insertion
-- Opening pixi.exe
-- Using the Command Prompt

- New Additions and Changes
-- Custom status handling and extra property bytes
-- Softcoding
-- Per-Level Sprites
-- SA-1 Detection and Default Labels
-- CFG Files and the new CFG Editor
-- JSON Files
-- Shared Routines
-- Header Files
-- Extra Bytes
-- Extend PIXI (extra defines and hijacks)

- Common Errors
-- JMP (label,x) or JSR (label,x)
-- JMP $xxxxxx
-- Faulty Math or Wrong Register size (inserts fine but crashes in-game)
-- incsrc/incbin file not found






- The List File
-- Normal Sprites
	To let the tool know which sprites you want to insert in which sprite slots, you have to open the file
	called "list.txt" or create a new one. In it, you define the sprites you want to insert into your ROM and the sprite
	number you want to give them. The format is as follows:
	
    id SPACE cfg_file
	
	For example, a "list.txt" that should insert Blue.cfg to sprite number 00, Green.cfg to sprite number 01
	and Shooter.cfg to C0 with Generator.cfg at D0 would look as such:
	
		00 Blue.cfg
		01 Green.cfg
		C0 Shooter.cfg
		D0 Generator.cfg
	
	Keep in mind that the areas for sprites (00-BF), shooters (C0-CF) and generators (D0-FF) are fixed.
	If you want to insert a shooter, it has to be in the range of C0 to CF due to the sprite type's different coding.
		

-- Per-Level Sprites (has to be enabled with -pl)
	The slots B0 to BF are special, in that if you assign a level to them, they will become per-level sprites. The sprite will only use
	the sprite slot between B0 and BF in that one specified level. Meaning you can assign sprite slot B0 of level 105
	to a Thwomp and B0 of level 106 to a Hammer Bro if you wanted. Keep in mind this only holds true for slots B0 to BF.
	Do note that per-level sprites support at max 4 extra bytes.
	The format for per-level sprites looks as follows:
	
		level COLON id SPACE cfg_file
	
	Here is an example of a "list.txt" file that inserts Blue.cfg and Green.cfg in the same slots as earlier,
	and then inserts Red.cfg and Yellow.cfg only for level 105, while Boo.cfg uses the same slot as Red.cfg but in level 106:
	
		00 Blue.cfg
		01 Green.cfg

		105:B0 Red.cfg
		105:B1 Yellow.cfg
		106:B0 Boo.cfg

		or 

		B0 Blue.cfg 
		105:B0 Red.cfg

		Note that the above is still perfectly valid, sprite B0 will behave like Blue.asm in any level except for 105, where it will take Red.asm properties and code instead.
		This is because since Pixi 1.3, slots B0-BF are not exclusive to per-level sprites anymore but they can be used by normal sprites aswell instead

-- Other sprite types
	PIXI also has the ability to insert other types of sprites, such as cluster or extended sprites.
	To insert these other types, you just have to change the list type within your list file. This is simply done by a
	type of headline with the all caps type followed by a colon. Valid headlines are: "SPRITE:" (default), "EXTENDED:",
	"CLUSTER:", all without quotes. You probably won't need the SPRITE: header, since it's the default but it's there
	anyway.
	After that header, you can proceed to place sprites just like before, except they are taken from their respective
	directories. An example:

		00 Blue.cfg
		01 Green.cfg

		CLUSTER:
		00 flower.asm
		01 fish.asm

		EXTENDED:
		00 hammer.asm

	Note that cluster and extended sprites use the .asm extension, while normal sprites have .cfg.
	Also keep in mind that shooters and generators are part of the SPRITE: group and are seperated by their slot.

	
- Sprite Insertion
-- Opening pixi.exe
  When opening pixi.exe by double clicking it, a window will open asking you for the location of your Super Mario World ROM.
  If the ROM is in the same folder as PIXI, you can simply type in its name, for example "My Hack.smc" and hit enter.
  Otherwise, you can use your mouse to drag and drop your ROM into PIXI's window and then hit enter to insert all sprites
  specified in the "list.txt" sprite list file explained above.
	
	
-- Using the Command Prompt
  This option is for slightly more advanced users. To open a command prompt window, hold shift and right click the folder PIXI
  is in, then select "Open command window here".
  
	The tool assumes a lot of default paths and files. You can change them when calling the tool from
	the command line interface by typing them as in the example below.
	
		Usage: pixi <options> <ROM>
		Options are:
		-d              Enable debug output
		-out <filename>	This can be placed after "-d" and with it you can define a file to redirect the debug output instead of the prompt. This flag only works if the debug output flag is enabled.
		-k              Keep debug files
		-l  <listpath>  Specify a custom list file (Default: list.txt)
		-pl				Per level sprites - will insert perlevel sprite code
		-npl            Same as the current default, no sprite per level will be inserted, left dangling for compatibility reasons
		-d255spl		disables 255 sprite per level support (won't do the 1938 remap)

		-a  <asm>       Specify a custom asm directory (Default asm/)
		
		-sp <sprites>   Specify a custom sprites directory (Default sprites/)
		-sh <shooters>  Specify a custom shooters directory (Default shooters/)
		-g  <generators>        Specify a custom generators directory (Default generators/)
		-e  <extended>  Specify a custom extended sprites directory (Default extended/)
		-c  <cluster>   Specify a custom cluster sprites directory (Default cluster/)

		-r  <sharedpath>        Specify a shared routine directory (Default routines/)
		
		-ssc <append ssc>       Specify ssc file to be copied into <romname>.ssc
		-mwt <append mwt>       Specify mwt file to be copied into <romname>.mwt
		-mw2 <append mw2>       Specify mw2 file to be copied into <romname>.mw2
		-s16 <base s16>         Specify s16 file to be used as a base for <romname>.s16
		                        Do not use <romname>.xxx as an argument as the file will be overwriten
		
		MeiMei: meimei is an embedded tool pixi uses to fix sprite data for levels when sprite data size is changed for sprites already in use. That happens when you have a level that already uses a certain sprite and you change the amount of extra bytes said sprite uses.
		Options are:
		-meimei-off		Shuts down MeiMei completely
		-meimei-a		Enables always remap sprite data
		-meimei-k		Enables keep temp patches files
		-meimei-d		Enables debug for MeiMei patches - I recommend you turn this on if you wanna know what levels were edited and how.
		
		They are all still considered pixi options by the way, so you would them the as any of ther other options above the MeiMei section.

	Examples:
		
		pixi.exe -l differentlistfile.txt rom.smc							-> will use "differentlistfile.txt" instead of "list.txt"

		pixi.exe -d -out debug_out.txt -k -l differentlistfile.txt rom.smc	-> will print debug output to "debug_out.txt", keep debug files and use "differentlistfile.txt"
		
		
		
		
- New Additions and Changes
If you are used to using Romi's SpriteTool, here is a quick rundown of everything new added in PIXI:

-- Custom status handling and extra property bytes:
  As most people know, Pixi relies on 2 print statements to tell the game what code to run in which state of the sprite.
  Most importantly, state 08 will run whatever code is under the "MAIN" print statement and state 01 will run whatever code is under the "INIT" print statement.
  All the other states will run the corresponding vanilla code, however, some bits in !extra_prop_2 can be set to activate certain functions. Setting bit 7 of that byte will make the sprite run its MAIN code in any state and it won't run the vanilla code, setting bit 6 will make it run both vanilla code and the custom MAIN.
  Since Pixi 1.2.16 you can have more control over other states that are not 08 and 01 by using new print statements crafted just for the occasion, valid print statements FOR NORMAL CUSTOM SPRITES are:
      > print "CARRIABLE", pc  which will run in state 09
	  > print "KICKED", pc  which will run in state 0A
	  > print "CARRIED", pc which will run in state 0B
	  > print "MOUTH", pc which will run in state 07
	  > print "GOAL", pc which will run in state 0C
  Note that while using these print statements, the data bank will be automatically set, so you don't need to manually set it like for MAIN or INIT.
  Please be aware that the use of these labels completely and totally overrides ANY vanilla code that would run in the respective states (unless you set the aforementioned bits in the property bytes), 
  so if you use them you have to code all of the wanted behaviors yourself, this is done on purpose so the code has complete control and they won't have unwanted side-effects due to vanilla code.
  You can find the code that vanilla rom uses to handle those states at the following rom locations, you can use those to see how to do implement whatever you feel like vanilla gave you and you're missing now, maybe even better than how the original game did things:
  - $01953C for carriable/stunned
  - $019913 for kicked
  - $019F71 for carried
  - $018157 for goal tape (only activates when the sprite has "turn into a powerup at goal tape" bit on.
  Fun fact, the game just returns when in Yoshi's Mouth so you can do anything you want here. Be aware that "MOUTH" activates only when the sprite is set to stay in Yoshi's mouth.
  If you don't use these print statement your sprite will just run the respective state's vanilla code, just as normal, for retro-compatibility purposes.
  There's also another special print statement that works only for EXTENDED sprites, which is print "CAPE", pc and its purpose is to fix a bug with cape interaction with custom extended sprites. You can use it to define the behavior of your extended sprite with cape twirl,
  not using it will default cape interaction of the extended sprite to do nothing.
 
-- Softcoding
  All the ASM code inserted by the tool is available to be edited by hand in the asm/ folder, namely main.asm.
  This means that if you need to hijack or change some code PIXI inserts, you can do it just like you would with
  any patch. This is of course mainly intended for people with understanding of ASM.


-- Per-Level Sprites (has to be enabled with -pl since 1.2.5)
  As explained in the Usage portion of this readme, sprite slots B0 to BF are per-level sprites, meaning
  those same 16 sprite slots can point to different sprite code in different levels.
  This can be especially useful for collaboration hacks or for one-off sprites that don't need to occupy
  their own global slot, especially if sprite slot space is running low.
  Per-level sprites can only use 4 extra bytes.


-- SA-1 Detection and Default Labels
	The file asm/sa1defs.asm contains all the necessary defines and macros for coding sprites to
	work with and without SA-1.	The file will be included by default in any sprite, so you don't have to
	manually do that for every sprite you code.
	
	You can check the file out yourself, but the most important bits are the !Base1 and !Base2 defines,
	the !SA1 and !SA_1 defines and a define !SprSize for the total amount of sprites.
	It's either $0C or $16, since SA-1 ROMs have larger sprite table sizes due to allowing more sprites on screen.
	
	Furthermore, there are defines for all sprite tables either by address or by name.
	To exemplify, the two lines below both refer to the same address:
	
		LDA !9E,x           ;note that this says !9E, not $9E
		LDA !sprite_num,x
	
	
-- CFG Files and the new CFG Editor
	CFG files themselves are mostly unchanged, except for the fact that all sprites will be assembled with Asar,
	rendering the final assembler bit that SpriteTool uses to determine whether to use xkas or TRASM unused.
	
	This also means that the new CFG Editor does not actually come with any new functionality. All the changes in it
	are purely cosmetic and meant to make CFG file editing a little easier by giving visual hints for clipping boxes
	and the colors in each palette row.
	
	In the two clipping visualizers, the darker color signifies the 16x16 box around the sprite's position (the
	position placed in Lunar Magic), while the red dots signify the clipping box' corners.
	For those who aren't aware, the Object Clipping (the green box) determines how the sprite interacts with tiles and
	objects, while the Sprite Clipping determines how it interacts with other sprites, including Mario.

	BONUS: As of version 1.1, you can also open your ROM in the CFG Editor and use it to tweak existing sprites in the
	game, basically replicating the functionality of Tweaker.


-- JSON Files
	As of version 1.2, PIXI now aso supports JSON files as an alternative to CFG files (CFG files can still be used
	for backwards-compatibility). The JSON format has the advantage of being more human-readable and wide-spread
	(there exist a lot of tools and libraries using JSON files). In the case of PIXI in particular, JSON files,
	unlike CFG files, embed additional information that can be used by PIXI to automatically generate .ssc, .mwt,
	.mw2 and .s16 files for you. The CFG Editor has also been updated with a graphical user interface inspired by
	 Lunar Magic that lets you edit that embedded information intuitively.


-- Shared Routines
	If you have used GPS before, the shared routines in PIXI work exactly like the ones there.
	If you haven't, it's easily explained: instead of placing the same globally used routines such as GET_DRAW_INFO
	and SUB_OFFSCREEN into every single sprite, thus eating up space unnecessarily, there are now macros to access
	them from any sprite without inserting the code again and again.
	
	Check out the routines/ folder for all shared routines included. To use them, call a macro with their file name
	in place of where you would usually JSR to them, like this:
	
	%GetDrawInfo()
	 -or-
	%Aiming()


-- Header Files
	Each sprite directory has a "_header.asm" file within it. This file will be included only with sprites of their
	respective type. Unlike sa1def.asm which is included with every sprite.
	You can use it to implement defines or macros that have different behavior with different sprite types without having
	to name them all differently.


-- Extra Bytes
	As of version 1.1, PIXI supports up to four extra bytes per sprite that can be customized via the CFG file and then set by
	Lunar Magic when placing a sprite in a level. The CFG file determines how many extra bytes a sprite uses, though
	per-level sprites always have all four extra bytes enabled.

	WARNING: Be EXTREMELY CAUTIONS with this feature. Changing the number of extra bytes for an already inserted sprite will
	corrupt the level data, as Lunar Magic will expect the sprite to be a different size than it is. So make sure to delete all
	instances of a sprite before changing it's number.

	sa1def.asm provides convenient defines for sprite coders to access all extra bytes:

	!extra_byte_1
	!extra_byte_2
	!extra_byte_3
	!extra_byte_4
	
	As of version 1.2.10, we now have 3 extra bytes for shooters. Everything that applies for normal sprite extra bytes applies for this.
	
	!shooter_extra_byte_1
	!shooter_extra_byte_2
	!shooter_extra_byte_3
	

	Indirect data pointer:
	From pixi 1.2.11 onwards, you are allowed to use n extra bytes, both for shooters and sprites - however limited at 12 (not in hex)
	extra bytes, because lunar magic only allows us to go that far with the input box.
	This feature isn't valid for per-level sprites, since by design every per-level sprite would have the same number of extra bytes and allowing 12 bytes for each per-level sprite would break every other sprite that used < 5 extra bytes.
	No additional RAM is reserved for this model.

	So for sprites from 5 onwards extra bytes, the first 3 extra bytes will be used as an indirect pointer to the sprite data, starting at 1.
	For shooters, from 4 onwards, same rule.

	Be careful when declaring 10+ extra bytes in the cfg/json format. Cfg format will expect hex numbers, json will expect decimal.

	Exemple for sprites:
			LDA !extra_byte_1,x
			STA $00
			LDA !extra_byte_2,x
			STA $01
			LDA !extra_byte_3,x
			STA $02
			LDY #$0B
			LDA [$00],y
	
	The code above would read the 12th extra byte for a sprite.

	
	Exemplo for shooters:
			LDA !shooter_extra_byte_1,x
			STA $00
			LDA !shooter_extra_byte_2,x
			STA $01
			LDA !shooter_extra_byte_3,x
			STA $02
			LDY #$07
			LDA [$00],y

	The code above would read the 8th extra byte for a shooter.


	So you could say that in this model, extra_byte_4 for sprites is a free table that won't get cleanups. I didn't add more ram for this feature because sprites already have a whole load of RAM reserved and they are mostly unused all the time.
	If you in turn think you need more RAM, just extend pixi. Check the section right below this one to see how to do that.
	
	It can potentially be harmful for shooters, since shooters do not possess the same amount of free ram tables as sprites do.
	But honestly, I think you should consider if it's really an issue (performance-wise), since to begin with shooters don't even have init pointers, they only have mains.
	If even then you think it is a performance issue, extend pixi, add your own reserved RAMs for shooters, add a hijack for cleaning up the tables and be happy.
	Check the Extend pixi section right below this to see how to do that.


-- Extend PIXI (extra defines and hijacks)
	From pixi 1.2.11+ we have two 'secret' folders called ExtraDefines and ExtraHijacks. They do not come in with pixi by default, they have to be created.

	Folder structure:
		./asm/ExtraDefines
		./asm/ExtraHijacks

	They each have their own unique behavior.

	For ExtraDefines, whatever .asm files you put in there, will be included in every single sprite as valid defines/macros. So be sure to only use these as defines
	and macros.

	For ExtraHijacks, before MeiMei runs, this is the last thing inserted to the rom, right after all pixi asms. All .asm files inside this folder will be inserted then.
	So be careful with cleaning up stuff, overwriting stuff, clashing with other hijacks and so on.

	Combaning those two things you could set up your own sprite/shooters/whatever tables and clean them up wherever you want - so they can be used with your resources.
	And a lot more.
	Essentially, there's no difference from adding a patch to be inserted with your sprite and adding something to the ExtraHijacks folder, except for the
	convinience, of course. Please do not abuse this feature.
	Since pixi does not touch .asm files, you will have to include sa1def or whatever else defines you defined at ExtraDefines inside your patch, if you wanna use them.

		
- Common Errors
The vast majority of the time, xkas code will work just fine with Asar, the assembler that PIXI uses exclusively.

If you do get errors trying to use a sprite that worked fine in the xkas-based SpriteTool, here are some common sources:

-- JMP (label,x) or JSR (label,x)
	Asar does not want to guess at the size of these instructions. You will have to append ".w" to the JMP/JSR instruction,
	to let Asar know that the pointers are 2 bytes in size (or a "word", hence the "w"). This would look like this corrected:
  
	JMP.w (label,x) or JSR.w (label,x)
  

-- JMP $xxxxxx
	xkas accepted the JMP $xxxxxx instruction, despite it technically not existing. JMP is intended to jump to addresses in
	the same bank as the instruction, but $xxxxxx (note the 6 bytes) points at an absolute place in the ROM. To fix this,
	change it to use the absolute JML command instead, like this:
  
	JML $xxxxxx
  

-- Faulty Math or Wrong Register size (inserts fine but crashes in-game)
	xkas and Asar handle assembler math a little differently. If your sprite assembles fine but ends up crashing, this will
	often be the fault of them disagreeing on how to read a bit of math. Asar tries to go the logical route while xkas does
	its own thing.
	If this happens to you, search for occurences of assembler math (such as LDA #$08+05^$FF or LDA #!define<<(!otherdefine*8))
	and specify the register size as before. Usually this means appending ".b" to the instruction (for example
	LDA.b #!define<<(!otherdefine*8)), but in other cases it might also be ".w" or ".l". Sometimes the math arguments
	themselves have to be rewritten too, which might be a little harder.
  
	If you can't figure it out yourself due to lack of ASM knowledge, feel free to ask on the SMWCentral forums.

-- incsrc/incbin file not found
	Romi's sprite_tool handled the insertion of sprites slightly differently than PIXI. That is, it created a copy of the sprite in the main
	directory of the exe and then patched it, whereas PIXI just creates temp file which references the original sprite.
	As a result, old sprites that use the incsrc or incbin command had to take the full path to the sprite into accound but PIXI doesn't.
	Example:

	Romi:
		incbin "sprites/data.bin"
	PIXI:
		incbin "data.bin"