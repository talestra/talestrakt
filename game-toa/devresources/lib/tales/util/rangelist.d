module tales.util.rangelist;

import std.stdio, std.file, std.format, std.stream, std.path, std.string, std.ctype, std.c.stdlib;

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
