﻿module src.ui;

import core.time;
import src.common, src.features, src.sys.config, src.sys.task;
import src.gui.mainform, src.gui.taskpanel, src.gui.configform,
       src.gui.taskconfigform,
       src.gui.maincontextmenu,
       src.gui.configpanels.base,
       src.gui.configpanels.copyformatsettings,
       src.gui.configpanels.visibulechangebehaviorsettings,
       src.gui.configpanels.saveloadsettings;
import dfl.all;
debug import src.gui.debugform;


/*******************************************************************************
 * 
 */
class UserInterface: UserInterfaceFeatures
{
private:
	shared CommInterface _comm;
	MainForm             _mainForm;
	NotifyIcon           _notifyIcon;
	ConfigForm           _configForm;
	TaskConfigForm       _taskConfigForm;
	shared SharedControl _sharedControl;
	debug DebugForm      _dbgForm;
	MainContextMenu      _contextMenu;
	string               _strDurInterruptUndoData;
	
	/***************************************************************************
	 * 
	 */
	void createUserInterface()
	{
		Application.enableVisualStyles();
		
		//--------------------------------------
		// メインフォームの設定
		_mainForm = new MainForm;
		_mainForm.icon = Application.resources.getIcon(101);
		
		// 有効無効切り替えボタン
		_mainForm.chkToggle.click ~= (Control ctrl, EventArgs ea)
		{
			if (_mainForm.chkToggle.checked)
			{
				_comm.command(["startInterruptStopWatch"]);
			}
			else
			{
				_comm.command(["stopInterruptStopWatch"]);
			}
		};
		// 編集前
		_mainForm.txtDurInterrupt.gotFocus ~= (Object s, EventArgs e)
		{
			_strDurInterruptUndoData = _mainForm.txtDurInterrupt.text;
		};
		// 編集後
		_mainForm.txtDurInterrupt.lostFocus ~= (Object s, EventArgs e)
		{
			if (!_mainForm.chkToggle.checked
			 && _mainForm.txtDurInterrupt.text != _strDurInterruptUndoData)
			{
				import std.regex;
				import std.math: lrint;
				auto r = regex(r"^(\d+):(\d+):(\d+)\.(\d+)$");
				auto m = match(_mainForm.txtDurInterrupt.text, r);
				if (m)
				{
					import std.conv;
					auto c = m.captures;
					Duration d;
					d += dur!"hours"(to!int(c[1]));
					d += dur!"minutes"(to!int(c[2]));
					d += dur!"usecs"(lrint(to!real(c[3]~"."~c[4])*1000000));
					_comm.command(["submitInterruptStopWatchDuration", sendData(d)]);
				}
				else
				{
					_mainForm.txtDurInterrupt.text = _strDurInterruptUndoData;
				}
			}
		};
		
		// リセットボタン
		_mainForm.btnReset.click ~= (Control ctrl, EventArgs ea)
		{
			_comm.command(["resetInterruptStopWatch"]);
		};
		
		// コピーボタン
		_mainForm.btnCopy.click ~= (Control ctrl, EventArgs ea)
		{
			_comm.command(["copyInterruptStopWatchDuration"]);
		};
		
		// 追加ボタン
		_mainForm.btnAdd.click ~= (Control ctrl, EventArgs ea)
		{
			_comm.command(["addTaskStopWatch"]);
		};
		
		// 設定ボタン
		_mainForm.btnConfig.image = Application.resources.getIcon(202);
		_mainForm.btnConfig.click ~= (Control ctrl, EventArgs ea)
		{
			showMenu();
		};
		
		
		// 最小化時の挙動
		_mainForm.resize ~= (Control ctrl, EventArgs e)
		{
			if (_mainForm.windowState == FormWindowState.MINIMIZED)
			{
				_comm.command(["gotoBackground"]);
			}
		};
		
		// 閉じる時の挙動
		_mainForm.closing ~= (Control ctrl, CancelEventArgs e)
		{
			_comm.command(["exit"]);
			e.cancel = true;
		};
		
		//--------------------------------------
		// 共有コントロールの設定
		_sharedControl = new shared(SharedControl)(_mainForm);
		
		
		//@@@TODO@@@ 本処理は現在MainForm内に実装中。こちらに移動予定。
		//--------------------------------------
		// 通知領域アイコンの設定
		_notifyIcon = new NotifyIcon;
		_notifyIcon.text = "TaskWatch";
		_notifyIcon.icon = Application.resources.getIcon(101);
		_notifyIcon.contextMenu = new ContextMenu;
		_notifyIcon.click ~= (Object s, EventArgs e)
		{
			_comm.command(["gotoForeground"]);
		};
		MenuItem mi;
		// ウィンドウをもとに戻す
		with (mi = new MenuItem)
		{
			mi.text = "もとに戻す";
			mi.click ~= (Object s, EventArgs e)
			{
				_comm.command(["gotoForeground"]);
			};
		}
		_notifyIcon.contextMenu.menuItems.add(mi);
		// 終了
		with (mi = new MenuItem)
		{
			mi.text = "終了";
			mi.click ~= (Object s, EventArgs e)
			{
				_comm.command(["exit"]);
			};
		}
		_notifyIcon.contextMenu.menuItems.add(mi);
		
		//--------------------------------------
		// コンテキストメニュー
		_contextMenu = new MainContextMenu(_comm);
		
		//--------------------------------------
		// 設定ダイアログの設定
		_configForm = new ConfigForm;
		// 設定項目の設定
		void setConfigMenu(string name, ConfigPanel panel)
		{
			auto tn = new TreeNode(name);
			tn.tag = panel;
			panel.parent = _configForm.pnlMain;
			panel.visible = false;
			_configForm.treeConfig.nodes.add(tn);
		}
		setConfigMenu("コピー用書式設定", new CopyFormatSettings);
		setConfigMenu("表示変更時の挙動", new VisibleChangeBehaviorSettings);
		setConfigMenu("保存・読込",       new SaveLoadSettings);
		// 設定項目の選択
		_configForm.treeConfig.afterSelect ~= (Control s, TreeViewEventArgs e)
		{
			auto p = cast(Panel)e.node.tag;
			foreach (c; _configForm.pnlMain.controls)
			{
				c.hide();
			}
			p.show();
		};
		// 設定の適用時の動作
		_configForm.onConfigApplied ~= 
		{
			_comm.command(["applyConfig", sendData(_configForm.config)]);
			_comm.command(["saveConfig"]);
		};
		
		// アイコン
		_configForm.icon = Application.resources.getIcon(202, false);
		
		//--------------------------------------
		// タスク設定
		_taskConfigForm = new TaskConfigForm;
		
		// 設定適用時の挙動
		_taskConfigForm.onConfigApplied ~=
		{
			_comm.command(["confirmActiveTaskStopWatchConfig", sendData(_taskConfigForm.task)]);
		};
		
		// アイコン
		_taskConfigForm.icon = Application.resources.getIcon(202, false);
		
		//--------------------------------------
		// ショートカットの設定
		_mainForm.addShortcut(Keys.HOME, (Object s, FormShortcutEventArgs e)
		{
			//_mainForm.windowState = FormWindowState.MINIMIZED;
			_comm.command(["gotoBackground"]);
		});
		
		//--------------------------------------
		// ホットキーの設定
		Application.addHotkey(Keys.WINDOWS|Keys.CONTROL|Keys.HOME, (Object s, KeyEventArgs e)
		{
			_comm.command(["gotoForeground"]);
		});
		
		//--------------------------------------
		// デバッグ用設定
		debug
		{
			_dbgForm = new DebugForm(_comm);
			_mainForm.handleCreated ~= (Control c, EventArgs e) => _dbgForm.show();
		}
	}
	
	
	/***************************************************************************
	 * イベント
	 */
	void changeInterruptState(bool b)
	{
		_mainForm.changeIntteruptToggleState(b);
	}
	
