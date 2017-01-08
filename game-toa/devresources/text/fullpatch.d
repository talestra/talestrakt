import std.stdio, std.stream, std.file, std.string, std.date, std.conv, std.process;
import tales.util.gameformat, tales.common;
import tales.scont.generic, tales.scont.iso, tales.scont.fps2, tales.scont.fps3;
import tales.isopath, tales.comp, tales.sb7, sqlite3;
import tales.util.rangelist;

void makedir(char[] name) {
	try { mkdir(name); } catch (Exception e) { }
}

void copyStreamToFile(Stream s, char[] file) {
	File f = new File(file, FileMode.OutNew);
	copyStream(s, f);
	f.close();	
}

const uint maxskits = 538;
const uint maxjournal = 114;
const int EXE_DISP = (0x100000 - 0x100);

void ExePatch() {
	File exe;
	
	int mem2file(int addr) { return addr - EXE_DISP; }
	
	void UpdateSkitTitles() {
		char[][] GetSkitTitlesFromSRC() {
			char[][] r;
			
			for (int n = 0; n < maxskits; n++) {
				auto cs = GetTextPointers(new File(format("SKT/SRC/%04d.txt", n), FileMode.In));
				r ~= cs[0];
			}
		
			return r;
		}		
		
		char[][] titles = GetSkitTitlesFromSRC();
	
		const uint ptpos = 0x43A4A4, tbpos = 0x47D728, tblen = 0x5AB0, foff = 0xfff00, stlen = 0x1C;
		GameFormatString gfs = new TOAGameFormatString();
		RangeList rl = new RangeList();
		ubyte c = 0;
	
		// Comprobamos que el stream sea correcto
		if (!exe) throw(new Exception(format("Error with stream (0x%08X)", cast(uint)cast(void *)exe)));
	
		// Limpiamos el exe
		exe.position = tbpos; for (int n = 0; n < tblen; n++) exe.write(c);
	
		// Añadimos el rango de texto
		rl.add(tbpos, tblen);
	
		// Colocamos el padding del RangeList a 2
		rl.padding = 2;
	
		// Nos recorremos todos los títulos
		foreach (i, k; titles) {
			uint titlepos, skitpos;
			char[] title = gfs.encodeString(k) ~ "\0";
			char[] skit  = std.string.format("CHT_%03d.SKT\0", i);
			if (i >= maxskits) throw(new Exception("Mas skits de los que hay"));
	
			// Escribimos el título en una posición vacía
			titlepos = rl.getAndUse(title.length);
			exe.position = titlepos;
			exe.writeExact(title.ptr, title.length);
	
			// Escribimos el fichero en una posición vacía
			skitpos  = rl.getAndUse(skit.length );
			exe.position = skitpos;
			exe.writeExact(skit.ptr, skit.length);
	
			// Escribimos los punteros del título y el fichero en la tabla de estructura
			exe.position = ptpos + (stlen * i);
			exe.write(cast(uint)(titlepos + foff));
			exe.write(cast(uint)(skitpos  + foff));
		}
	}
	
	void UpdateSynopsis() {
		Stream s = exe;
		RangeList rl = new RangeList();
	
		void addRange(int from, int to) {
			int length = to - from;
			rl.add(from, length);
			s.position = from - EXE_DISP;
			ubyte[] temp;
			temp.length = length;
			for (int n = 0; n < temp.length; n++) temp[n] = '\xFF';
			s.write(temp);
		}
	
		// Bloque: 0x005838D0-0x005B64D0
		addRange(0x005838D0, 0x005838E8);
		addRange(0x005838F8, 0x00583D80);
		addRange(0x00583D90, 0x005B64D0);		
		
		char[][int][int] listdata;
		//char[][][] listdata;
	
		for (int n = 0; n < 114; n++) {
			char[] data = cast(char[])read(std.string.format("SYN/SRC/%04d.txt", n));
			char[][] list = std.string.split(data, "## POINTER ");
	
			for (int m = 1; m < list.length; m++) {
				char[] clist = list[m];
				if (auto mm = std.regexp.search(clist, "^\\d+")) {
					int z = toInt(mm.match(0));
					char[] str = "";
					
					int pos = std.string.find(clist, "\n");
						
					str = (pos == -1) ? "" : std.string.stripr(clist[pos + 1..clist.length]);
					
					listdata[n][m - 1] ~= std.string.replace(str, "\r", "");
				}
			}
		}
	
		for (int n = 0; n < maxjournal; n++) {
			char[] string;
			uint structptr, temp;
			s.position = 0x005406D0 - EXE_DISP + 4 * n;
			s.read(structptr);
			s.position = structptr - EXE_DISP;
	
			// Title
			if (true) {
				string = listdata[n][0] ~ "\0";
				s.write(temp = rl.getAndUse(string.length));
				s.position = temp - EXE_DISP;
				s.writeString(string);
			}
	
			s.position = structptr - EXE_DISP + 8;
	
			// Body list
			if (true) {
				int m = 1;
				while (true) {
					s.read(temp);
					if (temp != 0x5838E8) break;
	
					string = listdata[n][m] ~ "\0";
					
					//printf("%s\n", toStringz(string));
	
					s.seek(3 * 4, SeekPos.Current);
					uint pback = s.position + 4;
					s.write(temp = rl.getAndUse(string.length));
					s.position = temp - EXE_DISP;
					s.writeString(string);
					s.position = pback;
					m++;
				}
			}
		}		
	}
	
	void reinsertPoiner32List(char[] file) {
		Stream inp = new File(file);
		RangeList rl = new RangeList();
		char[][] r;
		bool ignoring = false;
		int[][char[]] textl;
		
		while (!inp.eof) {
			char[] line = std.string.stripl(inp.readLine());
			if (!std.string.stripr(line).length) continue;
			
			if (ignoring) {
				if (line[0] == '*') ignoring = false;			
				continue;
			}		
				
			switch (line[0]) {
				case 'R': // Añadimos un rango
					r = std.string.split(std.string.split(line, ":")[1], "-");
					uint start = getdhvalue(r[0]);
					uint end   = getdhvalue(r[1]);
					rl.add(start, end - start);				
					ubyte[] temp; temp.length = end - start;
					exe.position = mem2file(start);
					version (writeexe) exe.write(temp);
					//printf("[%08X-%08X]\n", start, end);
				break;
				case 'T':
					char[] r2 = line[2..line.length];
					int p = std.string.find(r2, ":");
					uint[] addrl;
					char[] addr = r2[0..p];
					
					foreach (caddr; std.string.split(addr, ",")) addrl ~= getdhvalue(caddr);
					
					char[] ss = r2[p + 1..r2.length];
					char[] s = stripcslashes(ss) ~ "\0";
	
					if ((s in textl) is null) textl[s] = [];
					
					foreach (caddr; addrl) textl[s] ~= caddr;
					
					//printf("  '%s'\n", toStringz(ss));
				break;
				case '#':
					//printf("  %s\n", toStringz(line));
				break;
				case '/':
					ignoring = true;
				break;
				default:
					//printf("Skipping: %s\n", toStringz(line));
				break;
			}
		}
		
		foreach (s, pl; textl) {
			// Reservamos el espacio para la cadena
			uint pos = rl.getAndUse(s.length);
			
			// Escribimos la cadena
			exe.position = mem2file(pos);
			exe.writeString(s);
			
			// Actualizamos todos los punteros de la cadena
			foreach (p; pl) {
				exe.position = mem2file(p);
				exe.write(pos);
			}
		}
	}	
	
	ubyte[][int] patches;
	patches[0x00339B14] = cast(ubyte[])x"640011341a001102108800002D208002bc9f0d0c122800000a0012341a00320212880000109000003800010400000000";
	patches[0x00380FA0] = cast(ubyte[])x"5b00013c70b1243420208500000084800000844420008046a03f023c000882440800e00302000146";
	patches[0x005BB170] = cast(ubyte[])read("../font/_FONTB.WIDTH");	
	patches[0x0057ABD8] = cast(ubyte[])"toaend_es.txt";
	
	exe = new File("TO7/SLUS_213.86", FileMode.In | FileMode.Out);
	{
		foreach (k, v; patches) {
			exe.position = mem2file(k);
			exe.write(v);
		}
	}
	
	UpdateSkitTitles();
	UpdateSynopsis();
	reinsertPoiner32List("misc/actionlist.txt");
	
	exe.close();
}

