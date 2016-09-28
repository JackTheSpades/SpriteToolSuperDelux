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
!kickPort       =   $1DF9|!Base2
    ; Sound effect for when the Koopa kicks a shell.
    
!kickedSound    =   $03
!kickedPort     =   $1DF9|!Base2
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
    STA !1570,x         ;/
    LDA !7FAB28,x       ;\ Preserve extra byte 1.
    STA !1510,x         ;/
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
    LDA !14C8,x
    CMP #$08
    BCS NotDead
    STZ !1602,x
    JMP Graphics
  NotDead:
    LDA $9D                     ;\ Branch if the game is frozen.
    BEQ CheckStunned            ;|  Small bugfix here to not let Mario kill it by screenscrolling when he touches them.
    BRA GameFrozen              ;/  I'm not sure why Nintendo did that.



StationaryKoopa:
    LDA !163E,x                 ;\ 
    CMP #$80                    ;| Check the usage of $163E.
    BCC KickingKoopa            ;|  If 80-FF, the Koopa is stunned; animate it.
    LDA $9D                     ;|  If 01-7F, the Koopa is kicking a shell; don't animate it.
    BNE GameFrozen              ;/
StunnedKoopa:
    JSR SetAnimationFrame       ;\ 
    LDA !1602,x                 ;|
    CLC                         ;| Handle stunned animation.
    ADC #$04                    ;|
    STA !1602,x                 ;/
KickingKoopa:
    JSR StunnedInteraction      ; Handle contact with Mario.
GameFrozen:
    JSL $01802A                 ; Update position.
    STZ !B6,X                   ;\ 
    JSR IsOnGround              ;| Stop the Koopa and don't let it fall through the ground.
    BEQ FinishStunned           ;|
    STZ !AA,X                   ;/
FinishStunned:
    JMP SpriteInteraction       ; Process interaction with other sprites and draw graphics, then return.



StunnedInteraction:
    LDA !1510,x                 ;\ 
    AND #$20                    ;|
    BNE Kickable                ;| If not kickable and in contact with it, hurt Mario.
    JSL $01A7DC                 ;|
    RTS                         ;/

Kickable:
    ASL !167A,x                 ;\ 
    SEC                         ;|
    ROR !167A,x                 ;|
    JSL $01A7DC                 ;|
    BCC .noContact              ;| If kickable and in contact with it, kill it.
    JSR KickKill                ;|
  .noContact                    ;|
    ASL !167A,x                 ;|
    LSR !167A,x                 ;/
    RTS



CheckStunned:
    LDA !163E,x                 ;\ Skip if the Koopa is not stunned.
    BEQ CheckSliding            ;/
    CMP #$80                    ;\ If the stun timer is not exactly 80, branch.
    BNE .notUnstunning          ;/

    LDA !1510,x                 ;\ 
    AND #$10                    ;|
    BNE .noJump                 ;| Flip the sprite over and return to normal.
    LDA #!flipSpeed             ;|  Also make the sprite jump upward if kickable.
    STA !AA,x                   ;|
  .noJump                       ;|
    STZ !163E,x                 ;/

  .notUnstunning
    CMP #$01                    ;\ 
    BNE StationaryKoopa         ;|
    LDY !160E,x                 ;|
    LDA !14C8,y                 ;|
    CMP #$09                    ;| Jump back and handle basic stationary/stunned fuctions if:
    BNE StationaryKoopa         ;|  - The Koopa is not about to kick a shell/goomba/etc.
    LDA !E4,x                   ;|  - The state of the sprite being kicked isn't still 09 (stationary/carryable).
    SEC                         ;|  - The Koopa isn't close enough to the sprite anymore.
    SBC.w !E4,y                 ;|
    CLC                         ;|
    ADC #$12                    ;|
    CMP #$24                    ;|
    BCS StationaryKoopa         ;/
    LDA #!kickSound
    STA !kickPort
    LDA #$20                    ;\ 
    STA !C2,x                   ;| Disable contact with the sprite, and wait a bit before resuming movement.
    STA !1558,x                 ;/
    LDY !157C,x                 ;\ 
    LDA KickXSpeeds,y           ;|
    LDY !160E,x                 ;| Kick the sprite in the direction the Koopa is facing.
    STA.w !B6,y                 ;|
    LDA #$0A                    ;|
    STA !14C8,y                 ;/
    LDA !1540,y                 ;\ Mirror the sprite's stun timer, for no real reason.
    STA.w !C2,y                 ;/
    LDA #$08                    ;\ Briefly disable sprite interaction for the kicked sprite.
    STA !1564,y                 ;/
    LDA !167A,y                 ;\ 
    AND #$10                    ;|
    BEQ CheckSliding            ;| If it can't be kicked like a shell (i.e. Goombas, Bob-ombs, etc.), kick it slightly upwards.
    LDA #!kickYSpeed            ;|
    STA.w !AA,y                 ;/



