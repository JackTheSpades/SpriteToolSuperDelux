CODE_01A8C9:        BD 56 16      LDA.W RAM_Tweaker1656,X   ; \ Branch if can be jumped on 
CODE_01A8CC:        29 10         AND.B #$10                ;  | 
CODE_01A8CE:        D0 4C         BNE CODE_01A91C           ; / 
CODE_01A8D0:        AD 0D 14      LDA.W RAM_IsSpinJump      
CODE_01A8D3:        0D 7A 18      ORA.W RAM_OnYoshi         
CODE_01A8D6:        F0 0E         BEQ CODE_01A8E6           
CODE_01A8D8:        A9 02         LDA.B #$02                
CODE_01A8DA:        8D F9 1D      STA.W $1DF9               ; / Play sound effect 
CODE_01A8DD:        22 33 AA 01   JSL.L BoostMarioSpeed     


CODE_01A8E6:        AD ED 13      LDA.W $13ED               
CODE_01A8E9:        F0 0E         BEQ CODE_01A8F9           
CODE_01A8EB:        BD 0F 19      LDA.W RAM_Tweaker190F,X   ; \ Branch if "Takes 5 fireballs to kill"... 
CODE_01A8EE:        29 04         AND.B #$04                ;  | ...is set 
CODE_01A8F0:        D0 07         BNE CODE_01A8F9           ; / 
CODE_01A8F2:        20 28 A7      JSR.W PlayKickSfx         
CODE_01A8F5:        20 47 A8      JSR.W CODE_01A847         
Return01A8F8:       60            RTS    

CODE_01A8F9:        AD 97 14      LDA.W $1497               ; \ Return if Mario is invincible 
CODE_01A8FC:        D0 1D         BNE Return01A91B          ; / 
CODE_01A8FE:        AD 7A 18      LDA.W RAM_OnYoshi         
CODE_01A901:        D0 18         BNE Return01A91B          
CODE_01A903:        BD 86 16      LDA.W RAM_Tweaker1686,X   
CODE_01A906:        29 10         AND.B #$10                
CODE_01A908:        D0 07         BNE CODE_01A911           
CODE_01A90A:        20 30 AD      JSR.W SubHorizPos         
CODE_01A90D:        98            TYA                       
CODE_01A90E:        9D 7C 15      STA.W RAM_SpriteDir,X     
CODE_01A911:        B5 9E         LDA RAM_SpriteNum,X       
CODE_01A913:        C9 53         CMP.B #$53                
CODE_01A915:        F0 04         BEQ Return01A91B          
CODE_01A917:        22 B7 F5 00   JSL.L HurtMario           
Return01A91B:       60            RTS     

CODE_01A91C:        AD 0D 14      LDA.W RAM_IsSpinJump      
CODE_01A91F:        0D 7A 18      ORA.W RAM_OnYoshi         
CODE_01A922:        F0 23         BEQ CODE_01A947           
CODE_01A924:        22 99 AB 01   JSL.L DisplayContactGfx   
CODE_01A928:        A9 F8         LDA.B #$F8                
CODE_01A92A:        85 7D         STA RAM_MarioSpeedY       
CODE_01A92C:        AD 7A 18      LDA.W RAM_OnYoshi         
CODE_01A92F:        F0 04         BEQ CODE_01A935           
CODE_01A931:        22 33 AA 01   JSL.L BoostMarioSpeed     
CODE_01A935:        20 CB 9A      JSR.W CODE_019ACB         
CODE_01A938:        22 3B FC 07   JSL.L CODE_07FC3B         
CODE_01A93C:        20 46 AB      JSR.W CODE_01AB46         
CODE_01A93F:        A9 08         LDA.B #$08                
CODE_01A941:        8D F9 1D      STA.W $1DF9               ; / Play sound effect 
CODE_01A944:        4C F2 A9      JMP.W CODE_01A9F2   




