import imports;

void translate_skit(int n) {
	char[] base = format("CHT_%03d", n);
	
	if (FS.temp["se/" ~ base ~ ".SKT"].exists) return;
	
	//auto patch = getACME(FS.patch[format("skits/%04d.txt", n)].open(FileMode.In));
	
	Stream si = FS.gin[format("se/%s.SKT", base)].open; scope(exit) { si.close(); delete si; }
	ubyte[] skit_data = decode(si); scope(exit) delete skit_data;
	Stream siu = new MemoryStream(skit_data); scope(exit) { delete siu; }
	Fps3Archive fa = new Fps3Archive(siu);
	SB7 sb7 = new SB7(fa["CHTSC.SB7"].open); scope(exit) delete sb7;

	Stream patch = FS.patch[format("skits2/CHT_%03d.SKT.txt", n)].open(FileMode.In);
	int k = 0;
	while (!patch.eof) {
		char[] l = patch.readLine;
		l = std.string.replace(l, "\\n", "\n");
		if (k < sb7.str_tt.length) sb7.str_tt[k].text = l;
		k++;
	}
	patch.close();

	MemoryStream ms_sb7 = cast(MemoryStream)sb7.save;
	fa["CHTSC.SB7"].setStream(ms_sb7);
	
	MemoryStream ms = cast(MemoryStream)fa.save;
	Stream so = FS.temp["se/" ~ base ~ ".SKT"].open(FileMode.OutNew); scope(exit) { so.close(); delete so; }
	tocomp.encodeTo(ms.buf[0..ms.size], so);
	
	delete ms.buf;
	delete ms;
	delete ms_sb7.buf;
	delete ms_sb7;
	
	if (so.size > si.size) {
		sb7.saveto(new File("sb7.dump", FileMode.OutNew));
		throw(new Exception(std.string.format("Skit file larger than original (%d > %d)", so.size, si.size)));
	}
	
	so.close();
	
	Stream so2 = FS.temp["se/" ~ base ~ ".SKT"].open; scope(exit) { so2.close(); delete so2; }
	FS.gout["se/" ~ base ~ ".SKT"].replace(so2);
}

void process() { scope(exit)Progress.pop;Progress.push("Traduciendo skits", 538);
	//foreach (n; [506]) {
	for (int n = 0; n <= 537; n++) { patch_stopPoint();
		Progress.set(n);
		translate_skit(n);
		std.gc.genCollect();
	}
}