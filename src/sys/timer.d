module src.sys.timer;

import core.time;
static import dfl.timer;
import dfl.all;
import voile.misc;

/*******************************************************************************
 * 
 */
class Timer
{
private:
	Unique!(dfl.timer.Timer)  _timer;
	bool                      _running = false;
public:
	/***************************************************************************
	 * 
	 */
	Handler!(void delegate()) onTimer;
	
	
	/***************************************************************************
	 * 
	 */
	this()
	{
		_timer = unique!(dfl.timer.Timer)();
		_timer.tick ~= (dfl.timer.Timer tm, EventArgs e)
		{
			onTimer();
		};
	}
	
	
	/***************************************************************************
	 * 
	 */
	void interval(Duration dur) @property
	{
		_timer.interval = cast(size_t)dur.total!"msecs"();
	}
	
	
	/***************************************************************************
	 * 
	 */
	Duration interval() @property
	{
		return core.time.dur!"msecs"(_timer.interval);
	}
	
	
	/***************************************************************************
	 * 
	 */
	void start()
	{
		_timer.start();
		_running = true;
	}
	
	
	/***************************************************************************
	 * 
	 */
	void stop()
	{
		_timer.stop();
		_running = false;
	}
	~this()
	{
		_timer.stop();
		_running = false;
	}
	
	
	/***************************************************************************
	 * 
	 */
	bool running() @property inout
	{
		return _running;
	}
}
