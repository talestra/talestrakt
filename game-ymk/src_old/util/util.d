module yume.util;

import std.stdio, std.string, std.stream, std.file, std.path;

//void com.talestra.criminalgirls.main() { writefln("R:%s", explode("\n", "Hola\nesto es\nuna prueba", 2)); }

char[] substr(char[] s, int from, int length = 0x7FFFFFFF) {
	if (from < 0) from += s.length; if (from < 0 || from >= s.length) return "";
	int to = (length < 0) ? (s.length + length) : (from + length);
	if (to > s.length) to = s.length;
	return (from <= to) ? s[from..to] : "";
}

char[][] explode(char[] delim, char[] str, int length = 0x7FFFFFFF) {
	int dl = delim.length;
	
	if (dl > str.length) return [str];
	
	char[][] rr;
	
	char* s = str.ptr, se = s + str.length - dl, see = s + str.length, sp = s;

	if (length-- > 1) {
		while (s <= se) {
			if (s[0..dl] == delim[0..dl]) {
				rr ~= sp[0..s - sp];
				s += dl;
				sp = s;
				if (rr.length >= length) break;
			} else {
				s++;
			}
		}
	}
	
	rr ~= sp[0..see - sp];
	
	return rr;
}

int fromhex(char[] s) {
	int r;
	foreach (c; s) {
		int cv;
		if (c >= '0' && c <= '9') {
			cv = c - '0';
		} else if (c >= 'a' && c <= 'f') {
			cv = c - 'a' + 10;
		} else if (c >= 'A' && c <= 'F') {
			cv = c - 'A' + 10;
		} else {
			continue;
		}
		r *= 0x10;
		r += cv;
	}
	return r;
}

ubyte ror2(ubyte v) { asm { naked; ror AL, 0 + 2; ret; } }
ubyte rol2(ubyte v) { asm { naked; ror AL, 8 - 2; ret; } }

class DecryptStream : FilterStream {
	this(Stream s) {
		super(s);
	}

	override uint readBlock(void* buffer, uint size) {
		uint ret = source.readBlock(buffer, size);
		Data.decrypt((cast(ubyte *)buffer)[0..ret]);
		return ret;
	}
}

class Data {
	static void decompress(ubyte[] srcv, ubyte[] dstv) {
		ubyte ringbuf[0x1000]; uint ringpos_write = 1;
		ubyte* src = srcv.ptr, end = src + srcv.length, dst = dstv.ptr;
		try {
			while (src < end) {
				uint ops = (*(src++) | 0x100); // Read operation
				//writefln("%02X", ops & 0xFF);
				for (; ops != 1; ops >>= 1) {
					// Uncompressed
					if (ops & 1) {
						*(dst++) = ringbuf[ringpos_write] = *(src++);
						ringpos_write = (ringpos_write + 1) & 0xFFF;
					}
					// Compressed
					else{
						if (src >= end) break;
						ushort data;
						data  = (*(src++)) << 8;
						data |= *(src++);
						ubyte  count = (data & 0xF) + 2;
						ushort ringpos_read = (data >> 4);
						if (ringpos_read == 0) break;
						//writefln("%d, %d", count, ringpos_read);
						while (count--) {
							*(dst++) = ringbuf[ringpos_write] = ringbuf[ringpos_read];
							ringpos_write = (ringpos_write + 1) & 0xFFF;
							ringpos_read  = (ringpos_read  + 1) & 0xFFF;
						}
					} // if...else
				} // for
			} // while
		} catch (Exception e) {
			writefln("ERROR: %s", e.toString);
			throw(e);
		}
		//writefln("%d, %d", src - srcv.ptr, srcv.length);
		//writefln("%d, %d", dst - dstv.ptr, dstv.length);
	}
	
