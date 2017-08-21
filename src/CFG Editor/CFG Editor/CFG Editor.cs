using CFG.Map16;
using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Drawing;
using System.IO;
using System.Linq;
using System.Windows.Forms;

namespace CFG
{
	public enum CFG_SpriteType
	{
		Normal = 0,
		Custom = 1,
        [Description("Generator/Shooter")]
		GeneratorShooter = 3,
	}

    public enum FileType
    {
        CfgFile,
        RomFile,
    }

    public enum GridSize
    {
        [Description("1x1")]
        Size1x1 = 1,
        [Description("2x2")]
        Size2x2 = 2,
        [Description("4x4")]
        Size4x4 = 4,
        [Description("8x8")]
        Size8x8 = 8,
        [Description("16x16")]
        Size16x16 = 16,
    }

	public partial class CFG_Editor : Form
	{
        #region Properteis

        private string filename = "";
		public string Filename 
		{
			get { return filename; }
			set
			{
                if (filename != value)
                {
                    filename = value;
                    if (value != "")
                        this.Text = "CFG Editor - " + Path.GetFileName(value) + (Unsaved ? "*" : "");
                    else
                        this.Text = "CFG Editor";
                }
			}
		}

        private bool unsaved = false;
        public bool Unsaved
        {
            get { return unsaved; }
            set
            {
                if (unsaved != value)
                {
                    unsaved = value;
                    Filename = Filename;    //update filename using setter method
                }
            }
        }

        public readonly CFGFile Data;

        		
		public Image[] objClip = new Image[0x10];
		public Image[] sprClip = new Image[0x40];
		public Bitmap[] sprPal = new Bitmap[6 + 2 * 8];

        
        /// <summary>
        /// The sprite palette to be used. Not the one from the CFG file but the one displayed when pal E or F are selected.
        /// </summary>
		public int SpritePalette = 0;

        #endregion

        BindingList<ComboBoxItem> types_list = new BindingList<ComboBoxItem>();
        BindingList<ComboBoxItem> sprites_list = new BindingList<ComboBoxItem>();

        public DisplaySprite SelectedSprite { get; set; }
        Map16Resources resources = new Map16.Map16Resources();
        public IMap16Object SelectedMap16Object { get; set; } = new Map16Empty(16);

        /// <summary>
        /// List of all controlls that will be disabled when the Type is 0 or when in Rom editing mdoe.
        /// </summary>
        List<Control> disabled_controlls;

        FileType FileType;
        byte[] RomData = null;
               

