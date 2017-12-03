using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Drawing;
using System.Data;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;
using System.IO;

namespace CFG.Map16
{
    public delegate byte[] DataLoadHandler();

    public partial class FileSelector : UserControl
    {
        public byte[] Data { get { return DataLoadHandler?.Invoke(); } }
        
        [DefaultValue(null)]
        public DataLoadHandler DataLoadHandler { get; set; }
        [DefaultValue(null)]
        public OpenFileDialog FileDialog { get; set; }
        
        [DefaultValue("")]
        public string TextDisplay
        {
            get { return txtName.Text; }
            set { txtName.Text = value; }
        }

        public event EventHandler FileLoaded;

        public FileSelector()
        {
            InitializeComponent();

            FileDialog = new OpenFileDialog();
            FileDialog.Filter = "All files|*.*|Binary files|*.bin";
            FileDialog.Title = "Select File";
        }

        private void btnButton_Click(object sender, EventArgs e)
        {
            if (FileDialog.ShowDialog() != DialogResult.OK)
                return;

            TextDisplay = Path.GetFileName(FileDialog.FileName);
            DataLoadHandler = () => File.ReadAllBytes(FileDialog.FileName);
            FileLoaded?.Invoke(this, new EventArgs());
        }
    }
}
