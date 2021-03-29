import std.stdio, std.string, std.c.stdlib, std.file, std.stream;

// Definimos tipos
alias uint u32;
alias ushort u16;
alias ubyte u8;

alias int s32;
alias short s16;
alias byte s8;

void Dump(ElfHeader eh) {
	writefln("ElfHeader {");
	writefln("  magic:   %08X", eh.magic);
	writefln("  class:   %02X", eh._class);
	writefln("  data:    %02X", eh.data);
	writefln("  idver:   %02X", eh.idver);
	writefln("  pad:     '%s'", eh.pad);
	writefln("  type:    %04X", eh.type);
	writefln("  machine: %04X", eh.machine);
	writefln("  version: %08X", eh._version);
	writefln("  entry:   %08X", eh.entry);
	writefln("  phoff:   %08X", eh.phoff);
	writefln("  shoff:   %08X", eh.shoff);
	writefln("  flags:   %08X", eh.flags);
	writefln("  ehsize:  %04X", eh.phoff);
	writefln("  phentsize: %04X", eh.phentsize);
	writefln("  phnum:     %04X", eh.phnum);
	writefln("  shentsize: %04X", eh.shentsize);
	writefln("  shnum:     %04X", eh.shnum);
	writefln("  shstrndx:  %04X", eh.shstrndx);
	writefln("}");
}

// Header de los ficheros Elf
struct ElfHeader {
	u32 magic;
	u8  _class;
	u8  data;
	u8  idver;
	u8  pad[9];
	u16 type;
	u16 machine;
	u32 _version;
	u32 entry;

	u32 phoff; // Program Headers Offset
	u32 shoff; // Section Headers Offset

	u32 flags;

	u16 ehsize;

	// ProgramHeaders
	u16 phentsize; // Tamaño por entidad
	u16 phnum;     // Entidades

	// SectionHeaders
	u16 shentsize; // Tamaño por entidad
	u16 shnum;     // Entidades

	u16 shstrndx;  // Índice de una sección especial que indica los nombres de las secciones
}

// Los Elf pueden contener uno o mas ProgramHeader
struct ElfProgramHeader {
	u32 type;
	u32 offset;
	u32 vaddr;
	u32 paddr;
	u32 filesz;
	u32 memsz;
	u32 flags;
	u32 _align;
	u32 *pdata;
}

// Los Elf pueden contener diversas secciones
struct ElfSectionHeader {
	u32 name;
	u32 type;
	u32 flags;
	u32 addr;
	u32 offset;
	u32 size;
	u32 link;
	u32 info;
	u32 addralign;
	u32 entsize;
}

// Los Elf pueden tener secciones que indiquen relocs
struct ElfReloc {
	u32 offset;

	enum Type : u8 {
		MIPS_NONE     = 0,
		MIPS_16       = 1,
		MIPS_32       = 2,
		MIPS_REL32    = 3,
		MIPS_26       = 4,
		MIPS_HI16     = 5,
		MIPS_LO16     = 6,
		MIPS_GPREL16  = 7,
		MIPS_LITERAL  = 8,
		MIPS_GOT16    = 9,
		MIPS_PC16     = 10,
		MIPS_CALL16   = 11,
		MIPS_GPREL32  = 12
	} Type type;

	u8 offph;
	u8 valph;
	u8 unknown;
}

extern(C) int __elfreloccompare(void *_a, void *_b) {
	ElfReloc* a = cast(ElfReloc *)_a, b = cast(ElfReloc *)_b;
	if (a.offph != b.offph) return a.offph - b.offph;
	if (a.valph != b.valph) return a.valph - b.valph;
	return a.offset - b.offset;
}

int getasciilen(char *p) {
	char *cp;
	for (cp = p; *cp != 0; cp++) {
		switch (*cp) {
			case 0x01: if (*(cp + 1) == 3) { cp++; continue; } break;
			case 0xe2: case '\n': case '\r': case '\t': continue;
			case 0x81: case 0x82: case 0x83: case 0x84: cp++; continue;
			default: break;
		}
		if (*cp < ' ' || *cp > 0x86) return 0;
	}
	if (cp - p <= 1) return 0;
	while (((++cp - p) % 4) != 0) if (*cp != 0) return 0;
	return cp - p;
}

// Indicamos si una cierta dirección de memoria puede contener alguna cadena ascii
bool isascii(char *p) {
	return getasciilen(p) > 0;
}

