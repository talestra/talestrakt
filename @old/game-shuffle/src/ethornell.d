// This program is realeased AS IT IS. Without any warranty and responsibility from the author.
import std.file, std.string, std.stdio, std.stream, std.c.stdio, std.c.string, std.intrinsic, std.c.stdlib;

// Version of the utility.
const char[] _version = "0.3";

// Utility macros.
static int max(int a, int b) { return (a > b) ? a : b; }
static int min(int a, int b) { return (a < b) ? a : b; }
static ushort HIWORD(uint   v) { return (v >> 16); }
static ushort LOWORD(uint   v) { return (v & 0xFFFF); }
static ubyte  HIBYTE(ushort v) { return (v >> 8); }
static ubyte  LOBYTE(ushort v) { return (v & 0xFFFF); }

// Utility functin for the decrypting.
static uint hash_update(ref uint hash_val) {
	uint eax, ebx, edx, esi, edi;
	edx = (20021 * LOWORD(hash_val));
	eax = (20021 * HIWORD(hash_val)) + (346 * hash_val) + HIWORD(edx);
	hash_val = (LOWORD(eax) << 16) + LOWORD(edx) + 1;
	return eax & 0x7FFF;
}

// Read a variable value from a pointer.
static uint readVariable(ref ubyte *ptr) {
	ubyte c; uint v;
	int shift = 0;
	do {
		c = *ptr++;
		v |= (c & 0x7F) << shift;
		shift += 7;
	} while (c & 0x80);
	return v;
}

// Class to have read access to ARC files.
class ARC {
	Stream s;
	Stream sd;
	Entry[] table;
	Entry*[char[]] table_lookup;
	
	// Entry for the header.
	struct Entry {
		ubyte[0x10] _name; // Stringz with the name of the file.
		uint start, len;   // Slice of the file.
		ARC arc;           // Use a slice of the unused area to save a reference to the ARC parent.
		ubyte[8 - arc.sizeof] __pad; // Unused area.

		// Obtaining the processed name as a char[].
		char[] name() { return cast(char[])_name[0..strlen(cast(char *)_name.ptr)]; }
		char[] toString() { return format("%-16s (%08X-%08X)", name, start, len); }

		// Open a read-only stream for the file.
		Stream open() { return arc.open(*this); }
		
		// Method to save this entry to a file.
		void save(char[] name = null) {
			if (name == null) name = this.name;
			scope s = new BufferedFile(name, FileMode.OutNew);
			s.copyFrom(open);
			s.close();
		}

		// Defines the explicit cast to Stream.
		Stream opCast() { return open; }
	}

	// Check the struct to have the expected size.
	static assert(Entry.sizeof == 0x20, "Invalid size for ARC.Entry");

	// Open a ARC using an stream.
	this(Stream s, char[] name = "unknwon") {
		this.s = s;

		// Check the magic.
		assert(s.readString(12) == "PackFile    ", format("It doesn't seems to be an ARC file ('%s')", name));

		// Read the size.
		uint table_length; s.read(table_length);
		
		// Read the table itself.
		table.length = table_length; s.readExact(table.ptr, table.length * table[0].sizeof);

		// Stre a SliceStream starting with the data part.
		sd = new SliceStream(s, s.position);

		// Iterates over all the entries, creating references to this class, and creating a lookup table.
		for (int n = 0; n < table.length; n++) {
			table_lookup[table[n].name] = &table[n];
			table[n].arc = this;
		}
	}

	// Open an ARC using a file name.
	this(char[] name) { this(new BufferedFile(name), name); }
	
	// Shortcut for instantiating the class.
	static ARC opCall(Stream s   ) { return new ARC(s   ); }
	static ARC opCall(char[] name) { return new ARC(name); }

	// Gets a read-only stream for a entry.
	Stream open(Entry e) { return new SliceStream(sd, e.start, e.start + e.len); }

	// Defines an iterator for this class.
	int opApply(int delegate(ref Entry) dg) {
		for (int i = 0, result = void; i < table.length; i++) if ((result = dg(table[i])) != 0) return result;
		return 0;
	}

	// Defines an array accessor to obtain an entry file.
	Entry opIndex(char[] name) {
		if ((name in table_lookup) is null) throw(new Exception(format("Unknown index '%s'", name)));
		return *table_lookup[name];
	}
}

