import imports;

version = sb7_no_repeated;

struct SB7_header {
	char[0x20] date;
	
	uint unk_ptr0;
	
	uint tt_ptr2;
	
	// Info Code Block
	uint icb_count;
	uint icb_size;
	uint icb_ptr;

	// Unknown Section
	uint unk_ptr1;
	
	// TextTable
	uint tt_count;
	uint tt_size;
	uint tt_ptr;
	
	// Instructions
	uint i_size;
	uint i_ptr;

	// Text
	uint t_size;
	uint t_ptr;
	
	// Unknown section
	uint unk_ptr2;
	uint unk_ptr3;
	
	void print() {
		writefln("VERSION: '%s' (%04X)", date, SB7_header.sizeof);

		writefln("unk_ptr0      (%08X)", unk_ptr0);
		
		writefln("TextTable2    (%08X)", tt_ptr2);
		
		writefln("InfoCodeBlock (%08X, %d, %d)", icb_ptr, icb_size, icb_count);
		writefln("unk_ptr1:     (%08X)", unk_ptr1);
		writefln("TextTable     (%08X, %d, %d)", tt_ptr, tt_size, tt_count);
		writefln("Instructions  (%08X, %d)", i_ptr, i_size);
		writefln("Text          (%08X, %d)", t_ptr, t_size);
		writefln("unk_ptr2:     (%08X)", unk_ptr2);
		writefln("unk_ptr3:     (%08X)", unk_ptr3);
	}
}

struct ICB {
	uint[4] p0;
	uint i_ptr;
	uint i_count;
	uint[4] p1;
	
	void print() {
		printf("%08X (%-4d): ", i_ptr, i_count);
		printf("("); foreach (c; p0) printf("%4d,", c); printf(") ");
		printf("("); foreach (c; p1) printf("%4d,", c); printf(") ");
		printf("\n");
	}
}

struct INST {
	uint type;
	uint stack;
	uint[2] p;
	
	char[] instName() {
		switch (type) {
			case 0x000: return "?PUSH_VAR";
			case 0x001: return "?PUSH_LVAR"; 
			case 0x002: return "PUSH_CONST";          // Introudce un elemento en la pila
			case 0x003: return "POP";           // Extrae un elemento de la pila
			case 0x004: return "?ASSIGN";
			case 0x00B: return "?COMP";
			case 0x00C: return "RETURN";        // Vuelve a la funci'on que llam'o
			case 0x00D: return "?JUMP";
			case 0x00E: return "?JUMP_COND";			
			case 0x010: return "CALL";
			
			case 0x01C: return "?SUM";
			
			case 0x3F3: return "?FLAG_RELATED";

			case 0x411: return "ITEM_GET_COUNT";
			
			case 0x42B: return "PRINT_CONSOLE";
			case 0x42D: return "CREATE_MOTION";
			
			case 0x436: return "MOTION";
			
			case 0x434: return "PRINTF";
			case 0x450: return "TEX_CHANGE"; // Cambia la textura del ojo, la boca, y algo m'as (0, 1, 2)
			case 0x453: return "INFO_BOX";
			default: return "";
		}
	}
}

class PatchString {
	int ptr;
	char[] text;
	char[] otext;
	StringEncoder.PARAM[] params;
	
	~this() {
		//delete text;
		//delete otext;
		text.length = 0;
		otext.length = 0;
		params.length = 0;
	}
	
	this(int ptr, Stream text) {
		this.ptr    = ptr;
		this.otext  = StringEncoder.decode(text, false, true);
		this.text   = this.otext;
		this.params = StringEncoder.params;
	}

	ubyte[] encode() { return StringEncoder.encode(text, params) ~ cast(ubyte[])"\0"; }
}

class SB7 {
	SB7_header header;
	Stream s;
	Stream tts; uint[] ttt; // TextTable
	Stream ts; // Text
	Stream icbs; // ICB
	Stream insts; // INST
	INST[] inst;
	
	PatchString[]   str_i;
	//PatchString[][] str_t;
	PatchString[]  str_tt;
	
	~this() {
		foreach (i; str_i) delete i;
		foreach (i; str_tt) delete i;
		str_i.length = 0;
		str_tt.length = 0;
		delete str_i;
		delete str_tt;
		delete inst;
	}

