import std.stdio, std.stream, std.string, std.file, std.string, std.math, std.md5;

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
}

class TXD {
	const uint CSYNC = 0x1C02002D;
	ushort count;

	private void expectSync(Stream s) {
		uint sync;
		s.read(sync);
		if (sync != CSYNC) throw(new Exception("Sync error"));
	}

	int ipos = 0;
	
	void processPacket(Stream s, out uint packet, out uint len) {
		s.read(packet);
		s.read(len);
		expectSync(s);
		//writefln("packet: %02X : %04X", packet, len);
	}
	
	struct IMG {
		int pos;
		char[] name;
		ubyte[] data;
	}
	
	IMG[ubyte[]] images;
	int imgCount;
	
	ubyte[] readStream(Stream s) {
		long back = s.position;
		s.position = 0;
		ubyte[] data; data.length = s.size;
		s.read(data);
		s.position = back;
		return data;
	}
	
	Stream ntex;
	
	void prepareNTEX() {
		if (!ntex) {
			ntex = new File("ntex.txd", FileMode.OutNew);
			ntex.write(cast(ubyte[])x"160000002C0B04002D00021C01000000040000002D00021C24000600");
		}
	}
	
	void loadrealimage(Stream s, int rwidth, int rheight) {
		ubyte[16] digest;
		ubyte[] data; data.length = s.size;
		uint ImageType;
		uint width, height;
		uint blocksize;

		s.read(ImageType);
		s.position = 0x20; 
		s.read(width);
		s.read(height);
		s.position = 0x40; 
		s.read(blocksize);
		
		uint endpos = blocksize * 16 + 0x50;
		
		s.position = 0;
		s.read(data);
		std.md5.sum(digest, data); 

		//writefln("%s: %s", digestToString(digest), lastName);
		if (digest in images) {
			//writefln("rep: %s", images[digest].name);
			return;
		}
		IMG img;
		img.name = lastName;
		img.data = readStream(lastImageStream);
		img.pos = images.length;
		images[digest] = img;
		
		int bpp = (rwidth * rheight) / (width * height);

		/*
		if (blocksize * 16 == rwidth * rheight * 4) {
			//writefln("%d: 32!", img.pos);
		}
		*/
		
		/*if (endpos == data.length) {
			writefln("%d, %d: %dx%d : %d", endpos, data.length, width, height, width * height * 4);
		}
		if (data.length >= width * height * 4) {
			//writefln("%d > %d", data.length, width * height * 4);
		}*/
		
		if (rwidth == width && rheight == height) {
			//writefln("32BIT: %d", img.pos);
		}

		if (img.pos < 10) {
			//writefln(bpp);
		}
		
		if (img.pos == 91) {
			//writefln("%d: %dx%d : %d", ImageType, width, height, data.length);
			//writefln(bpp);
			write(std.string.format("i/%03d", img.pos), data);
		}
		
		/*if (img.pos == 90) {
			writefln("%d: %dx%d : %d", ImageType, width, height, data.length);
			write("s90", data);
		}

		if (img.pos == 0) {
			writefln("%d: %dx%d : %d", ImageType, width, height, data.length);
			write("s00", data);
		}

		if (img.pos == 1) {
			writefln("%d: %dx%d : %d", ImageType, width, height, data.length);
			write("s01", data);
		}*/
		
		if (img.data[0x2C..0x2C + 4] != cast(ubyte[])"cht_") {
			throw(new Exception("WAHT?!"));
		}

		if (ImageType != 3) writefln("%d", ImageType);

		img.data[0x2C..0x2C + 7] = cast(ubyte[])std.string.format("cht%04d", img.pos);
		prepareNTEX();
		
		if (rwidth == width && rheight == height) return;
		
		ntex.write(img.data);
		imgCount++;
	}
	
	void finish() {
		prepareNTEX();
		int size = ntex.position - 8;
		ntex.position = 0x04;
		ntex.write(size);
		ntex.position = 0x18;
		ntex.write(cast(ushort)imgCount);
	}
	
	char[] lastName;
	Stream lastImageStream;

