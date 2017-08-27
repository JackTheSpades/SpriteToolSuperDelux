using System;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using CFG;

namespace CFG_Editor_Tests
{
    public enum TestEnum
    {
        Entry1,
        Entry2,
        [DisplayName("Entry3")]
        EntryA
    }

    [TestClass]
    public class Test_Enum_Extension
    {
        [TestMethod]
        public void TestEnumName()
        {
            Assert.AreEqual("Entry1", TestEnum.Entry1.GetName());
            Assert.AreEqual("Entry2", TestEnum.Entry2.GetName());
            Assert.AreEqual("Entry3", TestEnum.EntryA.GetName());
        }
    }
}