CODE_019ACB:        A9 04         LDA.B #$04                ;  | ...Sprite status = Spin Jump Killed... 
CODE_019ACD:        9D C8 14      STA.W $14C8,X             ;  | 
CODE_019AD0:        A9 1F         LDA.B #$1F                ;  | ...Set Time to show smoke cloud... 
CODE_019AD2:        9D 40 15      STA.W $1540,X             ;  | 
Return019AD5:       60            RTS                       ; / ... and return 


	LDA !1656,x				; \
	AND #$10					; | check tweaker bit "Can be jumped on"
	BNE .jump				; /

	LDA $140D|!Base2		; \ if not spinjumping...
	ORA $187A|!Base2		; | ...or on yoshi...
	BEQ .check2				; / ...branch
.sfx_gfx_speed
	LDA #$02					; \ Play sound effect
	STA $1DF9|!Base2		; / 
	JSL $01AA33				; Boost Mario speed
	JSL $01AB99				; Display Contact Gfx
	RTL
	
.check2
	LDA $13ED|!Base2		; \
	BEQ .hurt				; / branch if not sliding
	LDA !190F,x				; \
	AND #$04					; | check tweaker bit "can't be killed by sliding"
	BNE .hurt				; /
	LDA #$03					; \ Play "kick" sound effect 
	STA $1DF9|!Base2		; / 
	JSR .slide_kill		; CODE_01A847
	RTL

.hurt
	LDA $1497|!Base2		; \
	BNE +						; / return if invincible
	LDA $187A|!Base2		; or on yoshi
	BNE +
	LDA !1686,x				; \
	AND #$10					; | check tweaker bit "don't change direction if touched"
	BNE ++					; /
	
	JSR .SubHorizPos		; \
	TYA						; | update direction
	STA !157C,x				; /
	
++ JSL $00F5B7				; hurt Mario	
+	RTL

.jump
	LDA $140D|!Base2		; \ if not spinjumping...
	ORA $187A|!Base2		; | ...or on yoshi...
	BEQ ..normal			; / branch to normal kill (CODE_01A947)
	JSL $01AB99				; Display Contact Gfx
	LDA #$F8					; \ slight upwards speed for Mario
	STA $7D					; /
	LDA $187A|!Base2		; \ if on yoshi...
	BEQ +						; | allow for boost Mario speed
	JSL $01AA33				; / 
+	LDA #$04					; \
	STA !14C8,x				; / sprite = spin killed
	LDA #$1F					; \
	STA !1540,x				; / smoke cloud timer
	JSL $07FC3B				; spin jump star GFX routine
	JSR .calc_points		; calculate points
	LDA #$08					; \ Play "spinkill" sound effect 
	STA $1DF9|!Base2		; / 
	RTL
	
..normal
	JSL .sfx_gfx_speed	; 
	LDA !187B,x				; Sprite stomp immunity flag table - enables stomp immunity for sprites if the flag is set.
	BEQ ..not_bounce
	JSR .SubHorizPos		; throws Mario away from the sprite?
	LDA #$18
	CPY #$00
	BEQ +
	LDA #$E8
+	STA $7B
	RTL
	
	
..not_bounce
	JSR .calc_points		; calculate points
	LDA !1686,x				; \
	AND #$40					; | check tweaker bit "spawn new sprite when jumped on"
	BEQ ..no_spawn			; /
	
	;TODO Add spawn routine :3
	
..no_spawn
	LDA !1656,x				; \
	AND #$20					; | check tweaker bit "Dies when jumped on"
	BEQ +						; / branch if not set.
	LDA #$03					; \
	STA !14C8,x				; / sprite status = smushed
	LDA #$20					; \
	STA !1540,x				; / smushed timer (before disappear)
	STZ !B6,x				; \
	STZ !AA,x				; / halt speed
	RTL
	
;--------------------------------------------------------------------------------
; Actual Subroutines:	

.calc_points
	PHY
	LDA $1697|!Base2		; Consecutive enemies stomped by Mario
	CLC						;
	ADC !1626,x				; Consecutive enemies killed by a sprite (like a thrown shell)
	INC $1697|!Base2
	TAY : INY
	CPY #$08
	BCS +
	LDA ..sounds-1,y
	STA $1DF9|!Base2
