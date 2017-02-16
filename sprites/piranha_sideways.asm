;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Sideways Piranha Plant, by mikeyk
;;
;; Description: A piranha plant that comes out of horizontal pipes.
;;
;; Uses first extra bit: YES
;; It's direction depends on the first extra bit.  If it is set it will travel to the
;; right to come out of the pipe.  Otherwise it will travel left to come out of the pipe.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
           
                    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; venus fire trap -  initialization JSL
; align sprite to middle of pipe
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

print "INIT ",pc
		LDA !extra_bits,x
		AND #$04
		BNE +
		INC !E4,x
		INC !E4,x
		RTL

+		DEC !E4,x
		DEC !E4,x
		RTL


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; venus fire trap -  main JSL
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

print "MAIN ",pc
		PHB                     ; \
		PHK                     ;  | main sprite function, just calls local subroutine
		PLB                     ;  |
		JSR VENUS_CODE_START    ;  |
		PLB                     ;  |
		RTL                     ; /


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; venus fire trap main routine
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

X_SPEED:             db $00,$F0,$00,$10     ;rest at bottom, moving up, rest at top, moving down
TIME_IN_POS:         db $22,$30,$22,$30     ;moving up, rest at top, moving down, rest at bottom


VENUS_CODE_START:    LDA !1594,x             ;A:8E76 X:0007 Y:0000 D:0000 DB:01 S:01F5 P:envMXdiZcHC:0918 VC:051 00 FL:24235
                    BNE LABEL24             ;A:8E00 X:0007 Y:0000 D:0000 DB:01 S:01F5 P:envMXdiZcHC:0950 VC:051 00 FL:24235
                    LDA $64                 ;A:8E00 X:0007 Y:0000 D:0000 DB:01 S:01F5 P:envMXdiZcHC:0966 VC:051 00 FL:24235
                    PHA                     ;A:8E20 X:0007 Y:0000 D:0000 DB:01 S:01F5 P:envMXdizcHC:0990 VC:051 00 FL:24235
                    LDA !15D0,x             ;A:8E20 X:0007 Y:0000 D:0000 DB:01 S:01F4 P:envMXdizcHC:1012 VC:051 00 FL:24235
                    BNE LABEL23             ;A:8E00 X:0007 Y:0000 D:0000 DB:01 S:01F4 P:envMXdiZcHC:1044 VC:051 00 FL:24235
                    LDA #$10                ;A:8E00 X:0007 Y:0000 D:0000 DB:01 S:01F4 P:envMXdiZcHC:1060 VC:051 00 FL:24235
                    STA $64                 ;A:8E10 X:0007 Y:0000 D:0000 DB:01 S:01F4 P:envMXdizcHC:1076 VC:051 00 FL:24235
LABEL23:            JSR SUB_GFX
                    PLA                     ;A:003B X:0007 Y:00EC D:0000 DB:01 S:01F4 P:envMXdizcHC:1152 VC:054 00 FL:24235
                    STA $64                 ;A:0020 X:0007 Y:00EC D:0000 DB:01 S:01F5 P:envMXdizcHC:1180 VC:054 00 FL:24235
						  LDA #$00
LABEL24:            %SubOffScreen()         ; off screen routine
                    LDA $9D                 ; \ if sprites locked, return
                    BNE RETURN27            ; /
                    LDA !1594,x             ;A:0000 X:0007 Y:00EC D:0000 DB:01 S:01F5 P:envMXdiZcHC:0538 VC:055 00 FL:24235
                    BNE LABEL25             ;A:0000 X:0007 Y:00EC D:0000 DB:01 S:01F5 P:envMXdiZcHC:0570 VC:055 00 FL:24235
                    JSL $01803A             ; 8FC1 wrapper - A:0000 X:0007 Y:00EC D:0000 DB:01 S:01F5 P:envMXdiZcHC:0586 VC:055 00 FL:24235 calls A40D then A7E4 

