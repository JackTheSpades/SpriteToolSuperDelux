using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Reflection;
using System.Text.Json.Serialization;

namespace CFG.Json
{
    [AttributeUsage(AttributeTargets.All)]
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
                var attr = prop.GetCustomAttribute<JsonPropertyOrderAttribute>();
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
                var attr = prop.GetCustomAttribute<JsonPropertyOrderAttribute>();
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
}
