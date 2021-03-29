import imports;

import btl_common;

void translate_skills() { scope(exit)Progress.pop;Progress.push("Traduciendo habilidades de enemigos");
	scope Stream s = getPatchFile("btl/enemies/skills");
	char[] l;
	
	int total = 0, cur = 0;
	
	while (!s.eof) { l = strip(s.readLine);
		if (!l.length) continue;
		total++;
	}
	
	s.position = 0;
	
	Progress.set(0, total);
	
	while (!s.eof) { l = strip(s.readLine);
		if (!l.length) continue;
		
		Progress.set(cur++);
		
		char[][] cl = split2(l, ":", 3);
		uint eid = intFromBase(cl[0], 10);
		uint ptr = intFromBase(cl[1], 16);
		ubyte[] text = cast(ubyte[])strip(cl[2]);
		if (text.length > 31) throw(new Exception("Too long enemy skill"));
		text.length = 32;

		//printf("%03d:%08X:%s\n", eid, ptr, std.string.toStringz(cast(char[])text));
		
		scope Stream sf = getTempFile(format("btl/enm/%04d", eid), FileMode.In | FileMode.Out);
		sf.position = ptr + 4;
		sf.write(text);
		
		sf.close();
	}
	s.close();
}

void translate_events() { scope(exit)Progress.pop;Progress.push("Traduciendo eventos de enemigos");
	foreach (n; [284]) {
		scope Stream sout = getTempFile(format("btl/enm/%04d", n), FileMode.Out | FileMode.In);
		auto te = getBTSC(cast(char[])getStream(getPatchFile(format("btl/enemies/%04d", n))));
		
		foreach (k, v; te) {
			sout.position = k;
			sout.write(BTSCT_encode(v));
		}
	}
}

void process() { scope(exit)Progress.pop;Progress.push("Parcheando nombres de enemigos");

	char[][int] enemies;
	scope Stream s = getTempFile("btl/usu/0010", FileMode.In | FileMode.Out);

	{ Progress.push("Obteniendo lista de enemigos");
	
		char[][] lines = getLines(getPatchFile("btl/enemies"));
		foreach (n, l; lines) {
			l = l.strip(); if (!l.length) continue;
			int idx = std.conv.toInt(l.split2(":")[0]);

			l = l.split2(":")[1];
			//printf("%04d: %s\n", idx, std.string.toStringz(l));
			if (l.length) l = l.split2("(")[0].strip();
			
			enemies[idx] = l;
		}
	Progress.pop; }
	
	{ scope(exit)Progress.pop; Progress.push("Extrayendo y traduciendo enemigos");
	
		scope Stream enm = getGameFile("btl/BTL_ENM.BIN");
		
		Progress.set(0, enemies.length);
		
		for (int n = 0; n < enemies.length; n++) { patch_stopPoint();
			Progress.set(n);
			if (existsTempFile(format("btl/enm/%04d", n))) continue;

			uint start, end;
			s.position = 4 * n;
			s.read(start);
			s.read(end);
			scope Stream ss = new SliceStream(enm, start, end);

			ubyte[] uncomp = cast(ubyte[])tocomp.decode(ss);
			scope Stream sout = getTempFile(format("btl/enm/%04d", n), FileMode.OutNew | FileMode.In);
			sout.write(uncomp);
			delete uncomp;
			{
				ubyte[32] text;
				sout.position = 0x0C;
				uint p;
				sout.read(p);
				sout.position = p;
				sout.write(text);
				sout.position = p;
				if (enemies[n].length >= 31) throw(new Exception("Too long enemy name"));
				sout.writeString(enemies[n]);
			}
		}
	}
	
	translate_events();
	translate_skills();
	
	{ scope(exit)Progress.pop; Progress.push("Reempaquetando enemigos", enemies.length);
	
		if (!FS.temp["btl/BTL_ENM.BIN"].exists) {
			scope Stream o_enm = FS.temp["btl/BTL_ENM.BIN"].open(FileMode.OutNew);

			s.position = 0;
			for (int n = 0; n < enemies.length; n++) { patch_stopPoint();
				s.write(cast(uint)o_enm.position);
				Progress.set(n, enemies.length);
				
				scope Stream enmn = getTempFile(std.string.format("btl/enm/%04d", n), FileMode.In);
				
				{
					ubyte[] data = tocomp.encode(enmn);
					o_enm.write(data);
					//std.gc.hasNoPointers(data.ptr);
					//std.gc.removeRange(data.ptr);
					delete data;					
				}
				
				// Alignment
				if ((o_enm.position % 0x800) != 0) {
					ubyte[] data; data.length = 0x800 - (o_enm.position % 0x800);
					o_enm.write(data);
				}
				
				enmn.close();
				delete enmn;
			}
			s.write(cast(uint)o_enm.position);
		}
		
		FS.gout["btl/BTL_ENM.BIN"].replace(FS.temp["btl/BTL_ENM.BIN"].open, false);
	}
}