	void loadimage(Stream s) {
		uint state = 0;

		uint width, height;

		while (!s.eof) {
			Stream cs;
			uint cpos, packet, len;
			processPacket(s, packet, len);

			//writefln("PACKET(IM): %02X [%08X]", packet, len);

			cpos = s.position; s.position = cpos + len;
			cs = new SliceStream(s, cpos, cpos + len);

			switch (packet) {
				default: throw(new Exception(std.string.format("Invalid TXD packet '%02X'", packet)));
				case 0x01: {
					switch (state) {
						case 0: {
							cs.read(width);
							cs.read(height);
							//writefln("IMAGE (%d, %d)", width, height);
							state = 1;
						} break;
						case 1:
							//writefln("loadrealimage(%d, %d) : %d", cpos, len, cs.available);
							loadrealimage(cs, width, height);
							//writefln("IMAGE");
						break;
					}
				} break;
			}
		}
	}

	void load15(Stream s) {
		uint state = 0;

		while (!s.eof) {
			Stream cs;
			uint cpos, packet, len;
			
			processPacket(s, packet, len);

			//writefln("PACKET(15): %02X [%08X]", packet, len);

			cpos = s.position; s.position = cpos + len;
			cs = new SliceStream(s, cpos, cpos + len);

			switch (packet) {
				default: throw(new Exception(std.string.format("Invalid TXD packet '%02X'", packet)));
				case 0x01: {
					switch (state) {
						case 0:
							uint magic;
							cs.read(magic);
							if (magic != 0x00325350) throw(new Exception("Not a PS2 Image"));
							state = 1;
						break;
						case 1:
							loadimage(cs);
						break;
					}
				} break;
				case 0x02: {
					char[] line = cs.readString(len);
					if (!line[0]) break;
					//writefln("%s", cast(char[])line);
					lastName = line;
					//writefln("************************* '%s'", cast(char[])line);
				} break;
				case 0x03:
					//writefln("-------------------------");
				break;
			}
		}
	}

	void load16(Stream s) {
		while (!s.eof) {
			Stream cs;
			uint cpos, packet, len;
			
			processPacket(s, packet, len);

			//writefln("PACKET(16): %02X [%08X]", packet, len);

			cpos = s.position; s.position = cpos + len;
			cs = new SliceStream(s, cpos, cpos + len);

			switch (packet) {
				default: throw(new Exception(std.string.format("Invalid TXD packet '%02X'", packet)));
				case 0x15: // Image stream
					lastImageStream = new SliceStream(s, cpos - 12, cpos + len);
					load15(cs);
				break;
				case 0x01: {
					ushort count, dummy;
					cs.read(count);
					cs.read(dummy);
					this.count = count;
				} break;
				case 0x03:
					//writefln("-------------------------");
				break;
			}
		}
	}

	void load(Stream s) {
		while (!s.eof) {
			Stream cs;
			uint cpos, packet, len;
			
			processPacket(s, packet, len);

			//writefln("PACKET(00): %02X [%08X]", packet, len);

			cpos = s.position; s.position = cpos + len;
			cs = new SliceStream(s, cpos, cpos + len);

			switch (packet) {
				default: throw(new Exception(std.string.format("Invalid TXD packet '%02X'", packet)));
				case 0x16: // TXD stream
					load16(cs);
				break;
			}
		}
	}
	
	void load(char[] f) {
		File s = new File(f, FileMode.In);
		load(s);
		s.close();
	}

	this(Stream s) {
		load(s);
	}

	this(char[] f) {
		load(f);
	}
	
	this() {
	}
}

void main() {
	auto txd = new TXD;
	for (int n = 0; n < 538; n++) {
		//writefln("%03d", n);
		try {
			txd.load(std.string.format("texs/skit%03d.txd", n));
		} catch (Exception e) {
			writefln("error: %s", e);
		}
		//break;
	}
	txd.finish();
	/*
	for (int n = 0; n < 538; n++) {
		uint pos, len;
		//writefln("%03d", n);
		ubyte[] type; type.length = 7;
		if (std.file.exists(std.string.format("texs/skit%03d.txd", n))) continue;
		auto s = new File(std.string.format("skits/CHT_%03d.SKT.u", n));
		s.position = 0x6C;
		s.read(pos);
		s.read(len);
		s.read(type);
		if (type != cast(ubyte[])"cht.txd") {
			writefln("ERROR: (%03d) %s", n, type);
			continue;
			//throw(new Exception("Error"));
		}
		s.position = pos;
		ubyte[] data; data.length = len;
		s.read(data);
		write(std.string.format("texs/skit%03d.txd", n), data);
	}
	*/
}