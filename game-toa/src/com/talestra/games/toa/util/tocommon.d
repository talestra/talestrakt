import std.stdio, std.stream, std.string, std.file, std.path;
import std.utf, std.math;
import vfs, iso, pfs;
import std.md5;

struct PTRSIZE {
	int ptr;
	int length;
	Stream s;
	
	static PTRSIZE opCall(int ptr, int length = 0, Stream s = null) {
		PTRSIZE p;
		p.ptr = ptr;
		p.length = length;
		p.s = s;
		return p;
	}
}

uint readUINT(Stream s) {
	uint v;
	s.read(v);
	return v;
}

char[][uint] getACME1(char[] s) {
	char[][uint] r;
	s = replace(s, "\r", "");
	foreach (token; std.string.split(s, "## POINTER ")) {
		int pos; //if ((pos = std.string.find(token, "\n")) == -1) continue;
		if (token.length == 0) continue;
		char[][] lines = split2(token, "\n", 2);
		int k = intFromBase(std.string.split(lines[0], " ")[0], 10);
		r[k] = (lines.length > 1) ? std.string.stripr(lines[1]) : "";
	}
	return r;
}

char[][uint] getACME(char[] s) {
	return getACME1(s);
}

char[][uint] getACME(Stream s) {
	ubyte[] data;
	data.length = s.size;
	s.read(data);
	return getACME(cast(char[])data);
}

PTRSIZE[] getSimplePTRSIZE(Stream s) {
	PTRSIZE[] r;
	uint count, bptr, ptr;
	s.read(count);
	s.read(bptr);
	count--;
	for (int n = 0; n < count; n++, bptr = ptr) {
		s.read(ptr);
		r ~= PTRSIZE(bptr, ptr - bptr, new SliceStream(s, bptr, ptr));
	}
	return r;
}

void setSimplePTRSIZE(Stream o, Stream[] ss) {
	uint pos = 4 + (ss.length + 1) * 4;
	o.write(cast(uint)(ss.length + 1));
	o.write(cast(uint)0);

	int zpos = 0;
	void setPointer() {
		uint bpos = o.position;
		o.position = 4 + zpos++ * 4;
		o.write(bpos);
		o.position = bpos;
	}
	
	foreach (s; ss) o.write(cast(uint)0);
	
	foreach (k, s; ss) {
		//writefln("a:%d (%d)", k, s.size);
		setPointer();
		o.copyFrom(s);
		//writefln("c:", k);

		while ((o.position % 4) != 0) o.write(cast(ubyte)0);
		
		s.close();
	}
	
	//writefln("-");
	
	setPointer();
}

char[] locale = "es";

char[] normalizePath(char[] path) {
	//return path.replaceSlice("\\", "/").replaceSlice("../", "/").replaceSlice("/..", "/").replaceSlice("//", "/");
	return path;
}

uint intFromBase(char[] s, int base = 10, bool _throw = true) {
	int r;
	foreach (c; s) { c = std.ctype.toupper(c);
		int v;
		if (0) {}
		else if (c >= '0' && c <= '9') v = c - '0';
		else if (c >= 'A' && c <= 'Z') v = c - 'A' + 10;
		if (v < base) {
			r *= base;
			r += v;
		} else if (_throw) {
			throw(new Exception("Invalid char"));
		}
	}
	return r;
}

long intFrom(char[] s, bool _throw = false) {
	if (!s.length) return 0;
	if (s[0] == '-') return -intFromBase(s[1..s.length]);
	if (s[0] == '0') {
		if (s.length >= 2) {
			switch (s[1]) {
				case 'x': return intFromBase(s[2..s.length], 16, _throw);
				case 'b': return intFromBase(s[2..s.length],  2, _throw);
			}
		}
		return intFromBase(s, 8, _throw);
	}
}

bool existsTempFile(char[] file)  { return FS.temp.exists(file ~ "." ~ locale);}

char[] getTempPath(char[] file) { return normalizePath(file); }

