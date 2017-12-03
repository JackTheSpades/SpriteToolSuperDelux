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
            this.rtbDisplayText = new System.Windows.Forms.RichTextBox();
            this.pcbSprite = new System.Windows.Forms.PictureBox();
            ((System.ComponentModel.ISupportInitialize)(this.pcbSprite)).BeginInit();
            this.SuspendLayout();
            // 
            // rtbDisplayText
            // 
            this.rtbDisplayText.Location = new System.Drawing.Point(0, 118);
            this.rtbDisplayText.Name = "rtbDisplayText";
            this.rtbDisplayText.Size = new System.Drawing.Size(176, 58);
            this.rtbDisplayText.TabIndex = 19;
            this.rtbDisplayText.Text = "";
            this.rtbDisplayText.Visible = false;
            this.rtbDisplayText.WordWrap = false;
            // 
            // pcbSprite
            // 
            this.pcbSprite.Location = new System.Drawing.Point(0, 0);
            this.pcbSprite.Name = "pcbSprite";
            this.pcbSprite.Size = new System.Drawing.Size(176, 176);
            this.pcbSprite.TabIndex = 16;
            this.pcbSprite.TabStop = false;
            this.pcbSprite.MouseDown += new System.Windows.Forms.MouseEventHandler(this.pcbSprite_MouseDown);
            this.pcbSprite.MouseEnter += new System.EventHandler(this.pcbSprite_MouseEnter);
            this.pcbSprite.MouseMove += new System.Windows.Forms.MouseEventHandler(this.pcbSprite_MouseMove);
            // 
            // SpriteEditor
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.Controls.Add(this.rtbDisplayText);
            this.Controls.Add(this.pcbSprite);
            this.Name = "SpriteEditor";
            this.Size = new System.Drawing.Size(176, 176);
            ((System.ComponentModel.ISupportInitialize)(this.pcbSprite)).EndInit();
            this.ResumeLayout(false);

        }

        #endregion

        private System.Windows.Forms.RichTextBox rtbDisplayText;
        private System.Windows.Forms.PictureBox pcbSprite;
    }
}
