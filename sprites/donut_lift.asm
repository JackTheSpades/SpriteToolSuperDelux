;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Donut Lift (sprite portion), by mikeyk
;; asar support by JackTheSpades
;;
;; Description: 
;;
;; NOTE: This sprite works in conjunction with a custom block. The MAP16 number for
;; the block must be specified where it says !DONUT_MAP16_NUM, likewise, the in the block
;; you have to set the sprite number to whatever you insert this sprite as.
;;
;; The block is to be inserted with GPS and can be found in the asm/Blocks folder or
;; downloaded here: (All credit to mikeyk and Davros)
;; https://www.smwcentral.net/?p=section&a=details&id=11690
;; 
;; Uses first extra bit: NO
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        !DONUT_MAP16_NUM = $0300             ; map16 value of the donut block in hex        
        !DONUT_SPRITE_TILE = $80             ; graphic tile to use for donut sprite

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; init JSL
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

print "INIT ",pc
		RTL

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; main sprite JSL
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

print "MAIN ",pc
		PHB                     ; \ 
		PHK                     ;  |
		PLB                     ;  |
		JSR DONUT_CODE_START    ;  |
		PLB                     ;  |
		RTL                     ; /


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; donut main code 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DONUT_CODE_START:

		JSR DONUT_GRAPHICS      ;gfx routine
		LDA #$00
		%SubOffScreen()			;Sub_Off_Screen_X0

		LDA $9D                 ; \ if sprites locked, RETURN
		BNE .return             ; /
		LDA !14C8,x
		CMP #$08
		BNE .return

		LDA !AA,x               ;if y speed = 0, jumps to timer code
		BEQ .timer
		
		LDA !AA,x               ;caps y speed at #$38
		CMP #$38  
		BPL + 
		CLC : ADC #$02   
		STA !AA,x
+		JSL $01801A             ;sets speed

		LDA #$01						;keep timer at #$01 timer (we're falling already)
		STA !1558,x
				
.timer
		JSL $01B44F             ;interact with sprite
		BCC MAKE_BLOCK          ;if not on donut lift, change sprite to map16 block

		LDA !1558,x             ;if the timer hasn't been set, set timer
		BNE +
		LDA #$28    
		STA !1558,x 
		
+		DEC A                   ;decrements timer
		STA !1558,x     
		CMP #$01                ;if the timer is down to 1, set y speed
		BNE .return 
		LDA #$0B                ;y speed=0B
		STA !AA,x       
.return
		RTS

MAKE_BLOCK:
		LDA !AA,x
		BNE Return
		STZ !14C8,x             ; destroy the sprite
		STZ !1558,x             ; reset timer

		LDA !E4,x               ; \  setup block properties
		STA $9A                 ;  |
		LDA !14E0,x             ;  |
		STA $9B                 ;  |
		LDA !D8,x               ;  |
		STA $98                 ;  |
		LDA !14D4,x             ;  |
		STA $99                 ; /

		PHP
		REP #$30                ; \ change sprite to block 
		LDA.w #!DONUT_MAP16_NUM ;  |
		%ChangeMap16()          ;  |
		PLP                     ; / 
Return:
		RTS     


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; donut graphics routine - specific 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DONUT_GRAPHICS:     
		%GetDrawInfo()          
                    
		LDA !AA,x
		BNE +

		LDA $14    
		AND #$02   
		BNE +
		LDA !1558,x
		BEQ +

		DEC $00

