;~@sa1 <-- DO NOT REMOVE THIS LINE!
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Disassembly of the shell-less Koopa from SMW.
;;
;; This sprite can have multiple versions, using Extra Byte 1 in the CFG editor.
;;  In binary, its format is [dgrh jfls]:
;;    d = turn shells into disco shells     (like yellow Koopas)
;;    g = use alt graphics                  (like blue Koopas)
;;    r = kickable when stunned             (like green/red/yellow Koopas)
;;    h = fast recovery from stunning       (like blue Koopas)
;;    j = jump over thrown shells           (like yellow Koopas)
;;    f = follow mario                      (like yellow Koopas)
;;    l = stay on ledges                    (like red/blue Koopas)
;;    s = move faster                       (like blue/yellow Koopas)
;;
;;  Values to recreate SMW's Koopas are:
;;   G: 20
;;   R: 22
;;   B: 53
;;   Y: AD
;;
;;  To make the Koopa kick shells, set its "acts like" setting in the CFG editor to 02.
;;  To make it hop into them instead, set it to anything else (36 is recommended).
;;  You can also disable both of those altogether by unchecking the "hop in/kick shells" option under 1656.
;;
;;  Additional settings can be found below.
;;
;;
;; Disassembled by kaizoman666/Thomas. No credit necessary.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Misc settings
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
XSpeeds:
    db $08,$F8
    db $0C,$F4
    ; X speeds for the Koopa.
    ; The first two are used when the "move faster" bit is clear. Second two are when it's set.


KickXSpeeds:
    db $30,$D0
    ; X speeds to give sprites kicked by the Koopa.
    
!kickYSpeed     =   $E0
    ; Y speed to give non-shell sprites kicked by the Koopa.


!jumpSpeed      =   $C0
    ; Y speed to give when jumping over thrown shells.
    

!followTimer    =   $7F
    ; How often to poll for Mario's position in Mario-following Koopas.
    ; Valid values are 00, 01, 03, 07, 0F, 1F, 3F, 7F, and FF. Higher is less often.


!shakeTime      =   $10
    ; How many frames to shake a Koopa shell after the Koopa hops in it.


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Tilemap
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Tilemap:
    db $C8,$CA,$CA,$CC,$86,$4E,$86
    db $E0,$E2,$E2,$E4,$E0,$E0,$E6
    ; These are all the animation frames used; each one is 16x16. 
    ;  First set of 6 bytes is for a normal Koopa.
    ;  Second set is if using the alt graphics bit (i.e. blue Koopa).
    ; Order is:
    ;  0/1 - Walking
    ;  2   - Turning
    ;  3   - Kicking/flipping shell
    ;  4/5 - Stunned
    ;  6   - Sliding
    ; Edit the CFG file to change YXPCCCT.

!squishTile     =   $EE
    ; 8x8 tile to use for the squish graphic.


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Sound effects
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
!kickSound      =   $03
!kickPort       =   $7DF9
    ; Sound effect for when the Koopa kicks a shell.
    
!kickedSound    =   $03
!kickedPort     =   $7DF9
    ; Sound effect for when the Koopa is killed by kicking it while it's stunned.


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Stunning
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Stunning is a bit weird.
;;  It's not normally possible to stun this sprite, since there's no full Koopa to knock it out of.
;;  However, the code for it is still implemented and usable if you set it elsewhere.
;;  Just set $163E,x to a value from 81-FF. That address decrements every frame, and when it reaches x80, the Koopa will unstun.
;;  Alternatively, set $1528,x to a non-zero value. That'll make the Koopa start sliding, and the stun timer will
;;   automatically set to the one of the values in "!stunTimeA" or "!stunTimeB" once its X speed reaches 0.

!stunTimeA      =   $7F
!stunTimeB      =   $20
    ; How long to stun the Koopa after it stops sliding.
    ; First one is if the "fast recovery from stunning" bit is clear. Second is if set.
    ; Maximum value is $7F.

!flipSpeed      =   $E0
    ; Y speed to hop with when uprighting itself after being stunned.
    ; Unused if the "fast recovery from stunning" bit is set.

!kickedPoints   =   $01
    ; Number of points to give if you kick-kill the Koopa while stunned.
    ; See here for values: http://www.smwcentral.net/?p=nmap&m=smwrom#02ACE5





;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; actual code begins
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

