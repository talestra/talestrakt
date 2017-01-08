import std.file, std.string, std.stdio, std.c.stdlib, std.path, std.regexp, std.stream;

import tales.isopath;
import tales.util.gameformat, tales.scont.generic, tales.scont.iso;
import tales.util.rangelist, tales.util.gameformat;
import tales.image.txd;
import tales.scont.fps3, tales.comp, tales.sb7;

version = writeexe;

Stream exe;

uint getdhvalue(char[] s) {
	uint r = 0, d, l = s.length;
	for (int n = 0; n < l; n++) {
		char c = s[n];
		if (c >= '0' && c <= '9') d = c - '0';
		else if (c >= 'a' && c <= 'f') d = c - 'a' + 0x0a;
		else if (c >= 'A' && c <= 'F') d = c - 'A' + 0x0a;
		else { d = 0; throw(new Exception("Invalid hex digit (" ~ c ~ ")")); }
		r |= d; r <<= 4;
	} r >>= 4;

	return r;
}

char[] stripcslashes(char[] s) {
	int n, p; char[] r; r.length = s.length;	
	for (n = 0, p = 0; n < s.length; n++) {
		char c = s[n];
		if (c == '\\') {
			switch (c = s[++n]) {
				case '\\': c = '\\'; break;
				case '\'': c = '\''; break;
				case '0' : c = '\0'; break;
				case 'a' : c = '\a'; break;
				case 'b' : c = '\b'; break;
				case 'n' : c = '\n'; break;
				case 'r' : c = '\r'; break;
				case 't' : c = '\t'; break;
				case 'v' : c = '\v'; break;
				case 'x' :
					c = getdhvalue(s[n + 1..n + 3]);
					n += 2;
				break;
				default:
					throw(new Exception("Invalid escape character"));
				break;
			}			
		}
		r[p++] = c;
	}
	r.length = p;
	return r;
}

int mem2file(int addr) { return addr - 0xfff00; }

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
				printf("[%08X-%08X]\n", start, end);
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
				
				printf("  '%s'\n", toStringz(ss));
			break;
			case '#':
				printf("  %s\n", toStringz(line));
			break;
			case '/':
				ignoring = true;
			break;
			default:
				printf("Skipping: %s\n", toStringz(line));
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

int main() {	
	copy("../../SLUS_213.86.BACK", "../../SLUS_213.86");

	exe = new File("../../SLUS_213.86", FileMode.In | FileMode.Out);
		
	reinsertPoiner32List("actionlist.txt");
	
	exe.close();
	
	chdir("..");
	system("micropatch.bat");
	
	return 0;
}