import std.stdio, std.string, std.file, std.stream, std.c.stdlib, std.conv, std.regexp;

// Version of the utility.
const char[] _version = "0.3";

/*
OPCODES:

000 - PUSH_INT <INT:INT>?
003 - PUSH_STRING <STR:STR>
03F - STACK_SIZE <INT:???>
07F - SCRIPT_LINE <STR:FILE> <INT:LINE>

0F0 - CALL_SCRIPT

140 - PUT_TEXT text, title, i0, i1, i2

*/

int min(int a, int b) { return (a < b) ? a : b; }
int max(int a, int b) { return (a > b) ? a : b; }
bool between(int a, int m, int M) { return (a >= m) && (a <= M); }

char[] addslahses(char[] t) {
	char[] r;
	foreach (c; t) {
		switch (c) {
			case '\n': r ~= r"\n"; break;
			case '\\': r ~= r"\\"; break;
			case '\r': r ~= r"\r"; break;
			case '\t': r ~= r"\t"; break;
			default: r ~= c;
		}
	}
	return r;
}

char[] stripslashes(char[] t) {
	char[] r;
	for (int n = 0; n < t.length; n++) {
		char c = void;
		switch (c = t[n]) {
			case '\\':
				switch (c = t[++n]) {
					case 'n': r ~= "\n"; break;
					case 'r': r ~= "\r"; break;
					case 't': r ~= "\t"; break;
					case '\\': r ~= "\\"; break;
					default: r ~= c; break;
				}
			break;
			default: r ~= c;
		}
	}
	return r;
}

char[] substr(char[] s, int start, int len = 0x7F_FF_FF_FF) {
	int end = s.length;
	if (start < 0) start = s.length - (-start) % s.length;
	if (start > s.length) start = s.length;
	if (len < 0) end -= (-len) % s.length;
	if (len >= 0) end = start + len;
	if (end > s.length) end = s.length;
	return s[start..end];
}

char[][] explode(char[] delim, char[] str, int length = 0x7FFFFFFF, bool fill = false) {
	char[][] rr;
	char[] str2 = str;

	while (true) {
		int pos = std.string.find(str2, delim);
		if (pos != -1) {
			if (rr.length < length - 1) {
				rr ~= str2[0..pos];
				str2 = str2[pos + 1..str2.length];
				continue;
			}
		}
		
		rr ~= str2;
		break;
	}
	
	if (fill && length < 100) while (rr.length < length) rr ~= "";
	
	return rr;
}

unittest {
	char[] c;
	c = "This is\n a test.\t\t\\\r\\\\\\.";
	assert(stripslashes(addslashes(c)) == c);
}

// SJIS

// http://msdn.microsoft.com/en-us/library/ms776413(VS.85).aspx
// http://msdn.microsoft.com/en-us/library/ms776446(VS.85).aspx
// http://www.microsoft.com/globaldev/reference/dbcs/932.mspx

extern(Windows) {
	int MultiByteToWideChar(uint CodePage, uint dwFlags, char* lpMultiByteStr, int cbMultiByte, wchar* lpWideCharStr, int cchWideChar);
	int WideCharToMultiByte(uint CodePage, uint dwFlags, wchar* lpWideCharStr, int cchWideChar, char* lpMultiByteStr, int cbMultiByte, char* lpDefaultChar, int* lpUsedDefaultChar);
}

wchar[] sjis_convert_utf16(char[] data) { return convert_to_utf16(data, 932); }
char[] sjis_convert_utf8(char[] data) { return std.utf.toUTF8(sjis_convert_utf16(data)); }

wchar[] convert_to_utf16(char[] data, int codepage) {
	wchar[] out_data = new wchar[data.length * 4];
	int len = MultiByteToWideChar(
		codepage,
		0,
		data.ptr,
		data.length,
		out_data.ptr,
		out_data.length
	);
	return out_data[0..len];
}

char[] convert_from_utf16(wchar[] data, uint codepage) {
	char[] out_data = new char[data.length * 4];
	int len = WideCharToMultiByte(
		codepage,
		0,
		data.ptr,
		data.length,
		out_data.ptr,
		out_data.length,
		null,
		null
	);
	return out_data[0..len];
}

