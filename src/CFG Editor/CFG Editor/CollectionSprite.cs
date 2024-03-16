using System;
using System.ComponentModel;
using System.Runtime.CompilerServices;
using System.Text.Json;
using System.Text.Json.Serialization;

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
        [JsonPropertyName("Name")]
        public string Name
        {
            get { return _Name; }
            set { SetPropertyValue(ref _Name, value); }
        }

        private bool _ExtraBit = false;
        /// <summary>
        /// Whether the sprite entry has the custom bit set.
        /// </summary>
        [JsonPropertyName("ExtraBit")]
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
        [JsonPropertyName("Extra Property Byte 1")]
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
        [JsonPropertyName("Extra Property Byte 2")]
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
        [JsonPropertyName("Extra Property Byte 3")]
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
        [JsonPropertyName("Extra Property Byte 4")]
        public byte ExtraPropertyByte4
        {
            get { return _ExtraPropertyByte4; }
            set { SetPropertyValue(ref _ExtraPropertyByte4, value); }
        }

        private byte _ExtraPropertyByte5;
        /// <summary>
        /// The first extra byte. Only used if the sprite has <see cref="CfgFile.ByteCount"/> or <see cref="CfgFile.ExByteCount"/> set to be larger or equal to 4, 
        /// depending on <see cref="ExtraBit"/>. Regardless the value is always saved into the json file.
        /// </summary>
        [JsonPropertyName("Extra Property Byte 5")]
        public byte ExtraPropertyByte5
        {
            get { return _ExtraPropertyByte5; }
            set { SetPropertyValue(ref _ExtraPropertyByte5, value); }
        }

        private byte _ExtraPropertyByte6;
        /// <summary>
        /// The first extra byte. Only used if the sprite has <see cref="CfgFile.ByteCount"/> or <see cref="CfgFile.ExByteCount"/> set to be larger or equal to 4, 
        /// depending on <see cref="ExtraBit"/>. Regardless the value is always saved into the json file.
        /// </summary>
        [JsonPropertyName("Extra Property Byte 6")]
        public byte ExtraPropertyByte6
        {
            get { return _ExtraPropertyByte6; }
            set { SetPropertyValue(ref _ExtraPropertyByte6, value); }
        }

        private byte _ExtraPropertyByte7;
        /// <summary>
        /// The first extra byte. Only used if the sprite has <see cref="CfgFile.ByteCount"/> or <see cref="CfgFile.ExByteCount"/> set to be larger or equal to 4, 
        /// depending on <see cref="ExtraBit"/>. Regardless the value is always saved into the json file.
        /// </summary>
        [JsonPropertyName("Extra Property Byte 7")]
        public byte ExtraPropertyByte7
        {
            get { return _ExtraPropertyByte7; }
            set { SetPropertyValue(ref _ExtraPropertyByte7, value); }
        }

        private byte _ExtraPropertyByte8;
        /// <summary>
        /// The first extra byte. Only used if the sprite has <see cref="CfgFile.ByteCount"/> or <see cref="CfgFile.ExByteCount"/> set to be larger or equal to 4, 
        /// depending on <see cref="ExtraBit"/>. Regardless the value is always saved into the json file.
        /// </summary>
        [JsonPropertyName("Extra Property Byte 8")]
        public byte ExtraPropertyByte8
        {
            get { return _ExtraPropertyByte8; }
            set { SetPropertyValue(ref _ExtraPropertyByte8, value); }
        }

        private byte _ExtraPropertyByte9;
        /// <summary>
        /// The first extra byte. Only used if the sprite has <see cref="CfgFile.ByteCount"/> or <see cref="CfgFile.ExByteCount"/> set to be larger or equal to 4, 
        /// depending on <see cref="ExtraBit"/>. Regardless the value is always saved into the json file.
        /// </summary>
        [JsonPropertyName("Extra Property Byte 9")]
        public byte ExtraPropertyByte9
        {
            get { return _ExtraPropertyByte9; }
            set { SetPropertyValue(ref _ExtraPropertyByte9, value); }
        }

        private byte _ExtraPropertyByte10;
        /// <summary>
        /// The first extra byte. Only used if the sprite has <see cref="CfgFile.ByteCount"/> or <see cref="CfgFile.ExByteCount"/> set to be larger or equal to 4, 
        /// depending on <see cref="ExtraBit"/>. Regardless the value is always saved into the json file.
        /// </summary>
        [JsonPropertyName("Extra Property Byte 10")]
        public byte ExtraPropertyByte10
        {
            get { return _ExtraPropertyByte10; }
            set { SetPropertyValue(ref _ExtraPropertyByte10, value); }
        }

        private byte _ExtraPropertyByte11;
        /// <summary>
        /// The first extra byte. Only used if the sprite has <see cref="CfgFile.ByteCount"/> or <see cref="CfgFile.ExByteCount"/> set to be larger or equal to 4, 
        /// depending on <see cref="ExtraBit"/>. Regardless the value is always saved into the json file.
        /// </summary>
        [JsonPropertyName("Extra Property Byte 11")]
        public byte ExtraPropertyByte11
        {
            get { return _ExtraPropertyByte11; }
            set { SetPropertyValue(ref _ExtraPropertyByte11, value); }
        }

        private byte _ExtraPropertyByte12;
        /// <summary>
        /// The first extra byte. Only used if the sprite has <see cref="CfgFile.ByteCount"/> or <see cref="CfgFile.ExByteCount"/> set to be larger or equal to 4, 
        /// depending on <see cref="ExtraBit"/>. Regardless the value is always saved into the json file.
        /// </summary>
        [JsonPropertyName("Extra Property Byte 12")]
        public byte ExtraPropertyByte12
        {
            get { return _ExtraPropertyByte12; }
            set { SetPropertyValue(ref _ExtraPropertyByte12, value); }
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
            bool pn = priv == null;
            bool vn = val == null;

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
                ExtraPropertyByte5 = this.ExtraPropertyByte5,
                ExtraPropertyByte6 = this.ExtraPropertyByte6,
                ExtraPropertyByte7 = this.ExtraPropertyByte7,
                ExtraPropertyByte8 = this.ExtraPropertyByte8,
                ExtraPropertyByte9 = this.ExtraPropertyByte9,
                ExtraPropertyByte10 = this.ExtraPropertyByte10,
                ExtraPropertyByte11 = this.ExtraPropertyByte11,
                ExtraPropertyByte12 = this.ExtraPropertyByte12,
            };
        }
    }
}