// A color RGBA struct that defines methods to sum colors per component and to obtain average colors.
struct Color {
	union {
		struct { ubyte r, g, b, a; }
		ubyte[4] vv;
		uint v;
	}
	static Color opCall(uint v) { Color c = void; c.v = v; return c; }
	static Color opCall(ubyte r, ubyte g, ubyte b, ubyte a = 0) {
		Color c; c.r = r; c.g = g; c.b = b; c.a = a;
		return c;
	}
	static Color avg(Color[] v) {
		Color c;
		uint[4] vv;
		for (int n = 0; n < v.length; n++) for (int m = 0; m < 4; m++) vv[m] += v[n].vv[m];
		for (int m = 0; m < 4; m++) c.vv[m] = vv[m] / v.length;
		return c;
	}
	alias opCall fromRGBA;
	Color opAdd(Color a) {
		Color c = void;
		for (int n = 0; n < 4; n++) c.vv[n] = this.vv[n] + a.vv[n];
		return c;
	}
	Color opAddAssign(Color a) {
		for (int n = 0; n < 4; n++) this.vv[n] += a.vv[n];
		return *this;
	}
	uint opCast() { return v; }
	char[] toString() { return format("#%02X%02X%02X%02X", r, g, b, a); }
}
static assert(Color.sizeof  == 4, "Invalid size for Color");

// A simple class for writting TGA 32bit images.
class TGA {
	align(1) struct Header {
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
	static assert(Header.sizeof == 18, "Invalid size for TGA.Header");
	
	static void write32(Stream s, int w, int h, void[] data, int bpp = 32) {
		Header header;
		
		if (bpp != 32 && bpp != 24) throw(new Exception("Unsupported bpp"));

		// Defines the header.
		with (header) {
			idlength        = 0;
			x_origin        = 0;
			y_origin        = 0;
			width           = w;
			height          = h;
			colourmaporigin = 0;
			imagedescriptor = 0b_00_1_0_1000;

			colourmaptype   = 0;
			datatypecode    = 2;
			colourmaplength = 0;
			colourmapdepth  = 0;
			bitsperpixel    = bpp;
		}

		// Writes the header.
		s.writeExact(&header, header.sizeof);
		// Then writes the data.
		s.write(cast(ubyte[])data);
	}

	static void write32(char[] name, int w, int h, void[] data, int bpp = 32) {
		scope s = new BufferedFile(name, FileMode.OutNew);
		write32(s, w, h, data, bpp);
		s.close();
	}
}

// Class to uncompress "CompressedBG" files.
class CompressedBG {
	// Header for the CompressedBG.
	struct Header {
		char[0x10] magic;
		ushort w, h;
		uint bpp;
		uint[2] _pad0;
		uint data1_len;
		uint data0_val;
		uint data0_len;
		ubyte hash0, hash1;
		ubyte _unknown;
	}
	// Node for the Huffman decompression.
	struct Node {
		uint[6] vv;
		char[] toString() { return format("(%d, %d, %d, %d, %d, %d)", vv[0], vv[1], vv[2], vv[3], vv[4], vv[5]); }
	}
	
	static assert(Header.sizeof == 0x30, "Invalid size for CompressedBG.Header");
	static assert(Node.sizeof   == 24  , "Invalid size for CompressedBG.Node");
	
	Header header;
	ubyte[] data0;
	uint[0x100] table;
	Node[0x1FF] table2;
	ubyte[] data1;
	uint[] data;

	this(char[] name) { this(new BufferedFile(name)); }
	this(Stream s) {
		s.readExact(&header, header.sizeof);
		assert(header.magic == "CompressedBG___\0");
		data0 = cast(ubyte[])s.readString(header.data0_len);
		auto datahf = cast(ubyte[])s.readString(s.size - s.position);

		decode_chunk0(data0, header.data0_val);
		// Check the decoded chunk with a hash.
		assert(check_chunk0(data0, header.hash0, header.hash1));
	
		process_chunk0(data0, table, 0x100);
		int method2_res = method2(table, table2);
		data = new uint[header.w * header.h];
		auto data3 = new ubyte[header.w * header.h * 4];
		
		data1.length = header.data1_len;
		uncompress_huffman(datahf, data1, table2, method2_res);
		uncompress_rle(data1, data3);
		
		unpack_real(data, data3);
	}

	static void decode_chunk0(ubyte[] data, uint hash_val) {
		for (int n = 0; n < data.length; n++) data[n] -= hash_update(hash_val) & 0xFF;
	}
	
	static bool check_chunk0(ubyte[] data, ubyte hash_dl, ubyte hash_bl) {
		ubyte dl = 0, bl = 0;
		foreach (c; data) { dl += c; bl ^= c; }
		return (dl == hash_dl) && (bl == hash_bl);
	}

	static void process_chunk0(ubyte[] data0, uint[] table, int count = 0x100) {
		ubyte *ptr = data0.ptr;
		for (int n = 0; n < count; n++) table[n] = readVariable(ptr);
	}

