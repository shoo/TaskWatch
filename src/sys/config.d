module src.sys.config;

import std.json;
import src.misc.jsonhelper;

/*******************************************************************************
 * 
 */
struct Config
{
	/***************************************************************************
	 * 
	 */
	string fmtCopyForInterrupt;
	
	
	/***************************************************************************
	 * 
	 */
	string fmtCopyForTask;
	
	
	/***************************************************************************
	 * 
	 */
	bool stopInterruptWithBackground;
	
	
	/***************************************************************************
	 * 
	 */
	bool startInterruptWithForeground;
	
	
	/***************************************************************************
	 * 
	 */
	JSONValue toJson() const
	{
		JSONValue json;
		json.type = JSON_TYPE.OBJECT;
		
		json.setValue("fmtCopyForInterrupt",          fmtCopyForInterrupt);
		json.setValue("fmtCopyForTask",               fmtCopyForTask);
		json.setValue("stopInterruptWithBackground",  stopInterruptWithBackground);
		json.setValue("startInterruptWithForeground", startInterruptWithForeground);
		
		return json;
	}
	
	/***************************************************************************
	 * 
	 */
	void fromJson(JSONValue json)
	{
		fmtCopyForInterrupt          = json.getValue("fmtCopyForInterrupt",          "");
		fmtCopyForTask               = json.getValue("fmtCopyForTask",               "");
		stopInterruptWithBackground  = json.getValue("startInterruptWithForeground", false);
		startInterruptWithForeground = json.getValue("startInterruptWithForeground", false);
	}
}