print "INIT ",pc
    JSL $01ACF9         ;\ Set random initial animation timer.
    STA $331E,x         ;/
    LDA $400057,x       ;\ Preserve extra byte 1.
    STA $750A,x         ;/
    JSR FaceMario
    RTL

print "MAIN ",pc
    PHB
    PHK
    PLB
    JSR Main
    PLB
    RTL



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; main routine
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Main:
    LDA $3242,x
    CMP #$08
    BCS NotDead
    STZ $33CE,x
    JMP Graphics
  NotDead:
    LDA $9D                     ;\ Branch if the game is frozen.
    BEQ CheckStunned            ;|  Small bugfix here to not let Mario kill it by screenscrolling when he touches them.
    BRA GameFrozen              ;/  I'm not sure why Nintendo did that.



StationaryKoopa:
    LDA $33FA,x                 ;\ 
    CMP #$80                    ;| Check the usage of $163E.
    BCC KickingKoopa            ;|  If 80-FF, the Koopa is stunned; animate it.
    LDA $9D                     ;|  If 01-7F, the Koopa is kicking a shell; don't animate it.
    BNE GameFrozen              ;/
StunnedKoopa:
    JSR SetAnimationFrame       ;\ 
    LDA $33CE,x                 ;|
    CLC                         ;| Handle stunned animation.
    ADC #$04                    ;|
    STA $33CE,x                 ;/
KickingKoopa:
    JSR StunnedInteraction      ; Handle contact with Mario.
GameFrozen:
    JSL $01802A                 ; Update position.
    STZ $B6,X                   ;\ 
    JSR IsOnGround              ;| Stop the Koopa and don't let it fall through the ground.
    BEQ FinishStunned           ;|
    STZ $9E,X                   ;/
FinishStunned:
    JMP SpriteInteraction       ; Process interaction with other sprites and draw graphics, then return.



StunnedInteraction:
    LDA $750A,x                 ;\ 
    AND #$20                    ;|
    BNE Kickable                ;| If not kickable and in contact with it, hurt Mario.
    JSL $01A7DC                 ;|
    RTS                         ;/

Kickable:
    ASL $7616,x                 ;\ 
    SEC                         ;|
    ROR $7616,x                 ;|
    JSL $01A7DC                 ;|
    BCC .noContact              ;| If kickable and in contact with it, kill it.
    JSR KickKill                ;|
  .noContact                    ;|
    ASL $7616,x                 ;|
    LSR $7616,x                 ;/
    RTS



CheckStunned:
    LDA $33FA,x                 ;\ Skip if the Koopa is not stunned.
    BEQ CheckSliding            ;/
    CMP #$80                    ;\ If the stun timer is not exactly 80, branch.
    BNE .notUnstunning          ;/

    LDA $750A,x                 ;\ 
    AND #$10                    ;|
    BNE .noJump                 ;| Flip the sprite over and return to normal.
    LDA #!flipSpeed             ;|  Also make the sprite jump upward if kickable.
    STA $9E,x                   ;|
  .noJump                       ;|
    STZ $33FA,x                 ;/

  .notUnstunning
    CMP #$01                    ;\ 
    BNE StationaryKoopa         ;|
    LDY $33E4,x                 ;|
    LDA $3242,y                 ;|
    CMP #$09                    ;| Jump back and handle basic stationary/stunned fuctions if:
    BNE StationaryKoopa         ;|  - The Koopa is not about to kick a shell/goomba/etc.
    LDA $322C,x                   ;|  - The state of the sprite being kicked isn't still 09 (stationary/carryable).
    SEC                         ;|  - The Koopa isn't close enough to the sprite anymore.
    SBC $322C,y                 ;|
    CLC                         ;|
    ADC #$12                    ;|
    CMP #$24                    ;|
    BCS StationaryKoopa         ;/
    LDA #!kickSound
    STA !kickPort
    LDA #$20                    ;\ 
    STA $D8,x                   ;| Disable contact with the sprite, and wait a bit before resuming movement.
    STA $32F2,x                 ;/
    LDY $3334,x                 ;\ 
    LDA KickXSpeeds,y           ;|
    LDY $33E4,x                 ;| Kick the sprite in the direction the Koopa is facing.
    STA $30B6,y                 ;|
    LDA #$0A                    ;|
    STA $3242,y                 ;/
    LDA $32C6,y                 ;\ Mirror the sprite's stun timer, for no real reason.
    STA $30D8,y                 ;/
    LDA #$08                    ;\ Briefly disable sprite interaction for the kicked sprite.
    STA $3308,y                 ;/
    LDA $7616,y                 ;\ 
    AND #$10                    ;|
    BEQ CheckSliding            ;| If it can't be kicked like a shell (i.e. Goombas, Bob-ombs, etc.), kick it slightly upwards.
    LDA #!kickYSpeed            ;|
    STA $309E,y                 ;/



