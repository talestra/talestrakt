/*
	Reinsertor Genérico para ficheros DAT del Tales of the Abyss
*/

import std.stdio, std.stream, std.file, std.string, std.date;
import tales.util.gameformat, tales.common;
import tales.scont.generic, tales.scont.iso;
import tales.isopath;

version = alignfake;
version = alignfake2;

version(alignfake2) {
	alias StreamWriteStringR2Fake2 StreamWriteStringR2Final;
} else {
	version(alignfake) {
		alias StreamWriteStringR2Fake StreamWriteStringR2Final;
	} else {
		alias StreamWriteStringR2 StreamWriteStringR2Final;
	}
}


void WriteCurrentDate(OutputStream mod) {
	Date date;
	date.parse(std.date.toString(std.date.getUTCtime()));
	mod.writef("%04d/%02d/%02d %02d:%02d:%02d", date.year, date.month, date.day, date.hour, date.minute, date.second);
}

void Create_ACS_Stream(Stream ori, Stream fin, Stream mod, bool autoclose = true) {
	uint textbase = 88 * 20 + 0x10;
	GameFormatString fs = new TOAGameFormatString();

	char[][] titles, descriptions;
	char[] line, title, description;

	while (!fin.eof) {
		if (line.length >= 2 && line[0..2] == "->") {
			title = std.string.strip(line[3..line.length]);
			while (!fin.eof) {
				line = std.string.strip(fin.readLine());
				if (!line.length) continue;
				if (line.length >= 2 && line[0..2] == "->") break;
				if (description.length) description ~= "\n";
				description ~= line;
			}

			titles ~= title;
			descriptions ~= description;

			description = title = "";
			continue;
		}

		line = std.string.strip(fin.readLine());
	}

	mod.position = 0;
	ori.position = 0;

	{
		ubyte[] temp;
		temp.length = textbase; ori.read(temp);
		mod.write(temp);
	}

	mod.position = textbase;
	{ // Actualizamos/Añadimos la fecha
		StreamAlignZ(mod, 0x20);
		StreamWritePointerAt(mod, 4);
		WriteCurrentDate(mod);
	}

	StreamAlignZ(mod, 0x20);

	// Añadimos la lista de títulos (todos juntos para evitar problemas de segmentación en cd)
	// se pueden mostrar todos los títulso a la vez (las descripciones no)
	for (int n = 0; n < titles.length; n++) {
		StreamWritePointerAt(mod, 0x10 + ((n + 1) * 20) + 0);
		StreamWriteStringR2Final(mod, fs.encodeString(titles[n]));
	}

	// Añadimos la lista de descripciones (todos juntos para evitar problemas de segmentación en cd)
	for (int n = 0; n < descriptions.length; n++) {
		StreamWritePointerAt(mod, 0x10 + ((n + 1) * 20) + 4);
		StreamWriteStringR2Final(mod, fs.encodeString(descriptions[n]));
	}

	StreamAlignZ(mod, 0x10);

	if (autoclose) {
		ori.close();
		fin.close();
	}

	mod.position = 0;
}

void Create_SLTSKL_Stream(Stream ori, Stream fin, Stream mod, bool autoclose = true) {
	GameFormatString fs = new TOAGameFormatString();
	ubyte[] temp;

	char[][] titles, descriptions;
	char[] line, title, description;

	while (!fin.eof) {
		if (line.length >= 2 && line[0..2] == "->") {
			title = std.string.strip(line[3..line.length]);
			while (!fin.eof) {
				line = std.string.strip(fin.readLine());
				if (!line.length) continue;
				if (line.length >= 2 && line[0..2] == "->") break;
				if (description.length) description ~= "\n";
				description ~= line;
			}

			titles ~= title;
			descriptions ~= description;

			description = title = "";
			continue;
		}

		line = std.string.strip(fin.readLine());
	}

	// Cabecera
	{
		temp.length = 0x10;
		ori.read(temp);
		mod.write(temp);
	}

	// Fecha
	WriteCurrentDate(mod);
	StreamAlignZ(mod, 0x10);

	// Datos & Punteros
	StreamAlignZ(mod, 0xD0);

	for (int n = 0; n < 19; n++) {
		StreamWritePointerAt(mod, 0x30 + (n * 8));
		StreamWriteStringR2Final(mod, fs.encodeString(titles[n]));

		StreamWritePointerAt(mod, 0x30 + (n * 8) + 4);
		StreamWriteStringR2Final(mod, fs.encodeString(descriptions[n]));
	}
}

