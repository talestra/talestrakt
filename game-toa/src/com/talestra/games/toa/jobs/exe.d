import imports;

//version = show_notices_ptr_recalc;
version = enable_binary_patches;

const int mem_bin_disp = -0x00100000 + 0x100;
const int EXE_DISP = -mem_bin_disp;

long mem2file(long mem)  { return mem  + mem_bin_disp; }
long file2mem(long file) { return file - mem_bin_disp; }

Stream exe, exe_o;
RangeListEx rl, rl_ovl;

void checkRewriteInvalidPointer(uint ptr) {
	try {
		if (ptr >= 0x005838D0 && ptr < 0x005B64D0) {
			throw(new Exception("Área reservada para journal"));
		}
		
		if (ptr >= 0x005406D0 && ptr < 0x005406D0 + 114 * 4) {
			throw(new Exception("Área reservada para punteros de journal"));
		}
	} catch (Exception e) {
		throw(new Exception(e.toString ~ " " ~ format("0x%08X", ptr)));
	}
}

void patch_font() { scope(exit)Progress.pop;Progress.push("Actualizando rutina de texto");
	ubyte[][uint] patches;
	
	patches[0x00339B14] = cast(ubyte[])x"640011341a001102108800002D208002bc9f0d0c122800000a0012341a00320212880000109000003800010400000000";
	patches[0x00380FA0] = cast(ubyte[])x"5b00013c70b1243420208500000084800000844420008046a03f023c000882440800e00302000146";
	patches[0x005BB170] = getStream(FS.patch["exe/font.width"].open);
	//patches[0x0057abd8] = cast(ubyte[])"toaend_jp.txt"; // Usamos el jp para tener espacio para el texto en español, comiéndonos parte del toaend_us.txt
	
	foreach (pos, data; patches) {
		exe.position = mem2file(pos);
		exe.write(data);
	}
}

void patch_skit_titles() {
	const uint ptpos = 0x53A3A4;
	rl.clean(0x57D628, 0x5830D8);
	
	const uint maxskits = 538;
	char[][] titles;
	
	void prepare() {
		Stream s_ti = FS.patch["exe/skit.titles"].open;
		while (!s_ti.eof) {
			char[] s = s_ti.readLine();
			titles ~= replace(s, "\\n", "\n");
			if (titles.length >= maxskits) break;
		}
		s_ti.close();
	}
	
	void patch() { scope(exit)Progress.pop;Progress.push("Traduciendo exe", titles.length);
		foreach (i, k; titles) {
			Progress.set(i);
			uint titlepos, skitpos;
			char[] title = k ~ "\0";
			char[] skit  = std.string.format("CHT_%03d.SKT\0", i);
			if (i >= maxskits) throw(new Exception("Mas skits de los que hay"));
	
			titlepos = rl.getAndUse(title.length);
			exe.position = mem2file(titlepos);
			exe.writeExact(title.ptr, title.length);
	
			skitpos = rl.getAndUse(skit.length);
			exe.position = mem2file(skitpos);
			exe.writeExact(skit.ptr, skit.length);
	
			exe.position = mem2file(ptpos) + (0x1C * i);
			exe.write(cast(uint)titlepos);
			exe.write(cast(uint)skitpos);
		}
	}

	prepare();
	patch();
}