Stream getGameFile(char[] file) { return FS.gin[file].open; }
//Stream getPatchFile(char[] file) { return new BufferedFile("patch/" ~ normalizePath(file) ~ "." ~ locale); }
Stream getPatchFile(char[] file) { return FS.patch[normalizePath(file) ~ "." ~ locale].open; }
Stream getTempFile(char[] file, FileMode mode = FileMode.OutNew) { file = normalizePath(file);
	char[] cpp;

	try { mkdir("temp"); } catch { }
	foreach (cp; file.split("/")) {
		cpp ~= cp ~ "/";
		try { mkdir("temp/" ~ cpp); } catch { }
	}
	try { rmdir("temp/" ~ cpp); } catch { }
	
	//return new BufferedStream(new File("../temp/" ~ file ~ "." ~ locale, mode));
	return new File("temp/" ~ file ~ "." ~ locale, mode);
	//return new BufferedFile("../temp/" ~ file ~ "." ~ locale, mode);
}

char[][] getLines(Stream s) {
	char[][] r;
	while (!s.eof) {
		char[] l = std.string.strip(s.readLine());
		if (!l.length) continue;
		r ~= l;
	}
	return r;
}

char[][] split2(char[] s, char[] sub, uint count = 0x7FFFFFFF) {
	char[][] r = split(s, sub);
	if (count < 1) count = 1;
	if (r.length > count) r = r[0..count - 1] ~ std.string.join(r[count - 1..r.length], sub);
	return r;
}

class StringEncoder {
	static int[char[]][char[]] constants;
	static char[][int][char[]] constants_r;

	static void setConstant(char[] name, int value, char[] group = "") {
		constants[group][name]  = value;
		constants_r[group][value] = name;
	}

	static this() {
		setConstant("speech"   , 0x08);
		setConstant("button"   , 0x0B);
		setConstant("page"     , 0x0C);
	
		setConstant("leftstick", 0x13, "button");
		setConstant("down"     , 0x15, "button");
		setConstant("backward" , 0x16, "button");
		setConstant("forward"  , 0x17, "button");
		setConstant("cross"    , 0x1D, "button");
		setConstant("square"   , 0x1F, "button");
		setConstant("r2"       , 0x23, "button");
		setConstant("l2"       , 0x24, "button");
	}
	
	static uint getValue(char[] s, char[] group = "") {
		uint v;
		s = std.string.tolower(s);
		
		if (s.length && s[s.length - 1] == '*') s = s[0..s.length - 1];
		
		group = std.string.tolower(group);
		if ((group in constants) && (s in constants[group])) {
			v = constants[group][s];
		} else {
			try {
				v = intFromBase(s, 16, true);
			} catch (Exception e) {
				printf("Invalid hexadecimal sequence and constant not found: '%s'\n", toStringz(s));
			}
		}
		return v;
	}

	static ubyte[] encodeKey(char[] s, PARAM[] pp, inout int cparam) {
		char[][] p = s.split2(":", 2);
		uint c = getValue(p[0]);
		
		// Es par, vamos a comprobar si es un shift_jis
		if (c >= 0x20) {
			ubyte[] r;
			for (int n = 0; n < p[0].length; n += 2) {
				r ~= cast(ubyte)intFromBase(p[0][n..n + 2], 16, true);
			}
			return r;
		}
		
		switch (c) {
			case 0x0B: return [0x0B, cast(ubyte)getValue(p[1], "button")];
			case 0x0C: return [0x0C];
			default:
				//throw(new Exception(format("Not defined opcode 0x%02X", c)));
		}

		if (cparam >= pp.length) throw(new Exception("StringEncoder::parameterMismatch::1"));
		if (pp[cparam].c != c) throw(new Exception("StringEncoder::parameterMismatch::2"));
		
		ubyte[] r; r.length = 5;
		r[0] = c;
		//*(cast(uint *)&r[1]) = getValue(p[1]);
		*(cast(uint *)&r[1]) = pp[cparam++].p;

		//writefln("%s: %d, %d", p, getValue(p[0]), getValue(p[1], "button"));
		return cast(ubyte[])r;
	}

