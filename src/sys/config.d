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
	JSONValue toJson() const
	{
		JSONValue json;
		json.type = JSON_TYPE.OBJECT;
		
		json.setValue("fmtCopyForInterrupt", fmtCopyForInterrupt);
		json.setValue("fmtCopyForTask",      fmtCopyForTask);
		
		return json;
	}
	
	/***************************************************************************
	 * 
	 */
	void fromJson(JSONValue json)
	{
		fmtCopyForInterrupt = json.getValue("fmtCopyForInterrupt", "");
		fmtCopyForTask      = json.getValue("fmtCopyForTask",      "");
	}
}
