using System;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using CFG.Map16;

namespace CFG_Editor_Tests
{
    [TestClass]
    public class Test_SnesGraphics
    {
        public SnesGraphics Gfx;

        [TestInitialize]
        public void GetGfx()
        {
            Gfx = new SnesGraphics(Properties.Resources.sampleGFX);
        }

        [TestMethod]
        [TestCategory(nameof(SnesGraphics))]
        public void TestGraphicsTile0()
        {
            for(int x = 0; x < 8; x++)
                for(int y = 0; y < 8; y++)
                {
                    int pal = Gfx.GetPixel8x8(0, x, y);
                    int exp = (x + y * 15) % 16;
                    Assert.AreEqual(exp, pal, $"x: {x}, y: {y}");
                }
        }
        [TestMethod]
        [TestCategory(nameof(SnesGraphics))]
        public void TestGraphicsTile1()
        {
            for (int x = 0; x < 8; x++)
                for (int y = 0; y < 8; y++)
                {
                    int pal = Gfx.GetPixel8x8(1, x, y);
                    Assert.AreEqual(y, pal, $"x: {x}, y: {y}");
                }
        }

        [TestMethod]
        [TestCategory(nameof(SnesGraphics))]
        public void TestGraphicsTile2()
        {
            for (int x = 0; x < 8; x++)
                for (int y = 0; y < 8; y++)
                {
                    int pal = Gfx.GetPixel8x8(2, x, y);
                    int exp = 15 - x;
                    Assert.AreEqual(exp, pal, $"x: {x}, y: {y}");
                }
        }

        [TestMethod]
        [TestCategory(nameof(SnesGraphics))]
        public void TestGraphicsTile3()
        {
            for (int x = 0; x < 8; x++)
                for (int y = 0; y < 8; y++)
                {
                    int pal = Gfx.GetPixel8x8(3, x, y);
                    int exp = ((x + y) % 2 == 0) ? 0x0E : 0x01;
                    Assert.AreEqual(exp, pal, $"x: {x}, y: {y}");
                }
        }
    }
}