CheckSliding:
    LDA $329A,x                 ;\ Skip if not sliding after being knocked out of a shell.
    BEQ CheckCatching           ;/

    LDA $334A,X                 ;\ 
    AND #$03                    ;| If the Koopa hits the side of a block, stop.
    BEQ .noWall                 ;|
    STZ $B6,x                   ;/
  .noWall
    JSR IsOnGround              ;\ 
    BEQ .noFriction             ;|
    LDA $86                     ;| 
    CMP #$01                    ;|
    LDA #$02                    ;|
    BCC .notSlippery            ;|
    LSR                         ;|
  .notSlippery                  ;|
    STA $00                     ;| Apply friction to the sliding Koopa, with slipperiness factored in.
    LDA $B6,x                   ;|  Also spawn smoke particles at its position.
    CMP #$02                    ;|
    BCC StopSliding             ;|
    BPL .movingRight            ;|
    CLC                         ;|
    ADC $00                     ;|
    CLC                         ;|
    ADC $00                     ;|
  .movingRight                  ;|
    SEC                         ;|
    SBC $00                     ;|
    STA $B6,x                   ;|
    JSR SmokeParticles          ;/

  .noFriction
    STZ $331E,x                 ; Don't animate.
    JSR StandardFunc            ; Run standard functions.
    LDA #$06                    ;\ 
    STA $33CE,x                 ;| Draw sprite.
    JMP Graphics                ;/

  StopSliding:
    JSR IsOnGround              ;\ If the sprite is not on the ground, don't stun it?
    BEQ .dontStun               ;/
    LDY.b #!stunTimeA+$80       ;\ 
    LDA $750A,x                 ;|
    AND #$10                    ;|
    BEQ .longStun               ;|
    LDY.b #!stunTimeB+$80       ;| Stun the sprite and return back for basic functionality.
  .longStun                     ;|
    TYA                         ;|
    STA $33FA,x                 ;|
  .dontStun                     ;|
    STZ $329A,x                 ;|
    JMP StunnedKoopa            ;/ 



CheckCatching:
    LDA.w $32B0,X               ;\ Skip if not catching a shell/goomba/etc.
    BEQ CheckKicking            ;/
    
    LDY $33E4,x                 ;\ 
    LDA $3242,y                 ;|
    CMP #$0A                    ;| Clear the "catching" flag and branch if the shell has stopped.
    BEQ SlowDown                ;|
    STZ $32B0,x                 ;|
    BRA NoFrictionCatch         ;/

  SlowDown:
    STA $329A,y                 ; Set the sliding flag.
    LDA $334A,X                 ;\ 
    AND #$03                    ;|
    BEQ .noWall                 ;| If the Koopa is pushed into a solid block, clear the X speed for both sprites.
    LDA #$00                    ;|
    STA $30B6,y                 ;|
    STA $B6,x                   ;/
  .noWall
    JSR IsOnGround              ;\ 
    BEQ NoFrictionCatch         ;|
    LDA $86                     ;|
    CMP.b #$01                  ;|
    LDA.b #$02                  ;|
    BCC .notSlippery            ;|
    LSR                         ;|
  .notSlippery                  ;|
    STA $00                     ;|
    LDA $30B6,y                 ;|
    CMP #$02                    ;| Apply friction to the two sprites, with slipperiness factored in.
    BCC StopCatching            ;|  Also spawn smoke particles at the Koopa's position.
    BPL .movingRight            ;|
    CLC                         ;|
    ADC $00                     ;|
    CLC                         ;|
    ADC $00                     ;|
  .movingRight                  ;|
    SEC                         ;|
    SBC $00                     ;|
    STA $30B6,y                 ;|
    STA $B6,x                   ;/
    JSR SmokeParticles          ;/
  NoFrictionCatch:              ;
    STZ $331E,X                 ; Don't animate.
    JSR StandardFunc            ; Run standard functions.
    RTS

  StopCatching:
    LDA.b #$00                  ;\ 
    STA $B6,x                   ;| Clear both sprites' X speeds.
    STA $30B6,y                 ;/
    STZ $32B0,x
    LDA #$09                    ;\ Make the sprite stationary/carryable.
    STA $3242,y                 ;/
    LDA $3200,y                 ;\ 
    CMP #$0D                    ;|
    BEQ .setStun                ;|
    CMP #$0F                    ;|
    BEQ .setStun                ;| If the sprite is a Goomba/Bob-omb/MechaKoopa, reset their stun timer to #$FF.
    CMP #$A2                    ;|
    BNE CheckKicking            ;|
  .setStun                      ;|
    LDA #$FF                    ;|
    STA $32C6,y                 ;/


