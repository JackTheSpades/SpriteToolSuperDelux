using Microsoft.VisualStudio.TestTools.UnitTesting;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace CFG_Editor_Tests.Json
{
    [TestClass]
    public class Byte_Representation_Test
    {
        [TestMethod]
        [TestCategory(nameof(CFG.Json.ByteRepresentant))]
        public void Test_Bytes()
        {
            var representants = new CFG.Json.ByteRepresentant[]
            {
                new CFG.Json.Value1656(),
                new CFG.Json.Value1662(),
                new CFG.Json.Value166E(),
                new CFG.Json.Value167A(),
                new CFG.Json.Value1686(),
                new CFG.Json.Value190F(),
            };

            foreach (var rep in representants)
                for (byte b = 0; b < byte.MaxValue; b++)
                    Test_Bytes(rep, b);
        }

        private void Test_Bytes(CFG.Json.ByteRepresentant representant, byte b)
        {
            representant.FromByte(b);
            Assert.AreEqual<byte>(b, representant.ToByte());
        }
    }
}