void Create_SP_Stream(Stream ori, Stream fin, Stream mod, bool autoclose = true) {
	GameFormatString fs = new TOAGameFormatString();
	ubyte[] temp;

	char[][] titles, descriptions;
	char[] line, title, description;

	while (!fin.eof) {
		if (line.length >= 2 && line[0..2] == "->") {
			title = (line.length >= 3) ? std.string.strip(line[3..line.length]) : "";
			while (!fin.eof) {
				line = std.string.strip(fin.readLine());
				if (!line.length) continue;
				if (line.length >= 2 && line[0..2] == "->") break;
				if (description.length) description ~= "\n";
				description ~= line;
			}

			titles ~= title;
			descriptions ~= description;

			description = title = "";
			continue;
		}

		line = std.string.strip(fin.readLine());
	}
	
	// Cabecera
	{
		temp.length = 0x10;
		ori.read(temp);
		mod.write(temp);
	}

	// Fecha
	WriteCurrentDate(mod);
	StreamAlignZ(mod, 0x10);	
	
	// Datos & Punteros
	//StreamAlignZ(mod, 0x3C00);	
	
	// Datos & Punteros
	{
		temp.length = 60 * 0xFF;
		ori.position = 0x30;
		mod.position = 0x30;
		ori.read(temp);
		mod.write(temp);
	}	
	
	StreamAlign(mod, 0x3C00);	
	
	for (int n = 0; n < 0xFF; n++) {
		printf("'%s'\n", toStringz(titles[n]));
		try {
			StreamWritePointerAt(mod, 0x30 + (n * 60) + 0);
			StreamWriteStringR2Final(mod, fs.encodeString(titles[n]));

			StreamWritePointerAt(mod, 0x30 + (n * 60) + 56);
			StreamWriteStringR2Final(mod, fs.encodeString(descriptions[n]));		
		} catch (Exception e) {
			writefln("Error en habilidad: %d", n);
			throw(e);
		}
	}
}

/*void Create_SP_Stream(Stream s, Stream d, bool autoclose = true) {
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
}*/

