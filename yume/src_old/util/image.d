module yume.image;

import std.stdio, std.string, std.stream, std.file, std.path;
import yume.util;

class Image {
	int width, height, bpp;
	ubyte[] data;
	uint[0x100] palette;
	Image mask;
	
	this(int width, int height, int bpp = 32) {
		this.width = width;
		this.height = height;
		this.bpp = bpp;
		data.length = width * height * bpp / 8;
	}
	
	~this() {
		delete data;
		data = null;
		delete mask;
		mask = null;
	}
	
	void setData(ubyte[] data) {
		this.data[0..data.length] = data;
	}

	align(1) struct TGA_HEADER {
		ubyte  identsize;          // size of ID field that follows 18 byte header (0 usually)
		ubyte  colourmaptype;      // type of colour map 0=none, 1=has palette
		ubyte  imagetype;          // type of image 0=none,1=indexed,2=rgb,3=grey,+8=rle packed

		ushort colourmapstart;     // first colour map entry in palette
		ushort colourmaplength;    // number of colours in palette
		ubyte  colourmapbits;      // number of bits per palette entry 15,16,24,32

		ushort xstart;             // image x origin
		ushort ystart;             // image y origin
		ushort width;              // image width in pixels
		ushort height;             // image height in pixels
		ubyte  bits;               // image bits per pixel 8,16,24,32
		ubyte  descriptor;         // image descriptor bits (vh flip bits) descriptor: 00vhaaaa * h horizontal flip * v vertical flip * a alpha bits
	}
	
	alias saveTGA save;
	
	void saveTGA(char[] name) {
		ubyte[] convert_8_32(ubyte[] data, uint[] palette) {
			uint[] r; r.length = data.length;
			for (int n = 0; n < data.length; n++) {
				uint col = palette[data[n]];
				col |= 0xFF000000;
				r[n] = col;
			}
			return cast(ubyte[])r;
		}
		
		ubyte[] convert_24_32(ubyte[] data, ubyte[] mask) {
			ubyte[] r; r.length = mask.length * 4; ubyte* dst = r.ptr, src = data.ptr, msk = mask.ptr; int count = mask.length;
			while (count--) {
				*(dst++) = *(src++);
				*(dst++) = *(src++);
				*(dst++) = *(src++);
				*(dst++) = *(msk++);
			}
			return r;
		}
		
		ubyte[] dataw = data;
		int bpp2 = bpp;
		
		if (bpp2 == 8) {
			dataw = convert_8_32(dataw, palette);
			bpp2 = 32;
		}
		
		if (bpp2 == 24 && mask) {
			dataw = convert_24_32(dataw, mask.data);
			bpp2 = 32;
		}
		
		TGA_HEADER tgah;
		
		tgah.identsize = 0;
		tgah.colourmaptype = 0;
		tgah.imagetype = 2;
		tgah.xstart = 0;
		tgah.ystart = 0;
		tgah.width  = width;
		tgah.height = height;
		tgah.bits   = bpp2;
		tgah.descriptor = 0b_00_1_0_0000;
		
		auto so = new File(name, FileMode.OutNew);
		{
			so.writeExact(&tgah, tgah.sizeof);
			so.write(dataw);
		}
		so.close();		
	}
	
	static ubyte[] unsizzle(ubyte[] srcv, int width, int height, int bpp) {
		ubyte[] dstv; dstv.length = srcv.length;
		int Bpp = bpp / 8;
		ubyte* src = srcv.ptr, dst = void, dste = dstv.ptr + dstv.length;
		for (int n = 0; n < Bpp; n++) for (dst = dstv.ptr + n; dst < dste; src++, dst += Bpp) *dst = *src;
		return dstv;
	}		
}

void decompressWIPMask(char[] name, char[] mask = null) {
	Image[] images = decompressWIP(name), masks;
	if (exists(mask)) foreach (n, cmask; decompressWIP(mask)) images[n].mask = cmask;
	foreach (n, image; images) {
		image.save(format("%s.%d.tga", name, n));
		delete image;
	}
	delete images;
}

Image[] decompressWIP(char[] name) {
	ushort count, bpp;
	Stream s = new BufferedFile(name);
	assert(s.readString(4) == "WIPF", "Not a WIPF image");
	s.read(count);
	s.read(bpp);
	
	struct IMAGE_INFO {
		uint width, height;
		uint x, y;
		uint unknown;
		uint compressed;
	}
	
	IMAGE_INFO[] iis;
	Image[] images;
	
	try {
		for (int n = 0; n < count; n++) {
			IMAGE_INFO ii; s.readExact(&ii, ii.sizeof);
			iis ~= ii;
			//writefln("  (%d, %d), (%d, %d) : %d, %d", ii.x, ii.y, ii.width, ii.height, bpp, count);
		}
		
		foreach (n, ii; iis) {
			if ((ii.width > 4096) || (ii.height > 4096)) {
				writefln("Invalid image size %d, %d", ii.width, ii.height);
				continue;
			}
			
			auto i = new Image(ii.width, ii.height, bpp);
			
			writefln("%d: %d", n, s.position);
			
			if (bpp == 8) {
				uint col;
				for (int m = 0; m < 0x100; m++) { s.read(col); i.palette[m] = col; }
			}
			
			ubyte[] data_c = new ubyte[ii.compressed];
			ubyte[] data_u = new ubyte[ii.width * ii.height * bpp / 8];
			s.read(data_c);
			Data.decompress(data_c, data_u);
			
			delete data_c; data_c = null;
			
			i.setData((bpp == 8) ? data_u : Image.unsizzle(data_u, ii.width, ii.height, bpp));
			
			delete data_u; data_u = null;
			
			images ~= i;
		}
	} catch (Exception e) {
		writefln("ERROR: %s", e.toString);
	}
	
	s.close();
	
	return images;
}