CheckSliding:
    LDA $1528,x                 ;\ Skip if not sliding after being knocked out of a shell.
    BEQ CheckCatching           ;/

    LDA $1588,X                 ;\ 
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
    STZ $1570,x                 ; Don't animate.
    JSR StandardFunc            ; Run standard functions.
    LDA #$06                    ;\ 
    STA $1602,x                 ;| Draw sprite.
    JMP Graphics                ;/

  StopSliding:
    JSR IsOnGround              ;\ If the sprite is not on the ground, don't stun it?
    BEQ .dontStun               ;/
    LDY.b #!stunTimeA+$80       ;\ 
    LDA $1510,x                 ;|
    AND #$10                    ;|
    BEQ .longStun               ;|
    LDY.b #!stunTimeB+$80       ;| Stun the sprite and return back for basic functionality.
  .longStun                     ;|
    TYA                         ;|
    STA $163E,x                 ;|
  .dontStun                     ;|
    STZ $1528,x                 ;|
    JMP StunnedKoopa            ;/ 



CheckCatching:
    LDA.w $1534,X               ;\ Skip if not catching a shell/goomba/etc.
    BEQ CheckKicking            ;/
    
    LDY $160E,x                 ;\ 
    LDA $14C8,y                 ;|
    CMP #$0A                    ;| Clear the "catching" flag and branch if the shell has stopped.
    BEQ SlowDown                ;|
    STZ $1534,x                 ;|
    BRA NoFrictionCatch         ;/

  SlowDown:
    STA $1528,y                 ; Set the sliding flag.
    LDA $1588,X                 ;\ 
    AND #$03                    ;|
    BEQ .noWall                 ;| If the Koopa is pushed into a solid block, clear the X speed for both sprites.
    LDA #$00                    ;|
    STA $00B6,y                 ;|
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
    LDA $00B6,y                 ;|
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
    STA $00B6,y                 ;|
    STA $B6,x                   ;/
    JSR SmokeParticles          ;/
  NoFrictionCatch:              ;
    STZ $1570,X                 ; Don't animate.
    JSR StandardFunc            ; Run standard functions.
    RTS

  StopCatching:
    LDA.b #$00                  ;\ 
    STA $B6,x                   ;| Clear both sprites' X speeds.
    STA $00B6,y                 ;/
    STZ $1534,x
    LDA #$09                    ;\ Make the sprite stationary/carryable.
    STA $14C8,y                 ;/
    LDA $009E,y                 ;\ 
    CMP #$0D                    ;|
    BEQ .setStun                ;|
    CMP #$0F                    ;|
    BEQ .setStun                ;| If the sprite is a Goomba/Bob-omb/MechaKoopa, reset their stun timer to #$FF.
    CMP #$A2                    ;|
    BNE CheckKicking            ;|
  .setStun                      ;|
    LDA #$FF                    ;|
    STA $1540,y                 ;/


CheckKicking:
    LDA $C2,x                   ;\ Skip if the Koopa is not in the process of kicking/flipping a shell.
    BEQ CheckEntering           ;/
    DEC $C2,x
    CMP #$08                    ;\ 
    LDA #$03                    ;|
    BCS .waiting                ;| Animate kicking the shell.
    LDA #$00                    ;|
  .waiting                      ;|
    STA $1602,x                 ;/
    JMP MarioInteraction        ; Run the shared routine.

CheckEntering:
    LDA $1558,x                 ;\ 
    CMP #$01                    ;| Skip if not about to enter a shell.
    BNE SetXSpeed               ;/
    LDY $1594,x                 ;\ 
    LDA $14C8,y                 ;|
    CMP #$08                    ;|
    BCC .return                 ;|
    LDA $00AA,y                 ;|
    BMI .return                 ;| Return if:
    LDA $009E,y                 ;|  - The shell is no longer alive.
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
    LDY $1594,x                 ;\ 
    LDA #!shakeTime             ;| Shake the shell.
    STA $1558,y                 ;/
    PHX
    LDA $1510,x                 ;\ 
    LDX #$03                    ;|
    AND #$80                    ;|
    BNE .disco                  ;| Turn the shell into a disco shell if applicable.
    LDX #$00                    ;|
  .disco                        ;|
    TXA                         ;|
    STA $160E,y                 ;/
    PLX
  .return
    RTS





