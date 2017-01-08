import std.stdio;
import std.stream;
import std.string;
import std.file;
import std.math;

class Image {
	ubyte[] data;
	uint[] palette;
	Image mask;
	int width, height, bpp;
	
	this(int width, int height, int bpp) {
		this.width = width;
		this.height = height;
		this.bpp = bpp;
		data.length = width * height * (bpp / 8);
	}
	
	void setData(ubyte[] data) {
		//writefln(this.data.length);
		//writefln(data.length);
		this.data[0..std.math.min(data.length, this.data.length)] = data;
	}
	
	void setPalette(ubyte[] data) {
		this.palette.length = 0x100;
		this.palette[0..0x100] = cast(uint[])data[0..0x400];
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
	
	void save(char[] name) {
		ubyte[] convert_8_32(ubyte[] data, uint[] palette) {
			uint[] r; r.length = data.length;
			for (int n = 0; n < data.length; n++) r[n] = palette[data[n]];
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
}

ubyte[] lz_decompress(ubyte[] bin) {
	struct LZ_HEAD {
		char[4] magic; // '  ZL'
		uint lout;
		uint lin;
	} LZ_HEAD* h = cast(LZ_HEAD*)bin.ptr;
	
	assert(h.magic == "  ZL", "Not LZ data");
	assert(bin.length >= h.lin + 0x10);
	
	ubyte[] bout = new ubyte[h.lout - 2];
	
	ubyte* i = bin.ptr + 0x10, ie = bin.ptr + 0x10 + h.lin, o = bout.ptr, oe = bout.ptr + bout.length;
	
	try {
		while (i < ie) {
			uint fields = cast(uint)(*(i++)) | (1 << 8);
			for (; !(fields & (1 << 16)); fields <<= 1) {
				if (i >= ie) break;
				//if (o >= oe) return;
				// Uncompressed
				if (fields & 0x80) {
					*(o++) = *(i++);
					//writefln("  %02X", *(o - 1));
				}
				// Compressed
				else {
					ushort z = *(cast(ushort *)i);
					uint lz_len = ((z >> 0) & 0x00F) + 2;
					uint lz_off = ((z >> 4) & 0xFFF) + 1;
					//writefln("%08X", o - bout.ptr);
					//writefln("%d, %d", lz_off, lz_len);
					while (lz_len--) *(o++) = *(o - lz_off);
					i += 2;
				}
			}
		}
	} catch (Exception e) {
		writefln("ERROR: %s at (%d, %d)", e.toString, i - (bin.ptr + 0x10), o - bout.ptr);
	}
	
	//writefln("end");
	
	//write("lol.dat", bout);
	
	return bout;
}

Image gpd_extract(ubyte[] data) {
	struct GPD_HEAD {
		char[4] magic; // ' DPG'
		int _ver;
		int unk1;
		int width;
		int height;
		int bpp;
	} GPD_HEAD* h = cast(GPD_HEAD*)(data.ptr);

	assert(h.magic == " DPG", "Not GPD data");
	
	auto i = new Image(h.width, h.height, h.bpp);
	i.setPalette(data[0x40..0x440]);
	i.setData(lz_decompress(data[0x40 + (h.bpp == 8) * 0x400..data.length]));
	delete data;
	return i;
}

void gpd_save(char[] fin, char[] fout) {
	auto i = gpd_extract(cast(ubyte[])read(fin));
	i.save(fout);
	delete i.data; i.data = null;
	delete i;
}

void gpd_save(char[] fin) {
	gpd_save(fin, fin ~ ".tga");
}

bool mkdir2(char[] name) { try { mkdir(name); return true; } catch { return false; } }

void fcap_extract(char[] pname) {
	struct CAPF_HEAD {
		char[4] magic; // 'CAPF'
		int _ver;
		int start;
		int count;
	} CAPF_HEAD h;
	Stream s = new BufferedFile(pname ~ ".pac");
	s.readExact(&h, h.sizeof);
	s.position = 0x20;
	
	char[] path;
	mkdir2("extract/");
	mkdir2(path = "extract/" ~ pname);
	
	for (int n = 0; n < h.count; n++) {
		uint pos, len;
		s.read(pos); s.read(len);
		char[] fname = split(s.readString(0x20), "\0")[0];
		char[] ffname = path ~ "/" ~ fname;
		writefln("%s...", fname);
		if (std.file.exists(ffname)) continue;
		auto zs = new SliceStream(s, pos, pos + len);
		ubyte[] data = new ubyte[len];
		zs.read(data);
		write(ffname, data);
		delete zs;
		delete data;
	}
	s.close();
}

void fcap_extract_all() {
	fcap_extract("bg");
	fcap_extract("bgm");
	fcap_extract("graphic");
	fcap_extract("script");
	fcap_extract("se");
	fcap_extract("sg");
	fcap_extract("system");
	fcap_extract("visual");
	fcap_extract("voice");
}

void gpd_save_folder(char[] path) {
	foreach (file; listdir(path)) {
		if (file.length >= 4 && file[file.length - 4..file.length] != ".GPD") continue;
		char[] ffile = path ~ "/" ~ file;
		printf("%s...", std.file.toStringz(file));
		if (std.file.exists(ffile ~ ".tga")) { writefln("Exists"); continue; }
		gpd_save(ffile);
		writefln("Ok");
	}
}

ubyte[] scr_extract(ubyte[] data) {
	return lz_decompress(data[0x80..data.length]);
}

void scr_extract_all(char[] path) {
	//char[] path;
	foreach (file; listdir(path)) {
		char[] ffile = path ~ "/" ~ file;
		if (file.length >= 4 && file[file.length - 4..file.length] != ".BIN") continue;
		writefln("%s", ffile);
		write(ffile ~ ".u",  scr_extract(cast(ubyte[])read(ffile)));
	}
}

void main() {
	//fcap_extract_all();
	
	//gpd_save_folder("extract/bg");
	//gpd_save_folder("extract/graphic");
	//gpd_save_folder("extract/sg");
	//gpd_save_folder("extract/visual");
	//gpd_save_folder("extract/system");
	
	scr_extract_all("script");
	//scr_extract_all("extract/script");
}