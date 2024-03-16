using System.Text.Json.Serialization;

namespace CFG.Json
{
    public class Value1656 : ByteRepresentant
    {
        [JsonPropertyName("Object Clipping")]
        [JsonPropertyOrder(0)]
        [JsonIntProperty(Size = 4)]
        public int ObjectClipping { get; set; }
        [JsonPropertyName("Can be jumped on")]
        [JsonPropertyOrder(4)]
        public bool CanBeJumpedOn { get; set; }
        [JsonPropertyName("Dies when jumped on")]
        [JsonPropertyOrder(5)]
        public bool DiesWhenJumpedOn { get; set; }
        [JsonPropertyName("Hop in/kick shell")]
        [JsonPropertyOrder(6)]
        public bool HopInkickShell { get; set; }
        [JsonPropertyName("Disappears in cloud of smoke")]
        [JsonPropertyOrder(7)]
        public bool DisappearsInCloudOfSmoke { get; set; }
    }

    public class Value1662 : ByteRepresentant
    {
        [JsonPropertyName("Sprite Clipping")]
        [JsonPropertyOrder(0)]
        [JsonIntProperty(Size = 6)]
        public int SpriteClipping { get; set; }
        [JsonPropertyName("Use shell as death frame")]
        [JsonPropertyOrder(6)]
        public bool UseShellAsDeathFrame { get; set; }
        [JsonPropertyName("Fall straight down when killed")]
        [JsonPropertyOrder(7)]
        public bool FallStraightDownWhenKilled { get; set; }
    }

    public class Value166E : ByteRepresentant
    {
        [JsonPropertyName("Use second graphics page")]
        [JsonPropertyOrder(0)]
        public bool UseSecondGraphicsPage { get; set; }
        [JsonPropertyName("Palette")]
        [JsonPropertyOrder(1)]
        [JsonIntProperty(Size = 3)]
        public int Palette { get; set; }
        [JsonPropertyName("Disable fireball killing")]
        [JsonPropertyOrder(4)]
        public bool DisableFireballKilling { get; set; }
        [JsonPropertyName("Disable cape killing")]
        [JsonPropertyOrder(5)]
        public bool DisableCapeKilling { get; set; }
        [JsonPropertyName("Disable water splash")]
        [JsonPropertyOrder(6)]
        public bool DisableWaterSplash { get; set; }
        [JsonPropertyName("Don't interact with Layer 2")]
        [JsonPropertyOrder(7)]
        public bool DontInteractWithLayer2 { get; set; }
    }

    public class Value167A : ByteRepresentant
    {
        [JsonPropertyName("Don't disable cliping when starkilled")]
        [JsonPropertyOrder(0)]
        public bool DontDisableClipingWhenStarkilled { get; set; }
        [JsonPropertyName("Invincible to star/cape/fire/bounce blk.")]
        [JsonPropertyOrder(1)]
        public bool InvincibleToStarcapefirebounceBlk { get; set; }
        [JsonPropertyName("Process when off screen")]
        [JsonPropertyOrder(2)]
        public bool ProcessWhenOffScreen { get; set; }
        [JsonPropertyName("Don't change into shell when stunned")]
        [JsonPropertyOrder(3)]
        public bool DontChangeIntoShellWhenStunned { get; set; }
        [JsonPropertyName("Can't be kicked like shell")]
        [JsonPropertyOrder(4)]
        public bool CantBeKickedLikeShell { get; set; }
        [JsonPropertyName("Process interaction with Mario every frame")]
        [JsonPropertyOrder(5)]
        public bool ProcessInteractionWithMarioEveryFrame { get; set; }
        [JsonPropertyName("Gives power-up when eaten by yoshi")]
        [JsonPropertyOrder(6)]
        public bool GivesPowerupWhenEatenByYoshi { get; set; }
        [JsonPropertyName("Don't use default interaction with Mario")]
        [JsonPropertyOrder(7)]
        public bool DontUseDefaultInteractionWithMario { get; set; }
    }

    public class Value1686 : ByteRepresentant
    {
        [JsonPropertyName("Inedible")]
        [JsonPropertyOrder(0)]
        public bool Inedible { get; set; }
        [JsonPropertyName("Stay in Yoshi's mouth")]
        [JsonPropertyOrder(1)]
        public bool StayInYoshisMouth { get; set; }
        [JsonPropertyName("Weird ground behaviour")]
        [JsonPropertyOrder(2)]
        public bool WeirdGroundBehaviour { get; set; }
        [JsonPropertyName("Don't interact with other sprites")]
        [JsonPropertyOrder(3)]
        public bool DontInteractWithOtherSprites { get; set; }
        [JsonPropertyName("Don't change direction if touched")]
        [JsonPropertyOrder(4)]
        public bool DontChangeDirectionIfTouched { get; set; }
        [JsonPropertyName("Don't turn into coin when goal passed")]
        [JsonPropertyOrder(5)]
        public bool DontTurnIntoCoinWhenGoalPassed { get; set; }
        [JsonPropertyName("Spawn a new sprite")]
        [JsonPropertyOrder(6)]
        public bool SpawnANewSprite { get; set; }
        [JsonPropertyName("Don't interact with objects")]
        [JsonPropertyOrder(7)]
        public bool DontInteractWithObjects { get; set; }
    }

    public class Value190F : ByteRepresentant
    {
        [JsonPropertyName("Make platform passable from below")]
        [JsonPropertyOrder(0)]
        public bool MakePlatformPassableFromBelow { get; set; }
        [JsonPropertyName("Don't erase when goal passed")]
        [JsonPropertyOrder(1)]
        public bool DontEraseWhenGoalPassed { get; set; }
        [JsonPropertyName("Can't be killed by sliding")]
        [JsonPropertyOrder(2)]
        public bool CantBeKilledBySliding { get; set; }
        [JsonPropertyName("Takes 5 fireballs to kill")]
        [JsonPropertyOrder(3)]
        public bool Takes5FireballsToKill { get; set; }
        [JsonPropertyName("Can be jumped on with upwards Y speed")]
        [JsonPropertyOrder(4)]
        public bool CanBeJumpedOnWithUpwardsYSpeed { get; set; }
        [JsonPropertyName("Death frame two tiles high")]
        [JsonPropertyOrder(5)]
        public bool DeathFrameTwoTilesHigh { get; set; }
        [JsonPropertyName("Don't turn into a coin with silver POW")]
        [JsonPropertyOrder(6)]
        public bool DontTurnIntoACoinWithSilverPow { get; set; }
        [JsonPropertyName("Don't get stuck in walls (carryable sprites)")]
        [JsonPropertyOrder(7)]
        public bool DontGetStuckInWallsCarryableSprites { get; set; }
    }
}