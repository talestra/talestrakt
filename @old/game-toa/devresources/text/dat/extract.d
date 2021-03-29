/*
	Extractor Genérico para ficheros DAT del Tales of the Abyss
*/

import std.stdio, std.stream, std.file, std.string;
import tales.util.gameformat, tales.isopath, tales.scont.generic, tales.scont.iso;

GameFormatString fs;

void Extract_ACS_Stream(Stream s, Stream f, bool autoclose = true) {
	char[] name, desc; uint pdate, pptr, ptr;

	s.seek(4, SeekPos.Current);
	s.read(pdate);
	s.read(pptr);

	s.position = pptr;

	s.seek(20, SeekPos.Current);

	for (int n = 0; n < 87; n++) {
		s.read(ptr); name = fs.extractStringz(s, ptr);
		s.read(ptr); desc = fs.extractStringz(s, ptr);
		s.seek(12, SeekPos.Current);
		f.writefln("-> %s\n%s\n", name, desc);
	}

	if (autoclose) { s.close(); f.close(); }
}

void Extract_CKD_Stream(Stream s, Stream d, bool autoclose = true) {
	void ExtractType1() {
		d.writeLine("*TYPE1");

		uint count, ptr;
		s.position = 4 + (8 * 0);
		s.read(count);
		s.read(ptr);
		s.position = ptr;

		for (uint n = 0; n < count; n++) {
			s.read(ptr); d.writeLine("-> " ~ fs.extractStringz(s, ptr));
			s.read(ptr); d.writeLine(fs.extractStringz(s, ptr));
			s.seek(40, SeekPos.Current);
			for (uint m = 0; m < 7; m++) {
				s.read(ptr); d.writeLine("- " ~ fs.extractStringz(s, ptr));
				s.seek(12, SeekPos.Current);
			}
			d.writefln();
		}
	}

	void ExtractType2() {
		d.writeLine("*TYPE2");

		uint count, ptr;
		s.position = 4 + (8 * 1);
		s.read(count);
		s.read(ptr);
		s.position = ptr;

		for (uint n = 0; n < count; n++) {
			s.read(ptr); d.writeLine(fs.extractStringz(s, ptr));
			s.seek(32, SeekPos.Current);
		}

		d.writeLine("");
	}

	void ExtractType3() {
		d.writeLine("*TYPE3");

		uint count, ptr;
		s.position = 4 + (8 * 2);
		s.read(count);
		s.read(ptr);
		s.position = ptr;

		for (uint n = 0; n < count; n++) {
			s.read(ptr); d.writeLine(fs.extractStringz(s, ptr));
		}

		d.writeLine("");
	}

	ExtractType1();
	ExtractType2();
	ExtractType3();

	if (autoclose) { s.close(); d.close(); }
}

void Extract_MAP_Stream(Stream s, Stream d, bool autoclose = true) {
	uint ptr;

	s.position = 0x0C;

	for (uint n = 0; n < 649; n++) {
		s.read(ptr); //d.writefln("%s", fs.extractStringz(s, ptr));
		s.read(ptr); d.writefln("%s", fs.extractStringz(s, ptr));
		//d.writefln();
		s.seek(0x14 - 8, SeekPos.Current);
	}

	if (autoclose) { s.close(); d.close(); }
}

void Extract_SP_Stream(Stream s, Stream d, bool autoclose = true) {
	uint ptr, count;

	s.seek(8, SeekPos.Current);
	s.read(count);
	s.read(ptr);

	s.position = ptr;

	for (int n = 0; n < count; n++) {
		s.read(ptr); d.writeLine("-> " ~ fs.extractStringz(s, ptr));
		s.seek(60 - 8, SeekPos.Current);
		s.read(ptr); d.writeLine(fs.extractStringz(s, ptr));;
		d.writefln();
	}

	if (autoclose) { s.close(); d.close(); }
}

void Extract_STG_Stream(Stream s, Stream d, bool autoclose = true) {
	void ExtractProfiles(Stream s, Stream d) {
		d.writefln("*profiles\n");
		s.position = 0x8;
		for (int n = 0; n < 3; n++) {
			uint ptr; char[] name;
			s.read(ptr); name = fs.extractStringz(s, ptr);
			d.writefln("%s", name);
		}
		d.writefln();
	}

	void ExtractGeneric(Stream s, Stream d, char[] cname, uint p) {
		uint ptr, count;
		d.writefln("*%s\n", cname);
		s.position = 0x14 + 8 * p;
		s.read(count);
		s.read(ptr);
		s.position = ptr;
		for (int n = 0; n < count; n++) {
			char[] name, description;
			s.read(ptr); name = fs.extractStringz(s, ptr);
			s.read(ptr); description = fs.extractStringz(s, ptr);
			s.seek(4, SeekPos.Current);
			d.writefln("%s\n%s\n", name, description);
		}
	}

	ExtractProfiles(s, d);
	ExtractGeneric (s, d, "targets", 0);
	ExtractGeneric (s, d, "tpuse", 1);
	ExtractGeneric (s, d, "behaviour", 2);
	ExtractGeneric (s, d, "items", 3);
	ExtractGeneric (s, d, "overlimit", 4);

	if (autoclose) { s.close(); d.close(); }
}

