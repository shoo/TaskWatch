module src.app;

import core.time;
import std.datetime, std.array;
import src.common, src.features;
import src.ui, src.sys.timer, src.sys.task, src.sys.config;


/*******************************************************************************
 * 
 */
shared class CommInstance: CommInterface
{
	shared AppInterface _app;
	
	this(AppInterface app)
	{
		_app = cast(shared)app;
		
	}
	
	void command(in string[] cmds)
	{
		(cast()_app).command(cmds);
	}
}


/*******************************************************************************
 * 
 */
class AppInstance: AppInterface
{
private:
	string[] _args;
	shared CommInterface _comm;
	shared UserInterface _ui;
	
	StopWatch            _interruptStopWatch;
	Task[]               _tasks;
	size_t               _activeTaskIndex;
	Timer                _timer;
	
	invariant()
	{
		assert(_activeTaskIndex == 0 || _activeTaskIndex < _tasks.length);
	}
	
	/***************************************************************************
	 * 割り込み時間用ストップウォッチ制御
	 */
	void startInterruptStopWatch()
	{
		if (!_interruptStopWatch.running)
			_interruptStopWatch.start();
		
		if (_tasks.length == 0)
			return;
		
		if (_tasks[_activeTaskIndex].stopwatch.running)
		{
			_tasks[_activeTaskIndex].stopwatch.stop();
		}
	}
	
	/// ditto
	void stopInterruptStopWatch()
	{
		if (_interruptStopWatch.running)
			_interruptStopWatch.stop();
		
		if (_tasks.length == 0)
			return;
		
		if (_tasks[_activeTaskIndex].enabled
		 && !_tasks[_activeTaskIndex].stopwatch.running)
		{
			_tasks[_activeTaskIndex].stopwatch.start();
		}
	}
	
	/// ditto
	void resetInterruptStopWatch()
	{
		_interruptStopWatch.reset();
	}
	
	
	/// ditto
	void copyInterruptStopWatchDuration()
	{
		import std.string: format;
		auto dur = _interruptStopWatch.peek();
		auto txt = format("%.6f", dur.to!("seconds", real)()/3600);
		_ui.command(["copyToClipboard", sendData(txt)]);
	}
	
	
	/***************************************************************************
	 * 積み上げタスク時間用ストップウォッチ管理
	 */
	void addTaskStopWatch()
	{
		Task t;
		t.startTime = Clock.currTime();
		t.name = t.startTime.toISOExtString();
		t.enabled = true;
		_tasks ~= t;
		_ui.command(["addTask"]);
		changeActiveTaskStopWatch(_tasks.length - 1);
	}
	
	
	/// ditto
	void removeActiveTaskStopWatch()
	{
		if (_tasks.length == 0)
			return;
		_tasks.replaceInPlace(_activeTaskIndex, _activeTaskIndex+1, _tasks.init);
		_ui.command(["removeTask", sendData(_activeTaskIndex)]);
		if (_activeTaskIndex != 0)
			_activeTaskIndex--;
		changeActiveTaskStopWatch(_activeTaskIndex);
	}
	
	
	/***************************************************************************
	 * 積み上げタスク時間用ストップウォッチ制御
	 */
	void startActiveTaskStopWatch()
	{
		if (_tasks.length == 0)
			return;
		if (!_interruptStopWatch.running
		 && _tasks[_activeTaskIndex].enabled
		 && !_tasks[_activeTaskIndex].stopwatch.running)
		{
			_tasks[_activeTaskIndex].stopwatch.start();
		}
	}
	
	/// ditto
	void stopActiveTaskStopWatch()
	{
		if (_tasks.length == 0)
			return;
		if (_tasks[_activeTaskIndex].stopwatch.running)
			_tasks[_activeTaskIndex].stopwatch.stop();
	}
	
	/// ditto
	void resetActiveTaskStopWatch()
	{
		if (_tasks.length == 0)
			return;
		_tasks[_activeTaskIndex].stopwatch.reset();
	}
	
	/// ditto
	void enableActiveTaskStopWatch()
	{
		if (_tasks.length == 0)
			return;
		_tasks[_activeTaskIndex].enabled = true;
		startActiveTaskStopWatch();
	}
	
	/// ditto
	void disableActiveTaskStopWatch()
	{
		if (_tasks.length == 0)
			return;
		if (_tasks[_activeTaskIndex].stopwatch.running)
		{
			_tasks[_activeTaskIndex].stopwatch.stop();
		}
		_tasks[_activeTaskIndex].enabled = true;
	}
	
	/// ditto
	void renameActiveTaskStopWatch()
	{
		if (_tasks.length == 0)
			return;
		
	}
	
