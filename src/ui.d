module src.ui;

import core.time;
import src.common, src.features;
import src.gui.mainform, src.gui.taskpanel, src.gui.controlpanel;
import dfl.all;
debug import src.gui.debugform;

class UserInterface: UserInterfaceFeatures
{
private:
	shared CommInterface _comm;
	MainForm             _mainform;
	NotifyIcon           _notifyicno;
	shared SharedControl _sharedControl;
	debug DebugForm      _dbgform;
	void createUserInterface()
	{
		Application.enableVisualStyles();
		
		//--------------------------------------
		// メインフォームの設定
		_mainform = new MainForm;
		
		debug
		{
			_dbgform = new DebugForm(_comm);
			_mainform.handleCreated ~= (Control c, EventArgs e) => _dbgform.show();
		}
		_mainform.chkToggle.click ~= (Control ctrl, EventArgs ea)
		{
			if (_mainform.chkToggle.checked)
			{
				_comm.command(["startInterruptStopWatch"]);
			}
			else
			{
				_comm.command(["stopInterruptStopWatch"]);
			}
		};
		_mainform.btnReset.click ~= (Control ctrl, EventArgs ea)
		{
			_comm.command(["resetInterruptStopWatch"]);
		};
		_mainform.btnCopy.click ~= (Control ctrl, EventArgs ea)
		{
			_comm.command(["copyInterruptStopWatchDuration"]);
		};
		_mainform.btnAdd.click ~= (Control ctrl, EventArgs ea)
		{
			_comm.command(["addTaskStopWatch"]);
		};
		
		//--------------------------------------
		// 共有コントロールの設定
		_sharedControl = new shared(SharedControl)(_mainform);
		
		
		//@@@TODO@@@ 本処理は現在MainForm内に実装中。こちらに移動予定。
		/+
		//--------------------------------------
		// 通知領域アイコンの設定
		_notifyicno = new NotifyIcon;
		+/
		
		//--------------------------------------
		// ショートカットの設定
		_mainform.addShortcut(Keys.HOME, (Object sender, FormShortcutEventArgs e)
		{
			//_mainform.windowState = FormWindowState.MINIMIZED;
			_comm.command(["gotoBackground"]);
		});
		
		//--------------------------------------
		// ホットキーの設定
		Application.addHotkey(Keys.WINDOWS|Keys.CONTROL|Keys.HOME, (Object sender, KeyEventArgs e)
		{
			_comm.command(["updateDisplay"]);
		});
	}
	
	
	/***************************************************************************
	 * イベント
	 */
	void addTask()
	{
		auto tp = new TaskPanel;
		tp.radioTask.click ~= (Control c, EventArgs e)
		{
			auto p = cast(TaskPanel)c.parent;
			assert(p);
			_comm.command(["changeActiveTaskStopWatch", sendData(_mainform.taskPanels.controls.indexOf(p))]);
		};
		tp.btnRemove.click ~= (Control c, EventArgs e)
		{
			auto p = cast(TaskPanel)c.parent;
			assert(p);
			_comm.command(["removeActiveTaskStopWatch"]);
		};
		tp.chkToggle.click ~= (Control c, EventArgs e)
		{
			auto p = cast(TaskPanel)c.parent;
			assert(p);
			if (p.chkToggle.checked)
			{
				_comm.command(["enableActiveTaskStopWatch"]);
			}
			else
			{
				_comm.command(["disableActiveTaskStopWatch"]);
			}
		};
		tp.btnReset.click ~= (Control c, EventArgs e)
		{
			_comm.command(["resetActiveTaskStopWatch"]);
		};
		tp.btnCopy.click ~= (Control c, EventArgs e)
		{
			_comm.command(["copyActiveTaskStopWatchDuration"]);
		};
		_mainform.taskPanels.controls.add(tp);
		tp.radioTask.performClick();
	}
	
	///
	void removeTask(size_t idx)
	{
		_mainform.taskPanels.controls.remove(_mainform.taskPanels.controls[idx]);
	}
	
	
	/***************************************************************************
	 * 概観管理
	 */
	void hide()
	{
		//_mainform.hideAndStop();
	}
	
	
	/// ditto
	void show()
	{
		//_mainform.hideAndStop();
	}
	
	
	/// ditto
	void config()
	{
		
	}
	
	/// ditto
	void updateDisplay(Duration intDur, Duration[] taskDurs)
	{
		assert(_mainform.taskPanels.controls.length == taskDurs.length);
		import std.string: format;
		string newtxt;
		if (_mainform.chkToggle.checked || _mainform.txtDurInterrupt.textLength == 0)
		{
			newtxt = format("%d:%02d:%02d.%03d", intDur.hours, intDur.minutes, intDur.seconds, intDur.fracSec.msecs);
			if (_mainform.txtDurInterrupt.text != newtxt)
				_mainform.txtDurInterrupt.text = newtxt;
		}
		foreach (i; 0.._mainform.taskPanels.controls.length)
		{
			auto p = cast(TaskPanel)_mainform.taskPanels.controls[i];
			assert(p);
			if (!p.chkToggle.checked || !p.radioTask.checked)
				continue;
			auto dur = taskDurs[i];
			newtxt = format("%d:%02d:%02d.%03d", dur.hours, dur.minutes, dur.seconds, dur.fracSec.msecs);
			if (p.txtDurTask.text != newtxt)
				p.txtDurTask.text = newtxt;
		}
	}
	
	
	/// ditto
	void changeActiveTask(size_t idx)
	{
		if (!_mainform.taskPanels.controls.length)
			return;
		auto p = cast(TaskPanel)_mainform.taskPanels.controls[idx];
		assert(p);
		foreach (c2; _mainform.taskPanels.controls)
		{
			auto p2 = cast(TaskPanel)c2;
			if (p2 is null)
				continue;
			if (p2 is p)
			{
				p2.activateTask();
			}
			else
			{
				p2.disactivateTask();
			}
		}
	}
	
	/***************************************************************************
	 * 時間のコピペ用
	 */
	void copyToClipboard(string txt)
	{
		Clipboard.setString(txt, true);
	}
	
	
	
public:
	this(shared CommInterface comm)
	{
		_comm = comm;
		createUserInterface();
	}
	
	shared void command(in string[] args)
	{
		_sharedControl.delayInvoke( function(Control xctrl, shared UserInterface ui, immutable(string)[] args)
		{
			auto me = cast(UserInterface)ui;
			assert(args.length);
			switch (args[0])
			{
			case "updateDisplay":
				assert(args.length == 3);
				auto durIntSw   = receiveData!Duration(args[1]);
				auto durTaskSws = receiveData!(Duration[])(args[2]);
				(cast()ui).updateDisplay(durIntSw, durTaskSws);
				break;
			case "addTask":
				(cast()ui).addTask();
				break;
			case "removeTask":
				(cast()ui).removeTask(receiveData!size_t(args[1]));
				break;
			case "changeActiveTask":
				(cast()ui).changeActiveTask(receiveData!size_t(args[1]));
				break;
			case "copyToClipboard":
				(cast()ui).copyToClipboard(receiveData!string(args[1]));
				break;
			default:
				
			}
		}, this, args.idup);
	}
	
	shared void exit()
	{
		clear(_mainform);
		Application.exitThread();
	}
	
	void run()
	{
		Application.run(_mainform);
	}
}