;Routine that spawns a smoke sprite with a position (+offset) and timer and returns
;the sprite index in Y

;Input:  A   = number of sprite to spawn
;        $00 = x offset  \
;        $01 = y offset  | you could also just ignore these and set them later
;        $02 = timer     /
;
;Output: Y   = index to spawned sprite (#$FF means no sprite spawned)
;        C   = Carry Set = spawn failed, Carry Clear = spawn successful.
;
;Number cheatsheet:
;       #$01 = Puff of smoke.
;       #$02 = Contact graphic.
;       #$03 = Smoke when the player turns around abruptly.
;       #$04 = Unused/None.
;       #$05 = Glitter sprite.
;
;Common combination:
;        STZ $00 : STZ $01
;        LDA #$1B : STA $02
;        LDA #$01
;        %SpawnSmoke()

?main:
        LDY.b #!SmokeSize-1     ; \ find a free slot to display effect
        XBA                     ; |
?.loop                          ; |
        LDA !smoke_num,y        ; |
        BEQ ?+                  ; |
        DEY                     ; |
        BPL ?.loop              ; |
        SEC                     ; |
        RTL                     ; / RETURN if no slots open

?+      XBA                     ; \ set effect graphic to smoke graphic
        STA !smoke_num,y        ; /
        LDA $02                 ; \ set time to show smoke
        STA !smoke_timer,y      ; /

        LDA !D8,x               ; \
        CLC                     ; | set smoke y position based on direction of shot
        ADC $01                 ; |
        STA !smoke_y_low,y      ; /

        LDA !E4,x               ; \
        CLC                     ; | set smoke x position based on direction of shot
        ADC $00                 ; |
        STA !smoke_x_low,y      ; /
        CLC
        RTL
