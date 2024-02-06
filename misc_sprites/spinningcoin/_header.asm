@include

macro UpdateYPos()
    %SpinningCoinUpdateYPos()
endmacro

macro SetupCoords()
    pha
    lda !spinning_coin_x_low,x
    sta $04
    lda !spinning_coin_x_high,x
    sta $05
    lda !spinning_coin_y_low,x
    sta $06
    lda !spinning_coin_y_high,x
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