void Create_I_Stream(Stream ori, Stream fin, Stream mod, bool autoclose = true) {
	GameFormatString fs = new TOAGameFormatString();
	uint count, ptr, lptr;
	uint[] iptrl;
	int[uint] iptr;
	char[] line;
	char[][] t2l;
	
	struct Item {
		char[] name;
		char[] desc;
	};
	
	Item[] items;
	
	ori.position = 0;
	ubyte[] temp; temp.length = ori.available;
	ori.read(temp);
	mod.write(temp);
	ori.position = 0;
	mod.position = 0;
	
	temp.length = 0; temp.length = 0x17680;
	mod.position = 0x9470;
	mod.write(temp);
	
	int type = 0, state = 0;
	while (!fin.eof) {
		line = std.string.strip(fin.readLine());
		
		if (line.length >= 1 && line[0] == '*') {
			switch (line[1..line.length]) {
				case "TYPE1": type = 1; state = 0; break;
				case "TYPE2": type = 2; break;
			}
			continue;
		}
		
		if (type == 1) {
			if (!line.length) { state = 0; continue; }
				
			if (state == 0) {
				// Titulo
				items.length = items.length + 1;
				items[items.length - 1].name = line;				
				items[items.length - 1].desc = "";
				state = 1;
			} else {
				// Descripcion aditiva
				if (items[items.length - 1].desc.length > 0) items[items.length - 1].desc ~= "\n";
				items[items.length - 1].desc ~= line;
			}			
		} else  if (type == 2) {
			if (!line.length) continue;
			t2l ~= line;
		}
	}
	
	//for (int n = 0; n < items.length; n++) writefln(items[n].name);
	
	ori.position = 0x04;

	ori.read(ptr); // Puntero a fecha
	
	mod.position = ptr;
	WriteCurrentDate(mod);
	
	ori.read(count);
	ori.read(ptr);

	ori.read(lptr);

	ori.position = ptr;

	//writefln("%d", ptr);

	ori.seek(60, SeekPos.Current);
	
	// 0x9470-0x17680
	// 0x20600
	
	int back = ori.position;

	for (int n = 1; n < count; n++) {
		char[] name, jname, desc, itype;
		ori.read(ptr);
		ori.read(ptr);
		ori.seek(60 - 8 - 8, SeekPos.Current);
		ori.read(ptr);
		ori.read(ptr);
		iptr[ptr] = 0;
	}
	
	iptrl = iptr.keys.sort;
	
	int m = 0;
	mod.position = 0x9470;
	foreach (cptr; iptrl) {
		StreamAlign(mod);
		iptr[cptr] = (cptr == 0) ? 0 : mod.position;
		//StreamWriteStringR2Final(mod, fs.encodeString(fs.extractStringz(ori, cptr)));
		if (cptr != 0) {
			StreamWriteStringR2Final(mod, fs.encodeString(t2l[m]));
			m++;
		}
	}
	
	ori.position = back;
	
	for (int n = 1; n < count; n++) {
		char[] name, jname, desc, itype;
		int estart = ori.position;
		ori.read(ptr); name = fs.extractStringz(ori, ptr);
		ori.read(ptr); jname = fs.extractStringz(ori, ptr);
		ori.seek(60 - 8 - 8, SeekPos.Current);
		ori.read(ptr); desc = fs.extractStringz(ori, ptr);
		ori.read(ptr);
		//iptr[ptr] = true;
		//itype = fs.extractStringz(ori, ptr);
		
		//StreamWriteStringR2(mod, fs.encodeString(name));
		
		try {
			//writef("%s - ", name);
			name = items[n - 1].name;
			//writefln("%s", name);
			desc = items[n - 1].desc;
		} catch (Exception e) {
			//writefln("ITEM: %d", n);
			//throw(e);
		}
		
		// Nombre e/j
		StreamAlign(mod);
		StreamWritePointerAt(mod, estart + 0);
		StreamWritePointerAt(mod, estart + 4);
		StreamWriteStringR2Final(mod, fs.encodeString(name));
		// Descripcion
		StreamAlign(mod);
		StreamWritePointerAt(mod, estart + 52);
		StreamWriteStringR2Final(mod, fs.encodeString(desc));
		// Tipo
		StreamWritePointerAt(mod, estart + 56, iptr[ptr]);
		
		/*
		StreamWriteStringR2Final(mod, fs.encodeString(titles[n]));
		*/
		
		//writefln(iptr[ptr]);
		//writefln(itype);
		//d.writeLine(desc);
		//d.writefln();
	}
}

void Create_STG_Stream(Stream ori, Stream fin, Stream mod, bool autoclose = true) {
	GameFormatString fs = new TOAGameFormatString();
	mod.copyFrom(ori);
	ori.position = 0;
	
	mod.position = 0x40;
	
	WriteCurrentDate(mod);
	
	struct entry {
		char[] name;
		char[] desc;
	}
	
	char[] type;
	
	ubyte[] temp;
	
	char[][] profiles;
	entry[][char[]] common;
	
	int status;
	
	while (!fin.eof) {
		char[] line = std.string.strip(fin.readLine());
		if (line.length >= 1 && line[0] == '*') {
			type = line[1..line.length];
			status = 0;
			continue;
		}
		
		switch (type) {
			case "profiles":
				if (line.length == 0) continue;
				profiles ~= line;
			break;
			default:
				if (line.length == 0) { status = 0; continue; }
				if (status == 0) {
					common[type].length = common[type].length + 1;
					common[type][common[type].length - 1].name = line;
					common[type][common[type].length - 1].desc = "";
					status = 1;
				} else {
					if (common[type][common[type].length - 1].desc.length) common[type][common[type].length - 1].desc ~= "\n";
					common[type][common[type].length - 1].desc ~= line;
				}
			break;
		}
	}
	
	mod.position = 0x70;
	temp.length = 0x50;
	mod.write(temp);
	mod.position = 0x70;
	foreach (n, name; profiles) {
		StreamAlign(mod);
		StreamWritePointerAt(mod, 0x08 + n * 4);
		StreamWriteStringR2Final(mod, fs.encodeString(name));
	}
	
	//int[2][]
	
	void updateText(int n, int pos, int length, char[] type) {
		int count, ptr;
		
		mod.position = pos;
		temp.length = length;
		mod.write(temp);
		
		ori.position = 0x18 + 8 * n;
		ori.read(ptr);
		ori.read(count);
		
		mod.position = pos;		
		//StreamWritePointerAt(mod, 0x18 + 8 * n);
				
		entry[] list = common[type];
		
		//writefln("%08X %08X", count, ptr);
		
		foreach (m, e; list) {
			StreamAlign(mod);
			StreamWritePointerAt(mod, ptr + m * 12 + 0);
			StreamWriteStringR2Final(mod, fs.encodeString(e.name));
			
			StreamAlign(mod);
			StreamWritePointerAt(mod, ptr + m * 12 + 4);
			StreamWriteStringR2Final(mod, fs.encodeString(e.desc));
		}
	}
		
	updateText(0, 0x130, 0x320, "targets");
	updateText(1, 0x4B0, 0x2E0, "tpuse");
	updateText(2, 0x7F0, 0x220, "behaviour");
	updateText(3, 0xA50, 0x170, "items");
	updateText(4, 0xC00, 0x1C0, "overlimit");
	
	//foreach (a; profiles) printf("%s\n", toStringz(a));
	//foreach (a; common["targets"]) printf("%s\n", toStringz(a.name));
	
	//mod.position = 0;	
}