+		LDA $00                 ; \ tile x position = sprite x location ($00)
		STA $0300|!Base2,y      ; /
		LDA $01                 ; \ tile y position = sprite y location ($01)
		STA $0301|!Base2,y      ; /

		LDA !15F6,x             ; tile properties xyppccct, format
		ORA $64                 ; add in tile priority of level
		STA $0303|!Base2,y      ; store tile properties

		LDA #!DONUT_SPRITE_TILE ; \ store tile
		STA $0302|!Base2,y      ; /

		LDY #$02                ; \ 460 = 2 (all 16x16 tiles)
		LDA #$00                ;  | A = (number of tiles drawn - 1)
		JSL $01B7B3             ; / don't draw if offscreen
		RTS                     ; RETURN

            
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; map16 subroutine
; doesn't work with mario allstars
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; SUBL_SET_MAP16:      PHP                     ;A:0266 X:0007 Y:0001 D:0000 DB:01 S:01EE P:envmxdizcHC:1306 VC:149 00 FL:1681
                    ; REP #$30                ;A:0266 X:0007 Y:0001 D:0000 DB:01 S:01ED P:envmxdizcHC:1328 VC:149 00 FL:1681
                    ; PHY                     ;A:0266 X:0007 Y:0001 D:0000 DB:01 S:01ED P:envmxdizcHC:1350 VC:149 00 FL:1681
                    ; PHX                     ;A:0266 X:0007 Y:0001 D:0000 DB:01 S:01EB P:envmxdizcHC:0012 VC:150 00 FL:1681
                    ; TAX                     ;A:0266 X:0007 Y:0001 D:0000 DB:01 S:01E9 P:envmxdizcHC:0042 VC:150 00 FL:1681
                    ; LDA $03                 ;A:0266 X:0266 Y:0001 D:0000 DB:01 S:01E9 P:envmxdizcHC:0056 VC:150 00 FL:1681
                    ; PHA                     ;A:0266 X:0266 Y:0001 D:0000 DB:01 S:01E9 P:envmxdizcHC:0088 VC:150 00 FL:1681
                    ; JSR SUB_8034            ;A:0266 X:0266 Y:0001 D:0000 DB:01 S:01E7 P:envmxdizcHC:0118 VC:150 00 FL:1681
                    ; PLA                     ;A:0010 X:0000 Y:0006 D:0000 DB:00 S:01DC P:envmxdizCHC:0726 VC:032 00 FL:11805
                    ; STA $03                 ;A:02A8 X:0000 Y:0006 D:0000 DB:00 S:01DE P:envmxdizCHC:0762 VC:032 00 FL:11805
                    ; PLX                     ;A:02A8 X:0000 Y:0006 D:0000 DB:00 S:01DE P:envmxdizCHC:0794 VC:032 00 FL:11805
                    ; PLY                     ;A:02A8 X:0020 Y:0006 D:0000 DB:00 S:01E0 P:envmxdizCHC:0830 VC:032 00 FL:11805
                    ; PLP                     ;A:02A8 X:0020 Y:0001 D:0000 DB:00 S:01E2 P:envmxdizCHC:0866 VC:032 00 FL:11805
                    ; RTS                     ;A:02A8 X:0020 Y:0001 D:0000 DB:00 S:01E3 P:envmxdizCHC:0894 VC:032 00 FL:11805

                    ; JMP $FEA301
; RETURN18:            PLX
                    ; PLB
                    ; PLP
                    ; RTS

