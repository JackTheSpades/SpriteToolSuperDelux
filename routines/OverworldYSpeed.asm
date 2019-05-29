; void -> void

	TXA
	CLC
	ADC #!OwSprSize*2
	TAX
        %OverworldXSpeed()
	LDX !ow_sprite_index
	RTL

