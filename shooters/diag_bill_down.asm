;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Diagonal Shooter, by mikeyk
;;
;; Description: This shoots bullet bills diagonally downwards
;;
;; Uses first extra bit: YES
;; The bullet will shoot to the right if the first extra bit is set
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; sprite code JSL
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                    dcb "INIT" 
                    dcb "MAIN"                                    
                    PHB                     
                    PHK                     
                    PLB                     
                    JSR SPRITE_CODE_START   
                    PLB                     
                    RTL      

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; main bullet bill shooter code
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RETURN2             RTS                     ; return
SPRITE_CODE_START   LDA $17AB,x             ; \ return if it's not time to generate
                    BNE RETURN2             ; /
                    LDA #$60                ; \ set time till next generation = 60
                    STA $17AB,x             ; /
                    LDA $178B,x             ; \ don't generate if off screen vertically
                    CMP $1C                 ;  |
                    LDA $1793,x             ;  |
                    SBC $1D                 ;  |
                    BNE RETURN2             ; /
                    LDA $179B,x             ; \ don't generate if off screen horizontally
                    CMP $1A                 ;  |
                    LDA $17A3,x             ;  |
                    SBC $1B                 ;  |
                    BNE RETURN2             ; / 
                    LDA $179B,x             ; \ ?? something else related to x position of generator??
                    SEC                     ;  | 
                    SBC $1A                 ;  |
                    CLC                     ;  |
                    ADC #$10                ;  |
                    CMP #$10                ;  |
                    BCC RETURN2             ; /
                    JSL $02A9DE             ; \ get an index to an unused sprite slot, return if all slots full
                    BMI RETURN2             ; / after: Y has index of sprite being generated

GENERATE_SPRITE     LDA #$09                ; \ play sound effect
                    STA $1DFC               ; /
                    LDA #$01                ; \ set sprite status for new sprite
                    STA $14C8,y             ; /
                    LDA #$1C                ; \ set sprite number for new sprite
                    STA $009E,y             ; /
                    LDA $179B,x             ; \ set x position for new sprite
                    STA $00E4,y             ;  |
                    LDA $17A3,x             ;  |
                    STA $14E0,y             ; /
                    LDA $178B,x             ; \ set y position for new sprite
                    SEC                     ;  | (y position of generator - 1)
                    SBC #$01                ;  |
                    STA $00D8,y             ;  |
                    LDA $1793,x             ;  |
                    SBC #$00                ;  |
                    STA $14D4,y             ; /
                    PHX                     ; \ before: X must have index of sprite being generated
                    TYX                     ;  | routine clears old sprite values...
                    JSL $07F7D2             ;  | ...and loads in new values for the 6 main sprite tables
                    PLX                     ; / 
                    LDA #$08                ;
                    STA $14C8,y             ;

                    LDA $00
                    PHA
                    
                    LDA $1783,x 
                    AND #$40
                    BEQ LEFT
                    
                    ;LDA $178B,x             ; check y position and shoot up or down accordingly
                    ;AND #$10                ; todo: change this check
                    ;BNE SHOOT_UP2
                    LDA #$05
                    ;BRA STORE
SHOOT_UP2           ;LDA #$04
                    BRA STORE

LEFT                ;LDA $178B,x             ; check y position and shoot up or down accordingly
                    ;AND #$10                ; todo: change this check
                    ;BNE SHOOT_UP
                    LDA #$06  
                    ;BRA STORE
SHOOT_UP            ;LDA #$07               
STORE               STA $00C2,y             ; 06 for down, 07 for up
                    STA $00
                    JSR SUB_SMOKE2
                    PLA
                    STA $00
                    
RETURN              RTS                     ; return


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; display smoke effect for diagonal shooter
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                    ;up left, down right, down left, up right,
Y_OFFSET            dcb $00,$00,$00,$00,$FA,$04,$04,$FA
X_OFFSET            dcb $00,$00,$00,$00,$04,$04,$FA,$FA

SUB_SMOKE2          LDY #$03                ; \ find a free slot to display effect
FINDFREE            LDA $17C0,y             ;  |
                    BEQ FOUNDONE            ;  |
                    DEY                     ;  |
                    BPL FINDFREE            ;  |
                    RTS                     ; / return if no slots open

FOUNDONE            LDA #$01                ; \ set effect graphic to smoke graphic
                    STA $17C0,y             ; /
                    LDA $178B,x             ; \
                    PHX                     ;  |
                    PHA                     ;  |
                    LDA $00
                    TAX
                    PLA                     ;  | set smoke y position based on direction of shot
                    CLC                     ;  |
                    ADC Y_OFFSET,x          ;  |
                    STA $17C4,y             ; /
                    PLX
                    
                    LDA #$1B                ; \ set time to show smoke
                    STA $17CC,y             ; /
                    LDA $179B,x             ; \ load generator x position
                    PHX
                    PHA
                    LDA $00
                    TAX
                    PLA
                    CLC                     ;  |
                    ADC X_OFFSET,x
                    STA $17C8,y             ; /
                    PLX
                    RTS                    