; SUB_8034:            PHP                     ;A:0266 X:0266 Y:0001 D:0000 DB:01 S:01E5 P:envmxdizcHC:0164 VC:150 00 FL:1682
                    ; SEP #$20                ;A:0266 X:0266 Y:0001 D:0000 DB:01 S:01E4 P:envmxdizcHC:0186 VC:150 00 FL:1682
                    ; PHB                     ;A:0266 X:0266 Y:0001 D:0000 DB:01 S:01E4 P:envMxdizcHC:0208 VC:150 00 FL:1682
                    ; LDA #$00                ;A:0200 X:0266 Y:0001 D:0000 DB:01 S:01E3 P:envMxdiZcHC:0286 VC:150 00 FL:1682
                    ; PHA                     ;A:0200 X:0266 Y:0001 D:0000 DB:01 S:01E3 P:envMxdiZcHC:0324 VC:150 00 FL:1682
                    ; PLB                     ;A:0200 X:0266 Y:0001 D:0000 DB:01 S:01E2 P:envMxdiZcHC:0346 VC:150 00 FL:1682
                    ; REP #$30                ;A:0200 X:0266 Y:0001 D:0000 DB:00 S:01E3 P:envMxdiZcHC:0374 VC:150 00 FL:1682
                    ; PHX                     ;A:0200 X:0266 Y:0001 D:0000 DB:00 S:01E3 P:envmxdiZcHC:0396 VC:150 00 FL:1682
                    ; LDA $9A                 ;A:0200 X:0266 Y:0001 D:0000 DB:00 S:01E1 P:envmxdiZcHC:0426 VC:150 00 FL:1682
                    ; STA $0C                 ;A:0070 X:0266 Y:0001 D:0000 DB:00 S:01E1 P:envmxdizcHC:0458 VC:150 00 FL:1682
                    ; LDA $98                 ;A:0070 X:0266 Y:0001 D:0000 DB:00 S:01E1 P:envmxdizcHC:0490 VC:150 00 FL:1682
                    ; STA $0E                 ;A:0130 X:0266 Y:0001 D:0000 DB:00 S:01E1 P:envmxdizcHC:0522 VC:150 00 FL:1682
                    ; LDA.w #$0000            ;A:0130 X:0266 Y:0001 D:0000 DB:00 S:01E1 P:envmxdizcHC:0554 VC:150 00 FL:1682
                    ; SEP #$20                ;A:0000 X:0266 Y:0001 D:0000 DB:00 S:01E1 P:envmxdiZcHC:0578 VC:150 00 FL:1682
                    ; LDA $5B                 ;A:0000 X:0266 Y:0001 D:0000 DB:00 S:01E1 P:envMxdiZcHC:0600 VC:150 00 FL:1682
                    ; STA $09                 ;A:0000 X:0266 Y:0001 D:0000 DB:00 S:01E1 P:envMxdiZcHC:0624 VC:150 00 FL:1682
                    ; LDA $1933               ;A:0000 X:0266 Y:0001 D:0000 DB:00 S:01E1 P:envMxdiZcHC:0648 VC:150 00 FL:1682
                    ; BEQ NO_SHIFT            ;A:0000 X:0266 Y:0001 D:0000 DB:00 S:01E1 P:envMxdiZcHC:0680 VC:150 00 FL:1682
                    ; LSR $09
; NO_SHIFT:            LDY $0E                 ;A:0000 X:0266 Y:0001 D:0000 DB:00 S:01E1 P:envMxdiZcHC:0702 VC:150 00 FL:1682
                    ; LDA $09                 ;A:0000 X:0266 Y:0130 D:0000 DB:00 S:01E1 P:envMxdizcHC:0734 VC:150 00 FL:1682
                    ; AND #$01                ;A:0000 X:0266 Y:0130 D:0000 DB:00 S:01E1 P:envMxdiZcHC:0758 VC:150 00 FL:1682
                    ; BEQ HORIZ               ;A:0000 X:0266 Y:0130 D:0000 DB:00 S:01E1 P:envMxdiZcHC:0774 VC:150 00 FL:1682
                    ; LDA $9B
                    ; STA $00
                    ; LDA $99
                    ; STA $9B
                    ; LDA $00  
                    ; STA $99
                    ; LDY $0C
