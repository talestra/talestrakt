module tales.util.gameformat;

import tales.common;
import std.stdio, std.file, std.format, std.stream, std.path, std.string, std.ctype, std.c.stdlib, std.regexp, std.string;

char[][int] GetTextPointers(Stream s) {
	char[][int] ret;
	char[] current;
	int id = -1;

	while (true) {
		char[] line = s.readLine();
		if (line.length >= 10 && line[0..10] == "## POINTER") {
			char[][] res = RegExp("\\d+").match(line);
			if (res.length == 0) {
				fwritefln(stderr, "El puntero no tiene identificador");
				continue;
			}

			if ((id in ret) !is null) ret[id] = std.string.strip(ret[id]);

			id = std.string.atoi(res[0]);

			continue;
		}

		//writefln(line);

		if ((id in ret) is null) ret[id] = line; else ret[id] ~= "\n" ~ line;

		if (s.eof) {
			if ((id in ret) !is null) ret[id] = std.string.strip(ret[id]);
			break;
		}
	}

	ret = ret.rehash;

	/*foreach (k; ret.keys.sort) {
		auto v = ret[k];
		printf("%d: %s\n", k, toStringz(v));
	}*/

	if (-1 in ret) ret.remove(-1);

	return ret;
}

void StreamAlignZ(Stream s, uint alignment = 4) {
	s.write(cast(ubyte)0);
	StreamAlign(s, alignment);
}

void StreamAlign(Stream s, uint alignment = 4) {
	if (s.position % alignment == 0) return;
	ubyte[] temp; temp.length = (alignment - (s.position % alignment));
	//writefln(":%d", temp.length);
	s.write(temp);
}

void StreamWritePointerAt(Stream s, uint at, uint ptr) {
	uint bpos = s.position;
	s.position = at;
	s.write(ptr);
	s.position = bpos;
}

void StreamWritePointerAt(Stream s, uint at) {
	StreamWritePointerAt(s, at, s.position);
}

void writeTextPointer(Stream to, uint id, char[] text) {
	to.writeLine(format("## POINTER %d", id));
	to.writeLine(text);
	to.writeLine("");
}

void writeTextPointers(Stream to, char[][int] text) {
	foreach (k, v; text) writeTextPointer(to, k, v);
}

void writeTextPointers(Stream to, char[][] text) {
	foreach (k, v; text) writeTextPointer(to, k, v);
}

void StreamWriteStringR2(Stream to, char[] s) {
	uint total;
	ubyte[] temp;
	to.write(cast(ubyte[])s);
	total = (s.length + 1) * 2;
	if (total % 4 != 0) total = total + 4 - (total % 4);
	temp.length = total - s.length; to.write(temp);
}

void StreamWriteStringR2Fake(Stream to, char[] s) {
	uint total;
	ubyte[] temp;
	to.write(cast(ubyte[])s);
	total = (s.length + 1);
	if (total % 4 != 0) total = total + 4 - (total % 4);
	temp.length = total - s.length; to.write(temp);
}

void StreamWriteStringR2Fake2(Stream to, char[] s) {
	to.write(cast(ubyte[])s);
	to.write(cast(ubyte)0);
}

class GameFormatString {
	bool    showString = false;
	bool    delegate(Stream sin, Stream sout, ubyte c)[] rcb;
	char[]  delegate(char[] name, char[] data)[char[]]   wcb;

	this() {
	}

	int getStringzLength(Stream s, uint pos) {
		uint ret = 0; extractStringz(s, pos, &ret); return ret;
	}

	char[] extractStringz(Stream s, uint pos, uint *save = null) {
		if (pos == 0) return "";
		
		MemoryStream retval = new MemoryStream();
		uint backp = s.position; s.position = pos; scope(exit) { /*writefln("%08X-%08X", pos, s.position);*/ if (save) *save = s.position - pos; s.position = backp; }
		showString = false;
		while (!s.eof) {
			int n; ubyte c; s.read(c); if (c == 0) break;
			for (n = rcb.length - 1; n >= 0; n--) if (rcb[n](s, retval, c)) break;
			if (n < 0) retval.write(c);
		}
		if (showString) {
			fprintf(stderr, "DEBUG string: '%s'\n\n", toStringz(cast(char[])retval.data));
		}
		return cast(char[])retval.data;
	}

	char[] decodeString(char[] s) {
		Stream ss = new MemoryStream(s ~ "\0");
		return extractStringz(ss, 0);
	}

