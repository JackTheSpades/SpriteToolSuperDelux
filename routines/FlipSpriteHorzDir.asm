;======================================================================================================================;
; this routine is an adaptation of the vanilla routine at $019089 that flips the sprite's direction if it hits a wall.
; additionally, you can control whether or not the sprite checks for wall interaction and/or sets the turning timer
;
; made by DrAnas, with the original code from Thomas's 'all.log': https://bin.smwcentral.net/u/7012/all.7z
;
; inputs:
;   - $8A: various settings in the format 'W------T':
;       - 'W' ($80): if set, then the wall check will be IGNORED, allowing you to run this routine for other conditions
;       - 'T' ($01): if set, then the turning timer WON'T be set and thus $15AC will be TOTALLY FREE for other stuff
;
; outputs:
;   - $15AC: if the above 'W' bit is CLEAR, then it will be set to 0x8
;
;======================================================================================================================;
?FlipIfTouchingObj:
    LDA $8A                         ;\ if the 'W' bit of $8A is SET, skip the wall check entirely!
    BMI ?.setTurningTmr             ;/
?.touchWall
    LDA !sprite_blocked_status,x    ;\
    AND #$03                        ;| turn the sprite around when it hits a wall
    BEQ ?.return                    ;/
?.setTurningTmr
    LDA $8A                         ;\
    AND #$01                        ;| if the 'T' bit of $8A is SET, don't set the turning timer!
    BNE ?.flipSprDir                ;/
    LDA !15AC,x                     ;\ if it's already turning, return
    BNE ?.return                    ;/
    LDA #$08                        ;\ set the turning timer
    STA !15AC,x                     ;/
?.flipSprDir
    LDA !sprite_speed_x,x           ;\
    EOR #$FF                        ;|
    INC                             ;|
    STA !sprite_speed_x,x           ;| invert the sprite's speed & horizontal direction
    LDA !157C,x                     ;|
    EOR #$01                        ;|
    STA !157C,x                     ;/
?.return
    RTL
