macro include_once(target, base, offset)
   if !<base> != 1
      !<base> = 1
      pushpc
      if read3(<offset>+$03E05C) != $FFFFFF
         <base> = read3(<offset>+$03E05C)
      else
         freecode cleaned
            #<base>:
            print "    Routine: <base> inserted at $",pc
            namespace <base>
            incsrc "<target>"
               namespace off
         ORG <offset>+$03E05C
            dl <base>
      endif
      pullpc
   endif
endmacro
!Aiming = 0
macro Aiming()
	%include_once("./routines/Aiming.asm", Aiming, $00)
	JSL Aiming
endmacro
!ChangeMap16 = 0
macro ChangeMap16()
	%include_once("./routines/ChangeMap16.asm", ChangeMap16, $03)
	JSL ChangeMap16
endmacro
!CircleX = 0
macro CircleX()
	%include_once("./routines/CircleX.asm", CircleX, $06)
	JSL CircleX
endmacro
!CircleY = 0
macro CircleY()
	%include_once("./routines/CircleY.asm", CircleY, $09)
	JSL CircleY
endmacro
!ExtendedGetDrawInfo = 0
macro ExtendedGetDrawInfo()
	%include_once("./routines/ExtendedGetDrawInfo.asm", ExtendedGetDrawInfo, $0C)
	JSL ExtendedGetDrawInfo
endmacro
!ExtendedHurt = 0
macro ExtendedHurt()
	%include_once("./routines/ExtendedHurt.asm", ExtendedHurt, $0F)
	JSL ExtendedHurt
endmacro
!ExtendedSpeed = 0
macro ExtendedSpeed()
	%include_once("./routines/ExtendedSpeed.asm", ExtendedSpeed, $12)
	JSL ExtendedSpeed
endmacro
!GetDrawInfo = 0
macro GetDrawInfo()
	%include_once("./routines/GetDrawInfo.asm", GetDrawInfo, $15)
	JSL GetDrawInfo
endmacro
!GetMap16 = 0
macro GetMap16()
	%include_once("./routines/GetMap16.asm", GetMap16, $18)
	JSL GetMap16
endmacro
!GetRandomRange = 0
macro GetRandomRange()
	%include_once("./routines/GetRandomRange.asm", GetRandomRange, $1B)
	JSL GetRandomRange
endmacro
!OverworldDistance = 0
macro OverworldDistance()
	%include_once("./routines/OverworldDistance.asm", OverworldDistance, $1E)
	JSL OverworldDistance
endmacro
!OverworldGetDrawInfo = 0
macro OverworldGetDrawInfo()
	%include_once("./routines/OverworldGetDrawInfo.asm", OverworldGetDrawInfo, $21)
	JSL OverworldGetDrawInfo
endmacro
!OverworldGetDrawInfoPriority = 0
macro OverworldGetDrawInfoPriority()
	%include_once("./routines/OverworldGetDrawInfoPriority.asm", OverworldGetDrawInfoPriority, $24)
	JSL OverworldGetDrawInfoPriority
endmacro
!OverworldHorzPos = 0
macro OverworldHorzPos()
	%include_once("./routines/OverworldHorzPos.asm", OverworldHorzPos, $27)
	JSL OverworldHorzPos
endmacro
!OverworldOffScreen = 0
macro OverworldOffScreen()
	%include_once("./routines/OverworldOffScreen.asm", OverworldOffScreen, $2A)
	JSL OverworldOffScreen
endmacro
!OverworldSpawnSprite = 0
macro OverworldSpawnSprite()
	%include_once("./routines/OverworldSpawnSprite.asm", OverworldSpawnSprite, $2D)
	JSL OverworldSpawnSprite
endmacro
!OverworldXSpeed = 0
macro OverworldXSpeed()
	%include_once("./routines/OverworldXSpeed.asm", OverworldXSpeed, $30)
	JSL OverworldXSpeed
endmacro
!OverworldYSpeed = 0
macro OverworldYSpeed()
	%include_once("./routines/OverworldYSpeed.asm", OverworldYSpeed, $33)
	JSL OverworldYSpeed
endmacro
!OverworldZSpeed = 0
macro OverworldZSpeed()
	%include_once("./routines/OverworldZSpeed.asm", OverworldZSpeed, $36)
	JSL OverworldZSpeed
endmacro
!Random = 0
macro Random()
	%include_once("./routines/Random.asm", Random, $39)
	JSL Random
endmacro
!ShooterMain = 0
macro ShooterMain()
	%include_once("./routines/ShooterMain.asm", ShooterMain, $3C)
	JSL ShooterMain
endmacro
!SpawnExtended = 0
macro SpawnExtended()
	%include_once("./routines/SpawnExtended.asm", SpawnExtended, $3F)
	JSL SpawnExtended
endmacro
!SpawnSmoke = 0
macro SpawnSmoke()
	%include_once("./routines/SpawnSmoke.asm", SpawnSmoke, $42)
	JSL SpawnSmoke
endmacro
!SpawnSprite = 0
macro SpawnSprite()
	%include_once("./routines/SpawnSprite.asm", SpawnSprite, $45)
	JSL SpawnSprite
endmacro
!Star = 0
macro Star()
	%include_once("./routines/Star.asm", Star, $48)
	JSL Star
endmacro
!SubHorzPos = 0
macro SubHorzPos()
	%include_once("./routines/SubHorzPos.asm", SubHorzPos, $4B)
	JSL SubHorzPos
endmacro
!SubOffScreen = 0
macro SubOffScreen()
	%include_once("./routines/SubOffScreen.asm", SubOffScreen, $4E)
	JSL SubOffScreen
endmacro
!SubVertPos = 0
macro SubVertPos()
	%include_once("./routines/SubVertPos.asm", SubVertPos, $51)
	JSL SubVertPos
endmacro
