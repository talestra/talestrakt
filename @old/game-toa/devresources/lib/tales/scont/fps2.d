module tales.scont.fps2;

import tales.scont.generic;
private import std.file, std.string, std.stdio, std.path, std.regexp, std.stream;

struct Fps2EntryData {
	uint position;
	uint length;
	char[3] type;
	byte dummy;
}

class Fps2Entry : ContainerEntryWithStream {
	Fps2Archive fa;
	Fps2EntryData fed;
	uint id;

	override char[] type() {
		return fed.type;
	}

	protected Stream realopen(bool limited = true) {
		return fa.openFileEntry(fed);
	}
}

class Fps2Archive : Fps2Entry {
	ubyte[4] magic = ['F', 'P', 'S', '2'];
	uint count;

	//uint count() { return fah.count - 1; }

	Stream openFileEntry(Fps2EntryData fed) {
		return new SliceStream(stream, fed.position, fed.position + fed.length);
	}

	void print() {
		ContainerEntry.print();
		writefln("{");
		writefln("  magic:  %s", magic);
		writefln("  count:  %d", count);
		writefln("}");
	}

	void add(Fps2Entry fe) {
		ContainerEntry.add(fe);
		fe.fa = this;
	}

	void saveto(Stream s) {
		uint start = s.position;
		s.writeString("FPS2");
		s.write(cast(uint)childs.length);
		
		s.position = s.position + 12 * childs.length;		
		
		foreach (_e; childs) { Fps2Entry e = cast(Fps2Entry)_e;
			Stream es = e.open();
			
			while (((s.position - start) % 0x40) != 0) s.write('\xFE');

			e.fed.position = s.position - start;
			s.copyFrom(es);
			e.fed.length = s.position - e.fed.position;				

			if (e.fed.type == "\x00\x00\x00" || e.fed.length == 0) {
				e.fed.length = e.fed.position = 0;
			}
			//e.close();
		}

		s.position = start + 8;
				
		foreach (e; this) s.write(TSerialize(&(cast(Fps2Entry)e).fed));
	}

	void saveto(char[] s) {
		ContainerEntry.saveto(s);
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
			stream.read(TSerialize(&fe.fed));
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