	static ubyte[] encode(char[] s, PARAM[] params = []) {
		ubyte[] r;
		s = replace(s, "<PAGE>\n", "<PAGE>"); // Quitamos los saltos de linea del <PAGE>
		int cparam = 0;
		for (int n = 0; n < s.length; n++) { char c = s[n];
			switch (c) {
				case '<':
					int m = ++n;
					for (; n < s.length; n++) { c = s[n];
						if (c == '>') break;
					}
					r ~= encodeKey(s[m..n], params, cparam);
				break;
				default: r ~= c;
			}
		}
		//writefln("%s", cast(char[])r);
		return r;
	}
	
	struct PARAM { uint c, p; }
	static PARAM[] params;
	
	static char[] decode(Stream s, bool ignoreParams = true, bool legacy = false) {
		char[] r;
		params = [];
		//printf("'");
		while (!s.eof) {
			ubyte c; s.read(c); if (c == 0) break;

			//if (c == '\n') printf("\\n"); else printf("%c", c);
			
			if (c < 0x20) {
				if (c == 0x0A) {
					r ~= "\n";
				} else if (c == 0x0C) {
					if (legacy) {
						r ~= "<PAGE>\n";
					} else {
						r ~= "<PAGE>";
					}
				} else if (c == 0x0B) {
					ubyte p;
					s.read(p);
					r ~= format("<BUTTON:%02X>", p);
				} else {
					uint p;
					s.read(p);
					if (legacy) {
						char[] fmt;
						switch (c) {
							case 0x08: fmt = "SPEECH"; break;
							default: fmt = format("%02X", c);
						}
						r ~= format("<%s*>", fmt);
					} else {
						if (ignoreParams) {
							r ~= format("<%02X>", c);
						} else {
							//r ~= format("<%02X:%08X>", c, p);
							r ~= format("<%02X:#F%d>", c, p / 40);
						}
					}
					params ~= PARAM(c, p);
				}
			} else {
				if (c == '<') {
					r ~= format("<%02X>", c);
				} else if (c == '\xFF') {
					r ~= format("<%02X>", c);
				} else {
					if (legacy) {
						if ((c >= 0x81 && c <= 0x9F) || (c >= 0xE0 && c <= 0xEF)) {
							r ~= "<";
							r ~= format("%02X", c);
							s.read(c);
							r ~= format("%02X", c);
							r ~= ">";
						} else {
							r ~= c;
						}
					} else {
						r ~= c;
					}
				}
			}
		}
		//printf("'\n");
		
		/*if (params.length) {
			writefln("--> %s", r);
		}*/
		
		//if (legacy) r = strip(r);
		
		return r;
	}
}

import std.c.windows.windows;

real secondsElapsed() {
	long count, freq;
	QueryPerformanceCounter(&count);
	QueryPerformanceFrequency(&freq);
	return ((cast(real)count) / (cast(real)freq));
}

real secondsPatcher() { return secondsElapsed - secondsStart; }

class Progress {
	static struct ProgressEntry {
		char[] name = "";
		long cur = 0, max = 1;
		real meanTicks = 0, meanTime = 0, meanTimeMult;
		real startTime = 0, lastTime = 0;
		real progressTime() { return secondsPatcher - startTime; }
		//real ETA() { return (progressTime * max) / cur; }
		real _ETA() { return meanTime * cast(real)(max - cur); }
		real ETA() {
			real r = _ETA;
			//if (r > minETA) r = minETA;
			//if (r < minETA) minETA = r;
			return r;
		}
		
		real minETA = 999999999999999;
		
		void updateTime() {
			real csp = secondsPatcher;
			real tickTime = csp - lastTime;
			meanTimeMult = sqrt(meanTicks);
			
			//if (fabs(tickTime - meanTime) > (meanTime * 10)) meanTimeMult = (meanTicks / 3);
			if (meanTimeMult < 1) meanTimeMult = 1;
			if (meanTicks < 0) meanTicks = 0;
			
			meanTime = (meanTime * meanTicks + tickTime * meanTimeMult) / (meanTicks + meanTimeMult);
			meanTicks++;
			lastTime = csp;
		}
	}
	
