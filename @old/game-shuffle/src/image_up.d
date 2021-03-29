module si;

public import
	std.stream, 
	std.stdio, 
	std.intrinsic, 
	std.path,
	std.math,
	std.file,
	std.process,
	std.string,
	std.system
;

int clamp(int v, int m, int M) {
	if (v < m) return m;
	if (v > M) return M;
	return v;
}

int hex(char c) {
	if (c >= '0' && c <= '9') return (c - '0') + 0;
	if (c >= 'a' && c <= 'f') return (c - 'a') + 10;
	if (c >= 'A' && c <= 'F') return (c - 'A') + 10;
	return -1;
}
int hex(char[] s) {
	int r;
	foreach (c; s) {
		int v = hex(c);
		if (v >= 0) {
			r *= 0x10;
			r += v;
		}
	}
	return r;
}

int imin(int a, int b) { return (a < b) ? a : b; }
int imax(int a, int b) { return (a > b) ? a : b; }
int iabs(int a) { return (a < 0) ? -a : a; }

void cendian(ref ushort v, Endian endian) { if (endian != std.system.endian) v = (bswap(v) >> 16); }
void cendian(ref uint   v, Endian endian) { if (endian != std.system.endian) v = bswap(v); }

template TA(T) { ubyte[] TA(ref T t) { return cast(ubyte[])(&t)[0..1]; } }

template swap(T) { void swap(ref T t1, ref T t2) { T t = t1; t1 = t2; t2 = t;} }

class Bit {
	final static ulong MASK(ubyte size) {
		return ((1 << size) - 1);
	}
	
	final static ulong INS(ulong v, ubyte pos, ubyte size, int iv) {
		ulong mask = MASK(size);
		return (v & ~(mask << pos)) | ((iv & mask) << pos);
	}
	
	final static ulong EXT(ulong v, ubyte pos, ubyte size) {
		return (v >> pos) & MASK(size);
	}
	
	static long div_mult_ceil (long v, long mult, long div) { return cast(long)std.math.ceil (cast(real)(v * mult) / cast(real)div); }
	static long div_mult_round(long v, long mult, long div) { return cast(long)std.math.round(cast(real)(v * mult) / cast(real)div); }
	static long div_mult_floor(long v, long mult, long div) { return (v * mult) / div; }
	alias div_mult_floor div_mult;

	//////////////////////////

	final static ulong INS2(ulong v, ubyte pos, ubyte size, int iv, int base) {
		ulong mask = MASK(size);

		/*
		writefln("%d", iv);
		writefln("%d", mask);
		writefln("%d", base);
		writefln("--------");
		*/
	
		return INS(v, pos, size, div_mult_ceil(iv, mask, base));
	}

	final static ulong EXT2(ulong v, ubyte pos, ubyte size, int base) {
		ulong mask = MASK(size);
		if (mask == 0) return 0;
		
		/*
		writefln("%d", EXT(v, pos, size));
		writefln("%d", base);
		writefln("%d", mask);
		writefln("--------");
		*/
		
		return div_mult_ceil(EXT(v, pos, size), base, mask);
	}
}

class ImageFileFormatProvider {
	static ImageFileFormat[char[]] list;

	static void registerFormat(ImageFileFormat iff) {
		list[iff.identifier] = iff;
	}

	static ImageFileFormat find(Stream s, int check_size = 1024) {
		auto ss = new SliceStream(s, 0);
		auto data = new ubyte[check_size];
		auto cs = new MemoryStream(data[0..ss.read(data)]);

		ImageFileFormat cff;
		int certain = 0;
		foreach (iff; list.values) {
			cs.position = 0;
			int c_certain = iff.check(cs);
			if (c_certain > certain) {
				cff = iff;
				certain = c_certain;
				if (certain >= 10) break;
			}
		}
		if (certain == 0) throw(new Exception("Unrecognized ImageFileFormat"));
		return cff;
	}

	static Image read(Stream s) { return find(s).read(s); }
	
	static Image read(char[] name) {
		Stream s = new BufferedFile(name);
		Image i = read(s);
		s.close();
		return i;
	}

	static ImageFileFormat opIndex(char[] idx) {
		if ((idx in list) is null) throw(new Exception(std.string.format("Unknown ImageFileFormat '%s'", idx)));
		return list[idx];
	}
}

// Abstract ImageFileFormat
abstract class ImageFileFormat {
	private this() { }
	
	bool update(Image i, Stream s) { throw(new Exception("Updating not implemented")); return false; }
	bool update(Image i, char[] name) { Stream s = new File(name, FileMode.OutNew); bool r = update(i, s); s.close(); return r; }
	
	bool write(Image i, Stream s) { throw(new Exception("Writing not implemented")); return false; }
	bool write(Image i, char[] name) { Stream s = new File(name, FileMode.OutNew); bool r = write(i, s); s.close(); return r; }
	
	Image read(Stream s) { throw(new Exception("Reading not implemented")); return null; }
	Image[] readMultiple(Stream s) { throw(new Exception("Multiple reading not implemented")); return null; }

