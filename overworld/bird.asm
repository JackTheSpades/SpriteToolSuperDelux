; did you know: owls are birds

!distance = $0035

!props1 = $32	; yxPPccCt
!props2 = $34	; yxPPcCct

!beak_down_time = $0008

!max_idle_time = $0080
!min_idle_time = $0008

!idle_frame = $0000
!beak_down_frame = $0001
!flying1_frame = $0002
!flying2_frame = $0003


!state = !ow_sprite_misc_1		; 0 idle, 1 idle beak down, 2 flying
!animationframe = !ow_sprite_misc_2		; index to tilemap
!direction = !ow_sprite_misc_3
;facing direction
!roost_index = !ow_sprite_misc_4
;0-3, the tree we want to be on right now

!timer = !ow_sprite_timer_1

;------------------------------------------------

print "INIT ",pc
	LDA #!max_idle_time-!min_idle_time+1
	%GetRandomRange()
        AND #$0001
        STA !direction,x
	CLC
	ADC #!min_idle_time
	STA !timer,x

        ;randomize position
        LDA #$0004
        %GetRandomRange()
        ASL
        STA $00
        LDA !ow_sprite_extra_bits,x
        ASL #2
        CLC
        ADC $00
        TAY
        LDA main_x_positions,y
        STA !ow_sprite_x_pos,x
        LDA main_y_positions,y
        STA !ow_sprite_y_pos,x
	RTL

;------------------------------------------------

print "MAIN ",pc
main:
	JSR draw_gfx
	
	LDA !state,x
	CMP #$0002
	BEQ .fly

        ;check if mario is close
        %OverworldDistance()
        LDA $06
        CLC
        ADC $08
        CMP #!distance
        BCS .NoFlyZone


;get a new destination tree and enter fly state, speed math is done every frame during that state
        LDA #$0002
        STA !state,x

        LDA #$0004
        %GetRandomRange()
        STA !roost_index,x
        RTL


.NoFlyZone
        ;lui code
        LDA !state,x
        DEC
        BEQ .beak_down

.idle
        LDA !timer,x
        BNE +

        INC !state,x
        LDA #!beak_down_time
        STA !timer,x
        LDA #!beak_down_frame
        STA !animationframe,x
+       RTL


.beak_down
        LDA !timer,x
        BNE +

        DEC !state,x

        LDA #!max_idle_time-!min_idle_time+1
        %GetRandomRange()
        CLC
        ADC #!min_idle_time
        STA !timer,x

        LDA #!idle_frame
        STA !animationframe,x
+       RTL
	
	
.fly
;animate
        LDA $14
        LSR #2
        CLC
        ADC !ow_sprite_index
        AND #$0001
        CLC
        ADC #$0002
        STA !animationframe,x

;set up aiming routine
;figure out speeds to the tree
        LDA !ow_sprite_extra_bits,x
        ASL #2
        CLC
        ADC !roost_index,x      ;get goal position
        ASL
        TAY
        LDA .y_positions,y
        STA $00
        LDA .x_positions,y
        STA $02

;shooter - target x and y
        LDA !ow_sprite_x_pos,x
        SEC
        SBC $00
        STA $00
        LDA !ow_sprite_y_pos,x
        SEC
        SBC $02
        STA $02

        LDA #$0040
        %Aiming()
;x speed is now in $00
;y speed is now in $02

        LDA $00
        BIT #$0080
        BEQ .NoORAX
        ORA #$FF00
.NoORAX
        STA !ow_sprite_speed_x,x
        LDA $02
        BIT #$0080
        BEQ .NoORAY
        ORA #$FF00
.NoORAY
        STA !ow_sprite_speed_y,x

;update x and y positions
        %OverworldXSpeed()
        %OverworldYSpeed()
        RTL

	
;1D 04 small tree left
;2C 01 big tree upper
;23 06 small tree right
;2A 08 big tree lower
	
.x_positions:
        dw $1D*8,$2C*8,$23*8,$2A*8	; bird 1
        dw $1E*8,$2D*8,$24*8,$2B*8	; bird 2
.y_positions:
        dw $03*8+3,$00*8+4,$05*8+1,$07*8+5	; bird 1
        dw $03*8+2,$00*8+6,$05*8+2,$07*8+7	; bird 2

;------------------------------------------------

draw_gfx:
	LDA #$0000
	%OverworldGetDrawInfoPriority()
        BCS .offscreen

        PHY
        TYA
        LSR #2
        TAY
        SEP #$20
        LDA #$00
        STA $0420|!Base2,y
        PLY

        LDA $00
        STA $0200|!Base2,y

        LDA $02
        STA $0201|!Base2,y

        LDA !animationframe,x
        TAX
        LDA .tilemap,x
        STA $0202|!Base2,y

        LDX !ow_sprite_index
        LDA !ow_sprite_extra_bits,x
        TAX
        LDA .props,x
        STA $04
        LDX !ow_sprite_index
        LDA !direction,x
        TAX
        LDA .xflip,x
        ORA $04
        STA $0203|!Base2,y

        REP #$20
        SEP #$10
.offscreen
        RTS

.tilemap
        db $D2,$D3      ; standing
        db $D0,$D1      ; flying
.props
        db !props1,!props2
.xflip
        db $40,$00

