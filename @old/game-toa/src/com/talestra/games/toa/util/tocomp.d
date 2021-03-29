module tocomp;

import std.stream, std.stdio, std.c.stdio, std.c.stdlib, std.c.string;

private {
	extern(C) {
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
	}

	void DecodeEncodeCheckError(int err) {
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

	void CompressionVersionCheck(ubyte ver) { if (ver != 1 && ver != 3) throw(new Exception("ERROR_UNKNOWN_VERSION")); }
}

public {
	ubyte[] decode(ubyte[] fin, bool raw = false, ubyte ver = 3) {
		int lcomp, luncomp;
		
		ubyte[] s, r;
		
		if (!raw) {
			ubyte *ptr = cast(ubyte *)fin.ptr;
			
			CompressionVersionCheck(ver = *(ptr + 0));
			
			lcomp   = *cast(int *)(ptr + 1);
			luncomp = *cast(int *)(ptr + 5);

			try {
				s = fin[9..lcomp + 9];
			} catch {
				throw(new Exception("Insufficient data for decompressing"));
			}
		} else {
			CompressionVersionCheck(ver);
		
			lcomp = fin.length;
			luncomp = fin.length * 12;
			s = fin;
		}
		
		r.length = luncomp;
		//std.gc.hasNoPointers(r.ptr);
		
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
		
		return r;
	}
	
	ubyte[] encode(ubyte[] s, bool raw = false, ubyte ver = 3) {
		int lcomp, luncomp;
		ubyte *outp;
		ubyte[] r;
		luncomp = s.length;
		lcomp = (luncomp * 9) / 8 + 9;
		r.length = lcomp;
		outp = r.ptr + (raw ? 0 : 9);
		
		DecodeEncodeCheckError(toencode(
			ver,
			s.ptr,
			s.length,
			outp,
			cast(int *)&lcomp
		));
		
		//std.gc.hasNoPointers(r.ptr);
		
		if (!raw) {
			*cast(ubyte *)(&r[0]) = ver;
			*cast(int   *)(&r[1]) = lcomp;
			*cast(int   *)(&r[5]) = luncomp;
		}
		
		r.length = lcomp + (raw ? 0 : 9);
		
		return r;
	}

	ubyte[] getStream(Stream s) {
		ubyte[] data;
		s.position = 0;
		data.length = s.size;
		//std.gc.hasNoPointers(data.ptr);
		s.read(data);
		s.position = 0;
		return data;
	}
	
	void cleanDelete(ubyte[] data) {
		memset(data.ptr, 0, data.length);
		//std.gc.removeRange(data.ptr);
		delete data;
		data = null;
		//std.gc.genCollect();
	}

	ubyte[] decode(Stream fin, bool raw = false, ubyte ver = 3) { ubyte[] data = getStream(fin); try { return decode(data, raw, ver); } finally { cleanDelete(data); data = null; } }
	ubyte[] encode(Stream fin, bool raw = false, ubyte ver = 3) { ubyte[] data = getStream(fin); try { return encode(data, raw, ver); } finally { cleanDelete(data); data = null; } }
	Stream decodeStream(ubyte[] data, bool raw = false, ubyte ver = 3) { return new MemoryStream(decode(data, raw, ver)); }
	Stream decodeStream(Stream  data, bool raw = false, ubyte ver = 3) { return new MemoryStream(decode(data, raw, ver)); }
	void encodeTo(ubyte[] u_data, Stream fout) {
		ubyte[] c_data = encode(u_data);
		fout.write(c_data);
		delete c_data; c_data = null;
	}
}