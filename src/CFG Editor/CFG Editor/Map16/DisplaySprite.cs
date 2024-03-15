using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Diagnostics;
using System.Text.RegularExpressions;
using System.Drawing;
using System.ComponentModel;
using System.Runtime.CompilerServices;
using CFG.Json;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace CFG.Map16
{
    [DebuggerDisplay("X={X_or_index},Y={Y_or_value},Ex={ExtraBit}, Tiles: {Tiles.Count}, GFXInfo: {GFXInfo.Count}")]
    public class DisplaySprite : ICloneable, INotifyPropertyChanged
    {
        [JsonIgnore]
        private DisplayType _displayType;

        [JsonIgnore]
#pragma warning disable IDE1006 // Naming Styles
        public DisplayType disp_type
#pragma warning restore IDE1006 // Naming Styles
        {
            get
            {
                return _displayType;
            }
            set
            {
                _displayType = value;
                if (_displayType == DisplayType.XY)
                {
                    if (_X == null && _Y == null)
                    {
                        _X = _Index.GetValueOrDefault();
                        _Y = _Value.GetValueOrDefault();
                        _Index = null;
                        _Value = null;
                    }
                }
                else
                {
                    if (_Index == null && _Value == null)
                    {
                        _Index = _X.GetValueOrDefault();
                        _Value = _Y.GetValueOrDefault();
                        _X = null;
                        _Y = null;
                    }
                }
            }
        }
        /// <summary>
        /// The default sprite with only a description and one tile (a pink X)
        /// </summary>
        public static DisplaySprite Default => new()
        {
            Description = "Undefined Sprite",
            Tiles =
            [
                new Tile(0, 0, 0),
            ]
        };

        private string _Description = "";
        public string Description
        {
            get { return _Description; }
            set { SetPropertyValue(ref _Description, value); }
        }

        private bool _ExtraBit = false;
        public bool ExtraBit
        {
            get { return _ExtraBit; }
            set { SetPropertyValue(ref _ExtraBit, value); }
        }

        private bool _CustomBit = true;
        [Newtonsoft.Json.JsonIgnore]
        public bool CustomBit
        {
            get { return _CustomBit; }
            set { SetPropertyValue(ref _CustomBit, value); }
        }

        public BindingList<Tile> Tiles { get; set; }

        [EditorBrowsable(EditorBrowsableState.Always)]
        [DesignerSerializationVisibility(DesignerSerializationVisibility.Visible)]
        [Bindable(true)]
        public GFXInfo GFXInfo { get; set; }

        [Newtonsoft.Json.JsonIgnore]
        public bool CheckDispType => disp_type == DisplayType.XY;

        class DisplayTypeConverter : JsonConverter
        {
            public override bool CanConvert(Type objectType)
            {
                return (objectType == typeof(int));
            }

            public override object ReadJson(JsonReader reader, Type objectType, object existingValue, JsonSerializer serializer)
            {
                var token = JToken.Load(reader);
                if (token.Type == JTokenType.Integer)
                {
                    return (int)token;
                }
                return null;
            }

            public override void WriteJson(JsonWriter writer, object value, JsonSerializer serializer)
            {
                if (value != null)
                    serializer.Serialize(writer, ((int?)value).Value);
            }
        }

        [JsonProperty(PropertyName = "X", NullValueHandling = NullValueHandling.Ignore)]
        [JsonConverter(typeof(DisplayTypeConverter))]
        private int? _X = null;

        [JsonProperty(PropertyName = "Y", NullValueHandling = NullValueHandling.Ignore)]
        [JsonConverter(typeof(DisplayTypeConverter))]
        private int? _Y = null;

        [JsonProperty(PropertyName = "Value", NullValueHandling = NullValueHandling.Ignore)]
        [JsonConverter(typeof(DisplayTypeConverter))]
        private int? _Value = null;

        [JsonProperty(PropertyName = "Index", NullValueHandling = NullValueHandling.Ignore)]
        [JsonConverter(typeof(DisplayTypeConverter))]
        private int? _Index = null;

        [JsonIgnore]
        public int X_or_index
        {
            get { return (CheckDispType ? _X : _Index).GetValueOrDefault(); }
            set { SetPropertyValue(ref CheckDispType ? ref _X : ref _Index, value); }
        }

        [JsonIgnore]
        public int Y_or_value
        {
            get { return (CheckDispType ? _Y : _Value).GetValueOrDefault(); }
            set { SetPropertyValue(ref CheckDispType ? ref _Y : ref _Value, value); }
        }

        private string _DisplayText = "";
        public string DisplayText
        {
            get { return _DisplayText; }
            set { SetPropertyValue(ref _DisplayText, value); UseText = true; }
        }
        private bool _UseText = false;
        public bool UseText
        {
            get { return _UseText; }
            set { SetPropertyValue(ref _UseText, value); }
        }
        public event PropertyChangedEventHandler PropertyChanged;

        public DisplaySprite()
        {
            Tiles = [];
            GFXInfo = new GFXInfo();
        }

        //public static void FillData(DisplaySprite sprite, string tilesLine)
        //{
        //    sprite.Y = Convert.ToInt32(tilesLine.Substring(0, 1), 16);
        //    sprite.X = Convert.ToInt32(tilesLine.Substring(1, 1), 16);
        //    sprite.ExtraBit = tilesLine[2] == '3';

        //    foreach (Tile t in Tile.GetTiles(tilesLine))
        //        sprite.Tiles.Add(t);
        //}

        #region Object Overrides

        public override string ToString()
        {
            int ex = (CustomBit ? 2 : 0) + (ExtraBit ? 1 : 0);
            return ex + ":" + Y_or_value.ToString("X") + X_or_index.ToString("X");
        }
        public override bool Equals(object obj)
        {
            if (object.ReferenceEquals(this, obj))
                return true;
            if (this is null)
                return false;

            if (obj is not DisplaySprite sp)
                return false;

            return sp.CustomBit == CustomBit && sp.ExtraBit == ExtraBit
                && sp.Description == Description && sp.DisplayText == DisplayText && sp.UseText == UseText
                && sp.Tiles.SequenceEqual(Tiles);
        }
        public override int GetHashCode()
        {
            return (ExtraBit ? 0x100 : 0) + (CustomBit ? 0x200 : 0) + (X_or_index ^ Y_or_value);
        }

        #endregion
        #region Operators

        public static bool operator ==(DisplaySprite sp1, DisplaySprite sp2)
        {
            if (object.ReferenceEquals(sp1, sp2))
                return true;
            if (sp1 is null)
                return false;
            if (sp2 is null)
                return false;

            return sp1.CustomBit == sp2.CustomBit && sp1.ExtraBit == sp2.ExtraBit;
        }
        public static bool operator !=(DisplaySprite sp1, DisplaySprite sp2)
        {
            return !(sp1 == sp2);
        }

        #endregion

        public string GetTileLine()
        {
            if (UseText)
                return Y_or_value.ToString("X") + X_or_index.ToString("X") + (2 + (ExtraBit ? 0x10 : 0) + (CustomBit ? 0x20 : 0)).ToString("X2") + " 0,0,*" + DisplayText + "*";
            return Y_or_value.ToString("X") + X_or_index.ToString("X") + (2 + (ExtraBit ? 0x10 : 0) + (CustomBit ? 0x20 : 0)).ToString("X2") + " " + String.Join(" ", Tiles);
        }

        public object Clone()
        {
            DisplaySprite s = new()
            {
                CustomBit = this.CustomBit,
                Description = this.Description,
                ExtraBit = this.ExtraBit,
                Tiles = []
            };
            foreach (Tile t in Tiles)
                s.Tiles.Add((Tile)t.Clone());
            s.GFXInfo = (GFXInfo)GFXInfo.Clone();
            s.X_or_index = this.X_or_index;
            s.Y_or_value = this.Y_or_value;
            s.DisplayText = this.DisplayText;
            s.UseText = this.UseText;
            return s;
        }

        protected virtual void OnPropertyChanged(string propertyName)
        {
            PropertyChangedEventHandler handler = PropertyChanged;
            if (handler != null)
            {
                var e = new PropertyChangedEventArgs(propertyName);
                handler(this, e);
            }
        }

        protected void SetPropertyValue<T>(ref T priv, T val, [CallerMemberName] string caller = "")
        {
            bool pn = priv == null;
            bool vn = val == null;

            if (pn && vn)
                return;
            if ((pn && !vn) || !priv.Equals(val))
            {
                priv = val;
                OnPropertyChanged(caller);
            }
        }
    }

    public class DisplaySpriteUniqueComparer : IEqualityComparer<DisplaySprite>
    {
        public bool Equals(DisplaySprite x, DisplaySprite y)
        {
            return x.X_or_index == y.X_or_index && x.Y_or_value == y.Y_or_value && x.ExtraBit == y.ExtraBit;
        }

        public int GetHashCode(DisplaySprite obj)
        {
            return obj.X_or_index ^ obj.Y_or_value * (obj.ExtraBit ? -1 : 1);
        }
    }

    [DebuggerDisplay("{ToString()}")]
    public partial class Tile : ICloneable
    {

        [Newtonsoft.Json.JsonProperty("X offset")]
        public int XOffset { get; set; }
        [Newtonsoft.Json.JsonProperty("Y offset")]
        public int YOffset { get; set; }
        [Newtonsoft.Json.JsonProperty("map16 tile")]
        public int Map16Number { get; set; }

        [Newtonsoft.Json.JsonIgnore]
        public bool Selected { get; set; }

        public Tile()
        { }

        public Tile(int x, int y, int num)
        {
            XOffset = x;
            YOffset = y;
            Map16Number = num;
        }

        public override bool Equals(object obj)
        {
            if (Object.ReferenceEquals(this, obj))
                return true;
            if (this is null)
                return false;

            if (obj is not Tile t)
                return false;

            return t.Map16Number == this.Map16Number && t.XOffset == this.XOffset && t.YOffset == this.YOffset;
        }

        public override int GetHashCode()
        {
            return Map16Number + (XOffset << 13) + (YOffset << 20);
        }

        public override string ToString()
        {
            return XOffset + "," + YOffset + "," + Map16Number.ToString("X");
        }

        const string regex = "(?<X>-?\\d+),(?<Y>-?\\d+),(?<M>[0-9a-fA-F]+)";

        public static Tile GetTile(string str)
        {
            var match = TileRegex().Match(str);
            if (!match.Success)
                return null;

            int XOffset = Convert.ToInt32(match.Groups["X"].Value);
            int YOffset = Convert.ToInt32(match.Groups["Y"].Value);
            int Map16Number = Convert.ToInt32(match.Groups["M"].Value, 16);
            return new Tile(XOffset, YOffset, Map16Number);
        }

        public static IEnumerable<Tile> GetTiles(string str)
        {
            var matches = SpaceTileRegex().Matches(str);
            if (matches.Count == 0)
                yield break;

            foreach (var match in matches.Cast<Match>())
            {
                int XOffset = Convert.ToInt32(match.Groups["X"].Value);
                int YOffset = Convert.ToInt32(match.Groups["Y"].Value);
                int Map16Number = Convert.ToInt32(match.Groups["M"].Value, 16);
                yield return new Tile(XOffset, YOffset, Map16Number);
            }
        }

        public virtual object Clone()
        {
            return new Tile(XOffset, YOffset, Map16Number);
        }

        [GeneratedRegex(regex)]
        private static partial Regex TileRegex();
        [GeneratedRegex(@"\s(?<X>-?\d+),(?<Y>-?\d+),(?<M>[0-9a-fA-F]+)")]
        private static partial Regex SpaceTileRegex();
    }
}
