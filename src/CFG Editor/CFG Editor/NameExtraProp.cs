using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace CFG
{
	public partial class NameExtraProp : Form
	{
		Control container;
		public NameExtraProp(Control container)
		{
			InitializeComponent();
			this.container = container;

			var txtList = grp1.Controls.Cast<Control>().Where(c => c is TextBox).Concat(grp2.Controls.Cast<Control>().Where(c => c is TextBox));
			foreach(TextBox txt in txtList)
			{
				CheckBox ch = (CheckBox)container.Controls.Find(txt.Name.Replace("txt", "chb"), true)[0];
				txt.Text = ch.Text;
			}
		}

		private void txt_TextChanged(object sender, EventArgs e)
		{
			TextBox tx = (TextBox)sender;
			CheckBox ch = (CheckBox)container.Controls.Find(tx.Name.Replace("txt", "chb"), true)[0];
			ch.Text = tx.Text;
		}
	}
}
