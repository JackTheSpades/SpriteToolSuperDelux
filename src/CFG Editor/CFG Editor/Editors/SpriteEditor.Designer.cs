namespace CFG.Map16
{
    partial class SpriteEditor
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
            rtbDisplayText = new System.Windows.Forms.RichTextBox();
            pcbSprite = new System.Windows.Forms.PictureBox();
            ((System.ComponentModel.ISupportInitialize)pcbSprite).BeginInit();
            SuspendLayout();
            // 
            // rtbDisplayText
            // 
            rtbDisplayText.Location = new System.Drawing.Point(0, 136);
            rtbDisplayText.Margin = new System.Windows.Forms.Padding(4, 3, 4, 3);
            rtbDisplayText.Name = "rtbDisplayText";
            rtbDisplayText.Size = new System.Drawing.Size(205, 66);
            rtbDisplayText.TabIndex = 19;
            rtbDisplayText.Text = "";
            rtbDisplayText.Visible = false;
            rtbDisplayText.WordWrap = false;
            // 
            // pcbSprite
            // 
            pcbSprite.Location = new System.Drawing.Point(0, 0);
            pcbSprite.Margin = new System.Windows.Forms.Padding(4, 3, 4, 3);
            pcbSprite.Name = "pcbSprite";
            pcbSprite.Size = new System.Drawing.Size(205, 203);
            pcbSprite.TabIndex = 16;
            pcbSprite.TabStop = false;
            pcbSprite.MouseDown += PcbSprite_MouseDown;
            pcbSprite.MouseEnter += PcbSprite_MouseEnter;
            pcbSprite.MouseMove += PcbSprite_MouseMove;
            // 
            // SpriteEditor
            // 
            AutoScaleDimensions = new System.Drawing.SizeF(7F, 15F);
            AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            Controls.Add(rtbDisplayText);
            Controls.Add(pcbSprite);
            Margin = new System.Windows.Forms.Padding(4, 3, 4, 3);
            Name = "SpriteEditor";
            Size = new System.Drawing.Size(205, 203);
            ((System.ComponentModel.ISupportInitialize)pcbSprite).EndInit();
            ResumeLayout(false);
        }

        #endregion

        private System.Windows.Forms.RichTextBox rtbDisplayText;
        private System.Windows.Forms.PictureBox pcbSprite;
    }
}
