using CFG.Map16;
using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace CFG.Editors
{
    public partial class PaletteEditorForm : Form
    {
        public int Zoom { get; set; } = 1;

        public readonly Map16Resources Resources;

        public event EventHandler PaletteLoaded;
        public event EventHandler<PaletteChangedEventArges> PaletteChanged;

        public PaletteEditorForm(Map16Resources resources)
        {
            InitializeComponent();
            pcbDisplay.Width = 16 * 16 * Zoom;
            pcbDisplay.Height = 8 * 16 * Zoom;

            Resources = resources;
            DrawPalette();
        }

        public void DrawPalette()
        {
            pcbDisplay.Image?.Dispose();
            if(Resources?.Palette == null)
            {
                pcbDisplay.Image = null;
                return;
            }

            Bitmap bm = new Bitmap(pcbDisplay.Width, pcbDisplay.Height);

            using(Graphics g = Graphics.FromImage(bm))
                for(int x = 0; x < 16; x++)
                    for(int y = 0; y < 8; y++)
                    {
                        Rectangle rec = new Rectangle(x * 16 * Zoom, y * 16 * Zoom, 16 * Zoom, 16 * Zoom);
                        g.FillRectangle(new SolidBrush(Resources.Palette[y][x]), rec);
                    }

            pcbDisplay.Image = bm;
        }

        private void pcbDisplay_MouseDown(object sender, MouseEventArgs e)
        {
            int row = e.Y / (16 * Zoom);
            int col = e.Y / (16 * Zoom);

            ColorDialog cd = new ColorDialog();
            cd.Color = Resources.Palette[row][col];
            cd.FullOpen = true;
            if (cd.ShowDialog() != DialogResult.OK)
                return;

            Resources.Palette[row][col] = cd.Color;
            DrawPalette();
            PaletteChanged?.Invoke(this, new PaletteChangedEventArges(row, col));
        }

        public static Color[][] ColorArrayFromBytes(byte[] data, int offset = 0)
        {
            Color[][] palette = new Color[8][];
            for (int row = 0; row < 8; row++)
            {
                Color[] palrow = new Color[16];
                for (int col = 0; col < 16; col++)
                {
                    palrow[col] = Color.FromArgb(
                        data[offset + 16 * 3 * row + 3 * col + 0],
                        data[offset + 16 * 3 * row + 3 * col + 1],
                        data[offset + 16 * 3 * row + 3 * col + 2]
                        );
                }
                palette[row] = palrow;
            }
            return palette;
        }

        private void btnLoad_Click(object sender, EventArgs e)
        {
            var ofd = new OpenFileDialog();
            ofd.Title = "Load Palette";
            ofd.Filter = "Palette File|*.pal";
            if (ofd.ShowDialog() != DialogResult.OK)
                return;

            Resources.Palette = ColorArrayFromBytes(File.ReadAllBytes(ofd.FileName), 8 * 16);
            DrawPalette();
            PaletteLoaded?.Invoke(this, new EventArgs());
        }
    }

    public class PaletteChangedEventArges : EventArgs
    {
        public int Column { get; set; }
        public int Row { get; set; }

        public PaletteChangedEventArges(int row, int col)
        {
            Row = row;
            Column = col;
        }
    }
}
