using System;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using CFG;

namespace CFG_Editor_Tests
{
    [TestClass]
    public class Test_CollectionSprite
    {
        [TestMethod]
        public void TestCollectionParse()
        {
            var cs = new CollectionSprite("1 FF EE BB 55 Some Name or so");

            Assert.AreEqual(true, cs.ExtraBit, nameof(CollectionSprite.ExtraBit));
            Assert.AreEqual(0xFF, cs.ExtraPropertyByte1, nameof(CollectionSprite.ExtraPropertyByte1));
            Assert.AreEqual(0xEE, cs.ExtraPropertyByte2, nameof(CollectionSprite.ExtraPropertyByte2));
            Assert.AreEqual(0xBB, cs.ExtraPropertyByte3, nameof(CollectionSprite.ExtraPropertyByte3));
            Assert.AreEqual(0x55, cs.ExtraPropertyByte4, nameof(CollectionSprite.ExtraPropertyByte4));
            Assert.AreEqual("Some Name or so", cs.Name, nameof(CollectionSprite.Name));
        }
    }
}
