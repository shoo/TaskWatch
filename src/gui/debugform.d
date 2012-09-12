module src.gui.debugform;

import std.exception, std.datetime, std.string, std.range, std.array, std.file;
import core.memory;
import win = win32.windows;
import dfl.all;
import src.common, src.features;
import voile.dataformatter;

/*******************************************************************************
 * 
 */
debug class DebugForm: Form
{
private:
	shared CommInterface    _comm;
	ListView                _list;
	TextBox                 _cmdInput;
	Button                  _cmdSend;
	//LogItem[]               _logItems;
	RefAppender!(string[])  _cmdListApp;
	string[]                _cmdList;
	uint                    _cmdIndex;
	
	void dispCmdInputBox(uint idx)
	{
		if (_cmdIndex == _cmdList.length)
		{
			_cmdInput.text = "";
		}
		else
		{
			_cmdInput.text = _cmdList[_cmdIndex];
		}
	}
	
	void dispCmdPrev()
	{
		if (!_cmdList.length) return;
		if (_cmdIndex > 0) --_cmdIndex;
		dispCmdInputBox(_cmdIndex);
	}
	
	void dispCmdNext()
	{
		if (!_cmdList.length) return;
		if (_cmdIndex < _cmdList.length) ++_cmdIndex;
		dispCmdInputBox(_cmdIndex);
	}
	
	void dispCmdLast()
	{
		_cmdIndex = _cmdList.length;
		dispCmdInputBox(_cmdIndex);
	}
	
	void dispCmdFirst()
	{
		_cmdIndex = 0;
		dispCmdInputBox(_cmdIndex);
	}
	
	void send()
	{
		focus();
		auto inputtext = _cmdInput.text;
		if (inputtext.length == 0) return;
		_cmdInput.text = "";
		_comm.command(inputtext.split(" "));
		if (_cmdIndex != _cmdList.length && _cmdList[_cmdIndex] == inputtext)
		{
			std.algorithm.move(_cmdList[_cmdIndex..$-1], _cmdList[_cmdIndex+1..$]);
			_cmdList[$-1] = inputtext;
		}
		else
		{
			_cmdListApp.put(inputtext);
		}
		_cmdIndex = _cmdList.length;
		dispCmdInputBox(_cmdIndex);
	}
	
public:
	/***************************************************************************
	 * 
	 */
	this(shared CommInterface comm)
	{
		_comm = comm;
		_cmdListApp = appender(&_cmdList);
		
		text = "DebugForm";
		Panel inputPanel;
		MainMenu mainmenu = new MainMenu;
		showInTaskbar = false;
		with (mainmenu)
		{
			static class Tag
			{
				string msg;
				this(string m) { msg = m; }
				override string toString() { return msg; }
			}
			
			auto miFile = new MenuItem;
			miFile.text = "ファイル(&F)";
			menuItems.add(miFile);
			
			auto miFile_Save = new MenuItem;
			miFile_Save.text = "保存(&S)";
			miFile_Save.click ~= (MenuItem sender, EventArgs e)
			{
				auto fd = new SaveFileDialog;
				with (fd)
				{
					initialDirectory = .std.file.getcwd() ~ "\\";
					overwritePrompt = true;
					title           = "ログデータファイルの保存先ファイル名を指定";
					fileName        = "log";
					filter          = "*.dat : ログデータファイル|*.dat";
					defaultExt      = "dat";
					validateNames   = true;
				}
				auto result = fd.showDialog();
				if (result == DialogResult.OK)
				{
					auto logfile = fd.fileName;
					//std.file.write(logfile, saveLog());
				}
			};
			miFile.menuItems.add(miFile_Save);
			
			auto miFile_Load = new MenuItem;
			miFile_Load.text = "読込(&L)";
			miFile_Load.click ~= (MenuItem sender, EventArgs e)
			{
				auto fd = new OpenFileDialog;
				with (fd)
				{
					initialDirectory = .std.file.getcwd() ~ "\\";
					title           = "ログデータファイルの読込元ファイル名を指定";
					fileName        = "log";
					filter          = "*.dat : ログデータファイル|*.dat";
					defaultExt      = "dat";
					validateNames   = true;
				}
				auto result = fd.showDialog();
				if (result == DialogResult.OK)
				{
					auto logfile = fd.fileName;
					//loadLog(cast(ubyte[])std.file.read(logfile));
				}
			};
			miFile.menuItems.add(miFile_Load);
			
			auto miFile_Clear = new MenuItem;
			miFile_Clear.text = "ログのクリア(&C)";
			miFile_Clear.click ~= (MenuItem sender, EventArgs e)
			{
				//clearLog();
			};
			miFile.menuItems.add(miFile_Clear);
			
			auto miGC = new MenuItem;
			miGC.text = "GC";
			menuItems.add(miGC);
			
			auto miGC_Collect = new MenuItem;
			miGC_Collect.text = "Collect";
			miGC_Collect.click ~= (MenuItem sender, EventArgs e)
			{
				core.memory.GC.collect();
			};
			miGC.menuItems.add(miGC_Collect);
		}
		menu = mainmenu;
		
		with (inputPanel = new Panel)
		{
			parent = this;
			height = 23;
			dock = DockStyle.BOTTOM;
			tabStop = false;
		}
		with (_cmdSend  = new Button)
		{
			parent = inputPanel;
			dock = DockStyle.RIGHT;
			width = 50;
			text = "送信";
			tabStop = false;
			click ~= (Control ctrl, EventArgs e)
			{
				send();
			};
		}
		with (_cmdInput = new class TextBox
		{
			override bool preProcessMessage(ref Message msg)
			{
				switch (msg.msg)
				{
				case win.WM_KEYDOWN:
					switch (msg.wParam)
					{
					case Keys.UP:
						auto df = enforce(cast(DebugForm)findForm());
						df.dispCmdPrev();
						return true;
					case Keys.DOWN:
						auto df = enforce(cast(DebugForm)findForm());
						df.dispCmdNext();
						return true;
					case Keys.PAGE_UP:
						auto df = enforce(cast(DebugForm)findForm());
						df.dispCmdFirst();
						return true;
					case Keys.PAGE_DOWN:
						auto df = enforce(cast(DebugForm)findForm());
						df.dispCmdLast();
						return true;
					default: {}
					}
					break;
				case win.WM_CHAR:
					switch (msg.wParam)
					{
					case Keys.ENTER:
						auto df = enforce(cast(DebugForm)findForm());
						df.send();
						return true;
					default: {}
					}
					break;
				default:
				}
				return super.preProcessMessage(msg);
			}
		})
		{
			parent = inputPanel;
			dock = DockStyle.FILL;
			selectNextControl(this, false, false, false, true);
		}
		with (_list = new ListView)
		{
			parent             = this;
			dock               = DockStyle.FILL;
			tabStop           = false;
			
			// リストの設定
			multiSelect        = true;
			allowColumnReorder = true;
			gridLines          = true;
			hideSelection      = true;
			multiSelect        = true;
			fullRowSelect      = true;
			scrollable         = true;
			view               = View.DETAILS;
			
			ColumnHeader ch(string name, int width)
			{
				auto newch  = new ColumnHeader;
				newch.text  = name;
				newch.width = width;
				return newch;
			}
			
			columns.addRange([
				ch("time", 100),
				ch("msg", 300)]);
		}
		
	}
	
	
///	/***************************************************************************
///	 * 
///	 */
///	void log(LogItem item)
///	{
///		_logItems ~= item;
///		auto li = new ListViewItem();
///		auto time = item.time;
///		with (time)
///		{
///			li.text = format("%02d:%02d:%02d.%03d",
///				hour, minute, second, fracSec.msecs);
///		}
///		li.subItems.add(item.msg);
///		_list.items.add(li);
///		_list.ensureVisible(_list.items.length-1);
///	}
///	
///	
///	/***************************************************************************
///	 * 
///	 */
///	ubyte[] saveLog()
///	{
///		auto app = appender!(ubyte[])();
///		auto writer = leWriter(app);
///		writer.put(cast(ulong)logStartTime.stdTime);
///		writer.put(cast(ulong)_logItems.length);
///		foreach (li; _logItems)
///		{
///			writer.put(cast(uint)li.level);
///			writer.put(cast(long)li.time.stdTime);
///			writer.put(cast(ulong)li.msg.length);
///			writer.put(cast(immutable ubyte[])li.msg);
///		}
///		return app.data;
///	}
///	
///	
///	/***************************************************************************
///	 * 
///	 */
///	void loadLog(ubyte[] data)
///	{
///		auto writer = leReader(data);
///		ulong tmpUlong;
///		long tmpLong;
///		uint tmpUint;
///		size_t len;
///		writer.pick(tmpLong);
///		writer.pick(tmpUlong);
///		len = cast(size_t)tmpUlong;
///		foreach (i; 0..len)
///		{
///			LogItem li;
///			writer.pick(tmpUint);
///			li.level = cast(LogLevel)tmpUint;
///			writer.pick(tmpLong);
///			li.time = SysTime(tmpLong);
///			writer.pick(tmpUlong);
///			ubyte[] buf = new ubyte[cast(size_t)tmpUlong];
///			writer.pick(buf);
///			li.msg = cast(string)buf;
///			log(li);
///		}
///	}
///	
///	
///	/***************************************************************************
///	 * 
///	 */
///	void clearLog()
///	{
///		_list.clear();
///		clear(_logItems);
///		_logItems = null;
///	}
	
	
protected override:
	
	
	///
	void onHandleCreated(EventArgs e)
	{
		size = Size(400, 260);
		super.onHandleCreated(e);
	}
	
	
	///
	void onGotFocus(EventArgs e)
	{
		_cmdInput.focus();
	}
	
	
	///
	void onClosed(EventArgs e)
	{
		
	}
	
	
	///
	void onClosing(CancelEventArgs e)
	{
		auto dr = msgBox("とじる？", "！", MsgBoxButtons.OK_CANCEL);
		
		if (dr == DialogResult.OK)
		{
			_comm.command(["exit"]);
		}
		
		e.cancel = true;
	}
	
	
	///
	void onResize(EventArgs e)
	{
		_list.columns[1].width = bounds.width - _list.columns[0].width - 50;
	}
}