	char[] identifier() { return "null"; }
	
	// 0 - impossible (discard)
	//
	// ... different levels of probability (uses the most probable)
	//
	// 10 - for sure (use this)
	int check(Stream s) { return 0; }
}

align(1) struct ColorFormat {
	align(1) struct Set {
		union {
			struct { ubyte r, g, b, a; }
			ubyte[4] vv;
		}
	}
	Set pos, len;
}

ColorFormat RGBA_8888 = { {0, 8, 16, 24}, {8, 8, 8, 8} };
ColorFormat RGBA_5551 = { {0, 5, 10, 15}, {5, 5, 5, 1} };
ColorFormat RGBA_5650 = { {0, 5, 11, 26}, {5, 6, 5, 0} };

align(1) struct RGBAf {
	union {
		struct { float r, g, b, a; }
		float[4] vv;
	}
	
	static ubyte clamp(float v) {
		float r = v * 0xFF;
		if (r > 0xFF) r = 0xFF;
		if (r < 0x00) r = 0x00;
		return cast(ubyte)r;
	}
	
	RGBA rgba() { return RGBA(clamp(r), clamp(g), clamp(b), clamp(a)); }
	
	static RGBAf opCall(float r, float g, float b, float a) {
		RGBAf c = {r, g, b, a};
		return c;
	}
	
	static RGBAf opCall(RGBA c) {
		RGBAf cf = void;
		for (int n = 0; n < 4; n++) cf.vv[n] = cast(float)c.vv[n] / 0xFF;
		return cf;
	}
	
	RGBAf opMul(float m) {
		//return RGBAf(r * m, g * m, b * m, a * m);
		return RGBAf(r * m, g * m, b * m, a);
	}
	
	RGBAf opAdd(RGBAf c) {
		RGBAf r = void;
		for (int n = 0; n < 4; n++) r.vv[n] = vv[n] + c.vv[n];
		return r;
	}
	
	static RGBAf over(RGBAf c1, RGBAf c2) {
		return c1 * c1.a + c2 * (c2.a * (1 - c1.a));
	}
	
	char[] toString() {
		return std.string.format("RGBA(%02X,%02X,%02X,%02X)", r, g, b, a);
	}	
}

// TrueColor pixel
align(1) struct RGBA {
	union {
		struct { ubyte r; ubyte g; ubyte b; ubyte a; }
		struct { byte _r; byte _g; byte _b; byte _a; }
		struct { ubyte[4] vv; }
		uint v;
		alias r R;
		alias g G;
		alias b B;
		alias a A;
	}
	
	ulong decode(ColorFormat format) {
		ulong rr;
		for (int n = 0; n < 4; n++) rr = Bit.INS2(rr, format.pos.vv[n], format.len.vv[n], vv[n], 0xFF);
		return rr;
	}
	
	static RGBA opCall(ColorFormat format, ulong data) {
		RGBA c = void;
		for (int n = 0; n < 4; n++) c.vv[n] = Bit.EXT2(data, format.pos.vv[n], format.len.vv[n], 0xFF);
		return c;
	}
	
	static RGBA opCall(ubyte r, ubyte g, ubyte b, ubyte a = 0xFF) {
		RGBA c = {r, g, b, a};
		return c;
	}
	
	static RGBA opCall(uint v) {
		RGBA c = void;
		c.v = v;
		return c;
	}
	
	static RGBA opCall(char[] s) {
		RGBA c;
		for (int n = 0; n < s.length; n += 2) c.vv[n / 2] = hex(s[n..n + 2]);
		return c;
	}
	
	static RGBA toBGRA(RGBA c) {
		ubyte r = c.r;
		c.r = c.b;
		c.b = r;
		return c;
	}
	
	static int dist(RGBA a, RGBA b) {
		alias std.math.abs abs;
		return (
			abs(a._r - b._r) +
			abs(a._g - b._g) +
			abs(a._b - b._b) +
			abs(a._a - b._a) +
		0);
	}
	
	char[] toString() {
		return std.string.format("RGBA(%02X,%02X,%02X,%02X)", r, g, b, a);
	}
}

static assert (RGBA.sizeof == 4);

// Abstract Image
abstract class Image {
	char[] id;
	Image[] childs;

	// Info
	ubyte bpp();
	int width();
	int height();

	// Data
	void set(int x, int y, uint v);
	uint get(int x, int y);
	ubyte[] _data() { return null; }

	void set32(int x, int y, RGBA c) {
		if (bpp == 32) { return set(x, y, c.v); }
		throw(new Exception("Not implemented (set32)"));
	}

	RGBA get32(int x, int y) {
		if (bpp == 32) {
			RGBA c; c.v = get(x, y);
			return c;
		}
		throw(new Exception("Not implemented (get32)"));
	}
	