void CreateScript() {
	bool doDebug = false;
	//bool doDebug = false;
	
	Sqlite3 db = new Sqlite3("SCR/translation.db");

	writefln("Starting...");
	
	//char[] id = "CAP_I06_02";
	
	//Fps2Archive fps2 = new Fps2Archive(new File(std.string.format("PKB/%s.FS2", id))); fps2.saveto(std.string.format("mod/%s.FS2.MOD", id)); return 0;

	int i = 0, clean = 0;
	foreach (e; isomap) { std.gc.fullCollect();
		char[] id;
		if (!e.isFile) continue;
		id = e.name[0..e.name.length - 4];
		//writefln(id);
		
		if (id == "CHP_T00E") continue;
		if (id == "COK_D02") continue;
		if (id == "ICE_D04E") continue;
		if (id == "MAP") continue;
		if (id == "SHI_D00E") continue;
			
		char[] oname = "TO7/MAP/" ~ id ~ ".PKB";
		
		if (std.file.exists(oname) && (std.file.getSize(oname) != 0)) continue;

		writef("%s...", id);
		
		void doEntry() {
			if (doDebug) printf("[1]");
			
			Stream fps2s;
			Stream cpkb = isomap[std.string.format("%s.PKB", id)].open;
			ubyte type;
			cpkb.read(type);
			cpkb.position = 0;
			
			if (doDebug) printf("[2]");
			
			if (true) {
				try { std.file.remove("TO7/TEMP"); } catch (Exception e) { }
				try { std.file.remove("TO7/TEMP2"); }  catch (Exception e) { }

				File t = new File("TO7/TEMP2", FileMode.OutNew);
				t.copyFrom(cpkb);
				t.close();
				delete t;

				ubyte[] input = cast(ubyte[])read("TO7/TEMP2");
				ubyte[] output;
				
				try {
					output = cast(ubyte[])DecodeBuffer(input);				
				} catch (Exception e) {
					output = input;
				}

				write("TO7/TEMP", output);
				
				std.file.remove("TO7/TEMP2");
				
				delete input;
				delete output;
				
				fps2s = new File("TO7/TEMP", FileMode.In);
			}

			/*if (external) {
				try { std.file.remove("TO7/TEMP"); } catch (Exception e) { }
				try { std.file.remove("TO7/TEMP2"); }  catch (Exception e) { }
				
				File t = new File("TO7/TEMP", FileMode.OutNew);
				t.copyFrom(cpkb);
				t.close();
				delete t;
				
				if (type < 5) {
					std.file.rename("TO7/TEMP", "TO7/TEMP2");
					std.process.system("comptoe.exe -s -d TO7\\TEMP2 TO7\\TEMP");
					std.file.remove("TO7/TEMP2");
				}
				
				fps2s = new File("TO7/TEMP", FileMode.In);
				
				//std.c.stdlib.exit(-1);
			} else {
				fps2s = (type < 5) ? (new CompressedStream(cpkb)) : cpkb;
			}*/
				
			if (doDebug) printf("[3]");
	
			Fps2Archive fps2 = new Fps2Archive(fps2s);
			
			if (doDebug) printf("[4]");
			
			Stream sb7s, sb7sn;
			
			foreach (_e; fps2) { Fps2Entry e = cast(Fps2Entry)_e;
				if (e.type != "sb7") continue;
					
				if (doDebug) printf("[a]");
	
				auto result = db.query("SELECT e.pid,t.t2 FROM entries AS e LEFT JOIN texts AS t ON (e.tid=t.id) WHERE e.fid=(SELECT id FROM files WHERE name=?) ORDER BY e.pid ASC;", [id]);
				
				if (doDebug) printf("[b]");
	
				sb7s = e.open;
				sb7sn = new MemoryStream();
				sb7sn.copyFrom(sb7s);
				SB7 sb7 = new SB7(sb7s);
				sb7s.position = 0;
				
				if (doDebug) printf("[c]");
	
				while (result.more) {
					sb7.list[result.getInt32(0)].text = result.getText(1);
					result.step();
				}
				
				if (doDebug) printf("[d]");
	
				sb7.update(sb7sn);
				e.setStream(sb7sn);
				//(new File("test.sb7", FileMode.OutNew)).copyFrom(sb7sn);
				
				if (doDebug) printf("[e]");
			}
			
			if (doDebug) printf("[5]");
	
			makedir("TO7/MAP");
			
			/*if (external) {
				File t = new File("TO7/TEMP2", FileMode.OutNew);
				fps2.saveto(t);
				t.close();
				delete t;
				std.process.system("comptoe.exe -s -c3 TO7\\TEMP2 " ~ oname);
				std.file.remove("TO7/TEMP2");
			} else {
				Stream dump = new CompressStream(new File(oname, FileMode.OutNew));
				fps2.saveto(dump);
				dump.close();
				delete dump;
			}*/
			
			if (true) {
				ubyte[] input = cast(ubyte[])read("TO7\\TEMP2");
				ubyte[] output;
				
				try {
					output = cast(ubyte[])DecodeBuffer(input);				
				} catch (Exception e) {
					output = input;
				}

				write(oname, output);
				
				delete input;
				delete output;			
			}
			
			if (doDebug) printf("[6]");
						
			delete fps2;
			fps2s.close(); delete sb7s;
			delete sb7sn;
			
			cpkb.close();
			
			try { delete cpkb; } catch (Exception e) { }
			try { delete fps2s; } catch (Exception e) { }
			
			if (doDebug) printf("[7]");
				
			std.gc.genCollect();
		}
		
		doEntry();
		
		if (clean++ >= 10) {
			//CompressionCleanup();
			clean = 0;
		}
		
		if (doDebug) printf("[10]");

		if (doDebug) {
			printf("Ok\n");
		} else {
			printf("Ok\t\t\r");
		}
		
		//break;
	}	
	printf("\n");
}

