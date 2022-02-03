using System;
using System.Runtime.InteropServices;
using System.Text;

namespace PixiCLR
{
    public static unsafe class PixiAPI
    {
        [DllImport("pixi_api", EntryPoint = "pixi_run", CharSet = CharSet.Ansi, CallingConvention = CallingConvention.Cdecl)]
        [return: MarshalAs(UnmanagedType.I4)]
        private static extern int _pixi_run(int argc, IntPtr[] argv, IntPtr stdin, IntPtr stdout);

        [DllImport("pixi_api", EntryPoint = "pixi_api_version", CharSet = CharSet.Ansi, CallingConvention = CallingConvention.Cdecl)]
        [return: MarshalAs(UnmanagedType.I4)]
        private static extern int _api_version();

        [DllImport("pixi_api", EntryPoint = "pixi_check_api_version", CharSet = CharSet.Ansi, CallingConvention = CallingConvention.Cdecl)]
        [return: MarshalAs(UnmanagedType.I4)]
        private static extern int _check_api_version(int edition, int major, int minor);

        /// <summary>
        /// Runs Pixi with the specified arguments
        /// stdin and stdout are optional parameters that will override the input and output of the program
        /// If not passed they will default to the normal stdin/stdout
        /// </summary>
        /// <param name="argv">Arguments</param>
        /// <param name="stdin">Optional filename for stdin</param>
        /// <param name="stdout">Optional filename for stdout</param>
        /// <returns>Exit code of the Pixi run</returns>
        public static int Run(string[] argv, string stdin = "", string stdout = "")
        {
            // this code is absolutely HORRIFIC but it's the only way I found to make this work
            // if anyone has better idea, PLEASE help.
            byte[] zerobyte = new byte[] { 0 };
            IntPtr[] argv_cpp = new IntPtr[argv.Length];
            IntPtr stdin_ = IntPtr.Zero;
            IntPtr stdout_ = IntPtr.Zero;
            if (stdin.Length > 0)
            {
                byte[] buffer = Encoding.ASCII.GetBytes(stdin);
                stdin_ = Marshal.AllocHGlobal(buffer.Length + 1);
                Marshal.Copy(buffer, 0, stdin_, buffer.Length);
                Marshal.Copy(zerobyte, 0, stdin_ + buffer.Length, 1);
            }
            if (stdout.Length > 0)
            {
                byte[] buffer = Encoding.ASCII.GetBytes(stdout);
                stdout_ = Marshal.AllocHGlobal(buffer.Length + 1);
                Marshal.Copy(buffer, 0, stdout_, buffer.Length);
                Marshal.Copy(zerobyte, 0, stdout_ + buffer.Length, 1);
            }
            for (int i = 0; i < argv.Length; i++)
            {
                byte[] buffer = Encoding.ASCII.GetBytes(argv[i]);
                IntPtr memory = Marshal.AllocHGlobal(buffer.Length + 1);
                Marshal.Copy(buffer, 0, memory, buffer.Length);
                Marshal.Copy(zerobyte, 0, memory + buffer.Length, 1);
                argv_cpp[i] = memory;
            }
            int ret_val = _pixi_run(argv.Length, argv_cpp, stdin_, stdout_);

            foreach (var ptr in argv_cpp)
                Marshal.FreeHGlobal(ptr);
            if (stdout_ != IntPtr.Zero)
                Marshal.FreeHGlobal(stdout_);
            if (stdin_ != IntPtr.Zero)
                Marshal.FreeHGlobal(stdin_);
            return ret_val;
        }

        /// <summary>
        /// Returns the API version that the pixi dll is currently using
        /// </summary>
        /// <returns>Full API version in the format EDITION*100+MAJOR*10+MINOR</returns>
        public static int ApiVersion()
        {
            return _api_version();
        }

        /// <summary>
        /// Checks if the version passed in equals the current version present in the DLL.
        /// </summary>
        /// <param name="edition">Edition</param>
        /// <param name="major">Major</param>
        /// <param name="minor">Minor</param>
        /// <returns>True if matching, False otherwise</returns>
        public static bool CheckApiVersion(int edition, int major, int minor)
        {
            return _check_api_version(edition, major, minor) == 1;
        }
    }
}