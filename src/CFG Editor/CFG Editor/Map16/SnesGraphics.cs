using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace CFG.Map16
{
    public delegate void TileChangedEventHandler(object sender, TileChangedEventArgs e);
    public class TileChangedEventArgs : EventArgs
    {
        public int[] Tiles { get; set; }
        public TileChangedEventArgs(IEnumerable<int> tiles)
        {
            Tiles = tiles.ToArray();
        }
    }

    public interface INotifyTileChanged : INotifyPropertyChanged
    {
        event TileChangedEventHandler TileChanged;
    }

    public class SnesGraphics : INotifyTileChanged
    {
        public byte[] Data { get; set; }

        public SnesGraphics(byte[] data)
        {
            Data = data;
        }

        public event TileChangedEventHandler TileChanged;
        public event PropertyChangedEventHandler PropertyChanged;

        public void ChangeData(byte[] data, int offset)
        {
            Array.Copy(data, 0, Data, offset, data.Length);

            int startTile = offset / 32;
            int length = data.Length / 32;

            TileChanged?.Invoke(this, new TileChangedEventArgs(CountTo(startTile, length)));
            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(nameof(Data)));
        }

        private IEnumerable<int> CountTo(int start, int length)
        {
            for (int i = 0; i < length; i++)
                yield return start + i;
        }

        /// <summary>
        /// 
        /// </summary>
        /// <param name="tile"></param>
        /// <param name="size">The size in 8x8 tiles</param>
        /// <param name="colors">The colors row used for the tiles</param>
        /// <param name="format"></param>
        /// <param name="loopY"></param>
        /// <param name="loopX"></param>
        /// <returns></returns>
        public virtual Image GetImage(int tile, Size size, IEnumerable<Color> colors, int loopY = 0x100, int loopX = 0x10)
        {
            Bitmap bm = new Bitmap(size.Width * 8, size.Height * 8);
            var bmdata = bm.LockBits(new Rectangle(0, 0, bm.Width, bm.Height), System.Drawing.Imaging.ImageLockMode.ReadWrite, bm.PixelFormat);
            byte[] content = new byte[bmdata.Stride * bmdata.Height];
            System.Runtime.InteropServices.Marshal.Copy(bmdata.Scan0, content, 0, content.Length);

            for (int y = 0; y < bm.Height; y++)
                for (int x = 0; x < bm.Width; x++)
                {
                    int targetTile = tile + ((x / 8) % loopX) + (((y / 8) * 16) % loopY);

                    int byteOffset = (x + y * bm.Width) * 4;            //4 byte per pixel
                    int pal = 0;

                    //if(byteOffset < GFXPuffer.Length)
                    pal = GetPixel8x8(targetTile, x, y);        //x and y are being modolod in the method

                    Color c = Color.Transparent;
                    if (pal != 0)
                        c = colors.ElementAt(pal);

                    content[byteOffset + 0] = c.B;
                    content[byteOffset + 1] = c.G;
                    content[byteOffset + 2] = c.R;
                    content[byteOffset + 3] = c.A;
                }

            System.Runtime.InteropServices.Marshal.Copy(content, 0, bmdata.Scan0, content.Length);
            bm.UnlockBits(bmdata);
            return bm;
        }


        /// <summary>
        /// Gets the color of a pixel from an 8x8 tile in 4bpp graphics.
        /// </summary>
        /// <param name="tile">The 8x8 tile from which a pixel should be read</param>
        /// <param name="x">The x position within the tile to be read. Will automatically be modoloed by 8</param>
        /// <param name="y">The y position within the tile to be read. Will automatically be modoloed by 8</param>
        /// <returns></returns>
        private int GetPixel8x8(int tile, int x, int y)
        {
            try
            {
                int xT = x % 8;
                int yT = y % 8;

                int pal = 0;
                int offset = tile * 32;

                for (int i = 0, j = 0; i < 2; i++, j += 2)
                {
                    pal += Data[offset + i * 16 + 0 + yT * 2].GetBit(7 - xT) ? 1 << j : 0;
                    pal += Data[offset + i * 16 + 1 + yT * 2].GetBit(7 - xT) ? 2 << j : 0;
                }
                return pal;
            }
            catch (IndexOutOfRangeException)
            {
                return 0;
            }
        }
    }
}