char[] mb_convert_encoding(char[] str, int to_codepage, int from_codepage) {
	return convert_from_utf16(convert_to_utf16(str, from_codepage), to_codepage);
}

uint charset_to_codepage(char[] charset) {
	charset = replace(std.string.tolower(strip(charset)), "-", "_");
	switch (charset) {
		case "shift_jis": return 932;
		case "utf_16": return 1200;
		case "utf_32": return 12000;
		case "utf_7": return 65000;
		case "utf_8": return 65001;
		case "windows_1252", "latin_1", "iso_8859_1": return 1252;
		default: throw(new Exception("Unknown charset '" ~ charset ~ "'"));
	}
}

char[] mb_convert_encoding(char[] str, char[] to_encoding, char[] from_encoding) {
       return mb_convert_encoding(str, charset_to_codepage(to_encoding), charset_to_codepage(from_encoding));
}

class BSS {
	static class OP {
		uint ori_pos;
		uint type;
		enum TYPE { INT, STR, PTR };
		int[]    i;
		char[][] s;
		TYPE[]   t;
		static OP opCall(uint type) {
			OP op = new OP;
			op.type = type;
			return op;
		}
		OP ori(int v) { ori_pos = v; return this; }
		OP push(int v   ) { i ~= v; s ~= null; t ~= TYPE.INT; return this; }
		OP push(char[] v) { i ~= 0; s ~= v;    t ~= TYPE.STR; return this; }
		OP pushPTR(int v) { i ~= v; s ~= null; t ~= TYPE.PTR; return this; }
		long length() { return i.length; }
		char[] toString() {
			char[] r;
			if (type == 0x7F) {
				return format("\n%s_%d:", s[0], i[1]);
			}
			switch (type) {
				case 0x0_00: r = "PUSH_INT";  break;
				case 0x0_01: r = "PUSH_PTR";  break;
				case 0x0_03: r = "PUSH_STR";  break;
				case 0x0_3F: r = "STACK";     break;
				case 0x1_40: r = "TEXT_PUT";  break;
				case 0x1_4D: r = "TEXT_SIZE"; break;
				default: r = std.string.format("OP_%03X", type); break;
			}
			r ~= " ";
			for (int n = 0; n < length; n++) {
				if (n != 0) r ~= ", ";
				r ~= (s[n] !is null) ? ("'" ~ s[n] ~ "'") : format("%d", i[n]);
			}
			r ~= "";
			return r;
		}
		int popi() {
			if (i.length <= 0) return 0;
			int r = i[i.length - 1];
			s.length = t.length = i.length = (length - 1);
			return r;
		}
		long size() { return 4 + length * 4; }
		void print() { printf("%s\n", toStringz(toString)); }
	}
	OP[] ops;
	void parse(char[] name) {
		parse(new BufferedFile(name, FileMode.In));
	}
	void parse(Stream s) {
		ubyte[] data = cast(ubyte[])s.readString(s.size - s.position);
		uint* op_ptr, op_start, op_end = cast(uint *)(data.ptr + data.length);
		ops = null;
		
		for (op_start = op_ptr = cast(uint *)data.ptr; op_ptr < cast(uint *)(data.ptr + data.length); op_ptr++) {
			if (op_end !is null) {
				//writefln("%08X: %08X", op_ptr, op_end);
				if (op_ptr >= op_end) break;
			}
			auto op = OP(*op_ptr).ori((op_ptr - op_start) * 4);
			
			int pushInt() {
				int v = cast(int)*(++op_ptr);
				op.push(v);
				return v;
			}

			int pushPtr() {
				int v = cast(int)*(++op_ptr);
				op.pushPTR(v);
				return v;
			}

			char[] pushStr() {
				int pos = cast(int)*(++op_ptr);
				//writefln("    : %08X", pos);
				char *ptr = cast(char *)data.ptr + pos;
				if (cast(uint *)ptr < cast(uint *)op_end) op_end = cast(uint *)ptr;

				char[] v = std.string.toString(ptr);
				//writefln("      '%s'", v);
				op.push(v);
				return v;
			}
			
			//writefln("%08X", op.type);
			switch (op.type) {
				case 0x0_00: pushInt(); break; // PUSH_INT
				case 0x0_01: pushPtr(); break; // PUSH_ADDR?
				case 0x0_02: break; // ??
				case 0x0_03: pushStr(); break; // PUSH_STRING
				case 0x0_04: pushInt(); break; // ??
				case 0x0_09: pushInt(); break; // PUSH_??
				case 0x0_19: pushInt(); break; // ??
				/*
				case 0x0_10: pushInt(); pushInt(); break; // ??
				case 0x0_11:
					pushInt();
					int size = pushInt();
					string_ptr = size + (op_ptr - op_start);
					op_end = cast(uint *)((cast(ubyte *)op_ptr) + size);
				break;
				*/
				case 0x0_3F:
					pushInt();
				break;
				case 0x0_7F: { // SCRIPT_LINE
					pushStr();
					pushInt();
				} break;
				case 0x0_F0: break; // SCRIPT_CALL
				case 0x0_1E: break;
				case 0x0_20: break;
				case 0x0_21: pushInt(); pushInt(); break; // UNK_STACK_OP_22
				case 0x0_22: break; // UNK_STACK_OP_22
				case 0x1_80: break; // AUDIO
				case 0x1_4D: break;  // TEXT_SIZE
				case 0x1_40: break; // TEXT_WRITE
				default:
				break;
			}

			ops ~= op;
		}
	}
	ubyte[] serialize() {
		int[char[]] table;
		uint[] ins; char[] str; int str_start;
		foreach (op; ops) str_start += op.size;

		foreach (op; ops) {
			ins ~= op.type;
			for (int n = 0; n < op.length; n++) {
				if (op.s[n] is null) {
					ins ~= op.i[n];
				} else {
					auto s = op.s[n];
					if ((s in table) is null) {
						table[s] = str_start + str.length;
						str ~= s ~ '\0';
					}
					ins ~= table[s];
				}
			}
			//writefln(op);
		}
		return cast(ubyte[])ins ~ cast(ubyte[])str;
	}
	void write(char[] name) {
		scope s = new BufferedFile(name, FileMode.OutNew); write(s); s.close();
	}
	void write(Stream s) {
		s.write(serialize);
	}
	void dump() {
		int pos = 0;
		foreach (k, op; ops) {
			printf("%08d: %s\n", pos, toStringz(op.toString));
			pos += op.size;
		}
	}
	void insert(int pos, OP[] new_ops) {
		ops = ops[0..pos] ~ new_ops ~ ops[pos..ops.length] ;
	}
	void patchStrings(ACME acme) {
		struct PATCH { int pos; OP[] ops; }
		PATCH[] patches;
		int line, line_pos;
		OP[] pushes;
		OP sstack = OP(0);
		int font_width = 22, font_height = 22;
		int last_op_type;
		bool changed_size = false;
		foreach (pos, op; ops) {
			switch (op.type) {
				case 0x7F: // SCRIPT_LINE
					if (last_op_type == 0x1_4D) {
						changed_size = true;
					} else {
						changed_size = false;
					}
					line = op.i[1];
					line_pos = pos + 1;
					sstack = OP(-1);
					pushes = null;
				break;
				case 0x00: sstack.push(op.i[0]); pushes ~= op; break;
				case 0x03: sstack.push(op.s[0]); pushes ~= op; break;
				case 0x3F:
					//writefln(op);
				break;
				case 0x1_40: // TEXT_WRITE
					//writefln("TEXT_WRITE");
					if (acme.has(line)) {
						char[] text = acme[line].text;
						
						if (sstack.s[1] !is null) {
							sstack.s[1] = sstack.s[1];
						}
						//writefln("::%s::%s::", sstack.s[1], text);
						
						// Has title.
						if ((sstack.s[1] !is null) && sstack.s[1].strip().length) {
							auto tt = explode("\n", text, 2);
							auto title = strip(tt[0]); text = (tt.length >= 2) ? tt[1] : "";
							assert(title.length > 2, format("ID/Line(@%d): Title length > 2", line));
							assert(title[0] == '{', format("ID/Line(@%d): Line doesn't start by '{'", line));
							assert(title[title.length - 1] == '}', format("ID/Line(@%d): Line end by '}'", line));
							title = title[1..title.length - 1];
							//while (title.length < 5) title ~= " ";
							// Ignore current title, and use the original one.
							// Another title won't work on Edelweiss.
							title = sstack.s[1];
							//writefln(pushes[1]);
							pushes[1].s[0] = title;
						}
						// Has text.
						if (sstack.s[0] !is null) {
							auto ttext = stripr(text);
							//writefln(pushes[0]);
							pushes[0].s[0] = ttext = ttext.replace("\r", "").replace("\n ", " ").replace(" \n", " ").replace("\n", " ");
							//pushes[0].s[0] = ttext;
							
							int calc_lines = (ttext.length / 42) + 1;

							if ((font_height <= 22) && (font_height >= 19)) {
								int calc_height = 22;
								if (ttext.length <= 44 * 3) {
									calc_height = 22;
								} else if (ttext.length <= 44 * 4) {
									calc_height = 20;
								} else if (ttext.length < 44 * 5) {
									calc_height = 19;
								}
								//int calc_height = 22 - cast(int)(1.1 * (calc_lines - 2));
								//calc_height = max(19, min(calc_height, 22));
								if (calc_height != font_height) {
									// 2, font_width, font_height, 0
									PATCH patch;
									{
										patch.pos = line_pos;
										patch.ops ~= OP(0x00).push(2);
										patch.ops ~= OP(0x00).push(calc_height);
										patch.ops ~= OP(0x00).push(calc_height);
										patch.ops ~= OP(0x00).push(0);
										patch.ops ~= OP(0x3F).push(4);
										patch.ops ~= OP(0x1_4D);
									}
									patches ~= patch;
									font_height = calc_height;
								}
							}
						}
					}
				break;
				case 0x0_22:
					int a = sstack.popi();
					int b = sstack.popi();
					pushes.length = pushes.length - 1;
					sstack.push(a * b);
				break;
				case 0x1_4D:
					//writefln("TEXT_SIZE: %s", sstack);
					font_width  = sstack.i[0];
					font_height = sstack.i[1];
				break;
				default:
				break;
			}
			last_op_type = op.type;
		}
		
		int disp = 0;
		foreach (patch; patches) {
			insert(patch.pos + disp, patch.ops);
			disp += patch.ops.length;
		}
		
		// Fix pointers.
		int size = 0;
		int[int] translate;
		foreach (op; ops) {
			translate[op.ori_pos] = size;
			//writefln("%d, %d", op.ori_pos, size);
			size += op.size;
		}
		int pos = 0;
		foreach (op; ops) {
			pos += op.size;
			//if (op.type == 0x11) op.i[1] = size - pos;
			foreach (k, t; op.t) {
				try {
					if (t == OP.TYPE.PTR) {
						op.i[k] = translate[op.i[k]];
						//writefln("Update!");
					}
				} catch (Exception e) {
					writefln("Error: %s", e);
				}
			}
		}
	}
	
