module tales.sb7;

import std.file, std.string, std.stdio, std.path, std.regexp, std.stream;
import tales.util.gameformat, tales.util.rangelist;

class SB7 {
	struct Sb7Entry {
		char[] text;
		uint[] params;
	}

	RangeList rl;
	Sb7Entry[] list;

	ubyte[0x20] info;
	uint ttable;
	uint tstart;
	TOAGameFormatString fs;

	this(Stream sb7 = null) {
		if (sb7) get(sb7);
	}
	
	~this() {
		delete list;
	}

	private void init(Stream sb7) {
		sb7.position = 0;

		fs = new TOAGameFormatString;
		fs.ignoreParams = true;

		sb7.read(info);
		if (cast(char[])info[0..3] != "SB7") throw(new Exception("Invalid SB7 file"));

		// Relacionado con bytes anteriores
		sb7.position = 0x38;
		sb7.read(tstart);

		// Inicio del texto
		sb7.position = 0x50;
		sb7.read(ttable);

		sb7.position = 0x5C + tstart * 4;
	}
	
	void get(Stream sb7) {
		rl = new RangeList();
		list = [];

		init(sb7);

		uint[] pointers;

		int n = 0, bpos = 0;
		while (true) {
			uint rpos;
			sb7.read(rpos);
			if ((rpos == 0 && n != 0)) break;
			if (bpos > rpos) writefln("WARNING!");
			//writefln("%08X", rpos);
			pointers ~= rpos;
			bpos = rpos;
			n++;
		}

		foreach (pptr, p; pointers) {
			//writefln(e.params);
			list ~= Sb7Entry(fs.extractStringz(sb7, p + ttable), fs.params);
			if (rl) rl.add(p + ttable, fs.getStringzLength(sb7, p + ttable));
		}

		return list;
	}

	void update(Stream sb7) {
		// Borramos los segmentos
		int endi = 0;
		foreach (p, l; rl.rangeStart) {
			ubyte[] w; w.length = l; sb7.position = p; sb7.write(w);
			if (p > endi) endi = p;
		}

		//rl.add(endi + rl.rangeStart[endi], 100000);
		sb7.position = 0;
		rl.add(sb7.available, 99999);

		init(sb7);

		uint[] pointers;

		int n = 0, bpos = 0;
		foreach (e; list) {
			uint rpos;

			fs.params = e.params;
			
			char[] rs;

			try {
				rs = fs.encodeString(e.text) ~ "\0";
			} catch (Exception ee) {
				//writefln(ee.toString);
				printf("Error en: '%s'\n", toStringz(e.text));
				throw(ee);
			}
			
			int ptr = rl.getAndUse(rs.length);
			rpos = ptr - ttable;

			//writefln("RPOS: %08X", ptr);

			sb7.write(rpos); n++;

			bpos = sb7.position;
				sb7.position = ptr;
				sb7.writeExact(rs.ptr, rs.length);
			sb7.position = bpos;
		}

		sb7.seek(0, SeekPos.End);

		// Padding
		while ((sb7.position % 4) != 0) sb7.write(cast(ubyte)0);

		sb7.position = 0;
	}
}


// deprecated deprecated deprecated deprecated deprecated deprecated deprecated deprecated deprecated
// deprecated deprecated deprecated deprecated deprecated deprecated deprecated deprecated deprecated
// deprecated deprecated deprecated deprecated deprecated deprecated deprecated deprecated deprecated
// Use SB7 class instead


// deprecated
char[][] MergeSB7Pointers(char[][] original, char[][int] modified) {
	foreach (k, v; modified) original[k] = v;
	return original;
}

// deprecated
void UpdateSB7(Stream sb7, RangeList rl, char[][] text, TOAGameFormatString[] fsl = null) {
	// Borramos los segmentos
	foreach (p, l; rl.rangeStart) {
		ubyte[] w;
		sb7.position = p;
		w.length = l;
		sb7.write(w);
	}

	sb7.position = 0;

	TOAGameFormatString fs = new TOAGameFormatString;

	char[][] list;
	ubyte[0x20] info;
	uint ttable;
	uint tstart;

	sb7.read(info);
	if (cast(char[])info[0..3] != "SB7") throw(new Exception("Invalid SB7 file"));

	// Relacionado con bytes anteriores
	sb7.position = 0x38;
	sb7.read(tstart);

	// Inicio del texto
	sb7.position = 0x50;
	sb7.read(ttable);

	//sb7.position = 0xB0 + tstart * 4;
	sb7.position = 0x5C + tstart * 4;

	uint[] pointers;

	int n = 0, bpos = 0;
	foreach (s; text) {
		uint rpos;

		if (fsl !is null) fs = fsl[n];

		char[] rs = fs.encodeString(s) ~ "\0";
		int ptr = rl.getAndUse(rs.length);
		rpos = ptr - ttable;

		//writefln("RPOS: %08X", ptr);

		sb7.write(rpos); n++;

		bpos = sb7.position;
			sb7.position = ptr;
			sb7.writeExact(rs.ptr, rs.length);
		sb7.position = bpos;
	}

	sb7.seek(0, SeekPos.End);

	while ((sb7.position % 4) != 0) {
		sb7.write(cast(ubyte)0);
	}

	sb7.position = 0;
}