	static int method2(uint[] table1, Node[] table2) {
		uint sum_of_values = 0;
		Node node;
		
		{ // Verified.
			for (uint n = 0; n < 0x100; n++) {
				with (table2[n]) {
					vv[0] = table1[n] > 0;
					vv[1] = table1[n];
					vv[2] = 0;
					vv[3] =-1;
					vv[4] = n;
					vv[5] = n;
				}
				sum_of_values += table1[n];
				//writefln(table2[n]);
			}
			//writefln(sum_of_values);
			if (sum_of_values == 0) return -1;
			assert(sum_of_values != 0);
		}

		{ // Verified.
			with (node) {
				vv[0] = 0;
				vv[1] = 0;
				vv[2] = 1;
				vv[3] =-1;
				vv[4] =-1;
				vv[5] =-1;
			}
			for (uint n = 0; n < 0x100 - 1; n++) table2[0x100 + n] = node;
			
			//std.file.write("table_out", cast(ubyte[])cast(void[])*(&table2[0..table2.length]));
		}

		uint cnodes = 0x100;
		uint vinfo[2];

		while (1) {
			for (uint m = 0; m < 2; m++) {
				vinfo[m] = -1;

				// Find the node with min_value.
				uint min_value = 0xFFFFFFFF;
				for (uint n = 0; n < cnodes; n++) {
					auto cnode = &table2[n];

					if (cnode.vv[0] && (cnode.vv[1] < min_value)) {
						vinfo[m] = n;
						min_value = cnode.vv[1];
					}
				}

				if (vinfo[m] != -1) {
					with (table2[vinfo[m]]) {
						vv[0] = 0;
						vv[3] = cnodes;
					}
				}
			}
			
			//assert(0 == 1);
			
			with (node) {
				vv[0] = 1;
				vv[1] = ((vinfo[1] != 0xFFFFFFFF) ? table2[vinfo[1]].vv[1] : 0) + table2[vinfo[0]].vv[1];
				vv[2] = 1;
				vv[3] =-1;
				vv[4] = vinfo[0];
				vv[5] = vinfo[1];
			}

			//writefln("node(%03x): ", cnodes, node);
			table2[cnodes++] = node;
			
			if (node.vv[1] == sum_of_values) break;
		}
		
		return cnodes - 1;
	}

	static void uncompress_huffman(ubyte[] src, ubyte[] dst, Node[] nodes, uint method2_res) {
		uint mask = 0x80;
		ubyte *psrc = src.ptr;
		int iter = 0;
		
		for (int n = 0; n < dst.length; n++) {
			uint cvalue = method2_res;

			if (nodes[method2_res].vv[2] == 1) {
				do {
					int bit = !!(*psrc & mask);
					mask >>= 1;

					cvalue = nodes[cvalue].vv[4 + bit];

					if (!mask) {
						psrc++;
						mask = 0x80;
					}
				} while (nodes[cvalue].vv[2] == 1);
			}

			dst[n] = cvalue;
		}
	}

	static void uncompress_rle(ubyte[] src, ref ubyte[] dst) {
		ubyte *psrc = src.ptr;
		ubyte *pdst = dst.ptr;
		ubyte *pslide = src.ptr;
		bool type = false;

		try {
			while (psrc < src.ptr + src.length) {
				uint len = readVariable(psrc);
				// RLE (for byte 00).
				if (type) {
					pdst[0..len] = 0;
				}
				// Copy from stream.
				else {
					pdst[0..len] = psrc[0..len];
					psrc += len;
				}
				pdst += len;
				type = !type;
			}
			dst.length = pdst - dst.ptr;
		} catch (Exception e) {
			throw(e);
		}
	}

	void unpack_real(uint[] output, ubyte[] data0) {
		switch (header.bpp) {
			case 24, 32: unpack_real_24_32(output, data0, header.bpp); break;
			//case 8: break; // Not implemented yet.
			default:
				assert(0, format("Unimplemented BPP %d", header.bpp));
			break;
		}
	}

	void unpack_real_24_32(uint[] output, ubyte[] data0, int bpp = 32) {
		auto out_ptr = output.ptr;
		Color c = Color(0, 0, 0, (bpp == 32) ? 0 : 0xFF);
		ubyte* src = data0.ptr;
		uint*  dst = output.ptr;
		
		Color extract_32() { scope (exit) src += 4; return Color(src[0], src[1], src[2], src[3]); }
		Color extract_24() { scope (exit) src += 3; return Color(src[0], src[1], src[2], 0); }
		
		auto extract = (bpp == 32) ? &extract_32 : &extract_24;
		Color extract_up() { return Color(*(dst - header.w)); }

		for (int x = 0; x < header.w; x++) {
			*dst++ = (c += extract()).v;
		}
		for (int y = 1; y < header.h; y++) {
			*dst++ = (c = (extract_up + extract())).v;
			for (int x = 1; x < header.w; x++) {
				*dst++ = (c = (Color.avg([c, extract_up]) + extract())).v;
			}
		}
	}

	void write_tga(char[] name) { TGA.write32(name, header.w, header.h, data); }
}

class DSC {
	// Header for DSC files.
	struct Header {
		char[0x10] magic;
		uint hash;
		uint usize;
		uint v2;
		uint _pad;

