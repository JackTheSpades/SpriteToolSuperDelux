namespace CFG.Editors
{
    partial class Tile8x8EditorForm
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

        #region Windows Form Designer generated code

        /// <summary>
        /// Required method for Designer support - do not modify
        /// the contents of this method with the code editor.
        /// </summary>
        private void InitializeComponent()
        {
            statusStrip1 = new System.Windows.Forms.StatusStrip();
            toolStripStatusLabel1 = new System.Windows.Forms.ToolStripStatusLabel();
            toolStripStatusLabel2 = new System.Windows.Forms.ToolStripStatusLabel();
            pcb = new System.Windows.Forms.PictureBox();
            vScrollBar1 = new System.Windows.Forms.VScrollBar();
            statusStrip1.SuspendLayout();
            ((System.ComponentModel.ISupportInitialize)pcb).BeginInit();
            SuspendLayout();
            // 
            // statusStrip1
            // 
            statusStrip1.Items.AddRange(new System.Windows.Forms.ToolStripItem[] { toolStripStatusLabel1, toolStripStatusLabel2 });
            statusStrip1.Location = new System.Drawing.Point(0, 300);
            statusStrip1.Name = "statusStrip1";
            statusStrip1.Padding = new System.Windows.Forms.Padding(1, 0, 16, 0);
            statusStrip1.Size = new System.Drawing.Size(318, 22);
            statusStrip1.TabIndex = 0;
            statusStrip1.Text = "statusStrip1";
            // 
            // toolStripStatusLabel1
            // 
            toolStripStatusLabel1.BorderStyle = System.Windows.Forms.Border3DStyle.SunkenOuter;
            toolStripStatusLabel1.Name = "toolStripStatusLabel1";
            toolStripStatusLabel1.Size = new System.Drawing.Size(25, 17);
            toolStripStatusLabel1.Text = "Tile";
            // 
            // toolStripStatusLabel2
            // 
            toolStripStatusLabel2.Name = "toolStripStatusLabel2";
            toolStripStatusLabel2.Size = new System.Drawing.Size(43, 17);
            toolStripStatusLabel2.Text = "Palette";
            // 
            // pcb
            // 
            pcb.Location = new System.Drawing.Point(0, 0);
            pcb.Margin = new System.Windows.Forms.Padding(4, 3, 4, 3);
            pcb.Name = "pcb";
            pcb.Size = new System.Drawing.Size(299, 295);
            pcb.SizeMode = System.Windows.Forms.PictureBoxSizeMode.Zoom;
            pcb.TabIndex = 1;
            pcb.TabStop = false;
            pcb.MouseClick += Pcb_MouseClick;
            pcb.MouseMove += Pcb_MouseMove;
            // 
            // vScrollBar1
            // 
            vScrollBar1.Dock = System.Windows.Forms.DockStyle.Right;
            vScrollBar1.LargeChange = 2;
            vScrollBar1.Location = new System.Drawing.Point(301, 0);
            vScrollBar1.Maximum = 2;
            vScrollBar1.Name = "vScrollBar1";
            vScrollBar1.Size = new System.Drawing.Size(17, 300);
            vScrollBar1.TabIndex = 2;
            // 
            // Tile8x8EditorForm
            // 
            AutoScaleDimensions = new System.Drawing.SizeF(7F, 15F);
            AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            ClientSize = new System.Drawing.Size(318, 322);
            Controls.Add(vScrollBar1);
            Controls.Add(pcb);
            Controls.Add(statusStrip1);
            FormBorderStyle = System.Windows.Forms.FormBorderStyle.FixedToolWindow;
            Margin = new System.Windows.Forms.Padding(4, 3, 4, 3);
            Name = "Tile8x8EditorForm";
            Text = "8x8 Tile Editor";
            statusStrip1.ResumeLayout(false);
            statusStrip1.PerformLayout();
            ((System.ComponentModel.ISupportInitialize)pcb).EndInit();
            ResumeLayout(false);
            PerformLayout();
        }

        #endregion

        private System.Windows.Forms.StatusStrip statusStrip1;
        private System.Windows.Forms.PictureBox pcb;
        private System.Windows.Forms.VScrollBar vScrollBar1;
        private System.Windows.Forms.ToolStripStatusLabel toolStripStatusLabel1;
        private System.Windows.Forms.ToolStripStatusLabel toolStripStatusLabel2;
    }
}