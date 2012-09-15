module src.sys.task;

import core.time;
import std.datetime, std.json;
import src.common;
import src.misc.jsonhelper;


/*******************************************************************************
 * 
 */
struct Task
{
	/***************************************************************************
	 * 
	 */
	string name;
	
	
	/***************************************************************************
	 * 
	 */
	StopWatch stopwatch;
	
	
	/***************************************************************************
	 * 
	 */
	bool enabled;
	
	
	/***************************************************************************
	 * 
	 */
	SysTime startTime;
	
	/***************************************************************************
	 * 
	 */
	JSONValue toJson() @property inout
	{
		JSONValue json;
		json.type = JSON_TYPE.OBJECT;
		
		json.setValue("name", name);
		json.setValue("stopwatch", stopwatch.peek().usecs);
		json.setValue("enabled",   enabled);
		json.setValue("startTime", startTime.toISOExtString());
		
		return json;
	}
	
	/// ditto
	void fromJson(in JSONValue json)
	{
		name = json.getValue("name", name);
		auto d = TickDuration.from!"usecs"(json.getValue("stopwatch", 0UL));
		stopwatch.setMeasured(d);
		enabled = json.getValue("enabled", enabled);
		if (auto str = json.getValue("startTime", string.init))
			startTime = SysTime.fromISOExtString(str);
	}
	
}
