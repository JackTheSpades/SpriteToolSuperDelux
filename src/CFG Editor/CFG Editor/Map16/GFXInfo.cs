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

        private int _Sp0 = 0x7F;
        private int _Sp1 = 0x7F;
        private int _Sp2 = 0x7F;
        private int _Sp3 = 0x7F;

        [JsonProperty(PropertyName = "0", DefaultValueHandling = DefaultValueHandling.Ignore)]
        [DefaultValue(0x7F)]
        public int Sp0 { get => _Sp0; set => _Sp0 = value; }
        [JsonProperty(PropertyName = "1", DefaultValueHandling = DefaultValueHandling.Ignore)]
        [DefaultValue(0x7F)]
        public int Sp1 { get => _Sp1; set => _Sp1 = value; }
        [JsonProperty(PropertyName = "2", DefaultValueHandling = DefaultValueHandling.Ignore)]
        [DefaultValue(0x7F)]
        public int Sp2 { get => _Sp2; set => _Sp2 = value; }
        [JsonProperty(PropertyName = "3", DefaultValueHandling = DefaultValueHandling.Ignore)]
        [DefaultValue(0x7F)]
        public int Sp3 { get => _Sp3; set => _Sp3 = value; }


    }
}