	Image filter(RGBA delegate(int, int, RGBA) func, bool duplicate = false) {
		if (duplicate) { return this.duplicate.filter(func, false); }
		int w = width, h = height;
		for (int y = 0; y < h; y++) {
			for (int x = 0; x < w; x++) {
				set32(x, y, func(x, y, get32(x, y)));
			}
		}
		return this;
	}
	
	Image duplicate() { assert(0 != 1, "duplicate not implemented"); return null; }

	RGBA getColor(int x, int y) {
		RGBA c;
		c.v = hasPalette ? color(get(x, y)).v : get(x, y);
		return c;
	}

	// Palette
	bool hasPalette() { return (bpp <= 8); }
	int ncolor() { return 0; }
	int ncolor(int n) { return ncolor; }
	RGBA color(int idx) { RGBA c; return c; }
	RGBA color(int idx, RGBA c) { return color(idx); }
	RGBA[] colors() {
		RGBA[] cc;
		for (int n = 0; n < ncolor; n++) cc ~= color(n);
		return cc;
	}

	static uint colorDist(RGBA c1, RGBA c2) {
		return (
			(
				iabs(c1.r * c1.a - c2.r * c2.a) +
				iabs(c1.g * c1.a - c2.g * c2.a) +
				iabs(c1.b * c1.a - c2.b * c2.a) +
				iabs(c1.a * c1.a - c2.a * c2.a) +
			0)
		);
	}

	RGBA[] createPalette(int count = 0x100) { throw(new Exception("Not implemented: createPalette")); }

	uint matchColor(RGBA c) {
		uint mdist = 0xFFFFFFFF;
		uint idx;
		for (int n = 0; n < ncolor; n++) {
			uint cdist = colorDist(color(n), c);
			if (cdist < mdist) {
				mdist = cdist;
				idx = n;
			}
		}
		return idx;
	}
	
	void blit(Image i, int px = 0, int py = 0, float alpha = 1.0) {
		int w = width, h = height;
		for (int y = 0; y < h; y++) {
			for (int x = 0; x < w; x++) {
				RGBAf c = RGBAf(get32(x, y));
				RGBAf c2 = RGBAf(i.get32(px + x, py + y));
				c.a *= alpha;
				c = RGBAf.over(c, c2);
				//writefln("%f, %f, %f, %f", c.r, c.g, c.b, c.a);
				i.set32(px + x, py + y, c.rgba);
			}
		}
	}

	void copyFrom(Image i, bool convertPalette = false) {
		int mw = imin(width, i.width);
		int mh = imin(height, i.height);

		//if (bpp != i.bpp) throw(new Exception(std.string.format("BPP mismatch copying image (%d != %d)", bpp, i.bpp)));

		if (i.hasPalette) {
			ncolor = i.ncolor;
			for (int n = 0; n < ncolor; n++) color(n, i.color(n));
		}

		/*if (hasPalette && !i.hasPalette) {
			i = toColorIndex(i);
		}*/

		if (convertPalette && hasPalette && !i.hasPalette) {
			foreach (idx, c; i.createPalette(ncolor)) color(idx, c);
		}

		if (hasPalette && i.hasPalette) {
			for (int y = 0; y < i.height; y++) for (int x = 0; x < i.width; x++) set(x, y, get(x, y));
		} else if (hasPalette) {
			for (int y = 0; y < i.height; y++) for (int x = 0; x < i.width; x++) set(x, y, matchColor(i.get32(x, y)));
		} else {
			for (int y = 0; y < i.height; y++) for (int x = 0; x < i.width; x++) set32(x, y, i.get32(x, y));
		}
	}
	
	static Image composite(Image color, Image alpha) {
		Image r = new Bitmap32(color.width, color.height);
		for (int y = 0; y < color.height; y++) {
			for (int x = 0; x < color.width; x++) {
				RGBA c = color.get32(x, y);
				RGBA a = alpha.get32(x, y);
				c.a = a.r;
				r.set32(x, y, c);
			}
		}
		return r;
	}
	
	void setChroma(RGBA c) {
		if (hasPalette) {
			foreach (idx, cc; colors) {
				if (cc == c) color(idx, RGBA(0, 0, 0, 0));
			}
		} else {
			for (int y = 0; y < height; y++) {
				for (int x = 0; x < width; x++) {
					if (get32(x, y) == c) set32(x, y, RGBA(0, 0, 0, 0));
				}
			}
		}
	}
	
	void write(char[] file, char[] format = null) {
		if (format is null) format = getExt(file);
		ImageFileFormatProvider[format].write(this, file);
	}
	void write(Stream file, char[] format) { ImageFileFormatProvider[format].write(this, file); }
	
	alias ImageFileFormatProvider.read read;
	
	bool check_bounds(int x, int y) { return !(x < 0 || y < 0 || x >= width || y >= height); }
	
	Image channel(int idx) {
		throw(new Exception("Channel getter not implemented"));
	}
}

// TrueColor Bitmap
class Bitmap32 : Image {
	RGBA[] data;
	int _width, _height;
	bool using_chroma = false;
	RGBA chroma;
	
	ubyte[] _data() { return cast(ubyte[])data; }
	