	char[] encodeString(Stream s) {
		MemoryStream retval = new MemoryStream();
		while (!s.eof) {
			int n; ubyte c; s.read(c); if (c == 0) break;

			//printf("'%c'", c);

			if (c == '<') {
				int isext = -1;
				bool ignore = false;
				char[] inner, name;
				do {
					s.read(c);
					if (c == ':') isext = inner.length;
					if (c == '*') {
						isext = inner.length;
						ignore = true;
					}
					if (c == '>') break;
					inner ~= c;
				} while(!s.eof);

				name = (isext != -1) ? std.string.toupper(std.string.strip(inner[0..isext])) : inner;

				//writefln("ignore: ", ignore, inner);
				//writefln("name: ", name);

				if (!((name in wcb) is null)) {
					if ((name in wcb) is null) throw(new Exception(std.string.format("Extension '%s' not implemented", name)));
					retval.write(cast(ubyte[])wcb[name](name, inner[isext + 1..inner.length]));
				} else if (isext >= 0) {
					throw(new Exception("gameformat: ext:, Not implemented"));
				} else {
					for (int m = 0; m < inner.length; m += 2) {
						retval.write(cast(ubyte)getdhvalue(inner[m..m + 2]));
					}
				}
			} else {
				retval.write(c);
			}
		}
		return cast(char[])retval.data;
	}

	char[] encodeString(char[] s) {
		return encodeString(new MemoryStream(s));
	}
}

class TOAGameFormatString : GameFormatString {
	bool ignoreParams = false;
	/*
	uint[][char] params;
	int[char] paramsp;
	*/
	uint[] params;
	int paramsp;

	this() {
		//rcb ~= &this.decodeJIS;
		rcb ~= &this.decodeSpecial;
		wcb["BUTTON"] = &this.encodeButton;
		wcb["PAGE"] = &this.encodePage;
		wcb["SPEECH"] = &this.encodeGuess;
		wcb["01"] = &this.encodeGuess;
		wcb["02"] = &this.encodeGuess;
		wcb["03"] = &this.encodeGuess;
		wcb["04"] = &this.encodeGuess;
		wcb["05"] = &this.encodeGuess;
		wcb["06"] = &this.encodeGuess;
		wcb["08"] = &this.encodeGuess;
		wcb["10"] = &this.encodeGuess;
		wcb["12"] = &this.encodeGuess;
		wcb["13"] = &this.encodeGuess;
	}

	char[] extractStringz(Stream s, uint pos, uint *save = null) {
		params = [];
		//foreach (k; params.keys) params.remove(k);
		//foreach (k; paramsp.keys) paramsp.remove(k);
		return GameFormatString.extractStringz(s, pos, save);
	}

	override char[] encodeString(Stream s) {
		MemoryStream retval = new MemoryStream();

		paramsp = 0;
		//foreach (k; paramsp.keys) paramsp[k] = 0;

		bool skip_jump = false;

		while (!s.eof) {
			int n; ubyte c; s.read(c); if (c == 0) break;

			//printf("'%c'", c);

			if (c == '<') {
				int isext = -1;
				bool ignore = false;
				char[] inner, name;
				do {
					s.read(c);
					if (c == ':') isext = inner.length;
					if (c == '*' && isext < 0) {
						isext = inner.length;
						ignore = true;
					}
					if (c == '>') break;
					inner ~= c;
				} while(!s.eof);

				name = (isext != -1) ? std.string.toupper(std.string.strip(inner[0..isext])) : inner;

				//writefln("ignore: ", ignore, inner);
				//writefln("name: ", name);

				if (!((name in wcb) is null)) {
					if ((name in wcb) is null) throw(new Exception(std.string.format("Extension '%s' not implemented", name)));
					if (name == "PAGE") { skip_jump = true; }
					retval.write(cast(ubyte[])wcb[name](name, inner[isext + 1..inner.length]));					
				} else if (isext >= 0) {
					throw(new Exception(std.string.format("gameformat: ext:%s, Not implemented", name)));
				} else {
					for (int m = 0; m < inner.length; m += 2) {
						retval.write(cast(ubyte)getdhvalue(inner[m..m + 2]));
					}
				}
			} else {
				if (c == '\n' && skip_jump) {
					skip_jump = false;
					continue;
				}
				retval.write(c);
			}
		}
		return cast(char[])retval.data;
	}

	char[] encodeString(char[] s) {
		return encodeString(new MemoryStream(s));
	}

	uint shiftParam(ubyte c) {
		//return params[c][paramsp[c]++];
		return params[paramsp++];

		/*
		if (((c in params) is null) || !params[c].length) return 0;
		uint v = params[c][0];
		for (int n = 0; n < params[c].length - 1; n++) params[c][n] = params[c][n + 1];
		params[c].length = params[c].length - 1;
		return v;
		*/
	}

