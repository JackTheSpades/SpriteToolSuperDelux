namespace CFG
{
    partial class Map16Editor
    {
        /// <summary> 
        /// Required designer variable.
        /// </summary>
        private System.ComponentModel.IContainer components = null;

        /// <summary> 
        /// Clean up any resources being used.
        /// </summary>
        /// <param name="disposing">true if managed resources should be disposed; otherwise, false.</param>
        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
            {
                components.Dispose();
            }
            base.Dispose(disposing);
        }

        #region Component Designer generated code

        /// <summary> 
        /// Required method for Designer support - do not modify 
        /// the contents of this method with the code editor.
        /// </summary>
        private void InitializeComponent()
        {
            this.components = new System.ComponentModel.Container();
            this.vScrollBar = new System.Windows.Forms.VScrollBar();
            this.pcbMap16 = new System.Windows.Forms.PictureBox();
            this.timer1 = new System.Windows.Forms.Timer(this.components);
            ((System.ComponentModel.ISupportInitialize)(this.pcbMap16)).BeginInit();
            this.SuspendLayout();
            // 
            // vScrollBar
            // 
            this.vScrollBar.Location = new System.Drawing.Point(259, 0);
            this.vScrollBar.Maximum = 57;
            this.vScrollBar.Name = "vScrollBar";
            this.vScrollBar.Size = new System.Drawing.Size(17, 256);
            this.vScrollBar.TabIndex = 7;
            this.vScrollBar.ValueChanged += new System.EventHandler(this.vScrollBar_ValueChanged);
            // 
            // pcbMap16
            // 
            this.pcbMap16.Location = new System.Drawing.Point(0, 0);
            this.pcbMap16.Name = "pcbMap16";
            this.pcbMap16.Size = new System.Drawing.Size(256, 256);
            this.pcbMap16.TabIndex = 6;
            this.pcbMap16.TabStop = false;
            this.pcbMap16.MouseClick += new System.Windows.Forms.MouseEventHandler(this.pcbMap16_MouseClick);
            this.pcbMap16.MouseEnter += new System.EventHandler(this.pcbMap16_MouseEnter);
            this.pcbMap16.MouseMove += new System.Windows.Forms.MouseEventHandler(this.pcbMap16_MouseMove);
            // 
            // timer1
            // 
            this.timer1.Tick += new System.EventHandler(this.timer1_Tick);
            // 
            // Map16Editor
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.Controls.Add(this.vScrollBar);
            this.Controls.Add(this.pcbMap16);
            this.Name = "Map16Editor";
            this.Size = new System.Drawing.Size(278, 256);
            ((System.ComponentModel.ISupportInitialize)(this.pcbMap16)).EndInit();
            this.ResumeLayout(false);

        }

        #endregion

        private System.Windows.Forms.VScrollBar vScrollBar;
        private System.Windows.Forms.PictureBox pcbMap16;
        private System.Windows.Forms.Timer timer1;
    }
}