LABEL25:            LDA !C2,x               ;A:0001 X:0007 Y:0007 D:0000 DB:01 S:01F5 P:envMXdizcHC:1270 VC:056 00 FL:24235
                    AND #$03                ;A:0000 X:0007 Y:0007 D:0000 DB:01 S:01F5 P:envMXdiZcHC:1300 VC:056 00 FL:24235
                    TAY                     ;A:0000 X:0007 Y:0007 D:0000 DB:01 S:01F5 P:envMXdiZcHC:1316 VC:056 00 FL:24235
                    LDA !1540,x             ;A:0000 X:0007 Y:0000 D:0000 DB:01 S:01F5 P:envMXdiZcHC:1330 VC:056 00 FL:24235
                    BEQ LABEL28             ;A:0000 X:0007 Y:0000 D:0000 DB:01 S:01F5 P:envMXdiZcHC:1362 VC:056 00 FL:24235

                    LDA X_SPEED,y           ; \ set x speed
                    STA !B6,x               ; /
                    
                    LDA !extra_bits,x        ; invert x speed if extra bits set
                    AND #$04
                    BEQ NO_FLIP2
                    LDA !B6,x
                    EOR #$FF
                    INC A
                    STA !B6,x
                    
NO_FLIP2:           STZ !AA,x
                    
                    
                    ;JSL $01801A             ; ABD8 wrapper - A:00F0 X:0007 Y:001A D:0000 DB:01 S:01F5 P:eNvMXdizcHC:0824 VC:097 00 FL:24268 stays in pipe w/o, has long
                    JSL $01802A
                    LDA !D8,x
                    AND #$F0
                    ORA #$08
                    STA !D8,x
RETURN27:           RTS                     ;A:00FF X:0007 Y:00FF D:0000 DB:01 S:01F5 P:eNvMXdizcHC:0488 VC:098 00 FL:24268

LABEL28:            LDA !C2,x               ;A:0000 X:0007 Y:0000 D:0000 DB:01 S:01F5 P:envMXdiZcHC:0016 VC:057 00 FL:24235
                    AND #$03                ;A:0000 X:0007 Y:0000 D:0000 DB:01 S:01F5 P:envMXdiZcHC:0046 VC:057 00 FL:24235
                    STA $00                 ;A:0000 X:0007 Y:0000 D:0000 DB:01 S:01F5 P:envMXdiZcHC:0062 VC:057 00 FL:24235
                    BNE LABEL29             ;A:0000 X:0007 Y:0000 D:0000 DB:01 S:01F5 P:envMXdiZcHC:0086 VC:057 00 FL:24235
                    %SubHorzPos()           ;A:0000 X:0007 Y:0000 D:0000 DB:01 S:01F5 P:envMXdiZcHC:0102 VC:057 00 FL:24235 nothing w/o
                    LDA $0F                 ;A:00FF X:0007 Y:0001 D:0000 DB:01 S:01F5 P:envMXdizcHC:0464 VC:057 00 FL:24235
                    CLC                     ;A:00B8 X:0007 Y:0001 D:0000 DB:01 S:01F5 P:eNvMXdizcHC:0488 VC:057 00 FL:24235
                    ADC #$1B                ;A:00B8 X:0007 Y:0001 D:0000 DB:01 S:01F5 P:eNvMXdizcHC:0502 VC:057 00 FL:24235
                    CMP #$37                ;A:00D3 X:0007 Y:0001 D:0000 DB:01 S:01F5 P:eNvMXdizcHC:0518 VC:057 00 FL:24235
                    LDA #$01                ;A:00D3 X:0007 Y:0001 D:0000 DB:01 S:01F5 P:eNvMXdizCHC:0534 VC:057 00 FL:24235
                    STA !1594,x             ;A:0001 X:0007 Y:0001 D:0000 DB:01 S:01F5 P:envMXdizCHC:0550 VC:057 00 FL:24235
                    ;BCC LABEL30             ;A:0001 X:0007 Y:0001 D:0000 DB:01 S:01F5 P:envMXdizCHC:0582 VC:057 00 FL:24235