	/*void decompress(ubyte[] srcv, ubyte[] dstv) {
		ubyte ringbuf[0x1000];
		uint ringpos_write = 1;
		ubyte* src = srcv.ptr, end = src + srcv.length, dst = dstv.ptr;
		while (src < end) {
			uint ops = (*src | 0x100); src++; // Read operation
			for (; ops != 1; ops >>= 1) {
				// Uncompressed
				if (ops & 1) {
					*(dst++) = ringbuf[ringpos_write] = *(src++);
					ringpos_write = (ringpos_write + 1) & 0xFFF;
				}
				// Compressed
				else{
					if (src < end) break;
					ushort data = *cast(ushort *)src; src += 2;
					ubyte  count = (data & 0xF) + 3;
					ushort ringpos_read = (data >> 4);
					while (count--) {
						*(dst++) = ringbuf[ringpos_write] = ringbuf[ringpos_read];
						ringpos_write = (ringpos_write + 1) & 0xFFF;
						ringpos_read  = (ringpos_read  + 1) & 0xFFF;
					}
					if (src < end) break;
				}
			}
		}
	}*/	
	
	static void decrypt(ubyte[] data) { for (ubyte* cur = data.ptr, end = cur + data.length; cur < end; cur++) *cur = ror2(*cur); }
	static void encrypt(ubyte[] data) { for (ubyte* cur = data.ptr, end = cur + data.length; cur < end; cur++) *cur = rol2(*cur); }
}

/+
void extractType(Stream s, int offset, int count, char[] ext) {
	Stream[char[]] slices;
	s.position = offset;
	for (int n = 0; n < count; n++) {
		uint length, foffset;
		char[] name = toString(s.readString(9).ptr);
		s.read(length); s.read(foffset);
		slices[name] = new SliceStream(s, foffset, foffset + length);
	}
	try { mkdir("data"); } catch { }
	try { mkdir("data/" ~ ext); } catch { }
	foreach (name; slices.keys.sort) {
		writefln("    %s", name);
		char[] rfile = "data/" ~ ext ~ "/" ~ name ~ "." ~ ext;
		if (exists(rfile)) continue;
		auto slice = slices[name];
		ubyte[] data = new ubyte[slice.size]; slice.read(data);
		if (ext == "WSC") decodeScript(data);
		write(rfile, data);
		delete data; data = null;
	}
}

void extract(char[] fname) {
	auto s = new BufferedFile(fname);
	writefln("%s", fname);
	uint typeCount; s.read(typeCount);
	for (int type = 0; type < typeCount; type++) {
		char[] ext = toString(s.readString(4).ptr);
		writefln("  %s", ext);
		uint count, offset; s.read(count); s.read(offset);
		extractType(new SliceStream(s, 0), offset, count, ext);
	}
	s.close();
	/*
	s.readExact(&h, h.sizeof);
	s.position = h.start;
	Stream[char[]] slices;
	for (int n = 0; n < h.count; n++) {
		uint len, pos;
		char[] name = toString(s.readString(9).ptr);
		s.read(len); s.read(pos);
		slices[name ~ "." ~ h.ext] = new SliceStream(s, pos, pos + len);
	}
	foreach (name; slices.keys.sort) { auto slice = slices[name];
		write("DATA/" ~ name, data);
	}
	*/
}

void extractARC() {
	extract("Bgm.arc");
	extract("Chip.arc");
	extract("Rio.arc");
	extract("Se.arc");
	extract("Voice.arc");
}

void decompressWIPFolderMask(char[] path, char[] pathMask) {
	foreach (file; listdir(path)) { char[] rfile = path ~ "/" ~ file, mfile = pathMask ~ "/" ~ file;
		if (file.length < 4 || file[file.length - 4..file.length] != ".WIP") continue;
		writefln("%s", file);
		decompressWIPMask(rfile, mfile[0..mfile.length - 4] ~ ".MSK");
		//writefln(rfile);
		//decompressWIP("BLOGIP.MSK");
		//return;
	}
}
+/
