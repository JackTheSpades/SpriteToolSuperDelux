
macro clean_pointer(addr, fill)	
	if read3(<addr>) != <fill>
		autoclean read3(<addr>)
		org <addr>
			print "   cleaning pointer: ",pc
			dl <fill>
	endif
endmacro

macro for(id,start,end,inc,addr,fill)
	!<id> ?= <start>
	if !<id> < <end>
		%clean_pointer(<addr>+!<id>,<fill>)
		!<id> #= !<id>+<inc>
		%for(<id>,<start>,<end>,<inc>,<addr>,<fill>)
	endif
endmacro
	
;clear routines
print "Cleaning routines:"
%for("routine",$00,$012C,$03,$03E05C,$FFFFFF)

;clear sprites

!spr0 = read3($02FFEE)

!spr1 = read3($02FFF1)
!spr2 = read3($02FFF4)
!spr3 = read3($02FFF7)
!spr4 = read3($02FFFA)

print "Cleaning global sprites:"
%for("sprite00",$0008,$0F00,$10,!spr0,$018021)	; global sprites

print "Cleaning sprites level 000-07F:"
%for("sprite01",$0008,$1000,$10,!spr1,$018021)	; per level sprites 000-07F
%for("sprite02",$1008,$2000,$10,!spr1,$018021)
%for("sprite03",$2008,$3000,$10,!spr1,$018021)
%for("sprite04",$3008,$4000,$10,!spr1,$018021)
%for("sprite05",$4008,$5000,$10,!spr1,$018021)
%for("sprite06",$5008,$6000,$10,!spr1,$018021)
%for("sprite07",$6008,$7000,$10,!spr1,$018021)
%for("sprite08",$7008,$8000,$10,!spr1,$018021)

print "Cleaning sprites level 080-0FF:"
%for("sprite11",$0008,$1000,$10,!spr2,$018021)	; per level sprites 080-0FF
%for("sprite12",$1008,$2000,$10,!spr2,$018021)
%for("sprite13",$2008,$3000,$10,!spr2,$018021)
%for("sprite14",$3008,$4000,$10,!spr2,$018021)
%for("sprite15",$4008,$5000,$10,!spr2,$018021)
%for("sprite16",$5008,$6000,$10,!spr2,$018021)
%for("sprite17",$6008,$7000,$10,!spr2,$018021)
%for("sprite18",$7008,$8000,$10,!spr2,$018021)

print "Cleaning sprites level 100-17F:"	
%for("sprite21",$0008,$1000,$10,!spr3,$018021)	; per level sprites 100-17F
%for("sprite22",$1008,$2000,$10,!spr3,$018021)
%for("sprite23",$2008,$3000,$10,!spr3,$018021)
%for("sprite24",$3008,$4000,$10,!spr3,$018021)
%for("sprite25",$4008,$5000,$10,!spr3,$018021)
%for("sprite26",$5008,$6000,$10,!spr3,$018021)
%for("sprite27",$6008,$7000,$10,!spr3,$018021)
%for("sprite28",$7008,$8000,$10,!spr3,$018021)
	
print "Cleaning sprites level 180-1FF:"
%for("sprite31",$0008,$1000,$10,!spr4,$018021)	; per level sprites 180-1FF
%for("sprite32",$1008,$2000,$10,!spr4,$018021)
%for("sprite33",$2008,$3000,$10,!spr4,$018021)
%for("sprite34",$3008,$4000,$10,!spr4,$018021)
%for("sprite35",$4008,$5000,$10,!spr4,$018021)
%for("sprite36",$5008,$6000,$10,!spr4,$018021)
%for("sprite37",$6008,$7000,$10,!spr4,$018021)
%for("sprite38",$7008,$8000,$10,!spr4,$018021)
	