void Extract_SLTSKL_Stream(Stream s, Stream d, bool autoclose = true) {
	s.position = 0x30;

	//File f = new File("_SLTSKL_.en.dat", FileMode.OutNew); f.copyFrom(s); f.close();

	for (int n = 0; n < 19; n++) {
		uint ptr;
		s.read(ptr); d.writefln("-> %s", fs.extractStringz(s, ptr));
		s.read(ptr); d.writefln("%s\n", fs.extractStringz(s, ptr));
	}

	if (autoclose) { s.close(); d.close(); }
}

void Extract_CLBD_Stream(Stream s, Stream d, bool autoclose = true) {
	char[] name, description;
	uint ptr;
	uint base;

	for (uint id = 1; id <= 630; id++) {
		base = id * 0x2000;
		s.position = base;

		// Leemos el nombre
		{
			s.position = base + 0x04;
			s.read(ptr); name = fs.extractStringz(s, base + ptr);

			if (name.length == 0) continue;

			d.writeLine(format("->(%03d) ", id) ~ name);
		}

		// Leemos la descripción
		{
			s.position = base + 0x48;
			s.read(ptr); description = fs.extractStringz(s, base + ptr);

			d.writeLine(description);
			//writeTextPointer(to, id * 10 + 1, description);
		}

		d.writefln();
	}

	/*
	// Leemos el TIM2
	{
		s.position = base + 0x4C;
		s.read(itim2);

		s.position = base + itim2;
		tim2.length = 0x1DAC; s.read(tim2);
		File f = new File(format("TM2/%04d.tm2", id), FileMode.Out);
		f.write(tim2);
		f.close();
	}
	*/
}

void Extract_I_Stream(Stream s, Stream d, bool autoclose = true) {
	uint count, ptr, lptr;
	uint[] iptrl;
	bool[uint] iptr;
	s.position = 0x04;

	s.read(ptr); // Puntero a fecha

	s.read(count);
	s.read(ptr);

	s.read(lptr);

	s.position = ptr;

	//writefln("%d", ptr);

	s.seek(60, SeekPos.Current);

	d.writefln("*TYPE1");
	for (int n = 1; n < count; n++) {
		char[] name, jname, desc, itype;
		s.read(ptr); name = fs.extractStringz(s, ptr);
		s.read(ptr); jname = fs.extractStringz(s, ptr);
		s.seek(60 - 8 - 8, SeekPos.Current);
		s.read(ptr); desc = fs.extractStringz(s, ptr);
		s.read(ptr);
		iptr[ptr] = true;
		itype = fs.extractStringz(s, ptr);
		d.writeLine(name);
		//d.writeLine(itype);
		d.writeLine(desc);
		d.writefln();
	}

	iptrl = iptr.keys.sort;

	d.writefln("*TYPE2");

	foreach (cptr; iptrl) {		
		d.writeLine(fs.extractStringz(s, cptr));
	}

	//
	/*s.position = lptr;

	writefln("%08X", lptr);

	for (int n = 1; n < 7; n++) {
		s.seek(16, SeekPos.Current);
		s.read(ptr);
		s.read(ptr);
		s.read(ptr);
		s.read(ptr);
	}*/

	if (autoclose) { s.close(); d.close(); }
}

int main(char[][] args) {
	AbyssInitIsoPath();

	fs = new TOAGameFormatString();

	if (args.length < 2) {
		writefln("Extractor DAT para Tales of the Abyss");
		writefln("");
		writefln("Drivers:");
		writefln("\tacs, ckd, map, sp, stg, sltskl, clbd, i");
		writefln("");
		writefln("modo de uso: extract driver [file.out]");
	} else {
		char[] driver = std.string.tolower(std.string.strip(args[1])), fileout;
		fileout = (args.length > 2) ? args[2] : format("%s.en.txt", driver);
		switch (driver) {
			case "acs": // Ad Skills
				Extract_ACS_Stream(
					isoroot["_ACS_.en.DAT"].open,
					new File(fileout, FileMode.OutNew)
				);
			break;
			case "ckd": // Cooking
				Extract_CKD_Stream(
					isoroot["_CKD_.en.DAT"].open,
					new File(fileout, FileMode.OutNew)
				);
			break;
			case "map": // Map Titles
				Extract_MAP_Stream(
					isoroot["MAPTABLE.en.MBT"].open,
					new File(fileout, FileMode.OutNew)
				);
			break;
			case "sp": // Skills
				Extract_SP_Stream(
					isoroot["_SP_.en.DAT"].open,
					new File(fileout, FileMode.OutNew)
				);
			break;
			case "stg": // Strategy
				Extract_STG_Stream(
					isoroot["_STG_.en.DAT"].open,
					new File(fileout, FileMode.OutNew)
				);
			break;
			case "sltskl": // Slot Skills
				Extract_SLTSKL_Stream(
					isoroot["_SLTSKL_.en.DAT"].open,
					new File(fileout, FileMode.OutNew)
				);
			break;
			case "clbd": // CLBD
				Extract_CLBD_Stream(
					isoroot["_CLBD.en.DAT"].open,
					new File(fileout, FileMode.OutNew)
				);
			break;
			case "i": // Items
				Extract_I_Stream(
					isoroot["_I_.en.DAT"].open,
					new File(fileout, FileMode.OutNew)
				);
			break;
			default:
				writefln("Extractor para '%s' no implementado", driver);
			break;
		}
	}

	return 0;
}
