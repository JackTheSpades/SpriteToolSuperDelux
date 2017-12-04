using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;
using CFG.Map16;


namespace CFG.Editors
{
    public partial class Tile8x8EditorForm : Form
    {
        public readonly Map16Resources Map16Resources;

        private int _Palette = 0;
        public int Palette
        {
            get { return _Palette; }
            set
            {
                if (value >= 8 || value < 0)
                    throw new ArgumentOutOfRangeException(nameof(Palette), "Palette must be inbetween 0 and 8");
                _Palette = value;
                toolStripStatusLabel2.Text = $"Palette: {_Palette}";
                UpdateImage();
            }
        }

        public int HoverTile { get; private set; }

        int SelectedTileX;
        int SelectedTileY;
        public int SelectedTile { get; private set; }

        public Tile8x8EditorForm(Map16Resources map16Resources)
        {
            InitializeComponent();
            Map16Resources = map16Resources;
            UpdateImage();

            vScrollBar1.Scroll += (_, __) => UpdateImage();
        }

        public void UpdateImage()
        {
            int tile = vScrollBar1.Value * 0x100;
            pcb.BackgroundImage?.Dispose();
            var img = new Bitmap(pcb.Width, pcb.Height);

            using (Graphics g = Graphics.FromImage(img))
            {
                Rectangle rec = new Rectangle(0, 0, img.Width, img.Height);
                using (var lgd = new System.Drawing.Drawing2D.LinearGradientBrush(rec, Color.FromArgb(0, 64, 0), Color.FromArgb(0, 255, 0), 90))
                    g.FillRectangle(lgd, rec);

                g.InterpolationMode = System.Drawing.Drawing2D.InterpolationMode.NearestNeighbor;
                var src = Map16Resources.Graphics.GetImage(tile, new Size(16, 16), Map16Resources.Palette[Palette]);
                g.DrawImage(src, rec);
            }
            pcb.BackgroundImage = img;
        }

        protected override bool ProcessDialogKey(Keys keyData)
        {
            if (keyData == Keys.PageUp && Palette < 7)
                Palette++;
            else if (keyData == Keys.PageDown && Palette > 0)
                Palette--;

            return base.ProcessDialogKey(keyData);
        }

        private void pcb_MouseMove(object sender, MouseEventArgs e)
        {
            int HoverX = e.X / 16;
            int HoverY = e.Y / 16;
            int off = vScrollBar1.Value * 0x100;

            HoverTile = off + (HoverY * 16) + HoverX;
            toolStripStatusLabel1.Text = $"Tile: {HoverTile.ToString("X3")}";
        }

        private void pcb_MouseClick(object sender, MouseEventArgs e)
        {
            SelectedTileX = e.X / 16;
            SelectedTileY = e.Y / 16;
            SelectedTile = HoverTile;
        }
    }
}