	/// ditto
	void confirmActiveTaskStopWatchName(string name)
	{
		if (_tasks.length == 0)
			return;
		_tasks[_activeTaskIndex].name = name;
	}
	
	
	/// ditto
	void copyActiveTaskStopWatchDuration()
	{
		import std.string: format;
		auto dur = _tasks[_activeTaskIndex].stopwatch.peek();
		auto txt = format("%.6f", dur.to!("seconds", real)()/3600);
		_ui.command(["copyToClipboard", sendData(txt)]);
	}
	
	/// ditto
	void changeActiveTaskStopWatch(size_t targetidx)
	{
		if (_tasks.length == 0)
			return;
		
		assert(targetidx < _tasks.length);
		
		auto oldidx = _activeTaskIndex;
		_activeTaskIndex = targetidx;
		
		if (targetidx != _activeTaskIndex && _tasks[oldidx].stopwatch.running)
			_tasks[oldidx].stopwatch.stop();
		
		startActiveTaskStopWatch();
		_ui.command(["changeActiveTask", sendData(_activeTaskIndex)]);
	}
	
	
	/***************************************************************************
	 * データ保存/復元
	 */
	void loadData()
	{
		string filename;
		loadData(filename);
	}
	
	/// ditto
	void loadData(string filename)
	{
		
	}
	
	/// ditto
	void saveData()
	{
		string filename;
		saveData(filename);
	}
	
	/// ditto
	void saveData(string filename)
	{
		
	}
	
	
	/***************************************************************************
	 * 設定
	 */
	void showConfig()
	{
		
	}
	
	/// ditto
	void applyConfig(Config cfg)
	{
		
	}
	
	/// ditto
	void loadConfig()
	{
		string filename;
		loadConfig(filename);
	}
	
	/// ditto
	void loadConfig(string filename)
	{
		
	}
	
	/// ditto
	void saveConfig()
	{
		string filename;
		saveConfig(filename);
	}
	
	/// ditto
	void saveConfig(string filename)
	{
		
	}
	
public:
	this(string[] args)
	{
		_args  = args;
		_comm  = new shared(CommInstance)(this);
		_ui    = new shared(UserInterface)(_comm);
		_timer = new Timer;
		_timer.onTimer ~= 
		{
			command(["updateDisplay"]);
		};
		_timer.interval = dur!"msecs"(17);
	}
	void command(in string[] args)
	{
		debug writeln(args);
		switch (args[0])
		{
		case "startInterruptStopWatch":
			startInterruptStopWatch();
			break;
		case "stopInterruptStopWatch":
			stopInterruptStopWatch();
			break;
		case "resetInterruptStopWatch":
			resetInterruptStopWatch();
			break;
		case "copyInterruptStopWatchDuration":
			copyInterruptStopWatchDuration();
			break;
		case "addTaskStopWatch":
			addTaskStopWatch();
			break;
		case "removeActiveTaskStopWatch":
			removeActiveTaskStopWatch();
			break;
		case "startActiveTaskStopWatch":
			startActiveTaskStopWatch();
			break;
		case "stopActiveTaskStopWatch":
			stopActiveTaskStopWatch();
			break;
		case "resetActiveTaskStopWatch":
			resetActiveTaskStopWatch();
			break;
		case "enableActiveTaskStopWatch":
			enableActiveTaskStopWatch();
			break;
		case "disableActiveTaskStopWatch":
			disableActiveTaskStopWatch();
			break;
		case "renameActiveTaskStopWatch":
			renameActiveTaskStopWatch();
			break;
		case "confirmActiveTaskStopWatchName":
			confirmActiveTaskStopWatchName(args[1]);
			break;
		case "copyActiveTaskStopWatchDuration":
			copyActiveTaskStopWatchDuration();
			break;
		case "changeActiveTaskStopWatch":
			changeActiveTaskStopWatch(receiveData!size_t(args[1]));
			break;
		case "loadData":
			loadData();
			break;
		case "loadDataWithFilename":
			loadData(args[1]);
			break;
		case "saveData":
			loadData();
			break;
		case "saveDataWithFilename":
			loadData(args[1]);
			break;
		case "updateDisplay":
			auto app = appender!(Duration[])();
			foreach (t; _tasks)
			{
				app.put(cast(Duration)t.stopwatch.peek());
			}
			_ui.command(["updateDisplay", sendData(cast(Duration)_interruptStopWatch.peek()), sendData(app.data)]);
			break;
		case "gotoBackground":
			//@@@TODO@@@
			break;
		case "exit":
			_ui.exit();
			break;
		default:
			
		}
		
	}
	
	void run()
	{
		_timer.start();
		(cast()_ui).run();
		_timer.stop();
	}
	
}