	RGBA *get_pos(int x, int y) {
		if (!check_bounds(x, y)) return null;
		return &data[y * _width + x];
	}

	class Channel : Image {
		int idx;
		
		this(int idx) {
			this.idx = idx;
		}
		
		bool hasPalette() { return true; }
		RGBA color(int n) { return RGBA(n, n, n, 0xFF); }
		
		ubyte bpp() { return 8; }
		int width() { return _width; }
		int height() { return _height; }
		
		void set(int x, int y, uint v) {
			auto p = get_pos(x, y);
			if (p !is null) p.vv[idx] = v;
		}

		uint get(int x, int y) {
			auto p = get_pos(x, y);
			if (p !is null) return p.vv[idx];
			return -1;
		}
	}

	Image channel(int idx) {
		return new Channel(idx);
	}

	ubyte bpp() { return 32; }
	int width() { return _width; }
	int height() { return _height; }
	
	override Image duplicate() {
		auto r = new Bitmap32(_width, _height);
		r.chroma = chroma;
		r.data = data.dup;
		return r;
	}
	
	void set(int x, int y, uint v) { if (check_bounds(x, y)) data[y * _width + x].v = v; }
	uint get(int x, int y) {
		if (!check_bounds(x, y)) return 0;
		uint c = data[y * _width + x].v;
		if (using_chroma && chroma.v == c) return RGBA(0, 0, 0, 0).v;
		return c;
	}
	
	alias createPalette1 createPalette;
	
	RGBA[] createPalette1(int count = 0x100) {
		RGBA[] r;
	
		int[RGBA] colors;
		RGBA[][int] colors_pos;
		foreach (c; data) {
			if (c in colors) colors[c]++;
			else colors[c] = 1;
		}
		colors = colors.rehash;
		
		colors_pos = null;
		foreach (c, n; colors) colors_pos[n] ~= c;
		
		int[] lengths = colors_pos.keys.sort.reverse;
		
		foreach (cc_count; lengths) {
			//writefln(cc_count);
			foreach (cc; colors_pos[cc_count]) {
				//writefln(cc);
				r ~= cc;
				if (r.length >= count) break;
			}
			if (r.length >= count) break;
		}
		
		return r;
	}
	
	RGBA[] createPalette2(int count = 0x100) {
		RGBA[] r;
		bool[] fixed;
		long[] scores;
	
		int[RGBA] colors;
		RGBA[][int] colors_pos;
		foreach (c; data) {
			if (c in colors) colors[c]++;
			else colors[c] = 1;
		}
		colors = colors.rehash;
		
		colors_pos = null;
		foreach (c, n; colors) {
			colors_pos[n] ~= c;
		}
		
		if (1 in colors_pos) {
			//if (colors.length - colors_pos[1].length > 256) {
			if (colors.length - colors_pos[1].length > 512) {
				colors_pos[1] = null;
			}
		}
		
		foreach (cc_count; colors_pos.keys.sort.reverse) foreach (cc; colors_pos[cc_count]) { r ~= cc; scores ~= cc_count; fixed ~= false; }
		
		for (int n = 0; n < count; n++) {
			if (fixed[n]) continue;
			uint lower_value = 0xFFFFFFFF, higher_value = 0x00000000;
			int lower_index = -1, higher_index = -1;
		
			for (int m = n + 1; m < count; m++) {
				if (fixed[m]) continue;
				uint c_dist = colorDist(r[n], r[m]);
				if (c_dist <= lower_value) {
					lower_value = c_dist;
					lower_index = m;
				}
			}
			
			for (int m = count; m < r.length; m++) {
				if (fixed[m]) continue;
				uint c_dist = colorDist(r[n], r[m]);
				if (c_dist >= higher_value) {
					higher_value = c_dist;
					higher_index = m;
				}
			}
			
			if (higher_index != -1 && lower_index != -1) {
				swap(r[lower_index], r[higher_index]);
				fixed[lower_index] = true;
			}

			writefln("%d, %d", lower_value, lower_index);
			
			//break;
		}
		
		writefln(r.length);
		
		/*
		for (int n = 0; n < r.length; n++) {
			writefln("%s: %d", r[n], scores[n]);
		}
		*/
		
		return r[0..count];
	}
	
	Bitmap8 paletize(int ncolors = 0x100) {
		int[RGBA] colors;
		
		auto r = new Bitmap8(width, height);
		
		r.palette = createPalette(ncolors);
		
		foreach (c; data) colors[c] = 0;
		foreach (c; colors.keys) colors[c] = r.matchColor(c);
		
		for (int y = 0; y < _height; y++) for (int x = 0; x < _width; x++) r.set(x, y, colors[get32(x, y)]);
		
		return r;
	}
	
	override void setChroma(RGBA c) {
		using_chroma = true;
		chroma = c;
	}

	this(int w, int h) {
		_width = w;
		_height = h;
		data.length = w * h;
	}
	