void patch_synopsis() { const uint maxjournal = 114; scope(exit)Progress.pop;Progress.push("Traduciendo journal", 114);
	const uint ptpos = 0x005406D0;
	char[][] titles;
	char[][][int] texts;

	void prepare() {
		for (int n = 0; n < maxjournal; n++) {
			Stream s = FS.patch[format("exe/journal/%04d.txt", n)].open;
			auto acme = getACME(s);
			titles ~= acme[0];
			foreach (k, t; acme) {
				if (k == 0) continue;
				texts[n] ~= t;
			}
			s.close();
		}
	}
	
	void validPtr(uint v) {
		if (v < 0x005838D0 || v >= 0x005B64D0) throw(new Exception("Modificando puntero de sinopsis inválido"));
	}
	
	void patch() {
		uint bpos;
		
		for (int n = 0; n < maxjournal; n++) { Progress.set(n);
			char[] string;
			uint structptr, temp;
			
			// Obtenemos el puntero al principio de la entrada del journal
			exe.position = mem2file(ptpos + 4 * n);
			exe.read(structptr);
			
			// Title
			exe.position = mem2file(structptr);
			validPtr(bpos = readUINT(exe)); exe.seekCur(-4);
			
			char[] btitle = StringEncoder.decode(new SliceStream(exe_o, mem2file(bpos)));
			char[] title = titles[n];
			//int titleMax = 15;
			//int titleMax = 39;
			int titleMax = 0xFF;
			
			if (title.length > titleMax) title = title[0..titleMax];
			
			//title = btitle;
			
			//writef("%04d:", n); writeln(title ~ "                            ");
			//writefln("%d                                         ", title.length);
			exe.write(rl.put(title, titleMax + 1));
	
			// Body list
			exe.position = mem2file(structptr + 8);
			
			//writef("%03d:", n); writeln("'" ~ titles[n] ~ "'\t\t\t\t"); //108:'La Tierra Gloriosa'
			
			int m = 0;
			while (true) {
				uint type = readUINT(exe);

				// Comprobamos el centinela
				if (type != 0x5838E8) break; // Puntero a ABCDEFGH
				
				//writefln("  %d", m);

				// Nos saltamos lso valores de la estructura que no vamos a usar
				exe.seek(3 * 4, SeekPos.Current);
				
				validPtr(bpos = readUINT(exe)); exe.seekCur(-4);
				
				char[] btext = StringEncoder.decode(new SliceStream(exe_o, mem2file(bpos)));
				char[] text;
				try {
					text = texts[n][m];
				} catch (Exception e) {
					//writefln("FAIL-exe-patch_synopsis: (%d/%d) : (%d)\t\t", n, m, texts.length);
					//writefln("FAIL-exe-patch_synopsis: (%d)\t\t", texts[n].length);

					//throw(e);
					text = "\n";
				}
				
				if (!text.length) text = "\n";
				
				/*if (n == 108) {
					//writeln();
					text = btext;
				}*/
				//text = btext;
				
				//writefln("   %d,%d                                        ", btext.length, text.length);
				
				try {
					uint locate = rl.put(text);
					try {
						exe.write(locate);
					} catch (Exception e) {
						writefln("WAHT");
						throw(e);
					}
				} catch (Exception e) {
					writefln("----------- (%d/%d) <-- required:[%d]  ", n, m, text.length);
					printf("'%s'\n", toStringz(text));
					rl.show();
					//rl.showSummary();
					throw(e);
				}
				//writefln("            %d                     ", texts[n][m].length);
				
				m++;
			}
		}
	}		

	rl.clean(0x005838D0, 0x005838E8); // Is started with a Song (antes de ABCDEFGH)
	rl.clean(0x005838F8, 0x00583D80); // Despues de ABCDEFGH (hasta IJKLMNOP)
	rl.clean(0x00583D90, 0x005B64D0); // Despues de IJKLMNOP (hasta el final)
	
	rl.useReserved = false;
	
	prepare();
	patch();
	
	rl.useReserved = true;
}

struct dtext { char[] title; char[] desc; char[] extra; }

dtext[][int] getDText(Stream fin) {
	dtext[][int] titles;
	int type = -1, status = 0;

	while (!fin.eof) {
		char[] line = std.string.strip(fin.readLine());
		
		if (line.length >= 1 && line[0] == '*') {
			type = std.conv.toInt(line[1..line.length]);
			status = 0;
			continue;
		}		
		
		if (type == -1) continue;
		if (line.length) {
			if (status == 0) {
				titles[type].length = titles[type].length + 1;
				titles[type][titles[type].length - 1].title = line;
				titles[type][titles[type].length - 1].desc = "";
				status = 1;
			} else {
				if (titles[type][titles[type].length - 1].desc.length) titles[type][titles[type].length - 1].desc ~= "\n";
				titles[type][titles[type].length - 1].desc ~= line;
			}
		} else {
			status = 0;
		}
	}
	
	return titles;
}

