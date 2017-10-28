;Aiming Routine by MarioE. 

;Input:  A   = 8 bit projectile speed
;        $00 = 16 bit (shooter x pos - target x pos)
;        $02 = 16 bit (shooter y pos - target y pos)
;
;Output: $00 = 8 bit X speed of projectile
;        $02 = 8 bit Y speed of projectile

.aiming
      
      PHX
      PHY
      PHP
      SEP #$30
      STA $0F
      
      LDX #$00
      REP #$20
      LDA $00
      BPL ..pos_dx
      EOR #$FFFF
      INC
      INX
      INX
      STA $00
..pos_dx
      SEP #$20
      if !SA1 == 0
         STA $4202
         STA $4203

         NOP
         NOP
         NOP
         REP #$20
         LDA $4216
      else
         STZ $2250
         STA $2251
         STZ $2252
         STA $2253
         STZ $2254
         NOP
         REP #$20
         LDA $2306
      endif
      STA $04
      LDA $02
      BPL ..pos_dy
      EOR #$FFFF
      INC
      INX
      STA $02
      
..pos_dy
      if !SA1 == 0
         STA $4202
         STA $4203

         STX $0E
         REP #$30
         LDA $04
         CLC
         ADC $4216
      else
         STZ $2250
         STA $2251
         STZ $2252
         STA $2253
         STZ $2254
         
         STX $0E
         REP #$30
         LDA $04
         CLC
         ADC $2306
      endif
      LDY #$0000
      BCC ..loop
      INY
      ROR
      LSR
..loop
      CMP #$0100
      BCC +
      INY
      LSR
      LSR
      BRA ..loop
   +  CLC
      ASL
      TAX
      LDA ..recip_sqrt_lookup,x
   -  DEY
      BMI +
      LSR
      BRA -
   +  SEP #$30
      
      if !SA1 == 0
         STA $4202
         LDA $0F
         STA $4203
         NOP
         STZ $05
         STZ $07
         LDA $4217
         STA $04
         XBA
         STA $4202
         LDA $0F
         STA $4203

         REP #$20
         LDA $04
         CLC
         ADC $4216
         STA $04
         SEP #$20

         LDX #$02
         -   LDA $04
         STA $4202
         LDA $00,x
         STA $4203

         NOP
         NOP
         NOP
         NOP

         LDA $4217
         STA $06
         LDA $05
         STA $4202
         LDA $00,x
         STA $4203

         REP #$20
         LDA $06
         CLC
         ADC $4216
         SEP #$20
      else
         STZ $2250
         STA $2251
         LDA $0F
         STA $2253
         STZ $2252
         STZ $2254
         STZ $05
         STZ $07
         LDA $2307
         STA $04
         XBA
         STZ $2250
         STA $2251
         STZ $2252
         LDA $0F
         STA $2253
         STZ $2254

         REP #$20
         LDA $04
         CLC
         ADC $2306
         STA $04
         SEP #$20

         LDX #$02
         -  
         LDA $04
         STZ $2250
         STA $2251
         STZ $2252
         LDA $00,X
         STA $2253
         STZ $2254

         NOP
         BRA $00

         LDA $2307
         STA $06
         LDA $05
         STZ $2250
         STA $2251
         STZ $2252
         LDA $00,X
         STA $2253
         STZ $2254

         REP #$20
         LDA $06
         CLC
         ADC $2306
         SEP #$20
      endif
      
      LSR $0E
      BCS +
      EOR #$FF
      INC
   +   STA $00,x
      DEX
      DEX
      BPL -
      
      PLP
      PLY
      PLX
      RTL
      
   
..recip_sqrt_lookup:
      dw $0000,$FFFF,$B505,$93CD,$8000,$727D,$6883,$60C2
      dw $5A82,$5555,$50F4,$4D30,$49E7,$4700,$446B,$4219
      dw $4000,$3E17,$3C57,$3ABB,$393E,$37DD,$3694,$3561
      dw $3441,$3333,$3235,$3144,$3061,$2F8A,$2EBD,$2DFB
      dw $2D41,$2C90,$2BE7,$2B46,$2AAB,$2A16,$2987,$28FE
      dw $287A,$27FB,$2780,$270A,$2698,$262A,$25BF,$2557
      dw $24F3,$2492,$2434,$23D9,$2380,$232A,$22D6,$2285
      dw $2236,$21E8,$219D,$2154,$210D,$20C7,$2083,$2041
      dw $2000,$1FC1,$1F83,$1F46,$1F0B,$1ED2,$1E99,$1E62
      dw $1E2B,$1DF6,$1DC2,$1D8F,$1D5D,$1D2D,$1CFC,$1CCD
      dw $1C9F,$1C72,$1C45,$1C1A,$1BEF,$1BC4,$1B9B,$1B72
      dw $1B4A,$1B23,$1AFC,$1AD6,$1AB1,$1A8C,$1A68,$1A44
      dw $1A21,$19FE,$19DC,$19BB,$199A,$1979,$1959,$1939
      dw $191A,$18FC,$18DD,$18C0,$18A2,$1885,$1869,$184C
      dw $1831,$1815,$17FA,$17DF,$17C5,$17AB,$1791,$1778
      dw $175F,$1746,$172D,$1715,$16FD,$16E6,$16CE,$16B7
      dw $16A1,$168A,$1674,$165E,$1648,$1633,$161D,$1608
      dw $15F4,$15DF,$15CB,$15B7,$15A3,$158F,$157C,$1568
      dw $1555,$1542,$1530,$151D,$150B,$14F9,$14E7,$14D5
      dw $14C4,$14B2,$14A1,$1490,$147F,$146E,$145E,$144D
      dw $143D,$142D,$141D,$140D,$13FE,$13EE,$13DF,$13CF
      dw $13C0,$13B1,$13A2,$1394,$1385,$1377,$1368,$135A
      dw $134C,$133E,$1330,$1322,$1315,$1307,$12FA,$12ED
      dw $12DF,$12D2,$12C5,$12B8,$12AC,$129F,$1292,$1286
      dw $127A,$126D,$1261,$1255,$1249,$123D,$1231,$1226
      dw $121A,$120F,$1203,$11F8,$11EC,$11E1,$11D6,$11CB
      dw $11C0,$11B5,$11AA,$11A0,$1195,$118A,$1180,$1176
      dw $116B,$1161,$1157,$114D,$1142,$1138,$112E,$1125
      dw $111B,$1111,$1107,$10FE,$10F4,$10EB,$10E1,$10D8
      dw $10CF,$10C5,$10BC,$10B3,$10AA,$10A1,$1098,$108F
      dw $1086,$107E,$1075,$106C,$1064,$105B,$1052,$104A
      dw $1042,$1039,$1031,$1029,$1020,$1018,$1010,$1008
