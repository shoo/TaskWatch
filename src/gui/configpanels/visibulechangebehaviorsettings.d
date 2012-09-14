﻿/*
	Generated by Entice Designer
	Entice Designer written by Christopher E. Miller
	www.dprogramming.com/entice.php
*/
module src.gui.configpanels.visibulechangebehaviorsettings;

import dfl.all;

import src.gui.configpanels.base, src.sys.config;

class VisibleChangeBehaviorSettings: src.gui.configpanels.base.ConfigPanel
{
	// Do not modify or move this block of variables.
	//~Entice Designer variables begin here.
	dfl.button.CheckBox chkStopInterruptWithBackground;
	dfl.button.CheckBox chkStartInterruptWithForeground;
	//~Entice Designer variables end here.
	
	
	/***************************************************************************
	 * 
	 */
	override void applyConfig(ref Config cfg)
	{
		cfg.stopInterruptWithBackground  = chkStopInterruptWithBackground.checked;
		cfg.startInterruptWithForeground = chkStartInterruptWithForeground.checked;
	}
	
	
	/***************************************************************************
	 * 
	 */
	override void loadConfig(in ref Config cfg)
	{
		chkStopInterruptWithBackground.checked  = cfg.stopInterruptWithBackground;
		chkStartInterruptWithForeground.checked = cfg.startInterruptWithForeground;
	}
	
	
	/***************************************************************************
	 * 
	 */
	this()
	{
		initializeVisibleChangeBehaviorSettings();
		
		//@  Other VisibleChangeBehaviorSettings initialization code here.
		
	}
	
	
	private void initializeVisibleChangeBehaviorSettings()
	{
		// Do not manually modify this function.
		//~Entice Designer 0.8.5.02 code begins here.
		//~DFL Panel
		name = "VisibleChangeBehaviorSettings";
		bounds = dfl.all.Rect(0, 0, 296, 272);
		//~DFL dfl.button.CheckBox=chkStopInterruptWithBackground
		chkStopInterruptWithBackground = new dfl.button.CheckBox();
		chkStopInterruptWithBackground.name = "chkStopInterruptWithBackground";
		chkStopInterruptWithBackground.dock = dfl.all.DockStyle.TOP;
		chkStopInterruptWithBackground.text = "バックグラウンド化と同時に割り込み解除";
		chkStopInterruptWithBackground.bounds = dfl.all.Rect(0, 0, 296, 23);
		chkStopInterruptWithBackground.parent = this;
		//~DFL dfl.button.CheckBox=chkStartInterruptWithForeground
		chkStartInterruptWithForeground = new dfl.button.CheckBox();
		chkStartInterruptWithForeground.name = "chkStartInterruptWithForeground";
		chkStartInterruptWithForeground.dock = dfl.all.DockStyle.TOP;
		chkStartInterruptWithForeground.text = "フォアグラウンド化と同時に割り込み開始";
		chkStartInterruptWithForeground.bounds = dfl.all.Rect(0, 23, 296, 23);
		chkStartInterruptWithForeground.parent = this;
		//~Entice Designer 0.8.5.02 code ends here.
	}
}