void patch_titles() { scope(exit)Progress.pop;Progress.push("Actualizando títulos");
	int[] counts = [
		21, // Luke
		17, // Tear
		15, // Jade
		15, // Anise
		16, // Guy
		14, // Natalia
		 3, // Asch
	];
	Stream fin = FS.patch["exe/titles.txt"].open; scope(exit) { fin.close(); }
	auto titles = getDText(fin);
	
	rl.clean(0x005C6350, 0x005C9000);

	foreach (kpos, count; counts) {
		uint ptr;

		// Leemos puntero 
		exe.position = mem2file(0x00567F6C + (kpos + 1) * 4);
		exe.read(ptr);
		
		exe.position = mem2file(ptr);
		
		for (int n = 0; n < count; n++) {
			uint tid = readUINT(exe);
			if (tid == 0) break;
			if (n != (tid - 1)) throw(new Exception("error(2467):patch_titles"));
			if (n >= titles[kpos].length) {
				uint p1 = readUINT(exe);
				uint p2 = readUINT(exe);
				writeln(StringEncoder.decode(new SliceStream(exe, mem2file(p1))));
				writeln(StringEncoder.decode(new SliceStream(exe, mem2file(p2))));
				throw(new Exception(format("error(2468):patch_titles:%d/%d", kpos, n)));
			}

			//writefln("Title: %d", tid);
			//writeln(titles[kpos][n].title);
			
			exe.write(rl.put(titles[kpos][n].title, 32));
			exe.write(rl.put(titles[kpos][n].desc));
			//exe.position = exe.position + 8;
		}
		//writefln();
	}
}

void patch_places() { scope(exit)Progress.pop;Progress.push("Actualizando lugares");
	// 212 bytes por estructura
	// 0x0055E430 - 3 punteros a los 3 tipos diferentes de lugares
	
	int[] pp_lengths = [21, 24, 18];
	
	struct PLACE_BASE {
		int      id;
		int      id2;
		uint[3]  _1unk;
		uint     title1;
		uint     title2;
		uint     desc;
		uint     spb_file;
		uint[15] _2unk;
		uint     title3;
		uint[28] _3unk;
	}

	Stream fin = FS.patch["exe/places.txt"].open;
	auto places = getDText(fin);
	fin.close();
	
	char[][uint] spb_files;
	
	rl.clean(0x005BCD18, 0x005BE810);
	
	for (int kpos = 0; kpos < 3; kpos++) {
		uint s_ptr;
		exe.position = mem2file(0x0055E430 + 4 * kpos);
		exe.read(s_ptr);
		
		int zpos = 0;
		
		//writefln("*%d", kpos);
		for (int n = 0; n < pp_lengths[kpos]; n++) {
			PLACE_BASE pb2;
			PLACE_BASE pb;
			uint[] pbv; pbv = (cast(uint *)&pb2)[0 .. (pb2.sizeof / int.sizeof)];
			
			uint cpos = s_ptr + n * PLACE_BASE.sizeof;
			
			exe_o.position = mem2file(cpos);
			exe_o.read(TA(pb));
			pb2 = pb;
			
			uint[] patched; patched.length = pbv.length;

			if (pb.spb_file) {
				uint _spb_file = rl.put(StringEncoder.decode(new SliceStream(exe_o, mem2file(pb.spb_file))));
				foreach (k, v; pbv) if (v == pb.spb_file) { pbv[k] = _spb_file; patched[k] = true; }
			}
			
			if (pb.title1) {
				uint _title = rl.put(places[kpos][zpos].title);
				uint _desc  = rl.put(places[kpos][zpos].desc);
				
				foreach (k, v; pbv) if (v == pb.title1 || v == pb.title2 || v == pb.title3) { pbv[k] = _title; patched[k] = true; }
				foreach (k, v; pbv) if (v == pb.desc) { pbv[k] = _desc; patched[k] = true; }
				
				zpos++;
			}
			
			foreach (k, v; pbv) {
				if ((v >= 0x005BCD18 && v < 0x005BE810) && (!patched[k])) {
					writefln("warning!!! code(0x7651)");
					writefln();
				}
			}

			exe.position = mem2file(cpos);
			exe.write(TA(pb2));
		}
	}
}

struct PATCH_INFO {
	uint ins_l;
	uint ins_u;
}

