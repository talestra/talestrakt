import std.stdio, std.c.stdlib, std.string, std.c.string, std.file;

align(1) struct Entry {
	ushort  unknown1;
	ushort  etype;
	ushort  unknown2;
	ushort  ptype;
	uint    width;
	uint    height;
	uint    ncolor;
	uint    clut;
	uint    data;
	uint    unknown4;
	short[] cbuffer;
	char[]  dbuffer;
	uint    rwidth;
	uint    rheight;
}

void ShowEntry(Entry e) {
	printf("Entry:\n");
	printf("UNK1:   %04X\n", e.unknown1);
	printf("TYPE:   %04X\n", e.etype);
	printf("PTYPE:  %04X\n", e.ptype);
	printf("UNK2:   %04X\n", e.unknown2);
	printf("WIDTH:  %08X [%08X]\n", e.width, e.rwidth);
	printf("HEIGHT: %08X [%08X]\n", e.height, e.rheight);
	printf("NCOL:   %08X\n", e.ncolor);
	printf("CLUT:   %08X\n", e.clut);
	printf("DATA:   %08X\n", e.data);
	printf("UNK3:   %08X\n", e.unknown4);
	printf("CLUTL:  %08X\n", e.cbuffer.length);
	printf("DATAL:  %08X\n", e.dbuffer.length);
	printf("\n");
}

align(1) struct TGAHeader {
   char  idlength;
   char  colourmaptype;
   char  datatypecode;
   short colourmaporigin;
   short colourmaplength;
   char  colourmapdepth;
   short x_origin;
   short y_origin;
   short width;
   short height;
   char  bitsperpixel;
   char  imagedescriptor;
}

align(1) struct RGB {
	char b;
	char g;
	char r;
	char a;
}

int abs(int a) { return (a >= 0) ? a : -a; }

int compare(RGB a, RGB b) {
	return (
		abs(cast(int)a.r - cast(int)b.r) +
		abs(cast(int)a.g - cast(int)b.g) +
		abs(cast(int)a.b - cast(int)b.b)
	) / 3;
}

int closest(in RGB[] palette, RGB c) {
	int mv = 256, mi = 0;
	for (int i = 0; i < palette.length; i++) {
		int cv = compare(palette[i], c);
		if (cv < mv) { mv = cv; mi = i; }
	}
	return mi;
}

RGB unpack15BitsColor(ushort color) {
	RGB r;

	r.r = ((color >>  0) & ((1 << 5) - 1)) << 3;
	r.g = ((color >>  5) & ((1 << 5) - 1)) << 3;
	r.b = ((color >> 10) & ((1 << 5) - 1)) << 3;

	return r;
}

ushort pack15BitsColor(RGB color) {
	return (
		((cast(int)color.r >> 3) <<  0) |
		((cast(int)color.g >> 3) <<  5) |
		((cast(int)color.b >> 3) << 10) |
		((cast(int)color.a >> 7) << 15) |
	0);
}

void TGA_Save(char[] name, RGB[] palette, char[][] image) { TGA_SaveIndex(toStringz(name), palette, image); }
void TGA_SaveIndex(char *name, RGB[] palette, char[][] image) {
	int width = image[0].length, height = image.length;

	TGAHeader tgah;

	FILE *f = fopen(name, "wb");

	tgah.idlength = 0;
	tgah.colourmaptype = 0;
	tgah.datatypecode = 2; // uncompressed RGB
	tgah.colourmaporigin = 0;
	tgah.colourmaplength = 0;
	tgah.colourmapdepth = 0;
	tgah.y_origin = tgah.x_origin = 0;
	tgah.width = width;
	tgah.height = height;
	tgah.bitsperpixel = 24;
	tgah.imagedescriptor = 0;

	fwrite(&tgah, tgah.sizeof, 1, f);

	for (int y = height; y >= 0; y--) {
		for (int x = 0; x < width; x++) {
			fwrite(&palette[image[y][x]], 3, 1, f);
		}
	}

	fclose(f);
}

void TGA_Save(char[] name, RGB[][] image) { TGA_Save(toStringz(name), image); }
void TGA_Save(char *name, RGB[][] image) {
	int width = image[0].length, height = image.length;

	TGAHeader tgah;

	FILE *f = fopen(name, "wb");

	tgah.idlength = 0;
	tgah.colourmaptype = 0;
	tgah.datatypecode = 2; // uncompressed RGB
	tgah.colourmaporigin = 0;
	tgah.colourmaplength = 0;
	tgah.colourmapdepth = 0;
	tgah.y_origin = tgah.x_origin = 0;
	tgah.width = width;
	tgah.height = height;
	tgah.bitsperpixel = 24;
	tgah.imagedescriptor = 0;

	fwrite(&tgah, tgah.sizeof, 1, f);

	for (int y = height; y >= 0; y--) {
		if (y >= image.length) continue;
		for (int x = 0; x < width; x++) {
			if (x >= image[y].length) continue;
			fwrite(&image[y][x], 3, 1, f);
		}
	}

	fclose(f);
}

RGB[][] TGA_Load(char[] name) { return TGA_Load(toStringz(name)); }
RGB[][] TGA_Load(char *name) {
	RGB[][] image;
	TGAHeader tgah;
	int bsp;

	FILE *f = fopen(name, "rb");

	fread(&tgah, tgah.sizeof, 1, f);

	if (tgah.bitsperpixel < 24) {
		fclose(f);
		throw(new Exception("No se soporta " ~ toString(tgah.bitsperpixel) ~ "bps"));
	}

	image.length = tgah.height; for (int y = 0; y < tgah.height; y++) image[y].length = tgah.width;

	bsp = tgah.bitsperpixel >> 3;

	//printf("%d, %d\n", tgah.width, tgah.height);

	for (int y = tgah.height - 1; y >= 0; y--) {
		if (y >= image.length) continue;
		for (int x = 0; x < tgah.width; x++) {
			if (x >= image[y].length) continue;
			RGB c; fread(&c, bsp, 1, f);
			//printf("%d, %d\n", x, y);
			image[y][x] = c;
		}
	}

	fclose(f);

	return image;
}
