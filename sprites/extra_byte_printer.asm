
print "INIT ",pc
		RTL
      
            
print "MAIN ",pc                      
      
      LDA !extra_byte_1,x
      STA $00
      LDA !extra_byte_2,x
      STA $01
      LDA !extra_byte_3,x
      STA $02
      LDA !extra_byte_4,x
      STA $03
		RTL                     ; /        