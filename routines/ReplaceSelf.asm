; ReplaceSelf
;
; Spawns a new sprite over top of the current one at the same position.
; Everything else about the current one will be overwritten by the new sprite.
;
; Input:
;    A:         sprite number to spawn
;    carry bit: clear for vanilla sprite, set for custom sprite
;
; Notes:
;    - Clobbers both bytes of A
;    - The new sprite is placed into the init state.  You can add an inx before returning
;      from the old sprite if you want to re-run the sprite handling for the current
;      slot to avoid a frame with no graphics

?main:
    xba
    jsl $07F722|!bank                       ; zero sprite tables
    xba
    bcs ?.custom

    sta !sprite_num,x
    sta !new_sprite_num,x                   ; not sure if this is necessary, but the ram map says it's set so
    jsl $07F78B|!bank                       ; vanilla load sprite tables
    lda #$01 : sta !sprite_status,x
    lda #$00 : sta !extra_bits,x
    rtl

?.custom:
    sta !new_sprite_num,x
    pei ($00)
    pei ($02)
    jsl $0187A7|!bank                       ; pixi's custom sprite load tables, clobbers $00-02
    lda #$01 : sta !sprite_status,x
    lda #$08 : sta !extra_bits,x
    rep #$20
    pla : sta $02
    pla : sta $00
    sep #$20
    rtl