; HORIZ:               CPY.w #$0200            ;A:0000 X:0266 Y:0130 D:0000 DB:00 S:01E1 P:envMxdiZcHC:0796 VC:150 00 FL:1682
                    ; BCS RETURN18            ;A:0000 X:0266 Y:0130 D:0000 DB:00 S:01E1 P:eNvMxdizcHC:0820 VC:150 00 FL:1682
                    ; LDA $1933               ;A:0000 X:0266 Y:0130 D:0000 DB:00 S:01E1 P:eNvMxdizcHC:0836 VC:150 00 FL:1682
                    ; ASL A                   ;A:0000 X:0266 Y:0130 D:0000 DB:00 S:01E1 P:envMxdiZcHC:0868 VC:150 00 FL:1682
                    ; TAX                     ;A:0000 X:0266 Y:0130 D:0000 DB:00 S:01E1 P:envMxdiZcHC:0882 VC:150 00 FL:1682
                    ; LDA $BEA8,x ;[$00:BEA8] ;A:0000 X:0000 Y:0130 D:0000 DB:00 S:01E1 P:envMxdiZcHC:0896 VC:150 00 FL:1682
                    ; STA $65                 ;A:00A8 X:0000 Y:0130 D:0000 DB:00 S:01E1 P:eNvMxdizcHC:0928 VC:150 00 FL:1682
                    ; LDA $BEA9,x ;[$00:BEA9] ;A:00A8 X:0000 Y:0130 D:0000 DB:00 S:01E1 P:eNvMxdizcHC:0952 VC:150 00 FL:1682
                    ; STA $66                 ;A:00BD X:0000 Y:0130 D:0000 DB:00 S:01E1 P:eNvMxdizcHC:0984 VC:150 00 FL:1682
                    ; STZ $67                 ;A:00BD X:0000 Y:0130 D:0000 DB:00 S:01E1 P:eNvMxdizcHC:1008 VC:150 00 FL:1682
                    ; LDA $1925               ;A:00BD X:0000 Y:0130 D:0000 DB:00 S:01E1 P:eNvMxdizcHC:1032 VC:150 00 FL:1682
                    ; ASL A                   ;A:0000 X:0000 Y:0130 D:0000 DB:00 S:01E1 P:envMxdiZcHC:1064 VC:150 00 FL:1682
                    ; TAY                     ;A:0000 X:0000 Y:0130 D:0000 DB:00 S:01E1 P:envMxdiZcHC:1078 VC:150 00 FL:1682
                    ; LDA ($65),y ;[$00:BDA8] ;A:0000 X:0000 Y:0000 D:0000 DB:00 S:01E1 P:envMxdiZcHC:1092 VC:150 00 FL:1682
                    ; STA $04                 ;A:00D8 X:0000 Y:0000 D:0000 DB:00 S:01E1 P:eNvMxdizcHC:1132 VC:150 00 FL:1682
                    ; INY                     ;A:00D8 X:0000 Y:0000 D:0000 DB:00 S:01E1 P:eNvMxdizcHC:1156 VC:150 00 FL:1682
                    ; LDA ($65),y ;[$00:BDA9] ;A:00D8 X:0000 Y:0001 D:0000 DB:00 S:01E1 P:envMxdizcHC:1170 VC:150 00 FL:1682
                    ; STA $05                 ;A:00BA X:0000 Y:0001 D:0000 DB:00 S:01E1 P:eNvMxdizcHC:1210 VC:150 00 FL:1682
                    ; STZ $06                 ;A:00BA X:0000 Y:0001 D:0000 DB:00 S:01E1 P:eNvMxdizcHC:1234 VC:150 00 FL:1682
                    ; LDA $9B                 ;A:00BA X:0000 Y:0001 D:0000 DB:00 S:01E1 P:eNvMxdizcHC:1258 VC:150 00 FL:1682
                    ; STA $07                 ;A:0000 X:0000 Y:0001 D:0000 DB:00 S:01E1 P:envMxdiZcHC:1282 VC:150 00 FL:1682
                    ; ASL A                   ;A:0000 X:0000 Y:0001 D:0000 DB:00 S:01E1 P:envMxdiZcHC:1306 VC:150 00 FL:1682
                    ; CLC                     ;A:0000 X:0000 Y:0001 D:0000 DB:00 S:01E1 P:envMxdiZcHC:1320 VC:150 00 FL:1682
                    ; ADC $07                 ;A:0000 X:0000 Y:0001 D:0000 DB:00 S:01E1 P:envMxdiZcHC:1334 VC:150 00 FL:1682
                    ; TAY                     ;A:0000 X:0000 Y:0001 D:0000 DB:00 S:01E1 P:envMxdiZcHC:1358 VC:150 00 FL:1682
                    ; LDA ($04),y ;[$00:BAD8] ;A:0000 X:0000 Y:0000 D:0000 DB:00 S:01E1 P:envMxdiZcHC:0004 VC:151 00 FL:1682
                    ; STA $6B                 ;A:0000 X:0000 Y:0000 D:0000 DB:00 S:01E1 P:envMxdiZcHC:0044 VC:151 00 FL:1682
                    ; STA $6E                 ;A:0000 X:0000 Y:0000 D:0000 DB:00 S:01E1 P:envMxdiZcHC:0068 VC:151 00 FL:1682
                    ; INY                     ;A:0000 X:0000 Y:0000 D:0000 DB:00 S:01E1 P:envMxdiZcHC:0092 VC:151 00 FL:1682
                    ; LDA ($04),y ;[$00:BAD9] ;A:0000 X:0000 Y:0001 D:0000 DB:00 S:01E1 P:envMxdizcHC:0106 VC:151 00 FL:1682
                    ; STA $6C                 ;A:00C8 X:0000 Y:0001 D:0000 DB:00 S:01E1 P:eNvMxdizcHC:0146 VC:151 00 FL:1682
                    ; STA $6F                 ;A:00C8 X:0000 Y:0001 D:0000 DB:00 S:01E1 P:eNvMxdizcHC:0170 VC:151 00 FL:1682
                    ; LDA #$7E                ;A:00C8 X:0000 Y:0001 D:0000 DB:00 S:01E1 P:eNvMxdizcHC:0194 VC:151 00 FL:1682
                    ; STA $6D                 ;A:007E X:0000 Y:0001 D:0000 DB:00 S:01E1 P:envMxdizcHC:0210 VC:151 00 FL:1682
                    ; INC A                   ;A:007E X:0000 Y:0001 D:0000 DB:00 S:01E1 P:envMxdizcHC:0234 VC:151 00 FL:1682
                    ; STA $70                 ;A:007F X:0000 Y:0001 D:0000 DB:00 S:01E1 P:envMxdizcHC:0248 VC:151 00 FL:1682
                    ; LDA $09                 ;A:007F X:0000 Y:0001 D:0000 DB:00 S:01E1 P:envMxdizcHC:0272 VC:151 00 FL:1682
                    ; AND #$01                ;A:0000 X:0000 Y:0001 D:0000 DB:00 S:01E1 P:envMxdiZcHC:0296 VC:151 00 FL:1682
                    ; BEQ NO_AND              ;A:0000 X:0000 Y:0001 D:0000 DB:00 S:01E1 P:envMxdiZcHC:0312 VC:151 00 FL:1682
                    ; LDA $99
                    ; LSR A
                    ; LDA $9B 
                    ; AND #$01
                    ; BRA LABEL52
