@include

macro RevertMap16()
    lda !bounce_map16_tile,x
    sta $9C
    %BounceSetupMap16()
    phx
    jsl $00BEB0|!BankB
    plx
endmacro

macro InvisibleMap16()
    lda #$09
    sta $9C
    %BounceSetupMap16()
    phx
    jsl $00BEB0|!BankB
    plx
endmacro

macro SetSpeed() 
    %BounceSetSpeed()
endmacro

macro SetMarioSpeed()
    %BounceSetMarioSpeed()
endmacro

macro UpdatePos()
    %BounceUpdatePos()
endmacro

macro EraseCoinAbove()
    phk
    pea.w ?label-1
    pea.w $B888
    jml $029265|!BankB
?label
endmacro

;; this macro preserves A because usually the routines that use it
;; subsequently use it to do something else (e.g. sprite number to spawn)
;; if you ask "why not XBA", it's because we don't know if who called us
;; is using the whole 16-bit A or just the low byte
macro SetupCoords()
    pha
    lda !bounce_x_low,x
    sta $04
    lda !bounce_x_high,x
    sta $05
    lda !bounce_y_low,x
    sta $06
    lda !bounce_y_high,x
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
    xba
    %SetupCoords()
    %SpawnScoreGeneric()
endmacro