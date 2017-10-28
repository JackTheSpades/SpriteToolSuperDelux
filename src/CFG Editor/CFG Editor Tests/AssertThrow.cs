using Microsoft.VisualStudio.TestTools.UnitTesting;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace CFG_Editor_Tests
{
    public static class AssertThrow
    {
        public static void Throws<T>(Action action, string message = null) where T : Exception
        {
            try
            {
                action();
                Assert.Fail(message);
            }
            catch(Exception ex)
            {
                if (ex is T)
                    Assert.IsTrue(true);
                else
                    Assert.Fail(message);
            }
        }
    }
}