void UpdateSkitText() {
	for (int n = 0; n < maxskits; n++, printf("Ok\t\t\r", n)) {
		printf("CHT_%03d.SKT...", n);		
		
		char[] oname = std.string.format("TO7/SE/CHT_%03d.SKT", n);		
		if (std.file.exists(oname) && (std.file.getSize(oname) != 0)) continue;
			
		Stream skit = isose[std.string.format("CHT_%03d.SKT", n)].open;
		
		CompressedStream cs = new CompressedStream(skit);
		
		//(new File("fps3", FileMode.OutNew)).copyFrom(cs);

		Fps3Archive fps = new Fps3Archive(cs);

		Stream CHTSC_SB7 = fps["CHTSC.SB7"].open;
		//fps.list;

		//(new File("sb7", FileMode.OutNew)).copyFrom(CHTSC_SB7);

		version(test) {
			RangeList rl  = GetSB7Space(CHTSC_SB7);
			char[][] strl = GetSB7Text (CHTSC_SB7);
		} else {
			SB7 sb7 = new SB7(CHTSC_SB7);
		}

		char[][int] strt;

		{
			File src = new File(format("SKT/SRC/%04d.txt", n), FileMode.In);
			strt = GetTextPointers(src);
			if (0 in strt) strt.remove(0);
			src.close();
			delete src;
		}
				
		foreach (k, v; strt) {			
			version (test) {
				//if (k >= strt.length) { fwritefln(stderr, "Posicion superada"); continue; }
				strl[k] = v;
			} else {
				if (k >= sb7.list.length) { fwritefln(stderr, "Posicion superada"); continue; }
				sb7.list[k].text = v;
			}
		}

		version (test) {
			rl.add(rl.getLastPosition, 0x80);
		}

		Stream newsb7 = new MemoryStream();
		CHTSC_SB7.position = 0; newsb7.copyFrom(CHTSC_SB7);
		CHTSC_SB7.position = 0;
		
		version (test) {
			UpdateSB7(newsb7, rl, strl);
		} else {
			sb7.update(newsb7);
		}

		(cast(Fps3Entry)fps["CHTSC.SB7"]).setStream(newsb7);

		File cdump = new File(oname, FileMode.OutNew);

		cdump.position = 0;
		
		CompressStream csnew = new CompressStream(cdump);
		fps.saveto(csnew);
		csnew.close();
		
		cdump.close();
		
		delete cdump;
		delete csnew;
		delete fps;
		delete cs;
		delete skit;		
		//break;
	}
	//printf("\r\t\t\t\r\n");
}

