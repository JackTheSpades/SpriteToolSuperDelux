using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace CFG
{
	static class Program
	{
		/// <summary>
		/// The main entry point of the progam.
        /// Other than passing the calling arguments into the CFG Editor, nothing new happens here.
		/// </summary>
		[STAThread]
		static void Main(string[] args)
		{
			Application.EnableVisualStyles();
			Application.SetCompatibleTextRenderingDefault(false);
			Application.Run(new CFG_Editor(args));
		}
	}
}