	/// 
	void addTask()
	{
		auto tp = new TaskPanel;
		// アクティブタスクの切り替えラジオボタン
		tp.radioTask.click ~= (Control c, EventArgs e)
		{
			auto p = cast(TaskPanel)c.parent;
			assert(p);
			_comm.command(["changeActiveTaskStopWatch", sendData(_mainForm.taskPanels.controls.indexOf(p))]);
		};
		// 削除ボタン
		tp.btnRemove.click ~= (Control c, EventArgs e)
		{
			auto p = cast(TaskPanel)c.parent;
			assert(p);
			_comm.command(["removeActiveTaskStopWatch"]);
		};
		// 有効無効の切り替えトグルボタン
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
		// リセットボタン
		tp.btnReset.click ~= (Control c, EventArgs e)
		{
			_comm.command(["resetActiveTaskStopWatch"]);
		};
		// コピーボタン
		tp.btnCopy.click ~= (Control c, EventArgs e)
		{
			_comm.command(["copyActiveTaskStopWatchDuration"]);
		};
		// 設定ボタン
		tp.btnConfig.click ~= (Control c, EventArgs e)
		{
			_comm.command(["configActiveTaskStopWatch"]);
		};
		// 編集前
		tp.txtDurTask.gotFocus ~= (Object s, EventArgs e)
		{
			tp.strDurTaskUndoData = tp.txtDurTask.text;
		};
		// 編集後
		tp.txtDurTask.lostFocus ~= (Object s, EventArgs e)
		{
			if (!tp.chkToggle.checked
			 && tp.txtDurTask.text != tp.strDurTaskUndoData)
			{
				import std.regex;
				import std.math: lrint;
				auto r = regex(r"^(\d+):(\d+):(\d+)\.(\d+)$");
				auto m = match(tp.txtDurTask.text, r);
				if (m)
				{
					import std.conv;
					auto c = m.captures;
					Duration d;
					d += dur!"hours"(to!int(c[1]));
					d += dur!"minutes"(to!int(c[2]));
					d += dur!"usecs"(lrint(to!real(c[3]~"."~c[4])*1000000));
					_comm.command(["submitActiveTaskStopWatchDuration", sendData(d)]);
				}
				else
				{
					tp.txtDurTask.text = tp.strDurTaskUndoData;
				}
			}
		};
		_mainForm.taskPanels.controls.add(tp);
	}
	
