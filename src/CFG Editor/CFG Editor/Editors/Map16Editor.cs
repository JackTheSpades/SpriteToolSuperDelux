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

namespace CFG
{
    public partial class Map16Editor : UserControl, INotifyPropertyChanged
    {
        public event SelectionChangedEventHandler SelectionChanged;

        public int Page => vScrollBar.Value / 16;

        [DefaultValue(false)]
        public bool PrintPage { get; set; } = true;
        [DefaultValue(false)]
        public bool In8x8Mode { get; set; }

        public int SelectedTile { get; private set; }

        public IMap16Object SelectedObject { get { return Map?.SelectedObject ?? new Map16Empty(In8x8Mode ? 8 : 16); } }

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
        }



        int x8LastHover = -1;
        int y8LastHover = -1;

        int x8Selected = -1;
        int y8Selected = -1;

        private float dashOffset = 0;

        public event PropertyChangedEventHandler PropertyChanged;

        private void pcbMap16_MouseClick(object sender, MouseEventArgs e)
        {
            x8Selected = x8LastHover;
            y8Selected = y8LastHover;

            int yOff = vScrollBar.Value * 2; //2 8x8 tiles scroll step
            Map.Select(x8Selected, y8Selected + yOff, In8x8Mode);

            SelectedTile = ((y8Selected + yOff) / 2) * 16 + (x8Selected / 2);

            SelectionChanged?.Invoke(this, new SelectionChangedEventArgs()
            {
                Tile = SelectedTile,
                Point = new Point(x8Selected / 2 * 16, (y8Selected + yOff) / 2 * 16),
            });
            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(nameof(SelectedObject)));
        }

        private void pcbMap16_MouseMove(object sender, MouseEventArgs e)
        {
            x8LastHover = e.X / 8;
            y8LastHover = e.Y / 8;
        }
        
        private void UpdateImage()
        {
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

                if(PrintPage)
                {
                    int end = 16 - (vScrollBar.Value % 16);

                    Point[] points = new Point[]
                    {
                        new Point(0, 0),
                        new Point(0, end * 16),
                        new Point(bg.Width, end * 16),
                        new Point(bg.Width, 0),
                    };
                    g.DrawLines(new Pen(Color.FromArgb(128, Color.Blue), 5), points);
                }
            }

            pcbMap16.BackgroundImage = bg;
        }

        private void timer1_Tick(object sender, EventArgs e)
        {
            Bitmap fg = pcbMap16.Image as Bitmap;
            if (fg != null)
                fg.Dispose();

            fg = new Bitmap(pcbMap16.Width, pcbMap16.Height);

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
        
        public event PropertyChangedEventHandler PropertyChanged;

        public void FlipX() { }
        public void FlipY() { }
        public Image GetImage() => new Bitmap(Size.Width, Size.Height);
    }

    public class SelectionChangedEventArgs : EventArgs
    {
        public int Tile { get; set; }
        public Point Point { get; set; }
    }
    public delegate void SelectionChangedEventHandler(object sender, SelectionChangedEventArgs e);
}