SetXSpeed:
    JSR IsOnGround              ;\ Branch if the sprite is not on ground.
    BEQ .dontSetX               ;/
    LDY $157C,x                 ;\ 
    LDA $1510,x                 ;|
    AND #$01                    ;|
    BEQ .moveSlower             ;|
    INY                         ;|
    INY                         ;|
  .moveSlower                   ;| Set the sprite's X speed, depending on the type of slope it's standing on.
    LDA XSpeeds,y               ;| If the corresponding property bit is set, the sprite will move a bit faster.
    EOR $15B8,x                 ;|
    ASL                         ;|
    LDA XSpeeds,y               ;|
    BCC .sameDir                ;|
    CLC                         ;|
    ADC $15B8,x                 ;|
  .sameDir                      ;|
    STA $B6,x                   ;/
  .dontSetX
    LDY $157C,x                 ;\ 
    TYA                         ;|
    INC A                       ;|
    AND $1588,x                 ;| If the sprite hits the side of a block, stop it.
    AND #$03                    ;|
    BEQ .checkCeiling           ;|
    STZ $B6,x                   ;/
  .checkCeiling
    LDA $1588,x                 ;\ 
    AND #$08                    ;| If the sprite is hits a ceiling, clear its Y speed.
    BEQ StandardFunc            ;|
    STZ $AA,x                   ;/

StandardFunc:
    JSR SubOffscreenX0          ; Erase if offscreen.
    JSL $01802A                 ; Update the sprite's position and apply gravity.
    JSR SetAnimationFrame       ; Animate.
    JSR IsOnGround              ;\ Branch if not on the ground.
    BEQ SpriteInAir             ;/


SpriteOnGround:
    LDA $1588,x                 ;\ 
    BMI .onLayer2               ;|
    LDA #$00                    ;| 
    LDY $15B8,x                 ;| If standing on a slope or Layer 2, give the sprite a Y speed of #$18.
    BEQ .setSpeed               ;|  Else, clear its Y speed.
  .onLayer2                     ;|
    LDA #$18                    ;|
  .setSpeed                     ;|
    STA $AA,x                   ;/
    
    STZ $151C,x                 ; For sprites that stay on ledges: you're currently on a ledge.
    LDA $1510,x                 ;\ 
    PHA                         ;|
    AND #$04                    ;|
    BEQ .dontFollow             ;|
    LDA $1570,X                 ;|
    AND #!followTimer           ;|
    BNE .dontFollow             ;| Follow Mario if set to do so.
    LDA $157C,x                 ;| Don't turn if not time to or already facing Mario.
    PHA                         ;|
    JSR FaceMario               ;|
    PLA                         ;|
    CMP $157C,x                 ;|
    BEQ .dontFollow             ;|
    LDA #$08                    ;|
    STA $15AC,x                 ;/
  .dontFollow
    PLA                         ;\ 
    AND #$08                    ;| Jump over shells if set to do so.
    BEQ .dontJump               ;|
    JSR JumpOverShells          ;/
  .dontJump
    BRA MarioInteraction


SpriteInAir:
    LDA $1510,x                 ;\ 
    AND #$02                    ;|
    BEQ MarioInteraction        ;|
    LDA.w $151C,X               ;|
    ORA.w $1558,X               ;| If the sprite is set to turn on ledges and is not having a special function run,
    ORA.w $1528,X               ;|  flip its direction.
    ORA.w $1534,X               ;|
    BNE MarioInteraction        ;|
    JSR FlipSpriteDir           ;|
    LDA.b #$01                  ;|
    STA.w $151C,X               ;/


MarioInteraction:
    LDA.w $1528,X               ;\ 
    BEQ NormInteraction         ;|
    JSR StunnedInteraction      ;| If the sprite is not sliding, process standard interaction with Mario.
    BRA SpriteInteraction       ;|  If the sprite is sliding, check whether to kick-kill it.
  NormInteraction:              ;|
    JSL $01A7DC                 ;/

