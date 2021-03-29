import std.stdio, std.string, std.file, std.path;

enum REG {
	EAX = 0,
	ECX,
	EDX,
	EBX,
	ESP,
	EBP,
	ESI,
	EDI
}

extern(C) void test(int a) {
	printf("[%d]", a);
}

abstract class DynaRec {
	ubyte[] ecode; // emulated code
	ubyte[] lcode; // local code

// Manipulacion
	protected void PushByte (ubyte b) { lcode.length = lcode.length + 1; *(lcode.ptr + lcode.length - 1) = b; }
	protected void PushInt  (int   b) { lcode.length = lcode.length + 4; *cast(uint *)(lcode.ptr + lcode.length - 4) = b; }
	protected void PushShort(short b) { lcode.length = lcode.length + 2; *cast(uint *)(lcode.ptr + lcode.length - 2) = b; }

// Codificacion
	// INC/DEC REG (0x40..0x47 | 0x48..0x4F)
	protected void PushINC (REG reg) { PushByte(0x40 + reg); }
	protected void PushDEC (REG reg) { PushByte(0x48 + reg); }

	// PUSH/POP REG (0x50..0x57 | 0x58..0x5F)
	protected void PushPUSH(REG reg) { PushByte(0x50 + reg); }
	protected void PushPOP (REG reg) { PushByte(0x58 + reg); }

	// PUSHAD/POPAD (0x60, 0x61)
	protected void PushPUSHAD() { PushByte(0x60); }
	protected void PushPOPAD () { PushByte(0x61); }

	// PUSH IMM32, PUSH IMM8 (0x68, 0x6A)
	protected void PushPUSH(int imm) {
		PushByte((imm >= 0x100) ? 0x68 : 0x6A);
		(imm >= 0x100) ? PushInt(imm) : PushByte(imm);
	}

	// MOV REG, IMM32 (0xB8..0xBF)
	protected void PushMOV(REG reg, int imm) { PushByte(0xB8 + reg); PushInt(imm); }

	// CALL REG (0xFF + 0xD0..0xD7)
	protected void PushCALL(REG reg) { PushByte(0xFF); PushByte(0xD0 + reg); }

	// CALL IMM (MACRO)
	protected void PushCALL(void *addr, REG treg = REG.EDX) {
		PushMOV (treg, cast(int)addr);
		PushCALL(treg);
	}

	// ADD REG, IMM (0x83 + 0xC0..0xC7)
	protected void PushADD(REG a, int v) {
		if (v < 0x100) {
			PushByte(0x83);
			PushByte(0xC0 + a);
			PushByte(v);
		}
	}

	protected void PushNOP() {
	}

	protected void PushRET(int dis = 0) {
		if (dis == 0) {
			PushByte(0xC3);
		} else {
			PushByte(0xC2);
		}
	}

	public void Run() {
		void *a = lcode.ptr;
		asm {
			call a;
		}
	}

	public void Save(char[] filename) {
		write(filename, lcode);
	}

	public void SetLabel(int addr, ubyte[] ec) {
		//ecore ~= ec;
	}

	// La convencion de windows especifica que los parametros se pasan por pila
	// y la funcion se encarga de quitar los elementos de la pila
	public void PushINVOKE_WINDOWS(void *ptr, int[] params) {
		foreach (p; params) PushPUSH(p);
		PushCALL(ptr);
	}

	// La convencion stdcall especifica que los parametros se pasan por pila
	// y la funcion se encarga de dejar la pila en su estado original
	public void PushINVOKE_STDCALL(void *ptr, int[] params) {
		PushINVOKE_WINDOWS(ptr, params);
		PushADD(REG.ESP, params.length * 4);
	}
}

class TestDynaRec : DynaRec {
	this() {
		PushINVOKE_STDCALL(&test, [1]);
		PushINVOKE_STDCALL(&test, [2]);
		PushINVOKE_STDCALL(&test, [3]);

		PushRET();
	}
}

//extern(C) typedef void (* void_int1)(int);

/*int main() {
//	void_int1 ptr = &test;
//	ptr(1);

	DynaRec dr = new TestDynaRec();

	//dr.Save("dynarec.bin");
	writefln("{");
	dr.Run();
	writefln("\n}");

	return 0;
}*/