LABEL29:            STZ !1594,x             ;A:0001 X:0007 Y:0001 D:0000 DB:01 S:01F5 P:envMXdizCHC:0598 VC:057 00 FL:24235
                    LDY $00                 ;A:0001 X:0007 Y:0001 D:0000 DB:01 S:01F5 P:envMXdizCHC:0630 VC:057 00 FL:24235
                    LDA TIME_IN_POS,y       ;A:0001 X:0007 Y:0000 D:0000 DB:01 S:01F5 P:envMXdiZCHC:0654 VC:057 00 FL:24235
                    STA !1540,x             ;A:0020 X:0007 Y:0000 D:0000 DB:01 S:01F5 P:envMXdizCHC:0686 VC:057 00 FL:24235
                    INC !C2,x               ;A:0020 X:0007 Y:0000 D:0000 DB:01 S:01F5 P:envMXdizCHC:0718 VC:057 00 FL:24235
LABEL30:            RTS                     ;A:0020 X:0007 Y:0000 D:0000 DB:01 S:01F5 P:envMXdizCHC:0762 VC:057 00 FL:24235


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; graphics routine
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                    
TILEMAP:             db $A4,$A0,$A4,$A2,$A4,$A0,$A4,$A2
HORIZ_DISP:          db $00,$10,$00,$10,$10,$00,$10,$00
PROPERTIES:          db $4B,$49,$4B,$49,$0B,$09,$0B,$09     ;xyppccct format

SUB_GFX:            %GetDrawInfo()          ; after: Y = index to sprite tile map ($300)
                                            ;      $00 = sprite x position relative to screen boarder 
                                            ;      $01 = sprite y position relative to screen boarder  
                    LDA !1540,x             ; \
                    LSR A
                    LSR A
                    LSR A
                    AND #$01
                    ASL A
                    STA $03                 ; /
                    LDA !157C,x             ; \ $02 = sprite direction
                    AND #$01                ;  |
                    STA $02                 ; /
                    PHX                     ; push sprite index
                    
                    LDA !extra_bits,x
                    AND #$04
                    BNE NOT_EXTRA
                    LDA $03 
                    CLC
                    ADC #$04
                    STA $03
NOT_EXTRA:                    

                    LDX #$01                ; loop counter = (number of tiles per frame) - 1
LOOP_START:         PHX                     ; push current tile number
                    TXA                     ; \ X = index to horizontal displacement
                    ORA $03                 ; / get index of tile (index to first tile of frame + current tile number)
                    TAX

                    LDA $00                 ; \ tile x position = sprite x location ($00)
                    CLC                     ;  |
                    ADC HORIZ_DISP,x        ;  |
                    STA $0300|!Base2,y      ; /
                    
                    LDA $01                 ;  | tile y position = sprite y location ($01) + tile displacement
                    STA $0301|!Base2,y      ; /

                    LDA TILEMAP,x           ; \ store tile
                    STA $0302|!Base2,y      ; / 

                    LDA PROPERTIES,x        ; \ get tile PROPERTIES
                    ORA $64                 ;  | 
                    STA $0303|!Base2,y      ; / store tile PROPERTIES

                    TYA                     ; \ get index to sprite property map ($460)...
                    LSR A                   ;  |    ...we use the sprite OAM index...
                    LSR A                   ;  |    ...and divide by 4 because a 16x16 tile is 4 8x8 tiles
                    TAX                     ;  | 
                    LDA #$02                ;  |    else show a full 16 x 16 tile
                    STA $0460|!Base2,x      ; /
                    
                    PLX                     ; \ pull, X = current tile of the frame we're drawing
                    INY                     ;  | increase index to sprite tile map ($300)...
                    INY                     ;  |    ...we wrote 1 16x16 tile...
                    INY                     ;  |    ...sprite OAM is 8x8...
                    INY                     ;  |    ...so increment 4 times
                    DEX                     ;  | go to next tile of frame and loop
                    BPL LOOP_START          ; / 

                    PLX                     ; pull, X = sprite index
                    LDY #$FF                ; \ why FF? (460 &= 2) 8x8 tiles maintained
                    LDA #$01                ;  | A = number of tiles drawn - 1
                    JSL $01B7B3             ; / don't draw if offscreen
                    RTS                     ; return