SpriteInteraction:
    JSL $018032                 ; Process interaction with other sprites.

    JSR FlipIfTouchingObj       ; Turn around if it hits a block.

    LDA $157C,X
    PHA
    LDY $15AC,X                 ;\ 
    BEQ .notTurning             ;|
    LDA #$02                    ;|
    STA $1602,X                 ;|
    LDA #$00                    ;| If the sprite's turn timer is non-zero, turn it around.
    CPY #$05                    ;| The actual turn occurs on frame 3 of the animation.
    BCC .stillWaiting           ;|
    INC A                       ;|
  .stillWaiting                 ;|
    EOR $157C,x                 ;|
    STA $157C,x                 ;/
  .notTurning
    JSR Graphics                ; Draw graphics.
    PLA
    STA.w $157C,X
    RTS





JumpOverShells:
    TXA                         ;\ 
    EOR $13                     ;| Divide detection across four frames. If not the right frame, return.
    AND #$03                    ;|
    BNE ReturnJumpLoop          ;/
    LDY #$09                    ;\ 
  FindShell:                    ;|
    LDA $14C8,y                 ;|
    CMP #$0A                    ;| Look for a sprite that's been thrown. Return if none exists.
    BEQ HandleJumpOver          ;|
  JumpLoopNext:                 ;|
    DEY                         ;|
    BPL FindShell               ;/
  ReturnJumpLoop:
    RTS

HandleJumpOver:
    LDA.w $00E4,y               ;\ 
    SEC                         ;|
    SBC #$1A                    ;|
    STA $00                     ;|
    LDA $14E0,y                 ;|
    SBC #$00                    ;|
    STA $08                     ;|
    LDA.b #$44                  ;|
    STA $02                     ;|
    LDA $00D8,y                 ;| If the shell isn't close enough
    STA $01                     ;|  or isn't on the ground, ignore it.
    LDA.w $14D4,y               ;|
    STA $09                     ;|
    LDA #$10                    ;|
    STA $03                     ;|
    JSL $03B69F                 ;|
    JSL $03B72B                 ;|
    BCC JumpLoopNext            ;|
    JSR IsOnGround              ;|
    BEQ JumpLoopNext            ;/
    LDA $157C,y                 ;\ 
    CMP $157C,x                 ;| If the Koopa and shell are moving in the same direction, don't jump.
    BEQ .return                 ;/
    LDA #!jumpSpeed
    STA $AA,x
    STZ $163E,x
  .return
    RTS 





KickKill:
    LDA #$10
    STA $149A
    LDA #!kickedSound
    STA !kickedPort
    LDA #$E0
    STA $AA,x
    LDA #$02
    STA $14C8,x
    STY $76
    LDA #!kickedPoints
    JSL $02ACE5
    RTS



SmokeParticles:
    LDA.w $1588,X
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
    LDA.w $17C0,Y
    BEQ FoundSmokeSlot
    DEY
    BPL .smokeLoop
  .return
    RTS

FoundSmokeSlot:
    LDA.b #$03
    STA.w $17C0,Y
    LDA $E4,X
    ADC $00
    STA.w $17C8,Y
    LDA $D8,X
    ADC $01
    STA.w $17C4,Y
    LDA.b #$13
    STA.w $17CC,Y
    RTS



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; gfx routine
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Graphics:
    JSR GetDrawInfo
    LDA $14C8,x
    BEQ .return
    CMP #$03
    BEQ Squished
    
    LDA $1510,x                 ;\ 
    AND #$40                    ;|
    BEQ .notAlt                 ;|
    LDA #$07                    ;|
  .notAlt                       ;|
    CLC                         ;| Set tile number.
    ADC $1602,x                 ;|
    LDY $15EA,x                 ;|
    TAX                         ;|
    LDA Tilemap,x               ;|
    STA $0302,y                 ;/
    LDX $15E9                   ;
    LDA $00                     ;\ 
    STA $0300,y                 ;| Set X/Y position.
    LDA $01                     ;|
    STA $0301,y                 ;/
    LDA $157C,x                 ;\ 
    LSR                         ;|
    LDA #$00                    ;|
    ORA $15F6,X                 ;|
    BCS .noXFlip                ;|
    EOR #$40                    ;|
  .noXFlip                      ;| Set YXPPCCCT.
    PHA                         ;|  Flip X if the sprite is facing left.
    LDA $14C8,x                 ;|  Set Y if killed.
    CMP #$03                    ;|
    PLA                         ;|
    BCS .noYFlip                ;|
    ORA #$80                    ;|
  .noYFlip                      ;|
    ORA $64                     ;|
    STA $0303,y                 ;/
    LDA #$00                    ;\ 
    LDY #$02                    ;| Draw a 16x16.
    JSL $01B7B3                 ;/
  .return
    RTS

