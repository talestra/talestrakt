import imports;

import vfs, sb7, fps2, fps3;

void test_skit() {
	char[] base = "CHT_506";
	(new File("../GGSKIT.SKT", FileMode.OutNew)).copyFrom(getGameFile("se/" ~ base ~ ".SKT"));
	Fps3Archive fa = new Fps3Archive(decodeStream(getGameFile("se/" ~ base ~ ".SKT")));
	fa["CHTSC.SB7"].saveto("../skit1.sb7");
	SB7 sb7 = new SB7(fa["CHTSC.SB7"].open);
	
	//sb7.dumpScriptVerbose(new File("../CHTSC.SB7.TXT", FileMode.OutNew));
	
	//sb7.str_tt[sb7.str_tt.length - 1].text = "aaaaaaaaaaaa";

	// Remove japanese names
	//foreach (k, v; sb7.str_t[0]) sb7.str_t[0][k].text = "";
	
	//sb7.str_t[1][0].text = "LUKE: *Ufff*";
	//sb7.str_t[1][1].text = "LUKE: Ya que no van a sacarme,\npodrian al menos tenerme entretenido.";
	//sb7.str_t[1][3].text = "go!";
	
	foreach (t; sb7.str_tt) writeln(t.text);
	
	fa["CHTSC.SB7"].setStream(sb7.save);
	
	//fa.saveto("../MYSKIT.SKT");
	write("../test/TO7SE.CVM/" ~ base ~ ".SKT", tocomp.encode(fa.save));
	fa.saveto("../test/TO7SE.CVM/" ~ base ~ ".SKT.d");
}

void test_script_file(char[] name) {
	Stream pkbs = getGameFile("map/" ~ name);
	Stream f_pkbs = pkbs;
	try { f_pkbs = decodeStream(pkbs); } catch { }
	
	Fps2Archive fa;
	try {
		fa = new Fps2Archive(f_pkbs);
	} catch (Exception e) {
		writefln("Error opening fps2: %s", e);
		return;
	}

	//(new File("../scr.sb7", FileMode.OutNew)).copyFrom(fa["sb7"].open);

	scope SB7 sb7 = new SB7(fa["sb7"].open);
	
	sb7.header.print();
	
	Stream so = new File("../out2/" ~ name ~ ".TXT", FileMode.OutNew);
	sb7.dumpScriptVerbose(so);
	so.close();
}

void test_script2() {
	test_script_file("CAP_I06_00.PKB");
	//test_script_file("SNO_I00_00.PKB");
	//test_script_file("SNO_T03E.PKB");
	//test_script_file("YUR_I01_02.PKB");
	//test_script_file("YUR_I01_01.PKB");
	//test_script_file("_CUSTOM.PKB");
	//test_script_file("AJI_D02.PKB");
	return;

	foreach (f; listdir("../data/map/")) {
		if (f[0] == '.') continue;
		writefln(f);
		test_script_file(f);
	}
}

void test_vfs() {
	/*
	auto vfs = new FileContainer();
	vfs.mount("btl", new Directory("../test/TO7BTL.CVM"));
	Stream s = vfs["btl/demo/test"].open(FileMode.OutNew);
	*/
	FS.gout["btl/BTL_USU.BIN"].copyFrom(FS.gin["btl/BTL_USU.BIN"]);
}

char[][char[]] test_translate_script_get_table() {
	char[][char[]] translate;
	foreach (f; FS.patch["script"]) { if (!f.isFile) continue;
		//writefln(f.name);
		scope auto fo = FS.patch["script/ori/" ~ f.name].open;
		scope auto ft = FS.patch["script/" ~ f.name].open;
		auto ao = getACME(fo);
		auto at = getACME(ft);
		foreach (k; ao.keys) translate[ao[k]] = at[k];
	}
	translate = translate.rehash;
	//writefln("Length: %d", translate.length);
	return translate;
}

void test_translate_script_dump() {
	Stream z = new BufferedFile("../script_dump.txt", FileMode.OutNew);
	foreach (o, t; test_translate_script_get_table) {
		z.writeString("'" ~ std.string.replace(o, "\n", "\\n") ~ "' -> '" ~ std.string.replace(t, "\n", "\\n") ~ "'");
		z.writefln();
	}
}

