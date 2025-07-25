!PerLevel ?= 0
!Disable255SpritesPerLevel ?= 0

if !Disable255SpritesPerLevel
	error "Since Pixi 1.41 disabling the 255 sprites per level isn't supported"
endif

;only works for SA-1 version 1.10+

!CustomBit		= $08

macro debugmsg(msg)
	!__debug ?= 0					; set debug flag to 0 if not set already
	if !__debug == 1				; if set...
		print "$",pc," <msg>"	; print the pc address.
	endif
endmacro

;branch extra bit set
macro BES(label)
	LDA !extra_bits,x
	AND #$04
	BNE <label>
endmacro

;branch extra bit clear
macro BEC(label)
	LDA !extra_bits,x
	AND #$04
	BEQ <label>
endmacro

;Check if A is inbetween x and -x
macro Between(x, label)
	CLC : ADC <x>
	CMP <x>*2
	BCS <label>
endmacro

!EXLEVEL = 0
if (((read1($0FF0B4)-'0')*100)+((read1($0FF0B4+2)-'0')*10)+(read1($0FF0B4+3)-'0')) > 253
	!EXLEVEL = 1
endif

macro invoke_snes(addr)
	LDA.b #<addr>
	STA $0183
	LDA.b #<addr>/256
	STA $0184
	LDA.b #<addr>/65536
	STA $0185
	LDA #$D0
	STA $2209
?-	LDA $018A
	BEQ ?-
	STZ $018A
endmacro

; Macro for calling SA-1 CPU. Label should point to a routine which ends in RTL.
; Data bank is not set, so use PHB/PHK/PLB ... PLB in your SA-1 code.
macro invoke_sa1(label)
	LDA.b #<label>
	STA $3180
	LDA.b #<label>>>8
	STA $3181
	LDA.b #<label>>>16
	STA $3182
	JSR $1E80
endmacro


if read1($00FFD5) == $23		; check if the rom is sa-1
	if read1($00FFD7) == $0D ; full 6/8 mb sa-1 rom
		fullsa1rom
		!fullsa1 = 1
	else
		!fullsa1 = 0
		sa1rom
	endif
	!sa1 = 1
	!SA1 = 1
	!SA_1 = 1
	!Base1 = $3000
	!Base2 = $6000
	!dp = $3000
	!addr = $6000
	
	!BankA = $400000
	!BankB = $000000
	!bank = $000000
	
	!Bank8 = $00
	!bank8 = $00
	
	!SprSize = $16
else
	lorom
	!sa1 = 0
	!SA1 = 0
	!SA_1 = 0
	!Base1 = $0000
	!Base2 = $0000
	!dp = $0000
	!addr = $0000

	!BankA = $7E0000
	!BankB = $800000
	!bank = $800000
	
	!Bank8 = $80
	!bank8 = $80
	
	!SprSize = $0C
endif

!More_ExSprite = 0
!ExSprSize = $07
if read2($029B39) == $0000
	!More_ExSprite = 1
	;; I don't know if this is even possible but let's be extra sure about it
	assert !SA1 == 1, "More Extended Sprites patch was detected but SA-1 was not found, this is an invalid rom configuration"
	!ExSprSize = read1($00FAD5)
endif

!FireballSprSize = !ExSprSize+2
	
macro define_sprite_table(name, addr, addr_sa1)
	if !SA1 == 0
		!<name> = <addr>
	else
		!<name> = <addr_sa1>
	endif
endmacro

macro define_base2_address(name, addr)
	if !SA1 == 0
		!<name> = <addr>
	else
		!<name> = <addr>|!Base2
	endif
endmacro

macro define_exsprite_table(name, addr, addr_more)
	if !More_ExSprite == 0
		%define_base2_address(<name>, <addr>)
	else
		!<name> = <addr_more>
	endif
endmacro

!GenStart = $D0
!ClusterOffset  = $09
!ExtendedOffset = $13
!MinorExtendedOffset = $0C
!SmokeOffset = $06
!SpinningCoinOffset = $02
!BounceOffset = $08
!ScoreOffset = $16
;!QuakeOffset = $03