; NO_AND:              LDA $9B                 ;A:0000 X:0000 Y:0001 D:0000 DB:00 S:01E1 P:envMxdiZcHC:0334 VC:151 00 FL:1682
                    ; LSR A                   ;A:0000 X:0000 Y:0001 D:0000 DB:00 S:01E1 P:envMxdiZcHC:0358 VC:151 00 FL:1682
                    ; LDA $99                 ;A:0000 X:0000 Y:0001 D:0000 DB:00 S:01E1 P:envMxdiZcHC:0372 VC:151 00 FL:1682
; LABEL52:             ROL A                   ;A:0001 X:0000 Y:0001 D:0000 DB:00 S:01E1 P:envMxdizcHC:0396 VC:151 00 FL:1682
                    ; ASL A                   ;A:0002 X:0000 Y:0001 D:0000 DB:00 S:01E1 P:envMxdizcHC:0410 VC:151 00 FL:1682
                    ; ASL A                   ;A:0004 X:0000 Y:0001 D:0000 DB:00 S:01E1 P:envMxdizcHC:0424 VC:151 00 FL:1682
                    ; ORA #$20                ;A:0008 X:0000 Y:0001 D:0000 DB:00 S:01E1 P:envMxdizcHC:0438 VC:151 00 FL:1682
                    ; STA $04                 ;A:0028 X:0000 Y:0001 D:0000 DB:00 S:01E1 P:envMxdizcHC:0454 VC:151 00 FL:1682
                    ; CPX.w #$0000            ;A:0028 X:0000 Y:0001 D:0000 DB:00 S:01E1 P:envMxdizcHC:0478 VC:151 00 FL:1682
                    ; BEQ NO_ADD              ;A:0028 X:0000 Y:0001 D:0000 DB:00 S:01E1 P:envMxdiZCHC:0502 VC:151 00 FL:1682
                    ; CLC
                    ; ADC #$10 
                    ; STA $04