Squished:
    LDA $00                     ;\ 
    STA $0300,y                 ;|
    CLC                         ;| Set X position.
    ADC #$08                    ;|
    STA $0304,y                 ;/
    LDA $01                     ;\ 
    CLC                         ;|
    ADC #$08                    ;| Set Y position.
    STA $0301,y                 ;|
    STA $0305,y                 ;/
    LDA #!squishTile            ;\ 
    STA $0302,y                 ;| Set tile number.
    STA $0306,y                 ;/
    LDA $64                     ;\ 
    ORA $15F6,x                 ;|
    STA $0303,y                 ;| Set YXPPCCCT.
    ORA #$40                    ;|
    STA $0307,y                 ;/
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
    SBC $E4,X
    STA $0F
    LDA $D2
    SBC $14E0,X
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
    STA $157C,X
    RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; IsOnGround
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
IsOnGround:
    LDA $1588,X
    AND #$04
    RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; SetAnimationFrame
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SetAnimationFrame:
    INC $1570,x
    LDA $1570,x
    LSR
    LSR
    LSR
    AND #$01
    STA $1602,x
    RTS
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; FlipSpriteDir / FlipIfTouchingObj
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FlipIfTouchingObj:
    LDA.w $157C,X
    INC A
    AND.w $1588,X
    AND.b #$03
    BEQ ReturnFlip
    
FlipSpriteDir:
    LDA.w $15AC,X
    BNE ReturnFlip
    LDA.b #$08
    STA.w $15AC,X
    LDA $B6,X
    EOR.b #$FF
    INC A
    STA $B6,X
    LDA.w $157C,X
    EOR.b #$01
    STA.w $157C,X
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
    LDA $D8,x
    CLC
    ADC #$50
    LDA $14D4,x
    ADC #$00
    CMP #$02
    BPL EraseSprite
    LDA $167A,x
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
    CMP $E4,x
    PHP
    LDA $1B
    LSR $00
    ADC Table5,y
    PLP
    SBC $14E0,x
    STA $00
    LSR $01
    BCC Label20
    EOR #$80
    STA $00
Label20:
    LDA $00
    BPL ReturnSOS

EraseSprite:
    LDA $14C8,x
    CMP #$08
    BCC KillSprite
    LDY $161A,x
    CPY #$FF
    BEQ KillSprite
    LDA #$00
    STA $1938,y
    KillSprite:
    STZ $14C8,x
ReturnSOS:
    RTS

VerticalLevel:
    LDA $167A,x
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
    CMP $D8,x
    PHP
    LDA $1D
    LSR $00
    ADC Table6,y
    PLP
    SBC $14D4,x
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
    LDA $15A0,x
    ORA $186C,x
    RTS



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; GetDrawInfo
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetDrawInfo:
    STZ $186C,x
    STZ $15A0,x
    LDA $E4,x
    CMP $1A
    LDA $14E0,x
    SBC $1B
    BEQ OnscreenX
    INC $15A0,x
OnscreenX:
    LDA $14E0,x
    XBA
    LDA $E4,x
    REP #$20
    SEC
    SBC $1A
    CLC
    ADC.w #$0040
    CMP #$0180
    SEP #$20
    ROL A
    AND #$01
    STA $15C4,x
    BNE Invalid

    LDY #$00
    LDA $1662,x
    AND #$20
    BEQ OnscreenLoop
    INY
OnscreenLoop:
    LDA $D8,x
    CLC
    ADC Table1,y
    PHP
    CMP $1C
    ROL $00
    PLP
    LDA $14D4,x
    ADC #$00
    LSR $00
    SBC $1D
    BEQ OnscreenY
    LDA $186C,x
    ORA Table2,y
    STA $186C,x
OnscreenY:
    DEY
    BPL OnscreenLoop
    LDY $15EA,x
    LDA $E4,x
    SEC
    SBC $1A
    STA $00
    LDA $D8,x
    SEC
    SBC $1C
    STA $01
    RTS
    
Invalid:
    PLA
    PLA
    RTS