!ClusterSize = $14
!ExtendedSize #= !ExSprSize+1
!MinorExtendedSize = $0C
!SmokeSize = $04
!SpinningCoinSize = $04
!BounceSize = $04
!ScoreSize = $06
;!QuakeSize = $04

;$9E,x =  ($B4)

;sprite tool / pixi defines
%define_sprite_table("7FAB10",$7FAB10,$6040)
%define_sprite_table("7FAB1C",$7FAB1C,$6056)
%define_sprite_table("7FAB28",$7FAB28,$6057)
%define_sprite_table("7FAB34",$7FAB34,$606D)
%define_sprite_table("7FAB9E",$7FAB9E,$6083)
%define_sprite_table("7FAB40",$7FAB40,$6099)
%define_sprite_table("7FAB4C",$7FAB4C,$60AF)
%define_sprite_table("7FAB58",$7FAB58,$60C5)
%define_sprite_table("7FAB64",$7FAB64,$60DB)

%define_sprite_table("7FAC00",$7FAC00,$60F1)
%define_sprite_table("7FAC08",$7FAC08,$6030)
%define_sprite_table("7FAC10",$7FAC10,$6038)

%define_sprite_table("extra_bits",$7FAB10,$6040)
%define_sprite_table("new_code_flag",$7FAB1C,$6056)
%define_sprite_table("extra_prop_1",$7FAB28,$6057)
%define_sprite_table("extra_prop_2",$7FAB34,$606D)
%define_sprite_table("new_sprite_num",$7FAB9E,$6083)
%define_sprite_table("extra_byte_1",$7FAB40,$6099)
%define_sprite_table("extra_byte_2",$7FAB4C,$60AF)
%define_sprite_table("extra_byte_3",$7FAB58,$60C5)
%define_sprite_table("extra_byte_4",$7FAB64,$60DB)

%define_sprite_table("shooter_extra_byte_1",$7FAC00,$60F1)
%define_sprite_table("shooter_extra_byte_2",$7FAC08,$6030)
%define_sprite_table("shooter_extra_byte_3",$7FAC10,$6038)

;%define_sprite_table(shoot_misc,$7FAB64,$4000DB)

;shooter defines
%define_base2_address(shoot_num,$1783)		; shooter number -#$BC, also has the extra bit in #$40
%define_base2_address(shoot_y_low,$178B)
%define_base2_address(shoot_y_high,$1793)
%define_base2_address(shoot_x_low,$179B)
%define_base2_address(shoot_x_high,$17A3)
%define_base2_address(shoot_timer,$17AB)


;cluster defines
%define_base2_address(cluster_num,$1892)
%define_base2_address(cluster_y_low,$1E02)
%define_base2_address(cluster_y_high,$1E2A)
%define_base2_address(cluster_x_low,$1E16)
%define_base2_address(cluster_x_high,$1E3E)
%define_base2_address(cluster_misc_0f4a,$0F4A)
%define_base2_address(cluster_misc_0f5e,$0F5E)
%define_base2_address(cluster_misc_0f72,$0F72)
%define_base2_address(cluster_misc_0f86,$0F86)
%define_base2_address(cluster_misc_0f9a,$0F9a)
%define_base2_address(cluster_misc_1e52,$1E52)
%define_base2_address(cluster_misc_1e66,$1E66)
%define_base2_address(cluster_misc_1e7a,$1E7A)
%define_base2_address(cluster_misc_1e8e,$1E8E)

;extended defines
%define_exsprite_table(extended_num,$170B,$770B)
%define_exsprite_table(extended_y_low,$1715,$3426)
%define_exsprite_table(extended_y_high,$1729,$771F)
%define_exsprite_table(extended_x_low,$171F,$343A)
%define_exsprite_table(extended_x_high,$1733,$7733)
%define_exsprite_table(extended_x_speed,$1747,$3462)
%define_exsprite_table(extended_y_speed,$173D,$344E)
%define_exsprite_table(extended_x_fraction,$175B,$775B)
%define_exsprite_table(extended_y_fraction,$1751,$7747)
%define_exsprite_table(extended_table,$1765,$3476)
%define_exsprite_table(extended_timer,$176F,$776F)
%define_exsprite_table(extended_behind,$1779,$348A)

