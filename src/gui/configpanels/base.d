module src.gui.configpanels.base;

import dfl.all;
import src.sys.config;

/*******************************************************************************
 * 設定用パネル
 */
abstract class ConfigPanel: Panel
{
	/***************************************************************************
	 * 
	 */
	void applyConfig(ref Config cfg);
	
	
	/***************************************************************************
	 * 
	 */
	void loadConfig(in ref Config cfg);
}