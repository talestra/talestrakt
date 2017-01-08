import std.file, std.stdio, std.stream, std.string, std.regexp, std.conv;

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
		rangeEnd[from + rangeStart[from]] -= length;
		if (rangeStart[from] - length > 0) {
			rangeStart[from + length] = rangeStart[from] - length;
		}
		rangeStart.remove(from);
	}

	int getFreeRange(int length) {
		foreach (key; rangeStart.keys.sort) { if (rangeStart[key] >= length) return key; }
		throw(new Exception(format("Not enough space (%d)", length)));
	}

	int getAndUse(int length) {
		int r;
		use(r = getFreeRange(length), length);
		return r;
	}

	int length() {
		int r = 0; foreach (int l; rangeStart) r += l; return r;
	}
}


const int EXE_DISP = (0x100000 - 0x100);

int main() {
	Stream s;
	RangeList rl = new RangeList();

	s = new File("../../SLUS_213.86", FileMode.In | FileMode.Out);

	void addRange(int from, int to) {
		int length = to - from;
		rl.add(from, length);
		s.position = from - EXE_DISP;
		ubyte[] temp;
		temp.length = length;
		for (int n = 0; n < temp.length; n++) temp[n] = '\xFF';
		s.write(temp);
	}

	// Bloque: 0x005838D0-0x005B64D0
	addRange(0x005838D0, 0x005838E8);
	addRange(0x005838F8, 0x00583D80);
	addRange(0x00583D90, 0x005B64D0);


	// Ocupamos 0x08 bytes en las siguientes direcciones: 0x005838E0, 0x00583D80
	//rl.use(0x005838E0, 9);
	//rl.use(0x00583D80, 9);

	// Tabla de punteros a inicio de bloque
	// 0x005406D0

	char[][int][int] listdata;
	//char[][][] listdata;

	for (int n = 0; n < 114; n++) {
		char[] data = cast(char[])read(std.string.format("SRC/%04d.txt", n));
		char[][] list = std.string.split(data, "## POINTER ");

		for (int m = 1; m < list.length; m++) {
			char[] clist = list[m];
			if (auto mm = std.regexp.search(clist, "^\\d+")) {
				int z = toInt(mm.match(0));
				char[] str = "";
				try {
					str = std.string.stripr(clist[std.string.find(clist, "\n") + 1..clist.length]);
				} catch (Exception e) {
				}
				//listdata[n] ~= [];
				listdata[n][m - 1] ~= std.string.replace(str, "\r", "");
			}
		}
	}

		//writefln(list[1]);
		//break;


	for (int n = 0; n < 114; n++) {
		char[] string;
		uint structptr, temp;
		s.position = 0x005406D0 - EXE_DISP + 4 * n;
		s.read(structptr);
		s.position = structptr - EXE_DISP;

		// Title
		{
			//s.read(temp);
			//writefln("%08X", temp);
			string = listdata[n][0] ~ "\0";
			s.write(temp = rl.getAndUse(string.length));
			s.position = temp - EXE_DISP;
			writefln(n);
			s.writeString(string);
		}

		s.position = structptr - EXE_DISP + 8;

		// Body list
		{
			int m = 1;
			while (true) {
				s.read(temp);
				if (temp != 0x5838E8) break;

				string = listdata[n][m] ~ "\0";

				s.seek(3 * 4, SeekPos.Current);
				uint pback = s.position + 4;
				s.write(temp = rl.getAndUse(string.length));
				s.position = temp - EXE_DISP;
				s.writeString(string);
				s.position = pback;
				m++;
			}
		}
	}

	return 0;
}