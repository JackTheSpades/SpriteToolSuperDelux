;Routine that star-kills the sprite and gives Mario points.
;Doesn't check whether Mario actually has a star.
;Now made compatible by DrAnas with Koopster's 'no consecutive scoring' patch!
;https://www.smwcentral.net/?p=section&a=details&id=40262
?main:
    PHB
    PHK
    PLB
    JSL $01AB6F|!BankB
    LDA #$02                ; sprite status = 2 (being killed by star)
    STA !14C8,x
    LDA #$D0                ; set y speed
    STA !AA,x
    %SubHorzPos()
    LDA ?.speed,y           ; set x speed based on sprite direction
    STA !B6,x
; this checks if there's NOT an 'INY' at $01A84B for Koopster's 'no consecutive scoring' patch
if read1($01A84B|!BankB) != $EE
    LDA #$13
    STA $1DF9|!Base2
    LDA.b #read1($01A851|!BankB)
    PHX
    JSL $02ACEF|!BankB
    PLX
    PLB
    RTL
else
    INC $18D2|!Base2        ; increment number consecutive enemies killed
    LDA $18D2|!Base2
    CMP #$08                ; if consecutive enemies stomped >= 8, reset to 8
    BCC ?+
    LDA #$08
    STA $18D2|!Base2
?+  
    JSL $02ACE5|!BankB      ; give mario points
    LDY $18D2|!Base2
    CPY #$08                ; if consecutive enemies stomped < 8 ...
    BCC ?+
    LDY #$08
?+  
    LDA ?.sound,y           ; ... play sound effect
    STA $1DF9|!Base2
    PLB
    RTL                     ; final return

?.sound
    db $00,$13,$14,$15,$16,$17,$18,$19,$03
endif

?.speed
    db $F0,$10