	static Bitmap32 convert(Image i) {
		auto r = new Bitmap32(i.width, i.height);
		for (int y = 0; y < r._height; y++) for (int x = 0; x < r._width; x++) r.set32(x, y, i.get32(x, y));
		return r;
	}
}

// Palletized Bitmap
class Bitmap8 : Image {
	RGBA[] palette;
	ubyte[] data;
	int _width, _height;
	
	ubyte[] _data() { return cast(ubyte[])data; }

	override ubyte bpp() { return 8; }
	int width() { return _width; }
	int height() { return _height; }

	void set(int x, int y, uint v) { if (check_bounds(x, y)) data[y * _width + x] = v; }
	uint get(int x, int y) { return check_bounds(x, y) ? data[y * _width + x] : 0; }
	override RGBA get32(int x, int y) { return palette[get(x, y) % palette.length];		 }
	
	override int ncolor() { return palette.length;}
	override int ncolor(int s) { palette.length = s; return s; }
	RGBA color(int idx) { return palette[idx]; }
	RGBA color(int idx, RGBA col) { return palette[idx] = col; }
	void colorSwap(int i1, int i2) {
		if (i1 >= palette.length || i2 >= palette.length) return;
		swap(palette[i1], palette[i2]);
	}
	
	this(int w, int h) {
		_width = w;
		_height = h;
		data.length = w * h;
	}
}

// http://local.wasp.uwa.edu.au/~pbourke/dataformats/tga/
class ImageFileFormat_TGA : ImageFileFormat {
	override char[] identifier() { return "tga"; }

	align(1) struct TGA_Header {
		ubyte idlength;           // 0
		ubyte colourmaptype;      // 1
		ubyte datatypecode;       // 2
		short colourmaporigin;    // 3-4
		short colourmaplength;    // 5-6
		ubyte colourmapdepth;     // 7
		short x_origin;           // 8-9
		short y_origin;           // 10-11
		short width;              // 12-13
		short height;             // 14-15
		ubyte bitsperpixel;       // 16
		ubyte imagedescriptor;    // 17
	   
		private alias imagedescriptor id;

		int  atr_bits()          { return Bit.EXT(id, 0, 3); }
		int  atr_bits(int v)     { id = Bit.INS(id, 0, 3, v); return atr_bits; }

		bool flip_y()            { return Bit.EXT(id, 5, 1) == 0; }
		bool flip_y(bool v)      { id = Bit.INS(id, 5, 1, !v); return flip_y; }

		int  interleaving()      { return Bit.EXT(id, 6, 2); }
		int  interleaving(int v) { id = Bit.INS(id, 6, 2, v); return interleaving; }
	}
	
	static assert (TGA_Header.sizeof == 18);

	override bool write(Image i, Stream s) {
		TGA_Header h;

		h.idlength = 0;
		h.x_origin = 0;
		h.y_origin = 0;
		h.width = i.width;
		h.height = i.height;
		//h.imagedescriptor = 0b_00_1_0_1000;
		h.flip_y = false;
		
		if (i.hasPalette) {
			h.colourmaptype = 1;
			h.datatypecode = 1;
			h.colourmaporigin = 0;
			h.colourmaplength = i.ncolor;
			h.colourmapdepth = 24;
			h.bitsperpixel = 8;
			
			h.imagedescriptor |= 8;
			//h.imagedescriptor = 8;
		} else {
			h.colourmaptype = 0;
			h.datatypecode = 2;
			h.colourmaplength = 0;
			h.colourmapdepth = 0;
			h.bitsperpixel = 32;
		}

		s.write(TA(h));
		
		// CLUT
		if (i.hasPalette) {
			for (int n = 0; n < h.colourmaplength; n++) {
				s.write(TA(RGBA.toBGRA(i.color(n)))[0..(h.colourmapdepth / 8)]);
			}
		}

		ubyte[] data;
		data.length = h.width * h.height * (i.hasPalette ? 1 : 4);
		//writef("(%dx%d)", h.width, h.height);

		ubyte *ptr = data.ptr;
		if (i.hasPalette) {
			for (int y = 0; y < h.height; y++) for (int x = 0; x < h.width; x++) {
				*ptr = cast(ubyte)i.get(x, y);
				ptr++;
			}
		} else {
			for (int y = 0; y < h.height; y++) for (int x = 0; x < h.width; x++) {
				RGBA c; c.v = i.get(x, y);
				*cast(uint *)ptr = RGBA.toBGRA(c).v;
				ptr += 4;
			}
		}

		s.write(data);
		
		s.write(cast(ubyte[])x"000000000000000054525545564953494F4E2D5846494C452E00");

		return false;
	}
	
