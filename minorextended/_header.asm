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