	this(Stream s) {
		this.s = new SliceStream(s, 0);
		s.read(TA(header));
		
		tts   = new SliceStream(this.s, header.tt_ptr, header.tt_ptr + header.tt_size);    // TextTableStream
		ts    = new SliceStream(this.s, header.t_ptr, header.t_ptr + header.t_size);       // TextStream
		icbs  = new SliceStream(this.s, header.icb_ptr, header.icb_ptr + header.icb_size); // ICB
		insts = new SliceStream(this.s, header.i_ptr, header.i_ptr + header.i_size);       // INST
		
		processTextTable();
		proecssTextTablePointers();

		processINST();
		processINSTPointers();
	}
	
	ICB[] getICB() {
		ICB[] r;
		icbs.position = 0;
		while (!icbs.eof) { ICB c; icbs.read(TA(c)); r ~= c; }
		return r;
	}
	
	void proecssTextTablePointers() {
		//str_t = [];
		str_tt = [];
		for (int table = 0; table < header.tt_count; table++) {
			//str_t.length = str_t.length + 1;
			int p_s = ttt[table], count = (ttt[table + 1] - ttt[table]) / 4;
			tts.position = p_s;
			
			//int str_t_start = str_tt.length;
			//str_t ~= [];
			
			for (int n = 0; n < count; n++) {
				uint ptr;
				tts.read(ptr);
				//writefln("%08X\n", ptr);
				
				//str_ttt ~= StringEncoder.decode(new SliceStream(ts, ptr), false, true);
				
				//ts.position = ptr;
				str_tt ~= new PatchString(
					header.tt_ptr + p_s + n * 4,
					new SliceStream(ts, ptr)
				);
				
				//str_t[str_t.length - 1] ~= str_tt[str_tt.length - 1];
			}
			//str_t ~= str_tt[str_t_start..str_tt.length];
		}
	}
	
	void processINSTPointers() {
		str_i = [];
		foreach (k, i; inst) {
			uint ci_ptr = header.i_ptr + k * INST.sizeof;
			// Pointer
			if (i.type == 2 && i.stack == 2) {
				str_i ~= new PatchString(
					ci_ptr + 8,
					new SliceStream(ts, i.p[0])
				);
			}
		}
	}

	private void processINST() {
		inst = [];
		
		insts.position = 0;
		while (!insts.eof) {
			INST c;
			insts.read(TA(c));
			inst ~= c;
		}
	}
	
	uint[] getTextPointers(int table) {
		uint[] r;
		Stream tps = new SliceStream(tts, ttt[table], ttt[table + 1]);
		while (!tps.eof) {
			uint p; tps.read(p); r ~= p;
			//writefln("%08X", p);
		}
		return r;
	}
	
	char[][] getTexts(uint[] pp) {
		char[][] r;
		foreach (p; pp) {
			r ~= StringEncoder.decode(new SliceStream(ts, p), false);
			//writefln("%s", r[r.length - 1]);
		}
		return r;
	}
	
	void processTextTable() {
		ttt = [];
		tts.position = 0;
		//writefln("printTextTable:");
		for (int n = 0; n < header.tt_count; n++) {
			uint p; tts.read(p);
			ttt ~= p;
			//writefln("  %03d: %08X", n, p);
		}
		ttt ~= header.tt_size;
	}
	
