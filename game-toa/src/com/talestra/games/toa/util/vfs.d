module vfs;

public import std.file, std.string, std.stdio, std.path, std.stream;

template TA(T) { ubyte[] TA(inout T t) { return (cast(ubyte *)&t)[0..T.sizeof]; } }

class PatchedMemoryStream : MemoryStream {
	override ulong seek(long offset, SeekPos rel) {
		assertSeekable();
		long scur; // signed to saturate to 0 properly

		switch (rel) {
			case SeekPos.Set: scur = offset; break;
			case SeekPos.Current: scur = cast(long)(cur + offset); break;
			case SeekPos.End: scur = cast(long)(len + offset); break;
			default: assert(0);
		}

		if (scur < 0) cur = 0;
		//else if (scur > len) cur = len; // Comportamiento inesperado
		else cur = cast(ulong)scur;

		return cur;
	}
	
	this() { }
	this(ubyte[] data) { super(data); }
	
	~this() {
		if (buf) delete buf;
	}
	
	override void close() {
		if (buf) delete buf;
	}
}

class SliceStreamNoClose : SliceStream {
	this(Stream s, ulong pos, ulong len) { super(s, pos, len); }
	this(Stream s, ulong pos) { super(s, pos); }

	override void close() { /*Stream.close();*/ }
}

void copy2From(Stream to, Stream from, bool restore = true) {
	ubyte[] buf;
	try {
		buf.length = 0x400000;
		long bpos;
		
		if (restore) {
			bpos = from.position;
			from.position = 0;
		}
		
		while (!from.eof) {
			size_t m = from.readBlock(buf.ptr, buf.length);
			to.writeExact(buf.ptr, m);
		}
		
		if (restore) from.position = bpos;
	} finally {
		delete buf;
		buf = null;
	}
}


class FileContainer {
	FileContainer parent;
	FileContainer[] childs;
	char[] name;
	Stream stream;
	Stream rs;
	FileContainer proxy;
	
	FileContainer[] _childs() { return childs; }
	char[] type() { return "FileContainer"; }
	void print() { writefln("%s('%s')", this, name); }
	
	static FileContainer getProxyChild(FileContainer fc) {
		//if (fc && fc.proxy) return getProxyChild(fc.proxy);
		return fc;
	}
	
	bool opened() {
		return stream && stream.isOpen;
	}
	
	long size() {
		long size;
		Stream s;
		if (opened) {
			s = stream;
			size = s.size;
		} else {
			s = open;
			size = s.size;
			s.close();
		}
		return size;
	}
	
	void mount(char[] name, FileContainer ce) {
		childs ~= new MountContainer(name, ce);
	}

	void saveto(Stream s) {
		Stream cs = this.open;
		copy2From(s, cs);
		s.flush();
		//this.close();
	}
	
	void saveto(FileContainer fc) {
		saveto(fc.open(FileMode.OutNew));
		fc.close();
	}

	void copyFrom(Stream s) { Stream cs = this.open(FileMode.OutNew); copy2From(cs, s); cs.flush(); this.close(); cs.close(); }
	void copyFrom(FileContainer fc) { copyFrom(fc.open); }
	
	ubyte[] saveData() {
		return (cast(PatchedMemoryStream)save).buf;
	}
	
	Stream save() {
		Stream ms = new PatchedMemoryStream();
		saveto(ms);
		ms.position = 0;
		return ms;
	}	

	ubyte[] read() {
		ubyte[] ret;
		MemoryStream s = new PatchedMemoryStream();
		saveto(s);
		ret.length = s.data.length;
		ret[0..ret.length] = s.data[0..ret.length];
		delete s;
		return ret;
	}

	public void saveto(char[] s) {
		scope File f = new File(s, FileMode.OutNew);
		saveto(f);
		f.close();
	}

	void list(char[] base = "") {
		print();
		foreach (child; _childs) {
			if (!child.name) continue;
			writefln("'%s%s'", base, child.name);
			if (child.childs.length) child.list(format("%s/", child.name));
		}
	}

	void add(FileContainer ce) {
		childs ~= ce;
		ce.parent = this;
	}

	FileContainer opIndex(char[] name) {
		char[] name_base = name, name_child;
		int pos;
		if ((pos = std.string.find(name, '/')) != -1) {
			name_base = name[0..pos];
			name_child = name[pos + 1..name.length];
		}
		
		if (name_base == ".") return this[name_child];
		if (name_base == "..") return getProxyChild(parent ? parent[name_child] : this[name_child]);
		
		return getChild(name_base, name_child);
	}
	
	// TODO
	FileContainer resolve(char[] path, bool create = false) {
		return null;
	}
	
	FileContainer getChildNotFound(char[] name_base, char[] name_child = "", bool create = true) {
		throw(new Exception(format("File '%s' doesn't exists in '%s'", name_base, name)));
		return null;
	}
	
	FileContainer getChild(char[] name_base, char[] name_child = "") {
		foreach (child; _childs) {
			if (std.string.icmp(child.name, name_base) == 0) {
				if (name_child.length) return cast(FileContainer)getProxyChild(child[name_child]);
				return cast(FileContainer)child;
			}
		}

		return getProxyChild(name_child.length ? getChildNotFound(name_base, name_child, true)[name_child] : getChildNotFound(name_base, name_child, true));
	}

    int opApply(int delegate(inout FileContainer) dg) {
    	int result = 0;
		foreach (c; _childs) {c = getProxyChild(c); if ((result = dg(c)) != 0) break; }
		return result;
    }