/*Iso isow, isorootw;

void AbyssInitIsoPathWrite() {
	isow     = new Iso("l:\\isos\\ps2\\Tales of the Abyss - test.iso");
	isorootw = new Iso(iso["TO7ROOT.CVM"].open);
}*/

void Create_MAP_Stream(Stream ori, Stream fin, Stream mod, bool autoclose = true) {
	// 0x32D4
	// 0x42AC

	GameFormatString fs = new TOAGameFormatString();

	struct MAP {
		uint file;
		uint title;
		uint[3] unk;
	}
	
	struct HEADER {
		uint map_count;
		uint se_ptr;
		uint se_count;
	}
	
	HEADER header;
	MAP[] maps;
	ubyte[] temp;
	char[][] map_names;
	int[][char[]] map_list;
	
	mod.copyFrom(ori);
	mod.position = 0x32D4;
	temp.length = 0x42AC; mod.write(temp);
	mod.position = 0x32D4;
	
	ori.position = 0;
	ori.read(TA(header));
	
	for (int n = 0; n < header.map_count; n++) {
		MAP map;
		ori.read(TA(map));
		maps ~= map;
	}

	foreach (k, map; maps) {
		char[] file = fs.extractStringz(ori, map.file) ~ "\0";
		maps[k].file = mod.position;
		mod.writeString(file);
	}
	
	int n = 0;
	bool ext = false;
	while (!fin.eof) {
		char[] ss = fin.readLine();
		if (!ext && (ss == "testmap")) ext = true;
		if (ext) {
			ss = fin.readLine();
			fin.readLine();
		}
		//writefln("%s", ss);
		char[] s = std.string.strip(ss) ~ "\0";
		map_list[s] ~= map_names.length;
		map_names ~= s;
	}
	
	foreach (title, list; map_list) {
		int pos = mod.position;
		mod.writeString(title);
		foreach (k; list) maps[k].title = pos;
		//writefln("%s", name);
	}
	
	mod.position = HEADER.sizeof;
	foreach (map; maps) mod.write(TA(map));
}

