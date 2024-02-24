include

macro LDE()
    LDA !extra_bits,x
    AND #$04
endmacro

;; this macro preserves A because usually the routines that use it
;; subsequently use it to do something else (e.g. sprite number to spawn)
;; if you ask "why not XBA", it's because we don't know if who called us
;; is using the whole 16-bit A or just the low byte
macro SetupCoords()
    pha
    lda !sprite_x_low,x
    sta $04
    lda !sprite_x_high,x
    sta $05
    lda !sprite_y_low,x
    sta $06
    lda !sprite_y_high,x
    sta $07
    pla
endmacro

macro SpawnMinorExtended()
    xba
    lda !sprite_off_screen_horz,x
    ora !sprite_off_screen_vert,x
    ora !sprite_being_eaten,x
    bne ?ret
    xba
    %SetupCoords()
    %SpawnMinorExtendedGeneric()
?ret 
endmacro

macro SpawnCluster()
    %SetupCoords()
    %SpawnClusterGeneric()
endmacro

macro SpawnSpinningCoin()
    %SetupCoords()
    %SpawnSpinningCoinGeneric()
endmacro

macro SpawnScore()
    %SetupCoords()
    %SpawnScoreGeneric()
endmacro