	///
	void removeTask(size_t idx)
	{
		_mainForm.taskPanels.controls.remove(_mainForm.taskPanels.controls[idx]);
	}
	
	///
	void clearAllTask()
	{
		while (_mainForm.taskPanels.controls.length)
		{
			_mainForm.taskPanels.controls.removeAt(_mainForm.taskPanels.controls.length-1);
		}
	}
	
	
	///
	void configTask(Task t)
	{
		_taskConfigForm.task = t;
		_taskConfigForm.show();
	}
	
	
	/***************************************************************************
	 * 概観管理
	 */
	void hide()
	{
		_mainForm.hide();
		_notifyIcon.visible = true;
	}
	
	
	/// ditto
	void show()
	{
		_notifyIcon.visible = false;
		_mainForm.show();
		if (_mainForm.windowState == FormWindowState.MINIMIZED)
		{
			_mainForm.windowState = FormWindowState.NORMAL;
		}
	}
	
	
	/// ditto
	void showMenu()
	{
		_contextMenu.show(_mainForm, Control.mousePosition);
	}
	
	/// ditto
	void showConfig(Config cfg)
	{
		_configForm.config = cfg;
		_configForm.show();
	}
	
	/// ditto
	void showException(Throwable e)
	{
		Application.onThreadException(e);
	}
	
	/// ditto
	void updateDisplay(Duration intDur, immutable(Task)[] tasks)
	{
		assert(_mainForm.taskPanels.controls.length == tasks.length);
		import std.string: format;
		import std.math: lrint;
		string newtxt;
		long fracsec = lrint((cast(real)intDur.fracSec.usecs)/1000);
		newtxt = format("%d:%02d:%02d.%03d", intDur.hours, intDur.minutes, intDur.seconds, fracsec);
		if (_mainForm.txtDurInterrupt.text != newtxt && (!_mainForm.txtDurInterrupt.focused || _mainForm.chkToggle.checked))
			_mainForm.txtDurInterrupt.text = newtxt;
		foreach (i; 0.._mainForm.taskPanels.controls.length)
		{
			auto p = cast(TaskPanel)_mainForm.taskPanels.controls[i];
			assert(p);
			auto t = tasks[i];
			if (p.lblName.text != t.name)
				p.lblName.text = t.name;
			auto dur = cast(Duration)t.stopwatch.peek();
			fracsec = lrint((cast(real)dur.fracSec.usecs)/1000);
			newtxt = format("%d:%02d:%02d.%03d", dur.hours, dur.minutes, dur.seconds, fracsec);
			if (p.txtDurTask.text != newtxt && (!p.txtDurTask.focused || p.chkToggle.checked))
				p.txtDurTask.text = newtxt;
		}
	}
	
	
	/// ditto
	void changeActiveTask(size_t idx)
	{
		if (!_mainForm.taskPanels.controls.length)
			return;
		auto p = cast(TaskPanel)_mainForm.taskPanels.controls[idx];
		assert(p);
		foreach (c2; _mainForm.taskPanels.controls)
		{
			auto p2 = cast(TaskPanel)c2;
			if (p2 is null)
				continue;
			if (p2 is p)
			{
				p2.activateTask();
				p2.btnConfig.image = Application.resources.getIcon(202, false);
			}
			else
			{
				p2.disactivateTask();
				p2.btnConfig.image = Application.resources.getIcon(201, false);
			}
		}
	}
	
