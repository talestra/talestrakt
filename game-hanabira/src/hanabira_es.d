import std.stdio, std.string, std.stream, std.algorithm, std.typecons, std.md5;

ubyte[] TA(T)(ref T v) { return cast(ubyte[])((&v)[0..1]); }

interface Serializable {
	void read(Stream stream);
	void write(Stream stream);
}

interface BaseInstruction : Serializable {
	string toString();
}

extern (Windows) {
	pragma(lib, "kernel32.lib");
	static int MultiByteToWideChar(uint CodePage, uint dwFlags, char* lpMultiByteStr, int cbMultiByte, wchar* lpWideCharStr, int cchWideChar);
	static int WideCharToMultiByte(uint CodePage, uint dwFlags, wchar* lpWideCharStr, int cchWideChar, char* lpMultiByteStr, int cbMultiByte, char* lpDefaultChar, int* lpUsedDefaultChar);
}

wchar[] sjis_convert_utf16(char[] data) { return convert_to_utf16(data, 932); }
char[]  sjis_convert_utf8 (char[] data) { return cast(char[])std.utf.toUTF8(sjis_convert_utf16(data)); }

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

string mb_convert_encoding(string str, int to_codepage, int from_codepage) { return cast(string)convert_from_utf16(convert_to_utf16(cast(char[])str, from_codepage), to_codepage); }
string mb_convert_encoding(string str, string to_encoding, string from_encoding) { return cast(string)mb_convert_encoding(str, charset_to_codepage(to_encoding), charset_to_codepage(from_encoding)); }