; NO_ADD:              LDA $98                 ;A:0028 X:0000 Y:0001 D:0000 DB:00 S:01E1 P:envMxdiZCHC:0524 VC:151 00 FL:1682
                    ; AND #$F0                ;A:0030 X:0000 Y:0001 D:0000 DB:00 S:01E1 P:envMxdizCHC:0548 VC:151 00 FL:1682
                    ; CLC                     ;A:0030 X:0000 Y:0001 D:0000 DB:00 S:01E1 P:envMxdizCHC:0564 VC:151 00 FL:1682
                    ; ASL A                   ;A:0030 X:0000 Y:0001 D:0000 DB:00 S:01E1 P:envMxdizcHC:0578 VC:151 00 FL:1682
                    ; ROL A                   ;A:0060 X:0000 Y:0001 D:0000 DB:00 S:01E1 P:envMxdizcHC:0592 VC:151 00 FL:1682
                    ; STA $05                 ;A:00C0 X:0000 Y:0001 D:0000 DB:00 S:01E1 P:eNvMxdizcHC:0606 VC:151 00 FL:1682
                    ; ROL A                   ;A:00C0 X:0000 Y:0001 D:0000 DB:00 S:01E1 P:eNvMxdizcHC:0630 VC:151 00 FL:1682
                    ; AND #$03                ;A:0080 X:0000 Y:0001 D:0000 DB:00 S:01E1 P:eNvMxdizCHC:0644 VC:151 00 FL:1682
                    ; ORA $04                 ;A:0000 X:0000 Y:0001 D:0000 DB:00 S:01E1 P:envMxdiZCHC:0660 VC:151 00 FL:1682
                    ; STA $06                 ;A:0028 X:0000 Y:0001 D:0000 DB:00 S:01E1 P:envMxdizCHC:0684 VC:151 00 FL:1682
                    ; LDA $9A                 ;A:0028 X:0000 Y:0001 D:0000 DB:00 S:01E1 P:envMxdizCHC:0708 VC:151 00 FL:1682
                    ; AND #$F0                ;A:0070 X:0000 Y:0001 D:0000 DB:00 S:01E1 P:envMxdizCHC:0732 VC:151 00 FL:1682
                    ; LSR A                   ;A:0070 X:0000 Y:0001 D:0000 DB:00 S:01E1 P:envMxdizCHC:0748 VC:151 00 FL:1682
                    ; LSR A                   ;A:0038 X:0000 Y:0001 D:0000 DB:00 S:01E1 P:envMxdizcHC:0762 VC:151 00 FL:1682
                    ; LSR A                   ;A:001C X:0000 Y:0001 D:0000 DB:00 S:01E1 P:envMxdizcHC:0776 VC:151 00 FL:1682
                    ; STA $04                 ;A:000E X:0000 Y:0001 D:0000 DB:00 S:01E1 P:envMxdizcHC:0790 VC:151 00 FL:1682
                    ; LDA $05                 ;A:000E X:0000 Y:0001 D:0000 DB:00 S:01E1 P:envMxdizcHC:0814 VC:151 00 FL:1682
                    ; AND #$C0                ;A:00C0 X:0000 Y:0001 D:0000 DB:00 S:01E1 P:eNvMxdizcHC:0838 VC:151 00 FL:1682
                    ; ORA $04                 ;A:00C0 X:0000 Y:0001 D:0000 DB:00 S:01E1 P:eNvMxdizcHC:0854 VC:151 00 FL:1682
                    ; STA $07                 ;A:00CE X:0000 Y:0001 D:0000 DB:00 S:01E1 P:eNvMxdizcHC:0878 VC:151 00 FL:1682
                    ; REP #$20                ;A:00CE X:0000 Y:0001 D:0000 DB:00 S:01E1 P:eNvMxdizcHC:0902 VC:151 00 FL:1682
                    ; LDA $09                 ;A:00CE X:0000 Y:0001 D:0000 DB:00 S:01E1 P:eNvmxdizcHC:0924 VC:151 00 FL:1682
                    ; AND.w #$0001            ;A:0100 X:0000 Y:0001 D:0000 DB:00 S:01E1 P:envmxdizcHC:0956 VC:151 00 FL:1682
                    ; BNE LABEL51             ;A:0000 X:0000 Y:0001 D:0000 DB:00 S:01E1 P:envmxdiZcHC:0980 VC:151 00 FL:1682
                    ; LDA $1A                 ;A:0000 X:0000 Y:0001 D:0000 DB:00 S:01E1 P:envmxdiZcHC:0996 VC:151 00 FL:1682
                    ; SEC                     ;A:0000 X:0000 Y:0001 D:0000 DB:00 S:01E1 P:envmxdiZcHC:1028 VC:151 00 FL:1682
                    ; SBC.w #$0080            ;A:0000 X:0000 Y:0001 D:0000 DB:00 S:01E1 P:envmxdiZCHC:1042 VC:151 00 FL:1682
                    ; TAX                     ;A:FF80 X:0000 Y:0001 D:0000 DB:00 S:01E1 P:eNvmxdizcHC:1066 VC:151 00 FL:1682
                    ; LDY $1C                 ;A:FF80 X:FF80 Y:0001 D:0000 DB:00 S:01E1 P:eNvmxdizcHC:1080 VC:151 00 FL:1682
                    ; LDA $1933               ;A:FF80 X:FF80 Y:00C0 D:0000 DB:00 S:01E1 P:envmxdizcHC:1112 VC:151 00 FL:1682
                    ; BEQ LABEL50             ;A:0000 X:FF80 Y:00C0 D:0000 DB:00 S:01E1 P:envmxdiZcHC:1152 VC:151 00 FL:1682
                    ; LDX $1E
                    ; LDA $20
                    ; SEC
                    ; SBC.w #$0080
                    ; TAY
                    ; BRA LABEL50
