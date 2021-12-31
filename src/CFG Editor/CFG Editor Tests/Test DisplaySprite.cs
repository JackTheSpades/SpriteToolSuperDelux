using System;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using CFG.Map16;
using System.ComponentModel;
using System.Collections.Generic;

namespace CFG_Editor_Tests
{
    [TestClass]
    public class Test_DisplaySprite
    {
        [TestMethod]
        [TestCategory(nameof(DisplaySprite))]
        public void TestDisplayEquality()
        {
            var ds1 = Create();
            AddRange(ds1.Tiles);
            var ds2 = Create();
            AddRange(ds2.Tiles);
            
            Assert.IsTrue(ds1.Equals(ds2), "Sprites are not equal but ought to be");

            TestChange(ds1, ds2, ds => ds.Tiles[0].Map16Number = 0x02, "Tiles[0]");
            TestChange(ds1, ds2, ds => ds.Tiles.Add(new Tile(0, 0, 0)), "Tiles.Count");
            TestChange(ds1, ds2, ds => ds.DisplayText = "Another text", "DisplayText");
            TestChange(ds1, ds2, ds => ds.CustomBit = !ds.CustomBit, "CustomBit");
        }
        
        [TestMethod]
        [TestCategory(nameof(DisplaySprite))]
        public void TestDisplayClone()
        {
            var ds = Create();
            Assert.IsTrue(ds.Equals(ds.Clone()), "Clone is not equal");
        }

        [TestMethod]
        [TestCategory(nameof(DisplaySprite))]
        public void TestUniqueDisplay()
        {
            var ds1 = Create();
            var ds2 = Create();

            var comp = new DisplaySpriteUniqueComparer();

            ds2.Description = "Something different";
            ds2.CustomBit = !ds1.CustomBit;
            ds2.Tiles.Add(new Tile(0, 0, 0));

            Assert.IsTrue(comp.Equals(ds1, ds2), "Should only have checked X, Y and ExtraBit");

            TestChange(ds1, ds2, comp, ds => ds.ExtraBit = !ds.ExtraBit, nameof(DisplaySprite.ExtraBit));
            TestChange(ds1, ds2, comp, ds => ds.X_or_index++, nameof(DisplaySprite.X_or_index));
            TestChange(ds1, ds2, comp, ds => ds.Y_or_value--, nameof(DisplaySprite.Y_or_value));
        }
        
        [TestMethod]
        [TestCategory(nameof(DisplaySprite))]
        public void TestDisplayText()
        {
            var ds = Create();
            ds.DisplayText = "Some Text";
            ds.X_or_index = 5;
            ds.Y_or_value = 15;
            ds.ExtraBit = false;
            ds.CustomBit = true;

            Assert.AreEqual("F522 0,0,*Some Text*", ds.GetTileLine(), "First");
            ds.ExtraBit = true;
            Assert.AreEqual("F532 0,0,*Some Text*", ds.GetTileLine(), nameof(DisplaySprite.ExtraBit));
            ds.X_or_index = 0x0A;
            Assert.AreEqual("FA32 0,0,*Some Text*", ds.GetTileLine(), nameof(DisplaySprite.X_or_index));
            ds.Y_or_value = 0x01;
            Assert.AreEqual("1A32 0,0,*Some Text*", ds.GetTileLine(), nameof(DisplaySprite.Y_or_value));
            ds.DisplayText = "New";
            Assert.AreEqual("1A32 0,0,*New*", ds.GetTileLine(), nameof(DisplaySprite.Description));
        }




        private DisplaySprite Create()
        {
            return new DisplaySprite()
            {
                CustomBit = false,
                ExtraBit = true,
                Description = "A pointless sprite",
                DisplayText = "None for this sprite uses tiles",
                UseText = false,
                X_or_index = 5,
                Y_or_value = 7,
            };
        }

        private void AddRange(BindingList<Tile> tiles)
        {
            tiles.Add(new Tile(0x00, 0x00, 0x01));
            tiles.Add(new Tile(0x00, 0x10, 0x07));
            tiles.Add(new Tile(0x10, 0x00, 0x1F));
            tiles.Add(new Tile(0x10, 0x10, 0x28));
        }

        private void TestChange(DisplaySprite ds1, DisplaySprite ds2, Action<DisplaySprite> change, string msg)
        {
            change(ds1);
            Assert.IsFalse(ds1.Equals(ds2), msg);
            change(ds2);
            Assert.IsTrue(ds1.Equals(ds2), msg);
        }
        private void TestChange(DisplaySprite ds1, DisplaySprite ds2, IEqualityComparer<DisplaySprite> comp, Action<DisplaySprite> change, string msg)
        {
            change(ds1);
            Assert.IsFalse(comp.Equals(ds1, ds2), msg);
            change(ds2);
            Assert.IsTrue(comp.Equals(ds1, ds2), msg);
        }
    }
}
