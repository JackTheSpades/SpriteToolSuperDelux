; void -> void

	TXA
	CLC
	ADC.w #!OwSprSize*2
	TAX
        %OverworldXSpeed()
	LDX !ow_sprite_index
	RTL

