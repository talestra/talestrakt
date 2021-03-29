module tales.isopath;
import tales.scont.generic, tales.scont.iso;

import std.stdio, std.file, std.format, std.stream, std.path, std.string, std.ctype, std.c.stdlib;

public Iso iso, isonpc, isobtl, isoev, isomap, isomov, isobgm, isoroot, isose;

//version = debug_path;

void AbyssInitIsoPath() {
	const int maxn = 5;
	int n;
	char[] file = "isopath.txt";
	char[] filename;
	
	version(debug_path) printf("[1]");
	
	for (n = 0; n < maxn; n++) {
		if (std.file.exists(file)) break;
		file = "../" ~ file;
	}
	
	version(debug_path) printf("[2]");

	if (n == maxn) {
		file = "isopath";
		for (n = 0; n < maxn; n++) {
			if (std.file.exists(file ~ ".default.txt")) break;
			file = "../" ~ file;
		}
		copy(file ~ ".default.txt", file ~ ".txt");
		file ~= ".txt";
	}
	
	version(debug_path) printf("[3]");

	if (n == maxn) throw(new Exception("Can't locate 'isopath.txt'"));

	filename = std.string.strip(cast(char[])read(file));

	if (!std.file.exists(filename)) {
		while (!std.file.exists(filename)) {
			writefln("La ISO no existe definida en '%s'\nISO: '%s'\nEscribir nueva direccion:\n", file, filename);
			filename = std.string.strip(readln());
			writefln();
		}
		write(file, filename);
	}
	
	version(debug_path) printf("[4]");

	//writefln("tales.isopath: '%s'\n", filename);
	
	version(debug_path) writef("[%s]", filename);

	iso     = new Iso(filename, true);
	
	version(debug_path) printf("[.]");
	
	isonpc  = new Iso(iso["TO7NPC.CVM" ].open);
	version(debug_path) printf("[a]");
	isobtl  = new Iso(iso["TO7BTL.CVM" ].open);
	version(debug_path) printf("[b]");
	isoev   = new Iso(iso["TO7EV.CVM"  ].open);
	version(debug_path) printf("[c]");
	isomap  = new Iso(iso["TO7MAP.CVM" ].open);
	version(debug_path) printf("[d]");
	isomov  = new Iso(iso["TO7MOV.CVM" ].open);
	version(debug_path) printf("[e]");
	isobgm  = new Iso(iso["TO7BGM.CVM" ].open);
	version(debug_path) printf("[f]");
	isoroot = new Iso(iso["TO7ROOT.CVM"].open);
	version(debug_path) printf("[g]");
	isose   = new Iso(iso["TO7SE.CVM"  ].open);
	version(debug_path) printf("[h]");
}