void BattleTranslate(char[] path) {
	char[] fname = path ~ "/BTL_USU.BIN";
	Stream btlusu;
	if (!std.file.exists(fname)) throw(new Exception(std.string.format("No existe el fichero '%s'", fname)));
	btlusu = new File(fname, FileMode.In | FileMode.Out);
	
	Stream getBtlImageStream() {
		uint start, end;
		
		btlusu.position = 4;
		btlusu.read(start);
		btlusu.read(end);
		
		return new SliceStream(btlusu, start, end);	
	}
	
	Stream getBTSC(int n) {	
		uint start, end;
		
		btlusu.position = 15 * 4;
		btlusu.read(start);
		btlusu.read(end);
		
		Stream btscll = new SliceStream(btlusu, start, end);
		
		btscll.position = 4 + n * 4;
		btscll.read(start);
		btscll.read(end);
		
		return new SliceStream(btscll, start, end);
	}

	Sqlite3 db;
	
	void ReinsertText() {
		ubyte clear[0x100 + 0x20];
		TOAGameFormatString fs = new TOAGameFormatString();
		
		db = new Sqlite3("btl/btsc.db");
		
		Sqlite3Result dids;
		
		void patchResult(Stream s, Sqlite3Result res) {
			foreach (row; res) {
				int pos = res.getInt32(0);
				//printf("  %04X\n", pos);
				s.position = pos; s.write(clear);
				s.position = pos + 0x000; s.writeString(fs.encodeString(
					std.string.replace(res.getText(1), "\r", "")
				));
				s.position = pos + 0x020; s.writeString(fs.encodeString(
					std.string.replace(res.getText(2), "\r", "")
				));
			}		
		}
		
		if (true) {
			for (dids = db.query("SELECT DISTINCT sid FROM texts WHERE file=?;", ["BTL_USU.BIN"]); dids.more; dids.next()) {
				int id = dids.getInt32(0);
				
				//printf("%d\n", id);
				
				Stream s = getBTSC(id);
				
				//writefln("  Available: %d", s.available);
				
				//writefln("ID:", id);
				
				auto res = db.query("SELECT sptr,title,text FROM texts WHERE sid=? AND file=?;", [std.string.format(id), "BTL_USU.BIN"]);
				patchResult(s, res);
			}
		}
		
		if (true) {
			for (dids = db.query("SELECT DISTINCT file FROM texts WHERE file!=?;", ["BTL_USU.BIN"]); dids.more; dids.next()) {
				auto file = dids.getText(0);
				Stream s = new File(path ~ "/" ~ file, FileMode.In | FileMode.Out);
		
				auto res = db.query("SELECT sptr,title,text FROM texts WHERE file=?;", [file]);
				patchResult(s, res);
				
				s.close();
			}
		}
	}
	
	void ReinsertImage() {
		int count = 4;
		int header;
		
		Stream s = new CompressStream(getBtlImageStream());
		
		s.position = 0;
		s.write(count);
		for (int n = 0; n < count; n++) {
			s.write(cast(int)0);
		}
		
		while ((s.position % 0x20) != 0) s.write('\xFE');
		
		//s.position = (header = 4 + count * 4);
		for (int n = 0; n < count; n++) {
			Stream f;
			
			//printf("  %d\n", n);
			
			if (n == 2) {
				f = new File("btl/2.mod.tm2");
			} else {
				if (n == 4) {
					f = new MemoryStream();
					f.writeString(x"0D0A0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000");
					f.position = 0;
				} else {
					f = new File(std.string.format("btl/%d.tm2", n));
				}
			}
			
			//f = new File(std.string.format("btl/%d.tm2", n));
			
			uint bpos = s.position;
			s.position = 4 + n * 4;
			s.write(bpos);
			s.position = bpos;
			s.copyFrom(f);
		}
		
		//printf("  finalizando...");
		
		s.close();
		
		printf("Ok\n");
		
		//new CompressStream();
	}
	
	//printf("ReinsertText...\n");
	ReinsertText();
	//printf("ReinsertImage...\n");
	ReinsertImage();
}

