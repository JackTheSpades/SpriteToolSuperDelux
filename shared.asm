macro include_once(target, base, offset)
	if !<base> != 1
		!<base> = 1
		pushpc
		if read3(<offset>*3+$03E05C) != $FFFFFF
			<base> = read3(<offset>*3+$03E05C)
		else
			freecode cleaned
			<base>:
			incsrc <target>
			ORG <offset>*3+$03E05C
			dl <base>
		endif
		pullpc
	endif
endmacro
!GetDrawInfo = 0
macro GetDrawInfo()
	%include_once("routines/GetDrawInfo.asm", GetDrawInfo, $00)
	JSL GetDrawInfo
endmacro
!SubHorzPos = 0
macro SubHorzPos()
	%include_once("routines/SubHorzPos.asm", SubHorzPos, $03)
	JSL SubHorzPos
endmacro
!SubOffScreen = 0
macro SubOffScreen()
	%include_once("routines/SubOffScreen.asm", SubOffScreen, $06)
	JSL SubOffScreen
endmacro
!SubVertPos = 0
macro SubVertPos()
	%include_once("routines/SubVertPos.asm", SubVertPos, $09)
	JSL SubVertPos
endmacro