	ACME extract() {
		auto acme = new ACME;
		OP sstack = OP(0);
		int line, line_pos;

		foreach (pos, op; ops) {
			switch (op.type) {
				case 0x7F: // SCRIPT_LINE
					line = op.i[1];
					line_pos = pos + 1;
					sstack = OP(-1);
				break;
				case 0x00:
					sstack.push(op.i[0]);
				break;
				case 0x03:
					//writefln("%s", op.s[0]);
					sstack.push(op.s[0]);
				break;
				case 0x1_40: // TEXT_WRITE
					//writefln("TEXT_WRITE");
					char[] r;
					char[] title = sstack.s[$ - 2].strip();
					if (title.length) r ~= "{" ~ title ~ "}\n";
					r ~= sstack.s[$ - 1];
					//writefln(" ## %s", title);
					acme.add(line, r);
				break;
				default:
				break;
			}
		}

		return acme;
	}
}

class ACME {
	static class Entry {
		long id;
		char[] text;
		char[][char[]] attribs;
		void header(char[] header) {
			auto r = new RegExp("^(\\d+)");
			auto ss = r.match(header);
			id = std.conv.toInt(ss[1]);
			//writefln(header);
		}
		char[] toString() {
			return (
				std.string.format("## POINTER %d\n", id)
				~ text ~ "\n\n"
			);
		}
	}
	Entry add(long id, char[] text) {
		Entry e = new Entry;
		e.text = text;
		entries[e.id = id] = e;
		return e;
	}
	Entry[long] entries;
	void parse(char[] name) {
		parse(new BufferedFile(name));
	}
	bool has(long idx) { return ((idx in entries) !is null); }
	Entry opIndex(long idx) {
		if ((idx in entries) is null) return null;
		return entries[idx];
	}
	long length() { return entries.length; }
	void parse(Stream s) {
		entries = null;
		s.position = 0; auto data = s.readString(s.size);
		auto ss = std.string.split(data, "## POINTER ");
		ss = ss[1..ss.length];
		foreach (line; ss) {
			auto e = new Entry;
			int pos = std.string.find(line, '\n');
			assert(pos >= 0);
			e.header(line[0..pos].strip());
			e.text = line[pos + 1..line.length].stripr();
			entries[e.id] = e;
		}
	}
	
