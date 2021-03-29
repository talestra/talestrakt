import std.file, std.stream, std.string, std.stdio, std.regexp;
import common, utils, lzsimple;

void patchEvents() {
	ubyte[][] creditos;
	
	creditos ~= cast(ubyte[])import("0000.tim");
	creditos ~= cast(ubyte[])import("0001.tim");
	creditos ~= cast(ubyte[])import("0002.tim");
	creditos ~= cast(ubyte[])import("0003.tim");
	creditos ~= cast(ubyte[])import("0004.tim");
	creditos ~= cast(ubyte[])import("0005.tim");
	creditos ~= cast(ubyte[])import("0006.tim");
	creditos ~= cast(ubyte[])import("0007.tim");
	creditos ~= cast(ubyte[])import("0008.tim");
	creditos ~= cast(ubyte[])import("0009.tim");
	creditos ~= cast(ubyte[])import("0010.tim");
	creditos ~= cast(ubyte[])import("0011.tim");
	creditos ~= cast(ubyte[])import("0012.tim");
	creditos ~= cast(ubyte[])import("0013.tim");
	creditos ~= cast(ubyte[])import("0014.tim");
	creditos ~= cast(ubyte[])import("0015.tim");
	creditos ~= cast(ubyte[])import("0016.tim");
	creditos ~= cast(ubyte[])import("0017.tim");
	creditos ~= cast(ubyte[])import("0018.tim");
	creditos ~= cast(ubyte[])import("0019.tim");
	
	auto pointers = new SliceStream(new BufferedFile(tempDir ~ "/SLUS_006.26"), 0xF3508, 0xF3638);
	
	//writefln("[1]");
	auto pak_ori  = new PAK(new SliceStream(new BufferedFile(tempDir ~ "/SLUS_006.26"), 0xF3508, 0xF3638), new BufferedFile(tempDir ~ "/E.DAT"), true);
	auto pak_mod  = new PAK(new SliceStream(new File(tempDir ~ "/SLES_106.26", FileMode.In | FileMode.Out), 0xF3508, 0xF3638), new File(tempDir ~ "/E_SPA.DAT", FileMode.OutNew), false);
	//writefln("[2]");
	auto pak_credits = SELFPAK(pak_ori[29]);
	//writefln("[3]");
	for (int n = 0; n < creditos.length; n++) {
		//writefln("[4][%d]", n);
		pak_credits[n] = Compression.Compress(new MemoryStream(creditos[n]));
	}
	//writefln("[5]");
	foreach (k, s; pak_ori) {
		//writefln("[5][%d]", k);
		if (k == 29) {
			pak_mod.addFile(pak_credits.stream);
		} else {
			pak_mod.addFile(s);
		}
	}
	//writefln("[6]");
	pak_ori.close();
	pak_mod.close();
}