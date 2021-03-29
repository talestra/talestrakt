import std.stdio, std.file, std.string, std.stream;

char[][] split2(char[] s, char[] sub, uint count = 0x7FFFFFFF) {
	char[][] r = split(s, sub);
	if (count < 1) count = 1;
	if (r.length > count) r = r[0..count - 1] ~ std.string.join(r[count - 1..r.length], sub);
	return r;
}

void writeln(char[] s = "") {
	printf("%s\n", toStringz(s));
}

uint intFromBase(char[] s, int base = 10, bool _throw = true) {
	int r;
	foreach (c; s) { c = std.ctype.toupper(c);
		int v;
		if (0) {}
		else if (c >= '0' && c <= '9') v = c - '0';
		else if (c >= 'A' && c <= 'Z') v = c - 'A' + 10;
		if (v < base) {
			r *= base;
			r += v;
		} else if (_throw) {
			throw(new Exception("Invalid char"));
		}
	}
	return r;
}

char[][uint] getACME1(char[] s) {
	char[][uint] r;
	s = replace(s, "\r", "");
	foreach (token; std.string.split(s, "## POINTER ")) {
		int pos; //if ((pos = std.string.find(token, "\n")) == -1) continue;
		if (token.length == 0) continue;
		char[][] lines = split2(token, "\n", 2);
		int k = intFromBase(std.string.split(lines[0], " ")[0], 10);
		r[k] = (lines.length > 1) ? std.string.stripr(lines[1]) : "";
	}
	return r;
}

	
struct Item {
	char[] name;
	char[] desc;
};

Item[] getItems(char[] fin) {
	return getItems(new File(fin));
}

Item[] getItems(Stream fin) {
	Item[] items;
	char[][] t2l;

	int type = 0, state = 0;
	while (!fin.eof) {
		auto line = std.string.strip(fin.readLine());
		
		if (line.length >= 1 && line[0] == '*') {
			switch (line[1..line.length]) {
				case "TYPE1": type = 1; state = 0; break;
				case "TYPE2": type = 2; break;
			}
			continue;
		}
		
		if (type == 1) {
			if (!line.length) { state = 0; continue; }
				
			if (state == 0) {
				// Titulo
				items.length = items.length + 1;
				items[items.length - 1].name = line;				
				items[items.length - 1].desc = "";
				state = 1;
			} else {
				// Descripcion aditiva
				if (items[items.length - 1].desc.length > 0) items[items.length - 1].desc ~= "\n";
				items[items.length - 1].desc ~= line;
			}			
		} else  if (type == 2) {
			if (!line.length) continue;
			t2l ~= line;
		}
	}
	
	return items;
}

void main() {
	char[] acme, acme_es;
	for (int n = 0; n < 32; n++) acme ~= cast(char[])read(format("items.en/%04d.txt", n)) ~ "\n\n\n";
	for (int n = 0; n < 32; n++) acme_es ~= cast(char[])read(format("items/%04d.txt", n)) ~ "\n\n\n";
	auto ac = getACME1(acme);
	auto ac_es = getACME1(acme_es);
	auto it = getItems("i.en.txt");
	auto it_es = getItems("i.es.txt");
	
	writefln("*TYPE1");
	
	for (int n = 0; n < 630; n++) {
		char[] title, desc;
		try {
			title = strip(ac[(n + 1) * 10 + 0]);
			desc  = strip(ac[(n + 1) * 10 + 1]);
			
			char[][] descs = split(desc, "\n");
			for (int m = 0; m < descs.length; m++) descs[m] = stripr(descs[m]);
			desc = join(descs, "\n");
			
			if (desc != it[n].desc) {
				writeln(it_es[n].name);
				writeln(it_es[n].desc);
				//writefln("%03d: %s", n, title);
				//writefln("'%s'", desc);
				//writefln("'%s'", it[n].desc);
				//writeln(desc);
				//writefln("%d,%d", desc.length, it[n].desc.length);
			} else {
				writeln(ac_es[(n + 1) * 10 + 0]);
				writeln(ac_es[(n + 1) * 10 + 1]);
			}
		} catch {
			writeln(it_es[n].name);
			writeln(it_es[n].desc);
		}
		writefln();
	}
}
