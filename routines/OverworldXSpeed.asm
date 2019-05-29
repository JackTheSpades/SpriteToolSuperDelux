; void -> void
; uses $00

	LDA !ow_sprite_speed_x,x
	BEQ .return
	BMI .negative
	XBA
	AND #$FF00
	CLC
	ADC !ow_sprite_speed_x_acc,x
	STA !ow_sprite_speed_x_acc,x
	PHP
	LDA !ow_sprite_speed_x,x
	XBA
	AND #$00FF
	PLP
	ADC !ow_sprite_x_pos,x
	STA !ow_sprite_x_pos,x
.return
	RTL
	
.negative
	EOR #$FFFF
	INC
	PHA
	XBA
	AND #$FF00
	STA $00
	LDA !ow_sprite_speed_x_acc,x
	SEC
	SBC $00
	STA !ow_sprite_speed_x_acc,x
	PLA
	PHP
	XBA
	AND #$00FF
	STA $00
	PLP
	LDA !ow_sprite_x_pos,x
	SBC $00
	STA !ow_sprite_x_pos,x
	RTL

