@include

macro SpeedX()
    lda #$00
    %MinorExtendedSpeed()
endmacro

macro SpeedY()
    lda #$02
    %MinorExtendedSpeed()
endmacro

macro SpeedXFast()
    lda #$01
    %MinorExtendedSpeed()
endmacro

macro SpeedYFast()
    lda #$03
    %MinorExtendedSpeed()
endmacro

;; this macro preserves A because usually the routines that use it
;; subsequently use it to do something else (e.g. sprite number to spawn)
;; if you ask "why not XBA", it's because we don't know if who called us
;; is using the whole 16-bit A or just the low byte
macro SetupCoords()
    pha
    lda !minor_extended_x_low,x
    sta $04
    lda !minor_extended_x_high,x
    sta $05
    lda !minor_extended_y_low,x
    sta $06
    lda !minor_extended_y_high,x
    sta $07
    pla
endmacro

macro SpawnExtendedAlt()
    %SetupCoords()
    %SpawnExtendedGeneric()
endmacro

macro SpawnSmokeAlt()
    %SetupCoords()
    %SpawnSmokeGeneric()
endmacro

macro SpawnCluster()
    %SetupCoords()
    %SpawnClusterGeneric()
endmacro

macro SpawnMinorExtended()
    %SetupCoords()
    %SpawnMinorExtendedGeneric()
endmacro

macro SpawnMinorExtendedOverwrite()
    %SetupCoords()
    %SpawnMinorExtendedOverwriteGeneric()
endmacro

macro SpawnSpinningCoin()
    %SetupCoords()
    %SpawnSpinningCoinGeneric()
endmacro

macro SpawnScore()
    %SetupCoords()
    %SpawnScoreGeneric()
endmacro