void Create_CKD_Stream(Stream ori, Stream fin, Stream mod, bool autoclose = true) {
	void clean(int pos, int size) {
		ubyte[] temp; temp.length = size;
		mod.position = pos;
		mod.write(temp);
	}

	mod.copyFrom(ori);

	clean(0x0ED0, 0x17B0);
	clean(0x26A0, 0x80);

	int type = 0;
	
	struct SLICE {
		int count;
		int ptr;
	}
	
	struct HEADER {
		uint magic;
		SLICE[3] list;
	}
	
	struct TYPE1 {
		char[] title;
		char[] desc;
		char[][] types;
	}
	
	HEADER header;
	TYPE1[] list1;
	char[][][2] slist;
	TYPE1 current;
	
	ori.position = 0;
	ori.read(TA(header));
	
	Stream[3] s_type;
	
	foreach (k, sl; header.list) {
		//writefln("SLICE: %08X-%08X", sl.ptr, sl.count);
		s_type[k] = new SliceStream(mod, sl.ptr);
	}

	void flush() {
		if (!current.title) return;
		list1 ~= current;
		current.title = [];
		current.desc = [];
		current.types = [];
	}
	
	while (!fin.eof) {
		char[] s = std.string.strip(fin.readLine);
		if (!s.length) continue;
		if (s[0] == '*') { type = s[5] - '0'; writefln("Type:%d", type); continue; }
		switch (type) {
			case 0: break;
			case 1:
				if (s[0] == '-') {
					// title
					if (s.length >= 2 && s[1] == '>') {
						flush();
						current.title = std.string.strip(s[2..s.length]);
					}
					// type
					else {
						current.types ~= std.string.strip(s[1..s.length]);
					}
				}
				// description
				else {
					if (current.desc.length) current.desc ~= "\n";
					current.desc ~= s;
				}
			break;
			case 2: case 3: slist[type - 2] ~= s; break;
		}
	}
	flush();
	
	mod.position = 0xED0;

	foreach (e; slist[0]) {
		s_type[1].write(cast(uint)mod.position); mod.writeString(e ~ "\0");
		s_type[1].seekCur(0x20);
	}

	foreach (e; slist[1]) {
		s_type[2].write(cast(uint)mod.position); mod.writeString(e ~ "\0");
	}
	
	foreach (e; list1) {
		s_type[0].write(cast(uint)mod.position); mod.writeString(e.title ~ "\0");
		s_type[0].write(cast(uint)mod.position); mod.writeString(e.desc ~ "\0");
		s_type[0].seekCur(0x28);
		for (int m = 0; m < 7; m++) {
			if (e.types[m].length <= 1) e.types[m] = " ";
			s_type[0].write(cast(uint)mod.position); mod.writeString(e.types[m] ~ "\0");
			s_type[0].seekCur(0xC);
		}
	}
	
	
}

int main(char[][] args) {
	AbyssInitIsoPath();
	//AbyssInitIsoPathWrite();

	if (args.length < 2) {
		writefln("Reinsertor DAT para Tales of the Abyss");
		writefln("");
		writefln("Drivers:");
		writefln("\tacs, sltskl, sp, i, stg, map, ckd");
		writefln("");
		writefln("modo de uso: reinsert driver [file.in] [file.out]");
	} else {
		char[] driver = std.string.tolower(std.string.strip(args[1])), filein;
		filein = (args.length > 2) ? args[2] : format("%s.es.txt", driver);
		switch (driver) {
			case "acs": {
				Stream mod = new File((args.length > 3) ? args[3] : "es/_ACS_.DAT", FileMode.OutNew);

				Create_ACS_Stream(
					isoroot["_ACS_.DAT"].open,
					new File(filein, FileMode.In),
					mod
				);

				mod.close();
			} break;
			case "stg": {
				Stream mod = new File((args.length > 3) ? args[3] : "es/_STG_.DAT", FileMode.OutNew);

				Create_STG_Stream(
					isoroot["_STG_.DAT"].open,
					new File(filein, FileMode.In),
					mod
				);

				mod.close();
			} break;
			case "map": {
				Stream mod = new File((args.length > 3) ? args[3] : "es/MAPTABLE.MBT", FileMode.OutNew);

				Create_MAP_Stream(
					isoroot["MAPTABLE.MBT"].open,
					new File(filein, FileMode.In),
					mod
				);

				mod.close();
			} break;			
			case "ckd": {
				Stream mod = new File((args.length > 3) ? args[3] : "es/_CKD_.DAT", FileMode.OutNew);

				Create_CKD_Stream(
					isoroot["_CKD_.DAT"].open,
					new File(filein, FileMode.In),
					mod
				);

				mod.close();
			} break;			
			case "sltskl": {
				Stream mod = new File((args.length > 3) ? args[3] : "es/_SLTSKL_.DAT", FileMode.OutNew);

				Create_SLTSKL_Stream(
					isoroot["_SLTSKL_.DAT"].open,
					new File(filein, FileMode.In),
					mod
				);

				mod.close();
			} break;
			case "sp": {
				Stream mod = new File((args.length > 3) ? args[3] : "es/_SP_.DAT", FileMode.OutNew);

				Create_SP_Stream(
					isoroot["_SP_.DAT"].open,
					new File(filein, FileMode.In),
					mod
				);

				mod.close();
			} break;			
			case "i": {
				Stream mod = new File((args.length > 3) ? args[3] : "es/_I_.DAT", FileMode.OutNew);

				Create_I_Stream(
					isoroot["_I_.DAT"].open,
					new File(filein, FileMode.In),
					mod
				);

				mod.close();
			} break;			
			default:
				writefln("Extractor para '%s' no implementado", driver);
			break;
		}
	}

	return 0;
}
