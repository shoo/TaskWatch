﻿module src.ui;

import core.time;
import src.common, src.features, src.sys.config;
import src.gui.mainform, src.gui.taskpanel, src.gui.configform,
       src.gui.configpanels.base,
       src.gui.configpanels.copyformatsettings,
       src.gui.configpanels.visibulechangebehaviorsettings;
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
	shared SharedControl _sharedControl;
	debug DebugForm      _dbgForm;
	
	
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
			_comm.command(["showConfig"]);
		};
		
		
		// 最小化時の挙動
		_mainForm.resize ~= (Control ctrl, EventArgs e)
		{
			if (_mainForm.windowState == FormWindowState.MINIMIZED)
			{
				_comm.command(["gotoBackground"]);
			}
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
		// 設定ダイアログの設定
		_configForm = new ConfigForm;
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
		_configForm.treeConfig.afterSelect ~= (Control s, TreeViewEventArgs e)
		{
			auto p = cast(Panel)e.node.tag;
			foreach (c; _configForm.pnlMain.controls)
			{
				c.hide();
			}
			p.show();
		};
		_configForm.onConfigApplied ~= 
		{
			_comm.command(["applyConfig", sendData(_configForm.config)]);
			_comm.command(["saveConfig"]);
		};
		_configForm.icon = Application.resources.getIcon(202);
		
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
	void addTask()
	{
		auto tp = new TaskPanel;
		tp.radioTask.click ~= (Control c, EventArgs e)
		{
			auto p = cast(TaskPanel)c.parent;
			assert(p);
			_comm.command(["changeActiveTaskStopWatch", sendData(_mainForm.taskPanels.controls.indexOf(p))]);
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
		_mainForm.taskPanels.controls.add(tp);
	}
	
	///
	void removeTask(size_t idx)
	{
		_mainForm.taskPanels.controls.remove(_mainForm.taskPanels.controls[idx]);
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
	void updateDisplay(Duration intDur, Duration[] taskDurs)
	{
		assert(_mainForm.taskPanels.controls.length == taskDurs.length);
		import std.string: format;
		string newtxt;
		newtxt = format("%d:%02d:%02d.%03d", intDur.hours, intDur.minutes, intDur.seconds, intDur.fracSec.msecs);
		if (_mainForm.txtDurInterrupt.text != newtxt)
			_mainForm.txtDurInterrupt.text = newtxt;
		foreach (i; 0.._mainForm.taskPanels.controls.length)
		{
			auto p = cast(TaskPanel)_mainForm.taskPanels.controls[i];
			assert(p);
			auto dur = taskDurs[i];
			newtxt = format("%d:%02d:%02d.%03d", dur.hours, dur.minutes, dur.seconds, dur.fracSec.msecs);
			if (p.txtDurTask.text != newtxt)
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
				p2.btnConfig.image = Application.resources.getIcon(202);
			}
			else
			{
				p2.disactivateTask();
				p2.btnConfig.image = Application.resources.getIcon(201, false);
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
	 *   $(LI addTask() )
	 *   $(LI removeTask(size_t(id)) )
	 *   $(LI changeActiveTask(size_t(id)) )
	 *   $(LI copyToClipboard(string(id)) )
	 *   $(LI showConfig(Config(id)) )
	 *   $(LI showException(Throwable(id)) )
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
			default:
				
			}
		}, this, args.idup);
	}
	
	
	/***************************************************************************
	 * 
	 */
	shared void exit()
	{
		clear(_mainForm);
		clear(_configForm);
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