	static void function(ProgressEntry[] progressStack, int end) updateCallback;
	
	static bool justPopped;

	static ProgressEntry[] progressStack;
	
	static void sendUpdate(int end = 0) {
		if (!updateCallback) return;
		updateCallback(progressStack.dup, end);
	}
	
	static int length() { return progressStack.length; }
	static void push(char[] name = null, int max = 0) {
		justPopped = false;
		writefln();
		progressStack ~= ProgressEntry();
		current.lastTime = current.startTime = secondsPatcher;
		if (name !is null) title(name, max);
	}
	static void pop() { progressStack.length = progressStack.length - 1; justPopped = true; sendUpdate(); }
	
	static ProgressEntry* current() { if (length == 0) return null; return &progressStack[progressStack.length - 1]; }
	
	static private void printPadding(int length) {
		if (justPopped) {
			writefln();
			justPopped = false;
		}
		for (int n = 0; n < length - 1; n++) printf("  ");
	}
	
	static void title(char[] name, int max = 0) {
		if (!current) return;
		current.name = name;
		current.max = max;
		current.cur = 0;
		
		//std.gc.fullCollect();
		std.gc.genCollect();

		printPadding(length);
		printf("%s\r", toStringz(current.name));
		
		sendUpdate();
	}

	static void set(long cur, long max = 0, char[] name = "") {
		if (!current) return;
		if (cur < 0) cur = current.cur - cur;
		current.cur = cur;
		if (max != 0) current.max = max;

		printPadding(length);
		//printf("progress[%d]: '%s' (%lld, %lld)", length, toStringz(current.name), current.cur, current.max);
		printf("%s: (%lld/%lld)", toStringz(current.name), current.cur, current.max);
		
		printf(" : %.2f", cast(float)current.ETA);
		if (name.length) printf(" : '%s'", toStringz(name));
		
		printf(" \r");
		
		current.updateTime();
		sendUpdate();
	}
}

void copy2(Stream from, char[] to, bool autoclose = true) {
	//scope Stream sto = new BufferedFile(to, FileMode.OutNew);
	scope Stream sto = new File(to, FileMode.OutNew);
	from.position = 0;
	sto.copyFrom(from);
	sto.close();
	if (autoclose) from.close();
}

void writeln(char[] s) {
	printf("%s\n", toStringz(s));
}

void writes(char[] s) {
	printf("%s", toStringz(s));
}

class FS {
	static FileContainer gin;
	static FileContainer gout;
	static FileContainer temp;
	static FileContainer patch;
	static FileContainer movie;
	static FileContainer res;

	static Iso getAbyssIso(char[] path, bool readonly = false) {
		Iso iso = new Iso(path, readonly);

		try {
			iso.mount("npc",   new Iso(iso["TO7NPC.CVM"].open));
			iso.mount("btl",   new Iso(iso["TO7BTL.CVM"].open));
			iso.mount("ev",    new Iso(iso["TO7EV.CVM"].open));
			iso.mount("map",   new Iso(iso["TO7MAP.CVM"].open));
			iso.mount("mov",   new Iso(iso["TO7MOV.CVM"].open));
			iso.mount("bgm",   new Iso(iso["TO7BGM.CVM"].open));
			iso.mount("root",  new Iso(iso["TO7ROOT.CVM"].open));
			iso.mount("se",    new Iso(iso["TO7SE.CVM"].open));
			iso.mount("field", new Iso(iso["TO7FIELD.CVM"].open));	
		} catch (Exception e) {
			writefln("FS.setAbyssIsos::error(%s)", e.toString);
		}
		
		return iso;
	}
	
	static void setAbyssIsos1(char[] i_in, char[] i_out) {
		if (gin) {
			gin.close();
			delete gin;
		}

		gin  = getAbyssIso(i_in, true);
	}

