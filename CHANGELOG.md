# Changelog

## Version 1.41 (TBD)
- (mellonpizza) Add --stddefines and --stdincludes command line options.
- (spooonsss) Add --symbols command line option to make asar output symbols file (can be WLA or nocash)
- (spooonsss) Fix CFG Editor small visual bug
- (Iwakoro) Add define support for the "More Extended Sprites" patch
- (RunicRain) Split shared routines in a way that makes it safe for routines to call each other
- (Atari2.0) Add a way to consume pixi as a library (dynamic or static), and add C,C++,C# and Python bindings, see the README for more details.
- (Atari2.0) Fixed a routine name
- (Atari2.0) Add plugin system, see the README for more details
- (Atari2.0) Correct on-hover tooltips on icons in CFG Editor, aswell as fix maximum value of spinbox for value when using extra byte in json.
- (Atari2.0) Add list.txt aswell as asm/ExtraDefines asm/ExtraHijacks to the zip file so users don't have to create them on their own.
- (Atari2.0) Add --exerel command line option to make Pixi search for the list.txt and the mwt/mw2/ssc/s16 files relative to the exe instead of relative to the ROM
- (Atari2.0) Partially fix an issue that could occur with wrong path resolution when the ROM and the pixi exe are on different drives on windows.
- (Atari2.0) Fix a bug from 1.21 where the CFG editor feature to be able to edit ROMs directly (akin to Tweaker) introduced in 1.1 was accidentally disabled, thanks to SubconsciousEye for reporting this.
- (Atari2.0) Fix a bug from 1.40 with some spawning routines where a missing XBA was making the routine not work properly. Special thanks to RussianMan for reporting this.
- (Atari2.0) Minor README improvements (document the CFG file format mostly).
- (Atari2.0) Warn when inserting sprite number $7B (goal tape) in ROMs that use LM 2.53+
- (zuccha) FireballContact now checks exactly for player fireball value
- (SubconsciousEye) Add custom GFX handler for sprite status 3
- (MarioFanGamer) CFG Sprites will now also show up in the custom sprite collection in LM
- (zuccha) Add command line flags for custom misc sprites directories in README
- (Atari2.0) Fix SpawnCluster & other misc sprites routines using wrong positions and overwriting A, additionally set $18B8 to 1 when spawning a cluster sprite, thanks to kkevinm for reporting this.
- (Atari2.0) Add %SpawnMinorExtendedOverwrite routine to spawn the sprite even if there's no slots free (overwrites oldest one)
- (Atari2.0) Fix %ExtendedSpeed routine not applying gravity when speed was between $80 and $C0, thanks to anonimzwx for reporting this. 
- (Atari2.0) Upgrade to Asar 1.90.

