import vfs;

struct Fps2EntryData {
	uint position;
	uint length;
	char[3] type;
	byte dummy;
}

class Fps2Entry : FileContainer {
	Fps2Archive fa;
	Fps2EntryData fed;
	uint id;

	override char[] type() {
		return fed.type;
	}

	protected Stream realopen(FileMode mode, bool limited = true) {
		return fa.openFileEntry(fed);
	}
}

class Fps2Archive : Fps2Entry {
	ubyte[4] magic = ['F', 'P', 'S', '2'];
	uint count;

	//uint count() { return fah.count - 1; }

	Stream openFileEntry(Fps2EntryData fed) {
		return new SliceStreamNoClose(stream, fed.position, fed.position + fed.length);
	}

	void print() {
		FileContainer.print();
		writefln("{");
		writefln("  magic:  %s", magic);
		writefln("  count:  %d", count);
		writefln("}");
	}

	void add(Fps2Entry fe) {
		FileContainer.add(fe);
		fe.fa = this;
	}
	
	override ubyte[] saveData() {
		ubyte[] r; r.length = 16 * (1024 * 1024); // 16MB
		uint pos = 8 + childs.length * Fps2EntryData.sizeof;
		r[0..4] = cast(ubyte[])"FPS2";
		*cast(uint *)&r[4] = childs.length;
		
		int count = 0;
		foreach (_e; childs) { Fps2Entry e = cast(Fps2Entry)_e;
			Stream es = e.open; scope (exit) es.close();
			
			if (e.fed.type == "\x00\x00\x00" || e.fed.length == 0) {
				e.fed.length = e.fed.position = 0;
			}  else {
				while ((pos % 0x40) != 0) pos++;
				
				//writefln("%08X", pos);
			
				e.fed.position = pos;
				e.fed.length = es.size;

				ubyte[] cdata; cdata.length = e.fed.length;
				int rr = es.read(cdata);
				r[pos..pos + rr] = cdata[0..rr];
				delete cdata;
				
				pos += e.fed.length;
			}
			
			*(cast(Fps2EntryData*)&r[8 + count * Fps2EntryData.sizeof]) = e.fed;
			
			count++;
		}
		
		while ((pos % 0x40) != 0) pos++;
		
		r.length = pos;
		
		return r;
	}

	void saveto(Stream s) {
		/*
		ubyte[] data = saveData;
		s.write(data);
		delete data;
		*/
		s.position = 0;
		s.writeString("FPS2");
		s.write(cast(uint)childs.length);
		
		s.position = s.position + 12 * childs.length;		
		
		foreach (_e; childs) { Fps2Entry e = cast(Fps2Entry)_e;
			Stream es = e.open; scope (exit) { es.close(); }

			while ((s.position % 0x40) != 0) s.write('\xFE');

			copy2From(s, es);
			//s.copyFrom(es);

			e.fed.length = s.position - e.fed.position;				
			if (e.fed.type == "\x00\x00\x00" || e.fed.length == 0) e.fed.length = e.fed.position = 0;
		}

		s.position = 8;
				
		foreach (_e; this) { Fps2Entry e = cast(Fps2Entry)_e;
			s.write(TA((cast(Fps2Entry)e).fed));
		}
		
		s.position = 0;
	}

	this(Stream s) {
		this.name = "archive";
		stream = s;
		stream.position = 0;
		s.read(magic);
		if (magic != ['F', 'P', 'S', '2']) throw(new Exception(format("This file isn't a FPS2 one magic: '%s'", magic)));
		s.read(count);

		for (int n = 0; n < count; n++) {
			Fps2Entry fe = new Fps2Entry;
			stream.read(TA(fe.fed));
			//fe.name = std.string.format("%s.%d", std.string.toString(toStringz(fe.fed.type)), n);
			fe.name = std.string.format("%s", std.string.toString(toStringz(fe.fed.type)));
			fe.id = n;
			add(fe);
		}
	}

	this(char[] s) {
		this(new File(s, FileMode.In | FileMode.Out));
		this.name = s;
	}
}