void test_translate_script() {
	auto tt = test_translate_script_get_table;
	//test_translate_script_dump();
	
	void processFile(char[] base) {
		scope Stream sii = getGameFile("map/" ~ base ~ ".PKB");
		scope Stream si = new BufferedStream(sii);
		scope Stream siu = si;
		scope Fps2Archive fa;
		scope SB7 sb7;
		bool compressed = false;
		
		Stream encs = FS.patch["script2/" ~ base ~ ".txt"].open(FileMode.OutNew);
		
		try {
			try { siu = tocomp.decodeStream(si); compressed = true; } catch { }
			
			fa = new Fps2Archive(siu);
			sb7 = new SB7(fa["sb7"].open);
			
			bool first = true;
		
			foreach (count, k; sb7.str_tt) {
				auto k_text2 = k.text;
				auto k_text = strip(k.text);
				if ((k_text in tt) is null) {
					//if (k_text.length >= 7 && (k_text[0..7] == "motion:")) continue;
					/*
					if (first) {
						writefln("%s                       ", base);
						first = false;
					}
					writeln("  '" ~ replace(k_text, "\n", "\\n") ~ "'");
					*/
				} else {
					k_text = tt[k_text];
					/*
					encs.writefln("## POINTER %d", count);
					encs.writeString(tt[k_text]);
					encs.writefln();
					encs.writefln();
					*/
				}
				while (k_text2.length) {
					bool ex;
					char c = k_text2[k_text2.length - 1];
					switch (c) {
						case '\n', ' ': k_text ~= c; k_text2 = k_text2[0..k_text2.length - 1]; break;
						default: ex = true;
					}
					if (ex) break;
				}
				encs.writeString(replace(k_text, "\n", "\\n"));
				encs.writefln();
			}
				
			delete sb7;
			delete fa;
		} finally {
			if (compressed) delete (cast(MemoryStream)siu).buf;
			delete siu;
			std.gc.fullCollect();
			encs.close();
		}
	}
	
	//processFile("AJI_D00E");
	
	// CAP_I00_05.PKB
	
	//processFile("YUR_I01_01"); return;
	
	foreach (f; FS.gin["map"]) {
		if (f.name == "GRA_D00.PKB") continue;
		if (f.name == "MAP.PKF") continue;
		if (f.name == "TESTMAP.PKB") continue;
		printf("%s                 \r", std.string.toStringz(f.name));
		try {
			processFile(f.name[0..f.name.length-4]);
		} catch (Exception e) {
			writefln("error(2): %s (%s)", f.name, e.toString);
		}
		//writefln(f.name);
		//processFile("AJI_D00E");
	}
}

void test_translate_script_extract_newstr() {
	bool[char[]] list;
	
	Stream so = new File("../system.txt", FileMode.OutNew);
	
	int textCount = 0;
	
	void processFile(char[] base) {
		//so.writefln("#@-@# %s", base);
		so.writefln("#### %s", base);
		so.writefln();
	
		scope Stream sii = getGameFile("map/" ~ base ~ ".PKB");
		scope Stream si = new BufferedStream(sii);
		scope Stream siu = si;
		scope Fps2Archive fa;
		scope SB7 sb7;
		bool compressed = false;
		
		Stream encs = FS.temp["scripti/" ~ base ~ ".txt"].open(FileMode.OutNew);
		
		try {
			try { siu = tocomp.decodeStream(si); compressed = true; } catch { }
			
			fa = new Fps2Archive(siu);
			sb7 = new SB7(fa["sb7"].open);
			
			foreach (count, k; sb7.str_i) {
				encs.writeString(std.string.replace(k.text, "\n", "\\n"));
				encs.writefln();
				if (!k.text.length) continue;
				if (k.text.length >= 7 && k.text[0..7] == "motion:") continue;
				if (k.text.length > 3 && k.text[k.text.length - 4..k.text.length] == ".npc") continue;
				if (k.text.length >= 4 && k.text[0..4] == "EYE_") continue;
				if (k.text.length >= 6 && k.text[0..6] == "MOUTH_") continue;
				if ((k.text in list) is null) {
					list[k.text] = true;
					so.writef("%04d:", textCount++);
					so.writeString(replace(k.text, "\n", "\\n"));
					so.writefln();
				}
			}
				
			delete sb7;
			delete fa;
		} finally {
			if (compressed) delete (cast(MemoryStream)siu).buf;
			delete siu;
			std.gc.fullCollect();
			encs.close();
		}
	}
	
	//processFile("AJI_D00E");
	
	// CAP_I00_05.PKB
	int count;
	foreach (f; FS.gin["map"]) {
		//if (f.name != "_TITLE.PKB") continue;
		//if (f.name != "_CUSTOM.PKB") continue;
		if (f.name == "GRA_D00.PKB") continue;
		if (f.name == "MAP.PKF") continue;
		if (f.name == "TESTMAP.PKB") continue;
		
		//if (count++ >= 10) continue;
		
		printf("%s                 \r", std.string.toStringz(f.name));
		try {
			processFile(f.name[0..f.name.length-4]);
		} catch (Exception e) {
			writefln("error(2): %s (%s)", f.name, e.toString);
		}
		//writefln(f.name);
		//processFile("AJI_D00E");
	}

	/*foreach (s; list.keys.sort) {
		//so.writef("'");
		so.writeString(replace(s, "\n", "\\n"));
		//so.writef("'");
		so.writefln();
	}*/
	so.close();
}

