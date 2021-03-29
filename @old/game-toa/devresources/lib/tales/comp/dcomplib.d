module tales.comp;

// Version
//version = static_compression;

private import std.file, std.string, std.stdio, std.path, std.regexp, std.stream, std.gc, std.c.string;
private import tales.common;

private extern(C) {
	enum : int {
		SUCCESS               =  0,
		ERROR_FILE_IN         = -1,
		ERROR_FILE_OUT        = -2,
		ERROR_MALLOC          = -3,
		ERROR_BAD_INPUT       = -4,
		ERROR_UNKNOWN_VERSION = -5,
		ERROR_FILES_MISMATCH  = -6,
	}

	int toencode(int _version, void *_in, int _inl, void *_out, int *_outl);
	int todecode(int _version, void *_in, int _inl, void *_out, int *_outl);	
	int tocheckver(int _version);
}

ubyte[] readAll(Stream s) {
	ubyte[] retval;

	if (s.available > 0) {
		retval.length = s.available;		
		s.read(retval);
	}

	while (!s.eof) {
		ubyte[0x1000] temp;
		retval ~= temp[0..s.read(temp)];
	}

	return retval;
}

int readAllTo(Stream s, ubyte[] buf) {
	int pos = 0, temp;
	if (s.available > 0) pos += s.read(buf[pos..pos + s.available]);
	while (!s.eof) pos += s.read(buf[pos..pos + 1000]);	
	return pos;
}

private void DecodeEncodeCheckError(int err) {
	switch (err) {
		case SUCCESS: break;
		case ERROR_FILE_IN:         throw(new Exception("ERROR_FILE_IN"));
		case ERROR_FILE_OUT:        throw(new Exception("ERROR_FILE_OUT"));
		case ERROR_MALLOC:          throw(new Exception("ERROR_MALLOC"));
		case ERROR_BAD_INPUT:       throw(new Exception("ERROR_BAD_INPUT"));
		case ERROR_UNKNOWN_VERSION: throw(new Exception("ERROR_UNKNOWN_VERSION"));
		case ERROR_FILES_MISMATCH:  throw(new Exception("ERROR_FILES_MISMATCH"));
		default: throw(new Exception("Unknown error"));
	}
}

private void CompressionVersionCheck(ubyte ver) {
	if (ver != 1 && ver != 3) throw(new Exception("ERROR_UNKNOWN_VERSION"));
}

const int maxbuffer = 12_000_000;
//const int maxbuffer = 4_000_000;

version (static_compression) {
	bool buffer_init = false;
	
	ubyte[] tbuffer; // buffer temporal usado tanto para compresion como descompresion
	ubyte[] cbuffer; // buffer usado para almacenar la compresion
	ubyte[] ubuffer; // buffer usado para almacenar la descompresion
	
	/*
	static this() {
		tbuffer = cast(ubyte[])std.gc.malloc(10_000_000);
		ubuffer = cast(ubyte[])std.gc.malloc(10_000_000);
		cbuffer = cast(ubyte[])std.gc.malloc(3_000_000);
		
		std.gc.hasNoPointers(tbuffer.ptr);
		std.gc.hasNoPointers(ubuffer.ptr);
		std.gc.hasNoPointers(cbuffer.ptr);
	}
	*/
	
	void InitBuffers() {
		if (buffer_init) return;
		
		tbuffer = cast(ubyte[])std.gc.malloc(10_000_000);
		ubuffer = cast(ubyte[])std.gc.malloc(10_000_000);
		cbuffer = cast(ubyte[])std.gc.malloc(3_000_000);
		
		std.gc.hasNoPointers(tbuffer.ptr);
		std.gc.hasNoPointers(ubuffer.ptr);
		std.gc.hasNoPointers(cbuffer.ptr);
		
		buffer_init = true;	
	}	
	
	//ubyte[] comp;
	//ubyte[] uncomp;
	alias cbuffer comp;
	alias ubuffer uncomp;
	
	/*static this() {
		comp.length   = 4000000;
		uncomp.length = 9000000;
	}*/
	
	void CheckBuffers(int lcomp, int luncomp) {
		if (comp.length   < lcomp  ) comp.length   = lcomp;
		if (uncomp.length < luncomp) uncomp.length = luncomp;
	}
}