Iso jiso, jisoev, jisose, jisoroot;
bool jtest = false;

int main(char[][] args) {
	printf("Iniciando...");	
	
	AbyssInitIsoPath();
	
	if (jtest) {
		jiso   = new Iso("L:\\Isos\\ps2\\Tales of the Abyss - JAP.iso", true);
		jisoev = new Iso(jiso["TO7EV.CVM" ].open);
		jisose = new Iso(jiso["TO7SE.CVM" ].open);
		jisoroot = new Iso(jiso["TO7ROOT.CVM" ].open);
	}
	
	printf("Ok\n");
	
	printf("Extrayendo y parcheando EXE...");	
	
	if (!std.file.exists("TO7/SLUS_213.86")) {						
	//if (true) {
		makedir("TO7");
		copyStreamToFile(iso["SLUS_213.86"].open, "TO7/SLUS_213.86");
		//ExePatch();
		
		printf("Ok\n");
	} else {
		printf("Evitado\n");
	}
	
	//return 0;
	
	printf("Extrayendo, parcheando y generando TO7ROOT...");
	
	if (!std.file.exists("TO7/TO7ROOT.iso")) {
		makedir("TO7/ROOT");
		
		if (jtest) {			
			copyStreamToFile(jisoroot["OV_PDVD_SKIT.OVL"].open, "TO7/ROOT/OV_PDVD_SKIT_US.OVL");
		}
		
		foreach (e; isoroot) {
			if (!e.name.length) continue;
			char[] fname = std.string.format("TO7/ROOT/", e.name);
			if (std.file.exists(fname)) continue;
			//writefln("%s", fname);
			copyStreamToFile(e.open, fname);
		}
		
		// Creditos del final
		copy("end/TOAEND_ES.TXT", "TO7/ROOT/TOAEND_ES.TXT");
		
		// Tablas
		copy("dat/_ACS_.es.DAT", "TO7/ROOT/_ACS_.DAT");
		copy("dat/_SLTSKL_.es.DAT", "TO7/ROOT/_SLTSKL_.DAT");
		copy("dat/_SP_.es.DAT", "TO7/ROOT/_SP_.DAT");
		copy("dat/_I_.es.DAT", "TO7/ROOT/_I_.DAT");
		copy("dat/_STG_.es.DAT", "TO7/ROOT/_STG_.DAT");
		
		// Imagenes
		copy("../images/S_NAMCOLOGO/S_NAMCOLOGO.tm2", "TO7/ROOT/S_NAMCOLOGO.tm2");
		copy("../images/S_TOA_LOGO/S_TOA_LOGO.tm2", "TO7/ROOT/S_TOA_LOGO.tm2");
		copy("../images/_S_MENU/_S_MENU.tm2", "TO7/ROOT/_S_MENU.tm2");		
		
		// Nueva fuente
		copy("../font/_FONTB.tm2", "TO7/ROOT/_FONTB.tm2");
		
		system("mkisofs.exe -quiet -full-iso9660-filenames -o TO7\\TO7ROOT.iso TO7\\ROOT");
		
		printf("Ok\n");
	} else {
		printf("Evitado\n");
	}
	
	printf("Extrayendo, parcheando y generando TO7BTL...");
	
	//if (true) {
	if (!std.file.exists("TO7/TO7BTL.iso")) {
		makedir("TO7/BTL");
		
		foreach (e; isobtl) {
			if (!e.name.length) continue;
			char[] fname = std.string.format("TO7/BTL/", e.name);
			if (std.file.exists(fname)) continue;
			//writefln("%s", fname);			
			copyStreamToFile(e.open, fname);
		}
		
		BattleTranslate("TO7/BTL/");
		//copy("../BTL_USU.BIN", "TO7/BTL/BTL_USU.BIN");
		
		system("mkisofs.exe -quiet -full-iso9660-filenames -o TO7\\TO7BTL.iso TO7\\BTL");
		
		printf("Ok\n");
	} else {
		printf("Evitado\n");
	}
	
	//return 0;
	
	printf("Extrayendo, parcheando y generando TO7MAP...");
	if (!std.file.exists("TO7/TO7MAP.iso")) {
		makedir("TO7/MAP");
		
		copyStreamToFile(isomap["MAP.PKF"].open, "TO7/MAP/MAP.PKF");		
		CreateScript();
		system("mkisofs.exe -quiet -full-iso9660-filenames -o TO7\\TO7MAP.iso TO7\\MAP");
		
		//copyStreamToFile(isomap["MAP.PKF"].open, "SCR/MOD/MAP.PKF");				
		//system("mkisofs.exe -quiet -full-iso9660-filenames -o TO7\\TO7MAP.iso SCR\\MOD");
		
		printf("Ok\n");
	} else {
		printf("Evitado\n");
	}

	printf("Extrayendo, parcheando y generando TO7SE...");
	if (!std.file.exists("TO7/TO7SE.iso")) {
		makedir("TO7/SE");
		
		foreach (e; jtest ? jisose : isose) {
			if (!e.name.length) continue;
			char[] fname = std.string.format("TO7/SE/", e.name);
			if (std.file.exists(fname)) continue;
			if (e.name.length > 4 && e.name[0..4] == "CHT_") continue;
			//writefln("%s", fname);
			copyStreamToFile(e.open, fname);
		}

		if (!jtest) {
			UpdateSkitText();
		} else {
			foreach (e; jisose) {
				if (e.name.length > 4 && e.name[0..4] == "CHT_") {
					if (!e.name.length) continue;
					char[] fname = std.string.format("TO7/SE/", e.name);
					if (std.file.exists(fname)) continue;
					if (e.name.length > 4 && e.name[0..4] == "CHT_") {
						copyStreamToFile(e.open, fname);
					}
				}
			}
		}
		
		system("mkisofs.exe -quiet -full-iso9660-filenames -o TO7\\TO7SE.iso TO7\\SE");
		
		printf("Ok\n");
	} else {
		printf("Evitado\n");
	}

	printf("Extrayendo, parcheando y generando TO7EV...");
	if (!std.file.exists("TO7/TO7EV.iso")) {
		makedir("TO7/EV");
		
		foreach (e; isoev) {
			//writefln(e.name);
			if (!e.name.length) continue;
			char[] fname = std.string.format("TO7/EV/", e.name);
			if (std.file.exists(fname)) continue;
			
			if (jtest) {
				if (e.name.length > 4 && e.name[e.name.length - 4..e.name.length] == ".AFS") continue;
			}
				
			//writefln("%s", fname);
			copyStreamToFile(e.open, fname);
		}
				
		// Imagenes
		copy("../images/S_DB_TITLE/S_DB_TITLE.tm2", "TO7/EV/S_DB_TITLE.tm2");		
		copy("../images/S_DB_GAME/S_DB_GAME.tm2", "TO7/EV/S_DB_GAME.tm2");		
		copy("../images/S_DB_SECRET/S_DB_SECRET.tm2", "TO7/EV/S_DB_SECRET.tm2");		
		copy("../images/PK_ETC/PK_ETC.tm2", "TO7/EV/PK_ETC.tm2");
		copy("../images/PK_NOTIP/PK_NOTIP.tm2", "TO7/EV/PK_NOTIP.tm2");
		
		if (jtest) {
			//writefln();
			foreach (e; jisoev) {
				//writefln(e.name);
				if (!e.name.length) continue;
				char[] fname = std.string.format("TO7/EV/", e.name);
				if (std.file.exists(fname)) continue;
					
				if (e.name.length > 4 && e.name[e.name.length - 4..e.name.length] == ".AFS") {
					//writefln(e.name);
					copyStreamToFile(e.open, fname);
				}
			}
		}
		
		//return 0;
		
		system("mkisofs.exe -quiet -full-iso9660-filenames -o TO7\\TO7EV.iso TO7\\EV");
		
		printf("Ok\n");
	} else {
		printf("Evitado\n");
	}

	printf("Extrayendo, parcheando y generando TO7MOV...");
	if (!std.file.exists("TO7/TO7MOV.iso")) {
		makedir("TO7/MOV");
		
		foreach (file; listdir("sub")) {
			if (!file.length || file[0] == '.') continue;
			try {
				copy(std.string.format("sub/%s", file), std.string.format("TO7/MOV/%s", file));
			} catch (Exception e) {
				writefln(e.toString);
			}
		}
		
		foreach (e; isomov) {
			//writefln(e.name);
			if (!e.name.length) continue;
			char[] fname = std.string.format("TO7/MOV/", e.name);
			if (std.file.exists(fname)) continue;
			//writefln("%s", fname);
			copyStreamToFile(e.open, fname);
		}
				
		system("mkisofs.exe -quiet -full-iso9660-filenames -o TO7\\TO7MOV.iso TO7\\MOV");
		
		printf("Ok\n");
	} else {
		printf("Evitado\n");
	}
	
	// Abrimos la nueva ISO para escritura y copiamos la estructura
	// de la iso original	
	File f = new File("TOA-SPA.iso", FileMode.OutNew | FileMode.In);
	Iso newiso = iso.copyIsoStructure(f);
	newiso._udf_check();	

	// Se copia el archivo parcheado
	newiso.recreateFile(newiso["SLUS_213.86"], "TO7/SLUS_213.86");
	//newiso.recreateFile(newiso["SLUS_213.86"], "../SLUS_213.86");
	
	void updateCVM(char[] file) {
		char[] cvmfile = file ~ ".CVM";
		Stream w;	
		printf("%s...", toStringz(file));
		w = newiso.startFileCreate(newiso[cvmfile]);
		copyStream(new SliceStream(iso[cvmfile].open, 0, 0x1800), w);
		copyStream(new File(std.string.format("TO7/%s.ISO", file)), w);
		newiso.endFileCreate(0x200);
		printf("Ok\n");
	}
	
	updateCVM("TO7ROOT");
	updateCVM("TO7MAP");
	updateCVM("TO7SE");
	updateCVM("TO7EV");
	updateCVM("TO7BTL");
	updateCVM("TO7MOV");

	newiso.copyUnrecreatedFiles(iso);
	
	return 0;
}
