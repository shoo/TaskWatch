module src.app;

import core.time;
import std.datetime, std.array;
import src.common, src.features;
import src.ui, src.sys.timer, src.sys.task, src.sys.config;
import src.misc.escseq;


/*******************************************************************************
 * 
 */
shared class CommInstance: CommInterface
{
private:
	shared AppInterface _app;
	
public:
	/***************************************************************************
	 * 
	 */
	this(AppInterface app)
	{
		_app = cast(shared)app;
		
	}
	
	/***************************************************************************
	 * 
	 */
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
	Config               _config;
	
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
		updateDisplay();
	}
	
	
	/// ditto
	void copyInterruptStopWatchDuration()
	{
		import std.format;
		auto dur = _interruptStopWatch.peek();
		auto app = appender!string();
		try
		{
			formattedWrite(app, _config.fmtCopyForInterrupt.unescapeSequence(),
				dur.to!("seconds", real)()/3600,
				dur.to!("seconds", real)()/60,
				dur.to!("seconds", real)());
			_ui.command(["copyToClipboard", sendData(app.data)]);
		}
		catch (Throwable e)
		{
			_ui.command(["showException", sendData(new RuntimeException(
				"割り込みストップウォッチのコピーで"
				"無効な書式が指定されました。"
				"設定を見なおしてください", e))]);
		}
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
		import std.format;
		auto dur = _tasks[_activeTaskIndex].stopwatch.peek();
		auto app = appender!string();
		try
		{
			formattedWrite(app, _config.fmtCopyForTask.unescapeSequence(),
				dur.to!("seconds", real)()/3600,
				dur.to!("seconds", real)()/60,
				dur.to!("seconds", real)());
			_ui.command(["copyToClipboard", sendData(app.data)]);
		}
		catch (Throwable e)
		{
			_ui.command(["showException", sendData(new RuntimeException(
				"タスクストップウォッチのコピーで"
				"無効な書式が指定されました"
				"設定を見なおしてください", e))]);
		}
	}
	
	/// ditto
	void changeActiveTaskStopWatch(size_t targetidx)
	{
		if (_tasks.length == 0)
			return;
		
		assert(targetidx < _tasks.length);
		
		auto oldidx = _activeTaskIndex;
		_activeTaskIndex = targetidx;
		
		if (oldidx != _activeTaskIndex && _tasks[oldidx].stopwatch.running)
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
		_ui.command(["showConfig", sendData(_config)]);
	}
	
	/// ditto
	void applyConfig(Config cfg)
	{
		_config = cfg;
	}
	
	/// ditto
	void loadConfig()
	{
		import std.file, std.json;
		if (exists("config.json"))
		{
			auto jsonContents = cast(string)std.file.read("config.json");
			auto json = std.json.parseJSON(jsonContents);
			_config.fromJson(json);
		}
	}
	
	/// ditto
	void saveConfig()
	{
		import std.file, std.json;
		auto json = _config.toJson();
		std.file.write("config.json", std.json.toJSON(&json));
	}
	
	
	/***************************************************************************
	 * ユーザーインターフェースとのやり取り
	 */
	void updateDisplay()
	{
		auto intDur = cast(Duration)_interruptStopWatch.peek();
		auto app = appender!(Duration[])();
		foreach (t; _tasks)
		{
			app.put(cast(Duration)t.stopwatch.peek());
		}
		_ui.command(["updateDisplay", sendData(intDur), sendData(app.data)]);
	}
	
	/// ditto
	void gotoForeground()
	{
		_ui.command(["show"]);
	}
	
	/// ditto
	void gotoBackground()
	{
		_ui.command(["hide"]);
	}
	
public:
	/***************************************************************************
	 * 
	 */
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
		loadConfig();
	}
	
	
	/***************************************************************************
	 * コマンドを機能に割り当てる
	 * 
	 * コマンドは以下(括弧内はパラメータ)
	 * $(UL
	 *   $(LI startInterruptStopWatch() )
	 *   $(LI stopInterruptStopWatch() )
	 *   $(LI resetInterruptStopWatch() )
	 *   $(LI copyInterruptStopWatchDuration() )
	 *   $(LI addTaskStopWatch() )
	 *   $(LI removeActiveTaskStopWatch() )
	 *   $(LI startActiveTaskStopWatch() )
	 *   $(LI stopActiveTaskStopWatch() )
	 *   $(LI resetActiveTaskStopWatch() )
	 *   $(LI enableActiveTaskStopWatch() )
	 *   $(LI disableActiveTaskStopWatch() )
	 *   $(LI renameActiveTaskStopWatch() )
	 *   $(LI confirmActiveTaskStopWatchName(string) )
	 *   $(LI copyActiveTaskStopWatchDuration() )
	 *   $(LI changeActiveTaskStopWatch(size_t(id)) )
	 *   $(LI loadData(string) )
	 *   $(LI loadDataWithFilename() )
	 *   $(LI saveData() )
	 *   $(LI saveDataWithFilename(string) )
	 *   $(LI showConfig() )
	 *   $(LI loadConfig() )
	 *   $(LI loadConfigWithFilename(string) )
	 *   $(LI saveConfig() )
	 *   $(LI saveConfigWithFilename(string) )
	 *   $(LI applyConfig(Config(id)) )
	 *   $(LI updateDisplay() )
	 *   $(LI gotoForeground() )
	 *   $(LI gotoBackground() )
	 *   $(LI exit() )
	 * )
	 * 
	 * Params:
	 * args = [_command name, parameters...]
	 * 
	 * Examples:
	 *--------------------------------------------------------------------------
	 *command(["startInterruptStopWatch"]);
	 *--------------------------------------------------------------------------
	 */
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
			saveData();
			break;
		case "saveDataWithFilename":
			saveData(args[1]);
			break;
		case "showConfig":
			showConfig();
			break;
		case "loadConfig":
			loadConfig();
			break;
		case "saveConfig":
			saveConfig();
			break;
		case "applyConfig":
			applyConfig(receiveData!Config(args[1]));
			break;
		case "updateDisplay":
			updateDisplay();
			break;
		case "gotoForeground":
			gotoForeground();
			break;
		case "gotoBackground":
			gotoBackground();
			break;
		case "exit":
			_ui.exit();
			break;
		default:
			
		}
		
	}
	
	
	/***************************************************************************
	 * 
	 */
	void run()
	{
		_timer.start();
		(cast()_ui).run();
		_timer.stop();
	}
	
}
