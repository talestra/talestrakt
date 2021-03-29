module tales.image.image;

import tales.common;
import std.stream, std.file, std.string, std.stdio, std.string, std.math;

version = pal32;

struct Color {
	ubyte r;
	ubyte g;
	ubyte b;
	ubyte a;
}

class Palette {
	Color rgba[0x100];
	int ncol;
}

class Image {
	ushort width, height;
	ubyte bpp;
	ubyte[] data;

	Palette *pal;
	Palette[] palettes;
	uint cpal;

	int ncol() { return pal ? pal.ncol : 0; }
	int ncol(int n) { if (!pal) return 0; return pal.ncol = n; }

	void setpal(int n) {
		if (n < 0 || n >= palettes.length) return;
		pal = &palettes[n];
	}

	void setcol(int n, Color c) {
		if (!pal || n < 0 || n >= 0x100) return;
		if (n >= pal.ncol) pal.ncol = n + 1;
		pal.rgba[n] = c;
	}

	void setcol(int n, ubyte r, ubyte g, ubyte b, ubyte a = 0xFF) {
		Color c; c.r = r; c.g = g; c.b = b; c.a = a; setcol(n, c);
	}

	Color getcol(int n) {
		Color c;
		if (pal && n >= 0 && n < pal.ncol) c = pal.rgba[n];
		return c;
	}

	this(ushort width, ushort height, ubyte bpp = 4) {
		this.width = width;
		this.height = height;
		this.bpp = bpp;
		data.length = width * height * bpp;
		if (bpp == 1) {
			palettes ~= new Palette;
			setpal(0);
		}
	}

	void putpixel(int x, int y, uint c) {
		if (x < 0 || y < 0 || x >= width || y >= height) return;

		switch (bpp) {
			case 1: *((cast(ubyte  *)data.ptr) + (y * width + x)) = c; break;
			case 2: *((cast(ushort *)data.ptr) + (y * width + x)) = c; break;
			case 4: *((cast(uint   *)data.ptr) + (y * width + x)) = c; break;
			default: throw(new Exception("Error"));
		}
	}

	uint getpixel(int x, int y) {
		if (x < 0 || y < 0 || x >= width || y >= height) return 0;

		switch (bpp) {
			case 1: return *((cast(ubyte  *)data.ptr) + (y * width + x)); break;
			case 2: return *((cast(ushort *)data.ptr) + (y * width + x)); break;
			case 4: return *((cast(uint   *)data.ptr) + (y * width + x)); break;
			default: throw(new Exception("Error"));
		}
	}

	void putbox(int x1, int y1, int x2, int y2, uint c) {
		for (int x = x1; x <= x2; x++) {
			putpixel(x, y1, c);
			putpixel(x, y2, c);
		}

		for (int y = y1 + 1; y < y2; y++) {
			putpixel(x1, y, c);
			putpixel(x2, y, c);
		}
	}

	void putfillbox(int x1, int y1, int x2, int y2, uint c) {
		for (int y = y1; y <= y2; y++) {
			for (int x = x1; x <= x2; x++) {
				putpixel(x, y, c);
			}
		}
	}

	private void swap(inout int a, inout int b) {
		int t = b; b = a; a = t;
	}

	void putline(int x1, int y1, int x2, int y2, uint c) {
		int dx = x2 - x1, dy = y2 - y1;
		if (abs(dx) >= abs(dy)) {
			if (x1 > x2) {
				swap(x1, x2);
				swap(y1, y2);
			}

			for (int x = x1, n = 0; x < x2; x++, n++) putpixel(x, y1 + (dy * n) / dx, c);
		} else {
			if (y1 > y2) {
				swap(x1, x2);
				swap(y1, y2);
			}

			for (int y = y1, n = 0; y < y2; y++, n++) putpixel(x1 + (dx * n) / dy, y, c);
		}
	}

	private ushort swap(ushort a) {
		return (a >> 8) | ((a & 0xFF) << 8);
	}