	static void setAbyssIsos2(char[] i_in, char[] i_out) {
		if (gout) {
			gout.close();
			delete gout;
		}

		bool recopy = false;
		
		if (!std.file.exists(i_out)) recopy = true;
		try { if (std.file.getSize(i_out) != std.file.getSize(i_in)) recopy = true; } catch (Exception e) { }
		
		if (recopy) {
			Progress.push("Duplicando iso");
			ubyte[] data; data.length = 0x4000000;
			
			auto sin = new BufferedStream(gin.open);
			auto sout = new File(i_out, FileMode.OutNew);
			
			sin.position = 0;
			while (!sin.eof) {
				Progress.set((sin.position * 100) / sin.size, 100);
				sout.write(data[0..sin.read(data)]);
				patch_stopPoint();
			}
			
			delete sin;
			delete sout;
			
			delete data;
			Progress.pop();
		}
		
		gout = getAbyssIso(i_out, false);
	}
	
	static void setAbyssIsos(char[] i_in, char[] i_out) {
		if (i_in == i_out) throw(new Exception("El archivo de origen y de destino no debe coincidir."));
	}
	
	static this() {
		try { mkdir("temp"); } catch { }
		try { mkdir("logs"); } catch { }
		try { mkdir("temp/map"); } catch { }
		try { mkdir("temp/se"); } catch { }
		//try { mkdir("temp/tv"); } catch { }
		try { mkdir("temp/btl"); } catch { }
		//try { mkdir("temp/field"); } catch { }
		//try { mkdir("temp/field/script"); } catch { }
		try { mkdir("temp/root"); } catch { }
		temp  = new Directory("temp");
		//patch = new Directory("patch");
		patch = pfs.patch_fs;
		movie = new Directory("movie");
		res   = new Directory("res");
		gin   = new FileContainer();
		gout  = new FileContainer();
	}
}

debug = RangeListDebug;

void log(char[] text, char[] type = "undefined", int level = 0) {
	static Stream ss;
	if (!ss) ss = new File("logs/action.log", FileMode.OutNew);
	ss.writeString(type);
	ss.writef("(%d):", level);		
	ss.writeString(text);
	ss.writefln();
}

class RangeList {
	int padding = 1;
	int[int] rangeStart;
	int[int] rangeEnd;

	int getLastPosition() {
		int last = 0;
		foreach (int r, int l; rangeStart) if (r + l > last) last = r + l;
		return last;
	}

	void show() {
		//rangeEnd = rangeStart.rehash;
		foreach (int r, int l; rangeStart) writefln("RANGE: %08X-%08X(%d)", r, r + l, l);
	}

	uint showSummary() {
		uint c = 0; foreach (int r, int l; rangeStart) c += l;
		writefln(format("%s {", this.toString));
		writefln("  RANGE SPACE: %d", c);
		writefln("}");
		return c;
	}

	void add(int from, int length) {
		/*if (from in rangeStart) {
			if (length > rangeStart[from]) {
				rangeEnd.remove(from + rangeStart[from]);
				rangeStart[from] = length;
				rangeEnd[from + length] = length;
			}
			return;
		}*/

		foreach (int afrom, int alen; rangeStart) {
			if (from >= afrom && from < afrom + alen) {
				return;
			}
		}

		//printf("ADD_RANGE: %08X, %d\n", from, length);

		if (from in rangeEnd) {
			int rstart = from - rangeEnd[from];
			rangeStart[rstart] += length;
			rangeEnd.remove(from);
			rangeEnd[from + length] = rangeStart[rstart];
		} else {
			rangeStart[from] = rangeEnd[from + length] = length;
		}

		//removeInnerRanges();

		//showRanges();
	}

	int removeInner() {
		int removed = 0;
		bool done = false;
		while (!done) {
			done = true;
			foreach (int afrom, int alen; rangeStart) {
				foreach (int bfrom, int blen; rangeStart) {
					if (afrom == bfrom) continue;

					if (bfrom < afrom + alen && bfrom + blen > afrom + alen) {
						show();

						writefln("%08X(%d)", afrom, alen);
						writefln("%08X(%d)", bfrom, blen);

						assert(1 == 0);
					}

					if (bfrom < afrom && bfrom + blen > afrom) {
						show();
						assert(1 == 0);
					}

					if (afrom >= bfrom && afrom + alen <= bfrom + blen) {
						done = false;
						rangeEnd.remove(afrom + alen);
						rangeStart.remove(afrom);
						removed++;
						break;
					}
				}

				if (!done) break;
			}
		}
		return removed;
	}

