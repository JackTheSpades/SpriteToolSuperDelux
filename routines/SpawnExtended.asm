;Routine that spawns an extended sprite with initial speed at the position (+offset)
;of the calling sprite and returns the sprite index in Y
;For a list of extended sprites see here: http://www.smwiki.net/wiki/RAM_Address/$7E:170B

;Input:  A   = number
;        $00 = x offset  \
;        $01 = y offset  | you could also just ignore these and set them later
;        $02 = x speed   | using the returned Y.
;        $03 = y speed   /
;
;Output: Y   = index to extended sprite (#$FF means no sprite spawned)
;        C   = Carry Set = spawn failed, Carry Clear = spawn successful.

?main:
    XBA                        ; Save A
    LDA !15A0,x                ; \
    ORA !186C,x                ; | return if offscreen or about to be eaten
    ORA !15D0,x                ; |
    BNE ?.ret                    ; /
    
; Get Index
    LDY.b #!ExtendedSize-1       ; loop over 8 extra sprite slots (last 2 are for fireballs)
?.loop
    LDA !extended_num,y    ; \ if empty, proceed
    BEQ ?+                        ; /
    DEY                        ; \
    BPL ?.loop                ; | if not, decrease Y and continue with loop
?.ret
    SEC                        ; | set carry if none is spawned
    RTL                        ; /
?+
    XBA                        ; get number back in A
    STA !extended_num,y     ;
        
        
    LDA $00                    ; \
    CLC : ADC !E4,x        ; |
    STA !extended_x_low,y    ; | store x position + x offset (low byte)
    LDA #$00                    ; |
    BIT $00                    ; | create high byte based on $00 in A and add
    BPL ?+                        ; | to x position
    DEC                        ; |
?+    ADC !14E0,x                ; |
    STA !extended_x_high,y    ; /
        
    LDA $01                    ; \ 
     CLC : ADC !D8,x        ; |
    STA !extended_y_low,y    ; | store y position + y offset    
    LDA #$00                    ; |
    BIT $01                    ; | create high byte based on $01 in A and add
    BPL ?+                        ; | to y position
    DEC                        ; |
?+    ADC !14D4,x                ; |
    STA !extended_y_high,y    ; /
    
    LDA $02                    ; \ store x speed
    STA !extended_x_speed,y    ; /
    LDA $03                    ; \ store y speed
    STA !extended_y_speed,y    ; /
    
    CLC
    RTL
    
