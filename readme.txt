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
-- Softcoding
-- Per-Level Sprites
-- SA-1 Detection and Default Labels
-- CFG Files and the new CFG Editor
-- Shared Routines
-- Header Files

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
		

-- Per-Level Sprites
	The slots B0 to BF are special, in that you have to assign a level to them. The sprite will only use
	the sprite slot between B0 and BF in that one specified level. Meaning you can assign sprite slot B0 of level 105
	to a Thwomp and B0 of level 106 to a Hammer Bro if you wanted. Keep in mind this only holds true for slots B0 to BF.
	The format for per-level sprites looks as follows:
	
    level COLON id SPACE cfg_file
	
	Here is an example of a "list.txt" file that inserts Blue.cfg and Green.cfg in the same slots as earlier,
	and then inserts Red.cfg and Yellow.cfg only for level 105, while Boo.cfg uses the same slot as Red.cfg but in level 106:
	
		00 Blue.cfg
		01 Green.cfg

		105:B0 Red.cfg
		105:B1 Yellow.cfg
		106:B0 Boo.cfg

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
		-k              Keep debug files
		-l  <listpath>  Specify a custom list file (Default: list.txt)
		
		-sp <sprites>   Specify a custom sprites directory (Default sprites/)
		-sh <shooters>  Specify a custom shooters directory (Default shooters/)
		-g  <generators>        Specify a custom generators directory (Default generators/)
		-e  <extended>  Specify a custom extended sprites directory (Default extended/)
		-c  <cluster>   Specify a custom cluster sprites directory (Default cluster/)

		-r  <sharedpath>        Specify a shared routine directory (Default routines/)
		
	Example:
		
		pixi.exe -l differentlistfile.txt rom.smc
		
		
		
		
- New Additions and Changes
If you are used to using Romi's SpriteTool, here is a quick rundown of everything new added in PIXI:

-- Softcoding
  All the ASM code inserted by the tool is available to be edited by hand in the asm/ folder, namely main.asm.
  This means that if you need to hijack or change some code PIXI inserts, you can do it just like you would with
  any patch. This is of course mainly intended for people with understanding of ASM.


-- Per-Level Sprites
  As explained in the Usage portion of this readme, sprite slots B0 to BF are per-level sprites, meaning
  those same 16 sprite slots can point to different sprite code in different levels.
  This can be especially useful for collaboration hacks or for one-off sprites that don't need to occupy
  their own global slot, especially if sprite slot space is running low.


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