	void parseForm2(char[] filename, char[] lang = "es") {
		scope s = new BufferedFile(filename);
		parseForm2(s, lang);
		s.close;
	}
	void parseForm2(Stream s, char[] lang = "es") {
		int id;
		entries = null;
		Entry e = new Entry;
		
		auto data = s.readString(s.size);
		data = mb_convert_encoding(data, "latin_1", "utf_8");
		s = new MemoryStream(data);
		
		while (!s.eof) {
			auto line = s.readLine();
			char c = line.length ? line[0] : '\0';
			switch (c) {
				case '#': // Comment
				break;
				case '@': // ID
					e = new Entry;
					e.id = std.conv.toInt(line[1..line.length]);
					e.text = "";
					entries[e.id] = e;
				break;
				case '<': // Text
					char[] add_text = stripslashes(substr(line, 4)).stripr();
					if (substr(line, 0, 4) == "<" ~ lang ~ ">") {
						if (add_text.length) e.text = add_text;
					} else if (!e.text.length) {
						e.text = add_text;
					}
				break;
				default: // Ignore.
				break;
			}
		}
	}
	
	void writeForm2(char[] filename, char[] file = "unknown") {
		scope s = new BufferedFile(filename, FileMode.OutNew);
		{
			writeForm2(s, file);
		}
		s.close();
	}
	
