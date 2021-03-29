/*
	Reinsertor Genérico para ficheros DAT del Tales of the Abyss
*/

import std.stdio, std.stream, std.file, std.string, std.date;
import tales.util.gameformat, tales.common, tales.util.rangelist;
import tales.scont.generic, tales.scont.iso;
import tales.isopath;

version = alignfake;

version(alignfake) {
	alias StreamWriteStringR2Fake StreamWriteStringR2Final;
} else {
	alias StreamWriteStringR2 StreamWriteStringR2Final;
}

TOAGameFormatString fs;

const int EXE_DISP = (0x100000 - 0x100);

int mem2file(int addr) { return addr - EXE_DISP; }
int file2mem(int addr) { return addr + EXE_DISP; }

void Create_TITLES_Stream(Stream s, Stream fin, bool autoclose = true) {
	struct title {
		char[] name;
		char[] desc;
	}
	int[] count = [21, 17, 15, 15, 15, 13, 3];
	title[][int] titles;

	int type = -1;	
	int status = 0;
	while (!fin.eof) {
		char[] line = std.string.strip(fin.readLine());
		
		if (line.length >= 1 && line[0] == '*') {
			type = std.conv.toInt(line[1..line.length]);
			status = 0;
			continue;
		}		
		
		if (type == -1) continue;
		if (line.length) {
			if (status == 0) {
				titles[type].length = titles[type].length + 1;
				titles[type][titles[type].length - 1].name = line;
				titles[type][titles[type].length - 1].desc = "";
				status = 1;
			} else {
				if (titles[type][titles[type].length - 1].desc.length) titles[type][titles[type].length - 1].desc ~= "\n";
				titles[type][titles[type].length - 1].desc ~= line;
			}
		} else {
			status = 0;
		}
	}
	
	//for (int n = 0; n < 4; n++) writefln(titles[0][n].desc);
	//return;
	
	// RANGO de texto:
	// 005C6350-005C9000
	RangeList rl = new RangeList();
	
	rl.add(0x005C6350, 0x005C9000 - 0x005C6350);
	
	{
		s.position = mem2file(0x005C6350);
		ubyte[] temp; temp.length = 0x005C9000 - 0x005C6350;
		s.write(temp);
	}
	
	s.position = mem2file(0x00567F6C);
	s.seek(4, SeekPos.Current);
	
	Stream wr = new SliceStream(s, 0);
	
	for (int n = 0; n < 7; n++) {
		uint ptr;
		s.read(ptr);		
		Stream ss = new SliceStream(s, mem2file(ptr));		
		for (int m = 0; m < count[n]; m++) {
			uint tptr, dptr;
			ss.seek(4, SeekPos.Current);
			
			{
				char[] str = fs.encodeString(titles[n][m].name) ~ "\0";			
				int pos = rl.getAndUse(str.length);			
				//StreamWritePointerAt(ss, pos);
				ss.write(cast(uint)pos);
				wr.position = mem2file(pos);
				StreamWriteStringR2Final(wr, str);						
			}
			
			{
				char[] str = fs.encodeString(titles[n][m].desc) ~ "\0";			
				int pos = rl.getAndUse(str.length);			
				//StreamWritePointerAt(ss, pos);
				ss.write(cast(uint)pos);
				wr.position = mem2file(pos);
				StreamWriteStringR2Final(wr, str);						
			}
		}
		//break;
	}
}

/*void Extract_TITLES_Stream(Stream s, char[] path, bool autoclose = true) {
	int[] count = [21, 17, 15, 15, 15, 13, 3];
	
	// RANGO de texto:
	// 005C6350-005C9000
	RangeList rl = new RangeList();
	
	rl.add(0x005C6350, 0x005C9000 - 0x005C6350);
	
	s.position = mem2file(0x00567F6C);
	s.seek(4, SeekPos.Current);
	
	for (int n = 0; n < 7; n++) {
		uint ptr;
		s.read(ptr);		
		Stream ss = new SliceStream(s, mem2file(ptr));
		writefln("*CHARACTER-%d\n", n);
		for (int m = 0; m < count[n]; m++) {
			uint tptr, dptr;
			ss.seek(4, SeekPos.Current);
			
			char[] str = fs.encodeString(titles[n]);
			
			int pos = rl.getAndUse(str.length);
			
			StreamWritePointerAt(ss, pos);
			StreamWriteStringR2Final(s, str);
			
			ss.read(tptr);
			ss.read(dptr);
			char[] name = fs.extractStringz(s, mem2file(tptr));
			char[] desc = fs.extractStringz(s, mem2file(dptr));
			writefln("%s\n%s\n", name, desc);
		}
		//break;
	}
}*/

int main(char[][] args) {
	fs = new TOAGameFormatString;
	AbyssInitIsoPath();

	if (args.length < 2) {
		writefln("Reinsertor EXE para Tales of the Abyss");
		writefln("");
		writefln("Drivers:");
		writefln("\tjournal, titles");
		writefln("");
		writefln("modo de uso: reinsert driver [file.in] [file.out]");
	} else {
		char[] driver = std.string.tolower(std.string.strip(args[1])), filein;
		filein = (args.length > 2) ? args[2] : format("%s.es.txt", driver);
		switch (driver) {
			case "journal":
				/*
				Stream mod = new File((args.length > 3) ? args[3] : "_ACS_.DAT", FileMode.OutNew);

				Create_ACS_Stream(
					isoroot["_ACS_.DAT"].open,
					new File(filein, FileMode.In),
					mod
				);

				mod.close();
				*/
			break;
			case "titles":
				Create_TITLES_Stream(new File("SLUS_213.86", FileMode.In | FileMode.Out), new File("titles.es.txt"));
			break;
			default:
				writefln("Extractor para '%s' no implementado", driver);
			break;
		}
	}

	return 0;
}