	void use(int from, int length) {
		debug (RangeListDebug) log(format("%d:%d", from, length), "RangeList");
		rangeEnd[from + rangeStart[from]] -= length;
		if (rangeStart[from] - length > 0) {
			rangeStart[from + length] = rangeStart[from] - length;
		}
		rangeStart.remove(from);
	}

	int getFreeRange(int length, uint _align = 1, uint nearTo = 0) {
		foreach (key; rangeStart.keys.sort) {
			int length2 = length;
			if ((key % _align) != 0) length2 += _align - (key % _align);
			if (rangeStart[key] >= length2) return key;
		}
		throw(new Exception(format("Not enough space (%d)", length)));
	}

	int getAndUse(int length, uint _align = 1, uint nearTo = 0) {
		int r;
		use(r = getFreeRange(length, _align, nearTo), length);
		if ((r % _align) != 0) r += _align - (r % _align);
		return r;
	}

	int length() {
		int r = 0; foreach (int l; rangeStart) r += l; return r;
	}
}

class RangeListEx : RangeList {
	Stream stream;
	long offset;
	uint[char[]] reserved;
	char[][uint] reserved_r;
	
	bool useReserved = true;
	
	this(Stream stream, long offset) {
		this.stream = stream;
		this.offset = offset;
	}
	
	void put4(char[] s, int maxlen = 0xFFFFF) {
		put(s, maxlen, 4);
	}
	
	uint put(char[] s, int maxlen = 0xFFFFF, uint _align = 1) {
		if (useReserved) if (s in reserved) return reserved[s];
		
		char[] str = cast(char[])StringEncoder.encode(s) ~ "\0";
		if (str.length > maxlen) {
			writeln("'" ~ s ~ "'");
			throw(new Exception(format("Longitud máxima permitida superada (%d > %d)", str.length, maxlen)));
		}
		uint pos = getAndUse(str.length, _align);
		Stream ss = new SliceStream(stream, pos - offset);
		ss.writeString(str);
		if (useReserved) {
			reserved[s] = pos;
			reserved_r[pos] = s;
		}
		return pos;
	}

	uint putBin(ubyte[] s) {
		uint pos = getAndUse(s.length);
		Stream ss = new SliceStream(stream, pos - offset);
		ss.write(s);
		return pos;
	}
	
	void clean(int from, int to) {
		int length = to - from;
		add(from, length);
		ubyte[] data; data.length = length;
		for (int n = 0; n < data.length; n++) data[n] = 0x00;
		stream.position = from - offset;
		stream.write(data);
	}

	void cleanLen(int from, int len) {
		clean(from, from + len);
	}
}

bool patch_stop_value = false;
bool patch_stopped = false;
real secondsStart;

void patch_stop() {
	patch_stop_value = true;
}

void patch_start() {
	patch_stop_value = false;
	patch_stopped = false;
	secondsStart = secondsElapsed;
}

void patch_stopPoint() {
	if (patch_stop_value) {
		patch_stopped = true;
		throw(new Exception(""));
	}
}

ubyte[] md5(Stream s) {
	ubyte[16] r;
	ubyte[] buf;
	buf.length = 0x1000;

	MD5_CTX context;
	long back = s.position;
	s.position = 0;
	
	context.start();
		while (!s.eof) context.update(buf[0..s.read(buf)]);
	context.finish(r);
	
	s.position = back;
	return r[0..16];
}

char hexdigit(int v) { return "0123456789abcdef"[v & 0xF]; }

char[] hexdump(ubyte[] data) {
	char[] r;
	foreach (c; data) {
		r ~= hexdigit((c >> 4) & 0xF);
		r ~= hexdigit((c >> 0) & 0xF);
	}
	return r;
}