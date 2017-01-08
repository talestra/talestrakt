import std.file, std.string, std.stdio, std.c.stdlib, std.path, std.regexp, std.stream;

import tales.isopath;
import tales.util.gameformat, tales.scont.generic, tales.scont.iso;
import tales.util.rangelist, tales.util.gameformat;
import tales.image.txd;
import tales.scont.fps3, tales.comp, tales.sb7;

// La cantidad de skits que hay
const uint maxskits = 538;

//version = test;

// 0x47D728 (0x5AB8)

void UpdateSkitTitles(Stream exe, char[][] titles) {
	printf("UpdateSkitTitles() : ...\r");

	const uint ptpos = 0x43A4A4, tbpos = 0x47D728, tblen = 0x5AB0, foff = 0xfff00, stlen = 0x1C;
	GameFormatString gfs = new TOAGameFormatString();
	RangeList rl = new RangeList();
	ubyte c = 0;

	// Comprobamos que el stream sea correcto
	if (!exe) throw(new Exception(format("Error with stream (0x%08X)", cast(uint)cast(void *)exe)));

	// Limpiamos el exe
	exe.position = tbpos; for (int n = 0; n < tblen; n++) {
		//printf("%08X\n", exe.position);
		exe.write(c);
	}

	// Añadimos el rango de texto
	rl.add(tbpos, tblen);

	// Colocamos el padding del RangeList a 2
	rl.padding = 2;

	// Nos recorremos todos los títulos
	foreach (i, k; titles) {
		uint titlepos, skitpos;
		char[] title = gfs.encodeString(k) ~ "\0";
		char[] skit  = std.string.format("CHT_%03d.SKT\0", i);
		if (i >= maxskits) throw(new Exception("Mas skits de los que hay"));

		// Escribimos el título en una posición vacía
		titlepos = rl.getAndUse(title.length);
		exe.position = titlepos;
		exe.writeExact(title.ptr, title.length);

		// Escribimos el fichero en una posición vacía
		skitpos  = rl.getAndUse(skit.length );
		exe.position = skitpos;
		exe.writeExact(skit.ptr, skit.length);

		// Escribimos los punteros del título y el fichero en la tabla de estructura
		exe.position = ptpos + (stlen * i);
		exe.write(cast(uint)(titlepos + foff));
		exe.write(cast(uint)(skitpos  + foff));
	}

	printf("UpdateSkitTitles()     : Ok\t\t\n");
}

char[][] GetSkitTitlesFromSRC() {
	char[][] r;

	for (int n = 0; n < maxskits; n++) {
		printf("GetSkitTitlesFromSRC() : %04d\r", n);

		File f = new File(format("SRC/%04d.txt", n), FileMode.In);
		int ptr = 0;
		char[] title;

		while (!f.eof) {
			char[] line = f.readLine();
			if (line.length >= 10 && line[0..10] == "## POINTER") {
				ptr++;
				if (ptr >= 2) break;
				continue;
			}
			title ~= line ~ "\n";
		}

		r ~= strip(title);

		f.close();
		delete f;
	}

	printf("GetSkitTitlesFromSRC() : Ok\t\t\n");

	return r;
}

/*
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

	to.writeLine(format("## POINTER %d", 0));
	to.writeLine(title);
	to.writeLine("");

	fps["CHTSC.SB7"].saveto("sb7");

	exit(-1);

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
*/

Stream opentowrite(char[] name) {
	return new File(name, FileMode.In | FileMode.OutNew);
}

void UpdateSkitText() {
	//char[][] titles = GetSkitTitles();
	try { mkdir("SRC"); } catch (Exception e) { }
	try { mkdir("MOD"); } catch (Exception e) { }
	
	for (int n = 0; n < maxskits; n++) {
	//for (int n = 0; n < 5; n++) {
	//for (int n = 1; n < 2; n++) {
	//{ int n = 171;
	//for (int n = 132; n < maxskits; n++) {
		Stream skit = isose[std.string.format("CHT_%03d.SKT", n)].open;
		
		printf("CHT_%03d.SKT...", n);

		CompressedStream cs = new CompressedStream(skit);

		//(new File("fps3", FileMode.OutNew)).copyFrom(cs);

		Fps3Archive fps = new Fps3Archive(cs);

		Stream CHTSC_SB7 = fps["CHTSC.SB7"].open;
		//fps.list;

		(new File("sb7", FileMode.OutNew)).copyFrom(CHTSC_SB7);

		version(test) {
			RangeList rl  = GetSB7Space(CHTSC_SB7);
			char[][] strl = GetSB7Text (CHTSC_SB7);
		} else {
			SB7 sb7 = new SB7(CHTSC_SB7);
		}

		char[][int] strt;

		{
			File src = new File(format("SRC/%04d.txt", n), FileMode.In);
			strt = GetTextPointers(src);
			if (0 in strt) strt.remove(0);
			src.close();
			delete src;
		}
		
		
		foreach (k, v; strt) {			
			version (test) {
				//if (k >= strt.length) { fwritefln(stderr, "Posicion superada"); continue; }
				strl[k] = v;
			} else {
				if (k >= sb7.list.length) { fwritefln(stderr, "Posicion superada"); continue; }
				sb7.list[k].text = v;
			}
		}

		version (test) {
			rl.add(rl.getLastPosition, 0x80);
		}

		Stream newsb7 = new MemoryStream();
		CHTSC_SB7.position = 0; newsb7.copyFrom(CHTSC_SB7);
		CHTSC_SB7.position = 0;
		
		version (test) {
			UpdateSB7(newsb7, rl, strl);
		} else {
			sb7.update(newsb7);
		}

		(cast(Fps3Entry)fps["CHTSC.SB7"]).setStream(newsb7);

		File cdump = new File(std.string.format("MOD/CHT_%03d.SKT", n), FileMode.OutNew);

		cdump.position = 0;

		CompressStream csnew = new CompressStream(cdump);
		fps.saveto(csnew);
		csnew.close();

		delete fps;
		delete cs;
		delete skit;
		
		printf("Ok\n", n);
		//break;
	}
	printf("\r\t\t\t\r\n");
}

int main(char[][] args) {
	AbyssInitIsoPath();

	//Iso iso_o = new Iso("c:\\juegos\\abyss\\abyss-original.iso");
	//Iso isose_o = new Iso(iso_o["TO7SE.CVM"].open);
	//isose["CHT_001.SKT"].replace(isose_o["CHT_001.SKT"].open);

	//UpdateSkitTitles(iso["SLUS_213.86"].open, GetSkitTitlesFromSRC());
	
	UpdateSkitTitles(new File("../../SLUS_213.86", FileMode.In | FileMode.Out), GetSkitTitlesFromSRC());	
	//UpdateSkitText();

	return 0;
}