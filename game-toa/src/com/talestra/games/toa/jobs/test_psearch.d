module test_psearch;

import std.stdio, std.c.string, std.string, std.c.stdlib, std.file, std.stream;

import imports;

/*class PATCH_INFO {
	uint cv;
	uint ins_u;
	uint ins_l;
	int block;
	bool ins;
	
	static PATCH_INFO opCall(uint cv, uint ins_u, uint ins_l, int block, bool ins) {
		PATCH_INFO pi = new PATCH_INFO();
		pi.cv = cv;
		pi.ins_u = ins_u;
		pi.ins_l = ins_l;
		pi.block = block;
		pi.ins = ins;
		return pi;
	}
}*/

struct PATCH_INFO {
	uint cv;
	uint ins_u;
	uint ins_l;
	int block;
	bool ins;
	
	void dump() {
		writefln("PATCH_INFO:");
		writefln("  cv: %08X", cv);
		writefln("  ins_u: %08X", ins_u);
		writefln("  ins_l: %08X", ins_l);
		writefln("  block: %08X", block);
		writefln("  ins: %d", ins);
	}
}

//debug = out_info_dump;

class PointerSearch {
	struct ANALYSIS_STATE {
		uint value[32];
		uint lui[32];
		uint status[32];
	}
	
	PATCH_INFO[uint][uint] search;
	
	//uint valueMask = 0x0FFFFFFF;
	uint valueMask = 0xFFFFFFFF;
	
	uint[][] search_data;
	
	uint[uint] lui_addr;
	
	void dump(char[] type) {
		auto f = FS.patch[format("exe/pointers/%s.txt", type)].open(FileMode.OutNew); scope(exit) f.close();
		auto ft = FS.patch[format("exe/texts/%s.txt", type)].open(FileMode.OutNew); scope(exit) f.close();
		
		foreach (key; search.keys.sort) {
			auto list = search[key];
			int block = 0;
			
			//printf("%f,", *(cast(float *)&key));
			
			foreach (pos; list.keys.sort) { auto pi = list[pos]; block = pi.block; }

			auto data = search_data[block];
			char outb[0x1000];
			sprintf(outb.ptr, "%s", ((cast(ubyte *)data.ptr) + key));
			char[] r = outb[0..strlen(outb.ptr)];
			
			int alloc = r.length + 1;
			while ((alloc % 4) != 0) alloc++;
			
			f.writef("%08X-%03X:", key, alloc);
			ft.writef("%08X:", key);
			
			debug(out_info_dump) printf("%08X-%03X:", key, alloc);
			r = cast(char[])StringEncoder.decode(new MemoryStream(cast(ubyte[])(r) ~ cast(ubyte[])"\0"));


			foreach (pos; list.keys.sort) { auto pi = list[pos];
			//foreach (pos, pi; list) {
				//printf("[$%d]", pi.block);
				if (!pi.ins) {
					f.writef("%08X,", pos);
					debug(out_info_dump) printf("%08X,", pos);
				} else {
					f.writef("%08X_%08X,", pi.ins_l, pi.ins_u);
					debug(out_info_dump) printf("%08X_%08X,", pi.ins_l, pi.ins_u);
					//printf("I[%08X],", pi.ins_u);
				}
				//writefln(pi.cv);
				//if (pi.ins) pi.dump();
			}
			f.writefln();
			ft.writef("'");
			ft.writeString(replace(r, "\n", "\\n"));
			ft.writef("'");
			ft.writefln();
			debug(out_info_dump) printf(":'%s'", toStringz(replace(r, "\n", "\\n")));
			debug(out_info_dump) printf("\n");
		}
	}
	
	void process(char[] type) {
		foreach (data; search_data) {
			ANALYSIS_STATE state;
			psearch(data, 0, 0, 0, state, 0);
		}

		dump(type);
	}

