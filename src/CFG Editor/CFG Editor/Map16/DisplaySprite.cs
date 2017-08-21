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
	[DebuggerDisplay("X={X},Y={Y},Ex={ExtraBit}")]
	public class DisplaySprite : ICloneable, INotifyPropertyChanged
	{
        public static readonly DisplaySprite Empty = new DisplaySprite();
        
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
        public bool CustomBit
        {
            get { return _CustomBit; }
            set { SetPropertyValue(ref _CustomBit, value); }
        }

        public BindingList<Tile> Tiles { get; set; } = new BindingList<Tile>();

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

        public class CompareFull : IEqualityComparer<DisplaySprite>
		{
			public bool Equals(DisplaySprite x, DisplaySprite y)
			{
				if (Object.ReferenceEquals(x, y))
					return true;
				if (Object.ReferenceEquals(x, null))
					return false;
				if (Object.ReferenceEquals(y, null))
					return false;

				return x.X == y.X && x.Y == y.Y && x.CustomBit == y.CustomBit && x.ExtraBit == y.ExtraBit;
			}

			public int GetHashCode(DisplaySprite obj)
			{
				return (obj.X << 8) + (obj.Y << 12) + (obj.ExtraBit ? 0x100 : 0) + (obj.CustomBit ? 0x200 : 0);
			}
		}

		public class CompareExceptXY : IEqualityComparer<DisplaySprite>
		{
			public bool Equals(DisplaySprite x, DisplaySprite y)
			{
				if (Object.ReferenceEquals(x, y))
					return true;
				if (Object.ReferenceEquals(x, null))
					return false;
				if (Object.ReferenceEquals(y, null))
					return false;

				return x.CustomBit == y.CustomBit && x.ExtraBit == y.ExtraBit;
			}

			public int GetHashCode(DisplaySprite obj)
			{
				return (obj.ExtraBit ? 0x100 : 0) + (obj.CustomBit ? 0x200 : 0);
			}
		}

		public class CompareExceptBits : IEqualityComparer<DisplaySprite>
		{
			public bool Equals(DisplaySprite x, DisplaySprite y)
			{
				if (Object.ReferenceEquals(x, y))
					return true;
				if (Object.ReferenceEquals(x, null))
					return false;
				if (Object.ReferenceEquals(y, null))
					return false;

				return x.X == y.X && x.Y == y.Y;
			}

			public int GetHashCode(DisplaySprite obj)
			{
				return (obj.X << 8) + (obj.Y << 12);
			}
		}
        
        public event PropertyChangedEventHandler PropertyChanged;

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

			return sp.CustomBit == CustomBit && sp.ExtraBit == ExtraBit;
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
		public string GetDescLine()
		{
			return Y.ToString("X") + X.ToString("X") + ((ExtraBit ? 0x10 : 0) + (CustomBit ? 0x20 : 0)).ToString("X2") + " " + Description;
		}

		public object Clone()
		{
			DisplaySprite s = new DisplaySprite();
			s.CustomBit = this.CustomBit;
			s.Description = this.Description;
			s.ExtraBit = this.ExtraBit;
			s.Tiles = new BindingList<Tile>(this.Tiles);
			s.X = this.X;
			s.Y = this.Y;
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
	
	[DebuggerDisplay("{ToString()}")]
	public class Tile : ICloneable
	{
		public int XOffset { get; set; }
		public int YOffset { get; set; }
		public int Map16Number { get; set; }

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

		public bool ParseString(string str)
		{
			var match = Regex.Match(str, "(?<X>-?\\d+),(?<Y>-?\\d+),(?<M>[0-9a-fA-F]+)");
			if (!match.Success)
				return false;
			XOffset = Convert.ToInt32(match.Groups["X"].Value);
			YOffset = Convert.ToInt32(match.Groups["Y"].Value);
			Map16Number = Convert.ToInt32(match.Groups["M"].Value, 16);
			return true;
		}

		public virtual object Clone()
		{
			return new Tile(XOffset, YOffset, Map16Number);
		}
    }

	public static class Ext
	{
		public static bool IsNullOrEmpty<T>(this IEnumerable<T> col)
		{
			if ((object)col == null)
				return true;
			if (col.Count() == 0)
				return true;
			return false;
		}
	}
}
