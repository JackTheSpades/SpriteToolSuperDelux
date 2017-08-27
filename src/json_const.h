// Tool generated code. See CFG Editor Solution (Build Json Cpp)
#define J1656_0	"Object Clipping"
#define J1656_4	"Can be jumped on"
#define J1656_5	"Dies when jumped on"
#define J1656_6	"Hop in/kick shell"
#define J1656_7	"Disappears in cloud of smoke"
#define J1656(c, j) {\
	c |= (((int)j[J1656_0] & 0x0F) << 0);\
	c |= (j[J1656_4] ? 0x10 : 0);\
	c |= (j[J1656_5] ? 0x20 : 0);\
	c |= (j[J1656_6] ? 0x40 : 0);\
	c |= (j[J1656_7] ? 0x80 : 0);\
	}


#define J1662_0	"Sprite Clipping"
#define J1662_6	"Use shell as death frame"
#define J1662_7	"Fall straight down when killed"
#define J1662(c, j) {\
	c |= (((int)j[J1662_0] & 0x3F) << 0);\
	c |= (j[J1662_6] ? 0x40 : 0);\
	c |= (j[J1662_7] ? 0x80 : 0);\
	}


#define J166E_0	"Use second graphics page"
#define J166E_1	"Palette"
#define J166E_4	"Disable fireball killing"
#define J166E_5	"Disable cape killing"
#define J166E_6	"Disable water splash"
#define J166E_7	"Don't interact with Layer 2"
#define J166E(c, j) {\
	c |= (j[J166E_0] ? 0x01 : 0);\
	c |= (((int)j[J166E_1] & 0x07) << 1);\
	c |= (j[J166E_4] ? 0x10 : 0);\
	c |= (j[J166E_5] ? 0x20 : 0);\
	c |= (j[J166E_6] ? 0x40 : 0);\
	c |= (j[J166E_7] ? 0x80 : 0);\
	}


#define J167A_0	"Don't disable cliping when starkilled"
#define J167A_1	"Invincible to star/cape/fire/bounce blk."
#define J167A_2	"Process when off screen"
#define J167A_3	"Don't change into shell when stunned"
#define J167A_4	"Can't be kicked like shell"
#define J167A_5	"Process interaction with Mario every frame"
#define J167A_6	"Gives power-up when eaten by yoshi"
#define J167A_7	"Don't use default interaction with Mario"
#define J167A(c, j) {\
	c |= (j[J167A_0] ? 0x01 : 0);\
	c |= (j[J167A_1] ? 0x02 : 0);\
	c |= (j[J167A_2] ? 0x04 : 0);\
	c |= (j[J167A_3] ? 0x08 : 0);\
	c |= (j[J167A_4] ? 0x10 : 0);\
	c |= (j[J167A_5] ? 0x20 : 0);\
	c |= (j[J167A_6] ? 0x40 : 0);\
	c |= (j[J167A_7] ? 0x80 : 0);\
	}


#define J1686_0	"Inedible"
#define J1686_1	"Stay in Yoshi's mouth"
#define J1686_2	"Weird ground behaviour"
#define J1686_3	"Don't interact with other sprites"
#define J1686_4	"Don't change direction if touched"
#define J1686_5	"Don't turn into coin when goal passed"
#define J1686_6	"Spawn a new sprite"
#define J1686_7	"Don't interact with objects"
#define J1686(c, j) {\
	c |= (j[J1686_0] ? 0x01 : 0);\
	c |= (j[J1686_1] ? 0x02 : 0);\
	c |= (j[J1686_2] ? 0x04 : 0);\
	c |= (j[J1686_3] ? 0x08 : 0);\
	c |= (j[J1686_4] ? 0x10 : 0);\
	c |= (j[J1686_5] ? 0x20 : 0);\
	c |= (j[J1686_6] ? 0x40 : 0);\
	c |= (j[J1686_7] ? 0x80 : 0);\
	}


#define J190F_0	"Make platform passable from below"
#define J190F_1	"Don't erase when goal passed"
#define J190F_2	"Can't be killed by sliding"
#define J190F_3	"Takes 5 fireballs to kill"
#define J190F_4	"Can be jumped on with upwards Y speed"
#define J190F_5	"Death frame two tiles high"
#define J190F_6	"Don't turn into a coin with silver POW"
#define J190F_7	"Don't get stuck in walls (carryable sprites)"
#define J190F(c, j) {\
	c |= (j[J190F_0] ? 0x01 : 0);\
	c |= (j[J190F_1] ? 0x02 : 0);\
	c |= (j[J190F_2] ? 0x04 : 0);\
	c |= (j[J190F_3] ? 0x08 : 0);\
	c |= (j[J190F_4] ? 0x10 : 0);\
	c |= (j[J190F_5] ? 0x20 : 0);\
	c |= (j[J190F_6] ? 0x40 : 0);\
	c |= (j[J190F_7] ? 0x80 : 0);\
	}


