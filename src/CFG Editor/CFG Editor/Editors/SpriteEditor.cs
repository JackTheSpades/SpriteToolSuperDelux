﻿using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Drawing;
using System.Data;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;
using System.Collections;
using System.Drawing.Drawing2D;

using System.Diagnostics;

namespace CFG.Map16
{
    public partial class SpriteEditor : UserControl
    {
        private Point SelectedPoint;
        private Map16Data Map16Data;
        private CFG_Editor parent_editor;

        public void SetParentEditor(CFG_Editor editor)
        {
            parent_editor = editor;
        }

        [DefaultValue(null)]
        public Map16Editor Map16Editor
        {
            set
            {
                Map16Data = value.Map;
                Map16Data.PropertyChanged += (s, e) =>
                {
                    if (e.PropertyName == nameof(Map16Data.Image))
                        UpdateSpriteScreen(pcbSprite.Size);
                };

                value.SelectionChanged += (s, e) =>
                {
                    SelectedPoint = e.Point;
                };
            }
        }

        [DefaultValue(false)]
        public bool UseText
        {
            get { return Sprite?.UseText ?? false; }
            set { if (Sprite != null) Sprite.UseText = value; }
        }

        private DisplaySprite _Sprite;
        [DefaultValue(null)]
        public DisplaySprite Sprite
        {
            get { return _Sprite; }
            set
            {
                if (_Sprite != null)
                {
                    _Sprite.Tiles.ListChanged -= Tiles_ListChanged;
                    _Sprite.PropertyChanged -= Sprite_PropertyChanged;
                }
                _Sprite = value;
                if (_Sprite != null)
                {
                    _Sprite.Tiles.ListChanged += Tiles_ListChanged;
                    _Sprite.PropertyChanged += Sprite_PropertyChanged;
                    UpdateUseText();
                }
                Redraw();
                SpriteChanged?.Invoke(this, EventArgs.Empty);
            }            
        }

        public event EventHandler SpriteChanged;

        private int _GridSize = 16;
        [DefaultValue(16)]
        public int GridSize
        {
            get { return _GridSize; }
            set
            {
                if ((value & (value - 1)) != 0)
                    throw new ArgumentException("Value must be a power of 2", nameof(GridSize));
                if (_GridSize != value)
                {
                    _GridSize = value;
                    UpdateGrid(_GridSize);
                }
            }
        }

        public SpriteEditor()
        {
            InitializeComponent();
            pcbSprite.Width = TileSize.Width * 11;
            pcbSprite.Height = TileSize.Height * 11;
            pcbSprite.Left = (Width - pcbSprite.Width) / 2;
            pcbSprite.Top = (Height - pcbSprite.Height) / 2;
            pcbSprite.MouseWheel += PcbSprite_MouseWheel;
            UpdateGrid(16);

            rtbDisplayText.Bind(this, c => c.Text, s => s.Sprite.DisplayText);
        }

        public void Redraw()
        {
            UpdateGrid(GridSize);
            UpdateSpriteScreen(pcbSprite.Size);
        }

        public void UpdateUseText()
        {
            if (Sprite.UseText)
            {
                rtbDisplayText.Visible = true;
                pcbSprite.Height = TileSize.Height * (11 - 4);
            }
            else
            {
                rtbDisplayText.Visible = false;
                pcbSprite.Height = TileSize.Height * 11;
            }
        }

        public void UpdateGrid(int size)
        {
            pcbSprite.BackgroundImage?.Dispose();

            Bitmap bm = new(pcbSprite.Width, pcbSprite.Height);

            //SpriteBM = new Bitmap(pcbSprite.Width, pcbSprite.Height);
            using (Graphics g = Graphics.FromImage(bm))
            {
                Rectangle rec = new(0, 0, bm.Width, bm.Height);
                using (LinearGradientBrush lgd = new(rec, Color.Red, Color.FromArgb(255, 96, 0, 0), 90))
                    g.FillRectangle(lgd, rec);

                if (size > 4)
                {
                    int realSize = size == 16 ? TileSize.Width : TileSize.HalfWidth;
                    Pen dashed = new(Color.White)
                    {
                        DashStyle = DashStyle.Dot
                    };

                    for (int x = 0; x < pcbSprite.Width; x += realSize)
                        g.DrawLine(dashed, x, 0, x, pcbSprite.Height - 1);
                    for (int y = 0; y < pcbSprite.Height; y += realSize)
                        g.DrawLine(dashed, 0, y, pcbSprite.Width - 1, y);

                    dashed.Color = Color.Blue;
                    dashed.DashStyle = DashStyle.Solid;
                    g.DrawRectangle(dashed, new Rectangle(pcbSprite.Width / 2 - TileSize.HalfWidth, pcbSprite.Height / 2 - TileSize.HalfHeight, TileSize.Width, TileSize.Height));
                }
            }
            pcbSprite.BackgroundImage = bm;
        }

