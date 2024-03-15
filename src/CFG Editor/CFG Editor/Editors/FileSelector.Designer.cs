namespace CFG.Map16
{
    partial class FileSelector
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
            splitContainer1 = new System.Windows.Forms.SplitContainer();
            txtName = new System.Windows.Forms.TextBox();
            btnButton = new System.Windows.Forms.Button();
            ((System.ComponentModel.ISupportInitialize)splitContainer1).BeginInit();
            splitContainer1.Panel1.SuspendLayout();
            splitContainer1.Panel2.SuspendLayout();
            splitContainer1.SuspendLayout();
            SuspendLayout();
            // 
            // splitContainer1
            // 
            splitContainer1.Dock = System.Windows.Forms.DockStyle.Fill;
            splitContainer1.FixedPanel = System.Windows.Forms.FixedPanel.Panel2;
            splitContainer1.Location = new System.Drawing.Point(0, 0);
            splitContainer1.Margin = new System.Windows.Forms.Padding(4, 3, 4, 3);
            splitContainer1.Name = "splitContainer1";
            // 
            // splitContainer1.Panel1
            // 
            splitContainer1.Panel1.Controls.Add(txtName);
            // 
            // splitContainer1.Panel2
            // 
            splitContainer1.Panel2.Controls.Add(btnButton);
            splitContainer1.Size = new System.Drawing.Size(161, 24);
            splitContainer1.SplitterDistance = 127;
            splitContainer1.SplitterWidth = 5;
            splitContainer1.TabIndex = 0;
            // 
            // txtName
            // 
            txtName.Dock = System.Windows.Forms.DockStyle.Top;
            txtName.Location = new System.Drawing.Point(0, 0);
            txtName.Margin = new System.Windows.Forms.Padding(4, 3, 4, 3);
            txtName.Name = "txtName";
            txtName.Size = new System.Drawing.Size(127, 23);
            txtName.TabIndex = 0;
            // 
            // btnButton
            // 
            btnButton.Dock = System.Windows.Forms.DockStyle.Top;
            btnButton.Location = new System.Drawing.Point(0, 0);
            btnButton.Margin = new System.Windows.Forms.Padding(4, 3, 4, 3);
            btnButton.Name = "btnButton";
            btnButton.Size = new System.Drawing.Size(29, 23);
            btnButton.TabIndex = 0;
            btnButton.Text = "...";
            btnButton.UseVisualStyleBackColor = true;
            btnButton.Click += BtnButton_Click;
            // 
            // FileSelector
            // 
            AutoScaleDimensions = new System.Drawing.SizeF(7F, 15F);
            AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            Controls.Add(splitContainer1);
            Margin = new System.Windows.Forms.Padding(4, 3, 4, 3);
            Name = "FileSelector";
            Size = new System.Drawing.Size(161, 24);
            splitContainer1.Panel1.ResumeLayout(false);
            splitContainer1.Panel1.PerformLayout();
            splitContainer1.Panel2.ResumeLayout(false);
            ((System.ComponentModel.ISupportInitialize)splitContainer1).EndInit();
            splitContainer1.ResumeLayout(false);
            ResumeLayout(false);
        }

        #endregion

        private System.Windows.Forms.SplitContainer splitContainer1;
        private System.Windows.Forms.TextBox txtName;
        private System.Windows.Forms.Button btnButton;
    }
}
