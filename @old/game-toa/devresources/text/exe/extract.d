/*
	Extractor Genérico para ficheros DAT del Tales of the Abyss
*/

import std.stdio, std.stream, std.file, std.string;
import tales.util.gameformat, tales.isopath, tales.scont.generic, tales.scont.iso;

GameFormatString fs;

const uint fileoffset = 0x4839D0 - 0x5838D0;

uint mem2file(uint mem)  { return mem + fileoffset; }
uint file2mem(uint file) { return file - fileoffset; }

void Extract_JOURNAL_Stream(Stream s, char[] path, bool autoclose = true) {
	uint titleptr, dataword, textptr;

	try { std.file.mkdir(path); } catch (Exception e) { }
	try { std.file.mkdir(path ~ "/en/"); } catch (Exception e) { }

	s.position = 0x43E150;
	for (int n = 0; n < 114; n++) {
		uint m = 1;
		File f = new File(format("%s/en/%04d.txt", path, n), FileMode.OutNew);

		s.read(titleptr);
		writeTextPointer(f, 0, fs.extractStringz(s, mem2file(titleptr)));

		s.seek(4, SeekPos.Current);
		while (!s.eof) {
			s.read(dataword);
			if (dataword == 0x5838E8) {
				s.seek(12, SeekPos.Current);
				s.read(textptr);
				writeTextPointer(f, m++, fs.extractStringz(s, mem2file(textptr)));
				m++;
			} else if (dataword == 0x583D80) {
				while (!s.eof) { s.read(dataword); if (dataword != 0) break; }
				s.seek(-4, SeekPos.Current);
				break;
			}
		}

		f.close();
	}

	if (autoclose) { s.close(); }
}

void Extract_TITLES_Stream(Stream s, char[] path, bool autoclose = true) {
	int[] count = [21, 17, 15, 15, 15, 13, 3];
	
	// RANGO de texto:
	// 005C6350-005C9000
	
	s.position = mem2file(0x00567F6C);
	s.seek(4, SeekPos.Current);
	
	for (int n = 0; n < 7; n++) {
		uint ptr;
		s.read(ptr);		
		Stream ss = new SliceStream(s, mem2file(ptr));
		writefln("*%d\n", n);
		for (int m = 0; m < count[n]; m++) {
			uint tptr, dptr;
			ss.seek(4, SeekPos.Current);
			ss.read(tptr);
			ss.read(dptr);
			char[] name = fs.extractStringz(s, mem2file(tptr));
			char[] desc = fs.extractStringz(s, mem2file(dptr));
			writefln("%s\n%s\n", name, desc);
		}
		//break;
	}
}

int main(char[][] args) {
	AbyssInitIsoPath();

	fs = new TOAGameFormatString();

	if (args.length < 2) {
		writefln("Extractor EXE para Tales of the Abyss");
		writefln("");
		writefln("Drivers:");
		writefln("\tjournal, titles");
		writefln("");
		writefln("modo de uso: extract driver [file.out]");
	} else {
		char[] driver = std.string.tolower(std.string.strip(args[1])), fileout;
		//fileout = (args.length > 2) ? args[2] : format("%s.en.txt", driver);
		switch (driver) {
			case "journal": // Journal de Luke
				Extract_JOURNAL_Stream(
					iso["SLUS_213.86"].open,
					driver
				);
			break;
			case "titles": // Journal de Luke
				Extract_TITLES_Stream(
					iso["SLUS_213.86"].open,
					driver
				);
			break;
			default:
				writefln("Extractor para '%s' no implementado", driver);
			break;
		}
	}

	return 0;
}
