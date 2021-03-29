import std.stdio, std.stream, std.file, std.string, std.process;
import tales.util.gameformat, tales.isopath, tales.scont.generic, tales.scont.iso;
import tales.scont.fps2, tales.sb7;
import tales.comp, sqlite3;

GameFormatString fs;

const uint fileoffset = 0x4839D0 - 0x5838D0;

uint mem2file(uint mem)  { return mem + fileoffset; }
uint file2mem(uint file) { return file - fileoffset; }

class TextEntry {
	uint count;
	char[][] maps;
	uint[] ids;
	char[] text;
	long id;

	this(char[] text) {
		this.text = text;
		sq.performQuery("INSERT INTO texts (t1,t2) VALUES (?,?);", [text, text]);
		id = sq.getLastId;
	}

	override char[] toString() {
		char[] r;
		for (int n = 0; n < count; n++) {
			if (n != 0) r ~= ", ";
			r ~= std.string.format("%s:%d", maps[n], ids[n]);
		}
		return "(" ~ r ~ ")";
	}
}

class TextFile {
	char[] fname;
	Stream s;
	uint p = 100;
	uint count = 0;
	uint level = 0;
	int fid;

	this(char[] fname) {
		this.fname = fname;
		try { mkdir("TXT"); } catch { }
		open();
	}

	void open() {
		s = new File(std.string.format("TXT/%s_%02d.txt", fname, level), FileMode.OutNew);
		sq.performQuery("INSERT INTO files2 (name) VALUES (?);", [std.string.format("%s_%02d", fname, level)]);
		fid = sq.getLastId;		
	}

	~this() {
		//s.close();
		//delete s;
	}

	void Push(TextEntry te) {
		if (count >= 200) {
			count = 0;
			level++;
			open();
		}

		//try {
			//s.writefln("## POINTER %d - %s", p, te.toString());
			s.writefln("## POINTER %d", p);
			s.writefln("%s\n", te.text);
		//} catch (Exception e) {
			//fprintf(stderr, "%s (%s)\n", toStringz(te.text), toStringz(te.toString()));
		//}
		
		sq.performQuery("INSERT INTO entries2 (fid,tid,pid) VALUES (?,?,?);", [std.string.toString(fid), std.string.toString(te.id), std.string.toString(p)]);
		
		count++;
		p += 2;
	}
}

int min(int a, int b) {
	return (a <= b) ? a : b;
}

class TextList {
	TextEntry[] listl;
	TextEntry[char[]] list;
	TextFile[char[]] textfile;

	void Info() {
		writefln("Cantidad de frases diferentes: %d", listl.length);
		uint size = 0, rep = 0;
		foreach (s; listl) {
			size += s.text.length;
			if (s.count > 1) rep++;
			//char[] name = (te.count > 1) ? (GetCommonName(te) ~ "_common") : te.maps[0];
			//GetTextFile(name);
		}
		writefln("Cantidad de frases repetidas: %d", rep);
		writefln("Tamanyo total de las frases: %d", size);
		//writefln("Cantidad de ficheros diferentes: %d", textfile);
		writefln();
	}

	void Insert(char[] text, char[] map, uint id, uint[] params) {
		// Creamos la entrada de texto si no existe
		if ((text in list) is null) listl ~= (list[text] = new TextEntry(text));

		TextEntry te = list[text];

		sq.performQuery("INSERT INTO entries (fid,tid,pid) VALUES ((SELECT id FROM files WHERE name=?),?,?);", [map, std.string.toString(te.id), std.string.toString(id)]);

		// Actualizamos los valores de la entrada de texto
		te.count++;
		te.maps ~= map;
		te.ids ~= id;
		//writefln(list.length);
	}

	char[] GetCommonName(TextEntry te) {
		char[] c1 = te.maps[0];
		int ccount = c1.length;
		//writefln("COMPARAR: %s", c1);
		for (int n = 1; n < te.maps.length; n++) {
			char[] c2 = te.maps[n];
			//writefln("-> %s", c2);
			ccount = min(ccount, c2.length);
			for (int m = 0; m < ccount; m++) {
				if (c1[m] != c2[m]) {
					ccount = m;
					break;
				}
			}
		}
		//writefln("COMMON: %s\n", c1[0..ccount]);
		return c1[0..ccount];
	}

