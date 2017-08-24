using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Drawing;
using System.Diagnostics;
using System.ComponentModel;
using System.Runtime.CompilerServices;

namespace CFG.Map16
{
    public class Map16Resources
    {
        public SnesGraphics Graphics { get; set; }
        public Color[][] Palette { get; set; }
    }

    public interface IMap16Object : INotifyPropertyChanged
    {
        int Palette { get; set; }
        
        int TopLeft { get; set; }
        int TopRight { get; set; }
        int BottomLeft { get; set; }
        int BottomRight { get; set; }

        void FlipX();
        void FlipY();
        
        Map16Resources Resources { get; }
        
        int TileNumber { get; }
        int PixelX { get; }
        int PixelY { get; }
        Size Size { get; }
        Image GetImage();
    }

	[DebuggerDisplay("Tile={GFXNumber.ToString(\"X2\")}")]
	public class Map16Tile8x8 : IMap16Object
	{
        public const int Invalid = 0xFFF;

        public readonly byte[] Data = new byte[2];

        internal Map16Tile16x16 Parent;

        public event PropertyChangedEventHandler PropertyChanged;

        public int TileNumber { get; private set; }
        public int PixelX { get; private set; }
        public int PixelY { get; private set; }
        public Size Size => new Size(8, 8);

        public int GFXNumber
        {
            //little endian
            get { return Data[0] + ((Data[1] & 0x03) << 8); }
            set
            {
                if (value < 0 || value > 0x3FF)
                    throw new ArgumentOutOfRangeException("Tile must be inbetween 0 and 0x3FF");
                Data[0] = (byte)value;
                Data[1] = Data[1].SetBits((value >> 8) & 0x03, 2, 0);
                PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(nameof(GFXNumber)));
            }
        }
		public bool XFlip
        {
            get { return Data[1].GetBit(6); }
            set { Data[1] = Data[1].SetBit(6, value); PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(nameof(XFlip))); }
        }
        public bool YFlip
        {
            get { return Data[1].GetBit(7); }
            set { Data[1] = Data[1].SetBit(7, value); PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(nameof(YFlip))); }
        }
        
		public bool Priority
        {
            get { return Data[1].GetBit(5); }
            set { Data[1] = Data[1].SetBit(5, value); }
        }
        
        public int Palette 
		{
			get { return Data[1].GetBits(3, 2); }
			set
			{
				if (value < 0 || value > 7)
					throw new ArgumentOutOfRangeException("Palette must be inbetween 0 and 7");
                Data[1] = Data[1].SetBits(value, 3, 2);
                PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(nameof(Palette)));
            }
		}
        
        public Map16Resources Resources { get; set; }

        public int TopLeft
        {
            get { return GFXNumber; }
            set
            {
                if (GFXNumber != value)
                {
                    GFXNumber = value;
                    PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(nameof(TopLeft)));
                }
            }
        }
        public int TopRight
        {
            get { return Invalid; }
            set { }
        }
        public int BottomLeft
        {
            get { return Invalid; }
            set { }
        }
        public int BottomRight
        {
            get { return Invalid; }
            set { }
        }

        public Map16Tile8x8(byte[] data, int offset)
		{
            Data[0] = data[offset + 0];
            Data[1] = data[offset + 1];

            TileNumber = offset / 8;

            int corners = (offset % 8) / 2;
            
            PixelX = (TileNumber % 16) * 16;
            PixelY = (TileNumber / 16) * 16;

            if ((corners & 0x01) != 0)
                PixelY += 8;
            if ((corners & 0x02) != 0)
                PixelX += 8;
        }

		public Image GetImage()
		{
			Image im = Resources.Graphics.GetImage(GFXNumber, new Size(1, 1), Resources.Palette[Palette]);
			if(XFlip && YFlip)
				im.RotateFlip(RotateFlipType.RotateNoneFlipXY);
			else if(XFlip)
				im.RotateFlip(RotateFlipType.RotateNoneFlipX);
			else if(YFlip)
				im.RotateFlip(RotateFlipType.RotateNoneFlipY);
			return im;
		}


		/// <summary>
		/// Checks if two Map16Tile8x8 objects contain the same data
		/// </summary>
		/// <param name="obj">The object to compare</param>
		/// <returns><c>True</c> if both objects contain the same data</returns>
		public override bool Equals(object obj)
		{
			if (object.ReferenceEquals(obj, this))
				return true;
			if ((object)this == null)
				return false;

			Map16Tile8x8 m = obj as Map16Tile8x8;
			if ((object)m == null)
				return false;

            return Data[0] == m.Data[0] && Data[1] == m.Data[1];
		}

		public override int GetHashCode()
		{
            return (Data[1] << 8) + Data[0];
		}

        public void FlipX()
        {
            Data[1] ^= 0x40;
            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(nameof(FlipX)));
        }
        public void FlipY()
        {
            Data[1] ^= 0x80;
            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(nameof(FlipY)));
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

        public static bool operator ==(Map16Tile8x8 m1, Map16Tile8x8 m2)
		{
			return m1.Equals(m2);
		}
		public static bool operator !=(Map16Tile8x8 m1, Map16Tile8x8 m2)
		{
			return !m1.Equals(m2);
		}
	}

	public class Map16Tile16x16 : IMap16Object
	{
        public int TileNumber { get; private set; }
		public int PixelX { get { return (TileNumber % 16) * 16; } }
		public int PixelY { get { return (TileNumber / 16) * 16; } }
        public Size Size => new Size(16, 16);

        public const int TopLeftIndex = 0;
        public const int BottomLeftIndex = 1;
        public const int TopRightIndex = 2;
        public const int BottomRightIndex = 3;

        internal Map16Tile8x8[] SubTiles = new Map16Tile8x8[4];
        
        public event PropertyChangedEventHandler PropertyChanged;

        public int Palette
        {
            get
            {
                return SubTiles.Aggregate(SubTiles[0].Palette, (curr, t) =>
                {
                    if (curr != t.Palette)
                        return 8;
                    return t.Palette;
                });
            }
            set
            {
                SubTiles.ForEach(t => t.Palette = value);
                PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(nameof(Palette)));
            }
        }

        public Map16Resources Resources
        {
            get { return SubTiles[0].Resources; }
            set { SubTiles.ForEach(t => t.Resources = value); }
        }

        public int TopLeft
        {
            get { return SubTiles[TopLeftIndex].GFXNumber; }
            set
            {
                SubTiles[TopLeftIndex].GFXNumber = value;
                PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(nameof(TopLeft)));
            }
        }

        public int TopRight
        {
            get { return SubTiles[TopRightIndex].GFXNumber; }
            set
            {
                SubTiles[TopRightIndex].GFXNumber = value;
                PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(nameof(TopRight)));
            }
        }

        public int BottomLeft
        {
            get { return SubTiles[BottomLeftIndex].GFXNumber; }
            set
            {
                SubTiles[BottomLeftIndex].GFXNumber = value;
                PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(nameof(BottomLeft)));
            }
        }

        public int BottomRight
        {
            get { return SubTiles[BottomRightIndex].GFXNumber; }
            set
            {
                SubTiles[BottomRightIndex].GFXNumber = value;
                PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(nameof(BottomRight)));
            }
        }

        public Map16Tile16x16(byte[] data, int offset)
        {
            TileNumber = offset / 8;
            SubTiles[TopLeftIndex] = new Map16Tile8x8(data, offset + 0);
            SubTiles[BottomLeftIndex] = new Map16Tile8x8(data, offset + 2);
            SubTiles[TopRightIndex] = new Map16Tile8x8(data, offset + 4);
            SubTiles[BottomRightIndex] = new Map16Tile8x8(data, offset + 6);

            SubTiles.ForEach(t => t.Parent = this);
		}

		public Image GetImage()
		{
			Bitmap bm = new Bitmap(16, 16);
			using(Graphics g = System.Drawing.Graphics.FromImage(bm))
			{
                foreach (Map16Tile8x8 sub in SubTiles)
                    g.DrawImage(sub.GetImage(), new Point(sub.PixelX % 16, sub.PixelY % 16));
			}
			return bm;
		}

        public byte[] GetData()
        {
            List<byte> b = new List<byte>();
            foreach (var m in SubTiles)
                b.AddRange(m.Data);
            return b.ToArray();
        }

		public override bool Equals(object obj)
		{
			if (object.ReferenceEquals(obj, this))
				return true;

			Map16Tile16x16 m = obj as Map16Tile16x16;
			if ((object)m == null)
				return false;

            for (int i = 0; i < 4; i++)
                if (m.SubTiles[i] != SubTiles[i])
                    return false;
            return true;
		}

		public override int GetHashCode()
		{
            return SubTiles.Aggregate(0, (curr, t) => curr ^ t.GetHashCode());
        }
        public static bool operator ==(Map16Tile16x16 m1, Map16Tile16x16 m2)
        {
            return m1.Equals(m2);
        }
        public static bool operator !=(Map16Tile16x16 m1, Map16Tile16x16 m2)
        {
            return !m1.Equals(m2);
        }

        public void FlipX()
        {
            SubTiles.ForEach(t => t.FlipX());
            int tmp = TopLeft;
            TopLeft = TopRight;
            TopRight = tmp;

            tmp = BottomLeft;
            BottomLeft = BottomRight;
            BottomRight = tmp;
        }

        public void FlipY()
        {
            SubTiles.ForEach(t => t.FlipY());
            int tmp = TopLeft;
            TopLeft = BottomLeft;
            BottomLeft = tmp;

            tmp = TopRight;
            TopRight = BottomRight;
            BottomRight = tmp;
        }

	}

    public class Map16Collection : IMap16Object
    {
        public readonly IEnumerable<IMap16Object> Objects;

        public int BottomLeft
        {
            get { return Objects.GetAll(o => o.BottomLeft, 0xFFF); }
            set { Objects.ForEach(o => o.BottomLeft = value); }
        }
        public int BottomRight
        {
            get { return Objects.GetAll(o => o.BottomRight, 0xFFF); }
            set { Objects.ForEach(o => o.BottomRight = value); }
        }

        public int Palette
        {
            get { return Objects.GetAll(o => o.Palette, 0xFFF); }
            set { Objects.ForEach(o => o.Palette = value); }
        }

        public int PixelX => Objects.Min(o => o.PixelX);
        public int PixelY => Objects.Min(o => o.PixelY);

        public Map16Resources Resources
        {
            get
            {
                throw new NotImplementedException();
            }
        }

        public Size Size
        {
            get
            {
                throw new NotImplementedException();
            }
        }

        public int TileNumber
        {
            get
            {
                throw new NotImplementedException();
            }
        }

        public int TopLeft
        {
            get { return Objects.GetAll(o => o.TopLeft, 0xFFF); }
            set { Objects.ForEach(o => o.TopLeft = value); }
        }

        public int TopRight
        {
            get { return Objects.GetAll(o => o.TopRight, 0xFFF); }
            set { Objects.ForEach(o => o.TopRight = value); }
        }

        public event PropertyChangedEventHandler PropertyChanged;

        public void FlipX()
        {
            throw new NotImplementedException();
        }

        public void FlipY()
        {
            throw new NotImplementedException();
        }

        public Image GetImage()
        {
            throw new NotImplementedException();
        }
    }

    public class Map16Data : INotifyPropertyChanged
    {
        public event PropertyChangedEventHandler PropertyChanged;

        public readonly Bitmap Image;
        public readonly Map16Resources Resources;

        private IMap16Object _SelectedObject = null;
        public IMap16Object SelectedObject
        {
            get { return _SelectedObject; }
            set { SetPropertyValue(ref _SelectedObject, value); }
        }


        Map16Tile16x16[] Map { get; set; }
        public Map16Data(byte[] data, Map16Resources resources)
		{
            Resources = resources;
            Map = new Map16Tile16x16[data.Length / 8];
            for (int i = 0; i < data.Length; i += 8)
            {
                Map[i / 8] = new Map16Tile16x16(data, i)
                {
                    Resources = resources,
                };
            }

            resources.Graphics.TileChanged += (s, e) =>
            {
                var updateMap = Map.Where(m => e.Tiles.Contains(m.TopLeft) || e.Tiles.Contains(m.TopRight) || e.Tiles.Contains(m.BottomLeft) || e.Tiles.Contains(m.BottomRight));
                foreach(var maptile in updateMap)
                    RedrawObject(maptile);
                PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(nameof(Image)));
            };

            int height = (int)Math.Ceiling((data.Length / 8.0m) / 16.0m);
            
            Image = new Bitmap(256, 16 * 320);            
            using (Graphics g = Graphics.FromImage(Image))
            {
                foreach (Map16Tile16x16 m in Map)
                {
                    Image im = m.GetImage();
                    g.DrawImage(im, new Point(m.PixelX, m.PixelY));
                    im.Dispose();
                }
            }

            SelectedObject = Map[0];
        }

        public void ChangeData(byte[] data, int block_start)
        {
            for (int i = 0; i < data.Length; i += 8)
            {
                var sub = new Map16Tile16x16(data, i)
                {
                    Resources = Resources,
                };
                RedrawObject(sub);
                Map[block_start + (i / 8)] = sub;
            }
            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(nameof(Image)));
        }


        /// <summary>
        /// Invoke a redraw of all tiles that are affected by a palette change.
        /// </summary>
        /// <param name="row"></param>
        public void PaletteChanged(int row)
        {
            var subtiles = Map.SelectMany(m => m.SubTiles)
                .Where(s => s.Palette == row);

            foreach (var t in subtiles)
                RedrawObject(t);

            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(nameof(Image)));
        }

        /// <summary>
        /// 
        /// </summary>
        /// <param name="x8">Horizontal value on an 8x8 grid</param>
        /// <param name="y8">Vertical value on an 8x8 grid</param>
        public void Select(int x8, int y8, bool in8x8Mode)
        {
            int index = (y8 / 2) * 16 + (x8 / 2); //32 8x8 tiles per horizontal row
            Map16Tile16x16 tile16 = Map[index];
            SelectedObject.PropertyChanged -= SelectedObject_PropertyChanged;
            
            if (!in8x8Mode)
                SelectedObject = tile16;
            else
            {
                int xPlus = (x8 % 2) * 2;   // +2 if we're on the right side
                int yPlus = y8 % 2;         // +1 if we're on the bottom

                Map16Tile8x8 tile8 = tile16.SubTiles[xPlus + yPlus];
                SelectedObject = tile8;
            }

            SelectedObject.PropertyChanged += SelectedObject_PropertyChanged;
        }

        private void SelectedObject_PropertyChanged(object sender, PropertyChangedEventArgs e)
        {
            IMap16Object obj = (IMap16Object)sender;
            RedrawObject(obj);
            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(nameof(Image)));
        }

        /// <summary>
        /// Redraw an object to the image. This does not invoke the image changed PropertChanged event.
        /// </summary>
        /// <param name="obj"></param>
        public void RedrawObject(IMap16Object obj)
        {
            //redraw.
            Rectangle rec = new Rectangle(obj.PixelX, obj.PixelY, obj.Size.Width, obj.Size.Height);
            using (Graphics g = Graphics.FromImage(Image))
            {
                g.SetClip(rec);
                g.Clear(Color.Transparent);
                g.SetClip(new Rectangle(Point.Empty, Image.Size));
                g.DrawImage(obj.GetImage(), rec);
            }
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
