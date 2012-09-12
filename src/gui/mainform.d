/*
	Generated by Entice Designer
	Entice Designer written by Christopher E. Miller
	www.dprogramming.com/entice.php
*/
module src.gui.mainform;
import dfl.all;


class MainForm: dfl.form.Form
{
	// Do not modify or move this block of variables.
	//~Entice Designer variables begin here.
	dfl.panel.Panel pnlInterrupt;
	dfl.button.CheckBox chkToggle;
	dfl.textbox.TextBox txtDurInterrupt;
	dfl.button.Button btnCopy;
	dfl.panel.Panel spacer2;
	dfl.button.Button btnReset;
	dfl.panel.Panel panel1;
	dfl.button.Button btnAdd;
	dfl.groupbox.GroupBox grpTasks;
	dfl.panel.Panel taskPanels;
	//~Entice Designer variables end here.
	
	
	this()
	{
		initializeMainForm();
		
		//@  Other MainForm initialization code here.
		with (pnlInterrupt.dockPadding)
		{
			left   = 15+16;
			top    = 4;
			right  = 15;
			bottom = 4;
		}
		txtDurInterrupt.font = new dfl.all.Font(txtDurInterrupt.font.name, 14f, dfl.all.FontStyle.REGULAR);
		chkToggle.textAlign = ContentAlignment.MIDDLE_CENTER;
		chkToggle.click ~= (Control c, EventArgs e)
		{
			if (chkToggle.checked)
			{
				chkToggle.text = "Stop";
			}
			else
			{
				chkToggle.text = "Run";
			}
		};
	}
	
	
	private void initializeMainForm()
	{
		// Do not manually modify this function.
		//~Entice Designer 0.8.5.02 code begins here.
		//~DFL Form
		text = "My Form";
		clientSize = dfl.all.Size(424, 254);
		//~DFL dfl.panel.Panel=pnlInterrupt
		pnlInterrupt = new dfl.panel.Panel();
		pnlInterrupt.name = "pnlInterrupt";
		pnlInterrupt.dock = dfl.all.DockStyle.TOP;
		pnlInterrupt.bounds = dfl.all.Rect(0, 0, 424, 40);
		pnlInterrupt.parent = this;
		//~DFL dfl.button.CheckBox=chkToggle
		chkToggle = new dfl.button.CheckBox();
		chkToggle.name = "chkToggle";
		chkToggle.dock = dfl.all.DockStyle.LEFT;
		chkToggle.text = "Run";
		chkToggle.appearance = dfl.all.Appearance.BUTTON;
		chkToggle.bounds = dfl.all.Rect(0, 0, 64, 40);
		chkToggle.parent = pnlInterrupt;
		//~DFL dfl.textbox.TextBox=txtDurInterrupt
		txtDurInterrupt = new dfl.textbox.TextBox();
		txtDurInterrupt.name = "txtDurInterrupt";
		txtDurInterrupt.dock = dfl.all.DockStyle.LEFT;
		txtDurInterrupt.bounds = dfl.all.Rect(64, 0, 128, 40);
		txtDurInterrupt.parent = pnlInterrupt;
		//~DFL dfl.button.Button=btnCopy
		btnCopy = new dfl.button.Button();
		btnCopy.name = "btnCopy";
		btnCopy.dock = dfl.all.DockStyle.LEFT;
		btnCopy.text = "Copy";
		btnCopy.bounds = dfl.all.Rect(192, 0, 48, 40);
		btnCopy.parent = pnlInterrupt;
		//~DFL dfl.panel.Panel=spacer2
		spacer2 = new dfl.panel.Panel();
		spacer2.name = "spacer2";
		spacer2.dock = dfl.all.DockStyle.LEFT;
		spacer2.bounds = dfl.all.Rect(240, 0, 16, 40);
		spacer2.parent = pnlInterrupt;
		//~DFL dfl.button.Button=btnReset
		btnReset = new dfl.button.Button();
		btnReset.name = "btnReset";
		btnReset.dock = dfl.all.DockStyle.LEFT;
		btnReset.text = "Reset";
		btnReset.bounds = dfl.all.Rect(256, 0, 48, 40);
		btnReset.parent = pnlInterrupt;
		//~DFL dfl.panel.Panel=panel1
		panel1 = new dfl.panel.Panel();
		panel1.name = "panel1";
		panel1.dock = dfl.all.DockStyle.LEFT;
		panel1.bounds = dfl.all.Rect(304, 0, 16, 40);
		panel1.parent = pnlInterrupt;
		//~DFL dfl.button.Button=btnAdd
		btnAdd = new dfl.button.Button();
		btnAdd.name = "btnAdd";
		btnAdd.dock = dfl.all.DockStyle.LEFT;
		btnAdd.text = "Add";
		btnAdd.bounds = dfl.all.Rect(320, 0, 48, 40);
		btnAdd.parent = pnlInterrupt;
		//~DFL dfl.groupbox.GroupBox=grpTasks
		grpTasks = new dfl.groupbox.GroupBox();
		grpTasks.name = "grpTasks";
		grpTasks.dock = dfl.all.DockStyle.FILL;
		grpTasks.text = "Tasks";
		grpTasks.bounds = dfl.all.Rect(0, 40, 424, 214);
		grpTasks.parent = this;
		//~DFL dfl.panel.Panel=taskPanels
		taskPanels = new dfl.panel.Panel();
		taskPanels.name = "taskPanels";
		taskPanels.dock = dfl.all.DockStyle.FILL;
		taskPanels.bounds = dfl.all.Rect(4, 16, 416, 194);
		taskPanels.parent = grpTasks;
		//~Entice Designer 0.8.5.02 code ends here.
	}
}
