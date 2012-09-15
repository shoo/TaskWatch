module src.misc.jsonhelper;

import std.json, std.conv, std.traits, std.array;

private @property JSONValue json(T)(in T[] x)
	if (isSomeString!(T[]))
{
	JSONValue v;
	v.type = JSON_TYPE.STRING;
	v.str = to!string(x);
	return v;
}

private @property JSONValue json(T)(in T x)
	if (isIntegral!T && !is(T == enum))
{
	JSONValue v;
	v.type = JSON_TYPE.INTEGER;
	v.integer = x;
	return v;
}

private @property JSONValue json(T)(in T x)
	if (isFloatingPoint!T)
{
	JSONValue v;
	v.type = JSON_TYPE.FLOAT;
	v.floating = x;
	return v;
}

private @property JSONValue json(T)(in T[] ary)
	if (!isSomeString!(T[]) && isArray!(T[]))
{
	auto app = appender!(JSONValue[])();
	JSONValue v;
	foreach (x; ary)
	{
		app.put(json(x));
	}
	v.type = JSON_TYPE.ARRAY;
	v.array = app.data;
	return v;
}

private @property JSONValue json(T)(in T x)
	if (is(T == bool))
{
	JSONValue v;
	if (x)
	{
		v.type = JSON_TYPE.TRUE;
	}
	else
	{
		v.type = JSON_TYPE.FALSE;
	}
	return v;
}

private @property JSONValue json(T)(in T x)
	if (is(typeof({JSONValue j = x.toJson();})))
{
	return x.toJson();
}


/*******************************************************************************
 *
 */
void setValue(T)(ref JSONValue v, string name, in T val)
	if (is(typeof(json(val))))
{
	v.object[name] = json(val);
}

/// ditto
void setValue(T)(ref JSONValue v, string name, in T val)
	if (is(T == enum))
{
	v.object[name] = json(to!string(val));
}


/*******************************************************************************
 *
 */
T getValue(T)(in ref JSONValue v, string name, T defaultVal = T.init)
	if (isSomeString!(T))
{
	T ret = defaultVal;
	if (auto x = name in v.object)
	{
		if (x.type == JSON_TYPE.STRING)
		{
			ret = to!T(x.str);
		}
	}
	return ret;
}

/// ditto
T getValue(T)(in ref JSONValue v, string name, T defaultVal = T.init)
	if (isIntegral!T && !is(T == enum))
{
	T ret = defaultVal;
	if (auto x = name in v.object)
	{
		if (x.type == JSON_TYPE.INTEGER)
		{
			ret = cast(T)x.integer;
		}
	}
	return ret;
}


/// ditto
T getValue(T)(in ref JSONValue v, string name, T defaultVal = T.init)
	if (isFloatingPoint!T)
{
	T ret = defaultVal;
	if (auto x = name in v.object)
	{
		if (x.type == JSON_TYPE.FLOAT)
		{
			ret = x.floating;
		}
	}
	return ret;
}


/// ditto
T getValue(T)(in ref JSONValue v, string name, T defaultVal = T.init)
	if (is(T == enum))
{
	T ret = defaultVal;
	if (auto x = name in v.object)
	{
		if (x.type == JSON_TYPE.STRING)
		{
			ret = to!T(x.str);
		}
	}
	return ret;
}


/// ditto
T getValue(T)(in ref JSONValue v, string name, T defaultVal = T.init)
	if (is(T == bool))
{
	T ret = defaultVal;
	if (auto x = name in v.object)
	{
		if (x.type == JSON_TYPE.TRUE)
		{
			ret = true;
		}
		else if (x.type == JSON_TYPE.FALSE)
		{
			ret = false;
		}
	}
	return ret;
}


/// ditto
T getValue(T)(in ref JSONValue v, string name, T defaultVal = T.init)
	if (is(typeof(
	{
		T val;
		JSONValue json;
		val.fromJson(json);
	})))
{
	T ret = defaultVal;
	if (auto x = name in v.object)
	{
		ret.fromJson(*x);
	}
	return ret;
}

/// ditto
T getValue(T)(in ref JSONValue v, string name, T defaultVal = T.init)
	if (!isSomeString!(T) && isArray!(T))
{
	T ret = defaultVal;
	alias ForeachType!T E;
	if (auto x = name in v.object)
	{
		if (x.type == JSON_TYPE.ARRAY)
		{
			ret.length = x.array.length;
			foreach (ref i; 0..x.array.length)
			{
				static if (isSomeString!E)
				{
					if (x.array[i].type == JSON_TYPE.STRING)
						ret[i] = to!E(x.array[i].str);
				}
				else static if (isIntegral!E)
				{
					if (x.array[i].type == JSON_TYPE.INTEGER)
						ret[i] = cast(T)x.array[i].integer;
				}
				else static if (isFloatingPoint!E)
				{
					if (x.array[i].type == JSON_TYPE.FLOAT)
						ret[i] = x.array[i].integer;
				}
				else static if (is(E==bool))
				{
					if (x.array[i].type == JSON_TYPE.TRUE)
					{
						ret[i] = true;
					}
					else if (x.array[i].type == JSON_TYPE.FALSE)
					{
						ret[i] = false;
					}
				}
				else static if (is(E==enum))
				{
					if (x.array[i].type == JSON_TYPE.STRING)
						ret[i] = to!E(x.array[i].str);
				}
				else static if (is(typeof({ ret[i].fromJson(x.array[i]); })))
				{
					if (x.array[i].type == JSON_TYPE.OBJECT)
						ret[i].fromJson(x.array[i]);
				}
				else static assert(0, "Unknown format");
			}
		}
	}
	return ret;
}
