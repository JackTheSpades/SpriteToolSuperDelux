using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Diagnostics;
using System.ComponentModel;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace CFG.Map16
{
    [DebuggerDisplay("Separate={Separate}, SP0={Sp0}, SP1={Sp1}, SP2={Sp2}, SP3={Sp3}")]
    public class GFXInfo : ICloneable, INotifyPropertyChanged
    {
        public event PropertyChangedEventHandler PropertyChanged;

        public object Clone()
        {
            GFXInfo info = new GFXInfo {
                _Separate = this._Separate,
                _Sp0 = this._Sp0,
                _Sp1 = this._Sp1,
                _Sp2 = this._Sp2,
                _Sp3 = this._Sp3,
            };
            return info;
        }

        private bool _Separate;
        public bool Separate { get => _Separate; set => _Separate = value;}

        private int _Sp0;
        private int _Sp1;
        private int _Sp2;
        private int _Sp3;

        class SPSerializer : JsonConverter
        {
            public override bool CanConvert(Type objectType)
            {
                return objectType == typeof(int);
            }

            public override object ReadJson(JsonReader reader, Type objectType, object existingValue, JsonSerializer serializer)
            {
                var token = JToken.ReadFrom(reader);
                if (token.Type == JTokenType.Integer)
                    return (int)token;
                return null;
            }

            public override void WriteJson(JsonWriter writer, object value, JsonSerializer serializer)
            {
                if (value == null || (int)value == 0x7F)
                    return;
                serializer.Serialize(writer, (int)value);
            }
        }

        [JsonProperty(PropertyName = "0")]
        [JsonConverter(typeof(SPSerializer))]
        public int Sp0 { get => _Sp0; set => _Sp0 = value; }
        [JsonProperty(PropertyName = "1")]
        [JsonConverter(typeof(SPSerializer))]
        public int Sp1 { get => _Sp1; set => _Sp1 = value; }
        [JsonProperty(PropertyName = "2")]
        [JsonConverter(typeof(SPSerializer))]
        public int Sp2 { get => _Sp2; set => _Sp2 = value; }
        [JsonProperty(PropertyName = "3")]
        [JsonConverter(typeof(SPSerializer))]
        public int Sp3 { get => _Sp3; set => _Sp3 = value; }


    }
}
