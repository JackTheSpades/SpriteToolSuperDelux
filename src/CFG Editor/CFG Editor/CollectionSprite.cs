using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Linq;
using System.Runtime.CompilerServices;
using System.Text;
using System.Threading.Tasks;

namespace CFG
{
    /// <summary>
    /// Class represents an entry of a custom collection for Lunar Magic, holding a name and "how" to insert it.
    /// That is to say, the extra bit, extra bytes and sprite number. However, the sprite number will be added by PIXI as we don't know it yet.
    /// </summary>
    public class CollectionSprite : ICloneable, INotifyPropertyChanged
    {
        /// <summary>
        /// Event that is triggered when a property is set to a new value.
        /// </summary>
        public event PropertyChangedEventHandler PropertyChanged;

        private string _Name;
        /// <summary>
        /// The name of the sprite entry.
        /// </summary>
        [Newtonsoft.Json.JsonProperty("Name")]
        public string Name
        {
            get { return _Name; }
            set { SetPropertyValue(ref _Name, value); }
        }

        private bool _ExtraBit = false;
        /// <summary>
        /// Whether the sprite entry has the custom bit set.
        /// </summary>
        [Newtonsoft.Json.JsonProperty("ExtraBit")]
        public bool ExtraBit
        {
            get { return _ExtraBit; }
            set { SetPropertyValue(ref _ExtraBit, value); }
        }

        private byte _ExtraPropertyByte1;
        /// <summary>
        /// The first extra byte. Only used if the sprite has <see cref="CfgFile.ByteCount"/> or <see cref="CfgFile.ExByteCount"/> set to be larger or equal to 1, 
        /// depending on <see cref="ExtraBit"/>. Regardless the value is always saved into the json file.
        /// </summary>
        [Newtonsoft.Json.JsonProperty("Extra Property Byte 1")]
        public byte ExtraPropertyByte1
        {
            get { return _ExtraPropertyByte1; }
            set { SetPropertyValue(ref _ExtraPropertyByte1, value); }
        }

        private byte _ExtraPropertyByte2;
        /// <summary>
        /// The first extra byte. Only used if the sprite has <see cref="CfgFile.ByteCount"/> or <see cref="CfgFile.ExByteCount"/> set to be larger or equal to 2, 
        /// depending on <see cref="ExtraBit"/>. Regardless the value is always saved into the json file.
        /// </summary>
        [Newtonsoft.Json.JsonProperty("Extra Property Byte 2")]
        public byte ExtraPropertyByte2
        {
            get { return _ExtraPropertyByte2; }
            set { SetPropertyValue(ref _ExtraPropertyByte2, value); }
        }

        private byte _ExtraPropertyByte3;
        /// <summary>
        /// The first extra byte. Only used if the sprite has <see cref="CfgFile.ByteCount"/> or <see cref="CfgFile.ExByteCount"/> set to be larger or equal to 3, 
        /// depending on <see cref="ExtraBit"/>. Regardless the value is always saved into the json file.
        /// </summary>
        [Newtonsoft.Json.JsonProperty("Extra Property Byte 3")]
        public byte ExtraPropertyByte3
        {
            get { return _ExtraPropertyByte3; }
            set { SetPropertyValue(ref _ExtraPropertyByte3, value); }
        }

        private byte _ExtraPropertyByte4;
        /// <summary>
        /// The first extra byte. Only used if the sprite has <see cref="CfgFile.ByteCount"/> or <see cref="CfgFile.ExByteCount"/> set to be larger or equal to 4, 
        /// depending on <see cref="ExtraBit"/>. Regardless the value is always saved into the json file.
        /// </summary>
        [Newtonsoft.Json.JsonProperty("Extra Property Byte 4")]
        public byte ExtraPropertyByte4
        {
            get { return _ExtraPropertyByte4; }
            set { SetPropertyValue(ref _ExtraPropertyByte4, value); }
        }

        /// <summary>
        /// Invokes the <see cref="PropertyChanged"/> event if the value of
        /// </summary>
        /// <typeparam name="T"></typeparam>
        /// <param name="priv"></param>
        /// <param name="val"></param>
        /// <param name="caller"></param>
        protected void SetPropertyValue<T>(ref T priv, T val, [CallerMemberName] string caller = "")
        {
            bool pn = ReferenceEquals(priv, null);
            bool vn = ReferenceEquals(val, null);

            if (pn && vn)
                return;
            if ((pn && !vn) || !priv.Equals(val))
            {
                priv = val;
                PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(caller));
            }
        }

        /// <summary>
        /// Creates a deep copy of the object
        /// </summary>
        /// <returns>A new copy of the object</returns>
        public object Clone()
        {
            return new CollectionSprite()
            {
                Name = this.Name,
                ExtraBit = this.ExtraBit,
                ExtraPropertyByte1 = this.ExtraPropertyByte1,
                ExtraPropertyByte2 = this.ExtraPropertyByte2,
                ExtraPropertyByte3 = this.ExtraPropertyByte3,
                ExtraPropertyByte4 = this.ExtraPropertyByte4,
            };
        }
    }
}
