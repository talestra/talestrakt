module tales.scont.fps3;

import tales.scont.generic;
private import std.file, std.string, std.stdio, std.path, std.regexp, std.stream;

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

class Fps3Entry : ContainerEntryWithStream {
	Fps3Archive fa;
	Fps3EntryData fed;

	void print() {
		ContainerEntry.print();
		writefln("{");
		writefln("  start:  %08X", fed.start);
		writefln("  length: %08X", fed.length);
		writefln("  name:   '%s'", name);
		writefln("}");
	}

	override Stream realopen(bool limited = true) {
		if (rs) return rs;
		return fa.openFileEntry(fed);
	}
}

class Fps3Archive : Fps3Entry {
	Fps3ArchiveHeader fah;
	uint count() { return fah.count - 1; }

	Stream openFileEntry(Fps3EntryData fed) {
		return new SliceStream(stream, fed.start, fed.start + fed.length);
	}

	void print() {
		ContainerEntry.print();
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
		ContainerEntry.add(fe);
		fe.fa = this;
	}

	void saveto(Stream s) {
		fah.magic[0..4] = "FPS3";
		fah.count = childs.length;
		fah.starte = Fps3ArchiveHeader.sizeof;
		fah.startd = fah.starte + Fps3EntryData.sizeof * fah.count;
		if (fah.startd % 0x20 != 0) fah.startd += (0x20 - fah.startd % 0x20);
		s.write(TSerialize(&fah));

		s.position = fah.startd;

		foreach (_e; childs) { Fps3Entry e = cast(Fps3Entry)_e;
			Stream es = e.open();
			//writefln("SAVE: %s (%08X)", e.name, cast(uint)cast(void *)es);
			e.fed.start = s.position;
			s.copyFrom(es);
			e.fed.length = s.position - e.fed.start;
			//e.close();
			if (e.name.ptr != e.fed.name.ptr) e.fed.name[0..e.name.length] = e.name[0..e.name.length];
		}

		s.position = fah.starte;

		foreach (_e; childs) { Fps3Entry e = cast(Fps3Entry)_e;
			s.write(TSerialize(&e.fed));
		}
	}

	void saveto(char[] s) {
		ContainerEntry.saveto(s);
	}

	this(Stream s) {
		this.name = "archive";
		stream = s;
		stream.position = 0;
		stream.read(TSerialize(&fah));
		if (fah.magic != "FPS3") throw(new Exception(format("This file isn't a FPS3 one magic: '%s'", fah.magic)));
		stream.position = fah.starte;

		for (int n = 0; n <= count; n++) {
			Fps3Entry fe = new Fps3Entry;
			stream.read(TSerialize(&fe.fed));
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