	void dumpScriptVerbose(Stream so) {
		auto sb7 = this;
	
		int kg = 0;
		for (int n = 0; n < sb7.header.tt_count; n++) {
			uint[] pp = sb7.getTextPointers(n);
			so.writefln("TABLE(%d):", n);
			foreach (k, s; sb7.getTexts(pp)) {
				so.writef("\t\t\t(%4d|%4d):'", k, kg);
				so.writeString(replace(s, "\n", "\\n"));
				so.writefln("'");
				kg++;
			}
		}
		
		so.writefln("ICB:");
		int[int] inst_points;
		foreach (k, icb; sb7.getICB) {
			//so.writefln("\t\t\t%08X:     %08X:%d", sb7.header.icb_ptr + icb.sizeof * k, icb.i_ptr, icb.i_count);
			so.writefln("\t\t\t%-3d:    ICB_PTR_ZERO(%08X) ICB_PTR(%08X) I_PTR(%08X):LEN(%d)", k, icb.sizeof * k, sb7.header.icb_ptr + icb.sizeof * k, icb.i_ptr, icb.i_count);
			inst_points[icb.i_ptr / 16] = k;
		}

		so.writefln("INSTRUCTIONS:");
		int local_k;
		foreach (k, i; sb7.inst) {
			if (k in inst_points) {
				so.writefln("\tF%d:", inst_points[k]);
				local_k = 0;
			}
			//so.writef("\t\t\t%03X: %08X (%08X, %08X) ; %s ", i.type, i.stack, i.p[0], i.p[1], i.instName);
			so.writef("\t\tI%03d: %03X: %08X (%08X, %08X) ; %s ", local_k, i.type, i.stack, i.p[0], i.p[1], i.instName);
			
			if (i.type == 2 && i.stack == 2) {
			//if (i.type == 2 && i.p[0] > 500) {
				so.writef("'");
				so.writeString(replace(sb7.getTexts([i.p[0]])[0], "\n", "\\n"));
				so.writef("'");
			}

			if (i.type == 2 && i.stack == 1) {
			//if (i.type == 2 && i.p[0] > 500) {
				switch (i.p[1]) {
					case 2: so.writef("%d", *(cast(int *)&i.p[0])); break;
					case 3: so.writef("%ff", *(cast(float *)&i.p[0])); break;
				}
			}
			
			if (i.type == 2 && i.stack == 0x5D) {
				so.writef("TABLE(%d)", *(cast(int *)&i.p[1]));
			}
			
			if (i.type == 0 || i.type == 1) {
				so.writef("%d", *(cast(int *)&i.stack));
			}
			
			if (i.type == 0x10) {
				if ((i.p[1] % ICB.sizeof) != 0) writef("invalid_call? ");
				so.writef("F%d", i.p[1] / ICB.sizeof);
			}

			if (i.type == 0x0E || i.type == 0x0D) {
				if ((i.p[1] % INST.sizeof) != 0) writef("invalid_jump? ");
				so.writef("I%03d", i.p[1] / INST.sizeof);
			}
			
			so.writefln();
			
			local_k++;
		}	
	}

	version (sb7_no_repeated) {
		void saveto(Stream so) {
			copy2From(so, new SliceStream(s, 0, header.t_ptr));
			Stream so_info = new SliceStream(so, 0, 32);
			
			ubyte[] info;
			info = cast(ubyte[])format("SB7 Jul 15 2008 00:00:00");
			
			info.length = 32;
			so_info.write(info);
			
			uint[ubyte[]] writted; scope (exit) writted = null;
			
			void encodeList(PatchString[] ps) {
				foreach (t; ps) {
					ubyte[] data = t.encode;
					scope Stream so_p = new SliceStream(so, t.ptr, t.ptr + 4);
					
					uint cpos = cast(uint)(so.position - header.t_ptr);
					
					if (data in writted) {
						cpos = writted[data];
					} else {
						so.write(data);
						writted[data] = cpos;
					}
					
					so_p.write(cpos);
				}
			}
			
			encodeList(str_tt);
			encodeList(str_i);
			
			while (so.position % 4) so.write(cast(ubyte)0);
		}
	} else {
		void saveto(Stream so) {
			copy2From(so, new SliceStream(s, 0, header.t_ptr));
			Stream so_info = new SliceStream(so, 0, 32);
			
			ubyte[] info;
			info = cast(ubyte[])format("SB7 Jul 15 2008 00:00:00");
			
			info.length = 32;
			so_info.write(info);
			
			void encodeList(PatchString[] ps) {
				foreach (t; ps) {
					ubyte[] data = t.encode;
					scope Stream so_p = new SliceStream(so, t.ptr, t.ptr + 4);
					so_p.write(cast(uint)(so.position - header.t_ptr));
					so.write(data);
				}
			}
			
			encodeList(str_tt);
			encodeList(str_i);
			
			while (so.position % 4) so.write(cast(ubyte)0);
		}
	}
	
	Stream save() {
		Stream ms = new MemoryStream();
		saveto(ms);
		return ms;
	}	
}

/*

TABLE for SCRIPT:
	00 - Names
	01 - Generic Locked
	02 - Head to
	03 - Character names?
	04 - ??
	05 - ??
	06 - Motion?
	07 - Motion?
	08 - Motion?
	09 - Motion? More?
	10 - Door Locked
	
	XX - Scenes?
*/