        public void UpdateSpriteScreen(Size imageSize)
        {
            pcbSprite.Image?.Dispose();
            Bitmap Image = new(imageSize.Width, imageSize.Height);

            using (Graphics g = Graphics.FromImage(Image))
            {
                if (Sprite != null)
                {
                    if (UseText)
                    {
                        Bitmap bm = ConvertStringToImage(Sprite.DisplayText);
                        if (bm != null)
                        {
                            int x = (Image.Width / 2) - (bm.Width / 2);
                            int y = (Image.Height / 2) - (bm.Height / 2);
                            g.DrawImage(bm, x, y);
                            bm.Dispose();
                        }
                    }
                    else
                    {
                        foreach (Tile t in Sprite.Tiles)
                        {
                            int xDraw = (imageSize.Width / 2 - TileSize.HalfWidth) + t.XOffset;
                            int yDraw = (imageSize.Height / 2 - TileSize.HalfHeight) + t.YOffset;

                            int xGet = t.Map16Number % 16 * TileSize.Width;
                            int yGet = (t.Map16Number / 16) * TileSize.Height;

                            Image img = Map16Data.Image.Clone(new Rectangle(xGet, yGet, TileSize.Width, TileSize.Height), System.Drawing.Imaging.PixelFormat.Format32bppArgb);
                            System.Drawing.Imaging.ImageAttributes attr = new();
                            if (t.Selected)
                                attr.SetColorMatrix(new System.Drawing.Imaging.ColorMatrix(
                            [
                            [-1f, 0, 0, 0, 0],
                            [0, -1f, 0, 0, 0],
                            [0, 0, -1f, 0, 0],
                            [0, 0, 0, +1f, 0],
                            [1, 1, 1, 0, +1f],
                            ]));

                            g.DrawImage(img, new Rectangle(xDraw, yDraw, TileSize.Width, TileSize.Height), 0, 0, TileSize.Width, TileSize.Height, GraphicsUnit.Pixel, attr);
                        }
                    }
                }
            }

            pcbSprite.Image = Image;
        }

        private static Bitmap ConvertStringToImage(string text)
        {
            string[] lines = text.Replace("\\n", "\n").Split('\n');
            if (lines.All(s => s.Length == 0))
                return null;
            int max = lines.Max(s => s.Length);
            Bitmap bm = new(max * 8, lines.Length * 8);

            char[] special = [',', '.', '!', '?', '-', ' ', '\'', '"', '&'];
            Size sz = new(8, 8);

            int yDest = 0;
            Bitmap letter = Properties.Resources.Letters;
            using (Graphics g = Graphics.FromImage(bm))
                foreach (string str in lines)
                {
                    for (int i = 0, xDest = 0; i < max; i++, xDest += 8)
                    {
                        char c = ' ';
                        if (i < str.Length)
                            c = str[i];
                        int ySrc = 0, xSrc = 0;
                        if (Char.IsLetter(c))
                        {
                            if (Char.IsLower(c))
                                xSrc = ((int)c - 0x61) * 8; //a is 0x61 in ASCII
                            else if (Char.IsUpper(c))
                            {
                                ySrc = 8;
                                xSrc = ((int)c - 0x41) * 8; //A is 0x41 in ASCII
                            }
                        }
                        else if (Char.IsNumber(c))
                        {
                            ySrc = 16;
                            xSrc = (int)Char.GetNumericValue(c) * 8;
                        }
                        else if (special.Contains(c))
                        {
                            ySrc = 16;
                            xSrc = (Array.IndexOf(special, c) + 10) * 8;
                        }
                        else
                        {
                            ySrc = 16;
                            xSrc = 16 * 8;  //srouce = ' '
                        }

                        Point src = new(xSrc, ySrc);
                        Point dest = new(xDest, yDest);

                        g.DrawImage(letter.Clone(new Rectangle(src, sz), letter.PixelFormat), new Rectangle(dest, sz));
                    }
                    yDest += 8;
                }

            return bm;
        }

        private void Tiles_ListChanged(object sender, ListChangedEventArgs e) =>
            UpdateSpriteScreen(pcbSprite.Size);
        private void Sprite_PropertyChanged(object sender, PropertyChangedEventArgs e)
        {
            if (e.PropertyName == nameof(DisplaySprite.UseText))
            {
                UpdateUseText();
                UpdateGrid(GridSize);
            }
            parent_editor.DgvDisplay.EndEdit();
            parent_editor.DgvDisplay.Update();
            parent_editor.DgvDisplay.Refresh();
            UpdateSpriteScreen(pcbSprite.Size);
        }

