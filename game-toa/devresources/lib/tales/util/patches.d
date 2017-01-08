module tales.util.patches;

import tales.common;
import tales.util.rangelist, tales.util.gameformat;
import std.stdio, std.file, std.format, std.stream, std.path, std.string, std.ctype, std.c.stdlib, std.regexp, std.string;

void patchMIPSLoadAdress(ref int lui, ref int add, int naddr) {
	lui &= 0b01111111111111110000000000000000;
	lui |= (naddr >> 16) & 0xFFFF;
		
	add &= 0b11111111111111110000000000000000;
	add |= (naddr >> 0) & 0xFFFF;
	
	add &= 0b00000011111111111111111111111111;
	add |= 0b00110100000000000000000000000000;
}

void mipsPatch(Stream fi, InputStream fp) {
	//TOAGameFormatString fs = new TOAGameFormatString;
	bool doPointers = true;
	
	enum PatchType {
		FIXED,
		POINTER,
		CODE,		
	}
	
	struct Patch {
		PatchType type;
		int p1, p2;
	}
	
	struct PatchText {
		int fixedPtr = 0;
		Patch[] patches;
	}
	
	PatchText[char[]] ptl;
	
	PatchText* getPatchText(char[] text) {
		if ((text in ptl) is null) ptl[text] = PatchText();
		return &ptl[text];
	}
	
	Patch* addNewPatch(char[] text, int fixed = -1) {
		PatchText* pt = getPatchText(text);
		pt.patches.length = pt.patches.length + 1;
		Patch *p = &pt.patches[pt.patches.length - 1];
		if (fixed != -1) pt.fixedPtr = fixed;
		return p;
	}
	
	int base = 0;
	RangeList rl = new RangeList;
	
	int mem2file(int mem) {
		assert(base <= mem);
		return mem - base;
	}
	
	void prepareText(PatchText* pt, char[] rtext) {
		// Debemos encontrar un sitio para el nuevo texto
		if (pt.fixedPtr != 0) return;
		pt.fixedPtr = rl.getAndUse(rtext.length);		
		
		// Escribimos texto
		fi.position = mem2file(pt.fixedPtr);
		fi.write(cast(ubyte[])rtext);
	}
	
	bool commented = false;
	
	while (!fp.eof) {
		char[] l = std.string.stripl(fp.readLine());
		if (!l.length || l[0] == '#') continue;
			
		if (commented) {
			if (l.length >= 2 && l[0..2] == "*/") commented = false;
			continue;
		}
			
		switch (l[0]) {
			case '/':
				if (l.length >= 2 && l[1] == '*') {
					commented = true;
				}
			break;
			case 'B': // Base
				char[][] list = split2(l, ":", 2);
				base = getdhvalue(list[1]);
			break;
			case 'R': // Range
				char[][] list = std.string.split(std.string.split(l, ":")[1], "-");
				int[] ptrs = [getdhvalue(list[0]), getdhvalue(list[1])];
				rl.add(ptrs[0], ptrs[1] - ptrs[0]);
			break;
			case 'F': // Fixed				
				char[][] list = split2(l, ":", 4);
				int pos = getdhvalue(list[1]), len = getdhvalue(list[2]);
				char[] text = list[3];
				{
					Patch *p = addNewPatch(text, pos);
					p.type = PatchType.FIXED;
					p.p1 = pos;
					p.p2 = len;
				}
			break;
			case 'T': // TextPointer
				char[][] list = split2(l, ":", 3);
				int pos = getdhvalue(list[1]);
				char[] text = list[2];
				{
					Patch *p = addNewPatch(text);
					p.type = PatchType.POINTER;
					p.p1 = pos;
				}
			break;
			case 'C': // Code
				char[][] list = split2(l, ":", 4);
				int pos1 = getdhvalue(list[1]), pos2 = getdhvalue(list[2]);
				char[] text = list[3];
				{
					Patch *p = addNewPatch(text);
					p.type = PatchType.CODE;
					p.p1 = pos1;
					p.p2 = pos2;
				}				
			break;
		}
	}
		
	char[] rtext;
	
	char[][] tll = ptl.keys;
	for (int n = 0; n < tll.length; n++) {
		for (int m = n + 1; m < tll.length; m++) {
			if (tll[m].length > tll[n].length) {
				char[] t = tll[m];
				tll[m] = tll[n];
				tll[n] = t;
			}
		}
	}
	
	try {
		foreach (char[] text; tll) {
			PatchText pt = ptl[text];
			//char[] rtext = uncodestring(text);
			//char[] rtext = fs.encodeString(text) ~ "\0";
			rtext = stripcslashes(text) ~ "\0";
			//printf("%d\n", text.length);
			//printf("'%s' (%d)\n", toStringz(rtext), rtext.length); rl.show();
			foreach (Patch p; pt.patches) {
				switch (p.type) {
					case PatchType.FIXED:
						int pos = p.p1, len = p.p2;
						if (rtext.length > len) throw(new Exception(std.string.format("Too much space in '%s'", rtext)));
						fi.position = mem2file(pos);
						fi.write(cast(ubyte[])rtext);
					break;
					case PatchType.POINTER:
						if (doPointers) {
							int ptr = p.p1;
							
							prepareText(&pt, rtext);						
							
							// Escribimos puntero
							fi.position = mem2file(ptr);
							fi.write(cast(uint)(pt.fixedPtr));
						}
					break;
					case PatchType.CODE:
						if (doPointers) {
							int i1 = p.p1, i2 = p.p2;
							int start = pt.fixedPtr;
							
							int c1, c2;
		
							prepareText(&pt, rtext);
							
							fi.position = mem2file(i1); fi.read(c1);
							fi.position = mem2file(i2); fi.read(c2);
							
							patchMIPSLoadAdress(c1, c2, pt.fixedPtr);
		
							fi.position = mem2file(i1); fi.write(c1);
							fi.position = mem2file(i2); fi.write(c2);
						}
					break;
				}
			}
		}	
	} catch (Exception e) {
		rl.show();
		printf("La cadena '%s' no coge\n", toStringz(rtext));
		throw(e);
	}
}