	void writeForm2(Stream s, char[] file = "unknown") {
		s.writefln("# Comments for '%s'", file);
		s.writefln();
		foreach (k; entries.keys.sort) {
			auto t = entries[k];
			s.writefln("@%d", k);
			s.writefln("<en>%s", addslahses(t.text));
			s.writefln("<es>");
			s.writefln();
		}
	}
	
	char[] toString() {
		char[] r;
		foreach (e; entries) r ~= e.toString;
		return r;
	}
}

class Segments {
	static class Segment {
		long l, r;
		long w() { return r - l; }
		alias w length;
		static bool intersect(Segment a, Segment b, bool strict = false) {
			return (strict
				? (a.l <  b.r && a.r >  b.l)
				: (a.l <= b.r && a.r >= b.l)
			);
		}
		bool valid() { return w >= 0; }
		static Segment opCall(long l, long r) {
			auto v = new Segment;
			v.l = l;
			v.r = r;
			return v;
		}
		int opCmp(Object o) { Segment that = cast(Segment)o;
			long r = this.l - that.l;
			if (r == 0) r = this.r - that.r;
			return r;
		}
		int opEquals(Object o) { Segment that = cast(Segment)o; return (this.l == that.l) && (this.r == that.r); }
		void grow(Segment s) {
			l = min(l, s.l);
			r = max(r, s.r);
		}
		char[] toString() { return format("(%08X, %08X)", l, r); }
	}
	Segment[] segments;
	void refactor() {
		segments = segments.sort;
		/*
		Segment[] ss = segments; segments = [];
		foreach (s; ss) if (s.valid) segments ~= s;
		*/
	}
	
	long length() { return segments.length; }
	Segment opIndex(int idx) { return segments[idx]; }

	Segments opAddAssign(Segment s) {
		foreach (cs; segments) {
			if (Segment.intersect(s, cs)) {
				cs.grow(s);
				goto end;
			}
		}
		segments ~= s;

		end: refactor(); return this;
	}
	
	Segments opSubAssign(Segment s) {
		Segment[] ss;
		
		void addValid(Segment s) { if (s.valid) ss ~= s; }

		foreach (cs; segments) {
			if (Segment.intersect(s, cs)) {
				addValid(Segment(cs.l, s.l ));
				addValid(Segment(s.r , cs.r));
			} else {
				addValid(cs);
			}
		}
		segments = ss;

		end: refactor(); return this;
	}

