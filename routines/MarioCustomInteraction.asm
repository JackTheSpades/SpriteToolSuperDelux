;======================================================================================================================;
; this is an adaptation of $01A83B from Kevin's koopa disassembly: https://www.smwcentral.net/?p=section&a=details&id=23125
; basically, this allows you to more comfortably code whatever interactions you want for certain things, such as star power,
; whether or not the player's touching the top of the sprite, whether he's cape-diving on the sprite, etc.
; please see the 'outputs:' heading for what interactions this accounts for!
;
; IMPORTANT NOTE: to use properly, make sure the 'Don't use default interaction with Mario' Tweaker bit's enabled!
; then check the carry for $01AD7C in your sprite's main code and if it's set, then call this routine!
; finally, to code the actual interactions, check the various bits of $8F down below
;
; IMPORTANT NOTE 2: the feature of knocking the player backwards from the sprite when $187B's set has been deliberately left out,
; in case you absolutely need to use $187B for something else. otherwise, you'll have to manually code that setting yourself
;
; made by DrAnas & Kevin
;
; outputs:
;   - $8F (scratch RAM) = formatted as 'SsUFC---'
;       - 'S': set to 1 when the player touches the sprite with a star
;       - 's': set to 1 when the player slides on the sprite (if bit 2 of Tweaker RAM $190F is set)
;       - 'U': set to 1 when the player's on top of the sprite in general
;       - 'F': set to 1 when the sprite's set to fall down (if bit 2 of Tweaker RAM $190F is set)
;       - 'C': set to 1 when the player cape-dives on the sprite (or if bit 6 of Tweaker RAM $1686 is set to make the sprite squishable)
;   - $157C = direction of the sprite when the player touches it (if bit 5 of Tweaker RAM $1686 is set)
;
;======================================================================================================================;
?SprMarioInteract:
    lda $1490|!addr                 ;\ If Mario has a star
    beq ?NoStar                     ;|
    lda !167A,x                     ;| and the sprite can be starkilled
    and #$02                        ;|
    bne ?NoStar                     ;|
    lda $8F                         ;|
    ora #$80                        ;| set the 'S' bit for $8F.
    sta $8F                         ;/
?NoStar:
    stz $18D2|!addr                 ;> Clear the star kill count.
?NotStationaryInteract:
    lda #$14                        ;\
    sta $01                         ;|
    lda $05                         ;|
    sec                             ;|
    sbc $01                         ;|
    rol $00                         ;|
    cmp $D3                         ;|
    php                             ;|
    lsr $00                         ;|
    lda $0B                         ;|
    sbc #$00                        ;| Don't bounce on the sprite if one of these is true:
    plp                             ;|  - Mario's Y position is too low w.r.t. the sprite's Y position.
    sbc $D4                         ;|  - Mario is moving upwards, the sprite can't be hit while moving upward
    bmi ?NotBouncing                ;|     and Mario hasn't bounced on any other enemies.
    lda $7D                         ;|  - Both Mario and the sprite are on the ground.
    bpl ?+                          ;|
    lda !190F,x                     ;|
    and #$10                        ;|
    bne ?+                          ;|
    lda $1697|!addr                 ;|
    beq ?NotBouncing                ;|
?+  lda !1588,x                     ;|
    and #$04                        ;|
    beq ?+                          ;|
    lda $72                         ;|
    beq ?NotBouncing                ;/
?+  lda $8F                         ;\
    ora #$20                        ;| Set the 'U' bit for $8F.
    sta $8F                         ;/
    lda $1407|!addr                 ;\
    bne ?++                         ;|
    lda !1656,x                     ;|
    and #$20                        ;| If the sprite dies when jumped on,
    beq ?NoSquish                   ;| or Mario flies into it, set the 'C' bit for $8F.
?++ lda $8F                         ;|
    ora #$08                        ;|
    sta $8F                         ;/
    rtl

?NoSquish:
    lda !1662,x                     ;\
    bpl ?.Return                    ;|
    lda $8F                         ;| If set to fall straight down, set the 'F' bit for $8F.
    ora #$10                        ;|
    sta $8F                         ;/
?.Return:
    rtl

?NotBouncing:
    lda $13ED|!addr                 ;\ If sliding
    beq ?+                          ;|
    lda !190F,x                     ;| and sprite can be killed with slide
    and #$04                        ;|
    bne ?+                          ;|
    lda #$03                        ;|
    sta $1DF9|!addr                 ;|
    lda $8F                         ;|
    ora #$40                        ;| set the 's' bit for $8F.
    sta $8F                         ;/
    rtl

?+  lda $1497|!addr                 ;\
    bne ?.Return                    ;| If Mario is invulnerable or riding Yoshi, return.
    lda $187A|!addr                 ;|
    bne ?.Return                    ;/
    lda !1686,x                     ;\
    and #$10                        ;|
    bne ?.Return                    ;| If set to change direction when touched, do it.
    %SubHorzPos()                   ;|
    tya                             ;|
    sta !157C,x                     ;/
?.Return:
    rtl