+	TYA
	CMP #$08
	BCC +
	LDA #$08
+	JSL $02ACE5				; give points
	PLY
	RTS

.sounds
	db $13,$14,$15,$16,$17,$18,$19

	
.SubHorizPos
	LDY #$00
	LDA $D1
	SEC
	SBC !E4,x
	STA $0F
	LDA $D2
	SBC !14E0,x
	BPL +
	INY
+	RTS
	
	
.slide_kill:
	JSL $01AB6F			; Display the white star effect
	
	;Code below removed because it was buggy in SMW to begin with
	;slide kill chain was always force reset in sprites.
	;doing this in custom sprites and not resetting by hand would
	;cause infinite increase. Uncomment at own risk	
	LDY #$01		;remove this if you uncomment.
	
	; INC $18D2|!Base2	; increment for star/slide kill counter
	; LDA $18D2|!Base2
	; CMP #$08
	; BCC +
	; LDA #$08
	; STA $18D2|!Base2	
; +	JSL $02ACE5			;
	; LDY $18D2|!Base2	
	; CPY #$08
	; BCS +	
	
	
	LDA ..sounds-1,y
	STA $1DF9|!Base2	
+	LDA #$02
	STA !14C8,x
	LDA #$D0
	STA !AA,x
	JSR .SubHorizPos	
	LDA ..data,y
	STA !B6,x
	CLC
	RTS
	
..data
	db $F0,$10
	
CODE_01A847:        22 6F AB 01   JSL.L CODE_01AB6F         
CODE_01A84B:        EE D2 18      INC.W $18D2               
CODE_01A84E:        AD D2 18      LDA.W $18D2               
CODE_01A851:        C9 08         CMP.B #$08                
CODE_01A853:        90 05         BCC CODE_01A85A           
CODE_01A855:        A9 08         LDA.B #$08                
CODE_01A857:        8D D2 18      STA.W $18D2               
CODE_01A85A:        22 E5 AC 02   JSL.L GivePoints          
CODE_01A85E:        AC D2 18      LDY.W $18D2               
CODE_01A861:        C0 08         CPY.B #$08                
CODE_01A863:        B0 06         BCS CODE_01A86B           
CODE_01A865:        B9 1D A6      LDA.W Return01A61D,Y      
CODE_01A868:        8D F9 1D      STA.W $1DF9               ; / Play sound effect 
CODE_01A86B:        A9 02         LDA.B #$02                ; \ Sprite status = Killed 
CODE_01A86D:        9D C8 14      STA.W $14C8,X             ; / 
CODE_01A870:        A9 D0         LDA.B #$D0                
CODE_01A872:        95 AA         STA RAM_SpriteSpeedY,X    
CODE_01A874:        20 30 AD      JSR.W SubHorizPos         
CODE_01A877:        B9 39 A8      LDA.W DATA_01A839,Y       
CODE_01A87A:        95 B6         STA RAM_SpriteSpeedX,X    
ReturnNoContact2:   18            CLC                       
Return01A87D:       60            RTS                       ; Return 
	
DATA_01A839:                      .db $F0,$10
	
SubHorizPos:        A0 00         LDY.B #$00                
CODE_01AD32:        A5 D1         LDA $D1                   
CODE_01AD34:        38            SEC                       
CODE_01AD35:        F5 E4         SBC RAM_SpriteXLo,X       
CODE_01AD37:        85 0F         STA $0F                   
CODE_01AD39:        A5 D2         LDA $D2                   
CODE_01AD3B:        FD E0 14      SBC.W RAM_SpriteXHi,X     
CODE_01AD3E:        10 01         BPL Return01AD41          
CODE_01AD40:        C8            INY                       
Return01AD41:       60            RTS                       ; Return 
	
	
CODE_01A947:        20 D8 A8      JSR.W CODE_01A8D8         
CODE_01A94A:        BD 7B 18      LDA.W $187B,X             
CODE_01A94D:        F0 0E         BEQ CODE_01A95D           
CODE_01A94F:        20 30 AD      JSR.W SubHorizPos         
CODE_01A952:        A9 18         LDA.B #$18                
CODE_01A954:        C0 00         CPY.B #$00                
CODE_01A956:        F0 02         BEQ CODE_01A95A           
CODE_01A958:        A9 E8         LDA.B #$E8                
CODE_01A95A:        85 7B         STA RAM_MarioSpeedX       
Return01A95C:       60            RTS                       ; Return 
	
	
	
