using Newtonsoft.Json;

namespace CFG.Json
{
    public class Value1656 : ByteRepresentant 
    {
        [JsonProperty(Order = 0, PropertyName = "Object Clipping")]
        [JsonIntProperty(Size = 4)]
        public int ObjectClipping { get; set; }
        [JsonProperty(Order = 4, PropertyName = "Can be jumped on")]
        public bool CanBeJumpedOn { get; set; }
        [JsonProperty(Order = 5, PropertyName = "Dies when jumped on")]
        public bool DiesWhenJumpedOn { get; set; }
        [JsonProperty(Order = 6, PropertyName = "Hop in/kick shell")]
        public bool HopInkickShell { get; set; }
        [JsonProperty(Order = 7, PropertyName = "Disappears in cloud of smoke")]
        public bool DisappearsInCloudOfSmoke { get; set; }
    }

    public class Value1662 : ByteRepresentant 
    {
        [JsonProperty(Order = 0, PropertyName = "Sprite Clipping")]
        [JsonIntProperty(Size = 6)]
        public int SpriteClipping { get; set; }
        [JsonProperty(Order = 6, PropertyName = "Use shell as death frame")]
        public bool UseShellAsDeathFrame { get; set; }
        [JsonProperty(Order = 7, PropertyName = "Fall straight down when killed")]
        public bool FallStraightDownWhenKilled { get; set; }
    }

    public class Value166E : ByteRepresentant 
    {
        [JsonProperty(Order = 0, PropertyName = "Use second graphics page")]
        public bool UseSecondGraphicsPage { get; set; }
        [JsonProperty(Order = 1, PropertyName = "Palette")]
        [JsonIntProperty(Size = 3)]
        public int Palette { get; set; }
        [JsonProperty(Order = 4, PropertyName = "Disable fireball killing")]
        public bool DisableFireballKilling { get; set; }
        [JsonProperty(Order = 5, PropertyName = "Disable cape killing")]
        public bool DisableCapeKilling { get; set; }
        [JsonProperty(Order = 6, PropertyName = "Disable water splash")]
        public bool DisableWaterSplash { get; set; }
        [JsonProperty(Order = 7, PropertyName = "Don't interact with Layer 2")]
        public bool DontInteractWithLayer2 { get; set; }
    }

    public class Value167A : ByteRepresentant 
    {
        [JsonProperty(Order = 0, PropertyName = "Don't disable cliping when starkilled")]
        public bool DontDisableClipingWhenStarkilled { get; set; }
        [JsonProperty(Order = 1, PropertyName = "Invincible to star/cape/fire/bounce blk.")]
        public bool InvincibleToStarcapefirebounceBlk { get; set; }
        [JsonProperty(Order = 2, PropertyName = "Process when off screen")]
        public bool ProcessWhenOffScreen { get; set; }
        [JsonProperty(Order = 3, PropertyName = "Don't change into shell when stunned")]
        public bool DontChangeIntoShellWhenStunned { get; set; }
        [JsonProperty(Order = 4, PropertyName = "Can't be kicked like shell")]
        public bool CantBeKickedLikeShell { get; set; }
        [JsonProperty(Order = 5, PropertyName = "Process interaction with Mario every frame")]
        public bool ProcessInteractionWithMarioEveryFrame { get; set; }
        [JsonProperty(Order = 6, PropertyName = "Gives power-up when eaten by yoshi")]
        public bool GivesPowerupWhenEatenByYoshi { get; set; }
        [JsonProperty(Order = 7, PropertyName = "Don't use default interaction with Mario")]
        public bool DontUseDefaultInteractionWithMario { get; set; }
    }

    public class Value1686 : ByteRepresentant 
    {
        [JsonProperty(Order = 0, PropertyName = "Inedible")]
        public bool Inedible { get; set; }
        [JsonProperty(Order = 1, PropertyName = "Stay in Yoshi's mouth")]
        public bool StayInYoshisMouth { get; set; }
        [JsonProperty(Order = 2, PropertyName = "Weird ground behaviour")]
        public bool WeirdGroundBehaviour { get; set; }
        [JsonProperty(Order = 3, PropertyName = "Don't interact with other sprites")]
        public bool DontInteractWithOtherSprites { get; set; }
        [JsonProperty(Order = 4, PropertyName = "Don't change direction if touched")]
        public bool DontChangeDirectionIfTouched { get; set; }
        [JsonProperty(Order = 5, PropertyName = "Don't turn into coin when goal passed")]
        public bool DontTurnIntoCoinWhenGoalPassed { get; set; }
        [JsonProperty(Order = 6, PropertyName = "Spawn a new sprite")]
        public bool SpawnANewSprite { get; set; }
        [JsonProperty(Order = 7, PropertyName = "Don't interact with objects")]
        public bool DontInteractWithObjects { get; set; }
    }

    public class Value190F : ByteRepresentant 
    {
        [JsonProperty(Order = 0, PropertyName = "Make platform passable from below")]
        public bool MakePlatformPassableFromBelow { get; set; }
        [JsonProperty(Order = 1, PropertyName = "Don't erase when goal passed")]
        public bool DontEraseWhenGoalPassed { get; set; }
        [JsonProperty(Order = 2, PropertyName = "Can't be killed by sliding")]
        public bool CantBeKilledBySliding { get; set; }
        [JsonProperty(Order = 3, PropertyName = "Takes 5 fireballs to kill")]
        public bool Takes5FireballsToKill { get; set; }
        [JsonProperty(Order = 4, PropertyName = "Can be jumped on with upwards Y speed")]
        public bool CanBeJumpedOnWithUpwardsYSpeed { get; set; }
        [JsonProperty(Order = 5, PropertyName = "Death frame two tiles high")]
        public bool DeathFrameTwoTilesHigh { get; set; }
        [JsonProperty(Order = 6, PropertyName = "Don't turn into a coin with silver POW")]
        public bool DontTurnIntoACoinWithSilverPow { get; set; }
        [JsonProperty(Order = 7, PropertyName = "Don't get stuck in walls (carryable sprites)")]
        public bool DontGetStuckInWallsCarryableSprites { get; set; }
    }
}