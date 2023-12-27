@include

macro Speed()
    LDA #$00
    %ExtendedSpeed()
endmacro

macro SpeedNoGrav()
    LDA #$01
    %ExtendedSpeed()
endmacro

macro SpeedX()
    LDA #$02
    %ExtendedSpeed()
endmacro

macro SpeedY()
    LDA #$03
    %ExtendedSpeed()
endmacro

;; this macro preserves A because usually the routines that use it
;; subsequently use it to do something else (e.g. sprite number to spawn)
;; if you ask "why not XBA", it's because we don't know if who called us
;; is using the whole 16-bit A or just the low byte
macro SetupCoords()
    pha
    lda !extended_x_low,x
    sta $04
    lda !extended_x_high,x
    sta $05
    lda !extended_y_low,x
    sta $06
    lda !extended_y_high,x
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

macro SpawnSpinningCoin()
    %SetupCoords()
    %SpawnSpinningCoinGeneric()
endmacro

macro SpawnScore()
    %SetupCoords()
    %SpawnScoreGeneric()
endmacro