void[] DecodeBuffer(void[] fin, bool raw = false, ubyte ver = 3) {
	int lcomp, luncomp;
	
	ubyte[] s, r;
	
	if (!raw) {
		ubyte *ptr = cast(ubyte *)fin.ptr;
		ver     = *(ptr + 0);
		
		//if (ver != 0 && ver != 3) DecodeEncodeCheckError(ERROR_UNKNOWN_VERSION);
		DecodeEncodeCheckError(tocheckver(ver));
		
		lcomp   = *cast(int *)(ptr + 1);
		luncomp = *cast(int *)(ptr + 5);
		s = (cast(ubyte[])fin)[9..fin.length];
	} else {
		lcomp = fin.length;
		luncomp = fin.length * 12;
		s = cast(ubyte[])fin;
	}
	
	r.length = luncomp;
	
	try {
		DecodeEncodeCheckError(todecode(
			ver,
			s.ptr,
			s.length,
			r.ptr,
			cast(int *)&luncomp
		));
	} catch (Exception e) {
		delete r;
		throw(e);
	}
	
	r.length = luncomp;
	
	return r;
}

void DecodeStream(Stream fin, Stream fout, bool raw = false, ubyte ver = 3, bool autoclose = false) {
	scope (exit) { if (autoclose) { fin.close(); fout.close(); } }
		
	version (static_compression) InitBuffers();

	uint luncomp, lcomp;	
	
	if (!raw) {
		fin.read(ver); fin.read(lcomp); fin.read(luncomp);
	} else {
		luncomp = (lcomp = fin.available) * 12;
	}
	
	CompressionVersionCheck(ver);
	if ((lcomp > maxbuffer) || (luncomp > maxbuffer)) throw(new Exception("ERROR_MALLOC"));
			
	version (static_compression) {
		CheckBuffers(lcomp, luncomp);		
	} else {
		ubyte[] comp, uncomp;
		comp.length = lcomp;
		uncomp.length = luncomp;
		//printf("%d,%d\n", lcomp, luncomp);
	}
	
	lcomp = readAllTo(fin, comp);
	//fin.read(comp[0..lcomp]);

	DecodeEncodeCheckError(todecode(
		ver,
		comp.ptr,
		cast(int)lcomp,
		uncomp.ptr,
		cast(int *)&luncomp
	));

	fout.write(uncomp[0..luncomp]);
	
	version (static_compression) {
	} else {
		delete comp;
		delete uncomp;
	}
}

void EncodeStream(Stream fin, Stream fout, bool raw = false, int ver = 3, bool autoclose = false) {
	scope (exit) { if (autoclose) { fin.close(); fout.close(); } }
		
	version (static_compression) InitBuffers();

	uint lcomp, luncomp;

	version (static_compression) {		
		luncomp = readAllTo(fin, uncomp);
	} else {
		ubyte[] uncomp, comp;	
		uncomp = readAll(fin);
		luncomp = uncomp.length;
		comp.length = (luncomp * 9) / 8;
	}
			
	lcomp = comp.length;

	DecodeEncodeCheckError(toencode(
		ver,
		cast(void *)uncomp.ptr,
		cast(int)luncomp,
		cast(void *)comp.ptr,
		cast(int *)&lcomp
	));

	if (!raw) {
		fout.write(cast(ubyte)ver);
		fout.write(cast(uint)lcomp);
		fout.write(cast(uint)luncomp);
	}

	fout.write(comp[0..lcomp]);

	version (static_compression) {
	} else {
		delete comp;
		delete uncomp;
	}
}

bool CheckCompression(Stream fin, int ver = 3, bool autoclose = true) {
	scope (exit) { if (autoclose) fin.close(); }

	Stream comp = new PatchedMemoryStream();
	Stream uncomp = new PatchedMemoryStream();

	EncodeStream(fin, comp, false, ver, false);

	comp.position = 0;
	DecodeStream(comp, uncomp, false, ver, false);

	fin.position = 0; uncomp.position = 0;

	if (readAll(fin) != readAll(uncomp)) {
		throw(new Exception("Compression error"));
	}

	comp.close();
	uncomp.close();

	return true;
}

