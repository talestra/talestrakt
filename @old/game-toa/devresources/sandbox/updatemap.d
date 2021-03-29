import tales.streamcontainer, tales.isocontainer;

private import std.file, std.string, std.stdio, std.path, std.regexp, std.stream, std.system, std.c.stdlib, std.gc;

Stream openfile(char[] name) { return new File(name, FileMode.In); }

// Intercamia el mapa inicial por el de debug
/*void SwapStartMap(Iso map) {
	IsoEntry testmap  = map["TESTMAP.PKB"];
	IsoEntry startmap = map["CAP_I06_05.PKB"];

	int extent, size;

	extent = testmap.dr.Extent;
	size   = testmap.dr.Size;

	testmap.dr.Extent = startmap.dr.Extent;
	testmap.dr.Size   = startmap.dr.Size;

	startmap.dr.Extent = extent;
	startmap.dr.Size = size;

	startmap.writedr();
	testmap.writedr();
}*/

int main(char[][] args) {
	Iso iso = new Iso("c:\\juegos\\abyss\\abyss.iso");
	Iso root = new Iso(iso["TO7ROOT.CVM"].open);
	Iso map  = new Iso(iso["TO7MAP.CVM"].open);
	Iso mov  = new Iso(iso["TO7MOV.CVM"].open);

	iso["SLUS_213.86"].replace("../SLUS_213.86");

	map.swap("TESTMAP.PKB", "CAP_I06_05.PKB");
	//map["TESTMAP.PKB"].replace();

    //mov["AS_001.SFD"].replace("..\\videos\\AS_002_SUB.MPG");

	//iso["SLUS_213.86"].replace("SLUS_213.86");

	//

	/*
	writefln("S_TOA_LOGO.TM2");
	root["S_TOA_LOGO.TM2"].replace("..\\..\\TO7ROOT\\S_TOA_LOGO\\S_TOA_LOGO.TM2");
	writefln("_S_MENU.TM2");
	root["_S_MENU.TM2"].replace("..\\..\\TO7ROOT\\_S_MENU\\_S_MENU.TM2");
	*/

	/*
	Iso map  = new Iso(iso["TO7MAP.CVM"].open);

	//for (int n = 0; n <= 7; n++) {
	for (int n = 5; n <= 5; n++) {
		writefln("CAP_I06_%02d.B", n);
		system(toStringz(format("comptoe.exe -s -c3 \"%s\\B\\CAP_I06_%02d.B\" \"%s\\temp\"", getcwd(), n, getcwd())));
		map[format("CAP_I06_%02d.PKB", n)].replace("temp");
	}
	*/

	//SwapStartMap(map);

	return 0;
}
