module src.common;

import core.sync.mutex, core.time, core.memory;
import std.datetime, std.conv, std.string, std.traits;
import voile.benchmark;

public:
debug import std.stdio: writeln, writefln;
import std.exception: enforce, enforceEx;

private
{
	shared TickDuration _logStartTick;
	shared SysTime      _logStartTime;
	shared static this()
	{
		(*cast(SysTime*)&_logStartTime) = Clock.currTime();
	}
}

///
@property immutable(TickDuration) logStartTick()
{
	return *cast(immutable(TickDuration*))&_logStartTick;
}

///
@property immutable(SysTime) logStartTime()
{
	return *cast(immutable(SysTime)*)&_logStartTime;
}


debug CallCounter callCounter;
debug FootPrintBenchmark footPrint;
/*******************************************************************************
 * 
 */
enum LogLevel: uint
{
	info, warn, fatal
}


/*******************************************************************************
 * 
 */
struct LogItem
{
private:
public:
	LogLevel     level;
	SysTime      time;
	string       msg;
	this(string m, LogLevel l=LogLevel.info, SysTime t = Clock.currTime())
	{
		level = l;
		time = t;
		msg = m;
	}
	
	string toString()
	{
		with (time) return format("%04d/%02d/%02d[%02d:%02d:%02d.%03d] - %s: %s", 
			year, month, day, hour, minute, second, fracSec.msecs, to!string(level), msg);
	}
}


private
{
	struct NamedData
	{
		Mutex    mutex;
		debug TypeInfo info;
		void*    data;
	}
	shared Mutex             _namedDataMutex;
	shared NamedData[string] _namedData;
}

shared static this()
{
	_namedDataMutex = new shared(Mutex);
}

/*******************************************************************************
 * 
 */
ref Data takeNamedData(Data)(string name)
	in
	{
		synchronized (_namedDataMutex) assert(name in _namedData);
	}
	body
{
	synchronized (_namedDataMutex)
	{
		auto nd = cast(NamedData*)(name in _namedData);
		nd.mutex.lock();
		return *cast(Data*)nd.data;
	}
}


/*******************************************************************************
 * 
 */
ref Data takeNamedData(Data)(string name, Duration dur)
	in
	{
		synchronized (_namedDataMutex) assert(name in _namedData);
	}
	body
{
	synchronized (_namedDataMutex)
	{
		auto nd = cast(NamedData*)(name in _namedData);
		enforce(nd.mutex.tryLock(dur));
		return nd.data;
	}
}


/*******************************************************************************
 * 
 */
void releaseNamedData(Data)(string name)
	in
	{
		synchronized (_namedDataMutex) assert(name in _namedData);
	}
	body
{
	synchronized (_namedDataMutex)
	{
		auto nd = cast(NamedData*)(name in _namedData);
		nd.mutex.unlock();
	}
}


/*******************************************************************************
 * 
 */
void addNamedData(Data)(string name, Data data)
	in
	{
		synchronized (_namedDataMutex) assert(name !in _namedData);
	}
	body
{
	synchronized (_namedDataMutex)
	{
		NamedData nd;
		nd.mutex = new Mutex;
		debug nd.info = typeid(Data);
		static if (is(Data == interface) || is(Data==class) || isPointer!Data)
		{
			nd.data = cast(void*)data;
		}
		else
		{
			nd.data = GC.malloc(Data.sizeof);
			(cast(ubyte*)nd.data)[0..Data.sizeof] = (cast(ubyte*)&data)[0..Data.sizeof];
		}
		_namedData[name] = cast(shared)nd;
	}
}


/*******************************************************************************
 * 
 */
Data removeNamedData(Data)(string name)
	in
	{
		synchronized (_namedDataMutex) assert(name in _namedData);
	}
	body
{
	synchronized (_namedDataMutex)
	{
		auto nd = cast(NamedData*)(name in _namedData);
		auto tmp = nd.data;
		clear(nd.mutex);
		_namedData.remove(name);
		static if (is(Data == interface) || is(Data==class) || isPointer!Data)
		{
			return cast(Data)tmp;
		}
		else
		{
			scope (exit)
			{
				clear(tmp);
				GC.free(tmp);
			}
			return *cast(Data*)tmp;
		}
	}
}


/*******************************************************************************
 * 
 */
string getUniqueName()
{
	shared static int id;
	int myid;
	synchronized
	{
		myid = id++;
	}
	return "UniqueID[" ~ to!string(myid) ~ "]";
}


/*******************************************************************************
 * 
 */
string sendData(Data)(Data dat)
{
	auto name = getUniqueName();
	addNamedData(name, dat);
	return name;
}


/*******************************************************************************
 * 
 */
Data receiveData(Data)(string name)
{
	return removeNamedData!Data(name);
}


/*******************************************************************************
 * 
 */
class RuntimeException: Exception
{
	this(string msg, Throwable e)
	{
		super(msg, e);
	}
}