%define_exsprite_table(extended_table_1,$1765,$3476)
%define_exsprite_table(extended_table_2,$198C,$798C)
%define_exsprite_table(extended_table_3,$1996,$349E)
%define_exsprite_table(extended_table_4,$19A0,$79A0)
%define_exsprite_table(extended_table_5,$19AA,$34B2)

;minor extended defines
%define_base2_address(minor_extended_num,$17F0)
%define_base2_address(minor_extended_y_low,$17FC)
%define_base2_address(minor_extended_y_high,$1814)
%define_base2_address(minor_extended_x_low,$1808)
%define_base2_address(minor_extended_x_high,$18EA)
%define_base2_address(minor_extended_x_speed,$182C)
%define_base2_address(minor_extended_y_speed,$1820)
%define_base2_address(minor_extended_x_fraction,$1844)
%define_base2_address(minor_extended_y_fraction,$1838)
%define_base2_address(minor_extended_timer,$1850)

%define_base2_address(minor_extended_table_1,$1938)
%define_base2_address(minor_extended_table_2,$1944)
%define_base2_address(minor_extended_table_3,$1950)

;smoke sprite defines
%define_base2_address(smoke_num,$17C0)
%define_base2_address(smoke_y_low,$17C4)
%define_base2_address(smoke_x_low,$17C8)
%define_base2_address(smoke_timer,$17CC)
%define_base2_address(smoke_table_1,$195C)
%define_base2_address(smoke_table_2,$1960)
%define_base2_address(smoke_table_3,$1964)
%define_base2_address(smoke_y_high,$1960)
%define_base2_address(smoke_x_high,$1964)

;spinning coin sprite defines
%define_base2_address(spinning_coin_num,$17D0)
%define_base2_address(spinning_coin_y_low,$17D4)
%define_base2_address(spinning_coin_y_speed,$17D8)
%define_base2_address(spinning_coin_y_bits,$17DC)
%define_base2_address(spinning_coin_x_low,$17E0)
%define_base2_address(spinning_coin_layer,$17E4)
%define_base2_address(spinning_coin_y_high,$17E8)
%define_base2_address(spinning_coin_x_high,$17EC)

%define_base2_address(spinning_coin_table_1,$1974)
%define_base2_address(spinning_coin_table_2,$1978)
%define_base2_address(spinning_coin_table_3,$197C)

;score sprite defines
%define_base2_address(score_num,$16E1)
%define_base2_address(score_y_low,$16E7)
%define_base2_address(score_x_low,$16ED)
%define_base2_address(score_x_high,$16F3)
%define_base2_address(score_y_high,$16F9)
%define_base2_address(score_y_speed,$16FF)
%define_base2_address(score_layer,$1705)

%define_base2_address(score_table_1,$1980)
%define_base2_address(score_table_2,$1986)

;bounce sprite defines
%define_base2_address(bounce_num,$1699)
%define_base2_address(bounce_init,$169D)
%define_base2_address(bounce_y_low,$16A1)
%define_base2_address(bounce_x_low,$16A5)
%define_base2_address(bounce_y_high,$16A9)
%define_base2_address(bounce_x_high,$16AD)
%define_base2_address(bounce_y_speed,$16B1)
%define_base2_address(bounce_x_speed,$16B5)
%define_base2_address(bounce_x_bits,$16B9)
%define_base2_address(bounce_y_bits,$16BD)
%define_base2_address(bounce_map16_tile,$16C1)
%define_base2_address(bounce_timer,$16C5)
%define_base2_address(bounce_table,$16C9)
%define_base2_address(bounce_table_1,$16C9)
%define_base2_address(bounce_properties,$1901)

%define_base2_address(bounce_table_2,$1968)
%define_base2_address(bounce_table_3,$196C)
%define_base2_address(bounce_table_4,$1970)
%define_base2_address(bounce_map16_low,$16C1)
%define_base2_address(bounce_map16_high,$1968)

;quake sprite defines
; %define_base2_address(quake_num,$16CD)
; %define_base2_address(quake_x_low,$16D1)
; %define_base2_address(quake_x_high,$16D5)
; %define_base2_address(quake_y_low,$16D9)
; %define_base2_address(quake_y_high,$16DD)
; %define_base2_address(quake_timer,$18F8)