		void check() {
			assert(magic == "DSC FORMAT 1.00\0", format("Not a DSC file"));
			assert(usize <= 0x_3_000_000,      format("Too big uncompressed size '%d'", usize));
		}
	}

	// A node for the huffman tree.
	struct Node {
		union {
			struct {
				uint has_childs;
				uint leaf_value;
				union {
					struct { uint node_left, node_right; }
					uint childs[2];
				}
			}
			uint vv[4];
		}
		char[] toString() { return format("(childs:%08X, leaf:%08X, L:%08X, R:%08X)", (vv[0]), (vv[1]), (vv[2]), (vv[3])); }
	}

	// Check the sizes for the class structs.
	static assert (Header.sizeof == 0x20, "Invalid size for DSC.Header");
	static assert (Node.sizeof   == 4*4 , "Invalid size for DSC.Node");

	Header header;
	ubyte[] data;
	
	this(char[] name) { this(new BufferedFile(name)); }

	this(Stream s) {
		s.readExact(&header, header.sizeof);
		header.check();

		scope src = new ubyte[s.size - s.position]; s.read(src);
		Node[0x400] nodes;
		data = new ubyte[header.usize];

		// Decrypt and initialize the huffman tree.
		CompressionInit(header.hash, src, nodes);
		// Decompress the data using that tree.
		CompressionDo(src[0x200..src.length], data, nodes);
	}

	// Initializes the huffman tree.
	static void CompressionInit(uint hash, ubyte[] src, Node[] nodes)
		// Input asserts.
		in {
			assert(src.length >= 0x200);
		}
		// Output asserts.
		out {
		}
		body {{
			scope uint[0x200] buffer;
			scope uint[0x400] vector0;
			int buffer_len = 0;
			
			// Decrypt the huffman header.
			for (int n = 0; n < buffer.length; n++) {
				ubyte v = src[n] - cast(ubyte)hash_update(hash);
				//src[n] = v;
				if (v) buffer[buffer_len++] = (v << 16) + n;
			}
			//writefln(src[0x000..0x100]); writefln(src[0x100..0x200]);

			// Sort the used slice of the buffer.
			buffer[0..buffer_len].sort;
			
			uint toggle = 0, cnt0_a = 0, nn = 0, value_set = 1, dec0 = 1;
			vector0[0] = 0;
			uint* v13 = vector0.ptr;

			for (int buffer_cur = 0; buffer_cur < buffer_len - 1; nn++) {
				auto vector0_ptr = &vector0[toggle ^= 0x200];
				auto group_count = 0;
				auto vector0_ptr_init = vector0_ptr;
				
				for ( ;nn == HIWORD(buffer[buffer_cur]); buffer_cur++, v13++, group_count++ ) {
					nodes[*v13].has_childs = false;
					nodes[*v13].leaf_value = buffer[buffer_cur + 0] & 0x1FF;
				}
				
				auto v18 = 2 * (dec0 - group_count);
				if ( group_count < dec0 ) {
					dec0 = (dec0 - group_count);
					for (int dd = 0; dd < dec0; dd++) {
						nodes[*v13].has_childs = true;
						for (int m = 0; m < 2; m++) {
							*vector0_ptr++ = nodes[*v13].childs[m] = value_set;
							value_set++;
						}
						v13++;
					}
				}
				dec0 = v18;
				v13 = vector0_ptr_init;
			}
		}
	}

	static void CompressionDo(ubyte[] src, ubyte[] dst, Node[] nodes) {
		//uint v2 = header.v2;

		uint bits = 0, nbits = 0;
		auto src_ptr = src.ptr, dst_ptr = dst.ptr;
		auto src_end = src.ptr + src.length, dst_end = dst.ptr + dst.length;
		
		//writefln("--------------------");

		// Check the input and output pointers.
		while ((dst_ptr < dst_end) && (src_ptr < src_end)) {
			uint nentry = 0;

			// Look over the tree.
			for (; nodes[nentry].has_childs; nbits--, bits = (bits << 1) & 0xFF) {
				// No bits left. Let's extract 8 bits more.
				if (!nbits) {
					nbits = 8;
					bits = *src_ptr++;
				}
				//writef("%b", (bits >> 7) & 1);
				nentry = nodes[nentry].childs[(bits >> 7) & 1];
			}
			//writefln();

			// We are in a leaf.
			ushort info = LOWORD(nodes[nentry].leaf_value);

			// Compressed chunk.
			if (HIBYTE(info) == 1) {
				auto cvalue = bits >> (8 - nbits);
				auto nbits2 = nbits;
				if (nbits < 12) {
					auto bytes = ((11 - nbits) >> 3) + 1;
					nbits2 = nbits;
					while (bytes--) {
						cvalue = *src_ptr++ + (cvalue << 8);
						nbits2 += 8;
					}
				}
				nbits = nbits2 - 12;
				bits = LOBYTE(cvalue << (8 - (nbits2 - 12)));

				int offset = (cvalue >> (nbits2 - 12)) + 2;
				auto ring_ptr = dst_ptr - offset;
				uint count = LOBYTE(info) + 2;
				
				//writefln("LZ(%d, %d)", -offset, count);

				assert((ring_ptr >= dst.ptr) && (ring_ptr + count < dst_end), "Invalid reference pointer");
				//assert((dst_ptr + count > dst.ptr + dst.length), "Buffer overrun");

				// Copy byte to byte to avoid overlapping issues.
				while (count--) *dst_ptr++ = *ring_ptr++;
			}
			// Uncompressed byte.
			else {
				//writefln("BYTE(%02X)", LOBYTE(info));
				*dst_ptr++ = LOBYTE(info);
			}
		}
		try {
			//assert(dst_ptr == dst_end, "Not written all the bytes to the output buffer");
			assert(src_ptr == src_end, "Not readed all the bytes from the input buffer");
		} catch (Exception e) {
			writefln(e);
		}
	}