        private bool DeleteSelected()
        {
            if (Sprite == null)
                return false;

            for (int i = 0; i < Sprite.Tiles.Count; i++)
                if (Sprite.Tiles[i].Selected)
                {
                    Sprite.Tiles.RemoveAt(i);
                    i--;
                }
            return true;
        }


        private int PixelToOffset(int pixel)
        {
            //should be same as height, otherwise... fixme
            return pixel - (pcbSprite.Width / 2 - 8);
        }

        private Point _startDrawPos;
        private void PcbSprite_MouseMove(object sender, MouseEventArgs e)
        {
            if (Sprite == null)
                return;

            if (e.Button == System.Windows.Forms.MouseButtons.Left)
            {
                if (!Sprite.Tiles.Any(s => s.Selected))
                    return;

                if (Cursor.Current == Cursors.SizeAll)
                {
                    int deltaX = e.X - _startDrawPos.X;
                    int deltaY = e.Y - _startDrawPos.Y;

                    if (Math.Abs(deltaX) >= GridSize || Math.Abs(deltaY) >= GridSize)
                    {
                        foreach (Tile t in Sprite.Tiles.Where(tt => tt.Selected))
                        {
                            t.XOffset += (deltaX / GridSize) * GridSize;
                            t.YOffset += (deltaY / GridSize) * GridSize;
                        }
                        _startDrawPos = e.Location;
                        UpdateSpriteScreen(pcbSprite.Size);
                    }
                }
                else
                {
                    Cursor.Current = Cursors.SizeAll;
                    _startDrawPos = e.Location;
                }
            }
            else
            {
                Cursor.Current = Cursors.Default;
            }
        }
        private void PcbSprite_MouseDown(object sender, MouseEventArgs e)
        {
            if (UseText)
                return;

            if (Sprite is null)
                return;

            if (e.Button == System.Windows.Forms.MouseButtons.Right)
            {
                int realGridSize = GridSize switch
                {
                    16 => TileSize.Width,
                    8 => TileSize.HalfWidth,
                    4 => TileSize.HalfWidth / 2,
                    2 => TileSize.HalfWidth / 4,
                    1 => TileSize.HalfWidth / 8,
                    _ => throw new ArgumentOutOfRangeException(nameof(GridSize)),
                };
                int xPix = e.X / realGridSize;
                int yPix = e.Y / realGridSize;
                Point p = new(xPix * realGridSize, yPix * realGridSize);

                int xOff = p.X - (pcbSprite.Width / 2 - TileSize.HalfWidth);
                int yOff = p.Y - (pcbSprite.Height / 2 - TileSize.HalfHeight);

                Sprite.Tiles.Add(new Tile(xOff, yOff, SelectedPoint.X / 16 + SelectedPoint.Y));
            }
            else if (e.Button == System.Windows.Forms.MouseButtons.Left)
            {
                if (Control.ModifierKeys != Keys.Control)
                    foreach (Tile t in Sprite.Tiles)
                        t.Selected = false;

                int x = PixelToOffset(e.X);
                int y = PixelToOffset(e.Y);
                Tile tl = Sprite.Tiles.LastOrDefault(t => (t.XOffset <= x && t.XOffset + 16 > x) && (t.YOffset <= y && t.YOffset + 16 > y));

                if (tl != null)
                    tl.Selected = !tl.Selected;

                UpdateSpriteScreen(pcbSprite.Size);
            }
        }
        private void PcbSprite_MouseWheel(object sender, MouseEventArgs e)
        {
            if (Sprite == null)
                return;

            if (!Sprite.Tiles.Any(s => s.Selected))
                return;

            int val = (e.Delta / -120); //scrolling up negative value, which will decrease the Z order.
            int limit = (val < 0 ? 0 : Sprite.Tiles.Count - 1);


            for (int i = limit; i < Sprite.Tiles.Count && i >= 0; i += (val * -1))
            {
                if (!Sprite.Tiles[i].Selected)
                    continue;
                if (i == limit)                     // if i is already at the limit, don't bother
                    continue;                       // as it won't get shifted anywhere.

                int off = i + val;

                if (off <= limit && val < 0)        // make sure tiles are not shifted out of the array
                    off = limit++;                  // if the limit is used, increase (or dec) it,
                else if (off > limit && val > 0)    // so the elements sort of "stack"
                    off = limit--;

                //swap them
                (Sprite.Tiles[off], Sprite.Tiles[i]) = (Sprite.Tiles[i], Sprite.Tiles[off]);
            }
        }
        private void PcbSprite_MouseEnter(object sender, EventArgs e)
        {
            pcbSprite.Focus();
        }


        protected override bool ProcessDialogKey(Keys keyData)
        {
            if (keyData == Keys.Delete && DeleteSelected())
                return true;
            return base.ProcessDialogKey(keyData);
        }
    }
}