	void psearch(uint[] data, int data_base, int start, int level, ANALYSIS_STATE state, int block) {
		int n, m;
		int branch = -1;
		
		search.remove(0);

		for (n = start; n < data.length; n++) {
			bool isbranch = false, update = false, show = false;

			uint cv = data[n];               // Dato actual de 32 bits
			uint cvm = (cv & valueMask);
			int cpos = data_base + (n << 2); // Dirección actual
			int j, cop, rs, rt;              // Partes de la instrucción
			short imm;                       // Valor inmediato
			
			// Comprobamos si hemos encontrado un puntero de 32 bits
			if (cvm in search) search[cvm][cpos] = PATCH_INFO(cv, 0, cpos, block, false);

			// TIPO:I | Inmediato
			cop = (cv >> 26) & 0b111111; // 6 bits
			rs  = (cv >> 21) & 0b11111;  // 5 bits
			rt  = (cv >> 16) & 0b11111;  // 5 bits
			imm = (cv >>  0) & 0xFFFF;   // 16 bits

			// TIPO:J | Salto incondicional largo
			//j   = cv & 0x3FFFFFF; // 26 bits

			//if (cpos >= 0x00389458 && cpos <= 0x00389488)
			//show = 1;
			
			// 0035F564_00360A28
			//if (00360A28_0035F564)
			
			bool possible_ptr = false;

			// Comprueba el código de operación
			switch (cop) {
				// Saltos cortos
				case 0b000100: case 0b000101: isbranch = true; break; // BEQ, BNE
				case 0b000001: switch (rt) { case 0b00001: case 0b10001: case 0b00000: case 0b10000: isbranch = true; default: } break; // BGEZ, BGEZAL, BLTZ, BLTZAL
				case 0b000110: case 0b000111: if (rt == 0) isbranch = true; break; // BLEZ, BGTZ
				// Saltos largos
				/*
				case 0b000010: // J
					if (level > 0) return;
				break;
				*/
				case 0b000000: // JR
					if ((cv & ((1 << 21) - 1)) == 0b_0_0000_0000_0000_0000_1000) {
						for (int i = 0; i < 32; i++) state.value[i] = 0;
					}
				break;
				// Carga de datos típicas (LUI + ADDI(U)/ORI)
				case 0b001111: // LUI
					state.value[rt] = (imm << 16);
					state.lui[rt] = cpos;
					state.status[rt] = 1;
					
					if (show) printf("LUI $%d, %04X\n", rt, imm);
					
					update = true;
					possible_ptr = true;
				break;
				case 0b001000: case 0b001001: // ADDI/ADDIU
					state.value[rt] = state.value[rs] + imm;
					state.status[rt] = 0;
					
					if (state.status[rs] == 1) possible_ptr = true;
					
					if (show) printf("ADDI $%d, $%d, %04X\n", rs, rt, imm);
					update = true;
				break;
				case 0b001101: // ORI
					state.value[rt] = state.value[rs] | imm;
					state.status[rt] = 0;

					if (state.status[rs] == 1) possible_ptr = true;

					if (show) printf("ORI $%d, $%d, %04X\n", rs, rt, imm);
					update = true;
				break;
				default: break;
			}

			if (update) {
				state.value[0] = 0x00000000;

				if (show) printf("## r%d = %08X\n", rt, state.value[rt]);

				cvm = ((cv = state.value[rt]) & valueMask);

				if (cvm in search) {
					//if (possible_ptr) {
					if (true) {
						//uint cpos_lui = state.lui[rt];
						uint cpos_lui = state.lui[rs];
						
						PATCH_INFO pi = PATCH_INFO(cv, cpos_lui, cpos, block, true);
						//search[cvm][cpos] = pi;
						search[cvm][cpos_lui] = pi;
						
						if (cpos_lui in lui_addr) {
							if (lui_addr[cpos_lui] != cvm) {
								//writefln("LUI with two addi/ori");
								//throw(new Exception("LUI with two addi/ori"));
							}
						} else {
							lui_addr[cpos_lui] = cvm;
						}
					} else {
						//writefln("%08X:Not possible ptr: %08X (%08X-%08X)", cpos, cvm, data[state.lui[rs]], data[cpos]);
						//writefln("%08X:Not possible ptr: %08X", cpos, cvm);
					}
				}
			}

			if (branch != -1) {
				if (level >= 1) return;
				//if (level >= 2) return;
				psearch(data, data_base, branch, level + 1, state, block);
				branch = -1;
			}

			if (isbranch) { branch = n + imm + 1; }
		}
	}
}

void process() {
	auto ps = new PointerSearch();

	void getFile(char[] gfile) {
		auto s = FS.patch[gfile].open;
		while (!s.eof) {
			char[] l = strip(s.readLine);
			if (!l.length) continue;
			if (l.length >= 2 && l[0..2] == "//") continue;
			if (l.length >= 2 && l[0..2] == "$$") continue;
			if (l.length >  8 && l[8] != ':') continue;
			char[][] r = split2(l, ":");
			uint v = intFromBase(r[0], 16);
			ps.search[v] = null;
			//writefln("%08X", v);
		}
	}
	
	void getFiles(char[] gfile) {
		ps.search = null;
		foreach (e; FS.patch[gfile]) getFile(gfile ~ "/" ~ e.name);
	}

	getFiles("exe/ttexts/main");
	ps.search_data = []; ps.search_data ~= cast(uint[])read("prepare/BTL.dump");
	ps.process("main");

	getFiles("exe/ttexts/btl");
	ps.search_data = []; ps.search_data ~= cast(uint[])read("prepare/BTL.dump");
	ps.process("btl");

	getFiles("exe/ttexts/field");
	ps.search_data = []; ps.search_data ~= cast(uint[])read("prepare/FIELD.dump");
	ps.process("field");
	
}

/*
$exe = file_get_contents('SLUS_213.86');
function create($type) {
	echo "$type\n";
	global $exe;
	$f = fopen("{$type}.dump", 'wb');
	fseek($f, 0xFFF00);
	fwrite($f, $exe);
	fseek($f, 0x64B880);
	fwrite($f, file_get_contents("OV_PDVD_{$type}_US.OVL"));
}

create('BTL');
create('FIELD');
create('SKIT');
create('SFD');
*/