void process_script() {
	//test_vfs();
	
	//test_script2();
	
	//test_translate_script();
	test_translate_script_extract_newstr();

	//test_script();
	//test_script2();
	//test_skit();

	//btl_enm.test_search_btem();
	//btl_enm.translate_skills();
}

void translate_skit(int n, Stream s2) {
	char[] base = format("CHT_%03d", n);
	
	//if (!FS.temp["se/" ~ base ~ ".SKT"].exists) {
		auto patch = getACME(FS.patch[format("skits/%04d.txt", n)].open(FileMode.In));
		
		Stream si = getGameFile("se/" ~ base ~ ".SKT");
		Fps3Archive fa = new Fps3Archive(decodeStream(si));
		SB7 sb7 = new SB7(fa["CHTSC.SB7"].open);

		// Borra los nombres japoneses
		//foreach (k, v; sb7.str_t[0]) sb7.str_t[0][k].text = "";
		foreach (k, v; sb7.str_tt[0..20]) sb7.str_tt[k].text = "";
		
		// Traduce textos
		foreach (k, v; patch) {
			if (k == 0) continue;
			sb7.str_tt[k].text = v;
		}
		
		s2.writeString(replace(patch[0], "\n", "\\n"));
		s2.writefln();
		
		Stream s = FS.patch[format("skits2/CHT_%03d.SKT.txt", n)].open(FileMode.OutNew);
		
		foreach (t; sb7.str_tt) {
			s.writeString(replace(t.text, "\n", "\\n"));
			s.writefln();
		}
		
		s.close();

		//fa["CHTSC.SB7"].setStream(sb7.save);
		
		//FS.gout["se/" ~ base ~ ".SKT"].replace(cast(ubyte[])tocomp.encode(fa.save));

		/*
		Stream so = FS.temp["se/" ~ base ~ ".SKT"].open(FileMode.OutNew);
		so.write(cast(ubyte[])tocomp.encode(fa.save));
		if (so.size > si.size) {
			sb7.saveto(new File("../sb7.dump", FileMode.OutNew));
			throw(new Exception(std.string.format("Skit file larger than original (%d > %d)", so.size, si.size)));
		}
		so.close();
		*/
	//}
}

void translate_skits() {
	Stream s = FS.patch["exe/skit.titles"].open(FileMode.OutNew);
	//foreach (n; [506]) {
	for (int n = 0; n <= 537; n++) {
		//Progress.set(n);
		translate_skit(n, s);
	}
	s.close();
}

import iso;

void process_mount_test() {
	Iso iso = new Iso("e:/isos/ps2/Tales of the Abyss - test.iso");

	iso.mount("npc",   new Iso(iso["TO7NPC.CVM"].open));
	iso.mount("btl",   new Iso(iso["TO7BTL.CVM"].open));
	iso.mount("ev",    new Iso(iso["TO7EV.CVM"].open));
	iso.mount("map",   new Iso(iso["TO7MAP.CVM"].open));
	iso.mount("mov",   new Iso(iso["TO7MOV.CVM"].open));
	iso.mount("bgm",   new Iso(iso["TO7BGM.CVM"].open));
	iso.mount("root",  new Iso(iso["TO7ROOT.CVM"].open));
	iso.mount("se",    new Iso(iso["TO7SE.CVM"].open));
	iso.mount("field", new Iso(iso["TO7FIELD.CVM"].open));
	
	foreach (e; iso) {
		writefln(e.name);
	}
}