	/***************************************************************************
	 * データの保存/読み込み
	 */
	void showLoadDataDialog()
	{
		import std.file;
		auto dialog = new OpenFileDialog;
		with (dialog)
		{
			checkFileExists  = true;
			checkPathExists  = true;
			defaultExt       = ".json";
			dereferenceLinks = true;
			fileName         = "data.json";
			filter           = "*.json データファイル|*.json";
			filterIndex      = 0;
			//initialDirectory = getcwd();
			restoreDirectory = true;
			showHelp         = true;
			title            = "データファイルの読み込み";
			validateNames    = true;
		}
		auto res = dialog.showDialog();
		if (res == DialogResult.OK)
		{
			_comm.command(["loadDataWithFilename", dialog.fileName]);
		}
	}
	
	/***************************************************************************
	 * 
	 */
	void showSaveDataDialog()
	{
		import std.file;
		auto dialog = new SaveFileDialog;
		with (dialog)
		{
			checkFileExists  = false;
			checkPathExists  = true;
			defaultExt       = ".json";
			dereferenceLinks = true;
			fileName         = "data.json";
			filter           = "*.json データファイル|*.json";
			filterIndex      = 0;
			//initialDirectory = getcwd();
			restoreDirectory = true;
			showHelp         = true;
			title            = "データファイルの読み込み";
			validateNames    = true;
			overwritePrompt     = true;
		}
		auto res = dialog.showDialog();
		if (res == DialogResult.OK)
		{
			_comm.command(["saveDataWithFilename", dialog.fileName]);
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
	
	/***************************************************************************
	 * 
	 */
	this(shared CommInterface comm)
	{
		_comm = comm;
		createUserInterface();
	}
	
	
	/***************************************************************************
	 * コマンドを機能に割り当てる。
	 * 
	 * コマンドは以下(括弧内はパラメータ)
	 * $(UL
	 *   $(LI updateDisplay() )
	 *   $(LI performInterrupt() )
	 *   $(LI addTask() )
	 *   $(LI removeTask(size_t(id)) )
	 *   $(LI changeActiveTask(size_t(id)) )
	 *   $(LI copyToClipboard(string(id)) )
	 *   $(LI showConfig(Config(id)) )
	 *   $(LI showException(Throwable(id)) )
	 *   $(LI showLoadDataDialog() )
	 *   $(LI showSaveDataDialog() )
	 * )
	 * 
	 * Params:
	 * args = [_command name, parameters...]
	 * 
	 * Examples:
	 *--------------------------------------------------------------------------
	 *command(["copyToClipboard"], sendData("abcde"));
	 *--------------------------------------------------------------------------
	 */
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
				auto durIntSw = receiveData!Duration(args[1]);
				auto durTasks = receiveData!(immutable(Task)[])(args[2]);
				(cast()ui).updateDisplay(durIntSw, durTasks);
				break;
			case "changeInterruptState":
				(cast()ui).changeInterruptState(receiveData!bool(args[1]));
				break;
			case "addTask":
				(cast()ui).addTask();
				break;
			case "removeTask":
				(cast()ui).removeTask(receiveData!size_t(args[1]));
				break;
			case "clearAllTask":
				(cast()ui).clearAllTask();
				break;
			case "configTask":
				(cast()ui).configTask(receiveData!Task(args[1]));
				break;
			case "changeActiveTask":
				(cast()ui).changeActiveTask(receiveData!size_t(args[1]));
				break;
			case "copyToClipboard":
				(cast()ui).copyToClipboard(receiveData!string(args[1]));
				break;
			case "show":
				(cast()ui).show();
				break;
			case "hide":
				(cast()ui).hide();
				break;
			case "showConfig":
				(cast()ui).showConfig(receiveData!Config(args[1]));
				break;
			case "showException":
				(cast()ui).showException(receiveData!Throwable(args[1]));
				break;
			case "showLoadDataDialog":
				(cast()ui).showLoadDataDialog();
				break;
			case "showSaveDataDialog":
				(cast()ui).showSaveDataDialog();
				break;
			case "exit":
				(cast()ui).exit();
				break;
			default:
				
			}
		}, this, args.idup);
	}
	
	
	/***************************************************************************
	 * 
	 */
	void exit()
	{
		clear(_mainForm);
		clear(_contextMenu);
		clear(_configForm);
		clear(_taskConfigForm);
		Application.exitThread();
	}
	
	
	/***************************************************************************
	 * 
	 */
	void run()
	{
		Application.run(_mainForm);
	}
}