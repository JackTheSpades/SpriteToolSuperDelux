namespace CFG.Editors
{
    partial class PaletteEditorForm
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
            pcbDisplay = new System.Windows.Forms.PictureBox();
            comboBox1 = new System.Windows.Forms.ComboBox();
            btnLoad = new System.Windows.Forms.Button();
            ((System.ComponentModel.ISupportInitialize)pcbDisplay).BeginInit();
            SuspendLayout();
            // 
            // pcbDisplay
            // 
            pcbDisplay.BackColor = System.Drawing.Color.Black;
            pcbDisplay.Location = new System.Drawing.Point(14, 14);
            pcbDisplay.Margin = new System.Windows.Forms.Padding(4, 3, 4, 3);
            pcbDisplay.Name = "pcbDisplay";
            pcbDisplay.Size = new System.Drawing.Size(299, 148);
            pcbDisplay.TabIndex = 0;
            pcbDisplay.TabStop = false;
            pcbDisplay.MouseDown += PcbDisplay_MouseDown;
            // 
            // comboBox1
            // 
            comboBox1.FormattingEnabled = true;
            comboBox1.Location = new System.Drawing.Point(108, 168);
            comboBox1.Margin = new System.Windows.Forms.Padding(4, 3, 4, 3);
            comboBox1.Name = "comboBox1";
            comboBox1.Size = new System.Drawing.Size(126, 23);
            comboBox1.TabIndex = 1;
            // 
            // btnLoad
            // 
            btnLoad.Location = new System.Drawing.Point(14, 168);
            btnLoad.Margin = new System.Windows.Forms.Padding(4, 3, 4, 3);
            btnLoad.Name = "btnLoad";
            btnLoad.Size = new System.Drawing.Size(88, 24);
            btnLoad.TabIndex = 2;
            btnLoad.Text = "Load";
            btnLoad.UseVisualStyleBackColor = true;
            btnLoad.Click += BtnLoad_Click;
            // 
            // PaletteEditorForm
            // 
            AutoScaleDimensions = new System.Drawing.SizeF(7F, 15F);
            AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            ClientSize = new System.Drawing.Size(334, 208);
            Controls.Add(btnLoad);
            Controls.Add(comboBox1);
            Controls.Add(pcbDisplay);
            FormBorderStyle = System.Windows.Forms.FormBorderStyle.FixedToolWindow;
            Margin = new System.Windows.Forms.Padding(4, 3, 4, 3);
            Name = "PaletteEditorForm";
            Text = "Palette";
            ((System.ComponentModel.ISupportInitialize)pcbDisplay).EndInit();
            ResumeLayout(false);
        }

        #endregion

        private System.Windows.Forms.PictureBox pcbDisplay;
        private System.Windows.Forms.ComboBox comboBox1;
        private System.Windows.Forms.Button btnLoad;
    }
}