CheckKicking:
    LDA $D8,x                   ;\ Skip if the Koopa is not in the process of kicking/flipping a shell.
    BEQ CheckEntering           ;/
    DEC $D8,x
    CMP #$08                    ;\ 
    LDA #$03                    ;|
    BCS .waiting                ;| Animate kicking the shell.
    LDA #$00                    ;|
  .waiting                      ;|
    STA $33CE,x                 ;/
    JMP MarioInteraction        ; Run the shared routine.

CheckEntering:
    LDA $32F2,x                 ;\ 
    CMP #$01                    ;| Skip if not about to enter a shell.
    BNE SetXSpeed               ;/
    LDY $3360,x                 ;\ 
    LDA $3242,y                 ;|
    CMP #$08                    ;|
    BCC .return                 ;|
    LDA $309E,y                 ;|
    BMI .return                 ;| Return if:
    LDA $3200,y                 ;|  - The shell is no longer alive.
    CMP #$21                    ;|  - The shell has Y speed.
    BEQ .return                 ;|  - The shell turned into a coin.
    JSL $03B69F                 ;|  - The Koopa and shell aren't touching. anymore.
    PHX                         ;|
    TYX                         ;|
    JSL $03B6E5                 ;|
    PLX                         ;|
    JSL $03B72B                 ;|
    BCC .return                 ;/
    JSR EraseSprite             ; Erase the Koopa.
    LDY $3360,x                 ;\ 
    LDA #!shakeTime             ;| Shake the shell.
    STA $32F2,y                 ;/
    PHX
    LDA $750A,x                 ;\ 
    LDX #$03                    ;|
    AND #$80                    ;|
    BNE .disco                  ;| Turn the shell into a disco shell if applicable.
    LDX #$00                    ;|
  .disco                        ;|
    TXA                         ;|
    STA $33E4,y                 ;/
    PLX
  .return
    RTS





SetXSpeed:
    JSR IsOnGround              ;\ Branch if the sprite is not on ground.
    BEQ .dontSetX               ;/
    LDY $3334,x                 ;\ 
    LDA $750A,x                 ;|
    AND #$01                    ;|
    BEQ .moveSlower             ;|
    INY                         ;|
    INY                         ;|
  .moveSlower                   ;| Set the sprite's X speed, depending on the type of slope it's standing on.
    LDA XSpeeds,y               ;| If the corresponding property bit is set, the sprite will move a bit faster.
    EOR $7520,x                 ;|
    ASL                         ;|
    LDA XSpeeds,y               ;|
    BCC .sameDir                ;|
    CLC                         ;|
    ADC $7520,x                 ;|
  .sameDir                      ;|
    STA $B6,x                   ;/
  .dontSetX
    LDY $3334,x                 ;\ 
    TYA                         ;|
    INC A                       ;|
    AND $334A,x                 ;| If the sprite hits the side of a block, stop it.
    AND #$03                    ;|
    BEQ .checkCeiling           ;|
    STZ $B6,x                   ;/
  .checkCeiling
    LDA $334A,x                 ;\ 
    AND #$08                    ;| If the sprite is hits a ceiling, clear its Y speed.
    BEQ StandardFunc            ;|
    STZ $9E,x                   ;/

StandardFunc:
    JSR SubOffscreenX0          ; Erase if offscreen.
    JSL $01802A                 ; Update the sprite's position and apply gravity.
    JSR SetAnimationFrame       ; Animate.
    JSR IsOnGround              ;\ Branch if not on the ground.
    BEQ SpriteInAir             ;/