	override Image read(Stream s) {
		TGA_Header h; s.read(TA(h));

		// Skips Id Length field
		s.seek(h.idlength, SeekPos.Current);
		
		assert (h.width <= 4096);
		assert (h.height <= 4096);
		
		assert (h.x_origin == 0);
		assert (h.y_origin == 0);

		RGBA readcol(int depth) {
			RGBA c;
			switch (depth) {
				case 16:
				break;
				case 24:
					s.read(TA(c)[0..3]);
					c = RGBA.toBGRA(c);
					c.a = 0xFF;					
				break;
				case 32:
					s.read(TA(c)[0..4]);
					c = RGBA.toBGRA(c);
				break;
				default: throw(new Exception(format("Invalid TGA Color Map Depth %d", h.colourmapdepth)));
			}
			return c;
		}
		
		int readcols(RGBA[] r, int depth) {
			for (int n = 0; n < r.length; n++) {
				r[n] = readcol(depth);
			}
			return r.length;
		}

		int y_from, y_to, y_inc;
			
		if (h.flip_y) {
			y_from = h.height - 1;
			y_to = -1;
			y_inc = -1;
		} else {
			y_from = 0;
			y_to = h.height;
			y_inc = 1;
		}		
		
		switch (h.datatypecode) {
			case 0: // No image data included.
			{
				return null;
			}
			break;
			case 1: // Uncompressed, color-mapped images.
			{
				auto i = new Bitmap8(h.width, h.height);
				
				if (h.colourmaporigin + h.colourmaplength > 0x100) {
					throw(new Exception("Not implemented multibyte mapped images"));
				}
				
				i.ncolor = h.colourmaporigin + h.colourmaplength;
				
				for (int n = 0; n < h.colourmaplength; n++) {
					i.color(n + h.colourmaporigin, readcol(h.colourmapdepth));
				}

				auto row = new ubyte[h.width];

				for (int y = y_from; y != y_to; y += y_inc) {
					s.read(row);
					for (int x = 0; x < h.width; x++) {
						i.set(x, y, row[x]);
					}
				}
				
				return i;
			}
			break;
			case 2: // Uncompressed, RGB images.
			{
				auto i = new Bitmap32(h.width, h.height);
				
				auto row = new RGBA[h.width];
				for (int y = y_from; y != y_to; y += y_inc) {
					readcols(row, h.bitsperpixel);
					for (int x = 0; x < h.width; x++) {
						i.set32(x, y, row[x]);
					}
				}
				//writefln(h.bitsperpixel);
				
				return i;
			}
			break;
			case  3:  // Uncompressed, black and white images.
			case  9:  // Runlength encoded color-mapped images.
			case 10:  // Runlength encoded RGB images.
			case 11:  // Compressed, black and white images.
			case 32:  // Compressed color-mapped data, using Huffman, Delta, and runlength encoding.
			case 33:  // Compressed color-mapped data, using Huffman, Delta, and runlength encoding.  4-pass quadtree-type process.
			break;
			default: throw(new Exception(format("Invalid tga colour map type: %d", h.datatypecode)));
		}

		throw(new Exception(format("Unimplemented tga colour map type: %d", h.datatypecode)));
		return null;
	}
	
	override int check(Stream s) {
		TGA_Header h; s.read(TA(h));
		switch (h.datatypecode) {
			default: return 0;
			case 0, 1, 2, 3, 9, 10, 11, 32, 33: break;
		}

		if (h.width > 4096 || h.height > 4096) return 0;
		
		return 5;
	}	
}

static this() {
	ImageFileFormatProvider.registerFormat(new ImageFileFormat_TGA);
}

class ImageFileFormat_IMG : ImageFileFormat {
	struct Header {
		ushort width, height;
		uint bpp;
		uint pad[2];
	}
	
	override Image read(Stream s) {
		return null;
	}

	override bool write(Image i, Stream s) {
		Header h;
		h.width  = i.width;
		h.height = i.height;
		h.bpp    = i.bpp;
		s.write(TA(h));
		auto i2 = i.duplicate;
		
		s.write(i.filter(delegate RGBA(int x, int y, RGBA c) {
			return RGBA.toBGRA(c);
		}, true)._data);

		return false;
	}
	
	override int check(Stream s) {
		Header h; s.read(TA(h));
		if (((h.bpp % 8) != 0) || (h.bpp < 0) && (h.bpp > 32)) return 0;
		if ((h.pad[0] != 0) || (h.pad[1] != 0)) return 0;
		if ((h.width <= 0) || (h.height <= 0)) return 0;
		if ((h.width > 8096 )|| (h.height > 8096)) return 0;
		
		return 5;
	}
	
	override char[] identifier() { return "img"; }
}

static this() {
	ImageFileFormatProvider.registerFormat(new ImageFileFormat_IMG);
}

import std.zlib;

// SPECS: http://www.libpng.org/pub/png/spec/iso/index-object.html
class ImageFileFormat_PNG : ImageFileFormat {
	void[] header = x"89504E470D0A1A0A";

	override char[] identifier() { return "png"; }

	align(1) struct PNG_IHDR {
		uint width;
		uint height;
		ubyte bps;
		ubyte ctype;
		ubyte comp;
		ubyte filter;
		ubyte interlace;
	}