void process_skit_titles() {
	Stream s = FS.patch["exe/skit.titles"].open(FileMode.OutNew);
	for (int n = 0; n <= 537; n++) {
		auto acme = getACME(FS.patch[format("_back/skits/%04d.txt", n)].open);
		s.writeString(acme[0]);
		s.writefln();
		//writeln(acme[0]);
	}
}

void extract_field_script() {
	Stream so3 = FS.patch["field/script/.ori/__single.txt"].open(FileMode.OutNew);
	
	bool[char[]] used;
	
	void process(char[] name) {
		Stream so = FS.patch["field/script/.ori/" ~ name ~ ".txt"].open(FileMode.OutNew);
		Stream so2 = FS.patch["field/script/.ori/sys/" ~ name ~ ".txt"].open(FileMode.OutNew);
		
		auto sb7 = new SB7(FS.gin["root/" ~ name].open);
		foreach (k, s; sb7.str_tt) {
			char[] ss = replace(s.text, "\n", "\\n");
			so.writeString(ss);
			so.writefln();
			if ((ss in used) is null) {
				so3.writef("%04d:'", used.length);
				so3.writeString(ss);
				so3.writefln("'");
				used[ss] = true;
			}
		}

		foreach (k, s; sb7.str_i) {
			char[] ss = replace(s.text, "\n", "\\n");
			so2.writeString(ss);
			so2.writefln();
		}
	}
	
	for (int n = 0; n < 4; n++) process(format("FIELD%02d.SB7", n));
}

void test_extract_ori_script() {
	bool[char[]] list;
	
	int textCount = 0;
	
	void processFile(char[] base) {
	
		scope Stream sii = getGameFile("map/" ~ base ~ ".PKB");
		scope Stream si = new BufferedStream(sii);
		scope Stream siu = si;
		scope Fps2Archive fa;
		scope SB7 sb7;
		bool compressed = false;
		
		Stream encs = FS.patch["script2/.ori/" ~ base ~ ".txt"].open(FileMode.OutNew);
		
		try {
			try { siu = tocomp.decodeStream(si); compressed = true; } catch { }
			
			fa = new Fps2Archive(siu);
			sb7 = new SB7(fa["sb7"].open);
			
			foreach (count, k; sb7.str_tt) {
				encs.writeString(std.string.replace(k.text, "\n", "\\n"));
				encs.writefln();
			}
				
			delete sb7;
			delete fa;
		} finally {
			if (compressed) delete (cast(MemoryStream)siu).buf;
			delete siu;
			std.gc.fullCollect();
			encs.close();
		}
	}
	
	//processFile("AJI_D00E");
	
	// CAP_I00_05.PKB
	int count;
	foreach (f; FS.gin["map"]) {
		//if (f.name != "_TITLE.PKB") continue;
		//if (f.name != "_CUSTOM.PKB") continue;
		if (f.name == "GRA_D00.PKB") continue;
		if (f.name == "MAP.PKF") continue;
		if (f.name == "TESTMAP.PKB") continue;
		
		//if (count++ >= 10) continue;
		
		printf("%s                 \r", std.string.toStringz(f.name));
		try {
			processFile(f.name[0..f.name.length-4]);
		} catch (Exception e) {
			writefln("error(2): %s (%s)", f.name, e.toString);
		}
		//writefln(f.name);
		//processFile("AJI_D00E");
	}

	/*foreach (s; list.keys.sort) {
		//so.writef("'");
		so.writeString(replace(s, "\n", "\\n"));
		//so.writef("'");
		so.writefln();
	}*/
}

void translate_field_script_make_trans_table() {
	char[][char[]] translate;
	foreach (e; FS.patch["script2/.ori"]) {
		char[] name = e.name;
		writefln(name);
		Stream s_es = new BufferedStream(FS.patch["script2/" ~ name].open);
		Stream s_en = new BufferedStream(FS.patch["script2/.ori/" ~ name].open);

		while (!s_en.eof) {
			char[] es = replace(s_es.readLine, "\\n", "\n");
			char[] en = replace(s_en.readLine, "\\n", "\n");
			translate[en] = es;
		}
		//break;
	}
	
	Stream st = FS.patch[".script.translate"].open(FileMode.OutNew);
	foreach (en, es; translate) {
		st.writeString(replace(en, "\n", "\\n"));
		st.writefln();
		st.writeString(replace(es, "\n", "\\n"));
		st.writefln();
	}
	//writefln(translate.length);
}