SpriteOnGround:
    LDA $334A,x                 ;\ 
    BMI .onLayer2               ;|
    LDA #$00                    ;| 
    LDY $7520,x                 ;| If standing on a slope or Layer 2, give the sprite a Y speed of #$18.
    BEQ .setSpeed               ;|  Else, clear its Y speed.
  .onLayer2                     ;|
    LDA #$18                    ;|
  .setSpeed                     ;|
    STA $9E,x                   ;/
    
    STZ $3284,x                 ; For sprites that stay on ledges: you're currently on a ledge.
    LDA $750A,x                 ;\ 
    PHA                         ;|
    AND #$04                    ;|
    BEQ .dontFollow             ;|
    LDA $331E,X                 ;|
    AND #!followTimer           ;|
    BNE .dontFollow             ;| Follow Mario if set to do so.
    LDA $3334,x                 ;| Don't turn if not time to or already facing Mario.
    PHA                         ;|
    JSR FaceMario               ;|
    PLA                         ;|
    CMP $3334,x                 ;|
    BEQ .dontFollow             ;|
    LDA #$08                    ;|
    STA $338C,x                 ;/
  .dontFollow
    PLA                         ;\ 
    AND #$08                    ;| Jump over shells if set to do so.
    BEQ .dontJump               ;|
    JSR JumpOverShells          ;/
  .dontJump
    BRA MarioInteraction


SpriteInAir:
    LDA $750A,x                 ;\ 
    AND #$02                    ;|
    BEQ MarioInteraction        ;|
    LDA.w $3284,X               ;|
    ORA.w $32F2,X               ;| If the sprite is set to turn on ledges and is not having a special function run,
    ORA.w $329A,X               ;|  flip its direction.
    ORA.w $32B0,X               ;|
    BNE MarioInteraction        ;|
    JSR FlipSpriteDir           ;|
    LDA.b #$01                  ;|
    STA.w $3284,X               ;/


MarioInteraction:
    LDA.w $329A,X               ;\ 
    BEQ NormInteraction         ;|
    JSR StunnedInteraction      ;| If the sprite is not sliding, process standard interaction with Mario.
    BRA SpriteInteraction       ;|  If the sprite is sliding, check whether to kick-kill it.
  NormInteraction:              ;|
    JSL $01A7DC                 ;/

SpriteInteraction:
    JSL $018032                 ; Process interaction with other sprites.

    JSR FlipIfTouchingObj       ; Turn around if it hits a block.

    LDA $3334,X
    PHA
    LDY $338C,X                 ;\ 
    BEQ .notTurning             ;|
    LDA #$02                    ;|
    STA $33CE,X                 ;|
    LDA #$00                    ;| If the sprite's turn timer is non-zero, turn it around.
    CPY #$05                    ;| The actual turn occurs on frame 3 of the animation.
    BCC .stillWaiting           ;|
    INC A                       ;|
  .stillWaiting                 ;|
    EOR $3334,x                 ;|
    STA $3334,x                 ;/
  .notTurning
    JSR Graphics                ; Draw graphics.
    PLA
    STA.w $3334,X
    RTS





JumpOverShells:
    TXA                         ;\ 
    EOR $13                     ;| Divide detection across four frames. If not the right frame, return.
    AND #$03                    ;|
    BNE ReturnJumpLoop          ;/
    LDY #$09                    ;\ 
  FindShell:                    ;|
    LDA $3242,y                 ;|
    CMP #$0A                    ;| Look for a sprite that's been thrown. Return if none exists.
    BEQ HandleJumpOver          ;|
  JumpLoopNext:                 ;|
    DEY                         ;|
    BPL FindShell               ;/
  ReturnJumpLoop:
    RTS

HandleJumpOver:
    LDA.w $322C,y               ;\ 
    SEC                         ;|
    SBC #$1A                    ;|
    STA $00                     ;|
    LDA $326E,y                 ;|
    SBC #$00                    ;|
    STA $08                     ;|
    LDA.b #$44                  ;|
    STA $02                     ;|
    LDA $3216,y                 ;| If the shell isn't close enough
    STA $01                     ;|  or isn't on the ground, ignore it.
    LDA.w $3258,y               ;|
    STA $09                     ;|
    LDA #$10                    ;|
    STA $03                     ;|
    JSL $03B69F                 ;|
    JSL $03B72B                 ;|
    BCC JumpLoopNext            ;|
    JSR IsOnGround              ;|
    BEQ JumpLoopNext            ;/
    LDA $3334,y                 ;\ 
    CMP $3334,x                 ;| If the Koopa and shell are moving in the same direction, don't jump.
    BEQ .return                 ;/
    LDA #!jumpSpeed
    STA $9E,x
    STZ $33FA,x
  .return
    RTS 