	TextFile GetTextFile(char[] name) {
		if ((name in textfile) is null) {
			textfile[name] = new TextFile(name);
		}
		return textfile[name];
	}

	void Rehash() {
		textfile = textfile.rehash;
	}

	void Dump() {
		writefln("Dumping...");
		foreach (te; listl) {
			char[] name = (te.count > 1) ? (GetCommonName(te) ~ "_common") : te.maps[0];
			TextFile tf = GetTextFile(name);
			if (!tf) throw(new Exception("Not TextFile"));
			tf.Push(te);
		}
	}
}

void Extract_SCRIPT_Stream() {
	AbyssInitIsoPath();

	sq = new Sqlite3("translation.db");

	try {
		sq.performQuery("
			CREATE TABLE files
			(
				id INTEGER PRIMARY KEY,
				name CHAR(32)
			);
		");
	} catch (Exception e) {
		sq.performQuery("DELETE FROM files;");
	}
	
	try {
		sq.performQuery("
			CREATE TABLE files2
			(
				id INTEGER PRIMARY KEY,
				name CHAR(62)
			);
		");
	} catch (Exception e) {
		sq.performQuery("DELETE FROM files2;");
	}	

	try {
		sq.performQuery("
			CREATE TABLE texts
			(
				id INTEGER PRIMARY KEY,
				t1 TEXT,
				t2 TEXT,
				translated BOOLEAN
			);
		");
	} catch (Exception e) {
		sq.performQuery("DELETE FROM texts;");
	}

	try {
		sq.performQuery(
			"CREATE TABLE entries"
			"("
				"id INTEGER PRIMARY KEY,"
				"fid INTEGER,"
				"tid INTEGER,"
				"pid INTEGER"
				//"params TEXT"
			");"
		);
	} catch (Exception e) {
		sq.performQuery("DELETE FROM entries;");
	}
	
	try {
		sq.performQuery(
			"CREATE TABLE entries2"
			"("
				"id INTEGER PRIMARY KEY,"
				"fid INTEGER,"
				"tid INTEGER,"
				"pid INTEGER"
				//"params TEXT"
			");"
		);
	} catch (Exception e) {
		sq.performQuery("DELETE FROM entries2;");
	}	

	//printf("%s", toStringz(sqlite_decode_binary(sqlite_encode_binary("hello'(test"))));

	sq.performQuery("BEGIN TRANSACTION;");

	foreach (e; isomap) { //std.gc.fullCollect();
		char[] id;
		if (!e.isFile) continue;
		id = e.name[0..e.name.length - 4];
		sq.performQuery("INSERT INTO files (name) VALUES (?);", [id]);
		//writefln(id);
	}
	sq.performQuery("END TRANSACTION;");

	sq.performQuery("BEGIN TRANSACTION;");

	/*
	auto result = sq.query("SELECT * FROM files;");

	writefln(result.fetchRow());
	writefln(result.fetchRow());
	*/


	TextList tl = new TextList;

	try { mkdir("PKB"); } catch { }
	try { mkdir("SB7"); } catch { }

	void Process_SB7(Stream sb7s, char[] name) {
		uint ptr;

		SB7 sb7 = new SB7(sb7s);

		foreach (id, e; sb7.list) {
			char[] s = e.text;
			//writefln(e.params);
			//if (id <= 96) continue;
			if (!s.length) continue;
			if (s.length >= 7 && s[0..7] == "motion:") continue;
			tl.Insert(s, name, id, e.params);
			//printf("%d: %s\n\n", i, toStringz(s));
		}

		tl.Rehash;
	}

	int i = 0;
	foreach (e; isomap) { //std.gc.fullCollect();
		char[] id;
		if (!e.isFile) continue;
		id = e.name[0..e.name.length - 4];

		if (id == "CHP_T00E") continue;
		if (id == "COK_D02") continue;
		if (id == "ICE_D04E") continue;
		if (id == "MAP") continue;
		if (id == "SHI_D00E") continue;

		if (!std.file.exists(format("SB7/%s.SB7", id))) {
			if (!std.file.exists(format("PKB/%s.PKB", id))) {
				File f = new File(format("PKB/%s.PKB", id), FileMode.OutNew);
				f.copyFrom(e.open);
				e.close();
				f.close();
				delete f;
			}

			if (!std.file.exists(format("PKB/%s.FS2", id))) {
				system(format("comptoe -s -d \"PKB\\%s.PKB\" \"PKB\\%s.FS2\"", id, id));
			}

			if (!std.file.exists(format("PKB/%s.FS2", id))) {
				system(format("copy \"PKB\\%s.PKB\" \"PKB\\%s.FS2\" > NUL", id, id));
			}

			try {
				Fps2Archive fa = new Fps2Archive(format("PKB/%s.FS2", id));

				foreach (e; fa) {
					if (e.type == "sb7") {
						Stream s = new File(format("SB7/%s.SB7", id), FileMode.OutNew);
						s.copyFrom(e.open);
						e.close();
						s.close();
						delete s;
						break;
					}
				}

				fa.close();
			} catch (Exception e) {
				writefln("ERROR WITH: %s\n%s", id, e.toString);
			}
		}

		bool ignore = false;

		switch (toupper(id)) {
			case "TESTMAP":
			case "GRA_D00":
				ignore = true;
			break;
			default:
			break;
		}

		if (ignore){
			writefln("SB7: %s...Ignorando", id);
		} else {
			writefln("SB7: %s", id);
			Stream sb7 = new File(format("SB7/%s.SB7", id), FileMode.In);
			Process_SB7(sb7, id);
			sb7.close();
			delete sb7;
		}

		//if (i++ >= 5) break;
	}

	//system("pause");

	tl.Info();

	tl.Dump();

	sq.performQuery("END TRANSACTION;");
}

void Extract_FILES() {
	AbyssInitIsoPath();

	foreach (e; isomap) { //std.gc.fullCollect();
		char[] id;
		if (!e.isFile) continue;
		id = e.name[0..e.name.length - 4];

		if (id == "CHP_T00E") continue;
		if (id == "COK_D02") continue;
		if (id == "ICE_D04E") continue;
		if (id == "MAP") continue;
		if (id == "SHI_D00E") continue;
			
		if (!std.file.exists(format("PKB/%s.PKB", id))) {
			File f = new File(format("PKB/%s.PKB", id), FileMode.OutNew);
			f.copyFrom(e.open);
			e.close();
			f.close();
			delete f;
		}

		if (!std.file.exists(format("PKB/%s.FS2", id))) {
			system(format("comptoe -s -d \"PKB\\%s.PKB\" \"PKB\\%s.FS2\"", id, id));
		}

		if (!std.file.exists(format("PKB/%s.FS2", id))) {
			system(format("copy \"PKB\\%s.PKB\" \"PKB\\%s.FS2\" > NUL", id, id));
		}		
	}	
}

Sqlite3 sq;

int main(char[][] args) {
	fs = new TOAGameFormatString();

	if (args.length < 2) {
		writefln("Extractor SCRIPT para Tales of the Abyss");
		writefln("");
		writefln("Drivers:");
		writefln("\tscript, files");
		writefln("");
		writefln("modo de uso: extract driver [file.out]");
	} else {
		char[] driver = std.string.tolower(std.string.strip(args[1])), fileout;
		//fileout = (args.length > 2) ? args[2] : format("%s.en.txt", driver);
		switch (driver) {
			case "script": // Script principal del juego
				Extract_SCRIPT_Stream();
			break;
			case "files": // Script principal del juego
				Extract_FILES();
			break;
			default:
				writefln("Extractor para '%s' no implementado", driver);
			break;
		}
	}

	return 0;
}
