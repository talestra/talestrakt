import std.file, std.string, std.stdio, std.c.stdlib, std.path, std.regexp, std.stream;

import tales.isopath;
import tales.util.gameformat, tales.scont.generic, tales.scont.iso;
import tales.util.rangelist, tales.util.gameformat;
import tales.image.txd;
import tales.scont.fps3, tales.comp, tales.sb7;

int main() {
	AbyssInitIsoPath();

	writefln("_S_MENU.TM2");
	isoroot["_S_MENU.TM2"].replace("_S_MENU/_S_MENU.TM2");
	writefln("S_NAMCOLOGO.TM2");
	isoroot["S_NAMCOLOGO.TM2"].replace("S_NAMCOLOGO/S_NAMCOLOGO.TM2");
	writefln("S_TOA_LOGO.TM2");
	isoroot["S_TOA_LOGO.TM2"].replace("S_TOA_LOGO/S_TOA_LOGO.TM2");

	return 0;
}