void process_ptr_recalc() { scope(exit)Progress.pop;Progress.push("Actualizando punteros de ejecutable");
	Stream[uint] mounts;
	PATCH_INFO[][uint] patches;
	
	Stream ovl;
	//mounts[0xFFF00] = exe;
	
	// Don't use ranges >= 0x64B880
	
	Stream getPtrStream(uint ptr) {
		if (ptr < 0x64B880) {
			exe.position = mem2file(ptr);
			return exe;
		} else { // OVL
			if (!ovl) throw(new Exception("Can't write in non loaded OVL"));
			ovl.position = ptr - 0x64B880;
			return ovl;
		}
	}
	
	void writeTo(uint ptr, ubyte[] dat) {	
		Stream s = getPtrStream(ptr);
		s.write(dat);
	}
	
	void writeTo32(uint ptr, uint v) {
		Stream s = getPtrStream(ptr);
		s.write(v);
	}

	uint readTo32(uint ptr) {
		return readUINT(getPtrStream(ptr));
	}
	
	void writeToL(uint ptr, uint len) {
		ubyte[] dat; dat.length = len;
		writeTo(ptr, dat);
	}
	
	uint[uint] lengths;
	
	void registerPtr(uint ptr) {
		uint len;
		try {
			len = lengths[ptr];
		} catch (Exception e) {
			writefln("pointer without length: '%08X'     ", ptr);
			throw(e);
		}
		writeToL(ptr, len);
		if (ptr < 0x64B880)  {
			rl.cleanLen(ptr, len);
		} else {
			rl_ovl.cleanLen(ptr, len);
		}
	}
	
	void processPointerFile(char[] file) {
		rl_ovl = new RangeListEx(ovl, 0x64B880);
		
		auto s = FS.patch[file].open;
		while (!s.eof) {
			char[] l = strip(s.readLine);
			if (!l.length) continue;
			char[][] r = split2(l, ":", 2);
			char[][] p_l = split2(r[0], "-", 2);
			char[][] p_p = split(r[1], ",");
			//writefln("%s", p_l[0]);
			
			uint ptr = intFromBase(p_l[0], 0x10);
			uint len = intFromBase(p_l[1], 0x10);
			
			lengths[ptr] = len;
			
			foreach (pt; p_p) { pt = strip(pt); if (!pt.length) continue;
				if (pt.length > 8) {
					if (pt[8] != '_') throw(new Exception("Invalid INSTRUCTION patch"));
					patches[ptr] ~= PATCH_INFO(intFromBase(pt[0..8], 0x10), intFromBase(pt[9..17], 0x10));
					//writefln(pt[9..17]);
					//writefln(pt[0..8]);
				} else {
					patches[ptr] ~= PATCH_INFO(intFromBase(pt[0..8], 0x10), -1);
					//writefln(pt);
				}
			}
		}
	}
	
	bool[uint] patched_luis;
	
	void processTexts(char[] path) {
		//uint[][ubyte[]][int] ptrs = null;
		uint[][char[]][int] ptrs = null;
		
		bool[uint] byte_patches;
		
		log("exe/ttexts/" ~ path, "process_ptr_recalc", 1);
		foreach (f; FS.patch["exe/ttexts/" ~ path]) {
			log(f.name, "process_ptr_recalc.processTexts");
		
			auto s = f.open;
			bool ignoring = false;
			while (!s.eof) {
				char[] l = strip(s.readLine);
				if (!l.length) continue;
				if (l.length >= 2 && l[0..2] == "@@") break;
				if (l.length >= 2 && l[0..2] == "/*") { ignoring = true; continue; }
				if (l.length >= 2 && l[0..2] == "*/") { ignoring = false; continue; }
				if (l[0] == '#') continue;
				if (l.length >= 2 && l[0..2] == "//") continue;
				if (ignoring) continue;
				
				if (l.length >= 2 && l[0..2] == "$$") {
					version (enable_binary_patches) {
						char[][] r = split(l, ":");
						uint ptr = intFromBase(r[1], 16);
						Stream ws = getPtrStream(ptr);
						char[] type = strip(tolower(r[2]));
						if ((ptr in byte_patches) !is null) writefln("\nWARNING: Already patched address 0x%08X\n", ptr);
						byte_patches[ptr] = true;
						if (type == "stringz" || type == "string") {
							char[] rs = strip(r[3]);
							if (rs[0] != '\'') throw(new Exception("Invalid exepatch stringz"));
							if (rs[rs.length - 1] != '\'') throw(new Exception("Invalid exepatch stringz"));
							rs = rs[1..rs.length - 1];
							ws.writeString(rs);
							if (type == "stringz") ws.write(cast(ubyte)0);
						} else {
							foreach (cv; split(r[3], ",")) { cv = strip(cv);
								switch (type) {
									case "ubyte":  ubyte  v = intFrom(cv); ws.write(v); break;
									case "ushort": ushort v = intFrom(cv); ws.write(v); break;
									case "uint":   uint   v = intFrom(cv); ws.write(v); break;
									case "float":  float  v = atof(cv);    ws.write(v); break;
									default: throw(new Exception(format("Tipo inválido: '%s'", r[2])));
								}
							}
						}
					}
					continue;
				}
				
				char[][] r = split2(l, ":", 2);
				uint ptr = intFromBase(r[0], 16);
				char[] rt = r[1];
				if ((rt[0] != '\'') || (rt[rt.length - 1] != '\'')) {
					writeln("[" ~ rt ~ "]      ");
					throw(new Exception("Invalid text"));
				}
				char[] text = replace(rt[1..rt.length - 1], "\\n", "\n");
				//ubyte[] tenc = StringEncoder.encode(text) ~ (cast(ubyte[])"\0");
				
				registerPtr(ptr);
				//ptrs[tenc.length][tenc] ~= ptr;
				ptrs[text.length][text] ~= ptr;
			}
		}

		foreach (len; ptrs.keys.sort.reverse) {
			foreach (data, ot_ptrs; ptrs[len]) {
				uint near_to = ot_ptrs[0];
				uint n_ptr;
				bool try_normal = false;
				try {
					if (rl_ovl) {
						//n_ptr = rl_ovl.getAndUse(len, near_to);
						n_ptr = rl_ovl.put(data);
					} else{
						try_normal = true;
					}
				} catch {
					try_normal = true;
				}
				
				if (try_normal) {
					//n_ptr = rl.getAndUse(len, near_to);
					n_ptr = rl.put(data);
				}
				
				//writeTo(n_ptr, data);
				
				foreach (ot_ptr; ot_ptrs) {
					if (ot_ptr in patches) {
						foreach (pi; patches[ot_ptr]) {
							if (pi.ins_u == -1) {
								try {
									checkRewriteInvalidPointer(pi.ins_l);
									writeTo32(pi.ins_l, n_ptr);
								} catch (Exception e) {
									writefln("p_32: '%s'", e.toString);
								}
							} else {
								if (pi.ins_u in patched_luis) {
									throw(new Exception(format("Already patched lui in position 0x%08X", pi.ins_u)));
								}
								patched_luis[pi.ins_u] = true;
								
								try {
									checkRewriteInvalidPointer(pi.ins_u);
									checkRewriteInvalidPointer(pi.ins_l);
								} catch (Exception e) {
									writefln("i_la: '%s'", e.toString);
								}
							
								uint ilui = readTo32(pi.ins_u), iadd = readTo32(pi.ins_l);
								//writefln("%08X,%08X", ilui, iadd);
								
								if ((ilui >> 26) != 0b001111) throw(new Exception("Invalid LUI instruction"));
								
								switch (iadd >> 26) {
									case 0b001000, 0b001001: break; // ADDI(U)
									case 0b001101: break; // ORI(U)
									default: throw(new Exception("Invalid load lower instruction"));
								}
								
								uint last_ilui_i = ilui;
								uint last_ilui = (ilui & 0xFFFF);
								uint last_iadd = (iadd & 0xFFFF);
								
								// Clean IMMEDIATE
								ilui = (ilui & ~0xFFFF);
								iadd = (iadd & ~0xFFFF);
								
								// Clean COP
								iadd = (iadd & 0x03FFFFFF);
								
								iadd |= (0b001101 << 26); // ORI
								
								ilui |= (n_ptr >> 16) & 0xFFFF;
								iadd |= (n_ptr >>  0) & 0xFFFF;
								
								version (show_notices_ptr_recalc) {
									if (last_ilui != (n_ptr >> 16)) {
										writefln("NOTICE:%08X: %04X%04X->%04X%04X", pi.ins_u, last_ilui, last_iadd, (n_ptr >> 16) & 0xFFFF, (n_ptr >> 0) & 0xFFFF);
									}
								}
								
								writeTo32(pi.ins_u, ilui);
								writeTo32(pi.ins_l, iadd);
								//writeTo32(pi.ins_l, n_ptr);
							}
						}
					} else {
						writefln("WARNING!: no patches for pointer 0x%08X", ot_ptr);
					}
				}
				//writefln("%08X", pos);
				////writefln("%s", cast(char[])data);
			}
		}
	}
	
	void process(char[] name) {
		processPointerFile("exe/pointers/" ~ name ~ ".txt");
		processTexts(name);
	}
	
	process("main");

	//ovl = FS.gout["root/OV_PDVD_BTL_US.OVL"].open;
	ovl = FS.temp["root/OV_PDVD_BTL_US.OVL"].open(FileMode.In | FileMode.Out);
		process("btl");
	ovl.close();

	//ovl = FS.gout["root/OV_PDVD_FIELD_US.OVL"].open;
	ovl = FS.temp["root/OV_PDVD_FIELD_US.OVL"].open(FileMode.In | FileMode.Out);
		process("field");
	ovl.close();
}