;overworld defines
; %define_sprite_table(ow_num,     $0DE5, $3200)
; %define_sprite_table(ow_x_pos,     $9E, $3230)
; %define_sprite_table(ow_y_pos,     $9E, $3260)
; %define_sprite_table(ow_z_pos,     $9E, $3290)
; %define_sprite_table(ow_x_speed, $0E95, $32C0)
; %define_sprite_table(ow_y_speed, $0EA5, $32F0)
; %define_sprite_table(ow_z_speed, $0EB5, $3320)

; %define_sprite_table(ow_misc1,   $0DF5, $3350)
; %define_sprite_table(ow_misc2,   $0E05, $3380)
; %define_sprite_table(ow_misc3,     $9E, $33B0)
; %define_sprite_table(ow_misc4,     $9E, $33E0)
; %define_sprite_table(ow_misc5,     $9E, $3410)
; %define_sprite_table(ow_timer1,  $0E15, $3440)
; %define_sprite_table(ow_timer2,  $0E25, $3470)
; %define_sprite_table(ow_timer3,    $9E, $34A0)
; %define_sprite_table(ow_extra,     $9E, $34D0)

; %define_sprite_table(ow_x_speed_acc, $9E, $3500)
; %define_sprite_table(ow_y_speed_acc, $9E, $3500)
; %define_sprite_table(ow_z_speed_acc, $9E, $3500)

;normal sprite defines
%define_sprite_table(sprite_num, $9E, $3200)
%define_sprite_table(sprite_speed_y, $AA, $9E)
%define_sprite_table(sprite_speed_x, $B6, $B6)
%define_sprite_table(sprite_misc_c2, $C2, $D8)
%define_sprite_table(sprite_y_low, $D8, $3216)
%define_sprite_table(sprite_x_low, $E4, $322C)
%define_sprite_table(sprite_status, $14C8, $3242)
%define_sprite_table(sprite_y_high, $14D4, $3258)
%define_sprite_table(sprite_x_high, $14E0, $326E)
%define_sprite_table(sprite_speed_y_frac, $14EC, $74C8)
%define_sprite_table(sprite_speed_x_frac, $14F8, $74DE)
%define_sprite_table(sprite_misc_1504, $1504, $74F4)
%define_sprite_table(sprite_misc_1510, $1510, $750A)
%define_sprite_table(sprite_misc_151c, $151C, $3284)
%define_sprite_table(sprite_misc_1528, $1528, $329A)
%define_sprite_table(sprite_misc_1534, $1534, $32B0)
%define_sprite_table(sprite_misc_1540, $1540, $32C6)
%define_sprite_table(sprite_misc_154c, $154C, $32DC)
%define_sprite_table(sprite_misc_1558, $1558, $32F2)
%define_sprite_table(sprite_misc_1564, $1564, $3308)
%define_sprite_table(sprite_misc_1570, $1570, $331E)
%define_sprite_table(sprite_misc_157c, $157C, $3334)
%define_sprite_table(sprite_blocked_status, $1588, $334A)
%define_sprite_table(sprite_misc_1594, $1594, $3360)
%define_sprite_table(sprite_off_screen_horz, $15A0, $3376)
%define_sprite_table(sprite_misc_15ac, $15AC, $338C)
%define_sprite_table(sprite_slope, $15B8, $7520)
%define_sprite_table(sprite_off_screen, $15C4, $7536)
%define_sprite_table(sprite_being_eaten, $15D0, $754C)
%define_sprite_table(sprite_obj_interact, $15DC, $7562)
%define_sprite_table(sprite_oam_index, $15EA, $33A2)
%define_sprite_table(sprite_oam_properties, $15F6, $33B8)
%define_sprite_table(sprite_misc_1602, $1602, $33CE)
%define_sprite_table(sprite_misc_160e, $160E, $33E4)
%define_sprite_table(sprite_index_in_level, $161A, $7578)
%define_sprite_table(sprite_misc_1626, $1626, $758E)
%define_sprite_table(sprite_behind_scenery, $1632, $75A4)
%define_sprite_table(sprite_misc_163e, $163E, $33FA)
%define_sprite_table(sprite_in_water, $164A, $75BA)
%define_sprite_table(sprite_tweaker_1656, $1656, $75D0)
%define_sprite_table(sprite_tweaker_1662, $1662, $75EA)
%define_sprite_table(sprite_tweaker_166e, $166E, $7600)
%define_sprite_table(sprite_tweaker_167a, $167A, $7616)
%define_sprite_table(sprite_tweaker_1686, $1686, $762C)
%define_sprite_table(sprite_off_screen_vert, $186C, $7642)
%define_sprite_table(sprite_misc_187b, $187B, $3410)