KickKill:
    LDA #$10
    STA $749A
    LDA #!kickedSound
    STA !kickedPort
    LDA #$E0
    STA $9E,x
    LDA #$02
    STA $3242,x
    STY $76
    LDA #!kickedPoints
    JSL $02ACE5
    RTS



SmokeParticles:
    LDA.w $334A,X
    BEQ .return
    LDA $13
    AND.b #$03
    ORA $86
    BNE .return
    LDA.b #$04
    STA $00
    LDA.b #$0A
    STA $01
    JSR SubIsOffscreen
    BNE .return
    LDY.b #$03
  .smokeLoop
    LDA.w $77C0,Y
    BEQ FoundSmokeSlot
    DEY
    BPL .smokeLoop
  .return
    RTS

FoundSmokeSlot:
    LDA.b #$03
    STA.w $77C0,Y
    LDA $322C,X
    ADC $00
    STA.w $77C8,Y
    LDA $3216,X
    ADC $01
    STA.w $77C4,Y
    LDA.b #$13
    STA.w $77CC,Y
    RTS



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; gfx routine
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Graphics:
    JSR GetDrawInfo
    LDA $3242,x
    BEQ .return
    CMP #$03
    BEQ Squished
    
    LDA $750A,x                 ;\ 
    AND #$40                    ;|
    BEQ .notAlt                 ;|
    LDA #$07                    ;|
  .notAlt                       ;|
    CLC                         ;| Set tile number.
    ADC $33CE,x                 ;|
    LDY $33A2,x                 ;|
    TAX                         ;|
    LDA Tilemap,x               ;|
    STA $6302,y                 ;/
    LDX $75E9                   ;
    LDA $00                     ;\ 
    STA $6300,y                 ;| Set X/Y position.
    LDA $01                     ;|
    STA $6301,y                 ;/
    LDA $3334,x                 ;\ 
    LSR                         ;|
    LDA #$00                    ;|
    ORA $33B8,X                 ;|
    BCS .noXFlip                ;|
    EOR #$40                    ;|
  .noXFlip                      ;| Set YXPPCCCT.
    PHA                         ;|  Flip X if the sprite is facing left.
    LDA $3242,x                 ;|  Set Y if killed.
    CMP #$03                    ;|
    PLA                         ;|
    BCS .noYFlip                ;|
    ORA #$80                    ;|
  .noYFlip                      ;|
    ORA $64                     ;|
    STA $6303,y                 ;/
    LDA #$00                    ;\ 
    LDY #$02                    ;| Draw a 16x16.
    JSL $01B7B3                 ;/
  .return
    RTS

Squished:
    LDA $00                     ;\ 
    STA $6300,y                 ;|
    CLC                         ;| Set X position.
    ADC #$08                    ;|
    STA $6304,y                 ;/
    LDA $01                     ;\ 
    CLC                         ;|
    ADC #$08                    ;| Set Y position.
    STA $6301,y                 ;|
    STA $6305,y                 ;/
    LDA #!squishTile            ;\ 
    STA $6302,y                 ;| Set tile number.
    STA $6306,y                 ;/
    LDA $64                     ;\ 
    ORA $33B8,x                 ;|
    STA $6303,y                 ;| Set YXPPCCCT.
    ORA #$40                    ;|
    STA $6307,y                 ;/
    LDA #$01                    ;\ 
    LDY #$00                    ;| Draw two 8x8s.
    JSL $01B7B3                 ;/
    RTS


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; shared subroutines
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; SubHorzPos
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SubHorzPos:
    LDY.b #$00
    LDA $D1
    SEC
    SBC $322C,X
    STA $0F
    LDA $D2
    SBC $326E,X
    BPL .return
    INY
  .return
    RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; FaceMario
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
FaceMario:
    JSR SubHorzPos
    TYA
    STA $3334,X
    RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; IsOnGround
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
IsOnGround:
    LDA $334A,X
    AND #$04
    RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; SetAnimationFrame
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SetAnimationFrame:
    INC $331E,x
    LDA $331E,x
    LSR
    LSR
    LSR
    AND #$01
    STA $33CE,x
    RTS
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; FlipSpriteDir / FlipIfTouchingObj
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FlipIfTouchingObj:
    LDA.w $3334,X
    INC A
    AND.w $334A,X
    AND.b #$03
    BEQ ReturnFlip
    