	// Allow storing the data in a stream.
	void save(char[] name) { std.file.write(name, data); }
}

class ShowHelpException : Exception { this(char[] t = "") { super(t); } static ShowHelpException opCall(char[] t = "") { return new ShowHelpException(t); } }

void find_variable_match(ubyte[] s, ubyte[] match, out int pos, out int len, int min_dist = 0) {
	pos = len = 0;
	if (match.length > s.length) match.length = s.length;
	if ((s.length > 0) && (match.length > 0)) {
		int iter_len = s.length - match.length - min_dist;
		for (int n = 0, m = 0; n < iter_len; n++) {
			for (m = 0; m < match.length; m++) {
				//writefln("%d, %d", n, m);
				if (match[m] != s[n + m]) break;
			}
			if (len < m) {
				len = m;
				pos = n;
			}
		}
		pos = iter_len - pos;
	}
}

char[] varbits(ulong v, uint bits) {
	if (bits == 0) return "";
	return format(format("%%0%db", bits), v);
}

struct BitWritter {
	ubyte[] data;
	uint cval; int av_bits = 8;
	static int mask(int bits) { return (1 << bits) - 1; }
	static ubyte reverse(ubyte b) { return ((b * 0x0802LU & 0x22110LU) | (b * 0x8020LU & 0x88440LU)) * 0x10101LU >> 16; }
	version (safebit) {
		void putbit(bool bit) {
			cval |= (bit << --av_bits);
			if (av_bits == 0) finish();
		}
		void write(ulong ins_val, int ins_bits) {
			for (int n = 0; n < ins_bits; n++) {
				bool bit = cast(bool)((ins_val >> (ins_bits - n - 1)) & 1);
				putbit(bit);
			}
		}
	} else {
		void write(ulong ins_val, int ins_bits) {
			//writefln("%s", varbits(ins_val, ins_bits));
			int ins_bits0 = ins_bits;

			while (ins_bits > 0) {
				int bits = min(ins_bits, av_bits);

				uint extract = (ins_val >> (ins_bits0 - bits)) & mask(bits);
				//writefln("  %s", varbits(extract, bits));
				
				cval |= extract << (av_bits - bits);

				ins_val  <<= bits;
				ins_bits -= bits;
				av_bits  -= bits;
				if (av_bits <= 0) finish();
			}
		}
	}
	void finish() {
		if (av_bits == 8) return;
		//writefln("  byte: %08b", cval);
		data   ~= (cval);
		av_bits = 8;
		cval = 0;
		//exit(0);
	}
}

class MNode {
	union {
		struct { int value, freq;  }
		long freq_value;
	}
	int level;
	uint encode;
	MNode parent;
	MNode childs[2];
	int opCmp(Object o) { MNode that = cast(MNode)o;
		//return this.freq_value - that.freq_value;
		int r = this.freq - that.freq;
		if (r == 0) return this.value - that.value;
		return r;
	}
	this(int value, int freq, int level = 0) {
		this.value = value;
		this.freq  = freq;
		this.level = level;
	}
	char[] toString() { return format("(%08X, %08X, %08X, %010b, [%d, %d])", value, freq, level, encode, childs[0] !is null, childs[1] !is null); }
	static void show(MNode[] nodes) {
		foreach (node; nodes) writefln(node);
	}
	bool leaf() { return (childs[0] is null) && (childs[1] is null); }
	static int findWithoutParent(MNode[] nodes, int start = 0) {
		foreach (pos, node; nodes[start..nodes.length]) if (node.parent is null) return start + pos;
		return -1;
	}
	void propagateLevels(int level = 0, uint encode = 0) {
		this.level  = level;
		this.encode = encode;
		foreach (k, node; childs) if (node !is null) node.propagateLevels(level + 1, (encode << 1) | k);
		//foreach (k, node; childs) if (node !is null) node.propagateLevels(level + 1, encode | (k << level));
	}
}

MNode[] extract_levels(uint[] freqs, ubyte[] levels) {
	assert(freqs.length == levels.length);

	MNode[] cnodes;

	foreach (value, freq; freqs) if (freq > 0) cnodes ~= new MNode(value, freq);
	while (1) {
		cnodes = cnodes.sort;
		int node1 = MNode.findWithoutParent(cnodes, 0);
		if (node1 == -1) break; // No nodes left without parent.
		int node2 = MNode.findWithoutParent(cnodes, node1 + 1);
		if (node2 == -1) break; // No nodes left without parent.
		auto node_l = cnodes[node1];
		auto node_r = cnodes[node2];
		auto node_p = new MNode(-1, node_l.freq + node_r.freq, 1);
		node_p.childs[0] = node_r;
		node_p.childs[1] = node_l;
		node_r.parent = node_l.parent = node_p;
		cnodes ~= node_p;
	}
	cnodes[cnodes.length - 1].propagateLevels();
	//MNode.show(cnodes);

	for (int n = 0; n < levels.length; n++) levels[n] = 0;
	foreach (node; cnodes) if (node.leaf) levels[node.value] = node.level;
	
	auto lnodes = new MNode[freqs.length];
	foreach (node; cnodes) if (node.leaf) lnodes[node.value] = node;
	
	assert(lnodes.length == freqs.length);
	
	return lnodes;
}

ubyte[] compress(ubyte[] data, int level = 0) {
	const min_lz_len = 2;
	const max_lz_len = 0x100 + 2;
	const max_lz_pos = 0x1000;
	const min_lz_pos = 2;
	int   max_lz_len2 = max_lz_len;
	int   max_lz_pos2 = max_lz_len;
	
	struct Encode {
		ubyte  bits;
		ushort value;
	}
	Encode encode[0x200];
	
	uint freq[0x200];
	ubyte levels[0x200];
	struct Block {
		short value;
		short pos;
	}
	Block[] blocks;
	
	max_lz_len2 = (max_lz_len * level) / 9;
	max_lz_pos2 = (max_lz_pos * level) / 9;
	
	for (int n = 0; n < data.length;) {
		int pos = 0, len = 0;
		int max_len = min(max_lz_len2, data.length - n);
		if (level > 0) {
			find_variable_match(data[max(0, n - max_lz_pos2)..n + max_len], data[n..n + max_len], pos, len, min_lz_pos);
		}

		// Compress.
		int id = 0;
		if (len >= min_lz_len) {
			int encoded_len = len - min_lz_len;
			blocks ~= Block(id = 0x100 | (encoded_len & 0xFF), pos);
			n += len;
		} else {
			blocks ~= Block(id = 0x000 | (data[n] & 0xFF), 0);
			n++;
		}
		freq[id]++;
	}
	struct RNode {
		ulong v;
		ubyte bits;
		
		static void iterate(RNode[] rnodes, DSC.Node[] nodes, int cnode = 0, int level = 0, ulong val = 0) {
			if (nodes[cnode].has_childs) {
				foreach (k, ccnode; nodes[cnode].childs) iterate(rnodes, nodes, ccnode, level + 1,
					//val | (k << level)
					(val << 1) | k
				);
			} else {
				with (rnodes[nodes[cnode].leaf_value & 0x1FF]) {
					v    = val;
					bits = level;
				}
			}
		}
		
		char[] toString() { return bits ? format(format("%%0%db", bits), v) : ""; }
	}
	RNode[0x200] rnodes;
	DSC.Node[0x400] cnodes;
	extract_levels(freq, levels);
	//auto nodes = extract_levels(freq, levels);
	ubyte[] r;
	
	uint hash_val = 0x000505D3 + rand(), init_hash_val = hash_val;
	
	void ins_int(uint v) {
		r.length = r.length + 4;
		*cast(uint *)(r.ptr + r.length - 4) = v;
	}
	
	r ~= cast(ubyte[])"DSC FORMAT 1.00\0";
	ins_int(hash_val);
	ins_int(data.length);
	ins_int(blocks.length);
	ins_int(0);
	
	foreach (clevel; levels) r ~= clevel + (hash_update(hash_val) & 0xFF);
	DSC.CompressionInit(init_hash_val, r[r.length - 0x200..r.length], cnodes);
	RNode.iterate(rnodes, cnodes);
	
	//writefln("rnodes:"); foreach (k, rnode; rnodes) if (rnode.bits > 0) writefln("  %03X:%s", k, rnode);
	
	// Write bits.
	BitWritter bitw;
	foreach (block; blocks) {
		auto rnode = rnodes[block.value];
		if (block.value & 0x100) {
			//writefln("BLOCK:LZ(%d, %d)", -(block.pos - 2), (block.value & 0xFF) + 2);
		} else {
			//writefln("BLOCK:BYTE(%02X)", block.value & 0xFF);
		}
		bitw.write(rnode.v, rnode.bits);
		if (block.value & 0x100) {
			bitw.write(block.pos, 12);
			//bitw.finish();
		}
	}
	bitw.finish();
	r ~= bitw.data;
	
	return r;
	//writefln(nodes[0]);
	//writefln(levels);
}

int main(char[][] args) {
	// Shows the help for the usage of the program.
	void show_help() {
		writefln("Ethornell utility %s - soywiz - 2009 - Build %s", _version, __TIMESTAMP__);
		writefln("Knows to work with English Shuffle! with Ethornell 1.69.140");
		writefln();
		writefln("ethornell <command> <parameters>");
		writefln();
		writefln("  -l       List the contents of an arc pack");
		writefln("  -x[0-9]  Extracts the contents of an arc pack (uncompressing when l>0)");
		writefln("  -p[0-9]  Packs and compress a folder");
		writefln();
		writefln("  -d       Decompress a single file");
		writefln("  -c[0-9]  Compress a single file");
		writefln("  -t[0-9]  Test the compression");
		writefln();
		writefln("  -h       Show this help");
	}

	// Throws an exception if there are less parameters than the required.
	void expect_params(int count) {
		if (args.length < (count + 2)) throw(new ShowHelpException(format("Expected '%d' params and '%d' received", count, args.length - 2)));
	}
	
	try {
		if (args.length < 2) throw(new ShowHelpException);

		char[][] params = [];
		if (args.length > 2) params = args[2..args.length];
		
		struct ImageHeader {
			short width, height;
			int bpp;
			int zpad[2];
		}

		bool check_image(ImageHeader i) {
			return (
				((i.bpp % 8) == 0) && (i.bpp > 0) && (i.bpp <= 32) && 
				(i.width > 0) && (i.height > 0) &&
				(i.width < 8096) && (i.height < 8096) &&
				(i.zpad[0] == 0) && (i.zpad[1] == 0)
			);
		}
		
		void write_image(ImageHeader ih, char[] out_file, void[] data) {
			if (ih.bpp != 32 && ih.bpp != 24) throw(new Exception("Unknown bpp"));
			//scope f = new BufferedFile(out_file, FileMode.OutNew);
			TGA.write32(out_file, ih.width, ih.height, data, ih.bpp);
			//f.close();
		}
		
		switch (args[1][0..2]) {
			// List.
			case "-l": {
				expect_params(1);
				auto arc_name = params[0];

				// Check if the arc actually exists.
				assert(std.file.exists(arc_name), format("File '%s' doesn't exists", arc_name));

				// Writes a header with the arc file that we are processing.
				writefln("----------------------------------------------------------------");
				writefln("ARC: %s", arc_name);
				writefln("----------------------------------------------------------------");
				// Iterate over the ARC file and write the files.
				foreach (e; ARC(arc_name)) printf("%s\n", std.string.toStringz(e.name));
			} break;
			// Extact + uncompress.
			case "-x":
				int level = 9;
				if (args[1].length == 3) level = args[1][2] - '0';
				expect_params(1);
				auto arc_name = params[0];

				// Check if the arc actually exists.
				assert(std.file.exists(arc_name), format("File '%s' doesn't exists", arc_name));

				// Determine the output path and create the folder if it doesn't exists already.
				auto out_path = arc_name ~ ".d";
				try { mkdir(out_path); } catch {}

				// Iterate over the arc file.
				foreach (e; ARC(arc_name)) {
					if (params.length >= 2) {
						bool found = false;
						foreach (filter; params[1..params.length]) {
							if (filter == e.name) { found = true; break; }
						}
						if (!found) continue; 
					}
					scope s = e.open;
					printf("%s...", std.string.toStringz(e.name));
					char[] out_file;
					if (params.length >= 2) {
						out_file = e.name;
					} else {
						out_file = out_path ~ "/" ~ e.name;
					}
					
					try {
						// Check the first 0x10 bytes to determine the magic of the file.
						switch ((new SliceStream(s, 0)).readString(0x10)) {
							// Encrypted+Static Huffman+LZ
							case "DSC FORMAT 1.00\0": {
								writef("DSC...");
								if (std.file.exists(out_file)) throw(new Exception("Exists"));
								ubyte[] data;
								if (level == 0) {
									data = cast(ubyte[])s.readString(s.size);
								} else {
									scope dsc = new DSC(s);
									data = dsc.data;
								}
								ImageHeader ih;
								ih = *cast(ImageHeader *)data;
								if (check_image(ih)) {
									writef("Image...BPP(%d)...", ih.bpp);
									out_file ~= ".tga";
									if (std.file.exists(out_file)) throw(new Exception("Exists"));
									write_image(ih, out_file, data[0x10..data.length]);
								} else {
									std.file.write(out_file, data);
								}
							} break;
							// Encrypted+Dynamic Huffman+RLE+LZ+Unpacking+Row processing
							case "CompressedBG___\0": {
								out_file ~= ".tga";
								writef("CBG...");
								if (std.file.exists(out_file)) throw(new Exception("Exists"));
								scope cbg = new CompressedBG(s);
								cbg.write_tga(out_file);
							} break;
							// Uncompressed/Unknown.
							default: {
								auto ss = new SliceStream(s, 6);
								short width, height; uint bpp;
								ImageHeader ih;
								ss.readExact(&ih, ih.sizeof);
								if (check_image(ih)) {
									writef("Image...BPP(%d)...", ih.bpp);
									out_file ~= ".tga";
									if (std.file.exists(out_file)) throw(new Exception("Exists"));
									s.position = 0x10;
									write_image(ih, out_file, s.readString(s.size - s.position));
								} else {
									writef("Uncompressed...");
									if (std.file.exists(out_file)) throw(new Exception("Exists"));
									scope f = new BufferedFile(out_file, FileMode.OutNew);
									f.copyFrom(s);
									f.close();
								}
							} break;
						}
						writefln("Ok");
					}
					// There was an error, write it.
					catch (Exception e) {
						writefln(e);
					}
				}
			break;
			// Packs and compress a file.
			case "-p": {
				int level = 9;
				if (args[1].length == 3) level = args[1][2] - '0';

				expect_params(1);
				auto folder_in = params[0];
				auto arc_out   = folder_in[0..folder_in.length - 2];
				
				// Check if the file actually exists.
				assert(std.file.exists(folder_in), format("Folder '%s' doesn't exists", folder_in));
				assert(folder_in[folder_in.length - 6..folder_in.length] == ".arc.d", format("Folder '%s', should finish by .arc.d", folder_in));
				int count = listdir(folder_in).length;
				scope s = new BufferedFile(arc_out, FileMode.OutNew);
				s.writeString("PackFile    ");
				s.write(cast(uint)count);
				int pos = 0;

				foreach (k, file_name; listdir(folder_in)) {
					writef("%s...", file_name);
					scope data = cast(ubyte[])std.file.read(folder_in ~ "/" ~ file_name);
					scope ubyte[] cdata;
					// Already compressed.
					if (data[0..0x10] == cast(ubyte[])"DSC FORMAT 1.00\0") {
						cdata = data;
						writefln("Already compressed");
					}
					// Not compressed.
					else {
						cdata = compress(data, level);
						writefln("Compressed");
					}
					s.position = 0x10 + count * 0x20 + pos;
					s.write(cdata);
					s.position = 0x10 + k * 0x20;
					s.writeString(file_name);
					while (s.position % 0x10) s.write(cast(ubyte)0);
					s.write(cast(uint)pos);
					s.write(cast(uint)cdata.length);
					s.write(cast(uint)0);
					s.write(cast(uint)0);
					pos += cdata.length;
				}
				s.close();
			} break;
			// Decompress a single file.
			case "-d":
				expect_params(1);
				auto file_name = params[0];
				auto out_file = file_name ~ ".u";

				// Check if the file actually exists.
				assert(std.file.exists(file_name), format("File '%s' doesn't exists", file_name));

				scope dsc = new DSC(file_name);
				dsc.save(out_file);
			break;
			// Compress a single file.
			case "-c":
				int level = 9;
				if (args[1].length == 3) level = args[1][2] - '0';
				expect_params(1);
				auto file_name = params[0];
				auto out_file = file_name ~ ".c";

				// Check if the file actually exists.
				assert(std.file.exists(file_name), format("File '%s' doesn't exists", file_name));

				std.file.write(out_file, compress(cast(ubyte[])std.file.read(file_name), level));
			break;
			// Test the compression.
			case "-t": {
				int level = 9;
				if (args[1].length == 3) level = args[1][2] - '0';
				expect_params(1);
				auto file_name = params[0];

				// Check if the file actually exists.
				assert(std.file.exists(file_name), format("File '%s' doesn't exists", file_name));

				auto uncompressed0 = cast(ubyte[])std.file.read(file_name);
				auto compressed    = compress(uncompressed0, level);
				scope dsc = new DSC(new MemoryStream(compressed));
				auto uncompressed1 = dsc.data;
				
				assert(uncompressed0 == uncompressed1, "Failed");
				writefln("Ok");
			} break;
			// Help command.
			case "-h":
				throw(ShowHelpException());
			break;
			// Unknown command.
			default:
				throw(ShowHelpException(format("Unknown command '%s'", args[1])));
			break;
		}

		return 0;
	}
	// Catch a exception to show the help/usage.
	catch (ShowHelpException e) {
		show_help();
		if (e.toString.length) writefln(e);
		return 0;
	}
	// Catch a generic unhandled exception.
	catch (Exception e) {
		writefln("Error: %s", e);
		return -1;
	}
}
