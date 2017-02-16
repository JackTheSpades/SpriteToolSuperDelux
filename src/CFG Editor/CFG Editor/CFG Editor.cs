#if !DAIYOUSEI
#define PIXI
#endif

using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace CFG
{
	public enum CFG_SpriteType
	{
		Normal = 0,
		Custom = 1,
		GeneratorShooter = 3,
	}

	public partial class CFG_Editor : Form
	{
		private string filename = "";
		public string Filename 
		{
			get { return filename; }
			set
			{
				filename = value;
				if (value != "")
					this.Text = "CFG Editor - " + Path.GetFileNameWithoutExtension(value);
				else
					this.Text = "CFG Editor";
			}
		}
		
		Color sprClipBG = Color.FromArgb(115, 189, 255);
		Color sprClipMain = Color.FromArgb(33, 148, 255);
		Color sprClipDots = Color.FromArgb(189, 0, 0);
		
		public Image[] objClip = new Image[0x10];
		public Image[] sprClip = new Image[0x40];
		public Bitmap[] sprPal = new Bitmap[6 + 2 * 8];

		public byte[] PropertyBytes = new byte[10];						// first 6 are as below, then ExByte1 and 2, Act Like, ExCount
		public byte[] ExSprClip = new byte[4] { 0, 0, 0x10, 0x10 };		// Custom Sprite Clipping values (x,y,width,height) from Daiyousei

		int offset = 0;

		Dictionary<int, int> dicIndex = new Dictionary<int, int>()
		{
			{0x1656, 0},
			{0x1662, 1},
			{0x166E, 2},
			{0x167A, 3},
			{0x1686, 4},
			{0x190F, 5},
			{0x0001, 6},
			{0x0002, 7},
		};


		public Image ResizeImg(Size size, Image img)
		{
			float width, height;
			float x, y;

			if(img.Width < img.Height)
			{
				height = size.Height;
				width = (height / img.Height) * img.Width;
				y = 0;
				x = (size.Width / 2) - (width / 2);
			}
			else
			{
				width = size.Width;
				height = (width / img.Width) * img.Height;
				x = 0;
				y = (size.Height / 2) - (height / 2);
			}

			Bitmap bm = new Bitmap(size.Width, size.Height);
			using (Graphics g = Graphics.FromImage(bm))
			{
				g.InterpolationMode = System.Drawing.Drawing2D.InterpolationMode.NearestNeighbor;
				g.DrawImage(img, new RectangleF(x, y, width, height));
			}
			return bm;
		}


		public CFG_Editor(string[] args)
		{
			InitializeComponent();

			//add types to the comboboxes.
			foreach (CFG_SpriteType type in Enum.GetValues(typeof(CFG_SpriteType)))
				tsbType.Items.Add(type);

			//fetch clipping images from resources and add them to the comboboxes.
			for (int i = 0; i < objClip.Length; i++)
			{
				using (Stream str = System.Reflection.Assembly.GetExecutingAssembly().GetManifestResourceStream("CFG.Resources.ObjClipping." + i.ToString("X2") + ".png"))
					objClip[i] = ResizeImg(pcbObjClipping.Size, Image.FromStream(str));
				cmb_1656_0F.Items.Add(i.ToString("X2"));
			}
			for (int i = 0; i < sprClip.Length; i++)
			{
				using (Stream str = System.Reflection.Assembly.GetExecutingAssembly().GetManifestResourceStream("CFG.Resources.SprClipping." + i.ToString("X2") + ".png"))
					sprClip[i] = ResizeImg(pcbSprClipping.Size, Image.FromStream(str));
				cmb_1662_3F.Items.Add(i.ToString("X2"));
			}
			
			//draw bitmap of palette file for sprites.
			var palfile = Properties.Resources.sprite;
			for (int i = 0; i < sprPal.Length; i++)
			{
				Bitmap b = new Bitmap(8 * 16, 16);
				using(Graphics g = Graphics.FromImage(b))
					for(int pal = 0; pal < 8; pal++)
					{
						Color c = Color.FromArgb(
							palfile[8 * 3 * i + 3 * pal + 0],
							palfile[8 * 3 * i + 3 * pal + 1],
							palfile[8 * 3 * i + 3 * pal + 2]);
						Rectangle rec = new Rectangle(16 * pal, 0, 16, 16);
						g.FillRectangle(new SolidBrush(c), rec);
					}
				sprPal[i] = b;
			}
			
			//get all CheckBox controlls and add event
			var chb = tpgDefault.Controls.Cast<Control>().SelectMany(g => g.Controls.Cast<Control>()).Where(c => c is CheckBox);
			chb = chb.Concat(tpgAdvanced_Dai.Controls.Cast<Control>().SelectMany(g => g.Controls.Cast<Control>()).Where(c => c is CheckBox));
			foreach (CheckBox c in chb)
				c.CheckedChanged += CheckedChanged;

			if (args.Length == 0)
				cmb_1656_0F.SelectedIndex = cmb_1662_3F.SelectedIndex = cmb_166E_0E.SelectedIndex = 0;
			else if (File.Exists(args[0]))
			{
				try { ReadCFGFile(args[0]); }
				catch (Exception ex)
				{
					Filename = "";
					tsbType.SelectedItem = 0;
					MessageBox.Show("An error occured while trying to read the CFG file\n" + ex.Message, "Unexpected Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
				}
			}
			else
				MessageBox.Show("File: \"" + args[0] + "\" doesn't exist", "File not found", MessageBoxButtons.OK, MessageBoxIcon.Information);


#if DAIYOUSEI
			tabControl1.TabPages.Remove(tpgAdvanced_Old);
			tsbType.Visible = false;
#else
			optionsToolStripMenuItem.Visible = false;
			tabControl1.TabPages.Remove(tpgAdvanced_Dai);
#endif

		}


		/// <summary>
		/// Only allow hex values (and backspace) to be inputed into the textboxes
		/// </summary>
		/// <param name="sender">The textbox in question</param>
		/// <param name="e">Event args</param>
		private void txt_Hex_KeyPress(object sender, KeyPressEventArgs e)
		{
			if (e.KeyChar != '\b' && !Uri.IsHexDigit(e.KeyChar))
				e.Handled = true;
			e.KeyChar = Char.ToUpper(e.KeyChar);
		}

		bool _triggeredByTXT = false;
		bool _triggeredByCHB = false;
		bool _triggeredByTXT2 = false;

		#region Handle ComboBoxes
		/*
		 * The ComboBoxes that need a bit of special treatment.
		*/

		private void cmb_1656_0F_SelectedIndexChanged(object sender, EventArgs e)
		{
			lblObjBroke.Visible = ((ComboBox)sender).SelectedIndex >= 0x0F;
			pcbObjClipping.Image = objClip[((ComboBox)sender).SelectedIndex];

			//if this event was called because we edited the textbox content, return now.
			if (_triggeredByTXT)
				return;

			//if not, set the textbox content ourselves.
			_triggeredByCHB = true;
			PropertyBytes[0] &= 0xF0;
			PropertyBytes[0] |= (byte)cmb_1656_0F.SelectedIndex;
			txt_1656.Text = PropertyBytes[0].ToString("X2");
			_triggeredByCHB = false;
		}
		private void cmb_1662_3F_SelectedIndexChanged(object sender, EventArgs e)
		{
			lblSprBroke.Visible = ((ComboBox)sender).SelectedIndex >= 0x3C;
			pcbSprClipping.Image = sprClip[((ComboBox)sender).SelectedIndex];

			if (_triggeredByTXT)
				return;
			_triggeredByCHB = true;

			PropertyBytes[1] &= 0xC0;
			PropertyBytes[1] |= (byte)(cmb_1662_3F.SelectedIndex);
			txt_1662.Text = PropertyBytes[1].ToString("X2");
			_triggeredByCHB = false;
		}
		private void cmb_166E_0E_SelectedIndexChanged(object sender, EventArgs e)
		{
			int index = ((ComboBox)sender).SelectedIndex;
			if(index > 5)
				index += offset * 2;
			pcbPal.Image = sprPal[index];


			if (_triggeredByTXT)
				return;
			_triggeredByCHB = true;

			PropertyBytes[2] &= 0xF1;
			PropertyBytes[2] |= (byte)(cmb_166E_0E.SelectedIndex << 1);
			txt_166E.Text = PropertyBytes[2].ToString("X2");
			_triggeredByCHB = false;
		}
		#endregion

		/// <summary>
		/// Event that is triggered when any one checkbox changes state.
		/// The name of the Controls is the key, they are all named chb_RAM_BIT where RAM is the tweaker address they target and BIT
		/// is the bitmask for setting it.
		/// All textboxes are named txt_RAM
		/// </summary>
		/// <param name="sender">The CheckBox that changed</param>
		/// <param name="e">EventArgs (useless)</param>
		private void CheckedChanged(object sender, EventArgs e)
		{
			//if this event was only triggered because we edited the textbox (causing the checkboxes to adjust), return now
			if (_triggeredByTXT)
				return;
			//make sure the textbox event won't trigger when we update it later.
			_triggeredByCHB = true;

			CheckBox cb = (CheckBox)sender;

			//parse name of the checkbox and fetch the property (tweaker address) and bitmask for setting.
			var match = System.Text.RegularExpressions.Regex.Match(cb.Name, "chb_(?<CFG>[0-9A-F]{4})_(?<BIT>[0-9A-F]{2})");
			int prop = Convert.ToInt32(match.Groups["CFG"].Value, 16);
			int bit = Convert.ToInt32(match.Groups["BIT"].Value, 16);
			//set or unset the bits in the property array (access via dictionary for translating tweaker address to index)
			if (cb.Checked)
				PropertyBytes[dicIndex[prop]] |= (byte)bit;
			else
				PropertyBytes[dicIndex[prop]] &= (byte)(bit ^ 0xFF);

			//find the text box that displayes the property byte which was just changed.
			Control[] arr = this.Controls.Find("txt_" + prop.ToString("X4"), true);
			((TextBox)arr[0]).Text = PropertyBytes[dicIndex[prop]].ToString("X2");

			if(!_triggeredByTXT2)
			{
				txtEx1.Text = PropertyBytes[6].ToString("X2");
				txtEx2.Text = PropertyBytes[7].ToString("X2");
			}

			_triggeredByCHB = false;
		}

		private void txt_Hex_TextChanged(object sender, EventArgs e)
		{
			if (_triggeredByCHB)
				return;
			_triggeredByTXT = true;

			TextBox tx = (TextBox)sender;
			var match = System.Text.RegularExpressions.Regex.Match(tx.Name, "txt_(?<CFG>[0-9A-F]{4})");		// fetch which property is targeted from name
			int prop = Convert.ToInt32(match.Groups["CFG"].Value, 16);										// convert property to int for later use
			string text = (tx.Text == "") ? "0" : tx.Text;
			byte bit = Convert.ToByte(text, 16);															// convert value for the property
			PropertyBytes[dicIndex[prop]] = bit;															// store to array

			GroupBox container = (GroupBox)this.Controls.Find("grp_" + prop.ToString("X4"), true)[0];		// get the groupbox containing the property's conttrols

			foreach(Control c in container.Controls)
			{
				if (c is Label || c is PictureBox)
					continue;
				byte mask = Convert.ToByte(System.Text.RegularExpressions.Regex.Match(c.Name, "(chb|cmb)_(?<CFG>[0-9A-F]{4})_(?<BIT>[0-9A-F]{2})").Groups["BIT"].Value, 16);
				if(c is CheckBox)
					((CheckBox)c).Checked = ((bit & mask) != 0);
				if (c is ComboBox)
					((ComboBox)c).SelectedIndex = (bit & mask) / ((prop == 0x166E) ? 2 : 1);
			}

			_triggeredByTXT = false;
		}

		
		private void customSprClipping_Changed(object sender, EventArgs e)
		{
			int x = (int)nudSprX.Value;
			int y = (int)nudSprY.Value;
			int width = (int)nudSprWidth.Value;
			int height = (int)nudSprHeight.Value;

			int left = (x < 0) ? x : 0;
			int right = (x + width > 16) ? x + width : 16;
			int top = (y < 0) ? y : 0;
			int bottom = (y + height > 16) ? y + height : 16;

			Bitmap bm = new Bitmap(right - left, bottom - top);
			using (Graphics g = Graphics.FromImage(bm))
			{
				g.FillRectangle(new SolidBrush(sprClipBG), new Rectangle(0, 0, bm.Width, bm.Height));
				g.FillRectangle(new SolidBrush(sprClipMain), new Rectangle(left * -1, top * -1, 16, 16));
			}

			bm.SetPixel(x - left, y - top, sprClipDots);
			bm.SetPixel(x - left + width - 1, y - top, sprClipDots);
			bm.SetPixel(x - left, y - top + height - 1, sprClipDots);
			bm.SetPixel(x - left + width - 1, y - top + height - 1, sprClipDots);

			pcbSprCustomClipping.Image = bm;
			ExSprClip[0] = (byte)x;
			ExSprClip[1] = (byte)y;
			ExSprClip[2] = (byte)width;
			ExSprClip[3] = (byte)height;
		}

		/*
		DYS 1
		acts-like:    xx
		props:        xx xx xx xx xx xx
		ext-props:    xx xx
		dys-opts:     10 00
		ext-clip:     00 f8 10 18
		name:         Sprite
		description:  A can of Sprite to satisfy Mario's thirst.
		name-set:     Sprite2
		desc-set:     Sprite with extra bit set.
		source:       file.asm
		xbytes:       x
		ext-prop-def: abb:text
		*/

		const string HEADER = "DYS 1";
		const string ACTLIKE = "acts-like:";
		const string PROPERTIES = "props:";
		const string EXTRABYTES = "ext-props:";
		const string DYSOPTIONS = "dys-opts:";
		const string EXTCLIPPING = "ext-clip:";
		const string NAME = "name:";
		const string DESC = "desc:";
		const string NAMESET = "name-set:";
		const string DESCSET = "desc-set:";
		const string SOURCE = "source:";
		const string EXBYTESCOUNT = "xbytes:";
		const string EXTPROPDEF = "ext-prop-def:";

		public void ReadCFGFile(string path)
		{
			string content = File.ReadAllText(path).Replace("\r","");
			Filename = path;

#if DAIYOUSEI
			if (content.StartsWith(HEADER))
			{
				var matches = Regex.Matches(content, "^" + EXTPROPDEF + "\\s*(?<DEST>[0-9]{3}):(?<TEXT>.*)", RegexOptions.Multiline);
				foreach (Match m in matches)
				{
					string txt = m.Groups["TEXT"].Value.Trim('\r');
					char ex = m.Groups["DEST"].Value[0];
					string mask = m.Groups["DEST"].Value.Substring(1);
					((CheckBox)tpgAdvanced_Dai.Controls.Find("chb_000" + ex + "_" + mask, true)[0]).Text = txt;
				}

				var mat = Regex.Match(content, "^" + EXTRABYTES + "\\s*(?<VAL1>[0-9a-fA-F]{2})\\s+(?<VAL2>[0-9a-fA-F]{2})", RegexOptions.Multiline);
				for (int i = 0; i < 2; i++)
				{
					if (!mat.Groups["VAL" + (i + 1)].Success)
						continue;
					PropertyBytes[i + 6] = Convert.ToByte(mat.Groups["VAL" + (i + 1)].Value, 16);
					int addr = dicIndex.FirstOrDefault(x => x.Value == (i + 6)).Key;
					TextBox tx = (TextBox)(tpgAdvanced_Dai.Controls.Find("txt_" + addr.ToString("X4"), false)[0]);
					tx.Text = PropertyBytes[i + 6].ToString("X2");
				}
				txtEx1.Text = PropertyBytes[6].ToString("X2");
				txtEx2.Text = PropertyBytes[7].ToString("X2");

				mat = Regex.Match(content, "^" + ACTLIKE + "\\s*(?<VAL>[0-9a-fA-F]{2})", RegexOptions.Multiline);
				if (mat.Groups["VAL"].Success)
				{
					PropertyBytes[8] = Convert.ToByte(mat.Groups["VAL"].Value, 16);
					txtActLike.Text = mat.Groups["VAL"].Value;
				}

				mat = Regex.Match(content, "^" + EXBYTESCOUNT + "\\s*(?<VAL>[0-6])", RegexOptions.Multiline);
				if (mat.Groups["VAL"].Success)
				{
					PropertyBytes[9] = Convert.ToByte(mat.Groups["VAL"].Value, 16);
				}


				mat = Regex.Match(content, "^" + PROPERTIES + "\\s*(?<VAL1>[0-9a-fA-F]{2})\\s+(?<VAL2>[0-9a-fA-F]{2})\\s+(?<VAL3>[0-9a-fA-F]{2})\\s+(?<VAL4>[0-9a-fA-F]{2})\\s+(?<VAL5>[0-9a-fA-F]{2})\\s+(?<VAL6>[0-9a-fA-F]{2})", RegexOptions.Multiline);
				for (int i = 0; i < 6; i++ )
				{
					if (!mat.Groups["VAL" + (i + 1)].Success)
						continue;
					PropertyBytes[i] = Convert.ToByte(mat.Groups["VAL" + (i + 1)].Value, 16);
					int addr = dicIndex.FirstOrDefault(x => x.Value == i).Key;
					TextBox tx = (TextBox)(tpgDefault.Controls.Find("txt_" + addr.ToString("X4"), false)[0]);
					tx.Text = PropertyBytes[i].ToString("X2");
				}

				mat = Regex.Match(content, "^" + SOURCE + "\\s*(?<TEXT>.*)", RegexOptions.Multiline);
				txtASMFile.Text = mat.Groups["TEXT"].Value;


				mat = Regex.Match(content, "^" + NAME + "\\s*(?<TEXT>.*)", RegexOptions.Multiline);
				if (mat.Groups["TEXT"].Success)
					txtName.Text = mat.Groups["TEXT"].Value;
				mat = Regex.Match(content, "^" + DESC + "\\s*(?<TEXT>.*)", RegexOptions.Multiline);
				if (mat.Groups["TEXT"].Success)
					rtbDesc.Text = mat.Groups["TEXT"].Value.Replace("\\n", "\n");
				mat = Regex.Match(content, "^" + NAMESET + "\\s*(?<TEXT>.*)", RegexOptions.Multiline);
				if (mat.Groups["TEXT"].Success)
					txtNameSet.Text = mat.Groups["TEXT"].Value;
				mat = Regex.Match(content, "^" + DESCSET + "\\s*(?<TEXT>.*)", RegexOptions.Multiline);
				if (mat.Groups["TEXT"].Success)
					rtbDescSet.Text = mat.Groups["TEXT"].Value.Replace("\\n", "\n");


				mat = Regex.Match(content, "^" + EXTCLIPPING + "\\s*(?<VAL1>[0-9a-fA-F]{2})\\s+(?<VAL2>[0-9a-fA-F]{2})\\s+(?<VAL3>[0-9a-fA-F]{2})\\s+(?<VAL4>[0-9a-fA-F]{2})", RegexOptions.Multiline);
				if (mat.Groups["VAL1"].Success)
					ExSprClip[0] = Convert.ToByte(mat.Groups["VAL1"].Value, 16);
				if (mat.Groups["VAL2"].Success)
					ExSprClip[1] = Convert.ToByte(mat.Groups["VAL2"].Value, 16);
				if (mat.Groups["VAL3"].Success)
					ExSprClip[2] = Convert.ToByte(mat.Groups["VAL3"].Value, 16);
				if (mat.Groups["VAL4"].Success)
					ExSprClip[3] = Convert.ToByte(mat.Groups["VAL4"].Value, 16);
			}
			else 
#endif
			{
				var old = Regex.Match(content, "(?<TYPE>[0-9a-fA-F]{1,2})\n(?<ACT>[0-9a-fA-F]{1,2})\n(?<PROP1>[0-9a-fA-F]{1,2}) (?<PROP2>[0-9a-fA-F]{1,2}) (?<PROP3>[0-9a-fA-F]{1,2}) (?<PROP4>[0-9a-fA-F]{1,2}) (?<PROP5>[0-9a-fA-F]{1,2}) (?<PROP6>[0-9a-fA-F]{1,2})\n((?<PROP7>[0-9a-fA-F]{1,2}) (?<PROP8>[0-9a-fA-F]{1,2})\n(?<ASM>.*))?");
				for(int i = 0; i<8;i++)
				{
					if (!old.Groups["PROP" + (i + 1)].Success)
						continue;
					PropertyBytes[i] = Convert.ToByte(old.Groups["PROP" + (i + 1)].Value, 16);
					int addr = dicIndex.FirstOrDefault(x => x.Value == (i)).Key;
					TextBox tx = (TextBox)(this.Controls.Find("txt_" + addr.ToString("X4"), true)[0]);
					tx.Text = PropertyBytes[i].ToString("X2");
				}
				txtASMFile.Text = old.Groups["ASM"].Value;
				PropertyBytes[8] = Convert.ToByte(old.Groups["ACT"].Value, 16);
				tsbType.SelectedItem = (CFG_SpriteType)Convert.ToByte(old.Groups["TYPE"].Value, 16);
				txtActLike.Text = PropertyBytes[8].ToString("X2");
			}
		}

		public void WriteCFGFile(string path)
		{
			StringBuilder sb = new StringBuilder();

#if DAIYOUSEI
			sb.AppendLine(HEADER);

			int padding = EXTPROPDEF.Length + 1;
			sb.AppendLine(ACTLIKE.PadRight(padding) + PropertyBytes[8].ToString("X2"));
			sb.AppendLine(PROPERTIES.PadRight(padding) + ByteToHex(PropertyBytes, 0, 6));
			sb.AppendLine(EXBYTESCOUNT.PadRight(padding) + ByteToHex(PropertyBytes, 7, 2));

			byte[] dys = new byte[] { 0, 0 };

			if (chbSprClip.Checked)
			{
				sb.AppendLine(EXTCLIPPING.PadRight(padding) + ByteToHex(ExSprClip, 0, 4));
				dys[0] |= 0x40;
			}
			sb.AppendLine(DYSOPTIONS.PadRight(padding) + ByteToHex(dys, 0, 2));

			if (txtName.Text != "")
				sb.AppendLine(NAME.PadRight(padding) + txtName.Text);
			if(rtbDesc.Text != "")
				sb.AppendLine(DESC.PadRight(padding) + rtbDesc.Text.Replace("\n", "\\n"));
			if (txtNameSet.Text != "")
				sb.AppendLine(NAMESET.PadRight(padding) + txtNameSet.Text);
			if (rtbDescSet.Text != "")
				sb.AppendLine(DESCSET.PadRight(padding) + rtbDescSet.Text.Replace("\n", "\\n"));
			sb.AppendLine(SOURCE.PadRight(padding) + txtASMFile.Text);

			sb.AppendLine(EXBYTESCOUNT.PadRight(padding) + PropertyBytes[9].ToString("X2"));


			for(int b = 1; b < 3; b++)
				for(int i = 0; i < 8; i++)
				{
					CheckBox ch = (CheckBox)tpgAdvanced_Dai.Controls.Find("chb_" + b.ToString("X4") + "_" + (1 << i).ToString("X2"), true)[0];
					sb.AppendLine(EXTPROPDEF.PadRight(padding) + b + (1 << i).ToString("X2") + ":" + ch.Text);
				}
#else
			var type = (CFG_SpriteType)tsbType.SelectedItem;

			sb.AppendLine(((int)type).ToString("X2"));
			sb.AppendLine(txtActLike.Text);
			sb.AppendLine(ByteToHex(PropertyBytes, 0, 6));
			if (type != CFG_SpriteType.Normal)
			{
				sb.AppendLine(ByteToHex(PropertyBytes, 6, 2));
				sb.AppendLine(txtASMFile.Text);
				sb.AppendLine("2");
			}

#endif
			File.WriteAllText(path, sb.ToString());
		}


		private string ByteToHex(byte[] arr, int start, int length)
		{
			string s = "";
			for (int i = start; i < (start + length); i++)
				s += arr[i].ToString("X2") + " ";
			return s.TrimEnd(' ');
		}


		private void nameExtraByteCheckboxesToolStripMenuItem_Click(object sender, EventArgs e)
		{
			new NameExtraProp(tpgAdvanced_Dai).ShowDialog();
		}

		#region "File" Menu Item Events
		private void newToolStripMenuItem_Click(object sender, EventArgs e)
		{
			if (MessageBox.Show("All unsaved changes will be lost. Proceed?", "Warning", MessageBoxButtons.OKCancel, MessageBoxIcon.Warning) ==
				System.Windows.Forms.DialogResult.Cancel)
				return;

			txt_0001.Text = "00";
			txt_0002.Text = "00";

			txt_1656.Text = "00";
			txt_1662.Text = "00";
			txt_166E.Text = "00";
			txt_167A.Text = "00";
			txt_1686.Text = "00";
			txt_190F.Text = "00";

			txtActLike.Text = "";
			txtASMFile.Text = "";
			txtName.Text = "";
			txtNameSet.Text = "";
			rtbDesc.Text = "";
			rtbDescSet.Text = "";

			chbSprClip.Checked = false;

			this.Filename = "";
		}

		private void loadToolStripMenuItem_Click(object sender, EventArgs e)
		{
			OpenFileDialog ofd = new OpenFileDialog();
			ofd.Filter = "CFG file|*.cfg";
			ofd.Title = "Load CFG file";
			if (ofd.ShowDialog() == System.Windows.Forms.DialogResult.Cancel)
				return;
			try
			{
				ReadCFGFile(ofd.FileName);
			}
			catch (Exception ex)
			{
				Filename = "";
				MessageBox.Show("An error occured while trying to read the CFG file\n" + ex.Message, "Unexpected Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
			}
		}

		private void saveAsToolStripMenuItem_Click(object sender, EventArgs e)
		{
			SaveFileDialog sfd = new SaveFileDialog();
			sfd.Title = "Save CFG File";
			sfd.Filter = "CFG File|*.cfg";
			sfd.FileName = Filename;
			if (sfd.ShowDialog() == System.Windows.Forms.DialogResult.Cancel)
				return;
			WriteCFGFile(sfd.FileName);
			Filename = sfd.FileName;
		}

		private void saveToolStripMenuItem_Click(object sender, EventArgs e)
		{
			if (Filename == "")
				saveAsToolStripMenuItem_Click(sender, e);
			else
				WriteCFGFile(Filename);
		}
		#endregion
		
		private void chbSprClip_CheckedChanged(object sender, EventArgs e)
		{
			grpSpr.Enabled = chbSprClip.Checked;
		}

		protected override bool ProcessCmdKey(ref Message msg, Keys keyData)
		{
			if(keyData == (Keys.O|Keys.Alt))
			{
				chbObjClip.Visible = grpObj.Visible = true;
				return true;
			}

			return base.ProcessCmdKey(ref msg, keyData);
		}

		private void txtActLike_TextChanged(object sender, EventArgs e)
		{
			string text = txtActLike.Text == "" ? "0" : txtActLike.Text;
			PropertyBytes[8] = Convert.ToByte(text, 16);
		}

		private void txtEx1_TextChanged(object sender, EventArgs e)
		{
			if (_triggeredByTXT)
				return;
			_triggeredByTXT2 = true;
			txt_0001.Text = txtEx1.Text;
			_triggeredByTXT2 = false;
		}

		private void txtEx2_TextChanged(object sender, EventArgs e)
		{

			if (_triggeredByTXT)
				return;
			_triggeredByTXT2 = true;
			txt_0002.Text = txtEx2.Text;
			_triggeredByTXT2 = false;
		}

		private void tsbType_SelectedIndexChanged(object sender, EventArgs e)
		{
			bool b = !((CFG_SpriteType)tsbType.SelectedItem == CFG_SpriteType.Normal);
			txtASMFile.Enabled = b;
			txtEx1.Enabled = b;
			txtEx2.Enabled = b;
		}

	}
}