%define_sprite_table(sprite_load_table, $7FAF00, $418A00)

%define_sprite_table(sprite_tweaker_190f, $190F, $7658)
%define_sprite_table(sprite_misc_1fd6, $1FD6, $766E)
%define_sprite_table(sprite_cape_disable_time, $1FE2, $7FD6)

%define_sprite_table("9E", $9E, $3200)
%define_sprite_table("AA", $AA, $9E)
%define_sprite_table("B6", $B6, $B6)
%define_sprite_table("C2", $C2, $D8)
%define_sprite_table("D8", $D8, $3216)
%define_sprite_table("E4", $E4, $322C)
%define_sprite_table("14C8", $14C8, $3242)
%define_sprite_table("14D4", $14D4, $3258)
%define_sprite_table("14E0", $14E0, $326E)
%define_sprite_table("14EC", $14EC, $74C8)
%define_sprite_table("14F8", $14F8, $74DE)
%define_sprite_table("1504", $1504, $74F4)
%define_sprite_table("1510", $1510, $750A)
%define_sprite_table("151C", $151C, $3284)
%define_sprite_table("1528", $1528, $329A)
%define_sprite_table("1534", $1534, $32B0)
%define_sprite_table("1540", $1540, $32C6)
%define_sprite_table("154C", $154C, $32DC)
%define_sprite_table("1558", $1558, $32F2)
%define_sprite_table("1564", $1564, $3308)
%define_sprite_table("1570", $1570, $331E)
%define_sprite_table("157C", $157C, $3334)
%define_sprite_table("1588", $1588, $334A)
%define_sprite_table("1594", $1594, $3360)
%define_sprite_table("15A0", $15A0, $3376)
%define_sprite_table("15AC", $15AC, $338C)
%define_sprite_table("15B8", $15B8, $7520)
%define_sprite_table("15C4", $15C4, $7536)
%define_sprite_table("15D0", $15D0, $754C)
%define_sprite_table("15DC", $15DC, $7562)
%define_sprite_table("15EA", $15EA, $33A2)
%define_sprite_table("15F6", $15F6, $33B8)
%define_sprite_table("1602", $1602, $33CE)
%define_sprite_table("160E", $160E, $33E4)
%define_sprite_table("161A", $161A, $7578)
%define_sprite_table("1626", $1626, $758E)
%define_sprite_table("1632", $1632, $75A4)
%define_sprite_table("163E", $163E, $33FA)
%define_sprite_table("164A", $164A, $75BA)
%define_sprite_table("1656", $1656, $75D0)
%define_sprite_table("1662", $1662, $75EA)
%define_sprite_table("166E", $166E, $7600)
%define_sprite_table("167A", $167A, $7616)
%define_sprite_table("1686", $1686, $762C)
%define_sprite_table("186C", $186C, $7642)
%define_sprite_table("187B", $187B, $3410)
%define_sprite_table("190F", $190F, $7658)

if !Disable255SpritesPerLevel
	%define_sprite_table("1938", $1938, $418A00)
	%define_sprite_table(sprite_load_table, $1938, $418A00)
else
	%define_sprite_table("1938", $7FAF00, $418A00)
	%define_sprite_table("7FAF00", $7FAF00, $418A00)
	%define_sprite_table(sprite_load_table, $7FAF00, $418A00)
endif

%define_sprite_table("1FD6", $1FD6, $766E)
%define_sprite_table("1FE2", $1FE2, $7FD6)