## Version 1.40 (November 23, 2022)
- (Atari2.0) Fix list.txt parsing bug when paths would get wrongly split for containing spaces.
- (Atari2.0) Now pixi also prints warnings that asar gives instead of silently ignoring them.
- (Atari2.0) Fixed oversight in extra byte count assignment
- (JamesD28) Updated circle routines to fix sign issues with large radii on LoRom.
- (Atari2.0) Better error messages in general.
- (Atari2.0) Fixed extended sprites cape interaction.
- (lx5, Atari2.0) Added support for minor sprite types (minor extended, bounce, spinningcoin, etc.)
- (Atari2.0) Fix misplaced bracket causing ExtendedHurt routine to send Yoshi always to the right.
- (KevinM) Extended/Cluster defines update (details [here](https://github.com/JackTheSpades/SpriteToolSuperDelux/commit/0e0d4d24dee1066118635da3824fc648f71bd630)) 
- (spooonsss) ExtendedGetDrawInfo: properly despawn when extended sprite is vertically offscreen 
- (Atari2.0) Add all of the LM3.30 ssc/mwt features. More details in README.md
- (lx5) Updated cluster sprites routines
- (Atari2.0) Added utf-8 paths support on Windows. This should fix any issues with paths containing non-ascii characters.
- (Atari2.0) Completely overhaul the build system, use CMake, enable building pixi as a .dll, add APIs for python, c and c#.
- (Atari2.0) Now the print statements in sprites can be substituted by labels (`init:` etc) and they are not case sensitive anymore (e.g. `print "init", pc` works)
- (Atari2.0) A lot (and I mean a lot) of internal C++ code changes to improve the codebase and speedup the tool as well as major changes to the build system. These changes are massive but they should not be visible to external users. As such they won't be reported here but they can be found in the single commits in the repository.
- (Atari2.0) Add support for having a pixi_setttings.json in the same folder as the executable. This file will be used to get command line options if present. Format explained in the README
- (Atari2.0) Now you can have subfolders in the routines folder, the subfolder path and the routine filename will be joined to be used as the routine name, e.g. routines/Bounce/Spawn.asm -> %BounceSpawn()

## Version 1.32 (January 23, 2021):

- (Atari2.0) Fixes spritetool_clean.asm not being in the asm/ folder.
- (Atari2.0) Now permits nested shared routine calls, fixing https://github.com/JackTheSpades/SpriteToolSuperDelux/issues/28
- (Atari2.0) Updated asar.dll to 1.80, fixes https://github.com/JackTheSpades/SpriteToolSuperDelux/issues/35
- (Atari2.0) Updated and fixed make, Makefile and .gitignore
- (Atari2.0) Added escaping to ! in filepaths, fixes https://github.com/JackTheSpades/SpriteToolSuperDelux/issues/16
- (Atari2.0) Added autoclean to all sprite pointers, fixes https://github.com/JackTheSpades/SpriteToolSuperDelux/issues/34
- (Atari2.0) Fixed various compiler warnings, swapped fread arguments causing an error when writing extmod file.
- (Atari2.0) Fixed snestopc not working correctly on SA-1 roms bigger than 2 mbs
- (Atari2.0) Greatly refactored and reworked MeiMei, embedded both ROM classes in one
- (Atari2.0) Made Pixi work on +6mb ROMs correctly
- (Atari2.0) Now can use -nr to specify max number of shared routines
- (Atari2.0) Fixed various memory leaks, along with a couple of asar warnings related to relative paths being used.
- (Atari2.0) You can now use comments in your list.txt file
- (Atari2.0) Completely rewritten populate_sprite_list and relative_directory to fix various bugs related to pathing.

## Version 1.31 (November 4, 2020):

- (Atari2.0, randomdude999) Fully implemented Romi's SpriteTool legacy cleanup (note that this doesn't mean that now Pixi can coexist in the same rom as SpriteTool but it means that at least SpriteTool roms can be easily upgraded to Pixi without breaking massively as long as you do it properly). ASM file used for cleanup provided by randomdude999.
- (Atari2.0) Fixed an issue where upon upgrading from 1.2.x to 1.3, Pixi would completely destroy overworld layer 2 events.
- (Atari2.0) Upped limit for .s16 files from 0x10 pages to 0x38 pages
- (Atari2.0) Added extmod support (for specifics read the Lunar Magic help file in the section "Restore Options"), also added a "-ext-off" command line option to turn off extmod logging.
- (Atari2.0) Finished implementing -mw2 and -mwt command line options, since they were not completed.
- (Atari2.0) Fixed a bunch of compilation warnings.
- (Atari2.0) Added a command line option (-lm-handle) strictly to enable the use of Pixi in the custom user toolbar of Lunar Magic, check LM's help file for more details. Usage is: "-lm-handle <LM_VERIFICATION_HANDLE>", this command line option can't be used out of LM's custom user toolbars. Keep in mind that this is Windows only.
- (Atari2.0) Added an icon to the executable file.

## Version 1.3 (September 19, 2020):

- (Atari2.0) Added a lot of utility routines (CapeContact, CheckForContactAlternate, SetPlayerClippingAlternate, SetSpriteClippingAlternate, LoseYoshi, FinishOAMWrite, FireballContact) most of these were taken from GIEPY. Credit to respective authors in the asm files.
- (Atari2.0) Fixed a bug regarding cape interaction with extended sprites by adding a print "CAPE" statement, along with an ExtendedCapeClipping routine
- (Atari2.0) Added a SpawnSpriteSafe routine to fix a problem related to how the vanilla game handles OAM in certain sprite slots.
- (Atari2.0) Optimized Random a little bit
- (Akaginite, randomdude999 and Atari2.0) Fixed, reworked and merged the per-level sprites update. Now you can use B0-BF as normal sprite slots aswell, reduced insert size
- (Atari2.0) Added print statements for states that are not 8, more details in README.txt
- (Atari2.0) Fixed various bugs related to per-level sprites in sprite.cpp
- (Atari2.0) Added a warning in case the user is inserting Pixi while having the VRAM patch from LM disabled.
- (Alcaro) Updated asardll.c to not give compiler warnings about strict aliasing and a missing cast
- (randomdude999) Fixed compilation on Linux, added basic makefile
- (lx5, Atari2.0) Updated CFG Editor and Pixi to support json files with more than 4 extra bytes for custom collections.
- (Atari2.0) Changed SA1 definitions to use absolute addressing instead of long addressing.
- (Atari2.0) Added setting bit to disable Lunar Magic sprite count warning message when using 255 sprites per level.
- (Atari2.0) Fixed per-level sprites displaying 9 extra bytes in the Lunar Magic window, forced to 4 (as a side effect of this, in fact, per level sprites now can only use up to 4 extra bytes).

## Version 1.2.15 (July 10, 2020):

- (Atari2.0) Removed unnecessary waiting (BRA $00/NOPs) in SA-1 version of various routines (Aiming, CircleX, CircleY, Random)
- (Atari2.0) Added exception control for missing .json files. Now it will output exactly what json file was not found instead of printing the stacktrace.
- (Atari2.0) Added a command line option "-out" that can be added after "-d" to redirect debug output to a file instead of the prompt/stdout.
- (Atari2.0) Fixed trimming of filenames causing bug with trailing whitespaces in .cfg/.json names in list.txt
- (Atari2.0) Added a warning in case the user is inserting Pixi into a rom without having modified any level in Lunar Magic, causing various bugs (like goal posts not working).

## Version 1.2.14 (March 02, 2020):

- (Atari2.0) Fixed a bug which caused pixi to cleanup stuff wrong if you ran it with an empty list.
- (Sillymel) Fixed a bug in GetDrawInfo which caused it to consider clippings from 20+ instead of two-tiles death animation flags. This is actually a bug in the Vanilla game as well (see $01A365 and $02D378).
- (Sillymel) Fixed comments on ShooterMain.
- (Sillymel) Fixed a bug which caused SpawnExtended to return the wrong carry flag when signalling it failed to spawn a sprite due to the sprite being offscreen.
- (Sillymel) Fixed carry return of GetMap16 so it actually returns the flags like it says it should.
- (Sillymel) Fixed ChangeMap16 return so it returns #$FFFF instead of #$00FF.
- (Sillymel) Fixed a bug which caused ChangeMap16 to break the stack due to it mishandling 16 bit mode.
- (Tattletale) Added proper documentation to -d255spl.
- (Tattletale) Added a comment about x/y offset in SpawnSprite, basically it substracts them if they are negative.
- (Tattletale) Added a comment about TDC usage in GetDrawInfo.
- (Tattletale) Fixed a slight overlook in GetDrawInfo which would cause it to keep the vertical offscreen flag's state if the sprite is offscreen horizontally. Reported by Super Maks 64.
- (Tattletale) -ssc is now properly implemented, reported by Shiny Ninetales, quite possibly imamelia had issues with this too.

## Version 1.2.13 (January 09, 2020):

- (Tattletale) Fixed a bug with sprite data displacement introduced in 1.2.10. LM3 cache would cover this up in most cases, except for reeeeeally tall levels.
- (Tattletale) Added a compatibility flag to disable 255 sprites per level support on fastROM -d255spl, check the readme for more info.
- (Tattletale) Removed main_npl.asm, now there's an optional config file included in sa1def.asm that's generated on every run. Eventually this file will actually become a config file. Special thanks to randomdude999 for giving me the code to check for files in asar.
- (Tattletale) SubOffScreen edited to include a check for -d255spl flag.
- (Tattletale) sa1def.asm edited to include checks for -d255spl flag. All defines that were in main.asm before were moved to sa1def.asm.

## Version 1.2.12 (October 28, 2019):

- (dtothefourth) Fixed the cfg editor to work properly with n extra bytes (actually only up to 12). Disclaimer, the cfg editor will be removed from pixi packaging starting from the next update! It will be submitted as a standalone resource.

## Version 1.2.11 (August 26, 2019):

- (Tattletale) n extra byte support for both shooters and sprites. Goes up to 12 because LM only supports up to 12. Read the readme.txt for further info.
- (Tattletale) added two secret folders called ./asm/ExtraDefines and ./asm/ExtraHijacks. Now you can ship your own defines and hijacks along with your resources, just be very very careful with that. Read the readme for further info.
- (Tattletale) added Akaginite's MeiMei to pixi. This will sort out your sprite data when inserting or modifying sprites' extra byte configuration, when said sprites are already used in levels. Before this, you would just get a crash / corrupted sprite data. Special thanks to Akaginite (I would say 95% of the code is from MeiMei), Vitor Vilela, Randomdude999, Alcaro, they helped me deal with asar / sa1 address conversions. For further information read the readme - several flags were added as config for MeiMei, check the readme.
- (Tattletale) fixed a json related crash when the file name is invalid. The current message isn't any better but at least it won't crash. Messages will be reworked at some point.

## Version 1.2.10 (July 6, 2019):

- (Tattletale) sa1convert officially removed from pixi.
- (Tattletale) trashkas officially removed from pixi.
- (Tattletale) donutblk gps block removed from pixi.
- (Tattletale) poison.asm patch removed from pixi.
- (Tattletale) level_ender sprite remove from pixi.
- (Tattletale) donut_lift sprite remove from pixi.
- (Tattletale) piranha_sideways sprite remove from pixi.
- (Tattletale) roto_disc sprite remove from pixi.
- (Tattletale) thwomp_left sprite remove from pixi.
- (Tattletale) thwomp_right sprite remove from pixi.
- (Tattletale) base_bro sprite remove from pixi.
- (Tattletale) shell_bro sprite remove from pixi.
- (Tattletale) bomb_bro sprite remove from pixi.
- (Tattletale) boomerang sprite remove from pixi.
- (Tattletale) boomerang_bro sprite remove from pixi.
- (Tattletale) hammer_bro sprite remove from pixi.
- (Tattletale) clusterspawn sprite remove from pixi.
- (Tattletale) fishspawn sprite remove from pixi.
- (Tattletale) flowerspawn sprite remove from pixi.
- (Tattletale) rainspawn sprite remove from pixi.
- (Tattletale) sandstormspawn sprite remove from pixi.
- (Tattletale) diag_down_bill shooter remove from pixi.
- (Tattletale) diag_up_bill shooter remove from pixi.
- (Tattletale) vertical_bill shooter remove from pixi.
- (Tattletale) fish cluster sprite remove from pixi.
- (Tattletale) flowers cluster sprite remove from pixi.
- (Tattletale) rain cluster sprite remove from pixi.
- (Tattletale) sandstorm cluster sprite remove from pixi.
- (Tattletale) boomerang extended sprite remove from pixi.
- (Tattletale) hammer extended sprite remove from pixi.
- (Tattletale) src.zip is not packed anymore. If you want the source, get it in github.
- (Tattletale) Graphic for Included Sprites has been removed.
- (Tattletale) Added a file called removedResources.txt so you can get back these resources from elsewhere.
- (Tattletale) Table 1938 has been moved to 7FAF00, it also now uses 256 bytes. So 7E1938 is now free.
- (Tattletale) Added 3 extra bytes for shooters at 7FAC00|4000F1, 7FAC08|400030 and 7FAC10|400038 - 8 bytes each.
- (Tattletale) Added !addr, !dp, !bank, !sa1, !shooter_extra_byte_1, !shooter_extra_byte_2, !shooter_extra_byte_3 and !7FAF00 as defines. !1938 is now the same as !7FAF00, so be careful, it's not 16bits anymore for fastROM.
- (Tattletale) SubOffScreen edited to explicitly use .L and the new table's macro.
- (Tattletale) Pixi now handles the sprite status table just like sa1 does (256 bytes). Now it's safe to disable LM's warning for sprite count when using fastROM. This is also technically a bug fix.
- (Tattletale) Some minor optimizations to main.asm.

## Version 1.2.9 (Feb 17, 2019):

- (Tattletale) Fixed a bug with the Star.asm routine (provided by Blinddevil, reported by Darolac).
- (Tattletale) Fixed a bug with ExtendedGetDrawInfo.asm (reported by Darolac, I think it was Sonikku who fixed this (?)).

## Version 1.2.8 (Jan 20, 2019):

- (Tattletale) Fixed a bug with sprite data in sa1 not being displaced correctly. This would cause random sprites to spawn when extension byte was used (didn't happen every time). Also added some doc/comments to main.asm while I was at it.

## Version 1.2.7 (Jan 13, 2019):

- (Tattletale) Routines ChangeMap16, ExtendedHurt, SubVertPos, SubHorzPos, SpawnSprite, GetMap16 and GetDrawInfo were updated so their top-most labels were removed and only sublabels are used within them to avoid issues with asar. Reported by DigitalSine.

## Version 1.2.6 (Dec 30, 2018):

- (Tattletale) Fixed an issue with ChangeMap16 in vertical levels.
- (Tattletale) Fixed an issue with GetMap16 in vertical levels.

## Version 1.2.5 (Dec 29, 2018):

- (Tattletale) Fixed an inconsistency I left in main.asm that would cause a half-state of the perlevel feature to be inserted. Without -npl this would cause the first shooter or generator to not spawn properly.
- (Tattletale) Perlevel sprite has been turned off by default.
- (Tattletale) -npl doesn't do anything anymore, but is still around so stuff don't break with it.
- (Tattletale) New flag -pl created so you can still use sprite perlevel feature.
- (Tattletale) Bugfix on the LM version detection code. Rude, rude mistake (didn't affect anyone unless you use lm 193 and 16x), unredeemable.
- (Tattletale) Fixed a bug in error handling for sprite per level below B0 or above BF.
- (Tattletale) CFG Editor now opens either cfg or json without changing file types in the menu (mask is _.json; _.cfg).
- (Tattletale) Fixed thwomp json mappings.
- (Tattletale) Donut Lift's code reverted. Now it should be working normally. I'm sorry I left a piece of test code there.

## Version 1.2.4 (Dec 25, 2018):

- (Tattletale) Recompiled with new g++. Added namespace as a fix for the macro sublabel shenanigan.
- (Tattletale) Updated Asar dll to 1.61.
- (Tattletale) SA-1 16bit sprite data pointer support.
- (Tattletale) FastROM pagination sprite data pointer support.
- (Tattletale) GetMap16 and ChangeMap16 were replaced by Akaginite's implementation. Added support to new LM.
- (Tattletale) Sprite 7B is entirely reserved to LM, so nothing inserted in the 7B slot will work as a custom sprite.
- (Tattletale) SubOffScreen updated to consider new LM settings.
- (Tattletale) Fixed a bug with SubOffScreen, it would run all checks even when the sprite is on screen.
- (Tattletale) Aiming routine update to use Akaginite's version.
- (Tattletale) All routines were updated to use ?+/?- instead of +/- to avoid redefines outside the routine context.

## Version 1.2.3 (Jul 15, 2018):

- (Telinc1) Updated to use Asar 1.60 DLL.
- (Telinc1) Fixed problems with the Aiming, ExtendedGetDrawInfo and Random routines.

## Version 1.2.2 (Jun 10, 2018):

- (Blind Devil) Fixed Star.asm, which didn't have a bank wrapper, thus not
  reading tables correctly.
- (Blind Devil) Fixed sa1def.asm, uncommenting the !7FAB64 define macro
  (Extra Byte 4), and also correcting the default SA-1 address of
  !extra_byte_4, used by the tool, which was wrong (default was $4000D8
  when the correct is $4000DB).

## Version 1.2.1 (Jan 17, 2018):

- (RPG Hacker) Added a changelog so that we don't have to search all over the
  internet for things that have changed between versions.
  (Note that information on versions prior to this one may be inaccurate)
- (RPG Hacker) Added missing command line arguments to Readme.
- (Blind Devil) Fixed SubOffScren.asm.
- (LX5) Fixed some extended sprites defines having wrong RAM addresses.

## Version 1.2 (Dec 04, 2017):

(Information on this version added post-released by RPG Hacker, may not be accurate,
feel free to fix any mistakes and add any missing information)

- (JackTheSpades) Added support for JSON configuration file (with CFG files still supported for
  backwards-compatibility).
- (JackTheSpades) Added functionality to generate .ssc, .mwt, .mw2 and .s16 files from information
  embedded into the JSON sprite configuration files.
  (Those files are used by Lunar Magic for displaying sprites more nicelys in the editor)
- (JackTheSpades) Updated the CFG Editor so that it actually lets you edit said embedded information
  in the JSON files via a more intuitive GUI, inspired by Lunar Magic's interface.
- (JackTheSpades) Added -npl option to disable per-level sprites. This is primarily intended as a
  workaround for Asar's "freedata align" freezing bug.
  NOTE: Do not use on ROMs with sprites already inserted into slots B0 to BF.
- (JackTheSpades) Added -a <asm> option to override the asm path PIXI uses.
- (JackTheSpades) Improved handling for when the ROM isn't in the same folder as PIXI by converting paths
  to either relative to the ROM or relative to the executable.

## Version 1.1 (Jul 29, 2017):

(Information on this version added post-released by RPG Hacker, may not be accurate,
feel free to fix any mistakes and add any missing information)

- (JackTheSpades) Added support for cluster sprites.
- (JackTheSpades) Added support for extended sprite.
- (JackTheSpades) Added support for up to 4 extra bytes per sprite that can be set via Lunar Magic.
- (JackTheSpades) Renamed and added new command line options for customizing the paths PIXI uses.
- (JackTheSpades) Updated CFG Editor, which now contains all the functionality of Tweaker.
- (RPG Hacker; Aug 22, 2017) Fixed a couple of bugs in different included ASM files,
  mainly in regards to SA-1 compatibility.

## Version 1.0 (Feb 16, 2017):

(Information on this version added post-released by RPG Hacker, may not be accurate,
feel free to fix any mistakes and add any missing information)

- (JackTheSpades) Initial release
