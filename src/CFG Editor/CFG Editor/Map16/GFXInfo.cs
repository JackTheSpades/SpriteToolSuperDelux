﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Diagnostics;
using System.ComponentModel;
using System.Text.Json.Serialization;

namespace CFG.Map16
{

    [DebuggerDisplay("Value={Value}, Separate={Separate}")]
    public struct SingleFile
    {
        public int Value;
        public bool Separate;
    }

    public class SingleFileDefaultValueAttribute : DefaultValueAttribute
    {
        public SingleFileDefaultValueAttribute() : base(new SingleFile { Value = 0x7F, Separate = false })
        {
        }
    }

    [DebuggerDisplay("SP0={Sp0}, SP1={Sp1}, SP2={Sp2}, SP3={Sp3}")]
    public class GFXInfo : ICloneable, INotifyPropertyChanged
    {
        public event PropertyChangedEventHandler PropertyChanged;

        public object Clone()
        {
            GFXInfo info = new GFXInfo {
                _Sp0 = this._Sp0,
                _Sp1 = this._Sp1,
                _Sp2 = this._Sp2,
                _Sp3 = this._Sp3,
            };
            return info;
        }

        private SingleFile _Sp0 = new SingleFile { Value = 0x7F, Separate = false };
        private SingleFile _Sp1 = new SingleFile { Value = 0x7F, Separate = false };
        private SingleFile _Sp2 = new SingleFile { Value = 0x7F, Separate = false };
        private SingleFile _Sp3 = new SingleFile { Value = 0x7F, Separate = false };

        [JsonPropertyName("0")]
        [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingDefault)]
        [SingleFileDefaultValue()]
        [Browsable(false)]
        public SingleFile Sp0 { get => _Sp0; set { _Sp0 = value; PropertyChanged.Invoke(this, new PropertyChangedEventArgs(nameof(Sp0))); } }
        [JsonPropertyName("1")]
        [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingDefault)]
        [SingleFileDefaultValue()]
        [Browsable(false)]
        public SingleFile Sp1 { get => _Sp1; set { _Sp1 = value; PropertyChanged.Invoke(this, new PropertyChangedEventArgs(nameof(Sp1))); } }
        [JsonPropertyName("2")]
        [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingDefault)]
        [SingleFileDefaultValue()]
        [Browsable(false)]
        public SingleFile Sp2 { get => _Sp2; set { _Sp2 = value; PropertyChanged.Invoke(this, new PropertyChangedEventArgs(nameof(Sp2))); } }
        [JsonPropertyName("3")]
        [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingDefault)]
        [SingleFileDefaultValue()]
        [Browsable(false)]
        public SingleFile Sp3 { get => _Sp3; set { _Sp3 = value; PropertyChanged.Invoke(this, new PropertyChangedEventArgs(nameof(Sp3))); } }

        [JsonIgnore]
        public int Sp0Value { get => _Sp0.Value; set { _Sp0.Value = value; PropertyChanged.Invoke(this, new PropertyChangedEventArgs(nameof(Sp0.Value))); } }
        [JsonIgnore]
        public bool Sp0Sep { get => _Sp0.Separate; set { _Sp0.Separate = value; PropertyChanged.Invoke(this, new PropertyChangedEventArgs(nameof(Sp0.Separate)));  } }
        [JsonIgnore]
        public int Sp1Value { get => _Sp1.Value; set { _Sp1.Value = value; PropertyChanged.Invoke(this, new PropertyChangedEventArgs(nameof(Sp1.Value))); } }
        [JsonIgnore]
        public bool Sp1Sep { get => _Sp1.Separate; set { _Sp1.Separate = value; PropertyChanged.Invoke(this, new PropertyChangedEventArgs(nameof(Sp1.Separate))); } }
        [JsonIgnore]
        public int Sp2Value { get => _Sp2.Value; set { _Sp2.Value = value; PropertyChanged.Invoke(this, new PropertyChangedEventArgs(nameof(Sp2.Value))); } }
        [JsonIgnore]
        public bool Sp2Sep { get => _Sp2.Separate; set { _Sp2.Separate = value; PropertyChanged.Invoke(this, new PropertyChangedEventArgs(nameof(Sp2.Separate))); } }
        [JsonIgnore]
        public int Sp3Value { get => _Sp3.Value; set { _Sp3.Value = value; PropertyChanged.Invoke(this, new PropertyChangedEventArgs(nameof(Sp3.Value))); } }
        [JsonIgnore]
        public bool Sp3Sep { get => _Sp3.Separate; set {_Sp3.Separate = value; PropertyChanged.Invoke(this, new PropertyChangedEventArgs(nameof(Sp3.Separate))); } }
    }
}
