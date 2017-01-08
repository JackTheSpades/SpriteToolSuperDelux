  _____             __    _____                          _   
 / ____|  /\       /_ |  / ____|                        | |  
| (___   /  \ ______| | | |     ___  _ ____   _____ _ __| |_ 
 \___ \ / /\ \______| | | |    / _ \| '_ \ \ / / _ \ '__| __|
 ____) / ____ \     | | | |___| (_) | | | \ V /  __/ |  | |_ 
|_____/_/    \_\    |_|  \_____\___/|_| |_|\_/ \___|_|   \__|
     VERSION 1.10                  SPRITES+BLOCKS EDITION


SA-1 Convert lets you convert Romi's Sprite Tool 1.40 sprites
and blocks to SA-1 format, making it work with SA-1 Pack 1.10+
or 1.20+ for blocks.

The tool is pretty simple, just drop all files you want to convert
on the executable file and the program will convert all to SA-1 format.

If you open the program without dropping any file, it will get and convert
all .asm files on the folder where the program is located. Perfect for who
want to convert multiples blocks or sprites at once.

Calling SA-1 Convert with -x option, it will search for subfolders too.

I recommend to you place the program on sprites folder, then call it: It
will convert all sprites inside that folder, making the only job you have
to do is to call sprite_tool and insert the sprites ready to be used on
your ROM without manual conversion! The same applies for blocks.

The program also outputs conversion.log, a log which reports every step
the program did while converting to SA-1.

---------------------------------------------------------------
Change Log:
	Version 1.10 - Harder but Smarter
		- Added a converter for generic map16 routine.
		- Fixed define parser not searching where the define got used correctly.
		- Fixed processor not fixing FastROM addresses.
		- Changed SA-1 mark from ";@sa1" to ";~@sa1", allowing Asar support.

	Version 1.02 - Saner Way
		- Fixed multi-threading bug which made some files get unsaved or exchanged.
		- The sprite won't be saved if the conversion fail.

	Version 1.01 - The Dynamic Version
		- Added dynamic sprites support.
		- Added division support.
		- Added multi-threading.
		- Fixed lots of minor bugs.
		- This program should work with 97% of all sprites on SMWC!

	Version 1.00 - The Start
		- First public version.

---------------------------------------------------------------
F.A.Q

Q: Does it work for all sprites?
A: No, unfortunately the program can't detect and fix all possible combinations
and with that some sprites will not work correctly. Most cases the program
will throw a error and request to you (or someone else) convert instead.
Otherwise, the sprite should work. If it not work, please report on the SA-1
Pack thread with the conversion.log file and the sprite in particular which
is not working correctly.

Hint: You can fix the part that is not converting and run with the tool
again. The tool will just convert the remaining.

Q: Does it works with xkas or asar sprites?
A: It should.

Q: Does it works with dynamic sprites?
A: Yes, since version 1.01.

Q: Can I use this program to convert shooters and generators?
A: Yes, you can use SA-1 Convert: Sprites Edition to convert shooters
and generators.

Q: Can I use this program to convert patches?
A: No, patches works on a different way which this specific program
wouldn't work well. I recommended checking SA-1 Pack readme
on how to convert resources manually.

Q: Can I use this program to convert blocks?
A: If you're using at least SA-1 Pack v1.20, yes, since blocks
are processed by the SA-1 chip too.

Q: I got a internal error. What now?
A: Please send the the error details and the sprite which the program
was converting.

---------------------------------------------------------------
Contact

If you need to contact me to request a sprite manual conversion
or send a bug report, do it now!

My profile is http://smwc.me/u/8251