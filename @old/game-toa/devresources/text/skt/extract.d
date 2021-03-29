import std.file, std.string, std.stdio, std.c.stdlib, std.path, std.regexp, std.stream;

import tales.util.gameformat, tales.isopath, tales.scont.generic, tales.scont.iso;
import tales.image.txd;
import tales.scont.fps3, tales.comp, tales.sb7;

// La cantidad de skits que hay
const uint maxskits = 538;

// Obtiene los titulos de los skit del ejecutable
char[][] GetSkitTitles() {
	struct SkitEntry {
		uint t1;
		uint t2;
		uint unk[5];
	} SkitEntry se;
	int offset;
	char[][] list;
	Stream s = iso["SLUS_213.86"].open();

	s.position = 0x43A4A4;
	offset = 0x47D728 - 0x57D628;

	for (int n = 0; n < maxskits; n++) {
		char[] name;

		s.read(TSerialize(&se));

		{
			ulong cp = s.position;
			s.position = se.t1 + offset;
			while (!s.eof) { ubyte c; s.read(c); if (c == 0) break; name ~= cast(char)c; }
			s.position = cp;
		}

		list ~= name;
	}

	s.close();

	return list;
}

void ExtractTextFromSKT(Stream skit, Stream to, char[] title) {
	CompressedStream cs = new CompressedStream(skit);
	Fps3Archive fps = new Fps3Archive(cs);

	/*
	fps["CHTSC.SB7"].saveto("sb7");
	exit(-1);

	fps.list;
	fps["CHTSC.SB7"].saveto("_CHTSC.SB7");
	fps["cht.anm"].saveto("_cht.anm");
	fps["cht.txd"].saveto("_cht.txd");
	TXD txd = new TXD("_cht.txd");
	exit(-1);
	*/

	to.writeLine(format("## POINTER %d", 0));
	to.writeLine(title);
	to.writeLine("");

	foreach (uint n, line; GetSB7Text(fps["CHTSC.SB7"].open)) {
		if (n <= 0x5F) continue;
		if (!line.length) continue;
		to.writeLine(format("## POINTER %d", n));
		to.writeLine(line);
		to.writeLine("");
	}

	delete cs;
	delete fps;
}

void ExtractTextFromSKT(char[] skit, char[] to, char[] title) {
	Stream skits = new File(skit, FileMode.In);
	Stream tos   = new File(to,   FileMode.OutNew);
	ExtractTextFromSKT(skits, tos, title);
	tos.close();
	skits.close();
}

void ProcessAllSKT() {
	char[][] titles = GetSkitTitles();
	try { mkdir("SRC"); } catch (Exception e) { }
	for (int n = 0; n < maxskits; n++) {
		printf("\r\t\t\t\r%d/%d...", n, 538);
		Stream ori = isose[std.string.format("CHT_%03d.SKT", n)].open;
		Stream ext = new File(format("SRC/%04d.txt", n), FileMode.OutNew);
		ExtractTextFromSKT(ori, ext, titles[n]);
		ori.close();
	}
	printf("\r\t\t\t\r\n");
}

int main() {
	AbyssInitIsoPath();

	ProcessAllSKT();

	return 0;
}