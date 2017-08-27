using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Linq;
using System.Runtime.CompilerServices;
using System.Text;
using System.Threading.Tasks;

namespace CFG
{
    public class CollectionSprite : INotifyPropertyChanged
    {
        public event PropertyChangedEventHandler PropertyChanged;

        private string _Name;
        public string Name
        {
            get { return _Name; }
            set { SetPropertyValue(ref _Name, value); }
        }

        private bool _ExtraBit = false;
        public bool ExtraBit
        {
            get { return _ExtraBit; }
            set { SetPropertyValue(ref _ExtraBit, value); }
        }

        private byte _ExtraPropertyByte1;
        [Newtonsoft.Json.JsonProperty("Extra Property Byte 1")]
        public byte ExtraPropertyByte1
        {
            get { return _ExtraPropertyByte1; }
            set { SetPropertyValue(ref _ExtraPropertyByte1, value); }
        }

        private byte _ExtraPropertyByte2;
        [Newtonsoft.Json.JsonProperty("Extra Property Byte 2")]
        public byte ExtraPropertyByte2
        {
            get { return _ExtraPropertyByte2; }
            set { SetPropertyValue(ref _ExtraPropertyByte2, value); }
        }

        private byte _ExtraPropertyByte3;
        [Newtonsoft.Json.JsonProperty("Extra Property Byte 3")]
        public byte ExtraPropertyByte3
        {
            get { return _ExtraPropertyByte3; }
            set { SetPropertyValue(ref _ExtraPropertyByte3, value); }
        }

        private byte _ExtraPropertyByte4;
        [Newtonsoft.Json.JsonProperty("Extra Property Byte 4")]
        public byte ExtraPropertyByte4
        {
            get { return _ExtraPropertyByte4; }
            set { SetPropertyValue(ref _ExtraPropertyByte4, value); }
        }

        public CollectionSprite()
        {
        }
        public CollectionSprite(string line)
        {
            var match = System.Text.RegularExpressions.Regex.Match(line, "(?<E>\\d) (?<P1>[0-9A-Fa-f]{1,2}) (?<P2>[0-9A-Fa-f]{1,2}) (?<P3>[0-9A-Fa-f]{1,2}) (?<P4>[0-9A-Fa-f]{1,2}) (?<NAME>.*)");

            ExtraBit = match.Groups["E"].Value != "0";
            ExtraPropertyByte1 = Convert.ToByte(match.Groups["P1"].Value, 16);
            ExtraPropertyByte2 = Convert.ToByte(match.Groups["P2"].Value, 16);
            ExtraPropertyByte3 = Convert.ToByte(match.Groups["P3"].Value, 16);
            ExtraPropertyByte4 = Convert.ToByte(match.Groups["P4"].Value, 16);

            Name = match.Groups["NAME"].Value;
        }


        public override string ToString()
        {
            return $"{(ExtraBit ? 1 : 0)} {ExtraPropertyByte1.ToString("X2")} {ExtraPropertyByte2.ToString("X2")} {ExtraPropertyByte3.ToString("X2")} {ExtraPropertyByte4.ToString("X2")} {Name}";
        }

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
    }
}
