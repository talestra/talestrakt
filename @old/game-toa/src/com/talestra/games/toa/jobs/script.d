import imports;

import std.process;

char[][char[]] _system_trans;
char[][char[]] system_trans() {
	if (_system_trans.length == 0) get_system_translation_table();
	return _system_trans;
}

//version = make_only_title;

//version = using_saveto;

version = comp_all_files;

void translate_script_map(char[] base) {
	//return;
	scope Stream si = new BufferedStream(FS.gin["map/" ~ base ~ ".PKB"].open);
	scope Stream siu;
	scope Fps2Archive fa;
	scope SB7 sb7;
	bool compress = false;
	
	char[][] trans; scope(exit) delete trans;
	Stream transs = new BufferedStream(FS.patch["script2/" ~ base ~ ".txt"].open(FileMode.In)); scope (exit) { transs.close(); delete transs; }
	while (!transs.eof) {
		char[] l;
		l = strip(transs.readLine);
		l = replace(l, "\\n", "\n");
		trans ~= l;
	}
	
	ubyte[] data = getStream(si), _data; scope(exit) delete data;
	try { _data = tocomp.decode(data); delete data; data = _data; compress = true; } catch { compress = false; }
	si.close(); delete si;
	siu = new MemoryStream(data); scope(exit) { siu.close(); delete siu; }

	{
		fa  = new Fps2Archive(siu); scope(exit) delete fa;
		sb7 = new SB7(fa["sb7"].open); scope(exit) delete sb7;
		
		// Translating texts
		foreach (k, s; sb7.str_tt) s.text = trans[k];

		// Translating system
		foreach (k, s; sb7.str_i) if (s.text in system_trans) s.text = system_trans[s.text];
		
		MemoryStream sout = new MemoryStream(); scope (exit) { delete sout.buf; delete sout; }
		sb7.saveto(sout);
		fa["sb7"].setStream(sout);
		
		version (using_saveto) {
			MemoryStream sout2 = new PatchedMemoryStream();
			fa.saveto(sout2);

			Stream so = FS.temp["map/" ~ base ~ ".PKB"].open(FileMode.OutNew); scope(exit) { so.close(); }

			tocomp.encodeTo(getStream(sout2), so);
		} else {
			ubyte[] sout2 = fa.saveData; scope (exit) { delete sout2; }

			Stream so = FS.temp["map/" ~ base ~ ".PKB"].open(FileMode.OutNew); scope(exit) { so.close(); delete so; }
			version (comp_all_files) compress = true;
			if (compress) tocomp.encodeTo(sout2, so); else so.write(sout2);
		}
	}
}

void get_system_translation_table() {
	char[][char[]] system_in;
	char[][char[]] system_out;
	
	Stream s_i = FS.patch["system.in"].open;
	Stream s_o = FS.patch["system.out"].open;
	
	void readTransSYSFile(Stream s, inout char[][char[]] ss) {
		while (!s.eof) {
			char[] l = strip(s.readLine);
			if (!l.length) continue;
			if (l.length >= 5 && l[0..5] == "#### ") continue;
			auto ll = split2(l, ":", 2);
			ss[ll[0]] = replace(ll[1], "\\n", "\n");
		}
	}
	
	readTransSYSFile(s_i, system_in);
	readTransSYSFile(s_o, system_out);
	
	foreach (k; system_in.keys) if ((k in system_out) !is null) _system_trans[system_in[k]] = system_out[k];

	s_o.close();
	s_i.close();
}

void translate_script() { scope(exit)Progress.pop;Progress.push("Traduciendo script principal");
	int total = 0, count = 0;
	foreach (f; FS.gin["map"]) total++;
	
	// TITLE.PKB
	// DIS_I00_00.PKB
	// dis_t00e.pkb
	// dis_t02.pkb
	
	foreach (f; FS.gin["map"]) { patch_stopPoint();
		Progress.set(count++, total, f.name);
		switch (f.name) {
			case "SHI_D00E.PKB", "ICE_D04E.PKB", "CHP_T00E.PKB", "COK_D02.PKB", "GRA_D00.PKB", "MAP.PKF", "TESTMAP.PKB": continue;
			default: break;
		}
		version (make_only_title) {
			switch (f.name) {
				default: continue;
				case "TITLE.PKB": //break;
				case "DIS_T02.PKB":
				case "DIS_T00E.PKB":
				case "DIS_I00_00.PKB":
				if (FS.temp["map/" ~ f.name].exists) continue;
			}
		} else {
			if (FS.temp["map/" ~ f.name].exists) continue;
		}
		
		try {
			translate_script_map(f.name[0..f.name.length - 4]);
			std.gc.genCollect();
		} catch (Exception e) {
			writefln("warning(2): %s (%s)", f.name, e.toString);
		}
	}
}

void copy_extra() { scope(exit)Progress.pop;Progress.push("Copiando archivos extra");
	version (make_only_title) {
		FS.temp["map/MAP.PKF"].copyFrom(FS.gin["map/MAP.PKF"]);
		//FS.temp["map/DIS_T02.PKB"].copyFrom(FS.gin["map/DIS_T02.PKB"]);
	} else {
		int count = 0;
		foreach (f; FS.gin["map"]) { patch_stopPoint();
			auto ff = FS.temp["map/" ~ f.name];
			if (ff.exists) continue;
			Progress.set(count++, 10, f.name);
			ff.copyFrom(f);
		}
		version (comp_all_files) {
		} else {
			FS.temp["map/TESTMAP.PKB"].open(FileMode.OutNew).close();
		}
	}
}

void update_iso() { scope(exit)Progress.pop;Progress.push("Actualizando mapas en iso");
	//version (make_only_title) return;
	FS.gout["map"].regen(FS.temp["map"], delegate int(char[] name, int pos_cur, int pos_len, long pos, long total, bool error) {
		if (error) {
			printf("\nregen [%-16s] ", toStringz(name));
			printf("error\n\n");
		} else {
			/*
			printf("(%3.2f/%.2f)\r",
				cast(float)((cast(real)pos) / 1024 / 1024),
				cast(float)((cast(real)total) / 1024 / 1024)
			);
			*/
		}
		Progress.set(pos_cur, pos_len, name);
		return false;
	});
}

void process() {
	translate_script();
	copy_extra();
	update_iso();
}