CODE_01A95D:        20 46 AB      JSR.W CODE_01AB46         
CODE_01A960:        B4 9E         LDY RAM_SpriteNum,X       
CODE_01A962:        BD 86 16      LDA.W RAM_Tweaker1686,X   
CODE_01A965:        29 40         AND.B #$40                
CODE_01A967:        F0 55         BEQ CODE_01A9BE           
CODE_01A969:        C0 72         CPY.B #$72                
CODE_01A96B:        90 0C         BCC CODE_01A979           
CODE_01A96D:        DA            PHX                       
CODE_01A96E:        5A            PHY                       
CODE_01A96F:        22 F2 EA 02   JSL.L CODE_02EAF2         ; super kooper spawning routine
CODE_01A973:        7A            PLY                       
CODE_01A974:        FA            PLX                       
CODE_01A975:        A9 02         LDA.B #$02                
CODE_01A977:        80 22         BRA CODE_01A99B   


CODE_01A9BE:        B5 9E         LDA RAM_SpriteNum,X       
CODE_01A9C0:        38            SEC                       
CODE_01A9C1:        E9 04         SBC.B #$04                
CODE_01A9C3:        C9 0D         CMP.B #$0D                
CODE_01A9C5:        B0 05         BCS CODE_01A9CC           
CODE_01A9C7:        AD 07 14      LDA.W $1407               
CODE_01A9CA:        D0 07         BNE CODE_01A9D3           
CODE_01A9CC:        BD 56 16      LDA.W RAM_Tweaker1656,X   ; \ Branch if doesn't die when jumped on 
CODE_01A9CF:        29 20         AND.B #$20                ;  | 
CODE_01A9D1:        F0 0F         BEQ CODE_01A9E2           ; / 
CODE_01A9D3:        A9 03         LDA.B #$03                ; \ Sprite status = Smushed 
CODE_01A9D5:        9D C8 14      STA.W $14C8,X             ; / 
CODE_01A9D8:        A9 20         LDA.B #$20                
CODE_01A9DA:        9D 40 15      STA.W $1540,X             
CODE_01A9DD:        74 B6         STZ RAM_SpriteSpeedX,X    ; \ Sprite Speed = 0 
CODE_01A9DF:        74 AA         STZ RAM_SpriteSpeedY,X    ; / 
Return01A9E1:       60            RTS                       ; Return 
	

CODE_01AB46:        5A            PHY                       
CODE_01AB47:        AD 97 16      LDA.W $1697               
CODE_01AB4A:        18            CLC                       
CODE_01AB4B:        7D 26 16      ADC.W $1626,X             
CODE_01AB4E:        EE 97 16      INC.W $1697               
CODE_01AB51:        A8            TAY                       
CODE_01AB52:        C8            INY                       
CODE_01AB53:        C0 08         CPY.B #$08                
CODE_01AB55:        B0 06         BCS CODE_01AB5D           
CODE_01AB57:        B9 1D A6      LDA.W Return01A61D,Y      
CODE_01AB5A:        8D F9 1D      STA.W $1DF9               ; / Play sound effect 
CODE_01AB5D:        98            TYA                       
CODE_01AB5E:        C9 08         CMP.B #$08                
CODE_01AB60:        90 02         BCC CODE_01AB64           
CODE_01AB62:        A9 08         LDA.B #$08                
CODE_01AB64:        22 E5 AC 02   JSL.L GivePoints          
CODE_01AB68:        7A            PLY                       
Return01AB69:       60            RTS                       ; Return 