uint charset_to_codepage(string charset) {
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

class Msd : Serializable {
	align(1) static struct Header { static assert (this.sizeof == 0x458);
		char magic[0x10] = "MSCENARIO FILE  ";
		uint filever = 0x_1_00_00;
		uint count_jump, count_line;
		ubyte _dummy[0x43C];
	}
	Header header;
	BaseInstruction[] instructions;

	static class CryptedStream : FilterStream {
		static string getCryptKey(uint index) {
			//return std.string.tolower(std.md5.getDigestString(x"82BB82CC89D482D182E782C982AD82BF82C382AF82F0", std.string.format("%d", index)));
			return std.string.tolower(std.md5.getDigestString(x"82BB82CC89D482D182E782C982AD82BF82C382AF82F0" ~ std.string.format("%d", index)));
		}

		unittest {
			assert(CryptedStream.getCryptKey(0) == "9af47d078810499992d59d183020882a");
			assert(CryptedStream.getCryptKey(1) == "7b94af425a09fc83dcf516c196f6cd6e");
			assert(CryptedStream.getCryptKey(2) == "b545a056e36af21e2a8c6b31f7cb25fe");
		}

		int block_current = -1;
		ubyte[] block_data;

		void prepareBlock(int pos) {
			int block_next = pos / 0x20;
			if (block_current != block_next) {
				//.writefln("Updated block");
				block_current = block_next;
				block_data = cast(ubyte[])getCryptKey(block_current);
			}
		}

		this(Stream stream) {
			super(stream);
		}

		size_t readBlock(void* buffer, size_t size) {
			auto start = source.position;
			int readed;
			scope (exit) {
				auto bbuffer = cast(ubyte *)buffer;
				foreach (pos, v; bbuffer[0..readed]) {
					auto cpos = cast(int)(start + pos);
					prepareBlock(cpos);
					//.writefln("%s", cast(string)block_data);
					//.writefln("%d:%d:%02X:%02X:(%d)", pos, cpos, v, block_data[cpos % 0x20]);
					bbuffer[pos] = v ^ block_data[cpos % 0x20];
				}
			}
			return readed = source.readBlock(buffer, size);
		}
		size_t writeBlock(const void* buffer, size_t size) {
			auto start = source.position;
			auto bbuffer = new ubyte[size];
			foreach (pos, v; (cast(ubyte *)buffer)[0..size]) {
				auto cpos = cast(int)(start + pos);
				prepareBlock(cpos);
				bbuffer[pos] = v ^ block_data[cpos % 0x20];
			}
			return source.writeBlock(bbuffer.ptr, size);
		}
		ulong seek(long offset, SeekPos whence) {
			return source.seek(offset, whence);
		}
	}

	static class Parameter : Serializable {
		enum Type : ubyte { LITERAL = 1, VARIABLE = 2, STRING = 3, ARRAY = 4 }
		Type type;
		static struct AV { int l, r; }
		union {
			int    value_int;
			string value_string;
			AV[]   value_array;
		}
		this() {
		}
		this(string text) {
			type = Type.STRING;
			value_string = text;
		}
		uint length() out (value) { assert((value >> 16) == 0); } body {
			switch (type) {
				case Type.LITERAL, Type.VARIABLE: return 1 + 4;
				case Type.STRING: return 1 + value_string.length + 1;
				case Type.ARRAY : return 1 + value_array.length * 8;
			}
		}
		void write(Stream stream) {
			stream.write(cast(ubyte)type);
			switch (type) {
				case Type.LITERAL, Type.VARIABLE:
					stream.write(value_int);
				break;
				case Type.STRING:
					stream.writeString(value_string ~ '\0');
				break;
				case Type.ARRAY:
					foreach (item; value_array) {
						stream.write(item.l);
						stream.write(item.r);
					}
					stream.write(cast(uint)-1);
					stream.write(cast(uint)-1);
				break;
			}
		}
		void read(Stream stream) {
			stream.read(cast(ubyte)type);
			//writefln("TYPE: %d", type);
			switch (type) {
				case Type.LITERAL, Type.VARIABLE:
					stream.read(value_int);
				break;
				case Type.STRING:
					char c;
					do { stream.read(c); value_string ~= c; } while (c);
					value_string = value_string[0..$ - 1];
					//stream.writeString(value_string);
				break;
				case Type.ARRAY: {
					AV item;
					do {
						stream.read(item.l);
						stream.read(item.r);
						value_array ~= item;
					} while (item.l != -1);
					value_array = value_array[0..$ - 1];
				} break;
			}
		}

		string toString() {
			switch (type) {
				case Type.LITERAL : return std.string.format("%d", value_int);
				case Type.VARIABLE: return std.string.format("$%d", value_int);
				case Type.STRING  : return std.string.format("'%s'", mb_convert_encoding(value_string, "utf_8", "shift_jis"));
				case Type.ARRAY   : return std.string.format("%s", value_array);
			}
		}
	}

	class Instruction : BaseInstruction {
		ushort type;
		Parameter[] params;
		void write(Stream stream) {
			stream.write(cast(ushort)type);
			stream.write(cast(ushort)length);
			foreach (param; params) param.write(stream);
		}
		void read(Stream stream) {
			ushort length;
			stream.read(type);
			stream.read(length);
			if (length > 0) {
				auto params_data = new ubyte[length];
				stream.read(params_data);
				auto paramsStream = new MemoryStream(params_data);
				paramsStream.position = 0;

				while (!paramsStream.eof) {
					auto param = new Parameter();
					param.read(paramsStream);
					params ~= param;
				}
			}
		}
		uint length() {
			uint len;
			foreach (param; params) len += param.length;
			return len;
		}
		string toString() {
			return std.string.format("Msd.Instruction(%d, %s)", type, params);
		}
	}

	abstract class InstructionJumpLine : BaseInstruction {
		uint index, value;
		void read (Stream stream) { }
		void write(Stream stream) { this.value = cast(uint)stream.position; update(); }
		this(uint index, uint value = 0) { this.index = index; this.value = value; update(); }
		abstract void update();
		string toString() {
			return std.string.format("Msd.InstructionJumpLine(%d, %d)", index, value);
		}
	}

	class InstructionLine : InstructionJumpLine { this(uint index, uint value = 0) { super(index, value); } void update() { lines[this.index] = this.value; } }
	class InstructionJump : InstructionJumpLine { this(uint index, uint value = 0) { super(index, value); } void update() { jumps[this.index] = this.value; } }

	uint[] jumps, lines;
	uint[uint] lookup_jumps, lookup_lines;

	void read(Stream stream, bool close) {
		//stream.read(TA(header)); std.file.write("temp.c", TA(header));

		if ((new SliceStream(stream, 0)).readString(0x10) != header.init.magic) stream = new CryptedStream(new SliceStream(stream, 0));
		stream.read(TA(header));

		//((std.file.write("temp.u", TA(header));

		assert(header.magic   == header.init.magic);
		assert(header.filever == header.init.filever);
		assert(header.count_jump < 0x10000);
		assert(header.count_line < 0x10000);

		jumps.length = header.count_jump;
		lines.length = header.count_line;

		stream.read(cast(ubyte[])(jumps)); foreach (n, jump; jumps) lookup_jumps[jump] = n;
		stream.read(cast(ubyte[])(lines)); foreach (n, line; lines) lookup_lines[line] = n;

		auto stream_code = new SliceStream(stream, stream.position, stream.size);

		//writefln("%d", stream_code.size);

		while (!stream_code.eof) {
			uint stream_code_position = cast(uint)stream_code.position;
			if (stream_code_position in lookup_jumps) instructions ~= new InstructionJump(lookup_jumps[stream_code_position], 0);
			if (stream_code_position in lookup_lines) instructions ~= new InstructionLine(lookup_lines[stream_code_position], 0);
			{
				auto instruction = new Instruction();
				instruction.read(stream_code);
				//writefln("Type:%d", instruction.type);
				instructions ~= instruction;
			}
		}
		//writefln("%d", instructions.length);
		if (close) stream.close();
	}

	void write(Stream stream, bool close) {
		// Header.
		stream.write(TA(header));

		// Instructions buffer (to prepare tables).
		auto stream_code = new MemoryStream();
		foreach (instruction; instructions) instruction.write(stream_code);

		// Tables.
		stream.write(cast(ubyte[])(jumps));
		stream.write(cast(ubyte[])(lines));
		// Instructions.
		stream.copyFrom(stream_code);

		stream.flush();
		if (close) stream.close();
	}

	void read (Stream stream) { return this.read (stream, false); }
	void write(Stream stream) { return this.write(stream, false); }
}

class Pak : Serializable {
	static struct Header { static assert (this.sizeof == 0x54);
		char magic[8] = "FJSYS\0\0\0";
		uint data_start;
		uint table_string_size;
		uint count;
		ubyte _dummy[0x40];
	}
	static class Entry { //static assert (this.sizeof == 0x10);
		uint name_start;
		uint data_size;
		uint data_start;
		uint dummy;
		Stream stream;
		string name;

		string toString() { return std.string.format("Pak.Entry('%s', %d)", name, length); }
		uint length() { return cast(uint)stream.size; }
		void update(uint name_start, uint data_start) {
			this.data_size  = length;
			this.name_start = name_start;
			this.data_start = data_start;
		}
		static Entry opCall(string name, Stream stream = null) {
			Entry entry = new Entry;
			entry.name = name;
			entry.stream = (stream !is null) ? stream : (new MemoryStream);
			return entry;
		}
		void read(Stream stream) {
			stream.read(name_start);
			stream.read(data_size);
			stream.read(data_start);
			stream.read(dummy);
			//stream.seekCur(4);
		}
		void write(Stream stream) {
			//writefln("%d,%d", name_start, length);
			stream.write(name_start);
			stream.write(length);
			stream.write(data_start);
			stream.write(cast(uint)0);
		}
	}

	ubyte[] data;
	Header header;
	Entry[] entries;
	char[] names;

	void read(Stream stream, bool close) {
		stream.read(TA(header));
		assert(header.magic == header.init.magic);
		assert(header.count < 0x10000);

		for (int n = 0; n < header.count; n++) {
			auto entry = new Entry;
			entry.read(stream);
			entries ~= entry;
		}
		names = stream.readString(header.table_string_size);

		assert(stream.position == header.data_start, std.string.format("%d != %d", stream.position, header.data_start));

		foreach (entry; entries) {
			long stream_position_next = stream.position + entry.data_size;
			entry.stream = new SliceStream(stream, stream.position, stream_position_next);
			entry.name   = std.conv.to!string(names.ptr + entry.name_start);
			stream.position = stream_position_next;
		}
		if (close) stream.close();
	}

	void write(Stream stream, bool close) {
		auto namesStream = new MemoryStream;
		uint data_start = 0;
		foreach (entry; entries) {
			//writefln("%d", entry.name);
			entry.update(cast(uint)namesStream.position, data_start);
			namesStream.writeString(entry.name ~ '\0');
			data_start += entry.length;
		}
		header.table_string_size = cast(uint)namesStream.size;
		header.data_start = header.sizeof + 0x10 * entries.length + header.table_string_size;

		//writefln("%08X", header.data_start);

		foreach (entry; entries) entry.data_start += header.data_start;

		header.count = entries.length;
		stream.write(TA(header));
		foreach (entry; entries) entry.write(stream);
		stream.copyFrom(namesStream);
		//stream.write(cast(ubyte)0);
		foreach (entry; entries) if (entry.stream !is null) stream.copyFrom(entry.stream);

		stream.flush();
		if (close) stream.close();
	}

	void read (Stream stream) { return this.read (stream, false); }
	void write(Stream stream) { return this.write(stream, false); }

	ref Entry opIndex(string index) {
		foreach (k, entry; entries) if (entry.name == index) return entries[k];
		assert(0);
	}
	ref Entry opIndex(uint index) { return entries[index]; }
	ref Entry opIndexAssign(Entry entry, uint index) { entries[index] = entry; return entries[index]; }
	ref Entry opIndexAssign(Entry entry, string index) {
		foreach (k, centry; entries) {
			if (centry.name == index) {
				entries[k] = entry;
				return entries[k];
			}
		}
		assert(0);
	}
	uint length() { return entries.length; }

	ref Entry opAddAssign(Entry entry) {
		entries ~= entry;
		return entries[entries.length - 1];
	}

    int opApply(int delegate(ref Entry) dg) {
		int result = 0;

		for (int i = 0; i < entries.length; i++) {
			result = dg(entries[i]);
			if (result) break;
		}
		return result;
    }
}

void main() {
	/*
	auto msd = new Msd;
	msd.read (new BufferedFile("MSE.D/S001.MSD"));
	//msd.write(new Msd.CryptedStream(new BufferedFile("MSE.D/S001.MSD.new", FileMode.OutNew)));
	msd.write(new BufferedFile("MSE.D/S001.MSD.new", FileMode.OutNew));
	*/


	auto pak = new Pak;
	if (!std.file.exists("MSE.BAK")) std.file.copy("MSE", "MSE.BAK");
	pak.read(new BufferedFile("MSE.BAK"));

	auto msd = new Msd;
	msd.read(pak["S001.MSD"].stream);
	foreach (cinstruction; msd.instructions) {
		auto instruction = cast(Msd.Instruction)cinstruction;
		if (instruction !is null) {
			switch (instruction.type) {
				case 1005:
				break;
				case 2010:
					writefln("%s", instruction);
					//instruction.params[3] = new Msd.Parameter("Test");
					//writefln("%s", instruction.params[3]);
					//instruction.params[3].value_string = 'E' ~ instruction.params[3].value_string[1..$];
					instruction.params[3] = new Msd.Parameter("Haaaaaaaaaa..............");
					goto end;
				break;
				default: break;
			}
		}
	}
	end:;
	pak["S001.MSD"].stream = new MemoryStream;
	msd.write(pak["S001.MSD"].stream);
	msd.write(new std.stream.BufferedFile("output", FileMode.OutNew));

	/*foreach (entry; pak) {
		writefln("%s", entry);
		auto msd = new Msd;
		msd.read(entry.stream);
		//entry.stream = new MemoryStream;
		//msd.write(new Msd.CryptedStream(entry.stream), false);
	}*/
	pak.write(new std.stream.File("MSE", FileMode.OutNew));
	/*
	if (1) {
		pak += Pak.Entry("hola!");
		pak.write(new BufferedFile("SE.NEW", FileMode.OutNew));
	} else {
		/+
		pak.read(new BufferedFile("SE"));
		pak.write(new BufferedFile("SE.NEW", FileMode.OutNew));
		+/
		pak.read(new BufferedFile("MGE.OLD"));
		pak.write(new BufferedFile("MGE", FileMode.OutNew));
	}*/
}