// deprecated
TOAGameFormatString[] GetSB7Format(Stream sb7) {
	bool ignoreParams = true;
	sb7.position = 0;

	TOAGameFormatString[] list;
	ubyte[0x20] info;
	uint ttable;
	uint tstart;

	sb7.read(info);
	if (cast(char[])info[0..3] != "SB7") throw(new Exception("Invalid SB7 file"));

	// Relacionado con bytes anteriores
	sb7.position = 0x38;
	sb7.read(tstart);

	// Inicio del texto
	sb7.position = 0x50;
	sb7.read(ttable);

	//sb7.position = 0xB0 + tstart * 4;
	sb7.position = 0x5C + tstart * 4;

	uint[] pointers;

	int n = 0, bpos = 0;
	while (true) {
		uint rpos;
		sb7.read(rpos);
		if ((rpos == 0 && n != 0)) break;
		if (bpos > rpos) writefln("WARNING!");
		//writefln("%08X", rpos);
		pointers ~= rpos;
		bpos = rpos;
		n++;
	}

	foreach (pptr, p; pointers) {
		TOAGameFormatString fs = new TOAGameFormatString;
		fs.ignoreParams = ignoreParams;
		fs.extractStringz(sb7, p + ttable);
		list ~= fs;
	}

	return list;
}

// deprecated
char[][] GetSB7Text(Stream sb7, bool ignoreParams = true) {
	sb7.position = 0;

	TOAGameFormatString fs = new TOAGameFormatString;

	fs.ignoreParams = ignoreParams;

	char[][] list;
	ubyte[0x20] info;
	uint ttable;
	uint tstart;

	sb7.read(info);
	if (cast(char[])info[0..3] != "SB7") throw(new Exception("Invalid SB7 file"));

	// Relacionado con bytes anteriores
	sb7.position = 0x38;
	sb7.read(tstart);

	// Inicio del texto
	sb7.position = 0x50;
	sb7.read(ttable);

	//sb7.position = 0xB0 + tstart * 4;
	sb7.position = 0x5C + tstart * 4;

	uint[] pointers;

	int n = 0, bpos = 0;
	while (true) {
		uint rpos;
		sb7.read(rpos);
		if ((rpos == 0 && n != 0)) break;
		if (bpos > rpos) writefln("WARNING!");
		//writefln("%08X", rpos);
		pointers ~= rpos;
		bpos = rpos;
		n++;
	}

	foreach (pptr, p; pointers) {
		list ~= fs.extractStringz(sb7, p + ttable);
	}

	return list;
}

// deprecated
RangeList GetSB7Space(Stream sb7) {
	sb7.position = 0;

	RangeList rl = new RangeList();
	TOAGameFormatString fs = new TOAGameFormatString;

	char[][] list;
	ubyte[0x20] info;
	uint ttable;
	uint tstart;

	sb7.read(info);
	if (cast(char[])info[0..3] != "SB7") throw(new Exception("Invalid SB7 file"));

	// Relacionado con bytes anteriores
	sb7.position = 0x38;
	sb7.read(tstart);

	// Inicio del texto
	sb7.position = 0x50;
	sb7.read(ttable);

	//sb7.position = 0xB0 + tstart * 4;
	sb7.position = 0x5C + tstart * 4;

	uint[] pointers;

	int n = 0, bpos = 0;
	while (true) {
		uint rpos;
		sb7.read(rpos);
		if ((rpos == 0 && n != 0)) break;
		if (bpos > rpos) writefln("WARNING!");
		//writefln("%08X", rpos);
		pointers ~= rpos;
		bpos = rpos;
		n++;
	}

	foreach (pptr, p; pointers) {
		rl.add(p + ttable, fs.getStringzLength(sb7, p + ttable));
	}

	return rl;
}
