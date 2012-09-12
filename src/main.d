import src.ui;

import src.app;
import src.common;

debug
{
	pragma(lib, "dfl_debug");
	pragma(lib, "voile-dbg");
}
else
{
	pragma(lib, "dfl");
	pragma(lib, "voile");
	
}


/*******************************************************************************
 * 
 */
void main(string[] args)
{
	try
	{
		auto app = new AppInstance(args);
		app.run();
	}
	catch (Throwable e)
	{
		debug writeln(e.toString());
		throw e;
	}
}
