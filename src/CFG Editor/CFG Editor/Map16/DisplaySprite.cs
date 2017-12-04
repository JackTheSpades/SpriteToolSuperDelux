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

namespace CFG.Map16
{
	[DebuggerDisplay("X={X},Y={Y},Ex={ExtraBit} Tiles: {Tiles.Count}")]
	public class DisplaySprite : ICloneable, INotifyPropertyChanged
	{
        /// <summary>
        /// The default sprite with only a description and one tile (a pink X)
        /// </summary>
        public static DisplaySprite Default => new DisplaySprite()
        {
            Description = "Undefined Sprite",
            Tiles = new BindingList<Tile>()
            {
                new Tile(0, 0, 0),
            }
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

        private int _X = 0;
		public int X
        {
            get { return _X; }
            set { SetPropertyValue(ref _X, value); }
        }
        private int _Y = 0;
        public int Y
        {
            get { return _Y; }
            set { SetPropertyValue(ref _Y, value); }
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
            Tiles = new BindingList<Tile>();
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
			return ex + ":" + Y.ToString("X") + X.ToString("X");
		}
		public override bool Equals(object obj)
		{
			if (object.ReferenceEquals(this, obj))
				return true;
			if (object.ReferenceEquals(this, null))
				return false;

			DisplaySprite sp = obj as DisplaySprite;
			if (object.ReferenceEquals(sp, null))
				return false;

            return sp.CustomBit == CustomBit && sp.ExtraBit == ExtraBit
                && sp.Description == Description && sp.DisplayText == DisplayText && sp.UseText == UseText
                && sp.Tiles.SequenceEqual(Tiles);
		}
		public override int GetHashCode()
		{
			return (ExtraBit ? 0x100 : 0) + (CustomBit ? 0x200 : 0) + (X ^ Y);
		}

		#endregion
		#region Operators

		public static bool operator ==(DisplaySprite sp1, DisplaySprite sp2)
		{
			if (object.ReferenceEquals(sp1, sp2))
				return true;
			if (object.ReferenceEquals(sp1, null))
				return false;
			if (object.ReferenceEquals(sp2, null))
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
			if(UseText)
				return Y.ToString("X") + X.ToString("X") + (2 + (ExtraBit ? 0x10 : 0) + (CustomBit ? 0x20 : 0)).ToString("X2") + " 0,0,*" + DisplayText + "*";
			return Y.ToString("X") + X.ToString("X") + (2 + (ExtraBit ? 0x10 : 0) + (CustomBit ? 0x20 : 0)).ToString("X2") + " " + String.Join(" ", Tiles);
		}

		public object Clone()
		{
			DisplaySprite s = new DisplaySprite();
			s.CustomBit = this.CustomBit;
			s.Description = this.Description;
			s.ExtraBit = this.ExtraBit;
			s.Tiles = new BindingList<Tile>();
            foreach (Tile t in Tiles)
                s.Tiles.Add((Tile)t.Clone());
			s.X = this.X;
			s.Y = this.Y;
            s.DisplayText = this.DisplayText;
            s.UseText = this.UseText;
			return s;
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

    public class DisplaySpriteUniqueComparer : IEqualityComparer<DisplaySprite>
    {
        public bool Equals(DisplaySprite x, DisplaySprite y)
        {
            return x.X == y.X && x.Y == y.Y && x.ExtraBit == y.ExtraBit;
        }

        public int GetHashCode(DisplaySprite obj)
        {
            return obj.X ^ obj.Y * (obj.ExtraBit ? -1 : 1);
        }
    }

    [DebuggerDisplay("{ToString()}")]
	public class Tile : ICloneable
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
			if ((object)this == null)
				return false;

			Tile t = obj as Tile;
			if ((object)t == null)
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
			var match = Regex.Match(str, regex);
            if (!match.Success)
                return null;

			int XOffset = Convert.ToInt32(match.Groups["X"].Value);
			int YOffset = Convert.ToInt32(match.Groups["Y"].Value);
			int Map16Number = Convert.ToInt32(match.Groups["M"].Value, 16);
            return new Tile(XOffset, YOffset, Map16Number);
		}

        public static IEnumerable<Tile> GetTiles(string str)
        {
            var matches = Regex.Matches(str, "\\s" + regex);
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
    }
}
