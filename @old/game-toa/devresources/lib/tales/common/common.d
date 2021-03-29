module tales.common;

import std.stdio, std.file, std.format, std.stream, std.path, std.string, std.ctype, std.c.stdlib;

template TSerialize(T) {
	ubyte[] TSerialize(T *t) {
		return (cast(ubyte *)t)[0..T.sizeof];
	}
}

template TA(T) { ubyte[] TA(inout T t) { return (cast(ubyte *)&t)[0..T.sizeof]; } }

abstract class Stream2 : Stream {
/*
	void copyFrom(Stream s) {
		if (seekable) {
			ulong pos = s.position();
			s.position(0);
			copyFrom(s, s.size());
			s.position(pos);
		} else {
			ubyte[32768] buf;
			while (!s.eof()) {
				size_t m = s.readBlock(buf.ptr, buf.length);
				writeExact(buf.ptr, m);
			}
		}
	}
	
	void copyFrom(Stream s, ulong count) {
		ubyte[32768] buf;
		while (count > 0) {
			size_t n = cast(size_t)(count<buf.length ? count : buf.length);
			s.readExact(buf.ptr, n);
			writeExact(buf.ptr, n);
			count -= n;
		}
	}	
*/
}

class PatchedMemoryStream : MemoryStream {
	override ulong seek(long offset, SeekPos rel) {
		assertSeekable();
		long scur; // signed to saturate to 0 properly

		switch (rel) {
			case SeekPos.Set: scur = offset; break;
			case SeekPos.Current: scur = cast(long)(cur + offset); break;
			case SeekPos.End: scur = cast(long)(len + offset); break;
			default:
			assert(0);
		}

		if (scur < 0)
			cur = 0;
		// Comportamiento inesperado
		//else if (scur > len)
		//	cur = len;
		else
			cur = cast(ulong)scur;

		return cur;
	}
	
	/*override size_t readBlock(void* buffer, size_t size) {
		assertReadable();
		ubyte* cbuf = cast(ubyte*) buffer;
		if (len - cur < size) size = cast(size_t)(len - cur);
		ubyte[] ubuf = cast(ubyte[])buf[cast(size_t)cur .. cast(size_t)(cur + size)];
		cbuf[0 .. size] = ubuf[];
		cur += size;
		return size;
	}
	
	override size_t writeBlock(void* buffer, size_t size) {
		assertWriteable();
		ubyte* cbuf = cast(ubyte*) buffer;
		ulong blen = buf.length;
		if (cur + size > blen) size = cast(size_t)(blen - cur);
		ubyte[] ubuf = cast(ubyte[])buf[cast(size_t)cur .. cast(size_t)(cur + size)];
		ubuf[] = cbuf[0 .. size];
		cur += size;
		if (cur > len) len = cur;
		return size;
	}*/
	
	this() {
		//buf = []; cur = len = 0;
		//if (buf != null)
		//writefln("hi");
		//std.gc.hasNoPointers(buf.ptr);
	}
	
	void noptr() {
		if (buf) std.gc.hasNoPointers(buf.ptr);
	}
	
	~this() {
		if (buf) { delete buf; buf = null; }
	}
}

class PatchedStream : Stream {
	Stream p;
	
	this(Stream p) {
		this.p = p;
	}
	
	size_t writeBlock(void* buffer, size_t size) {
		return p.writeBlock(buffer, size);
	}

	size_t readBlock(void* buffer, size_t size) {
		return p.readBlock(buffer, size);
	}
	
	ulong seek(long offset, SeekPos rel) {
		return p.seek(offset, rel);
		/*
		printf("%d\n", offset);
		//p.assertSeekable();
		long scur; // signed to saturate to 0 properly

		switch (rel) {
			case SeekPos.Set:     scur = offset; break;
			case SeekPos.Current: scur = cast(long)(p.position + offset); break;
			case SeekPos.End:     scur = cast(long)(p.size + offset); break;
			default: assert(0);
		}

		if (scur > p.size) {
			p.position = p.size;
			
			ubyte[] temp; temp.length = 0x800 * 0x100;
			while (p.position < scur) {
				uint rest = scur - p.position;
				p.write(temp[0..(rest > temp.length) ? temp.length : rest]);
			}
			
			return p.position;
		} else {
			return p.seek(offset, rel);
		}
		*/
	}
}

