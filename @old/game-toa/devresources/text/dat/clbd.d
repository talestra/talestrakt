import std.stdio, std.c.stdio, std.string, std.stream, std.math, std.file;

char[][] split2(char[] s, char[] sub, uint count = 0x7FFFFFFF) {
	char[][] r = split(s, sub);
	if (count < 1) count = 1;
	if (r.length > count) r = r[0..count - 1] ~ std.string.join(r[count - 1..r.length], sub);
	if (!r.length) r = [""];
	return r;
}

char[][char[]] enemyTranslate;

char[][char[]] enemyMerge(char[][uint] o, char[][uint] t) {
	char[][char[]] r;
	foreach (k; o.keys) {
		if (!o[k].length) continue;
		r[o[k]] = t[k];
	}
	writefln(r.length);
	return r;
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

char[][uint] item_t;

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


char[][uint] enemyProcess(Stream s) {
	char[][uint] r;
	while (!s.eof) {
		char[] l = strip(s.readLine);
		if (l.length < 5) continue;
		char[][] p = split2(l, ":");
		char[] tex = strip(split2(p[1], "(")[0]);
		r[atoi(p[0])] = tex;
	}
	return r;
}

char[][uint] enemyProcess(char[] f) {
	return enemyProcess(new BufferedFile(f));
}

struct IENTRY {
	uint id;
	uint title;
	uint enemies_drop[3];
	uint enemies_drop_has[3];
	uint enemies_steal[3];
	uint enemies_steal_has[3];
	uint enemies_shops[2];
	uint enemies_shops_has[2];
	uint description;
	uint enemies_images[6];
}

char[] readStringz(Stream s) {
	char[] r;
	while (!s.eof) {
		ubyte c;
		s.read(c);
		if (c == 0) break;
		r ~= cast(char)c;
	}
	return r;
}

char[] readStringzAT(Stream s, int pos) {
	return readStringz(new SliceStream(s, pos));
}

void writeln(char[] s) {
	printf("%s\n", toStringz(s));
}

char[] translate(char[] t) {
	if (t in enemyTranslate) {
		//writeln(enemyTranslate[t]);
		return enemyTranslate[t];
	}
	
	return t;
}

void process_clbd() {
	int blockSize = 0x2000;
	auto s = new BufferedFile("_CLBD.DAT");
	auto s2 = new File("es/_CLBD.DAT", FileMode.OutNew | FileMode.In);
	s2.copyFrom(s); s2.position = 0;
	uint count = s.size / blockSize;
	
	ubyte clean[0x2000];
	
	void processFile(int n) {
		auto ss = new SliceStream(s2, (n + 0) * blockSize, (n + 1) * blockSize);
		auto ss_o = new MemoryStream(); ss_o.copyFrom(ss); ss_o.position = 0; ss.position = 0;
		
		ss.position = 0; ss.write(clean); ss.position = 0;
		
		IENTRY i, i_o; ss_o.readExact(&i, i.sizeof); i_o = i;
		
		//writefln(ss.position);
		
		ss.position = i.sizeof;
		
		char[] title = readStringzAT(ss_o, i_o.title);
		char[] desc = readStringzAT(ss_o, i_o.description);
		
		int title_idx = (n * 10) + 0;
		int desc_idx  = (n * 10) + 1;
		
		if (title_idx in item_t) title = item_t[title_idx];
		if (desc_idx in item_t) desc = item_t[desc_idx];
		
		i.title = ss.position; ss.writeString(translate(title) ~ "\0");
		
		for (int k = 0; k < 3; k++) { i.enemies_drop [k] = ss.position; ss.writeString(translate(readStringzAT(ss_o, i_o.enemies_drop [k])) ~ "\0"); }
		for (int k = 0; k < 3; k++) { i.enemies_steal[k] = ss.position; ss.writeString(translate(readStringzAT(ss_o, i_o.enemies_steal[k])) ~ "\0"); }
		for (int k = 0; k < 2; k++) { i.enemies_shops[k] = ss.position; ss.writeString(translate(readStringzAT(ss_o, i_o.enemies_shops[k])) ~ "\0"); }
		
		i.description = ss.position; ss.writeString(translate(desc) ~ "\0");
		
		while ((ss.position % 4) != 0) ss.write(cast(ubyte)0);

		// 0x280
		for (int k = 0; k < 6; k++) {
			ubyte[0x280] tm2;
			int p = i_o.enemies_images[k];
			if (p == 0) continue;

			ss_o.position = p;
			ss_o.read(tm2);
			
			p = ss.position;
			ss.write(tm2);
			
			i.enemies_images[k] = p;
		}
		
		/*
		writefln("%d", i.id);
		writeln(readStringzAT(ss_o, i.title));
		writeln(readStringzAT(ss_o, i.enemies_drop[0]));
		*/
		
		ss.position = 0;
		ss.writeExact(&i, i.sizeof);
		//writefln(n);
	}
	
	for (int n = 0; n < count; n++) {
		processFile(n);
	}
}

void process_icons() {
	int blockSize = 0x800;
	auto s = new BufferedFile("_I_ICO.DAT");
	uint count = s.size / blockSize;
	writefln(count);
	for (int n = 0; n < count; n++) {
		auto ss = new SliceStream(s, (n + 0) * blockSize, (n + 1) * blockSize);
		(new File(format("icons/%03d.txd", n), FileMode.OutNew)).copyFrom(ss);
	}
}

void process_icons_convert() {
	int count = 633;
	int rcount = 0;
	
	auto fout = new File("out.txd", FileMode.OutNew);
	
	fout.position = 0x1C;
	
	for (int n = 0; n < count; n++) {
		auto ss = new BufferedFile(format("icons/%03d.txd", n));
		auto ss2 = new SliceStream(ss, 0x1C, 0x1C + 0x3D4);
		auto ss3 = new MemoryStream();
		ss3.copyFrom(ss2);
		
		ss3.position = 0x2C;
		ss3.writeString(format("%03d.tm2\0", n));
		
		ss3.position = 0;
		fout.copyFrom(ss3); rcount++;
	}
	
	fout.position = 0;
	fout.write(cast(uint)0x16);
	fout.write(cast(uint)(fout.size - 12));
	fout.write(cast(uint)0x1C02002D);
	fout.write(cast(uint)0x1);
	fout.write(cast(uint)4);
	fout.write(cast(uint)0x1C02002D);
	fout.write(cast(ushort)rcount);
	fout.write(cast(ushort)6);
}

void main() {
	enemyTranslate = enemyMerge(enemyProcess("enemies.en"), enemyProcess("enemies.es"));
	
	char[] acme_es;
	for (int n = 0; n < 32; n++) acme_es ~= cast(char[])read(format("items/%04d.txt", n)) ~ "\n\n\n";
	item_t = getACME1(acme_es);
	
	/*
	foreach (e; enemyProcess("enemies.es")) {
		writefln(e);
	}*/
	process_clbd();
	//process_icons();
	//process_icons_convert();
}