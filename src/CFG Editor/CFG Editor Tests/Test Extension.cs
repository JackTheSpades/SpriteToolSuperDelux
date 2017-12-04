using System;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using CFG;
using System.Collections.Generic;
using System.Linq;

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
    public class Test_Extension
    {
        [TestMethod]
        public void TestEnumName()
        {
            Assert.AreEqual("Entry1", TestEnum.Entry1.GetName());
            Assert.AreEqual("Entry2", TestEnum.Entry2.GetName());
            Assert.AreEqual("Entry3", TestEnum.EntryA.GetName());
        }

        public class TestCompare<T> : IEqualityComparer<T>
        {
            public Func<T, T, bool> EqualityFunction;
            public Func<T, int> HashFunction;

            public bool Equals(T x, T y)
            {
                return EqualityFunction(x, y);
            }

            public int GetHashCode(T obj)
            {
                if (ReferenceEquals(obj, null))
                    return 0;
                return HashFunction(obj);
            }
        }

        [TestMethod]
        public void DistinctTest()
        {
            var range = Enumerable.Range(0, 10);
            Assert.IsTrue(range.IsDistinct());

            var comp = new TestCompare<int>();
            comp.HashFunction = i => i % 9;
            comp.EqualityFunction = (x, y) => (x % 9) == (y % 9);

            Assert.IsFalse(range.IsDistinct(comp));
        }


        [TestMethod]
        public void TestGetBit()
        {
            byte ff = 0xFF;
            for (int i = 0; i < 8; i++)
                Assert.IsTrue(ff.GetBit(i));
            byte zero = 0x00;
            for (int i = 0; i < 8; i++)
                Assert.IsFalse(zero.GetBit(i));
            
            byte b = 0x53;
            Assert.AreEqual(true, b.GetBit(0));
            Assert.AreEqual(true, b.GetBit(1));
            Assert.AreEqual(false, b.GetBit(2));
            Assert.AreEqual(false, b.GetBit(3));
            Assert.AreEqual(true, b.GetBit(4));
            Assert.AreEqual(false, b.GetBit(5));
            Assert.AreEqual(true, b.GetBit(6));
            Assert.AreEqual(false, b.GetBit(7));

            //invert all bits
            b ^= 0xFF;

            Assert.AreEqual(false, b.GetBit(0));
            Assert.AreEqual(false, b.GetBit(1));
            Assert.AreEqual(true, b.GetBit(2));
            Assert.AreEqual(true, b.GetBit(3));
            Assert.AreEqual(false, b.GetBit(4));
            Assert.AreEqual(true, b.GetBit(5));
            Assert.AreEqual(false, b.GetBit(6));
            Assert.AreEqual(true, b.GetBit(7));
        }

        [TestMethod]
        public void TestGetBitException()
        {
            byte b = 0xFA;
            AssertThrow.Throws<ArgumentOutOfRangeException>(() => b.GetBit(8), "Shouldn't be able to read bit 8");
            AssertThrow.Throws<ArgumentOutOfRangeException>(() => b.GetBit(-1), "Shouldn't be able to read bit -1");
        }
    }
}
