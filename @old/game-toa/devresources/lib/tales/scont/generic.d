module tales.scont.generic;

public import tales.common;

private import std.file, std.string, std.stdio, std.path, std.regexp, std.stream;

/*
template TSerialize(T) {
	ubyte[] TSerialize(T *t) {
		return (cast(ubyte *)t)[0..T.sizeof];
	}
}
*/

//template TA(T) { ubyte[] TA(inout T t) { return (cast(ubyte *)&t)[0..T.sizeof]; } }

// TODO
/*class SliceStreamNotClose : SliceStream {
}*/

abstract class ContainerEntry {
	ContainerEntry parent;
	ContainerEntry[] childs;
	char[] name;
	Stream open () { throw(new Exception("'open' Not implemented")); }
	void close() { throw(new Exception("'close' Not implemented")); }

	char[] type() {
		return "";
	}

	void print() {
		writefln("%s('%s')", this, name);
	}

	void saveto(Stream s) {
		Stream cs = this.open();
		s.copyFrom(cs);
		s.flush();
		//this.close();
	}

	ubyte[] read() {
		ubyte[] ret;
		MemoryStream s = new MemoryStream();
		saveto(s);
		ret.length = s.data.length;
		ret[0..ret.length] = s.data[0..ret.length];
		delete s;
		return ret;
	}

	public void saveto(char[] s) {
		File f = new File(s, FileMode.OutNew);
		saveto(f);
		f.close();
	}

	void list(char[] base = "") {
		print();
		foreach (child; childs) {
			if (!child.name) continue;
			writefln("'%s%s'", base, child.name);
			if (child.childs.length) child.list(format("%s/", child.name));
		}
	}

	void add(ContainerEntry ce) {
		childs ~= ce;
		ce.parent = this;
	}

	ContainerEntry opIndex(char[] name) {
		if (std.string.find(name, '/') != -1) throw(new Exception("Only root files implemented"));
		foreach (child; childs) {
			if (std.string.icmp(child.name, name) == 0) return cast(ContainerEntry)child;
		}
		throw(new Exception(format("File '%s' doesn't exists", name)));
	}

    int opApply(int delegate(inout ContainerEntry) dg) {
    	int result = 0;

		for (int n = 0; n < childs.length; n++) {
			result = dg(childs[n]);
			if (result) break;
		}

		return result;
    }

	// Reemplazamos un stream
	int replace(Stream from, bool limited = true) {
		//writefln("ContainerEntry.replace(%08X);", cast(uint)cast(uint *)this);
		Stream op = this.open();
		//writefln("%d", op.writeable);
		ulong start = op.position;
		
		copyStream(from, op);
		
		return op.position - start;
	}
	
	int replaceAt(Stream from, int skip = 0) {
		//writefln("ContainerEntry.replace(%08X);", cast(uint)cast(uint *)this);
		Stream op = this.open();
		//writefln("%d", op.writeable);
		ulong start = op.position;
		op.position = start + skip;
		copyStream(from, op);
		return op.position - start;
	}

	// Reemplazamos por un fichero
	void replace(char[] from, bool limited = true) {
		File f = new File(from, FileMode.In);
		replace(f, limited);
		f.close();
	}
	
	// Reemplazamos por un fichero
	void replaceAt(char[] from, int skip = 0) {
		File f = new File(from, FileMode.In);
		replaceAt(f, skip);
		f.close();
	}	

	bool isFile() {
		return false;
	}
}

abstract class ContainerEntryWithStream : ContainerEntry {
	Stream stream;

	Stream rs;

	void setData(void[] data) {
		setStream(new MemoryStream(cast(ubyte[])data));
	}

	void setStream(Stream s) {
		//close();
		rs = s;
		s.position = 0;
	}

	Stream open() {
		if (rs) return rs;

		//writefln("ContainerEntry.open(%08X);", cast(uint)cast(uint *)this);
		if (stream && stream.isOpen) {
			//writefln("opened");
			stream.position = 0;
			return stream;
		}
		//writefln("realopen");
		return stream = realopen();
	}

	void close() {
		//writefln("ContainerEntry.close(%08X);", cast(uint)cast(uint *)this);
		if (stream && stream.isOpen) {
			//writefln("closd");
			stream.close();
		}
	}

	protected Stream realopen(bool limited = true) {
		throw(new Exception("realopen: Not Implemented (" ~ this.toString ~ ")"));
	}
}