	char[] toString() { char[] r = "Segments {\n"; foreach (s; segments) r ~= "  " ~ s.toString ~ "\n"; r ~= "}"; return r; }

	unittest {
		auto ss = new Segments;
		ss += Segment(0, 100);
		ss += Segment(50, 200);
		ss += Segment(-50, 0);
		ss -= Segment(0, 50);
		ss -= Segment(0, 75);
		ss += Segment(-1500, -100);
		ss -= Segment(-1000, 1000);
		assert(ss.length == 1);
		assert(ss[0] == Segment(-1500, -1000));
	}
}

void patch(char[] game_folder, char[] acme_folder) {
	char[] script_folder_in = game_folder ~ "/data01000.arc.d";
	char[] script_folder_out = game_folder ~ "/Script/CVTD";

	auto acme = new ACME;
	auto bss  = new BSS;

	writefln("Patch all:");
	writefln(" - script_folder_in : %s", script_folder_in);
	writefln(" - script_folder_out: %s", script_folder_out);
	writefln(" - acme_folder      : %s", acme_folder);
	
	try { mkdir(game_folder ~ "/Script"); } catch { }
	try { mkdir(game_folder ~ "/Script/CVTD"); } catch { }

	foreach (file; listdir(script_folder_in)) {
		writefln(file);
		auto file_in  = script_folder_in ~ "/" ~ file;
		auto file_out = script_folder_out ~ "/" ~ file;
		auto acme_in  = acme_folder ~ "/" ~ file ~ ".txt";

		writefln("  ACME parsing...");
		acme.parseForm2(acme_in);
		writefln("  BSS parsing...");
		bss.parse(file_in);
		writefln("  BSS patching...");
		bss.patchStrings(acme);
		writefln("  BSS writting...");
		bss.write(file_out);
		//bss.dump();
	}
}

void extract_all2(char[] game_folder, char[] acme_folder) {
	char[] script_folder_in = game_folder ~ "/data01000.arc.d";

	auto bss = new BSS;
	
	writefln("Extract all:");
	writefln(" - script_folder: %s", script_folder_in);
	writefln(" - acme_folder  : %s", acme_folder);

	auto file_list = listdir(script_folder_in);
	if (file_list.length) {
		foreach (file; file_list) {
			if (file[0] == '.') continue;
			writefln("%s", file);
			bss.parse(script_folder_in ~ "/" ~ file);
			auto acme = bss.extract;
			acme.writeForm2(std.string.format("%s/%s.txt", acme_folder, file), file);
		}
	} else {
		writefln("No files detected.");
	}
}

class ShowHelpException : Exception { this(char[] t = "") { super(t); } static ShowHelpException opCall(char[] t = "") { return new ShowHelpException(t); } }

int main(char[][] args) {
	void show_help() {
		writefln("Ethornell script utility %s - soywiz - 2009 - Build %s", _version, __TIMESTAMP__);
		writefln("Knows to work with English Shuffle! and Edelweiss with Ethornell 1.69.140");
		writefln();
		writefln("script <command> <game_folder> <text_folder>");
		writefln();
		writefln("  -x[1,3]  Extracts texts from a folder with scripts.");
		writefln("  -p       Patches a folder with scripts with modified texts.");
		writefln();
		writefln("  -h       Show this help");
	}
	
	try {
		if (args.length < 2) throw(new ShowHelpException);
		
		switch (substr(args[1], 0, 2)) {
			case "-x":
				extract_all2(args[2], args[3]); // Game folder -> Text folder
			break;
			case "-p":
				patch(args[2], args[3]); // Game folder <- Text folder
			break;
			// Unknown command.
			default:
				throw(ShowHelpException(format("Unknown command '%s'", args[1])));
			break;
		}
	}
	// Catch a exception to show the help/usage.
	catch (ShowHelpException e) {
		show_help();
		if (e.toString.length) writefln(e);
		return 0;
	}
	// Catch a generic unhandled exception.
	catch (Exception e) {
		writefln("Error: %s", e);
		return -1;
	}
	
	return 0;
}