	override bool write(Image i, Stream s) {
		PNG_IHDR h;

		void writeChunk(char[4] type, void[] data = []) {
			uint crc = void;

			s.write(bswap(cast(uint)(cast(ubyte[])data).length));
			s.write(cast(ubyte[])type);
			s.write(cast(ubyte[])data);

			ubyte[] full = cast(ubyte[])type ~ cast(ubyte[])data;
			crc = etc.c.zlib.crc32(0, cast(ubyte *)full.ptr, full.length);

			s.write(bswap(crc));
		}

		void writeIHDR() { writeChunk("IHDR", TA(h)); }
		void writeIEND() { writeChunk("IEND", []); }

		void writeIDAT() {
			ubyte[] data;

			data.length = i.height + i.width * i.height * 4;

			int n = 0;
			ubyte *datap = data.ptr;
			for (int y = 0; y < i.height; y++) {
				*datap = 0x00; datap++;
				for (int x = 0; x < i.width; x++) {
					if (i.hasPalette) {
						*datap = cast(ubyte)i.get(x, y); datap++;
					} else {
						RGBA cc = i.getColor(x, y);
						*datap = cc.r; datap++;
						*datap = cc.g; datap++;
						*datap = cc.b; datap++;
						*datap = cc.a; datap++;
					}
				}
			}

			writeChunk("IDAT", std.zlib.compress(data, 9));
		}

		void writePLTE() {
			ubyte[] data;
			data.length = i.ncolor * 3;
			ubyte* pdata = data.ptr;
			for (int n = 0; n < i.ncolor; n++) {
				RGBA c = i.color(n);
				*pdata = c.r; pdata++;
				*pdata = c.g; pdata++;
				*pdata = c.b; pdata++;
			}
			writeChunk("PLTE", data);
		}

		void writetRNS() {
			ubyte[] data;
			data.length = i.ncolor;
			ubyte* pdata = data.ptr;
			bool hasTrans = false;
			for (int n = 0; n < i.ncolor; n++) {
				RGBA c = i.color(n);
				*pdata = c.a; pdata++;
				if (c.a != 0xFF) hasTrans = true;
			}
			if (hasTrans) writeChunk("tRNS", data);
		}

		s.write(cast(ubyte[])header);
		h.width = bswap(i.width);
		h.height = bswap(i.height);
		h.bps = 8;
		h.ctype = (i.hasPalette) ? 3 : 6;
		h.comp = 0;
		h.filter = 0;
		h.interlace = 0;

		writeIHDR();
		if (i.hasPalette) {
			writePLTE();
			writetRNS();
		}
		writeIDAT();
		writeIEND();

		return true;
	}

	override Image read(Stream s) {
		PNG_IHDR h;

		uint Bpp;
		Image i;
		ubyte[] buffer;
		uint size, crc;
		ubyte[4] type;
		bool finished = false;

		if (!check(s)) throw(new Exception("Not a PNG file"));

		while (!finished && !s.eof) {
			s.read(size); size = bswap(size);
			s.read(type);
			uint pos = s.position;

			//writefln("%s", cast(char[])type);

			switch (cast(char[])type) {
				case "IHDR":
					s.read(TA(h));
					h.width = bswap(h.width); h.height = bswap(h.height);

					switch (h.ctype) {
						case 4: case 0: throw(new Exception("Grayscale images not supported yet"));
						case 2: Bpp = 3; break; // RGB
						case 3: Bpp = 1; break; // Index
						case 6: Bpp = 4; break; // RGBA
						default: throw(new Exception("Invalid image type"));
					}

					i = (Bpp == 1) ? cast(Image)(new Bitmap8(h.width, h.height)) : cast(Image)(new Bitmap32(h.width, h.height));
				break;
				case "PLTE":
					if (size % 3 != 0) throw(new Exception("Invalid Palette"));
					i.ncolor = size / 3;
					for (int n = 0; n < i.ncolor; n++) {
						RGBA c;
						s.read(c.r);
						s.read(c.g);
						s.read(c.b);
						c.a = 0xFF;
						i.color(n, c);
					}
				break;
				case "tRNS":
					if (Bpp == 1) {
						//if (size != i.ncolor) throw(new Exception(std.string.format("Invalid Transparent Data (%d != %d)", size, i.ncolor)));
						//for (int n = 0; n < i.ncolor; n++) {
						for (int n = 0; n < size; n++) {
							RGBA c = i.color(n);
							s.read(c.a);
							i.color(n, c);
						}
					} else {
						throw(new Exception(std.string.format("Invalid Transparent Data (%d != %d) 32bits", size, i.ncolor)));
					}
				break;
				case "IDAT":
					ubyte[] temp; temp.length = size;
					s.read(temp); buffer ~= temp;
				break;
				case "IEND":
					ubyte[] idata = cast(ubyte[])std.zlib.uncompress(buffer);
					ubyte *pdata = void;

					ubyte[] row, prow;

					prow.length = Bpp * (h.width + 1);
					row.length = prow.length;

					ubyte PaethPredictor(int a, int b, int c) {
						int babs(int a) { return (a < 0) ? -a : a; }
						int p = a + b - c; int pa = babs(p - a), pb = babs(p - b), pc = babs(p - c);
						if (pa <= pb && pa <= pc) return a; else if (pb <= pc) return b; else return c;
					}

					for (int y = 0; y < h.height; y++) {
						int x;

						pdata = idata.ptr + (1 + Bpp * h.width) * y;
						ubyte filter = *pdata; pdata++;
						
						//writefln("%d: %d", y, filter);
						
						switch (filter) {
							default: throw(new Exception(std.string.format("Row filter 0x%02d unsupported", filter)));
							case 0: for (x = Bpp; x < row.length; x++, pdata++) row[x] = *pdata + 0; break; // Unfiltered
							case 1: for (x = Bpp; x < row.length; x++, pdata++) row[x] = *pdata + row[x - Bpp]; break; // Sub
							case 2: for (x = Bpp; x < row.length; x++, pdata++) row[x] = *pdata + prow[x]; break; // Up
							case 3: for (x = Bpp; x < row.length; x++, pdata++) row[x] = *pdata + (row[x - Bpp] + prow[x]) / 2; break; // Average
							case 4: for (x = Bpp; x < row.length; x++, pdata++) row[x] = *pdata + PaethPredictor(row[x - Bpp], prow[x], prow[x - Bpp]); break; // Paeth
						}

						prow[0..row.length] = row[0..row.length];

						ubyte *rowp = row.ptr + Bpp;
						for (x = 0; x < h.width; x++) {
							if (Bpp == 1) {
								i.set(x, y, *rowp++);
							} else {
								RGBA c;
								c.r = *rowp++;
								c.g = *rowp++;
								c.b = *rowp++;
								c.a = (Bpp == 4) ? *rowp++ : 0xFF;
								i.set(x, y, c.v);
							}
						}
					}
					//writefln("%d", pdata - idata.ptr);
					//writefln("%d", idata.length);
					finished = true;
				break;
				default: break;
			}
			s.position = pos + size;
			s.read(crc);
			//break;
		}

		return i;
	}

