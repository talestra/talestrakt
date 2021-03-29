module tales.image.txd;

import tales.image.image;
import std.stream, std.file, std.string, std.stdio, std.string, std.math, std.c.stdlib;
import tales.common;

const uint CSYNC = 0x1C02002D;

class TXD {
	ushort count;

	private void expectSync(Stream s) {
		uint sync;
		s.read(sync);
		if (sync != CSYNC) throw(new Exception("Sync error"));
	}

	/*Image loadrealimage(Stream s) {
		//(new File("dump.dat", FileMode.OutNew)).copyFrom(s);

		uint ImageType, width, height;
		ushort c;
		s.read(ImageType);
		if (ImageType != 0x03) throw(new Exception("ImageType not implemented"));
		s.position = 0x20; s.read(width); s.read(height);

		Image i = new Image(width, height, 4);

		writefln("SIZE(%d, %d)", width, height);

		s.position = 0x50;

		for (int y = 0; y < height; y++) {
			for (int x = 0; x < width; x++) {
				s.read(c);
				i.putpixel(x, y, c);
			}
		}

		i.savetga("fin.tga");

		exit(-1);

		return i;
	}*/

	int ipos = 0;


	Image loadrealimage(Stream s) {
		//(new File("dump.dat", FileMode.OutNew)).copyFrom(s);

		uint ImageType, width, height;
		//uint c;
		ushort c;
		s.read(ImageType);
		if (ImageType != 0x03) throw(new Exception("ImageType not implemented"));
		s.position = 0x20; s.read(width); s.read(height);

		Image i = new Image(width, height, 2);

		writefln("SIZE(%d, %d) : %d", width, height, s.available);

		s.position = 0x50;

		try {
			for (int y = 0; y < height; y++) {
				for (int x = 0; x < width; x++) {
					s.read(c);
					writef("%04X,", c);
					i.putpixel(x, y, c);
					//i.putpixel(x * 2, y, (c >> 4) & 0xF);
					//i.putpixel(x * 2 + 1, y, (c) & 0xF);
					//i.putpixel(x * 2, y, (c >> 4) & 0xF);
					//i.putpixel(x * 2 + 1, y, (c) & 0xF);
				}
			}
			writefln();
		} catch (Exception e) {
			writefln(e.toString);
		}

		i.savetga(std.string.format("%04X.tga", ipos++));

		//exit(-1);

		return i;
	}

	void loadimage(Stream s) {
		uint state = 0;

		while (!s.eof) {
			Stream cs;
			uint cpos, packet, len;
			s.read(packet);
			s.read(len);
			expectSync(s);

			writefln("PACKET(IM): %02X [%08X]", packet, len);

			cpos = s.position; s.position = cpos + len;
			cs = new SliceStream(s, cpos, cpos + len);

			switch (packet) {
				default: throw(new Exception(std.string.format("Invalid TXD packet '%02X'", packet)));
				case 0x01: {
					switch (state) {
						case 0: {
							uint width, height;
							cs.read(width);
							cs.read(height);
							writefln("IMAGE (%d, %d)", width, height);
							state = 1;
						} break;
						case 1:
							writefln("loadrealimage(%d, %d) : %d", cpos, len, cs.available);
							loadrealimage(cs);
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
			s.read(packet);
			s.read(len);
			expectSync(s);

			writefln("PACKET(15): %02X [%08X]", packet, len);

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
					ubyte[] line;
					line.length = len;
					cs.read(line);
					if (!line[0]) break;
					writefln("************************* '%s'", cast(char[])line);
				} break;
				case 0x03: writefln("-------------------------"); break;
			}
		}
	}

	void load16(Stream s) {
		while (!s.eof) {
			Stream cs;
			uint cpos, packet, len;
			s.read(packet);
			s.read(len);
			expectSync(s);

			writefln("PACKET(16): %02X [%08X]", packet, len);

			cpos = s.position; s.position = cpos + len;
			cs = new SliceStream(s, cpos, cpos + len);

			switch (packet) {
				default: throw(new Exception(std.string.format("Invalid TXD packet '%02X'", packet)));
				case 0x15: // Image stream
					load15(cs);
				break;
				case 0x01: {
					ushort count, dummy;
					cs.read(count);
					cs.read(dummy);
					this.count = count;
				} break;
				case 0x03: writefln("-------------------------"); break;
			}
		}
	}

	void load(Stream s) {
		while (!s.eof) {
			Stream cs;
			uint cpos, packet, len;
			s.read(packet);
			s.read(len);
			expectSync(s);

			writefln("PACKET(00): %02X [%08X]", packet, len);

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