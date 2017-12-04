using System;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using CFG;

namespace CFG_Editor_Tests
{
    [TestClass]
    public partial class CFGFileTest
    {
        CfgFile data = new CfgFile();

        private void AssertTweakBytes(CfgFile data, byte[] reference)
        {
            Assert.AreEqual<byte>(reference[0], data.Type, nameof(CfgFile.Type));
            Assert.AreEqual<byte>(reference[1], data.ActLike, nameof(CfgFile.ActLike));

            Assert.AreEqual<byte>(reference[2], data.Addr1656, nameof(CfgFile.Addr1656));
            Assert.AreEqual<byte>(reference[3], data.Addr1662, nameof(CfgFile.Addr1662));
            Assert.AreEqual<byte>(reference[4], data.Addr166E, nameof(CfgFile.Addr166E));
            Assert.AreEqual<byte>(reference[5], data.Addr167A, nameof(CfgFile.Addr167A));
            Assert.AreEqual<byte>(reference[6], data.Addr1686, nameof(CfgFile.Addr1686));
            Assert.AreEqual<byte>(reference[7], data.Addr190F, nameof(CfgFile.Addr190F));

            Assert.AreEqual<byte>(reference[8], data.ExProp1, nameof(CfgFile.ExProp1));
            Assert.AreEqual<byte>(reference[9], data.ExProp2, nameof(CfgFile.ExProp2));
        }

        
        [TestMethod]
        public void TestClear()
        {
            TestRomiAsarLoad();
            data.Clear();
            byte[] reference = new byte[]
            {
                0x00,
                0x00,
                0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                0x00, 0x00
            };
            AssertTweakBytes(data, reference);
            Assert.AreEqual("", data.AsmFile);
            AssertVersion(data, 1, 0);
        }

        [TestMethod]
        public void TestTweakLoad()
        {
            data.FromLines(Properties.Resources.Tweak);

            byte[] reference = new byte[]
            {
                0x00,
                0x48,
                0x10, 0x80, 0x17, 0x00, 0x00, 0x00,
                0x00, 0x00
            };
            AssertTweakBytes(data, reference);
            AssertVersion(data, 1, 0);
        }

        [TestMethod]
        public void TestTweakWrite()
        {
            data.FromLines(Properties.Resources.Tweak);
            string dataSaved = data.ToLines();
            Assert.AreEqual(Properties.Resources.Tweak, dataSaved);
        }

        [TestMethod]
        public void TestRomiXkasLoad()
        {
            data.FromLines(Properties.Resources.CustomOldXkas);
            byte[] reference = new byte[]
            {
                0x01,
                0x36,
                0x80, 0x00, 0x31, 0x81, 0x19, 0x44,
                0x00, 0x00
            };
            AssertTweakBytes(data, reference);
            Assert.AreEqual("roto_disc.asm", data.AsmFile, nameof(CfgFile.AsmFile));
            AssertVersion(data, 1, 0);
        }
        [TestMethod]
        public void TestRomiAsarLoad()
        {
            data.FromLines(Properties.Resources.CustomOldAsar);
            byte[] reference = new byte[]
            {
                0x01,
                0x36,
                0x80, 0x00, 0x31, 0x81, 0x19, 0x44,
                0x00, 0x00
            };
            AssertTweakBytes(data, reference);
            Assert.AreEqual("roto_disc.asm", data.AsmFile, nameof(CfgFile.AsmFile));
            AssertVersion(data, 1, 0);
        }

        [TestMethod]
        public void TestPixiV1_1Load()
        {
            data.FromLines(Properties.Resources.Pixi_v1_1);
            byte[] reference = new byte[]
            {
                0x01,
                0x36,
                0x00, 0x15, 0x22, 0xAA, 0x89, 0x00,
                0x02, 0x05
            };
            AssertTweakBytes(data, reference);
            Assert.AreEqual("donut_lift.asm", data.AsmFile, nameof(CfgFile.AsmFile));
            Assert.AreEqual<byte>(3, data.ByteCount, nameof(CfgFile.ByteCount));
            Assert.AreEqual<byte>(4, data.ExByteCount, nameof(CfgFile.ExByteCount));

            AssertVersion(data, 1, 1);
        }

        [TestMethod]
        public void TestSmcRomSprite0()
        {
            data.FromRomBytes(Properties.Resources.faux_smc, 0);
            byte[] reference = new byte[]
            {
                0x00,
                0x00,
                0x70, 0x00, 0x0A, 0x00, 0x00, 0x00,
                0x00, 0x00
            };
            AssertTweakBytes(data, reference);
            Assert.AreEqual("", data.AsmFile, nameof(CfgFile.AsmFile));

            AssertVersion(data, 1, 0);
        }
        [TestMethod]
        public void TestSfcRomSprite0()
        {
            data.FromRomBytes(Properties.Resources.faux_sfc, 0);
            byte[] reference = new byte[]
            {
                0x00,
                0x00,
                0x70, 0x00, 0x0A, 0x00, 0x00, 0x00,
                0x00, 0x00
            };
            AssertTweakBytes(data, reference);
            Assert.AreEqual("", data.AsmFile, nameof(CfgFile.AsmFile));

            AssertVersion(data, 1, 0);
        }
    }
}