uint getdhvalue(char[] s) {
	uint r = 0, d, l = s.length;
	for (int n = 0; n < l; n++) {
		char c = s[n];
		if (c >= '0' && c <= '9') d = c - '0';
		else if (c >= 'a' && c <= 'f') d = c - 'a' + 0x0a;
		else if (c >= 'A' && c <= 'F') d = c - 'A' + 0x0a;
		else { d = 0; throw(new Exception("Invalid hex digit (" ~ c ~ ") in '" ~ s ~ "'")); }
		r |= d; r <<= 4;
	} r >>= 4;

	return r;
}

char[][char] translate;

char[] uncodestring(char[] s) {
	char[] r;

	for (int n = 0; n < s.length; n++) {
		if (s[n] == '\\') {
			switch (s[++n]) {
				case 'n': r  ~= '\n'; break;
				case 'r': r  ~= '\r'; break;
				case 't': r  ~= '\t'; break;
				default:
					printf("FORMAT ERROR: %s\n", toStringz(s));
					exit(-1);
				break;
			}

			continue;
		}

		if (s[n] == '<') {
			char hx[2];
			n++;

			while (n < s.length && s[n] != '>') {
				r ~= cast(char)getdhvalue(s[n..n+2]);
				n += 2;
			}

			continue;
		}

		//r ~= translate[s[n]];
		r ~= s[n];
	}

	r ~= "\0";

	version (padding2) { while (r.length % 4 != 0) r ~= "\0"; }
	version (padding4) { while (r.length % 4 != 0) r ~= "\0"; }

	return r;
}

char[] makestringz(char[] s, int l) {
	char[] r = s[0..s.length];
	while (r.length < l) r ~= '\0';
	return r[0..l];
}

void copyStream(Stream from, Stream to) {
	if (false) {
		ubyte[] temp; temp.length = 0x800 * 0x200 * 4;
		from.position = 0;
		uint toread = from.size;
		while (toread) {
			uint readed;
			//if (toread < temp.length) temp.length = toread;
			readed = from.read(temp);
			to.write(temp[0..readed]);	
			//writefln("* %d", readed);
			toread -= readed;
			if (readed <= 0) break;
		}
		delete temp;
	} else {
		to.copyFrom(from);
	}
}

char[] stripcslashes(char[] s) {
	int n, p; char[] r; r.length = s.length;	
	for (n = 0, p = 0; n < s.length; n++) {
		char c = s[n];
		if (c == '\\') {
			switch (c = s[++n]) {
				case '\\': c = '\\'; break;
				case '\'': c = '\''; break;
				case '0' : c = '\0'; break;
				case 'a' : c = '\a'; break;
				case 'b' : c = '\b'; break;
				case 'n' : c = '\n'; break;
				case 'r' : c = '\r'; break;
				case 't' : c = '\t'; break;
				case 'v' : c = '\v'; break;
				case 'x' :
					c = getdhvalue(s[n + 1..n + 3]);
					n += 2;
				break;
				default:
					throw(new Exception("Invalid escape character"));
				break;
			}			
		}
		r[p++] = c;
	}
	r.length = p;
	return r;
}

void makedir(char[] name) {
	try { mkdir(name); } catch (Exception e) { }
}

void copyStreamToFile(Stream s, char[] file) {
	ubyte[] data;
	data.length = s.size;
	s.read(data);
	write(file, data);
	delete data;
}

char[][] split2(char[] s, char[] r, int count = 0) {
	char[][] rr = split(s, r);
	if (count > 0 && rr.length > count) {
		for (int n = count; n < rr.length; n++) rr[count - 1] ~= r ~ rr[n];
		rr.length = count;
	}
	return rr;
}

/*static this() {
	for (int n = 0; n < 0x100; n++) translate[cast(char)n] ~= cast(char)n;

	File tf;
	try {
		tf = new File("../../../bin/src/translate.tbl");
	} catch (Exception e) {
		tf = new File("translate.tbl");
	}
	while (!tf.eof) {
		char[] l = tf.readLine().strip();
		if (!l.length) continue;
		char[][] ls = l.split("=");
		translate[ls[0][0]] = ls[1];
	} tf.close();
}*/