bool isStringz(char[] d, out char[] save) {
	int s = 0;
	foreach (k, c; d) {
		switch (s) {
			case 0:
				if (c == 0) {
					save = d[0..k];
					s = 1;
				}
			break;
			case 1:
				if (c != 0) return false;
			break;
		}
	}
	return true;
}

void test_search_btem_file(int id, Stream s) {
	ubyte[] data = getStream(s);
	for (int n = 0; n < data.length; n += 4) {
		uint v = *cast(uint *)&data[n];
		switch (v) {
			//case 0x5A: // Skill normal
			//case 0xFA: // Skill2
			case 0x46: // Skill3?
			case 0xB4: // Skill4?
				if (n == 0x42C) break;
				char[] save;
				if (isStringz(cast(char[])data[n + 4..n + 4 + 32], save)) {
					if (save.length) {
						//writefln("%04d:%08X:'%s'", id, n, save);
						writefln("%04d:%08X:%s", id, n, save);
					}
				}
			break;
			default:
			break;
		}
	}
}

void test_search_btem() {
	for (int n = 0; n < 316; n++) {
		test_search_btem_file(n, getTempFile(format("btl/enm/%04d", n), FileMode.In));
	}
}

/*
Batallas con eventos:

Sin texto:
	btl/enm/0041:62880 - Caballero del Oraculo
	btl/enm/0267:9568  - Asch

Con texto:
	btl/enm/0282:44896 - Van
	btl/enm/0283:48256 - Van
	btl/enm/0284:9888  - Reina Ligre
*/

import std.c.stdlib;

void test_search_btsc() {
	void text_search(ubyte[] data) {
		for (int n = 0; n < data.length; n++) {
			if (data[n] == 0) continue;
			int s = 0;
			
			int title_s = n, title_e = n;
			int text_s = n, text_e = n;
			for (int m = n; m < data.length; m++) {
				ubyte c = data[m];
				
				switch (s) {
					case 0:
						if (c == 0) s = 1;
					break;
					case 1:
						if (data[m] != 0) {
							title_e = m;

							if ((title_e - title_s) == 0x20) {
								s = 2;
								text_s = m;
							} else{
								m = data.length;
							}
						}
					break;
					case 2:
						if (c == 0) s = 3;
					break;
					case 3:
						if (data[m] != 0) {
							text_e = m;

							if ((text_e - text_s) == 0x100) {
								printf("%08X:\n", title_s);
								printf("%s\n", cast(char *)data[title_s..title_e].ptr);
								printf("%s\n", cast(char *)data[text_s..text_e].ptr);
								printf("\n");
							} else{
								m = data.length;
							}
						}
					break;
				}
			}
		}
	}

	//for (int n = 0; n < 316; n++) {
	//foreach (n; [41, 267, 282, 283, 284]) {
	foreach (n; [284]) {
		char[] name = format("btl/enm/%04d", n);
		scope Stream f = getTempFile(name, FileMode.In);
		ubyte[] data = tocomp.getStream(f);
		int pos = std.string.find(cast(char[])data, "BTSC");
		if (pos != -1) {
			writefln("%s:%d", name, pos);
			//text_search(data[pos..data.length]);
			//text_search(data[0..data.length]);
			//text_search(data[0..data.length]);
			//text_search(data[0x102C..0x102C+0xAE88]);
			text_search(data);
		}
	}

}