FlipSpriteDir:
    LDA.w $338C,X
    BNE ReturnFlip
    LDA.b #$08
    STA.w $338C,X
    LDA $B6,X
    EOR.b #$FF
    INC A
    STA $B6,X
    LDA.w $3334,X
    EOR.b #$01
    STA.w $3334,X
ReturnFlip:
    RTS



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; SubOffScreen
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Table1:              db $0C,$1C
Table2:              db $01,$02
Table3:              db $40,$B0
Table6:              db $01,$FF
Table4:              db $30,$C0,$A0,$C0,$A0,$F0,$60,$90,$30,$C0,$A0,$80,$A0,$40,$60,$B0
Table5:              db $01,$FF,$01,$FF,$01,$FF,$01,$FF,$01,$FF,$01,$FF,$01,$00,$01,$FF

SubOffscreenX0:
    STZ $03
    JSR SubIsOffscreen
    BEQ ReturnSOS
    LDA $5B
    LSR
    BCS VerticalLevel
    LDA $3216,x
    CLC
    ADC #$50
    LDA $3258,x
    ADC #$00
    CMP #$02
    BPL EraseSprite
    LDA $7616,x
    AND #$04
    BNE ReturnSOS
    LDA $13
    AND #$01
    ORA $03
    STA $01
    TAY
    LDA $1A
    CLC
    ADC Table4,y
    ROL $00
    CMP $322C,x
    PHP
    LDA $1B
    LSR $00
    ADC Table5,y
    PLP
    SBC $326E,x
    STA $00
    LSR $01
    BCC Label20
    EOR #$80
    STA $00
Label20:
    LDA $00
    BPL ReturnSOS

EraseSprite:
    LDA $3242,x
    CMP #$08
    BCC KillSprite
    LDY $7578,x
    CPY #$FF
    BEQ KillSprite
    LDA #$00
    PHX
    TYX
    STA $418A00,x
    PLX        
    KillSprite:
    STZ $3242,x
ReturnSOS:
    RTS

VerticalLevel:
    LDA $7616,x
    AND #$04
    BNE ReturnSOS
    LDA $13
    LSR
    BCS ReturnSOS
    AND #$01
    STA $01
    TAY
    LDA $1C
    CLC
    ADC Table3,y
    ROL $00
    CMP $3216,x
    PHP
    LDA $1D
    LSR $00
    ADC Table6,y
    PLP
    SBC $3258,x
    STA $00
    LDY $02
    BEQ Label22
    EOR #$80
    STA $00
Label22:
    LDA $00
    BPL ReturnSOS
    BMI EraseSprite

SubIsOffscreen:
    LDA $3376,x
    ORA $7642,x
    RTS



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; GetDrawInfo
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetDrawInfo:
    STZ $7642,x
    STZ $3376,x
    LDA $322C,x
    CMP $1A
    LDA $326E,x
    SBC $1B
    BEQ OnscreenX
    INC $3376,x
OnscreenX:
    LDA $326E,x
    XBA
    LDA $322C,x
    REP #$20
    SEC
    SBC $1A
    CLC
    ADC.w #$0040
    CMP #$0180
    SEP #$20
    ROL A
    AND #$01
    STA $7536,x
    BNE Invalid

    LDY #$00
    LDA $75EA,x
    AND #$20
    BEQ OnscreenLoop
    INY
OnscreenLoop:
    LDA $3216,x
    CLC
    ADC Table1,y
    PHP
    CMP $1C
    ROL $00
    PLP
    LDA $3258,x
    ADC #$00
    LSR $00
    SBC $1D
    BEQ OnscreenY
    LDA $7642,x
    ORA Table2,y
    STA $7642,x
OnscreenY:
    DEY
    BPL OnscreenLoop
    LDY $33A2,x
    LDA $322C,x
    SEC
    SBC $1A
    STA $00
    LDA $3216,x
    SEC
    SBC $1C
    STA $01
    RTS
    
Invalid:
    PLA
    PLA
    RTS