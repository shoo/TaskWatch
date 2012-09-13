module src.misc.escseq;

import std.array, std.range, std.conv;

/*******************************************************************************
 * 
 */
void unescapeSequence(Target, Source)(ref Target dst, Source src)
{
	dchar getChar() { auto c = src.front; src.popFront(); return c; }
	while (!src.empty)
	{
		switch(src.front)
		{
		case '\\':
			src.popFront();
			auto c = getChar();
			switch(c)
			{
			case '\\':      dst.put('\\');  break;
			case '/':       dst.put('/');   break;
			case 'b':       dst.put('\b');  break;
			case 'f':       dst.put('\f');  break;
			case 'n':       dst.put('\n');  break;
			case 'r':       dst.put('\r');  break;
			case 't':       dst.put('\t');  break;
			case 'u':
				dchar val = 0;
				foreach_reverse(i; 0 .. 4)
				{
					switch (getChar())
					{
					case '0': val +=  0 << (4 * i); break;
					case '1': val +=  1 << (4 * i); break;
					case '2': val +=  2 << (4 * i); break;
					case '3': val +=  3 << (4 * i); break;
					case '4': val +=  4 << (4 * i); break;
					case '5': val +=  5 << (4 * i); break;
					case '6': val +=  6 << (4 * i); break;
					case '7': val +=  7 << (4 * i); break;
					case '8': val +=  8 << (4 * i); break;
					case '9': val +=  9 << (4 * i); break;
					case 'A': val += 10 << (4 * i); break;
					case 'B': val += 11 << (4 * i); break;
					case 'C': val += 12 << (4 * i); break;
					case 'D': val += 13 << (4 * i); break;
					case 'E': val += 14 << (4 * i); break;
					case 'F': val += 15 << (4 * i); break;
					case 'a': val += 10 << (4 * i); break;
					case 'b': val += 11 << (4 * i); break;
					case 'c': val += 12 << (4 * i); break;
					case 'd': val += 13 << (4 * i); break;
					case 'e': val += 14 << (4 * i); break;
					case 'f': val += 15 << (4 * i); break;
					default: throw new ConvException("Expecting hex character");
					}
				}
				dst.put(val);
				break;
			default:
				throw new ConvException(text("Invalid escape sequence '\\", c, "'."));
			}
			break;
		default:
			dst.put(getChar());
		}
	}
}

/// ditto
auto unescapeSequence(Source)(Source src)
{
	auto app = appender!(ElementEncodingType!(Source)[])();
	unescapeSequence(app, src);
	return app.data;
}

/*******************************************************************************
 * 
 */
void escapeSequence(Target, Source)(ref Target dst, Source src)
{
	foreach (c; src)
	{
		switch(c)
		{
		case '\\':      dst.put("\\\\");       break;
		case '/':       dst.put("\\/");        break;
		case '\b':      dst.put("\\b");        break;
		case '\f':      dst.put("\\f");        break;
		case '\n':      dst.put("\\n");        break;
		case '\r':      dst.put("\\r");        break;
		case '\t':      dst.put("\\t");        break;
		default:
			dst.put(c);
		}
	}
}

/// ditto
auto escapeSequence(Source)(Source src)
{
	auto app = appender!(ElementEncodingType!(Source)[])();
	escapeSequence(app, src);
	return app.data;
}

unittest
{
	auto x1 = `ab\te\nf`;
	auto x2 = unescapeSequence(x1);
	assert(x2 == "ab\te\nf");
	auto x3 = escapeSequence(x2);
	assert(x3 == x1);
}

unittest
{
	auto x = `ab\te\nf`;
	auto app1 = appender!string();
	auto app2 = appender!string();
	unescapeSequence(app1, x);
	assert(app1.data == "ab\te\nf");
	escapeSequence(app2, app1.data);
	assert(app2.data == x);
}