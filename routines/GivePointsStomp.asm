;======================================================================================================================;
; this is an adaptation of $01AB46 from Kevin's koopa disassembly: https://www.smwcentral.net/?p=section&a=details&id=23125
; basically, it gives the player consecutive points when they stomp on multiple sprites without touching the ground
; unlike other point-giving routines, this one automatically takes Koopster's 'no consecutive scoring' patch into account!
; https://www.smwcentral.net/?p=section&a=details&id=40262
;
; this means that with that patch applied, you won't inappropriately rack up points when stomping on the sprite,
; and instead you'll constantly get whatever score is specified from there for normal stomps
;
; made by DrAnas & Kevin
;
;======================================================================================================================;
; this checks if there's NOT a 'PHY' at $01AB46 for Koopster's 'no consecutive scoring' patch:
; https://www.smwcentral.net/?p=section&a=details&id=40262
if read1($01AB46|!bank) != $5A
    lda #$13
    sta $1DF9|!addr
    lda.b #read1($01AB4C|!bank)
    phx
    jsl $02ACEF|!bank
    plx
    rtl
else
    lda $1697|!addr                 ;\
    clc                             ;|
    adc !1626,x                     ;|
    inc $1697|!addr                 ;|
    tay                             ;| Play bounce SFX when $1697+$1626,x < #$08
    iny                             ;| (if >= #$08, it spawns a 1up score sprite which plays the SFX)
    cpy #$08                        ;|
    bcs ?+                          ;|
    lda .SFX-1,y                    ;|
    sta $1DF9|!addr                 ;/
?+  tya                             ;\
    cmp #$08                        ;|
    bcc ?+                          ;| Give points accordingly (input capped to $08 = 1up)
    lda #$08                        ;|
?+  jsl $02ACE5|!bank               ;/
    rtl

.SFX:
    db $13,$14,$15,$16,$17,$18,$19
endif
