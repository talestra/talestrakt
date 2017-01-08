module field;

import imports;

import script;

import std.c.string;

const uint item_count = 146;
const uint coli_count = 176;

// FD_ITEM_DATA.ID7 - TEXT:0x20 - STRUCT:0x28
// FD_COLI_DATA.CB7 - TEXT:0x80 - STRUCT:0xD4

void translate_item() { scope(exit)Progress.pop;Progress.push("Actualizando objetos de mapa mundi", item_count);
	Stream dat_s = FS.gout["field/FD_ITEM_DATA.ID7"].open; scope(exit) dat_s.close();
	Stream txt_s = FS.patch["field/item.txt"].open; scope(exit) txt_s.close();
	int count = 0;
	while (!txt_s.eof) {
		Progress.set(count++);
		char[] l = txt_s.readLine; l = strip(l);
		if (!l.length) continue;
		char[][] ll = split2(l, ":", 2);
		uint n = intFromBase(ll[0], 10);
		if (ll[1][0] != '\'') throw(new Exception("Invalid item"));
		char[] text = replace(ll[1][1..ll[1].length - 1], "\\n", "\n");
		ubyte[0x20] data;
		data[0..text.length] = cast(ubyte[])text;
		dat_s.position = n * 0x28;
		dat_s.write(data);
	}
}

void translate_coli() { scope(exit)Progress.pop;Progress.push("Actualizando localizaciones de mapa mundi", coli_count);
	Stream dat_s = FS.gout["field/FD_COLI_DATA.CB7"].open; scope(exit) dat_s.close();
	Stream txt_s = FS.patch["field/coli.txt"].open; scope(exit) txt_s.close();
	int count = 0;
	while (!txt_s.eof) {
		Progress.set(count++);
		char[] l = txt_s.readLine; l = strip(l);
		if (!l.length) continue;
		char[][] ll = split2(l, ":", 2);
		uint n = intFromBase(ll[0], 10);
		if (ll[1][0] != '\'') throw(new Exception("Invalid coli"));
		char[] text = replace(ll[1][1..ll[1].length - 1], "\\n", "\n");
		ubyte[0x80] data;
		data[0..text.length] = cast(ubyte[])text;
		dat_s.position = n * 0xD4;
		dat_s.write(data);
	}
}

import iso;

void translate_field_script() { scope(exit)Progress.pop;Progress.push("Traduciendo script del mapa mundi", 4);
	void process(char[] name) {
		char[][] trans; scope(exit) delete trans;
		Stream transs = new BufferedStream(FS.patch["field/script/" ~ name ~ ".txt"].open(FileMode.In)); scope (exit) { transs.close(); delete transs; }
		while (!transs.eof) {
			char[] l;
			l = strip(transs.readLine);
			l = replace(l, "\\n", "\n");
			trans ~= l;
		}		
		
		auto sb7 = new SB7(FS.gin["root/" ~ name].open);
		
		// Translating texts
		foreach (k, s; sb7.str_tt) sb7.str_tt[k].text = trans[k];

		// Translating system
		foreach (k, s; sb7.str_i) if (s.text in system_trans) sb7.str_i[k].text = system_trans[s.text];
		
		auto ms = new MemoryStream();
		sb7.saveto(ms);
		
		//Stream ww = new File(name ~ ".patch", FileMode.OutNew);
		Stream ww = FS.temp["root/" ~ name].open(FileMode.OutNew);
		//ww.write(tocomp.encode(ms));
		ww.write(ms.buf[0..ms.size]);
		ww.close();
		
		//FS.gout["root/" ~ name].replace(FS.temp["field/script/" ~ name], false);
		/*
		try {
			FS.gout["root/" ~ name].replace(FS.temp["field/script/" ~ name]);
		} catch (Exception e) {
			writefln("Can't write '%s', reason: %s", name, e.toString);
			writefln(Iso.sectors(FS.gout["root/" ~ name].open.size) * 0x800);
		}
		*/
	}
	
	for (int n = 0; n < 4; n++) {
		Progress.set(n);
		process(format("FIELD%02d.SB7", n));
	}
}