		public CFG_Editor(string[] args)
		{
            InitializeComponent();

            #region Default Tab

            disabled_controlls = new List<Control>()
            {
                grpAsmActLike,
                grpExtraByteCount,
                grpExtraPropByte,
            };

            Data = new CFGFile();
            Data.PropertyChanged += (_, __) => Unsaved = true;

            cmb_1656_0F.BitsBind(Data, c => c.SelectedIndex, f => f.Addr1656, 4, 0).DataSourceUpdateMode = DataSourceUpdateMode.OnPropertyChanged;
			cmb_1662_3F.BitsBind(Data, c => c.SelectedIndex, f => f.Addr1662, 6, 0).DataSourceUpdateMode = DataSourceUpdateMode.OnPropertyChanged;
			cmb_166E_0E.BitsBind(Data, c => c.SelectedIndex, f => f.Addr166E, 3, 1).DataSourceUpdateMode = DataSourceUpdateMode.OnPropertyChanged;

			SetupBinding(Data, f => f.Addr1656, "1656", 0);
			SetupBinding(Data, f => f.Addr1662, "1662", 0);
			SetupBinding(Data, f => f.Addr166E, "166E", 0);
			SetupBinding(Data, f => f.Addr167A, "167A", 0);
			SetupBinding(Data, f => f.Addr1686, "1686", 0);
			SetupBinding(Data, f => f.Addr190F, "190F", 0);
            
			txt_0001.Bind(Data, c => c.Text, f => f.ExProp1, f => f.ToString("X2"), c => StringToByte(c));
			txt_0002.Bind(Data, c => c.Text, f => f.ExProp2, f => f.ToString("X2"), c => StringToByte(c));
            nudNormal.Bind(Data, c => c.Value, f => f.ByteCount, null, c => (byte)c);
            nudExtra.Bind(Data, c => c.Value, f => f.ExByteCount, null, c => (byte)c);
            txtASMFile.Bind(Data, c => c.Text, f => f.AsmFile);
            txtActLike.Bind(Data, c => c.Text, f => f.ActLike, f => f.ToString("X2"), c => StringToByte(c));


            //add types to the comboboxes.
            foreach (CFG_SpriteType type in Enum.GetValues(typeof(CFG_SpriteType)))
                types_list.Add(new ComboBoxItem(type.GetName(), (int)type));
            string[] sprite_list_lines = Properties.Resources.SpriteList.Split("\r\n".ToCharArray(), StringSplitOptions.RemoveEmptyEntries);
            for (int i = 0; i < 201; i++)
                sprites_list.Add(new ComboBoxItem(sprite_list_lines[i], i));

            cmbType.DataSource = types_list;

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

            #endregion
            
            List<byte> gfx = new List<byte>();
            gfx.AddRange(Enumerable.Repeat<byte>(0, 0x4000));
            gfx.AddRange(GetGfxArray(0x33, 0x3000));
            gfx.AddRange(Enumerable.Repeat<byte>(0, 0x800));

            resources.Graphics = new Map16.SnesGraphics(gfx.ToArray());


            cmbTilesets.Items.AddRange(new[]
            {
                new SpriteTileset(0x13, 0x02, "Forest"),
                new SpriteTileset(0x12, 0x03, "Castle"),
                new SpriteTileset(0x13, 0x05, "Mushroom"),
                new SpriteTileset(0x13, 0x04, "Underground"),
                new SpriteTileset(0x13, 0x06, "Water"),
                new SpriteTileset(0x13, 0x09, "Pokey"),
                new SpriteTileset(0x06, 0x11, "Ghost House"),
                new SpriteTileset(0x13, 0x20, "Banzai Bill"),
                new SpriteTileset(0x1C, 0x1D, "Overworld") { Sp1 = 0x10, Sp2 = 0x0F },
            });
            cmbTilesets.SelectedIndexChanged += (_, __) =>
            {
                var tileset = (SpriteTileset)cmbTilesets.SelectedItem;
                SetDataSelectorGfx(dsSP1, tileset.Sp1);
                SetDataSelectorGfx(dsSP2, tileset.Sp2);
                SetDataSelectorGfx(dsSP3, tileset.Sp3);
                SetDataSelectorGfx(dsSP4, tileset.Sp4);
            };
            dsSP1.Tag = 0x0000;
            dsSP2.Tag = 0x1000;
            dsSP3.Tag = 0x2000;
            dsSP4.Tag = 0x3000;
            cmbTilesets.SelectedIndex = 0;






            SelectedSprite = new DisplaySprite();
            SelectedSprite.Description = "A green bouncing parakoopa. It will jump high (7 tiles up) or low (2 tiles up) depending on its Y position. It's currently set to jump low.";
            SelectedSprite.Tiles = new BindingList<Tile>()
            {
                new Tile(0, -16, 0x10),
                new Tile(0, 0, 0x140),
                new Tile(2, -14, 8),
            };



            foreach (GridSize gridSize in Enum.GetValues(typeof(GridSize)).Cast<GridSize>().Reverse())
                cmbGrid.Items.Add(new ComboBoxItem(gridSize.GetName(), (int)gridSize));
            cmbGrid.SelectedIndex = 0;
            cmbGrid.SelectedIndexChanged += (_, __) => spriteEditor1.GridSize = ((ComboBoxItem)cmbGrid.SelectedItem).Value;

            displaySpriteBindingSource.DataSource = Data;
            displaySpriteBindingSource.DataMember = nameof(CFGFile.DisplayEntries);

            rtbDesc.DataBindings.Add(nameof(RichTextBox.Text), displaySpriteBindingSource, $"{nameof(BindingSource.Current)}.{nameof(DisplaySprite.Description)}");
            nudX.DataBindings.Add(nameof(NumericUpDown.Value), displaySpriteBindingSource, $"{nameof(BindingSource.Current)}.{nameof(DisplaySprite.X)}");
            nudY.DataBindings.Add(nameof(NumericUpDown.Value), displaySpriteBindingSource, $"{nameof(BindingSource.Current)}.{nameof(DisplaySprite.Y)}");
            chbExtraBit.DataBindings.Add(nameof(CheckBox.Checked), displaySpriteBindingSource, $"{nameof(BindingSource.Current)}.{nameof(DisplaySprite.ExtraBit)}");
            chbUseText.DataBindings.Add(nameof(CheckBox.Checked), displaySpriteBindingSource, $"{nameof(BindingSource.Current)}.{nameof(DisplaySprite.UseText)}");



            byte[] paldata = CFG.Properties.Resources.sprite;
            Color[][] palette = new Color[8][];
            for (int row = 0; row < 8; row++)
            {
                palette[row] = new Color[16];
                palette[row][0] = Color.Transparent;
                for (int col = 1; col < 8; col++)
                {
                    palette[row][col] = Color.FromArgb(
                        paldata[row * 8 * 3 + col * 3 + 0],
                        paldata[row * 8 * 3 + col * 3 + 1],
                        paldata[row * 8 * 3 + col * 3 + 2]
                        );
                }
                for (int col = 8; col < 16; col++)
                    palette[row][col] = Color.Black;
            }

            resources.Palette = palette;

            byte[] map16data = new byte[0x2000];
            Array.Copy(CFG.Properties.Resources.m16Page1_3, map16data, 0x1800);

            map16Editor1.Initialize(map16data, resources);
            txtTopLeft.Bind(map16Editor1, c => c.Text, e => e.SelectedObject.TopLeft, i => i.ToString("X2"), StringToInt);
            txtTopRight.Bind(map16Editor1, c => c.Text, e => e.SelectedObject.TopRight, i => i.ToString("X2"), StringToInt);
            txtBottomLeft.Bind(map16Editor1, c => c.Text, e => e.SelectedObject.BottomLeft, i => i.ToString("X2"), StringToInt);
            txtBottomRight.Bind(map16Editor1, c => c.Text, e => e.SelectedObject.BottomRight, i => i.ToString("X2"), StringToInt);
            cmbPalette.Bind(map16Editor1, c => c.SelectedIndex, e => e.SelectedObject.Palette);
            btnX.Click += (_, __) => map16Editor1.SelectedObject.FlipX();
            btnY.Click += (_, __) => map16Editor1.SelectedObject.FlipY();

            map16Editor1.SelectionChanged += (_, e) => pnlEdit.Enabled = e.Tile >= 0x300;
            Data.PropertyChanged += (_, e) =>
            {
                if (e.PropertyName == nameof(Data.CustomMap16Data))
                    map16Editor1.Map.ChangeData(Data.CustomMap16Data, 0x300);
            };

            spriteEditor1.Map16Editor = map16Editor1;
            spriteEditor1.Sprite = SelectedSprite;

            collectionSpriteBindingSource.DataSource = Data;
            collectionSpriteBindingSource.DataMember = nameof(Data.CollectionEntries);

            if (args.Length == 0)
				cmb_1656_0F.SelectedIndex = cmb_1662_3F.SelectedIndex = cmb_166E_0E.SelectedIndex = 0;
			else if (File.Exists(args[0]))
			{
				try
                {
                    LoadFile(args[0]);
                }
				catch (Exception ex)
				{
                    Data.Clear();
					Filename = "";
                    cmbType.SelectedItem = 0;
					MessageBox.Show("An error occured while trying to read the file.\n" + ex.Message, "Unexpected Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
				}
			}
			else
				MessageBox.Show("File: \"" + args[0] + "\" doesn't exist", "File not found", MessageBoxButtons.OK, MessageBoxIcon.Information);

#if DEBUG
            testToolStripMenuItem.Visible = true;
#endif

		}

        /// <summary>
        /// Testbutton on the menu. Only available in debug mode.
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>
        private void testToolStripMenuItem_Click(object sender, EventArgs e)
        {
        }

        #region Helper Methods

        /// <summary>
        /// Helper method for data binding. Converts a hex-string to byte. An empty string will be parsed as 0.
        /// </summary>
        /// <param name="str">The string containing two digits to be parsed</param>
        /// <returns></returns>
        private byte StringToByte(string str)
        {
            try
            {
                if (str.Length > 2)
                    str = str.Substring(0, 2);
                if (string.IsNullOrWhiteSpace(str))
                    return 0;
                return Convert.ToByte(str, 16);
            }
            catch
            {
                return 0;
            }
        }
        /// <summary>
        /// Helper method for data binding. Converts a hex-string to int. An empty string will be parsed as 0.
        /// </summary>
        /// <param name="str">The string containing two digits to be parsed</param>
        /// <returns></returns>
        private int StringToInt(string str)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(str))
                    return 0;
                return Convert.ToInt32(str, 16);
            }
            catch
            {
                return 0;
            }
        }

        /// <summary>
        /// Creats a new image based on the passed on with the given size, but the same ratio.
        /// </summary>
        /// <param name="size">The new desired size</param>
        /// <param name="img">The base image</param>
        /// <returns></returns>
        private Image ResizeImg(Size size, Image img)
        {
            float width, height;
            float x, y;

            if (img.Width < img.Height)
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

        /// <summary>
        /// Gives a warning if there are unsaved changes and asks the user if they want to continue.
        /// </summary>
        /// <returns><c>True</c> if they want to continue</returns>
        private bool UnsavedWarning()
        {
            if (Unsaved &&
                (MessageBox.Show("All unsaved changes will be lost. Proceed?", "Warning",
                MessageBoxButtons.OKCancel, MessageBoxIcon.Warning) == DialogResult.Cancel))
                return false;
            return true;
        }

        /// <summary>
        /// Method that sets up the binding for the CFGFile's byte property to the corresponding TextBoxes and CheckBoxes.
        /// This makes use of the fact that all TextBoxes are named txt_xxxx and all CheckBoxes are named chb_xxxx_bb.
        /// With xxxx being the address they represent and bb being the bit (in hex) that the checkbox controlls.
        /// </summary>
        /// <param name="file">The CFGFile object that is the DataSource</param>
        /// <param name="expr">The expression that selects the Property to bind to from the CFGFile</param>
        /// <param name="addr">The string representation of the address, used for searching through the controlls</param>
        /// <param name="start_bit">For the CheckBoxes, this indicates where to start</param>
		private void SetupBinding(CFGFile file, System.Linq.Expressions.Expression<Func<CFGFile, byte>> expr, string addr, int start_bit = 0)
		{
			TextBox txt = (TextBox)Controls.Find("txt_" + addr, true).FirstOrDefault();
			if (txt == null)
				return;
			txt.Bind(file, c => c.Text, expr, f => f.ToString("X2"), c => StringToByte(c));
			for(int i = start_bit; i < 8; i++)
			{
				CheckBox ch = (CheckBox)Controls.Find("chb_" + addr + "_" + (1 << i).ToString("X2"), true).FirstOrDefault();
				if (ch == null)
					continue;
				ch.BitBind(file, c => c.Checked, expr, i).DataSourceUpdateMode = DataSourceUpdateMode.OnPropertyChanged;
			}
		}

        private void SetDataSelectorGfx(FileSelector ds, int id)
        {
            string display = $"GFX{id.ToString("X2")}";

            if (ds.TextDisplay == display)
                return;

            ds.TextDisplay = display;
            ds.DataLoadHandler = () => GetGfxArray(id);
            ds_FileLoaded(ds, null);
        }

        private byte[] GetGfxArray(int id, int size = 0x1000)
        {
            byte[] ret = new byte[size];
            try
            {
                using (Stream str = System.Reflection.Assembly.GetExecutingAssembly().GetManifestResourceStream("CFG.Resources.Graphics.GFX" + id.ToString("X2") + ".bin"))
                {
                    str.Read(ret, 0, ret.Length);
                }
            }
            catch { }
            return ret;
        }

        #endregion
        
        public void LoadFile(string path)
        {
            if (!File.Exists(path))
                throw new FileNotFoundException($"\"{path}\" not found.");
            string ext = Path.GetExtension(path);
            switch(ext.ToLower())
            {
                case ".cfg":
                    FileType = FileType.CfgFile;
                    break;
                case ".smc":
                case ".sfc":
                    FileType = FileType.RomFile;
                    break;
                default:
                    throw new FormatException($"Uknown file extension {ext}");
            }


            if (FileType == FileType.CfgFile)
            {
                Data.FromLines(File.ReadAllText(path));
                cmbType.DataSource = types_list;
                cmbType.SelectedIndex = Data.Type;
                disabled_controlls.SetControllsEnabled(Data.Type != 0);
                grpActLike.Enabled = true;
                saveAsToolStripMenuItem.Enabled = true;
            }
            else if (FileType == FileType.RomFile)
            {
                RomData = File.ReadAllBytes(path);

                cmbType.DataSource = sprites_list;
                cmbType.SelectedIndex = 0;

                disabled_controlls.SetControllsEnabled(false);
                grpActLike.Enabled = false;
                saveAsToolStripMenuItem.Enabled = false;
            }

            Unsaved = false;
            Filename = path;
        }
        
        public void SaveFile(string path)
        {
            //update binding in case the current control is a textbox,
            //because these only write once they lose foucus, which might not have happened yet.
            var bindings = this.ActiveControl?.DataBindings;
            if (bindings != null && bindings.Count != 0)
                bindings[0].WriteValue();

            string ext = Path.GetExtension(path);
            switch (ext.ToLower())
            {
                case ".cfg":
                    File.WriteAllText(path, Data.ToLines());
                    break;
                case ".smc":
                case ".sfc":
                    Data.ToRomBytes(RomData, cmbType.SelectedIndex);
                    File.WriteAllBytes(path, RomData);
                    break;
                default:
                    MessageBox.Show($"Uknown file extension {ext}", "Couldn't save file", MessageBoxButtons.OK, MessageBoxIcon.Information);
                    return;
            }

            Unsaved = false;
            Filename = path;
        }

		#region Events
		private void cmb_1656_0F_SelectedIndexChanged(object sender, EventArgs e)
		{
			lblObjBroke.Visible = ((ComboBox)sender).SelectedIndex >= 0x0F;
			pcbObjClipping.Image = objClip[((ComboBox)sender).SelectedIndex];
		}
		private void cmb_1662_3F_SelectedIndexChanged(object sender, EventArgs e)
		{
			lblSprBroke.Visible = ((ComboBox)sender).SelectedIndex >= 0x3C;
			pcbSprClipping.Image = sprClip[((ComboBox)sender).SelectedIndex];
		}
		private void cmb_166E_0E_SelectedIndexChanged(object sender, EventArgs e)
		{
			int index = ((ComboBox)sender).SelectedIndex;
			if(index > 5)
				index += SpritePalette * 2;
			pcbPal.Image = sprPal[index];
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

        private void cmbType_SelectedIndexChanged(object sender, EventArgs e)
        {
            if (FileType == FileType.CfgFile)
            {
                Data.Type = (byte)((ComboBoxItem)cmbType.SelectedValue).Value;
                disabled_controlls.SetControllsEnabled(Data.Type != 0);
            }
            else if (FileType == FileType.RomFile)
            {
                Data.FromRomBytes(RomData, cmbType.SelectedIndex);
            }
        }
        #endregion

        #region "File" Menu Item Events
        private void newToolStripMenuItem_Click(object sender, EventArgs e)
        {
            if (!UnsavedWarning())
                return;

            Data.Clear();

            FileType = FileType.CfgFile;
            cmbType.DataSource = types_list;
            cmbType.SelectedIndex = 0;
            grpActLike.Enabled = true;
            saveAsToolStripMenuItem.Enabled = true;
            this.Filename = "";
            this.Unsaved = true;
		}

		private void loadToolStripMenuItem_Click(object sender, EventArgs e)
		{
			OpenFileDialog ofd = new OpenFileDialog();
			ofd.Filter = "CFG file|*.cfg|ROM file|*.smc;*.sfc";
			ofd.Title = "Load CFG file";
			if (ofd.ShowDialog() == System.Windows.Forms.DialogResult.Cancel)
				return;
			try
			{
				LoadFile(ofd.FileName);
			}
			catch (Exception ex)
			{
                Data.Clear();
				Filename = "";
				MessageBox.Show("An error occured while trying to read the CFG data\n" + ex.Message, "Unexpected Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
			}
		}

		private void saveAsToolStripMenuItem_Click(object sender, EventArgs e)
		{
            if (FileType == FileType.RomFile)
            {
                MessageBox.Show("You can't save a ROM under a different filename. Sorry about that.", "Error",
                    MessageBoxButtons.OK, MessageBoxIcon.Information);
                return;
            }

            SaveFileDialog sfd = new SaveFileDialog();
			sfd.Title = "Save CFG File";
            sfd.Filter = "CFG File|*.cfg";
			sfd.FileName = Filename;
			if (sfd.ShowDialog() == System.Windows.Forms.DialogResult.Cancel)
				return;

            try { SaveFile(sfd.FileName); }
            catch(Exception ex)
            {
                MessageBox.Show("An error occured while trying to write the CFG data\n" + ex.Message, "Unexpected Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
		}

		private void saveToolStripMenuItem_Click(object sender, EventArgs e)
		{
            if (Filename == "")
                saveAsToolStripMenuItem_Click(sender, e);
            else
            {
                try { SaveFile(Filename); }
                catch (Exception ex)
                {
                    MessageBox.Show("An error occured while trying to write the CFG data\n" + ex.Message, "Unexpected Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
                }
            }
		}
        #endregion

        private void ds_FileLoaded(object sender, EventArgs e)
        {
            var fs = ((FileSelector)sender);

            int offset = (int)fs.Tag;
            resources.Graphics.ChangeData(fs.Data, offset);
        }

        private void btnX_Click(object sender, EventArgs e)
        {
            map16Editor1.SelectedObject.FlipX();
        }

        private void toolStripMenuItem1_Click(object sender, EventArgs e)
        {
            var im = Image.FromStream(null, false, false);

            var p = new Editors.PaletteEditorForm(resources);
            p.ShowDialog();
        }
    }

    public class ComboBoxItem
    {
        public string Name { get; set; }
        public int Value { get; set; }
        public ComboBoxItem(string name, int value)
        {
            Name = name;
            Value = value;
        }
        public override string ToString() => Name;

        public override int GetHashCode() => Value;
        public override bool Equals(object obj)
        {
            if (ReferenceEquals(this, obj))
                return true;
            ComboBoxItem item = obj as ComboBoxItem;
            if (ReferenceEquals(item, null))
                return false;
            return this.Value == item.Value;
        }

        public static ComboBoxItem Reference(int value) => new ComboBoxItem("", value);
    }

    public class SpriteTileset
    {
        public string Name { get; set; }
        public int Sp1 { get; set; } = 0;
        public int Sp2 { get; set; } = 1;
        public int Sp3 { get; set; }
        public int Sp4 { get; set; }

        public SpriteTileset(int sp3, int sp4, string name)
        {
            Sp3 = sp3;
            Sp4 = sp4;
            Name = name;
        }

        public override string ToString()
        {
            return $"{Sp1.ToString("X2")} {Sp2.ToString("X2")} {Sp3.ToString("X2")} {Sp4.ToString("X2")} ({Name})";
        }
    }
}