ubyte[] encodeDistributed(char[] d) {
	ubyte[] r;
	foreach (c; d) r ~= ((((~c) + 33) - 11) ^ 0b10101010);
	return r;
}

void testRangeList() {
	auto rl2 = new RangeList();
	rl2.add(0, 10000);
	uint p1 = rl2.getAndUse(1);
	uint p2 = rl2.getAndUse(7, 4);
	writefln(p1);
	writefln(p2);

	return;
}

void process(bool stand_alone = false) { scope(exit)Progress.pop;Progress.push("Actualizando ejecutable", 6);
	//testRangeList(); return;

	FS.gout["SLUS_213.86"].replace(FS.gin["SLUS_213.86"].open(FileMode.In));
	FS.gin["root/OV_PDVD_BTL_US.OVL"].saveto(FS.temp["root/OV_PDVD_BTL_US.OVL"]);
	FS.gin["root/OV_PDVD_FIELD_US.OVL"].saveto(FS.temp["root/OV_PDVD_FIELD_US.OVL"]);
	FS.gin["root/OV_PDVD_SFD_US.OVL"].saveto(FS.temp["root/OV_PDVD_SFD_US.OVL"]);
	FS.gin["root/OV_PDVD_SKIT_US.OVL"].saveto(FS.temp["root/OV_PDVD_SKIT_US.OVL"]);
	
	exe = FS.gout["SLUS_213.86"].open;
	//exe = FS.temp["SLUS_213.86"].open;
	exe_o = new BufferedStream(FS.gin["SLUS_213.86"].open(FileMode.In));
	exe.position = 0;

	rl = new RangeListEx(exe, 0xFFF00);
	
	//patch_synopsis();     Progress.set(-1);
	patch_font();         Progress.set(-1);
	patch_skit_titles();  Progress.set(-1);
	patch_titles();       Progress.set(-1);
	patch_places();       Progress.set(-1);
	process_ptr_recalc(); Progress.set(-1);
	patch_synopsis();     Progress.set(-1);
	
	rl.putBin(encodeDistributed("distributed.to:" ~ cast(char[])FS.patch["distributed.to"].read) ~ cast(ubyte[])"\0");
	
	//writeln(cast(char[])encodeDistributed("distributed.to:" ~ cast(char[])FS.patch["distributed.to"].read));
	//writefln(encodeDistributed("distributed.to:" ~ cast(char[])FS.patch["distributed.to"].read));
	//writefln("%s  ", encodeDistributed("distributed.to:"));
	
	exe.close();

	patch_stopPoint();
	
	if (stand_alone) {
		//FS.gout["SLUS_213.86"].replace(FS.temp["SLUS_213.86"].open(FileMode.In));
		FS.gout["root/OV_PDVD_BTL_US.OVL"].replace(FS.temp["root/OV_PDVD_BTL_US.OVL"].open(FileMode.In));
		FS.gout["root/OV_PDVD_FIELD_US.OVL"].replace(FS.temp["root/OV_PDVD_FIELD_US.OVL"].open(FileMode.In));
		FS.gout["root/OV_PDVD_SFD_US.OVL"].replace(FS.temp["root/OV_PDVD_SFD_US.OVL"].open(FileMode.In));
		FS.gout["root/OV_PDVD_SKIT_US.OVL"].replace(FS.temp["root/OV_PDVD_SKIT_US.OVL"].open(FileMode.In));
	}
	
	writefln();
	rl.showSummary();
	
	
	//rl.showSummary();
	
	//FS.gout["SLUS_213.86"].saveto(FS.temp["SLUS_213.86"].open(FileMode.OutNew));
	//FS.gout["SLUS_213.86"].makePPF(FS.temp["SLUS_213.86.ppf"].open(FileMode.OutNew), 0);
}