// Obtenemos un stringz dada una dirección de memoria
char[] getstr(char *ptr) {
	char temp[10];
	char[] r;

	for (; *ptr != 0; ptr++) {
		char c = *ptr;

		switch (c) {
			case 0x81: case 0x82: case 0x83: case 0x84:
				sprintf(temp.ptr, "<%02X%02X>", c, *(++ptr));
				r ~= toString(temp.ptr);
				continue;
			break;
			default: break;
		}

		if (c == '\n') { sprintf(temp.ptr, "\\n"); r ~= toString(temp.ptr); continue; }
		if (c == '\r') { sprintf(temp.ptr, "\\r"); r ~= toString(temp.ptr); continue; }
		if (c == '\t') { sprintf(temp.ptr, "\\t"); r ~= toString(temp.ptr); continue; }

		if (c < ' ' || c == '<' || c == '>') {
			sprintf(temp.ptr, "<%02X>", c);
			r ~= toString(temp.ptr);
			continue;
		}

		if (c > 0x7f) {
			sprintf(temp.ptr, "<%02X>", c);
			r ~= toString(temp.ptr);
			continue;
		}

		sprintf(temp.ptr, "%c", c);
		r ~= toString(temp.ptr);
	}

	return r;
}

int getasciilen2(char *p) {
	char *cp;
	for (cp = p; *cp != 0; cp++) {
		switch (*cp) {
			case 0xe2: case '\n': case '\r': case '\t': continue;
			case 0x81: case 0x82: case 0x83: case 0x84: case 0x85: cp++; continue;
			default: break;
		}
		if (*cp > 0x86) return 0;
	}
	if (cp - p <= 1) return 0;
	while (((++cp - p) % 4) != 0) if (*cp != 0) return 0;
	return cp - p;
}

// Indicamos si una cierta dirección de memoria puede contener alguna cadena ascii
bool isascii2(char *p) {
	return getasciilen2(p) > 0;
}

uint decodeHiLo(uint hi, uint lo) {
	uint r;
	r = (hi & 0xFFFF) << 16;

	if ((lo >> 26) == 0xD) {
		r |= lo & 0xFFFF;
	} else {
		r = cast(s32)r + cast(s16)(lo & 0xFFFF);
	}

	return r;
}

// ADDIU 001001ssssstttttiiiiiiiiiiiiiiii
// ORI   001101ssssstttttiiiiiiiiiiiiiiii

/*void encodeHiLo(inout uint hi, inout uint lo, uint addr) {
	// LUI
	hi &= ~0xFFFF; hi |= (addr >> 16) & 0xFFFF;

	// ORI
	uint regs = ((lo << 6) >> 22);
	lo = (0xD << 26) | (regs << 16) | (addr & 0xFFFF);
}*/

void encodeHiLo(inout uint hi, inout uint lo, uint addr) {
	bool show = false;

	//if (((lo >> 26) != 0xD) && (addr & 0x8000)) show = true;
	if (show) {
		printf("%08X\n", addr);
		printf("%08X %08X (%08X)\n", hi, lo, decodeHiLo(hi, lo));
	}

	hi &= ~0xFFFF; lo &= ~0xFFFF;
	lo |= addr & 0xFFFF;

	// Si no es un ori y tiene signo
	if (((lo >> 26) != 0xD) && (addr & 0x8000)) {
		//printf("LOL");
		addr += 0x10000;
	}

	hi |= (addr >> 16) & 0xFFFF;

	if (show) {
		printf("%08X %08X (%08X)\n", hi, lo, decodeHiLo(hi, lo));
		printf("\n");
	}
}

/*int main() {
	FILE* unfout, unfoutun, grfout;
	char[] file;
	char* pt;
	int dwBase = 0x4000;
	char *strptr = null;
	struct __hirelt {
		u32  addr;
		u8   ori;
		u32 *inst;
	} __hirelt regs[32];
	ElfReloc[] erl;
	ElfHeader h;
	ElfProgramHeader[] ep;
	ElfSectionHeader[] es;
	uint[][uint] href;


	// Cargamos el fichero en memoria
	file = cast(char[])read("SLUS_213.86");

	// Carga el ElfHeader
	h = *cast(ElfHeader *)file;

	Dump(h);

	if (h.magic != 0x464C457F) throw(new Exception("No es un fichero ELF válido"));

	// Carga los ElfProgramHeader
	ep = new ElfProgramHeader[h.phnum];
	pt = &file[0] + h.phoff;
	for (int n = 0; n < h.phnum; n++) { ep[n] = *cast(ElfProgramHeader *)pt; pt += h.phentsize; }

	// Carga los ElfSectionHeader
	es = new ElfSectionHeader[h.shnum];
	pt = &file[0] + h.shoff;
	for (int n = 0; n < h.shnum; n++) {
		es[n] = *cast(ElfSectionHeader *)pt;
		if (n == h.shstrndx) {
			strptr = cast(char *)(&file[0] + es[n].offset);
		}
		pt += h.shentsize;
	}

	exit(-1);

	// Se recorre las secciones buscando secciones de relocs
	for (int n = 0; n < h.shnum; n++) {
		if (es[n].type != 0x700000A0) continue;
		int count = es[n].size / es[n].entsize;
		pt = cast(char *)(&file[0] + es[n].offset);
		for (int m = 0; m < count; m++) {
			erl ~= *cast(ElfReloc *)pt;
			pt += es[n].entsize;
		}
	}

	// Comprueba que hay relocs en la lista
	if (erl.length <= 0) {
		writefln("No se han encontrado relocs");
		exit(-1);
	}
}*/
