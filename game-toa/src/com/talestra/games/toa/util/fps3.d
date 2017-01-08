import vfs;

// NOTAS: El ultimo elemento tiene como start
// el final del archivo, como length = 0 y name todos 0s
struct Fps3EntryData {
	uint start;
	uint length;
	char name[0x20];
}

struct Fps3ArchiveHeader {
	char magic[4];
	uint count;
	uint starte;
	uint startd;
	uint unknown[3];
}

class Fps3Entry : FileContainer {
	Fps3Archive fa;
	Fps3EntryData fed;

	void print() {
		FileContainer.print();
		writefln("{");
		writefln("  start:  %08X", fed.start);
		writefln("  length: %08X", fed.length);
		writefln("  name:   '%s'", name);
		writefln("}");
	}

	override Stream realopen(FileMode mode, bool limited = true) {
		return fa.openFileEntry(fed);
	}
}

class Fps3Archive : Fps3Entry {
	Fps3ArchiveHeader fah;
	uint count() { return fah.count - 1; }

	Stream openFileEntry(Fps3EntryData fed) {
		return new SliceStreamNoClose(stream, fed.start, fed.start + fed.length);
	}

	void print() {
		FileContainer.print();
		writefln("{");
		writefln("  magic:  %s", fah.magic);
		writefln("  count:  %d", fah.count);
		writefln("  starte: %08X", fah.starte);
		writefln("  startd: %08X", fah.startd);
		writefln("  unk0:   %08X", fah.unknown[0]);
		writefln("  unk1:   %08X", fah.unknown[1]);
		writefln("  unk2:   %08X", fah.unknown[2]);
		writefln("}");
	}

	void add(Fps3Entry fe) {
		FileContainer.add(fe);
		fe.fa = this;
	}

	void saveto(Stream s) {
		fah.magic[0..4] = "FPS3";
		fah.count = childs.length;
		fah.starte = Fps3ArchiveHeader.sizeof;
		fah.startd = fah.starte + Fps3EntryData.sizeof * fah.count;
		if (fah.startd % 0x20 != 0) fah.startd += (0x20 - fah.startd % 0x20);
		s.write(TA(fah));

		while (s.position < fah.startd) s.write(cast(ubyte)0);
		s.position = fah.startd;

		//foreach (_e; childs.reverse) { Fps3Entry e = cast(Fps3Entry)_e;
		foreach (_e; childs) { Fps3Entry e = cast(Fps3Entry)_e;
			Stream es = e.open();
			es.position = 0;
			//writefln("SAVE: %s (%08X)", e.name, cast(uint)cast(void *)es);
			e.fed.start = s.position;
			copy2From(s, es);
			e.fed.length = s.position - e.fed.start;
			//e.close();
			if (e.name.ptr != e.fed.name.ptr) e.fed.name[0..e.name.length] = e.name[0..e.name.length];
		}

		while (s.position < fah.starte) s.write(cast(ubyte)0);
		s.position = fah.starte;

		foreach (_e; childs) { Fps3Entry e = cast(Fps3Entry)_e;
			s.write(TA(e.fed));
		}
	}
	
	void saveto(char[] s) {
		FileContainer.saveto(s);
	}

	this(Stream s) {
		this.name = "archive";
		stream = s;
		stream.position = 0;
		stream.read(TA(fah));
		if (fah.magic != "FPS3") throw(new Exception(format("This file isn't a FPS3 one magic: '%s'", fah.magic)));
		stream.position = fah.starte;

		for (int n = 0; n <= count; n++) {
			Fps3Entry fe = new Fps3Entry;
			stream.read(TA(fe.fed));
			fe.name = std.string.toString(fe.fed.name.ptr);
			//writefln("LOAD: %s", fe.name);
			add(fe);
		}
	}

	this(char[] s) {
		this(new File(s, FileMode.In | FileMode.Out));
		this.name = s;
	}
}
