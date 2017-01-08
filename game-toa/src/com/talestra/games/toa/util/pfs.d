import vfs, lzma;
import std.c.string;

version = pfs_memory_crypt;
version (gui) {
} else {
	version = pfs_patch_check_fs;
}

char[][] split2(char[] s, char[] sub, uint count = 0x7FFFFFFF) {
	char[][] r = split(s, sub);
	if (count < 1) count = 1;
	if (r.length > count) r = r[0..count - 1] ~ std.string.join(r[count - 1..r.length], sub);
	return r;
}

class PFS_Entry : FileContainer {
	uint pos;
	uint len;
	ubyte atr;
	PFS pfs;
	char[] path;
	
	private this() { }
	
	this(PFS pfs, char[] path, uint pos, uint len, ubyte atr) {
		this.pfs = pfs;
		this.path = path;
		this.pos = pos;
		this.len = len;
		this.atr = atr;
		int np = rfind(path, "/");
		this.name = path;
		if (np != -1) this.name = path[np + 1..path.length];
	}
	
	FileContainer[] _childs_cache;
	
	FileContainer[] _childs() {
		if (_childs_cache.length) return _childs_cache;
		
		FileContainer[] r;
		foreach (e; pfs.list) { char[] path_c = e.path;
			if (path.length > path_c.length) continue;
			if (path != path_c[0..path.length]) continue;
			//writefln(path, ":", path_c);
			if (path == path_c) continue;
			char[] rest = path_c[path.length + 1..path_c.length];
			//writefln(rest);
			if (find(rest, "/") != -1) continue;
			r ~= e;
		}
		return _childs_cache = r;
	}
	
	override bool exists(char[] name = "") {
		if (!name.length) return true;
		char[][] r = split2(name, "/", 2);
		FileContainer fc;
		foreach (e; _childs) if (e.name == r[0]) { fc = e; break; }
		if (fc is null) return false;
		if (r.length == 1) return true;
		return fc.exists(r[1]);
	}
	
	bool isFile() { return (atr == 0); }
	
	protected Stream realopen(FileMode mode = FileMode.In | FileMode.Out, bool limited = true) {
		return new SliceStreamNoClose(pfs.s, pos, pos + len);
	}
}

class PFS : PFS_Entry { // Patch File System
	Stream s;
	uint count;
	PFS_Entry[] list;
	
	this(ubyte[] data) {
		s = new MemoryStream(data);
		process();
		super();
	}
	
	this(Stream s) {
		this.s = s;
		process();
		super();
	}
	
	void process() {
		pfs = this;
		list = [];
		ubyte[] h; h.length = 9;
		s.position = 0; s.read(h);
		if (h != cast(ubyte[])"Tales Tra") throw(new Exception("Invalid PFS stream"));
		s.position = 0x25;
		s.read(count);
		for (int n = 0; n < count; n++) {
			char[] name; uint pos, len; ubyte a;
			s.read(pos);
			s.read(len);
			s.read(a);
			s.read(name);			
			list ~= new PFS_Entry(pfs, name, pos, len, a);
			//writefln(name);
		}
	}
}

FileContainer patch_fs;

ubyte[] patch_bin_lzma = cast(ubyte[])import("patch.bin.lzma.enc");
ubyte[] patch_bin;

ubyte[] lzma_decode_seed = [0xF3, 0x76, 0x39, 0x03, 0x32, 0x92, 0x11];
ubyte[] pfs_decode_seed  = [0x21, 0x39, 0xF7, 0xFF, 0x73, 0x12, 0x31, 0x8F, 0x31, 0x03, 0xE5, 0x88, 0x37];

class PFS_Decode : FilterStream {
	this(Stream source) { super(source); }
	
	override size_t readBlock(void* buffer, size_t size) {
		int sp = position;
		
		size_t res = super.readBlock(buffer, size);

		ubyte *ptr = cast(ubyte *)buffer;
		ubyte *stop = ptr + res;
		
		for (;ptr < stop; ptr++, sp++) *ptr = (*ptr + sp) ^ pfs_decode_seed[sp % pfs_decode_seed.length];

		return res;
	}
}

void decrypt_lzma_bin__crypt_patch_bin() {
	foreach (k, c; patch_bin_lzma) patch_bin_lzma[k] = cast(ubyte)(c + k) ^ lzma_decode_seed[k % lzma_decode_seed.length];
	patch_bin = lzma.decode(patch_bin_lzma); // Descomprimimos los datos LZMA
	memset(patch_bin_lzma.ptr, 0, patch_bin_lzma.length); // Borramos los datos originales
	version (pfs_memory_crypt) {
		foreach (k, c; patch_bin) patch_bin[k] = (c ^ pfs_decode_seed[k % pfs_decode_seed.length]) - k;
	}
}

class DirectorySVN : Directory {
	this(char[] path, char[] name = "") { super(path, name); }
	
	override bool childsFilterName(char[] n) {
		if (n == ".svn") return false;
		return true;
	}
	
	override Directory createDir(char[] path, char[] name = "") {
		return new DirectorySVN(path, name);
	}	
}

static this() {
	version (pfs_patch_check_fs) {
		if (exists("patch")) {
			patch_fs = new DirectorySVN("patch");
			//patch_fs = new Directory("patch");
			writefln("Usando directorio 'patch' para el parche.");
		}
	}
	
	if (!patch_fs) {
		decrypt_lzma_bin__crypt_patch_bin();
		version (pfs_memory_crypt) {
			patch_fs = new PFS(new PFS_Decode(new MemoryStream(patch_bin)));
		} else {
			patch_fs = new PFS(new MemoryStream(patch_bin));
		}
		writefln("Usando fichero intrínseco 'patch.bin' para parche.");
	}
}