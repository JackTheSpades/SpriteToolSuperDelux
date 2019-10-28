; void ->  void

	TXA
	CLC
	ADC.w #!OwSprSize*4
	TAX
	%OverworldXSpeed()
	LDX !ow_sprite_index
	RTL