	// Reemplazamos un stream
	int replace(Stream from, bool limited = true) {
		//writefln("FileContainer.replace(%08X);", cast(uint)cast(uint *)this);
		Stream op = this.open();
		//writefln("%d", op.writeable);
		ulong start = op.position;
		
		copy2From(op, from);
		
		return op.position - start;
	}
	
	int replace(ubyte[] from, bool limited = true) {
		MemoryStream from_s = new MemoryStream(from);
		try {
			return replace(from_s, limited);
		} finally {
			delete from_s.buf;
			delete from_s;
		}
	}
	
	int replaceAt(Stream from, int skip = 0) {
		//writefln("FileContainer.replace(%08X);", cast(uint)cast(uint *)this);
		Stream op = this.open();
		//writefln("%d", op.writeable);
		ulong start = op.position;
		op.position = start + skip;
		copy2From(op, from);
		return op.position - start;
	}

	// Reemplazamos por un fichero
	void replace(char[] from, bool limited = true) {
		File f = new File(from, FileMode.In);
		replace(f, limited);
		f.close();
	}
	
	void replace(FileContainer f, bool limited = true) {
		Stream s = f.open;
		replace(s, limited);
		f.close();
	}
	
	// Reemplazamos por un fichero
	void replaceAt(char[] from, int skip = 0) {
		File f = new File(from, FileMode.In);
		replaceAt(f, skip);
		f.close();
	}	

	bool isFile() { return false; }
	
	void setData(void[] data) {
		setStream(new PatchedMemoryStream(cast(ubyte[])data));
	}

	void setStream(Stream s) {
		//close();
		rs = s;
		s.position = 0;
	}

	Stream open(FileMode mode = FileMode.In | FileMode.Out) {
		if (rs && rs.isOpen) return rs;

		//writefln("FileContainer.open(%08X);", cast(uint)cast(uint *)this);
		if (opened) {
			//writefln("opened");
			stream.position = 0;
			return stream;
		}
		//writefln("realopen");
		return stream = realopen(mode);
	}
	
	bool exists(char[] name = "") {
		if (!name.length) return true;
		foreach (child; _childs) {
			if (child.name == name) return true;
		}
		return false;
	}

	void close() {
		//writefln("FileContainer.close(%08X);", cast(uint)cast(uint *)this);
		if (stream && stream.isOpen) {
			//writefln("closd");
			stream.close();
		}
	}

	protected Stream realopen(FileMode mode = FileMode.In | FileMode.Out, bool limited = true) {
		throw(new Exception("realopen: Not Implemented (" ~ toString ~ ")"));
	}
	
	void invalidate() {
	}
	
	void regen(FileContainer fc, int delegate(char[], int, int, long, long, bool) callback = null) {
	}
	
	void makePPF(Stream to, long offset) {
	}
}

class MountContainer : FileContainer {
	this(char[] name, FileContainer proxy) {
		this.name = name;
		this.proxy = proxy;
	}

	FileContainer proxy;

	override FileContainer[] _childs() {
		return proxy._childs;
	}
	
	override FileContainer getChildNotFound(char[] name_base, char[] name_child = "", bool create = true) {
		return proxy.getChildNotFound(name_base, name_child, create);
	}

	protected Stream realopen(FileMode mode, bool limited = true) {
		writefln("realopen");
		return proxy.realopen(mode, limited);
	}

	override bool exists(char[] name = "") {
		return proxy.exists(name);
	}

	void regen(FileContainer fc, int delegate(char[], int, int, long, long, bool) callback = null) {
		proxy.regen(fc, callback);
	}
	
	override void makePPF(Stream to, long offset) {
		proxy.makePPF(to, offset);
	}
}

class Directory : FileContainer {
	char[] path;
	
	bool isFile() { return std.file.isfile(path) != 0; }

	override FileContainer getChildNotFound(char[] name_base, char[] name_child = "", bool create = true) {
		if (name_child.length) try { mkdir(path ~ "/" ~ name_base); } catch { }
		return new Directory(path ~ "/" ~ name_base, name_base);
	}
	
	override bool exists(char[] name = "") {
		if (name.length) name = "/" ~ name;
		//writefln("exists(%s):%d", path ~ name, std.file.exists(path ~ name));
		return std.file.exists(path ~ name) != 0;
	}
	
	FileContainer[] cacheChilds;
	bool cached = false;
	
	bool childsFilterName(char[] n) {
		return true;
	}
	
	Directory createDir(char[] path, char[] name = "") {
		return new Directory(path, name);
	}
	
	FileContainer[] _childs() {
		FileContainer[] r;
		
		if (!cached) {
			//writefln("!cached: %s", path);
			cached = true;
			cacheChilds = [];
			foreach (n; listdir(path)) {
				if (childsFilterName(n)) {
					cacheChilds ~= createDir(path ~ "/" ~ n, n);
					//writefln("Directory.process(%s): %s/'%s' (%s)", this.classinfo.name, path, n, cacheChilds[cacheChilds.length - 1].classinfo.name);
				} else {
					//writefln("Directory.ignore (%s): %s/'%s'", this.classinfo.name, path, n);
				}
			}
			/*
			listdir(path, delegate bool(char[] n) {
				if (childsFilterName(n)) cacheChilds ~= new Directory(path ~ "/" ~ n, n);
				return true;
			});
			*/
		}
		
		foreach (child; cacheChilds) r ~= child;
		foreach (child; childs) r ~= child;
		
		return r;
	}

	this(char[] path, char[] name = "") {
		if (!name.length) name = getBaseName(path);
		this.path = path;
		this.name = name;
	}
	
	protected Stream realopen(FileMode mode, bool limited = true) {
		return new File(path, mode);
	}

	override void invalidate() {
		cached = false;
	}
}