import imports;

import btl_common;

void unpack() { scope(exit)Progress.pop;Progress.push("Extrayendo BTL_USU");
	auto l = getSimplePTRSIZE(getGameFile("btl/BTL_USU.BIN"));
	Stream sl;
	char[] name;
	
	foreach (k, c; l) {
		Progress.set(k, l.length);
		name = format("btl/usu/%04d", k);
		char[] name2 = format("btl/usu/%04d_u", k);
		
		if (existsTempFile(name)) continue;
		
		//writefln("%02d: %08X", k, c.ptr);
		Stream s = getTempFile(name, FileMode.OutNew);
		s.copyFrom(c.s);
		s.close();
		
		/*if (!existsTempFile(name2)) {
			try {
				ubyte[] data = cast(ubyte[])tocomp.decode(getTempFile(name, FileMode.In));
				Stream s2 = getTempFile(name2, FileMode.OutNew);
				s2.write(data);
				s2.close();
			} catch (Exception e) {
				//writefln(e);
			}
		}*/
	}
	
	l = getSimplePTRSIZE(new MemoryStream(cast(ubyte[])tocomp.decode(sl = getTempFile("btl/usu/0000", FileMode.In))));
	
	foreach (k, c; l) {
		Progress.set(k, l.length);
		name = format("btl/usu/0000/%04d", k);
		if (existsTempFile(name)) continue;
		//writefln("%02d: %08X", k, c.ptr);
		Stream s = getTempFile(name, FileMode.OutNew);
		s.copyFrom(c.s);
		s.close();
	}	
	sl.close();
	
	l = getSimplePTRSIZE(sl = getTempFile("btl/usu/0014", FileMode.In));
	
	foreach (k, c; l) {
		Progress.set(k, l.length);
		name = format("btl/usu/0014/%04d", k);
		if (existsTempFile(name)) continue;
		//writefln("%02d: %08X", k, c.ptr);
		Stream s = getTempFile(name, FileMode.OutNew);
		s.copyFrom(c.s);
		s.close();
	}
	sl.close();
}

void repackBTSC() { scope(exit)Progress.pop;Progress.push("Reempaquetando BTSC", 12);
	Stream[] ss; Stream s;
	for (int n = 0; n < 10; n++) {
		Progress.set(n);
		ss ~= getTempFile(format("btl/usu/0014/%04d", n), FileMode.In);
	}
	Progress.set(10);
	setSimplePTRSIZE(s = getTempFile("btl/usu/0014"), ss);
	Progress.set(11);
	
	s.close(); foreach (_s; ss) _s.close();
}

void repack() { scope(exit)Progress.pop;Progress.push("Reempaquetando fichero de batalla", 3);

	Progress.set(0); repackBTSC();

	Stream[] ss;
	Stream s;
	
	void cleanStreams() {
		s.close(); foreach (_s; ss) _s.close();
		ss = [];
	}
	
	Progress.set(1);
	
	for (int n = 0; n < 4; n++) ss ~= getTempFile(format("btl/usu/0000/%04d", n), FileMode.In);
	Stream s2 = new MemoryStream();
	setSimplePTRSIZE(s2, ss);
	s2.position = 0;
	s = getTempFile("btl/usu/0000");
	s.write(cast(ubyte[])tocomp.encode(s2));
	s2.close();
	cleanStreams();
	
	Progress.set(2);
	
	for (int n = 0; n < 21; n++) ss ~= getTempFile(format("btl/usu/%04d", n), FileMode.In);
	Stream bt_usu_s = FS.temp["btl/BTL_USU.BIN"].open(FileMode.OutNew);
	setSimplePTRSIZE(bt_usu_s, ss);
	cleanStreams();
	bt_usu_s.close();
	
	Progress.set(3);
	
	FS.gout["btl/BTL_USU.BIN"].replace(FS.temp["btl/BTL_USU.BIN"].open, false);

	// TEMP
	//copy2(getTempFile("btl/usu", FileMode.In), "../test/TO7BTL.CVM/BTL_USU.BIN");
}

void translate_btsc() { scope(exit)Progress.pop;Progress.push("Traduciendo scripts de batalla");
	foreach (n, id; [2, 3, 5]) {
		Progress.set(n, 3);
		char[] pname = format("btl/usu/14/%d", id);
		scope Stream sout = getTempFile(format("btl/usu/0014/%04d", id), FileMode.Out | FileMode.In);
		scope Stream ps = getPatchFile(pname);
		auto te = getBTSC(cast(char[])getStream(ps));
		int poscount = 0;
		
		foreach (k, v; te) {
			Progress.set(poscount++, te.length);
			sout.position = k;
			sout.write(BTSCT_encode(v));
		}
		
		sout.close();
		ps.close();
	}
}

void translate_btim() { scope(exit)Progress.pop;Progress.push("Traduciendo imágenes de batalla batalla");
	Stream i = getPatchFile("btl/usu/2.tm2");
	Stream o = getTempFile("btl/usu/0000/0002");
	o.copyFrom(i);
	o.close();
	i.close();
}

void translate_ep39() { scope(exit)Progress.pop;Progress.push("Traduciendo batalla final");
	foreach (f; FS.patch["btl/ep039"]) { char[] base = f.name[0..f.name.length - 4];
		auto te = getBTSC(cast(char[])getStream(f.open));
		Stream sout = FS.gout["btl/" ~ base].open(FileMode.Out | FileMode.In);
		int poscount = 0;
		
		foreach (k, v; te) {
			Progress.set(poscount++, te.length);
			sout.position = k;
			sout.write(BTSCT_encode(v));
		}
		sout.close();
	}
}

void translate() { scope(exit)Progress.pop;Progress.push("Traduciendo archivos comunes de batalla");
	translate_btsc();
	translate_btim();
	translate_ep39();
}

/*
00: 00000060 | Images
01: 000185E0 | 
02: 0001E160 | 
03: 0002F220 | 
04: 000321A0 | 
05: 00036D60 | 
06: 00085860 | 
07: 00094FE0 | 
08: 0009CD20 | 
09: 000E7720 | 
10: 000E7920 | BTL_ENM.BIN pointers
11: 000E7E20 | 
12: 000E84A0 | 
13: 000E8760 | 
14: 000E8B60 | misc BTSC (BaTtle SCript)
15: 000F7F60 | 
16: 000F7FA0 | 
17: 000FB560 | 
18: 000FC520 | 
19: 000FC620 | 
20: 000FCB20 | 
*/