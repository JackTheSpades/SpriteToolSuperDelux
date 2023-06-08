; Routine that simplifies the process of writing oam tiles for smoke sprites.
; It will draw a single tile at the smoke's position.
;
; Input: 
;   $02 = Tile number to show
;   $03 = YXPPCCCT properties of the tile
;   $04 = Tile size & X high bit
; 
; Output:
;   C   = Draw status
;       Set     = Smoke sprite drawn on screen
;       Clear   = Smoke sprite not drawn on screen

?main:
    %SmokeGetDrawInfo()
    bcc ?.return
    rep #$20
    lda $00
    sta $0200|!addr,y
    lda $02
    sta $0202|!addr,y
    sep #$20
    tya 
    lsr #2
    tay 
    lda $04
    sta $0420|!addr,y
    sec 
?.return
    rtl