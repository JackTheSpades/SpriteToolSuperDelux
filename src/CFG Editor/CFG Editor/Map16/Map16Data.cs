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
        /// <summary>
        /// A value between 0 and 7 for the color the map16 object uses or 8 in case multiple are used.
        /// Setting this property should set the palette of any and all sub objects so that future reading returns the same value.
        /// </summary>
        int Palette { get; set; }
        
        int TopLeft { get; set; }
        int TopRight { get; set; }
        int BottomLeft { get; set; }
        int BottomRight { get; set; }

        /// <summary>
        /// Flips the map16 object x wise
        /// </summary>
        void FlipX();
        /// <summary>
        /// Flips the map16 object y wise
        /// </summary>
        void FlipY();
        
        Map16Resources Resources { get; }
        
        int TileNumber { get; }
        int PixelX { get; }
        int PixelY { get; }
        Size Size { get; }

        /// <summary>
        /// Returns an image representation of the map16 object.
        /// </summary>
        /// <returns>The image</returns>
        Image GetImage();
        /// <summary>
        /// Returns the raw data of the map16 object.
        /// </summary>
        /// <returns>The raw data./returns>
        byte[] GetData();
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

        public byte[] GetData() => Data;


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
                Diagnose.Start();
                SubTiles.ForEach(t => t.Palette = value);
                Diagnose.Time();
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
        
        public bool IsEmpty()
        {
            return TopLeft == 0 && BottomLeft == 0 && TopRight == 0 && BottomRight == 0 && Palette == 0;
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
            SwapData(SubTiles[TopLeftIndex].Data, SubTiles[TopRightIndex].Data);
            SwapData(SubTiles[BottomLeftIndex].Data, SubTiles[BottomRightIndex].Data);
            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs("FlipX"));
        }

        public void FlipY()
        {
            SubTiles.ForEach(t => t.FlipY());
            SwapData(SubTiles[TopLeftIndex].Data, SubTiles[BottomLeftIndex].Data);
            SwapData(SubTiles[TopRightIndex].Data, SubTiles[BottomRightIndex].Data);
            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs("FlipY"));
        }

        public void ChangeData(byte[] data, bool top, bool left)
        {
            if (data.Length == 8)
            {
                SubTiles[0].Data[0] = data[0];
                SubTiles[0].Data[1] = data[1];
                SubTiles[1].Data[0] = data[2];
                SubTiles[1].Data[1] = data[3];
                SubTiles[2].Data[0] = data[4];
                SubTiles[2].Data[1] = data[5];
                SubTiles[3].Data[0] = data[6];
                SubTiles[3].Data[1] = data[7];
            }
            else if (data.Length == 2)
            {
                int index = (!top ? 1 : 0) + (!left ? 2 : 0);
                SubTiles[index].Data[0] = data[0];
                SubTiles[index].Data[1] = data[1];
            }
            else
                throw new ArgumentException("Length must be 8 or 2", nameof(data));
        }

        private void SwapData(byte[] bytes1, byte[] bytes2)
        {
            if (bytes1.Length != bytes2.Length)
                throw new ArgumentException("Arrays need same length");
            byte[] tmp = new byte[bytes1.Length];

            Array.Copy(bytes1, tmp, bytes1.Length);
            Array.Copy(bytes2, bytes1, bytes1.Length);
            Array.Copy(tmp, bytes2, bytes2.Length);
        }

	}

    public class Map16Collection : IMap16Object
    {
        public IEnumerable<IMap16Object> Objects { get; set; }
        public Size Size
        {
            get
            {
                throw new NotImplementedException();
            }
            set
            {

            }
        }

        protected Size SizeInBlocks => new Size(Size.Width / 8, Size.Height / 16);


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
        public int TileNumber => Objects.Min(o => o.TileNumber);

        public Map16Resources Resources => Objects.FirstOrDefault()?.Resources;



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

        public byte[] GetData()
        {
            throw new NotImplementedException();
        }
    }

    /// <summary>
    /// Fun Fact: You cannot use DataBinding on Interface properties as apperently they run GetType internally, so when you pass another type to the
    /// interface property it causes an exception. Hence, this wrapper class to represent <see cref="IMap16Object"/> types.
    /// It can <see cref="Load(IMap16Object)"/>  a map16 object and then represent it's values through itself. It will also forward the <see cref="PropertyChanged"/> event.
    /// </summary>
    public class Map16Wrapper : IMap16Object
    {
        private IMap16Object _Source = null;
        public IMap16Object Source
        {
            get { return _Source; }
            set
            {
                if (_Source != null)
                    Source.PropertyChanged -= Source_PropertyChanged;
                _Source = value;
                _Source.PropertyChanged += Source_PropertyChanged;
            }
        }

        public Map16Wrapper(IMap16Object source)
        {
            Source = source;
        }

        public void Load(IMap16Object source)
        {
            Source = source;
        }

        
        /// <summary>
        /// Method for the PropertyChanged Event of the <see cref="Source"/>. It just forwards the event without making any changes.
        /// Even the sender remains unchanged.
        /// </summary>
        /// <param name="sender"><see cref="Source"/> most likely.</param>
        /// <param name="e">Event args containing the name of the property that triggered the event.</param>
        private void Source_PropertyChanged(object sender, PropertyChangedEventArgs e) =>
            PropertyChanged?.Invoke(sender, e);

        /// <summary>
        /// Generic method to get the value of a property from the underlying <see cref="Source"/> object.
        /// Using the <see cref="CallerMemberNameAttribute"/> it automatically uses the name of the calling property.
        /// </summary>
        /// <typeparam name="T">The expected return type of the property.</typeparam>
        /// <param name="name">The name of the property</param>
        /// <returns>A casted content of the property</returns>
        protected T Get<T>([CallerMemberName]string name = "")
        {
            var prop = typeof(IMap16Object).GetProperty(name);
            return (T)prop.GetValue(Source);
        }
        /// <summary>
        /// Generic method to set the value of a property of the underlying <see cref="Source"/> object.
        /// Using the <see cref="CallerMemberNameAttribute"/> it automatically uses the name of the calling property.
        /// </summary>
        /// <typeparam name="T">The expected return type of the property.</typeparam>
        /// <param name="val">The value to write ot the property.</param>
        /// <param name="name">The name of the property</param>
        protected void Set<T>(T val,[CallerMemberName]string name = "")
        {
            var prop = typeof(IMap16Object).GetProperty(name);
            prop.SetValue(Source, val);
        }
        protected T Invoke<T>(object[] args, [CallerMemberName]string name = "")
        {
            Type[] types = args?.Select(a => a.GetType())?.ToArray() ?? Type.EmptyTypes;
            var meth = typeof(IMap16Object).GetMethod(name, types);
            return (T)meth.Invoke(Source, args);
        }
        protected void Invoke(object[] args, [CallerMemberName]string name = "")
        {
            Type[] types = args?.Select(a => a.GetType())?.ToArray() ?? Type.EmptyTypes;
            var meth = typeof(IMap16Object).GetMethod(name, types);
            meth.Invoke(Source, args);
        }

        #region IMap16Object Data

        public int BottomLeft
        {
            get { return Get<int>(); }
            set { Set(value); }
        }
        public int BottomRight
        {
            get { return Get<int>(); }
            set { Set(value); }
        }
        public int Palette
        {
            get { return Get<int>(); }
            set { Set(value); }
        }

        public int PixelX => Get<int>();
        public int PixelY => Get<int>();
        public Map16Resources Resources => Get<Map16Resources>();
        public Size Size => Get<Size>();
        public int TileNumber => Get<int>();

        public int TopLeft
        {
            get { return Get<int>(); }
            set { Set(value); }
        }

        public int TopRight
        {
            get { return Get<int>(); }
            set { Set(value); }
        }

        public event PropertyChangedEventHandler PropertyChanged;

        public void FlipX() => Invoke(null);
        public void FlipY() => Invoke(null);
        public byte[] GetData() => Invoke<byte[]>(null);
        public Image GetImage() => Invoke<Image>(null);
        #endregion
    }

    public class Map16Data : INotifyPropertyChanged
    {
        public event PropertyChangedEventHandler PropertyChanged;

        public readonly Bitmap Image;
        public readonly Map16Resources Resources;
        
        public IMap16Object SelectedObject { get; set; }


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

        /// <summary>
        /// Gets all 16x16 blocks beyond block 0x300 until only empty ones are left.
        /// </summary>
        /// <returns></returns>
        public byte[] GetNotEmptyData()
        {
            List<byte> data = new List<byte>();
            int size = 0x3FF;
            while (Map[size].IsEmpty() && size >= 0x300)
                size--;
            

            for(int index = 0x300; index <= size; index++)
                data.AddRange(Map[index].GetData());
            return data.ToArray();
        }

        public void ChangeData(byte[] data, int x8, int y8)
        {
            int x16 = x8 / 2;
            int y16 = y8 / 2;
            Map16Tile16x16 t16 = Map[x16 + y16 * 16];
            t16.ChangeData(data, y8 % 2 == 0, x8 % 2 == 0);
            RedrawObject(t16);
            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(nameof(Image)));
        }

        public void ChangeData(byte[] data, int block_start)
        {
            //subarray because of stupid internal logic regarding the offset in the byte array
            //being used to calculate the tile number.
            var subData = new byte[block_start * 8 + data.Length];
            Array.Copy(data, 0, subData, block_start * 8, data.Length);

            for (int i = 0; i < data.Length && block_start + (i / 8) < 0x400; i += 8)
            {
                var sub = new Map16Tile16x16(subData, block_start * 8 + i)
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
            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(nameof(SelectedObject)));
        }

        private void SelectedObject_PropertyChanged(object sender, PropertyChangedEventArgs e)
        {
            Diagnose.Start();
            IMap16Object obj = (IMap16Object)sender;
            RedrawObject(obj);
            Diagnose.Time();
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
        
    }

}
