using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Newtonsoft.Json;
using System.Reflection;

namespace CFG.Json
{
    public class JsonIntPropertyAttribute : Attribute
    {
        public int Size { get; set; }
    }

    /// <summary>
    /// Basis class for JSON objects that are representativ for a single byte.
    /// That is to say, their properties can be compiled into a byte.
    /// Only properties having the <see cref="JsonPropertyAttribute"/> or <see cref="JsonIntPropertyAttribute"/> are used to build the byte by default.
    /// </summary>
    public abstract class ByteRepresentant
    {
        /// <summary>
        /// The method used to compile the byte. It looks for all bool or int properties within the class.
        /// For bool properties the <see cref="JsonPropertyAttribute.Order"/> field is used to indicate which bit in the byte to set.
        /// For int properties, in addition, the <see cref="JsonIntPropertyAttribute.Size"/> field is used to determine how many bits to set.
        /// </summary>
        /// <returns>The compiled byte representing this object</returns>
        public virtual byte ToByte()
        {
            byte b = 0;
            var props = GetType().GetProperties();
            foreach(var prop in props)
            {
                var attr = prop.GetCustomAttribute<JsonPropertyAttribute>();
                if (attr == null)
                    continue;
                if (prop.PropertyType == typeof(bool))
                {
                    bool bit = (bool)prop.GetValue(this);
                    b = b.SetBit(attr.Order, bit);
                }
                else if(prop.PropertyType == typeof(int))
                {
                    var iAttr = prop.GetCustomAttribute<JsonIntPropertyAttribute>();
                    if (iAttr == null)
                        continue;

                    int bits = (int)prop.GetValue(this);
                    b = b.SetBits(bits, iAttr.Size, attr.Order);
                }
            }
            return b;
        }
        /// <summary>
        /// The method used to set the properties of this object from a byte. It looks for all bool or int properties within the class.
        /// For bool properties the <see cref="JsonPropertyAttribute.Order"/> field is used to indicate which bit of the byte is used to set the property.
        /// For int properties, in addition, the <see cref="JsonIntPropertyAttribute.Size"/> field is used to determine how many bits of the byte to read.
        /// </summary>
        /// <returns>The compiled byte representing this object</returns>
        public virtual void FromByte(byte value)
        {
            var props = GetType().GetProperties();
            foreach (var prop in props)
            {
                var attr = prop.GetCustomAttribute<JsonPropertyAttribute>();
                if (attr == null)
                    continue;
                if (prop.PropertyType == typeof(bool))
                {
                    bool bit = value.GetBit(attr.Order);
                    prop.SetValue(this, bit);
                }
                else if(prop.PropertyType == typeof(int))
                {
                    var iAttr = prop.GetCustomAttribute<JsonIntPropertyAttribute>();
                    if (iAttr == null)
                        continue;

                    int bits = value.GetBits(iAttr.Size, attr.Order);
                    prop.SetValue(this, bits);
                }
            }
        }

        /// <summary>
        /// Compares to another object. If it also is a <see cref="ByteRepresentant"/> their byte values are compared.
        /// </summary>
        /// <param name="obj">The object to compare to</param>
        /// <returns><c>True</c> if obj is a <see cref="ByteRepresentant"/> and their byte values are the same.</returns>
        public override bool Equals(object obj)
        {
            if (ReferenceEquals(this, obj))
                return true;
            ByteRepresentant br = obj as ByteRepresentant;
            if (ReferenceEquals(br, null))
                return false;
            return ToByte() == br.ToByte();
        }
        /// <summary>
        /// Returns the byte representation of the object
        /// </summary>
        /// <returns>The byte representation</returns>
        public override int GetHashCode() => ToByte();
        public override string ToString() => string.Format("0x{0:X2}", ToByte());
    }

    public class Value1656 : ByteRepresentant
    {
        [JsonProperty(Order = 0, PropertyName = "Object Clipping")]
        [JsonIntProperty(Size = 4)]
        public int Object_Clipping { get; set; }
        [JsonProperty(Order = 4, PropertyName = "Can be jumped on")]
        public bool Can_Be_Jumped_On { get; set; }
        [JsonProperty(Order = 5, PropertyName = "Dies when jumped on")]
        public bool Dies_When_Jumped_On { get; set; }
        [JsonProperty(Order = 6, PropertyName = "Hop in/kick shell")]
        public bool Hop_in_kick_shell { get; set; }
        [JsonProperty(Order = 7, PropertyName = "Disappears in cloud of smoke")]
        public bool Disappears_In_Could_Of_Smoke { get; set; }
    }

    public class Value1662 : ByteRepresentant
    {
        [JsonProperty(Order = 0, PropertyName = "Sprite Clipping")]
        [JsonIntProperty(Size = 6)]
        public int Sprite_Clipping { get; set; }
        [JsonProperty(Order = 6, PropertyName = "Use shell as death frame")]
        public bool Use_Shell_As_Death_Frame { get; set; }
        [JsonProperty(Order = 7, PropertyName = "Fall straight down when killed")]
        public bool Fall_Staight_Down_When_Killed { get; set; }
    }