version (static_compression) {
	class CompressedStream : Stream {	
		this(char[] name) { File f = new File(name, FileMode.In); this(f); f.close(); delete f; }	
		
		int cur, len;
		ubyte[] buf;
		
		alias comp tbuffer;
		alias uncomp ubuffer;
		
		this(Stream s) {
			InitBuffers();
			
			ubyte ver; uint lcomp, luncomp;		
			s.read(ver); s.read(lcomp); s.read(luncomp);		
			CompressionVersionCheck(ver);
					
			lcomp = readAllTo(s, comp);
			
			DecodeEncodeCheckError(todecode(
				ver,
				comp.ptr,
				cast(int)lcomp,
				uncomp.ptr,
				cast(int *)&luncomp
			));		
			
			buf = uncomp[0..luncomp];
			cur = 0; len = luncomp;
			
			readable = seekable = true;
			writeable = false;
		}
		
		size_t readBlock(void* buffer, size_t size) {
			assertReadable();
			ubyte* cbuf = cast(ubyte*) buffer;
			if (len - cur < size) size = cast(size_t)(len - cur);
			ubyte[] ubuf = cast(ubyte[])buf[cast(size_t)cur .. cast(size_t)(cur + size)];
			cbuf[0 .. size] = ubuf[];
			cur += size;
			return size;
		}
		
		size_t writeBlock(void* buffer, size_t size) {
			assertWriteable(); return size;
		}
		
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
	
			return cur = (scur < 0) ? 0 : cast(ulong)scur;
		}
		
		~this() {
		}
	}
	
	class CompressStream : Stream {
		this(char[] name, int ver = 3, bool raw = false) { File f = new File(name, FileMode.OutNew); this(f, ver, raw); }
		
		Stream saves;
		bool raw, closed;
		int ver;
		
		int cur, len;
		ubyte[] buf;	
		
		alias comp tbuffer;
		alias uncomp cbuffer;	
	
		this(Stream s, int ver = 3, bool raw = false) {
			InitBuffers();
			
			saves = s;
			this.ver = ver;
			this.raw = raw;
			this.closed = false;
			
			writeable = readable = seekable = true;
			
			buf = uncomp;
			cur = 0;
			len = 0;
		}
	
		~this() {
			if (!closed) close();
		}
		
		size_t readBlock(void* buffer, size_t size) {
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
		}
		
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
	
			return cur = (scur < 0) ? 0 : cast(ulong)scur;
		}	
	
		void close() {
			closed = true;
			this.position = 0;
			
			int luncomp = len, lcomp = comp.length;
	
			DecodeEncodeCheckError(toencode(
				ver,
				cast(void *)uncomp.ptr,
				cast(int)luncomp,
				cast(void *)comp.ptr,
				cast(int *)&lcomp
			));
		
			saves.write(cast(ubyte)ver);
			saves.write(cast(uint)lcomp);
			saves.write(cast(uint)luncomp);
			saves.write(comp[0..lcomp]);
			saves.close();
		}
		
	}
} else {
	class CompressedStream : PatchedMemoryStream {
		this(Stream s) {
			//buf.length = 12_000_000;
			//std.gc.hasNoPointers(buf.ptr);
			
			//std.stdio.writefln("CompressedStream()");
			DecodeStream(s, this);
			this.position = 0;
			//std.gc.hasNoPointers(buf.ptr);
		}
	
		~this() {
			delete buf;
			//std.gc.genCollect();
		}
		
		this(char[] name) {
			File f = new File(name, FileMode.In); this(f); f.close(); delete f;
		}
	}
	
	class CompressStream : PatchedMemoryStream {
		Stream saves;
		bool raw, closed;
		int ver;
	
		this(Stream s, int ver = 3, bool raw = false) {
			saves = s;
			this.position = 0;
			this.ver = ver;
			this.raw = raw;
			this.closed = false;
		}
	
		~this() {
			if (!closed) close();
			//delete buf;
			//std.gc.genCollect();		
		}
	
		void close() {
			closed = true;
			this.position = 0;
			//void Encode(Stream fin, Stream fout, bool raw = false, int ver = 3, bool autoclose = false)
			EncodeStream(this, saves, raw, ver, false);
			//saves.close();
		}
	
		this(char[] name, int ver = 3, bool raw = false) {
			File f = new File(name, FileMode.OutNew);
			this(f, ver, raw);
		}
	}	
}

void CompressionCleanup() {
	version (static_compression) {
		std.c.string.memset(tbuffer.ptr, 0, tbuffer.length);
		std.c.string.memset(cbuffer.ptr, 0, cbuffer.length);
		std.c.string.memset(ubuffer.ptr, 0, ubuffer.length);
	}
	
	std.gc.fullCollect();
}