	private char[] encodeGuess(char[] name, char[] data) {
		char[] ret; ret.length = 5;
		uint c;
		switch (name) {
			case "SPEECH": c = 8; break;
			default: c = getdhvalue(name); break;
		}
		*cast(uint *)(&ret[1]) = shiftParam(ret[0] = c);
		return ret;
	}

	private char[] encodePage(char[] name, char[] data) {
		return "\x0C";
	}

	private char[] encodeButton(char[] name, char[] data) {
		switch (std.string.tolower(data)) {
			case "leftstick": return "\x0B\x13";
			case "down":      return "\x0B\x15";
			case "backward":  return "\x0B\x16";
			case "forward":   return "\x0B\x17";
			case "cross":     return "\x0B\x1D";
			case "square":    return "\x0B\x1F";
			case "r2":        return "\x0B\x23";
			case "l2":        return "\x0B\x24";
			default:
				if (data.length == 2) return "\x0B" ~ cast(char)getdhvalue(data);
				throw(new Exception(std.string.format("Unknown button type '%s'", data)));
		}

		return "\x0B\xFF";
	}

	/**private bool decodeJIS(Stream sin, Stream sout, ubyte c) {
		if (c >= )
	}*/

	private bool decodeSpecial(Stream sin, Stream sout, ubyte c) {
		ubyte c2;

		//printf("[%02X]", c);

		switch (c) {
			case 0x09: // TAB
				// SB7: SNO_I05_03
				//DEBUG string: 'Okay"
				//<09>Run away'
				sout.writef("<%02X>", c);
				return true;
			break;

			case 0x01: // VARIABLE??
			case 0x02:
			case 0x03:
			case 0x04:
			case 0x05: // MONSTER_SKILL??
			case 0x06:
			case 0x08: // SPEECH
			case 0x10: // TITLE??
			case 0x12: // ?? (DEBUG?)
			case 0x13: // ??
			{ // ???
				uint v;
				sin.read(v);
				//params[c] ~= v;
				//paramsp[c] = 0;
				params ~= v;

				//writefln(params[c]);
				switch (c) {
					case 0x08:
						if (ignoreParams) {
							//sout.writef("<SPEECH:*%d>", params.length - 1);
							sout.writef("<SPEECH*>");
						} else {
							sout.writef("<SPEECH:%08X>", v);
						}
					break;
					default:
						if (ignoreParams) {
							//sout.writef("<%02X:*%d>", c, params.length - 1);
							sout.writef("<%02X*>", c);
						} else {
							sout.writef("<%02X:%08X>", c, v);
						}
					break;
				}

				return true;
			} break;

			/*
			case 0x04: { // ???
				uint v;
				sin.read(v);
				sout.writef("<04:%08X>", v);

				return true;
			} break;
			case 0x08: { // ???
				uint v;
				sin.read(v);
				sout.writef("<08:%08X>", v);

				return true;
			} break;
			*/
			case 0x0B: // Sustitución
				sin.read(c2);

				switch (c2) {
					case 0x13: sout.writef("<BUTTON:LEFTSTICK>"); break;
					case 0x15: sout.writef("<BUTTON:DOWN>"); break;
					case 0x16: sout.writef("<BUTTON:BACKWARD>"); break;
					case 0x17: sout.writef("<BUTTON:FORWARD>"); break;
					case 0x1D: sout.writef("<BUTTON:CROSS>"); break;
					case 0x1F: sout.writef("<BUTTON:SQUARE>"); break;
					case 0x23: sout.writef("<BUTTON:R2>"); break;
					case 0x24: sout.writef("<BUTTON:L2>"); break;
					default:   sout.writef("<BUTTON:%02X>", c2); break;
				}

				return true;
			break;
			case 0x0C: // Nueva página
				sout.writef("<PAGE>\n");
				return true;
			break;
			case '\n':
				sout.writef("\n");
				return true;
			break;
			default: break;
		}

		if (c < 20) {
			fprintf(stderr, "Código de control <%02X> no controlado en cadena\n", c);
			sout.writef("<%02X>", c);
			showString = true;
			return true;
		}

		// katanaka
		if (c >= 0xA1 && c <= 0xDF) {
			sout.writef("<%02X>", c);
			return true;
		}

		if (c >= 0x81 && c <= 0x9F) {
			sin.read(c2);
			sout.writef("<%02X%02X>", c, c2);
			return true;
		}

		if (c >= 0xE0 && c <= 0xEF) {
			sin.read(c2);
			sout.writef("<%02X%02X>", c, c2);
			return true;
		}

		if (c <= 0x7F) {
			sout.writef(cast(char)c);
			return true;
		}

		sout.writef("<%02X>", c);
		return true;

		//return false;
	}
}
