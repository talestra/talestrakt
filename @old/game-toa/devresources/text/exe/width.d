//module tales.isopath;

import tales.scont.generic, tales.scont.iso;

import std.stdio, std.file, std.format, std.stream, std.path, std.string, std.ctype, std.c.stdlib;import std.stdio, std.file, std.format, std.stream, std.path, std.string, std.ctype, std.c.stdlib;

import tales.image.image, tales.image.tim2, tales.image.txd;

const int width_add_normal = 1;
const int width_space      = 8;

int main() {
	TIM2 t2 = new TIM2("../../images/_FONTB/_FONTB.TM2");
	int c = 0;
	char width_table[0x100];
	for (int n = 0; n < 3; n++) {
		Image i = t2.images[n];
		for (int y = 0; y < 10; y++) {
			for (int x = 0; x < 10; x++, c++) {
				if (c >= 0x100) break;
				int w = 0;
				for (int y2 = 0; y2 < 24; y2++) {
					for (int x2 = 0; x2 < 24; x2++) {
						if (i.getpixel(x * 24 + x2, y * 24 + y2) == 0) continue;
						if (x2 > w) w = x2;
					}
				}
				if (w > 0) w += width_add_normal;
				if (c == 0x20) w = width_space;
				width_table[c] = w;
			}
		}
	}
	
	for (int n = 0; n < 0x100; n += 4) {
		writefln("patch=0,EE,%08X,word,%08X", 0x005BB170 + n, *cast(uint *)&width_table[n]);
	}

	return 0;
}