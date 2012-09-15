module src.gui.maincontextmenu;

import dfl.all;
import src.features;

/*******************************************************************************
 * 
 */
class MainContextMenu: dfl.all.ContextMenu
{
private:
	shared CommInterface _comm;
public:
	/***************************************************************************
	 * 
	 */
	this(shared CommInterface comm)
	{
		_comm = comm;
		MenuItem mi1;
		void onMenuItemSelected(MenuItem mi, EventArgs e)
		{
			_comm.command([mi.tag.toString()]);
		}
		
		// ファイル 保存
		with (mi1 = new MenuItem)
		{
			mi1.text = "ファイルに保存する";
			mi1.tag  = new StringObject("saveData");
			mi1.click ~= &onMenuItemSelected;
		}
		menuItems.add(mi1);
		
		// ファイル 読込
		with (mi1 = new MenuItem)
		{
			mi1.text = "ファイルから読み込む";
			mi1.tag  = new StringObject("loadData");
			mi1.click ~= &onMenuItemSelected;
		}
		menuItems.add(mi1);
		
		// ツール 設定
		with (mi1 = new MenuItem)
		{
			mi1.text = "設定";
			mi1.tag  = new StringObject("showConfig");
			mi1.click ~= &onMenuItemSelected;
		}
		menuItems.add(mi1);
		
		// --------
		with (mi1 = new MenuItem)
		{
			mi1.text = "-";
		}
		menuItems.add(mi1);
		
		// ファイル 閉じる
		with (mi1 = new MenuItem)
		{
			mi1.text = "閉じる";
			mi1.tag  = new StringObject("exit");
			mi1.click ~= &onMenuItemSelected;
		}
		menuItems.add(mi1);
	}
}