void translate_f1() { scope(exit)Progress.pop;Progress.push("Traduciendo punto cardinal del mapa mundi");
	Stream s1;
	try {
		s1 = FS.temp["F1.DAT"].open(FileMode.OutNew | FileMode.In);
		ubyte[] u_data = tocomp.decode(FS.gin["field/F1.SLZ"].open);
		s1.write(u_data);
		delete u_data;
		s1.position = 0x117000;
		s1.copyFrom(FS.patch["field/images/F1_0027.tm2"].open);
		s1.position = 0;
		//s1.close();
		//delete s1;
	} catch (Exception e) {
		writefln("block1  ");
		throw(e);
	}

	try {
		ubyte[] c_data; Stream s;
		
		try {
			//s1 = FS.temp["F1.DAT"].open;
		} catch (Exception e) {
			writefln();
			writefln("Error opening F1.DAT");
			throw(e);
		}
		
		try {
			c_data = tocomp.encode(s1);
			s = new MemoryStream(c_data);
		} catch (Exception e) {
			writefln();
			writefln("Can't encode F1.DAT from temp.");
			throw(e);
		}
		
		try {
			FS.gout["field/F1.SLZ"].replace(s);
		} catch (Exception e) {
			writefln();
			writefln("Can't replace field/F1.SLZ");
			throw(e);
		}
		try {
			s.close();
			delete s;
		} catch (Exception e) {
		}
		try {
			delete c_data;
		} catch (Exception e) {
		}
	} catch (Exception e) {
		writefln();
		writefln("block2  ");
		throw(e);
	}
	
	s1.close();
	delete s1;
}

void process() { scope(exit)Progress.pop;Progress.push("Actualizando archivos de mapa mundi", 4);

	Progress.set(1);
	FS.gout["field/FD_ITEM_DATA.ID7"].replace(FS.gin["field/FD_ITEM_DATA.ID7"]);
	translate_item();

	Progress.set(2);
	FS.gout["field/FD_COLI_DATA.CB7"].replace(FS.gin["field/FD_COLI_DATA.CB7"]);
	translate_coli();
	
	Progress.set(3);
	translate_field_script();

	Progress.set(4);
	translate_f1();
	
	//test();
}

void test() {
	Stream coli_s = FS.gin["field/FD_COLI_DATA.CB7"].open; scope(exit) coli_s.close();
	Stream item_s = FS.gin["field/FD_ITEM_DATA.ID7"].open; scope(exit) item_s.close();

	Stream item_so = FS.patch["field/ori/item.txt"].open(FileMode.OutNew); scope(exit) item_so.close();
	for (int n = 0; n < item_count; n++) {
		ubyte[0x20] item_name;
		item_s.position = n * 0x28;
		item_s.read(item_name);
		char[] item_namer = cast(char[])item_name[0..strlen(cast(char*)item_name.ptr)];
		writefln("%s", item_namer);
		item_so.writef("%04d:'", n);
		item_so.writeString(replace(item_namer, "\n", "\\n"));
		item_so.writefln("'");
	}
	
	Stream coli_so = FS.patch["field/ori/coli.txt"].open(FileMode.OutNew); scope(exit) coli_so.close();
	for (int n = 0; n < coli_count; n++) {
		ubyte[0x80] coli_name;
		coli_s.position = n * 0xD4;
		coli_s.read(coli_name);
		char[] coli_namer = cast(char[])coli_name[0..strlen(cast(char*)coli_name.ptr)];
		writefln("%s", coli_namer);
		coli_so.writef("%04d:'", n);
		coli_so.writeString(replace(coli_namer, "\n", "\\n"));
		coli_so.writefln("'");
	}
}