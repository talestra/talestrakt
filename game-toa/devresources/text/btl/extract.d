import std.stdio, std.stream, std.file, std.string, std.process;
import tales.util.gameformat, tales.isopath, tales.scont.generic, tales.scont.iso;
import tales.scont.fps2, tales.sb7;
import tales.comp, sqlite3;

int main(char[][] args) {	
	uint count;	
	/*
	File f = new File("../../BTL_USU.BIN");
	f.read(count);
	for (int n = 0; n < count; n++) {
		int p;
		ubyte cc;
		f.read(p);
		Stream sf = new SliceStream(f, p);
		sf.read(cc);
		writefln("%08X : %02X", p, cc);
		if (cc == 0x3) {
			sf.position = 0;
			(new File(std.string.format("PAK_%d", n), FileMode.OutNew)).copyFrom((new CompressedStream(sf)));
			//(new File(std.string.format("PAK_%d", n), FileMode.OutNew)).copyFrom(sf);
			//break;
		}
	}*/
	
	File f = new File("PAK_0");
	f.read(count);
	int pb;
	f.read(pb);
	for (int n = 0; n < count - 1; n++) {
		int p;
		f.read(p);
		(new File(std.string.format("%d.tm2", n), FileMode.OutNew)).copyFrom(new SliceStream(f, pb, p));
		//writefln("%08X", p - pb);
		pb = p;
	}

	
	return 0;
}

/*
00000060 : 03
000185E0 : 42
0001E160 : 42
0002F220 : 07
000321A0 : 07
00036D60 : 9D
00085860 : 42
00094FE0 : 42
0009CD20 : 03
000E7720 : 00
000E7920 : 00
000E7E20 : 00
000E84A0 : 00
000E8760 : B4
000E8B60 : 0B (text)
000F7F60 : 0D
000F7FA0 : 07
000FB560 : 00
000FC520 : 00
000FC620 : 00
000FCB20 : 90
000FCEE0 : 0D
*/
