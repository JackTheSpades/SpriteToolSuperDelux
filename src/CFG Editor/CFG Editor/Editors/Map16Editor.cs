using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Drawing;
using System.Data;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;
using CFG.Map16;
using System.Drawing.Drawing2D;
using System.IO;
using System.Diagnostics;

namespace CFG
{
    public partial class Map16Editor : UserControl, INotifyPropertyChanged
    {
        public event SelectionChangedEventHandler SelectionChanged;
        public event HoverChangedEventHandler HoverChanged;
        public event PropertyChangedEventHandler PropertyChanged;
        public event EventHandler In8x8ModeChanged;

        public event EventHandler PageChanged;
        public int Page => vScrollBar.Value / 16;

        public event EventHandler PrintPageChanged;
        private bool _PrintPage = false;
        [DefaultValue(false)]
        public bool PrintPage
        {
            get { return _PrintPage; }
            set
            {
                _PrintPage = value;
                UpdateImage();
                PrintPageChanged?.Invoke(this, EventArgs.Empty);
                PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(nameof(PrintPage)));
            }
        }

        public event EventHandler ShowGridChanged;
        private bool _ShowGrid = false;
        [DefaultValue(false)]
        public bool ShowGrid
        {
            get { return _ShowGrid; }
            set
            {
                _ShowGrid = value;
                UpdateImage();
                ShowGridChanged?.Invoke(this, EventArgs.Empty);
                PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(nameof(ShowGrid)));
            }
        }

        private bool _In8x8Mode = false;
        [DefaultValue(false)]
        public bool In8x8Mode
        {
            get { return _In8x8Mode; }
            set
            {
                _In8x8Mode = value;
                PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(nameof(In8x8Mode)));
                In8x8ModeChanged?.Invoke(this, EventArgs.Empty);
                if (Map != null && x8Selected != -1 && y8Selected != -1)
                {
                    int yOff = vScrollBar.Value * 2;
                    Map.Select(x8Selected, y8Selected + yOff, In8x8Mode);
                    SelectionChanged?.Invoke(this, new TileChangedEventArgs(SelectedTile, XY_ToPoint(x8Selected, y8Selected)));
                }
            }
        }

        public int SelectedTile { get; private set; } = -1;

        public Map16Wrapper SelectedObject { get; private set; } = new Map16Wrapper(new Map16Empty(16));

        [DefaultValue(null)]
        public Map16Data Map { get; set; }
        
        
        public Map16Editor()
        {
            InitializeComponent();
            pcbMap16.SetBackgroundGradient(Color.Blue, Color.FromArgb(255, 0, 0, 96));
        }
        
        public void Initialize(byte[] data, Map16Resources resources)
        {
            Map = new Map16Data(data, resources);
            UpdateImage();

            Map.PropertyChanged += (s, e) =>
            {
                if (e.PropertyName == nameof(Map.Image))
                    UpdateImage();
                else if (e.PropertyName == nameof(Map.SelectedObject))
                {
                    SelectedObject.Load(Map.SelectedObject);
                    PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(nameof(SelectedObject)));
                }
            };

            timer1.Start();
        }

        private int ToInt(string str)
        {
            if (string.IsNullOrWhiteSpace(str))
                return 0;
            return Convert.ToInt32(str, 16);
        }

        public void StartAnimation() => timer1.Start();
        public void StopAnimation() => timer1.Stop();
        
        int last = 0;
        private void vScrollBar_ValueChanged(object sender, EventArgs e)
        {
            int inc = (last - vScrollBar.Value) * 2;
            last = vScrollBar.Value;

            if (y8Selected != -1)
                y8Selected += inc;
            if (y8LastHover != -1)
                y8LastHover += inc;

            UpdateImage();
            PageChanged?.Invoke(this, EventArgs.Empty);
        }



        int x8LastHover = -1;
        int y8LastHover = -1;

        int x8Selected = -1;
        int y8Selected = -1;

        private float dashOffset = 0;

        private int XY_ToTile(int x8, int y8)
        {
            int yOff = vScrollBar.Value * 2; //2 8x8 tiles scroll step
            return ((y8 + yOff) / 2) * 16 + (x8 / 2);
        }
        private Point XY_ToPoint(int x8, int y8)
        {
            int yOff = vScrollBar.Value * 2; //2 8x8 tiles scroll step
            return new Point(x8 / 2 * 16, (y8 + yOff) / 2 * 16);
        }


        private void pcbMap16_MouseClick(object sender, MouseEventArgs e)
        {
            byte[] previousData = null;
            if (e.Button == MouseButtons.Right)
            {
                previousData = SelectedObject.GetData();
            }


            x8Selected = x8LastHover;
            y8Selected = y8LastHover;

            int yOff = vScrollBar.Value * 2; //2 8x8 tiles scroll step
            SelectedTile = XY_ToTile(x8Selected, y8Selected);

            if(previousData != null && yOff >= 0x60)
            {
                Map.ChangeData(previousData, x8Selected, y8Selected + yOff);
            }

            Map.Select(x8Selected, y8Selected + yOff, In8x8Mode);
            SelectionChanged?.Invoke(this, new TileChangedEventArgs(SelectedTile, XY_ToPoint(x8Selected, y8Selected)));
        }

        private void pcbMap16_MouseMove(object sender, MouseEventArgs e)
        {
            x8LastHover = e.X / 8;
            y8LastHover = e.Y / 8;

            HoverChanged?.Invoke(this, new TileChangedEventArgs(
                XY_ToTile(x8LastHover, y8LastHover),
                XY_ToPoint(x8LastHover, y8LastHover)));
        }
        
        private void UpdateImage()
        {
            Diagnose.Start();
            Bitmap bg = pcbMap16.BackgroundImage as Bitmap;
            if (bg != null)
                bg.Dispose();

            bg = new Bitmap(pcbMap16.Width, pcbMap16.Height);

            using (Graphics g = Graphics.FromImage(bg))
            {
                Rectangle recGrad = new Rectangle(0, 0, bg.Width, bg.Height);
                using (LinearGradientBrush lgd = new LinearGradientBrush(recGrad, Color.Blue, Color.FromArgb(255, 0, 0, 96), 90))
                    g.FillRectangle(lgd, recGrad);

                Rectangle rec = new Rectangle(0, vScrollBar.Value * 16, 256, 256);
                g.DrawImage(Map.Image, 0, 0, rec, GraphicsUnit.Pixel);

                if (ShowGrid)
                {
                    using (Pen p = new Pen(Color.White))
                    {
                        for (int x = 15; x < bg.Width; x += 16)
                            g.DrawLine(p, x, 0, x, bg.Height - 1);
                        for (int y = 15; y < bg.Height; y += 16)
                            g.DrawLine(p, 0, y, bg.Width - 1, y);
                    }
                }
                if (PrintPage)
                {
                    int end = 16 - (vScrollBar.Value % 16);

                    Point[] points = new Point[]
                    {
                        new Point(0, 0),
                        new Point(0, end * 16),
                        new Point(bg.Width, end * 16),
                        new Point(bg.Width, 0),
                    };
                    g.DrawLines(new Pen(Color.FromArgb(128, Color.Blue), 6), points);
                }

            }

            pcbMap16.BackgroundImage = bg;
            Diagnose.Time();
        }

        private void timer1_Tick(object sender, EventArgs e)
        {
            pcbMap16.Image?.Dispose();
            Bitmap fg = new Bitmap(pcbMap16.Width, pcbMap16.Height);

            using (Graphics g = Graphics.FromImage(fg))
            {
                int size = In8x8Mode ? 8 : 16;
                int dev = In8x8Mode ? 1 : 2;
                int upperLimit = 32 - dev;
                if (x8Selected >= 0 && x8Selected <= upperLimit && y8Selected >= 0 && y8Selected <= upperLimit)
                {
                    Rectangle recSelected = new Rectangle(x8Selected / dev * size, y8Selected / dev * size, size, size);
                    g.DrawRectangle(new Pen(Color.White), recSelected);

                    using (Pen pDash = new Pen(Color.Blue))
                    {
                        pDash.DashStyle = DashStyle.Dash;
                        pDash.DashOffset = dashOffset;
                        dashOffset -= 0.5f;
                        g.DrawRectangle(pDash, recSelected);
                    }
                }
                if (x8LastHover != -1 && y8LastHover != -1)
                {
                    Rectangle recSelected = new Rectangle(x8LastHover / dev * size, y8LastHover / dev * size, size, size);
                    g.FillRectangle(new SolidBrush(Color.FromArgb(128, Color.Magenta)), recSelected);
                }
            }

            pcbMap16.Image = fg;

        }
        
        protected override bool ProcessDialogKey(Keys keyData)
        {
            int val = vScrollBar.Value;
            if (keyData == Keys.Down)
            {
                val += 16;
                val -= val % 16;
                vScrollBar.Value = Math.Min(val, 0x30);
                return true;
            }
            if (keyData == Keys.Up)
            {
                val -= 16;
                val -= val % 16;
                vScrollBar.Value = Math.Max(val, vScrollBar.Minimum);
                return true;
            }
            return base.ProcessDialogKey(keyData);
        }

        private void pcbMap16_MouseEnter(object sender, EventArgs e)
        {
            pcbMap16.Focus();
        }
    }

    public class Map16Empty : IMap16Object
    {
        public Map16Empty(int size)
        {
            Size = new Size(size, size);
        }

        public int BottomLeft
        {
            get { return 0xFFF; }
            set { }
        }
        public int BottomRight
        {
            get { return 0xFFF; }
            set { }
        }
        public int TopLeft
        {
            get { return 0xFFF; }
            set { }
        }
        public int TopRight
        {
            get { return 0xFFF; }
            set { }
        }

        public int Palette
        {
            get { return 8; }
            set { }
        }

        public int PixelX => 0;
        public int PixelY => 0;
        public Size Size { get; private set; }

        public Map16Resources Resources
        {
            get { return null; }
            set { }
        }

        public int TileNumber => 0;

#pragma warning disable CS0067
        public event PropertyChangedEventHandler PropertyChanged;
#pragma warning restore CS0067

        public void FlipX() { }
        public void FlipY() { }
        public Image GetImage() => new Bitmap(Size.Width, Size.Height);

        public byte[] GetData() => new byte[Size.Width * Size.Height / 32];
    }

    public class TileChangedEventArgs : EventArgs
    {
        public int Tile { get; set; }
        public Point Point { get; set; }

        public TileChangedEventArgs(int tile, Point point)
        {
            Tile = tile;
            Point = point;
        }
    }
    public delegate void SelectionChangedEventHandler(object sender, TileChangedEventArgs e);
    public delegate void HoverChangedEventHandler(object sender, TileChangedEventArgs e);
}