    public class Value166E : ByteRepresentant
    {
        [JsonProperty(Order = 0, PropertyName = "Use second graphics page")]
        public bool Use_Second_Graphics_Page { get; set; }
        [JsonProperty(Order = 1, PropertyName = "Palette")]
        [JsonIntProperty(Size = 3)]
        public int Palette { get; set; }
        [JsonProperty(Order = 4, PropertyName = "Disable fireball killing")]
        public bool Disable_Fireball_Killing { get; set; }
        [JsonProperty(Order = 5, PropertyName = "Disable cape killing")]
        public bool Disable_Cape_Killing { get; set; }
        [JsonProperty(Order = 6, PropertyName = "Disable water splash")]
        public bool Disable_Water_Splash { get; set; }
        [JsonProperty(Order = 7, PropertyName = "Don't interact with Layer 2")]
        public bool Dont_Interact_With_L2 { get; set; }
    }

    public class Value167A : ByteRepresentant
    {
        [JsonProperty(Order = 0, PropertyName = "Don't disable cliping when starkilled")]
        public bool Dont_Disable_Clipping_When_Startkilled { get; set; }
        [JsonProperty(Order = 1, PropertyName = "Invincible to star/cape/fire/bounce blk.")]
        public bool Invincible_to_star_cape_fire_bounce { get; set; }
        [JsonProperty(Order = 2, PropertyName = "Process when off screen")]
        public bool Process_when_offscreen { get; set; }
        [JsonProperty(Order = 3, PropertyName = "Don't change into shell when stunned")]
        public bool Dont_change_into_shell_when_stunned { get; set; }
        [JsonProperty(Order = 4, PropertyName = "Can't be kicked like shell")]
        public bool Cant_be_kicked_like_shell { get; set; }
        [JsonProperty(Order = 5, PropertyName = "Process interaction with Mario every frame")]
        public bool Interact_with_mario_every_frame { get; set; }
        [JsonProperty(Order = 6, PropertyName = "Gives power-up when eaten by yoshi")]
        public bool Gives_powerup_when_eaten_by_yoshi { get; set; }
        [JsonProperty(Order = 7, PropertyName = "Don't use default interaction with Mario")]
        public bool Dont_use_default_interaction_with_Mario { get; set; }
    }

    public class Value1686 : ByteRepresentant
    {
        [JsonProperty(Order = 0, PropertyName = "Inedible")]
        public bool Inedible { get; set; }
        [JsonProperty(Order = 1, PropertyName = "Stay in Yoshi's mouth")]
        public bool Stay_in_yoshi_mouth { get; set; }
        [JsonProperty(Order = 2, PropertyName = "Weird ground behaviour")]
        public bool Weird_ground_behaviour { get; set; }
        [JsonProperty(Order = 3, PropertyName = "Don't interact with other sprites")]
        public bool Dont_interact_with_other_sprites { get; set; }
        [JsonProperty(Order = 4, PropertyName = "Don't change direction if touched")]
        public bool Dont_change_direction_if_touched { get; set; }
        [JsonProperty(Order = 5, PropertyName = "Don't turn into coin when goal passed")]
        public bool Dont_turn_into_coin_when_goal_passed { get; set; }
        [JsonProperty(Order = 6, PropertyName = "Spawn a new sprite")]
        public bool Spawn_a_new_sprite { get; set; }
        [JsonProperty(Order = 7, PropertyName = "Don't interact with objects")]
        public bool Dont_interact_with_objects { get; set; }
    }

    public class Value190F : ByteRepresentant
    {
        [JsonProperty(Order = 0, PropertyName = "Make platform passable from below")]
        public bool Make_platform_passable_from_below { get; set; }
        [JsonProperty(Order = 1, PropertyName = "Don't erase when goal passed")]
        public bool Dont_erase_when_goal_passed { get; set; }
        [JsonProperty(Order = 2, PropertyName = "Can't be killed by sliding")]
        public bool Cant_be_killed_by_sliding { get; set; }
        [JsonProperty(Order = 3, PropertyName = "Takes 5 fireballs to kill")]
        public bool Takes_5_fireballs_to_kill { get; set; }
        [JsonProperty(Order = 4, PropertyName = "Can be jumped on with upwards Y speed")]
        public bool Can_be_jumped_on_with_upwards_speed { get; set; }
        [JsonProperty(Order = 5, PropertyName = "Death frame two tiles high")]
        public bool Death_frame_two_tiles_high { get; set; }
        [JsonProperty(Order = 6, PropertyName = "Don't turn into a coin with silver POW")]
        public bool Dont_turn_into_a_coin_with_silver_pow { get; set; }
        [JsonProperty(Order = 7, PropertyName = "Don't get stuck in walls (carryable sprites)")]
        public bool Dont_get_stuck_in_walls { get; set; }
    }
}
