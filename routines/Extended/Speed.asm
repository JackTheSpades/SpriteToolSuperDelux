
;Input:  A   = type of speed update
;              0 ... x+y with high gravity (YSpeed +3 every flame)
;              1 ... x+y without gravity
;              2 ... x only
;              3 ... y only
;              4 ... x+y with low gravity (YSpeed +1 every flame)(Lava Lotus's fiery objects)
;              5 ... x+y with normal gravity (YSpeed +2 every flame)(Hammer,Coin from coin cloud game,etc...)
;              6 ... x+y with high gravity (YSpeed +3 every flame)(PIXI Orifinal (Same as 0) )
;              7 ... x+y with very high gravity (YSpeed +4 every flame)(Player fireball)

?main:
   CMP #$04 : BCS ?+ : CMP #$00
   BEQ ?.SpriteSpd
   DEC : BEQ ?.SpriteSpdNoGravity
   DEC : BEQ ?.SpriteXSpd
   BRA ?.SpriteYSpd
?+ SBC #$03
   LDY !extended_y_speed,x
   BMI $04
   CPY #$40 : BPL ?.SpriteSpdNoGravity
   CLC : ADC !extended_y_speed,x
   STA !extended_y_speed,x
   BRA ?.SpriteSpdNoGravity

;; sprite x + y speed handler; has gravity.
?.SpriteSpd
    LDA !extended_y_speed,x
    BMI $04
    CMP #$40 : BPL ?.SpriteSpdNoGravity
    CLC : ADC #$03
    STA !extended_y_speed,x

;; sprite x + y speed handler; no gravity.
?.SpriteSpdNoGravity
    JSL ?.SpriteYSpd

;; original sprite x speed handler.
?.SpriteXSpd
    PHK
    PEA.w ?..donex-1
    PEA.w $B889-1        ;RTS in bank 02
    JML $02B554|!BankB
?..donex
    RTL

;; original sprite y speed handler.
?.SpriteYSpd
    PHK
    PEA.w ?..doney-1
    PEA.w $B889-1        ;RTS in bank 02
    JML $02B560|!BankB
?..doney
    RTL