; LABEL51:             LDX $1A
                    ; LDA $1C
                    ; SEC
                    ; SBC.w #$0080
                    ; TAY
                    ; LDA $1933
                    ; BEQ LABEL50
                    ; LDA $1E
                    ; SEC
                    ; SBC.w #$0080
                    ; TAX  
                    ; LDY $20
; LABEL50:             STX $08                 ;A:0000 X:FF80 Y:00C0 D:0000 DB:00 S:01E1 P:envmxdiZcHC:1174 VC:151 00 FL:1682
                    ; STY $0A                 ;A:0000 X:FF80 Y:00C0 D:0000 DB:00 S:01E1 P:envmxdiZcHC:1206 VC:151 00 FL:1682
                    ; LDA $98                 ;A:0000 X:FF80 Y:00C0 D:0000 DB:00 S:01E1 P:envmxdiZcHC:1238 VC:151 00 FL:1682
                    ; AND.w #$01F0            ;A:0130 X:FF80 Y:00C0 D:0000 DB:00 S:01E1 P:envmxdizcHC:1270 VC:151 00 FL:1682
                    ; STA $04                 ;A:0130 X:FF80 Y:00C0 D:0000 DB:00 S:01E1 P:envmxdizcHC:1294 VC:151 00 FL:1682
                    ; LDA $9A                 ;A:0130 X:FF80 Y:00C0 D:0000 DB:00 S:01E1 P:envmxdizcHC:1326 VC:151 00 FL:1682
                    ; LSR A                   ;A:0070 X:FF80 Y:00C0 D:0000 DB:00 S:01E1 P:envmxdizcHC:1358 VC:151 00 FL:1682
                    ; LSR A                   ;A:0038 X:FF80 Y:00C0 D:0000 DB:00 S:01E1 P:envmxdizcHC:0004 VC:152 00 FL:1682
                    ; LSR A                   ;A:001C X:FF80 Y:00C0 D:0000 DB:00 S:01E1 P:envmxdizcHC:0018 VC:152 00 FL:1682
                    ; LSR A                   ;A:000E X:FF80 Y:00C0 D:0000 DB:00 S:01E1 P:envmxdizcHC:0032 VC:152 00 FL:1682
                    ; AND.w #$000F            ;A:0007 X:FF80 Y:00C0 D:0000 DB:00 S:01E1 P:envmxdizcHC:0046 VC:152 00 FL:1682
                    ; ORA $04                 ;A:0007 X:FF80 Y:00C0 D:0000 DB:00 S:01E1 P:envmxdizcHC:0070 VC:152 00 FL:1682
                    ; TAY                     ;A:0137 X:FF80 Y:00C0 D:0000 DB:00 S:01E1 P:envmxdizcHC:0102 VC:152 00 FL:1682
                    ; PLA                     ;A:0137 X:FF80 Y:0137 D:0000 DB:00 S:01E1 P:envmxdizcHC:0116 VC:152 00 FL:1682
                    ; SEP #$20                ;A:0266 X:FF80 Y:0137 D:0000 DB:00 S:01E3 P:envmxdizcHC:0152 VC:152 00 FL:1682
                    ; STA [$6B],y ;[$7E:C937] ;A:0266 X:FF80 Y:0137 D:0000 DB:00 S:01E3 P:envMxdizcHC:0174 VC:152 00 FL:1682
                    ; XBA                     ;A:0266 X:FF80 Y:0137 D:0000 DB:00 S:01E3 P:envMxdizcHC:0222 VC:152 00 FL:1682
                    ; STA [$6E],y ;[$7F:C937] ;A:6602 X:FF80 Y:0137 D:0000 DB:00 S:01E3 P:envMxdizcHC:0242 VC:152 00 FL:1682
                    ; XBA                     ;A:6602 X:FF80 Y:0137 D:0000 DB:00 S:01E3 P:envMxdizcHC:0290 VC:152 00 FL:1682
                    ; REP #$20                ;A:0266 X:FF80 Y:0137 D:0000 DB:00 S:01E3 P:envMxdizcHC:0310 VC:152 00 FL:1682
                    ; ASL A                   ;A:0266 X:FF80 Y:0137 D:0000 DB:00 S:01E3 P:envmxdizcHC:0332 VC:152 00 FL:1682
                    ; TAY                     ;A:04CC X:FF80 Y:0137 D:0000 DB:00 S:01E3 P:envmxdizcHC:0346 VC:152 00 FL:1682
                    ; PHK                     ;A:04CC X:FF80 Y:04CC D:0000 DB:00 S:01E3 P:envmxdizcHC:0360 VC:152 00 FL:1682
                    ; PER.w $0006            ; NOTE: this relative counter must always point to MAP16_RETURN. 
                    ; PEA $804C
                    ; JMP.l $00C0FB
; MAP16_RETURN:        PLB
                    ; PLP
                    ; RTS

                    
                    ; NOP
                    