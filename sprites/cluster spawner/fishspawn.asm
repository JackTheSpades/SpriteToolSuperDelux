!SpikeCount = $09		; Amount of sprites to fall down, -1. Values outside of 00-13 are not recommended.

!ClusterSpriteNum = $0B		; Cluster sprite number




print "INIT ",pc



PHY              ; \ Wrapper.

PHB              ;  |

PHK              ;  |

PLB              ; /


LDY #!SpikeCount


-

LDA #!ClusterSpriteNum

STA $1892,y

LDA InitXY,y	; \ Initial X and Y position of each sprite.

PHA 		; | Is relative to screen border.

AND #$F0 	; |

STA $1E16,y 	; |

PLA 		; |

ASL #4		; |

STA $1E02,y 	; |

DEY 		; | Loop until all slots are done.

BPL - 		; /


LDA #$01 	; \ Run cluster sprite routine.

STA $18B8 	; /


PLB              ;

PLY              ;

RTL              ; Return.



InitXY:

db $06,$45,$9E,$E2,$A7,$BC,$59,$40,$61,$F5,$D6,$24,$7B,$33,$C6,$0B,$00,$39,$70,$A1

; Initial X and Y position table of sprites.

; Relative to screen border.

; Format: $xy



print "MAIN ",pc

STZ $14C8,x
RTL