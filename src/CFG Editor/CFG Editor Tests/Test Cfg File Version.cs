using System;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using CFG;
using CFG.Map16;

namespace CFG_Editor_Tests
{
    public partial class CFGFileTest
    {

        private void AssertVersion(CfgFile data, int major = 1, int minor = 0)
        {
            //don't check on the given version if fields are clear but on the next one.
            minor++;

            Version v = data.GetType().Assembly.GetName().Version;
            for(; major <= v.Major; major++)
            {
                for(; minor <= v.Minor; minor++)
                {
                    string methodName = $"AssertVersion_{major}_{minor}";
                    var methodInfo = GetType().GetMethod(methodName, new[] { data.GetType() });
                    Assert.IsNotNull(methodInfo, $"Version guard method: \"{methodName}\" not found");
                    methodInfo.Invoke(this, new[] { data });
                }
            }
        }

        /// <summary>
        /// No real point in version guarding for 1.0, so just check that it's not null.
        /// </summary>
        /// <param name="data"></param>
        public void AssertVersion_1_0(CfgFile data) => Assert.IsNotNull(data);


        /// <summary>
        /// Asserts that fields that were added in Version 1.1 or later remained clear on older loadings.
        /// </summary>
        /// <param name="data"></param>
        public void AssertVersion_1_1(CfgFile data)
        {
            Assert.AreEqual<byte>(0x00, data.ByteCount, nameof(CfgFile.ByteCount));
            Assert.AreEqual<byte>(0x00, data.ExByteCount, nameof(CfgFile.ExByteCount));
        }

        /// <summary>
        /// Asserts that fields that were added in Version 1.2 or later remained clear on older loadings.
        /// Entries are suppose to be empty and not null
        /// </summary>
        /// <param name="data"></param>
        public void AssertVersion_1_2(CfgFile data)
        {
            Assert.IsNotNull(data.CustomMap16Data, nameof(CfgFile.CustomMap16Data));
            Assert.IsNotNull(data.DisplayEntries, nameof(CfgFile.CustomMap16Data));
            Assert.IsNotNull(data.CollectionEntries, nameof(CfgFile.CollectionEntries));

            Assert.AreEqual(0, data.CustomMap16Data.Length, nameof(CfgFile.CustomMap16Data));
            Assert.AreEqual(0, data.DisplayEntries.Count, nameof(CfgFile.CustomMap16Data));
            Assert.AreEqual(0, data.CollectionEntries.Count, nameof(CfgFile.CollectionEntries));
        }
    }
}