	void savetga(Stream tga, bool pal32 = true) {
		switch (bpp) {
			case 1:
				tga.write(cast(ubyte)0); // Number of Characters in Identification Field.
				tga.write(cast(ubyte)1); // Color Map Type.
				tga.write(cast(ubyte)1); // Image Type Code.

				// Color Map Specification.
				tga.write(cast(ushort)0); // Color Map Origin.
				tga.write(cast(ushort)ncol); // Color Map Length.
				tga.write(cast(ubyte)(pal32 ? 32 : 24));  // Color Map Entry Size.

				tga.write(cast(ushort)0); // X Origin of Image.
				tga.write(cast(ushort)0); // Y Origin of Image.

				tga.write(cast(ushort)width);  // Width of Image.
				tga.write(cast(ushort)height); // Height of Image.

				tga.write(cast(ubyte)8); // Image Pixel Size.
				tga.write(cast(ubyte)32); // Image Descriptor Byte.

				// Identification Field.
				// void

				// Color map data.
				for (int n = 0; n < ncol; n++) {
					tga.write(pal.rgba[n].b);
					tga.write(pal.rgba[n].g);
					tga.write(pal.rgba[n].r);
					if (pal32) tga.write(pal.rgba[n].a);
				}

				tga.write(data); // Image Data Field.
			break;
			case 2:
				tga.write(cast(ubyte)0); // Number of Characters in Identification Field.
				tga.write(cast(ubyte)0); // Color Map Type.
				tga.write(cast(ubyte)2); // Image Type Code.

				// Color Map Specification.
				tga.write(cast(ushort)0); // Color Map Origin.
				tga.write(cast(ushort)0); // Color Map Length.
				tga.write(cast(ubyte)0);  // Color Map Entry Size.

				tga.write(cast(ushort)0); // X Origin of Image.
				tga.write(cast(ushort)0); // Y Origin of Image.

				tga.write(cast(ushort)width);  // Width of Image.
				tga.write(cast(ushort)height); // Height of Image.

				tga.write(cast(ubyte)32); // Image Pixel Size.
				tga.write(cast(ubyte)32); // Image Descriptor Byte.
/*
|        |        |  Bits 3-0 - number of attribute bits associated with each  |
|        |        |             pixel.                                         |
|        |        |  Bit 4    - reserved.  Must be set to 0.                   |
|        |        |  Bit 5    - screen origin bit.                             |
|        |        |             0 = Origin in lower left-hand corner.          |
|        |        |             1 = Origin in upper left-hand corner.          |
|        |        |             Must be 0 for Truevision images.               |
|        |        |  Bits 7-6 - Data storage interleaving flag.                |
|        |        |             00 = non-interleaved.                          |
|        |        |             01 = two-way (even/odd) interleaving.          |
|        |        |             10 = four way interleaving.                    |
|        |        |             11 = reserved.                                 |
|        |        |  This entire byte should be set to 0.  Don't ask me.       |
*/
				// Identification Field.
				// void

				// Color map data.
				// void

				for (int y = 0; y < height; y++) {
					for (int x = 0; x < width; x++) {
						const int r5 = ((1 << 5) - 1);
						ushort c16 = *((cast(ushort *)data.ptr) + (y * width + x));
						uint   c32 = 0;
						c32 |= ((((c16 >>  0) & r5) << 3) <<  0);
						c32 |= ((((c16 >>  5) & r5) << 3) <<  8);
						c32 |= ((((c16 >> 10) & r5) << 3) << 16);
						c32 |= 0xFF << 24;
						tga.write(c32);
					}
				}
				//tga.write(data); // Image Data Field.
			break;
			case 4:
				tga.write(cast(ubyte)0); // Number of Characters in Identification Field.
				tga.write(cast(ubyte)0); // Color Map Type.
				tga.write(cast(ubyte)2); // Image Type Code.

				// Color Map Specification.
				tga.write(cast(ushort)0); // Color Map Origin.
				tga.write(cast(ushort)0); // Color Map Length.
				tga.write(cast(ubyte)0);  // Color Map Entry Size.

				tga.write(cast(ushort)0); // X Origin of Image.
				tga.write(cast(ushort)0); // Y Origin of Image.

				tga.write(cast(ushort)width);  // Width of Image.
				tga.write(cast(ushort)height); // Height of Image.

				tga.write(cast(ubyte)32); // Image Pixel Size.
				tga.write(cast(ubyte)32); // Image Descriptor Byte.
/*
|        |        |  Bits 3-0 - number of attribute bits associated with each  |
|        |        |             pixel.                                         |
|        |        |  Bit 4    - reserved.  Must be set to 0.                   |
|        |        |  Bit 5    - screen origin bit.                             |
|        |        |             0 = Origin in lower left-hand corner.          |
|        |        |             1 = Origin in upper left-hand corner.          |
|        |        |             Must be 0 for Truevision images.               |
|        |        |  Bits 7-6 - Data storage interleaving flag.                |
|        |        |             00 = non-interleaved.                          |
|        |        |             01 = two-way (even/odd) interleaving.          |
|        |        |             10 = four way interleaving.                    |
|        |        |             11 = reserved.                                 |
|        |        |  This entire byte should be set to 0.  Don't ask me.       |
*/
				// Identification Field.
				// void

				// Color map data.
				// void

				tga.write(data); // Image Data Field.
			break;
		}
	}

	void savetga(char[] tga) {
		File f = new File(tga, FileMode.OutNew);
		savetga(f);
		f.close();
	}
}