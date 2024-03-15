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
            components = new System.ComponentModel.Container();
            vScrollBar = new System.Windows.Forms.VScrollBar();
            pcbMap16 = new System.Windows.Forms.PictureBox();
            timer1 = new System.Windows.Forms.Timer(components);
            ((System.ComponentModel.ISupportInitialize)pcbMap16).BeginInit();
            SuspendLayout();
            // 
            // vScrollBar
            // 
            vScrollBar.Location = new System.Drawing.Point(302, 0);
            vScrollBar.Maximum = 57;
            vScrollBar.Name = "vScrollBar";
            vScrollBar.Size = new System.Drawing.Size(17, 295);
            vScrollBar.TabIndex = 7;
            vScrollBar.ValueChanged += VScrollBar_ValueChanged;
            // 
            // pcbMap16
            // 
            pcbMap16.Location = new System.Drawing.Point(0, 0);
            pcbMap16.Margin = new System.Windows.Forms.Padding(4, 3, 4, 3);
            pcbMap16.Name = "pcbMap16";
            pcbMap16.Size = new System.Drawing.Size(299, 295);
            pcbMap16.TabIndex = 6;
            pcbMap16.TabStop = false;
            pcbMap16.MouseClick += PcbMap16_MouseClick;
            pcbMap16.MouseEnter += PcbMap16_MouseEnter;
            pcbMap16.MouseMove += PcbMap16_MouseMove;
            // 
            // timer1
            // 
            timer1.Tick += Timer1_Tick;
            // 
            // Map16Editor
            // 
            AutoScaleDimensions = new System.Drawing.SizeF(7F, 15F);
            AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            Controls.Add(vScrollBar);
            Controls.Add(pcbMap16);
            Margin = new System.Windows.Forms.Padding(4, 3, 4, 3);
            Name = "Map16Editor";
            Size = new System.Drawing.Size(324, 295);
            ((System.ComponentModel.ISupportInitialize)pcbMap16).EndInit();
            ResumeLayout(false);
        }

        #endregion

        private System.Windows.Forms.VScrollBar vScrollBar;
        private System.Windows.Forms.PictureBox pcbMap16;
        private System.Windows.Forms.Timer timer1;
    }
}
