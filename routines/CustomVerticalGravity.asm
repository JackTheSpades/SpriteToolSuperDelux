;======================================================================================================================;
; this routine is an adaptation of the vanilla gravity at $01802A that allows to specify a custom VERTICAL gravity
; for your sprite. unlike many custom gravity codes, this one takes water interaction into account!
;
; please note that $15DC is deliberately not taken care of here! it's only used in the vanilla gravity routine at $01802A
; as well as the moving ghost house ledge hole's code. this is in case you need to use it for something else in your sprite
;
; the vanilla object interaction routine is also left out in case you wanna use that separately or your own custom routine
;
; made by DrAnas, with the original code from Thomas's 'all.log': https://bin.smwcentral.net/u/7012/all.7z
;
; inputs:
;   - $8A ('VS'): various settings in the format 'W-----YX':
;       - 'W' ($80): if set, then the sprite's X/Y-speeds WON'T be affected by water
;       - 'Y' ($02): if set, then the Y-position WON'T be updated
;       - 'X' ($01): if set, then the X-position WON'T be updated. useful for, say, stopping a sprite in its tracks when
;       it hits a wall!
;   - $8B ('RS'): rising Y-speed in water (i.e. #$E8). can be positive or negative
;   - $8C & $8D ('GA' & 'GW'): gravities for air & water respectively (i.e. #$03 & #$01). shouldn't be negative here!
;   - $8E & $8F ('CA' & 'CW'): falling Y-speed caps for air & water respectively (i.e. #$40 & #$10). can be positive or negative
;
; example setup:
;    REP #$20                        ;> get into 16-bit 'A' since it'll be much faster here
;    LDA #$RSVS
;    STA $8A
;    LDA #$GAGW
;    STA $8C
;    LDA #$CACW
;    STA $8E
;    SEP #$20                        ;> exit 16-bit 'A'
;    %CustomVerticalGravity()
;
;======================================================================================================================;
?SubUpdateSprPos:
    LDA $8A                         ;\
    AND #$02                        ;| if the 'Y' bit of $8A is SET, don't update the Y-position!
    BNE ?.slowDownXSpd              ;/
    JSL $01801A|!bank               ;> update the sprite's Y-position
    LDY #$00                        ;> 'Y' = 0x0 if in air
    LDA $8A                         ;\ if the 'W' bit of $8A is SET, don't check for water interaction!
    BMI ?.applyGravPos              ;/
?.checkInWater
    LDA !sprite_in_water,x          ;\
    BEQ ?.applyGravPos              ;| now 'Y' = 0x1 if in water
    INY                             ;/
?.limitYSpdNeg
    LDA !sprite_speed_y,x           ;\ if the sprite's Y-speed is POSITIVE (i.e., moving DOWN), apply positive gravity accordingly
    BPL ?.limitYSpdPos              ;/
    CMP $8B                         ;\
    BCS ?.applyGravPos              ;| limit the sprite's NEGATIVE rising Y-speed in water to whatever's in $8B
    BRA ?.setYSpd                   ;/

?.limitYSpdPos
    CMP $8B                         ;\
    BCC ?.applyGravPos              ;|
?.setYSpd                           ;| limit the sprite's POSITIVE 'rising' Y-speed in water to whatever's in $8B
    LDA $8B                         ;|
    STA !sprite_speed_y,x           ;/
?.applyGravPos
    LDA $8E,y                       ;\ if the input speed's NEGATIVE (i.e., moving UP), apply negative gravity accordingly
    BMI ?.applyGravNeg              ;/
    LDA !sprite_speed_y,x           ;\
    CLC : ADC $8C,y                 ;| apply POSITIVE gravity to the sprite's Y-speed
    STA !sprite_speed_y,x           ;/
    BMI ?.slowDownXSpd              ;> don't apply the gravity cap if the speed is NEGATIVE
    CMP $8E,y                       ;\
    BCC ?.slowDownXSpd              ;| limit the sprite's POSITIVE falling Y-speed to either $8E (air) or $8F (water)
    BRA ?.setGravCap                ;/

?.applyGravNeg
    LDA !sprite_speed_y,x           ;\
    SEC : SBC $8C,y                 ;| apply NEGATIVE gravity to the sprite's Y-speed
    STA !sprite_speed_y,x           ;/
    BPL ?.slowDownXSpd              ;> don't apply the gravity cap if the speed is POSITIVE
    CMP $8E,y                       ;\
    BCS ?.slowDownXSpd              ;|
?.setGravCap                        ;| limit the sprite's NEGATIVE 'falling' Y-speed to either $8E (air) or $8F (water)
    LDA $8E,y                       ;|
    STA !sprite_speed_y,x           ;/
?.slowDownXSpd
    LDA $8A                         ;\
    AND #$01                        ;| if the 'X' bit of $8A is SET, don't update the X-position!
    BNE ?.return                    ;/
    LDA $8A                         ;\ if the 'W' bit of $8A is SET, don't check for water interaction!
    BMI ?.justUpdateXPos            ;/
    LDA !sprite_speed_x,x           ;\
    STA $00                         ;|
    LDY !sprite_in_water,x          ;|
    BEQ ?.notInWater                ;|
    ASL                             ;|
    ROR !sprite_speed_x,x           ;|
    LDA !sprite_speed_x,x           ;| if the sprite is in water, slow it down to 3/4th of its original speed
    PHA                             ;|
    STA $01                         ;|
    ASL                             ;|
    ROR $01                         ;|
    PLA                             ;|
    ADC $01                         ;|
    STA !sprite_speed_x,x           ;/
?.notInWater
    JSL $018022|!bank               ;\
    LDA $00                         ;| now update the sprite's X-position & restore the original speed
    STA !sprite_speed_x,x           ;/
?.return
    RTL

?.justUpdateXPos
    JML $018022|!bank               ;> just update the X-position
