;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; original shooters by mikey and 682
; update and sa-1 support by JackTheSpades
;
; Diagonal Upwards Bullet Bill Shooter
; 
; Extra Bit Set   = Shoots Up-Right
; Extra Bit Clear = Shoots Up-Left
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


; Cheat Sheet for $C2,x						  
; #$00 = Right
; #$01 = Left
; #$02 = Up
; #$03 = Down
; #$04 = Right Up
; #$05 = Right Down
; #$06 = Left Down
; #$07 = Left Up

!C2ExSet = $04
!C2ExClr = $07

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; sprite code JSL
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
print "INIT ",pc 
print "MAIN ",pc                                    
		PHB                     
		PHK                     
		PLB                     
		JSR SPRITE_CODE_START   
		PLB                     
		RTL      

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; main bullet bill shooter code
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Return:
		RTS                     ; RETURN
		
SPRITE_CODE_START:   
		LDA !shoot_timer,x      ; \ RETURN if it's not time to generate
		BNE Return              ; /
		LDA #$60                ; \ set time till next generation = 60
		STA !shoot_timer,x      ; /
		LDA $178B|!Base2,x      ; \ don't generate if off screen vertically
		CMP $1C                 ;  |
		LDA $1793|!Base2,x      ;  |
		SBC $1D                 ;  |
		BNE Return              ; /
		LDA $179B|!Base2,x      ; \ don't generate if off screen horizontally
		CMP $1A                 ;  |
		LDA $17A3|!Base2,x      ;  |
		SBC $1B                 ;  |
		BNE Return              ; / 
		LDA $179B|!Base2,x      ; \ ?? something else related to x position of generator??
		SEC                     ;  | 
		SBC $1A                 ;  |
		CLC                     ;  |
		ADC #$10                ;  |
		CMP #$10                ;  |
		BCC Return              ; /
		JSL $02A9DE             ; \ get an index to an unused sprite slot, RETURN if all slots full
		BMI Return              ; / after: Y has index of sprite being generated

Shoot:
		LDA #$09                ; \ play sound effect
		STA $1DFC|!Base2        ; /
		LDA #$01                ; \ set sprite status for new sprite
		STA !14C8,y             ; /
		LDA #$1C                ; \ set sprite number for new sprite
		STA.w !9E,y             ; /
		LDA $179B|!Base2,x      ; \ set x position for new sprite
		STA.w !E4,y             ;  |
		LDA $17A3|!Base2,x      ;  |
		STA !14E0,y             ; /
		LDA $178B|!Base2,x      ; \ set y position for new sprite
		SEC                     ;  | (y position of generator - 1)
		SBC #$01                ;  |
		STA.w !D8,y             ;  |
		LDA $1793|!Base2,x      ;  |
		SBC #$00                ;  |
		STA !14D4,y             ; /
		PHX                     ; \ before: X must have index of sprite being generated
		TYX                     ;  | routine clears old sprite values...
		JSL $07F7D2             ;  | ...and loads in new values for the 6 main sprite tables
		PLX                     ; / 
		LDA #$08                ;
		STA !14C8,y             ;

		LDA $00 : PHA           ; preserve $00 ... for some reason
                    
		LDA $1783|!Base2,x      ; \
		AND #$40                ;  |
		BEQ +                   ;  |
		LDA #!C2ExSet           ;  | get C2 value depending on extra bit of sprite.
		BRA ++                  ;  |
+		LDA #!C2ExClr           ;  |
++		STA.w !C2,y             ; /
		
		STA $00
		JSR Smoke
		
		PLA : STA $00           ; retore $00 ... for some reason
		RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; display smoke effect bullet bill shooter
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                  						  
Smoke:
		LDY #$03                ; \ find a free slot to display effect
.loop
		LDA $17C0|!Base2,y      ;  |
		BEQ +                   ;  |
		DEY                     ;  |
		BPL .loop               ;  |
		RTS                     ; /  RETURN if no slots open

+		LDA #$01                ; \ set effect graphic to smoke graphic
		STA $17C0|!Base2,y      ; /
		LDA #$1B                ; \ set time to show smoke
		STA $17CC|!Base2,y      ; /

		LDA $178B|!Base2,x      ; \
		PHX                     ;  |
		LDX $00                 ;  | set smoke y position based on direction of shot
		CLC                     ;  |
		ADC .y_off,x            ;  |
		STA $17C4|!Base2,y      ; /
		PLX

		LDA $179B|!Base2,x      ; \
		PHX                     ;  |
		LDX $00                 ;  | set smoke x position based on direction of shot
		CLC                     ;  |
		ADC .x_off,x            ;  |
		STA $17C8|!Base2,y      ; /
		PLX
		RTS                    
						  
.y_off:	db $00,$00,$00,$00,$FA,$04,$04,$FA
.x_off:	db $00,$00,$00,$00,$04,$04,$FA,$FA