void translate_field_script() {
	char[][char[]] translate;
	bool[char[]] used;
	
	Stream fout = FS.patch["field/script/.ori/.translate.txt"].open(FileMode.OutNew);
	
	void processTranslate() {
		auto st = new BufferedStream(FS.patch[".script.translate"].open);
		while (!st.eof) {
			char[] en = replace(st.readLine, "\\n", "\n");
			char[] es = replace(st.readLine, "\\n", "\n");
			translate[en] = es;
		}
		translate = translate.rehash;
		//writefln(translate.length);
	}
	
	void process(char[] name) {
		auto sb7 = new SB7(FS.gin["root/" ~ name].open);
		foreach (k, s; sb7.str_tt) {
			bool translated = false;
			if (s.otext in translate) {
				s.text = translate[s.otext];
				translated = true;
			}
			
			char[] ss = replace(s.text, "\n", "\\n");

			if (!translated) {
				if ((ss in used) is null) {
					//fout.writef("%04d:'", used.length);
					fout.writeString(ss);
					//fout.writef("'");
					fout.writefln();
					used[ss] = true;
				}
			}

			/*so.writeString(ss);
			so.writefln();
			if ((ss in used) is null) {
				so3.writef("%04d:'", used.length);
				so3.writeString(ss);
				so3.writefln("'");
				used[ss] = true;
			}*/
		}
	}
	
	processTranslate();
	for (int n = 0; n < 4; n++) process(format("FIELD%02d.SB7", n));	
}

void translate_field_script_final() {
	char[][char[]] translate;
	bool[char[]] used;
	
	void processTranslate() {
		auto st = new BufferedStream(FS.patch[".script.translate"].open);
		while (!st.eof) {
			char[] en = replace(st.readLine, "\\n", "\n");
			char[] es = replace(st.readLine, "\\n", "\n");
			translate[en] = es;
		}
	}
	
	void processTranslate2() {
		auto st_en = new BufferedStream(FS.patch["field/script/.ori/.translate.txt"].open(FileMode.In));
		auto st_es = new BufferedStream(FS.patch["field/script/.translate.txt"].open(FileMode.In));
		while (!st_en.eof) {
			char[] en = replace(st_en.readLine, "\\n", "\n");
			char[] es = replace(st_es.readLine, "\\n", "\n");
			translate[en] = es;
			/*
			if (en.length < 4) continue;
			if (es.length < 4) continue;
			char[][] enl = split2(en, ":", 2);
			char[][] esl = split2(es, ":", 2);
			intFromBase(enl[]);
			if (es[4] != ':') { writefln("error ':'"); continue; }
			if (es[5] != '\'') { writefln("error ' (1)"); continue; }
			if (es[es.length - 1] != '\'') { writefln("error ' (2)"); continue; }
			*/
		}
	}
	
	void process(char[] name) {
		auto sb7 = new SB7(FS.gin["root/" ~ name].open);
		Stream so = FS.patch["field/script/" ~ name ~ ".txt"].open(FileMode.OutNew);
		foreach (k, s; sb7.str_tt) {
			bool translated = false;
			if (s.otext in translate) {
				s.text = translate[s.otext];
				translated = true;
			}
			
			char[] ss = replace(s.text, "\n", "\\n");

			so.writeString(ss);
			so.writefln();
		}
	}
	
	processTranslate();
	processTranslate2();
	translate = translate.rehash;
	for (int n = 0; n < 4; n++) process(format("FIELD%02d.SB7", n));	
}

void process() {
	//translate_skits();
	//process_mount_test();
	//process_skit_titles();
	//extract_field_script();
	//test_extract_ori_script();
	//extract_field_script();
	//translate_field_script();
	translate_field_script_final();
}

void process_swap_testmap() {
	writefln("Intercambiando testmap...");
	Iso iso = cast(Iso)((cast(MountContainer)FS.gout["map"]).proxy); iso.swap("TESTMAP.PKB", "CAP_I06_05.PKB");
	//Iso iso = cast(Iso)((cast(MountContainer)FS.gout["mov"]).proxy); iso.swap("AS_009.sfd", "AS_001.sfd");
	writefln("listo");
}