	override int check(Stream s) {
		ubyte[] cheader; cheader.length = header.length;
		s.read(cast(ubyte[])cheader);
		return (cheader == header) ? 10 : 0;
	}
}

static this() {
	ImageFileFormatProvider.registerFormat(new ImageFileFormat_PNG);
}

Image gaussian(Image i, int rad = 3, real o = 0.84089642) {
	//real o = 0.84089642;
	int[] v_int;
	real[] v;
	uint mult = 0xFFFFFF;
	real sum = 0, sum2 = 0;
	for (int x = -rad; x <= rad; x++) {
		real cv = 1 / sqrt(2 * PI * o) * pow(E, (-x * x) / (2 * o * o * cast(real)rad));
		v ~= cv;
		sum += cv;
	}
	// Normalize.
	int v_int_sum;
	for (int x = 0; x < v.length; x++) {
		v[x] /= sum;
		v_int ~= cast(uint)(v[x] * cast(real)mult);
		v_int_sum += v_int[x];
	}
	writefln(v_int);
	writefln(v_int_sum);

	foreach (pass; [0, 1]) {
	//foreach (pass; [0]) {
		for (int y = 0; y < i.height; y++) {
			for (int x = 0; x < i.width; x++) {
				RGBA col = void;
				uint vv[4];
				for (int n = -rad; n <= rad; n++) {
					auto factor = v_int[n + rad];
					//auto factor = v[n + 3];
					col = (pass == 0) ? i.get32(clamp(x + n, 0, i.width - 1), y) : i.get32(x, clamp(y + n, 0, i.height - 1));
					for (int c = 0; c < 4; c++) {
						vv[c] += factor * col.vv[c];
					}
				}
				//writefln(vv[0] / mult);
				for (int c = 0; c < 4; c++) col.vv[c] = vv[c] / mult;
				//writefln(i.get32(x, y));
				//writefln(col);
				i.set32(x, y, col);
			}
		}
	}
	return i;
}

void main() {
	void do_image(char[] name) {
		writef("%s...", name);
		Image i;
		foreach (ext; ["png", "tga"]) {
			char[] file_in = format("images/%s.%s", name, ext);
			if (std.file.exists(file_in)) {
				i = ImageFileFormatProvider.read(file_in);
				break;
			}
		}
		assert(i !is null, format("Can't load image '%s'.", name));
		ImageFileFormatProvider["img"].write(i, format("d:/shared/shuffle/Script/CVTD/%s", name));
		writefln("Ok");
	}

	//real x = -1.0, o = 0.84089642;
	//writefln(1 / sqrt(2 * PI * o) * pow(E, (-x * x) / (2 * o * o)));
	
	for (int n = 0; n <= 6; n++) do_image(format("SGMenu000%d00", n));
	for (int n = 0; n <= 9; n++) do_image(format("SGTitle000%d00", n));
	
	/*
	auto i = ImageFileFormatProvider.read("sgas13aa.tga");
	gaussian(i);
	writefln("writting.png");
	i.write("test.png");
	*/
}